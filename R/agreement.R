#' Attribute agreement of a categorical LLM pipeline
#'
#' The categorical counterpart of [msa_grr()], following the attribute
#' agreement analysis of the AIAG MSA manual: how often does the pipeline
#' give the same answer when asked again (repeatability), the same answer
#' under a different prompt or model (reproducibility), and the correct
#' answer (accuracy against a reference)? Agreement is summarised as
#' percentages of consistent cells and items, as Krippendorff's alpha
#' (which tolerates missing responses and ordinal scales) and, against a
#' reference, as Cohen's kappa with optional ordinal weights.
#'
#' @param runs An `msa_runs` object with categorical values.
#' @param levels The labels in scale order (needed for ordinal weights and
#'   for a clean category list). Default: sorted unique values.
#' @param reference Optional reference classification: a named vector keyed
#'   by `item_id`, a data.frame with columns `item_id` and `reference`, or
#'   the name of a column in `runs`.
#' @param weights Weighting of disagreements for the ordinal statistics:
#'   `"unweighted"` (nominal), `"linear"` or `"quadratic"`.
#'
#' @return An object of class `msa_agreement`, a list with
#'   `repeatability` (per prompt-model cell: share of items whose replicates
#'   all agree), `reproducibility` (share of items consistent across
#'   prompts, across models and overall), `alpha` (Krippendorff's alpha
#'   within replicates, across prompts, across models, and overall), and,
#'   if a reference is given, `accuracy` (per prompt-model and overall) and
#'   `kappa` (Cohen's kappa of the modal response and of all responses
#'   against the reference).
#' @examples
#' lv <- c("B", "LB", "VUS", "LP", "P")
#' ag <- msa_agreement(acmg_demo, levels = lv, reference = "reference", weights = "linear")
#' ag
#' @export
msa_agreement <- function(runs, levels = NULL, reference = NULL,
                          weights = c("unweighted", "linear", "quadratic")) {
  weights <- match.arg(weights)
  d <- as.data.frame(runs, stringsAsFactors = FALSE)
  stop_if_missing_cols(d, c("item_id", "prompt_id", "model_id", "rep", "value"), "runs")
  d$value <- as.character(d$value)
  if (is.null(levels)) levels <- sort(unique(d$value[!is.na(d$value)]))
  d$value[!d$value %in% levels] <- NA
  n_missing <- sum(is.na(d$value))

  all_same <- function(v) { v <- v[!is.na(v)]; if (length(v) < 2) NA else length(unique(v)) == 1 }
  mean_na <- function(x) if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE)

  # repeatability: within item x prompt x model
  cell <- stats::aggregate(value ~ item_id + prompt_id + model_id, data = d,
                           FUN = all_same, na.action = stats::na.pass)
  repeat_tab <- stats::aggregate(value ~ prompt_id + model_id, data = cell,
                                 FUN = function(v) 100 * mean_na(v), na.action = stats::na.pass)
  names(repeat_tab)[3] <- "pct_items_consistent"
  repeat_overall <- 100 * mean_na(cell$value)

  # reproducibility: across prompts (within model), across models (within prompt), overall
  by_item_model <- stats::aggregate(value ~ item_id + model_id, data = d, FUN = all_same, na.action = stats::na.pass)
  by_item_prompt <- stats::aggregate(value ~ item_id + prompt_id, data = d, FUN = all_same, na.action = stats::na.pass)
  by_item <- stats::aggregate(value ~ item_id, data = d, FUN = all_same, na.action = stats::na.pass)
  repro <- c(pct_items_consistent_across_prompts = 100 * mean_na(by_item_model$value),
             pct_items_consistent_across_models = 100 * mean_na(by_item_prompt$value),
             pct_items_consistent_overall = 100 * mean_na(by_item$value))

  # Krippendorff's alpha at several scopes
  metric <- switch(weights, unweighted = "nominal", linear = "ordinal", quadratic = "interval")
  alpha_scope <- function(unit_cols) {
    unit <- do.call(paste, c(d[unit_cols], sep = "|"))
    krippendorff_alpha(d$value, unit, levels, metric)
  }
  alpha <- data.frame(
    scope = c("replicates (within prompt & model)", "across prompts (within model)",
              "across models (within prompt)", "all conditions"),
    alpha = c(alpha_scope(c("item_id", "prompt_id", "model_id")),
              alpha_scope(c("item_id", "model_id")),
              alpha_scope(c("item_id", "prompt_id")),
              alpha_scope("item_id")),
    stringsAsFactors = FALSE)

  out <- list(repeatability = repeat_tab, repeatability_overall = repeat_overall,
              reproducibility = repro, alpha = alpha, levels = levels, weights = weights,
              n = c(items = length(unique(d$item_id)), responses = nrow(d), missing = n_missing))

  if (!is.null(reference)) {
    ref <- resolve_reference(reference, d)
    d$reference <- unname(ref[d$item_id])
    d$hit <- d$value == d$reference
    acc_tab <- stats::aggregate(hit ~ prompt_id + model_id, data = d,
                                FUN = function(v) 100 * mean_na(v), na.action = stats::na.pass)
    names(acc_tab)[3] <- "pct_correct"
    acc_overall <- 100 * mean_na(d$hit)
    item_all_correct <- stats::aggregate(hit ~ item_id, data = d,
                                         FUN = function(v) all(v[!is.na(v)]), na.action = stats::na.pass)
    modal <- stats::aggregate(value ~ item_id, data = d, FUN = function(v) {
      v <- v[!is.na(v)]; if (!length(v)) NA_character_ else names(which.max(table(factor(v, levels = levels))))
    }, na.action = stats::na.pass)
    modal$reference <- unname(ref[modal$item_id])
    kappa <- c(
      kappa_modal_vs_reference = cohen_kappa(modal$value, modal$reference, levels, weights),
      kappa_all_vs_reference = cohen_kappa(d$value, d$reference, levels, weights))
    out$accuracy <- acc_tab
    out$accuracy_overall <- acc_overall
    out$pct_items_all_correct <- 100 * mean_na(item_all_correct$hit)
    out$kappa <- kappa
    out$modal <- modal
  }
  class(out) <- "msa_agreement"
  out
}

resolve_reference <- function(reference, d) {
  if (is.character(reference) && length(reference) == 1 && reference %in% names(d)) {
    r <- unique(d[, c("item_id", reference)])
    return(stats::setNames(as.character(r[[reference]]), r$item_id))
  }
  if (is.data.frame(reference)) {
    stop_if_missing_cols(reference, c("item_id", "reference"), "reference")
    return(stats::setNames(as.character(reference$reference), as.character(reference$item_id)))
  }
  if (!is.null(names(reference))) return(stats::setNames(as.character(reference), names(reference)))
  stop("`reference` must be a named vector, a data.frame (item_id, reference) or a column name.",
       call. = FALSE)
}

#' @export
print.msa_agreement <- function(x, ...) {
  cat("Attribute agreement of an LLM measurement system\n")
  cat(sprintf("  %d items, %d responses (%d missing/unparseable); categories: %s; weights: %s\n",
              x$n[["items"]], x$n[["responses"]], x$n[["missing"]],
              paste(x$levels, collapse = " < "), x$weights))
  cat(sprintf("\nRepeatability: %.1f %% of item-prompt-model cells have identical replicates\n",
              x$repeatability_overall))
  rt <- x$repeatability; rt$pct_items_consistent <- fmt_pct(rt$pct_items_consistent)
  print(rt, row.names = FALSE)
  r <- x$reproducibility
  cat(sprintf("\nReproducibility: items consistent across prompts %.1f %%, across models %.1f %%, overall %.1f %%\n",
              r[[1]], r[[2]], r[[3]]))
  al <- x$alpha; al$alpha <- fmt_num(al$alpha, 3)
  cat("\nKrippendorff's alpha:\n"); print(al, row.names = FALSE)
  if (!is.null(x$accuracy)) {
    cat(sprintf("\nAccuracy vs reference: %.1f %% of responses correct; %.1f %% of items correct in every call\n",
                x$accuracy_overall, x$pct_items_all_correct))
    at <- x$accuracy; at$pct_correct <- fmt_pct(at$pct_correct)
    print(at, row.names = FALSE)
    cat(sprintf("  Cohen's kappa (%s): modal response vs reference %.3f; all responses vs reference %.3f\n",
                x$weights, x$kappa[[1]], x$kappa[[2]]))
  }
  invisible(x)
}

# Krippendorff's alpha from a vector of values and a unit id per value.
# Handles missing values and units with a single value (ignored).
krippendorff_alpha <- function(values, units, levels, metric = c("nominal", "ordinal", "interval")) {
  metric <- match.arg(metric)
  k <- length(levels)
  ok <- !is.na(values)
  values <- values[ok]; units <- units[ok]
  if (!length(values)) return(NA_real_)
  ci <- match(values, levels)
  o <- matrix(0, k, k)
  for (u in split(ci, units)) {
    m <- length(u)
    if (m < 2) next
    tab <- tabulate(u, nbins = k)
    # pairs of values from different "coders" within the unit
    o <- o + (outer(tab, tab) - diag(tab, k)) / (m - 1)
  }
  n_c <- rowSums(o); n <- sum(n_c)
  if (n < 2) return(NA_real_)
  delta <- switch(metric,
    nominal = 1 - diag(k),
    interval = outer(seq_len(k), seq_len(k), function(a, b) (a - b)^2),
    ordinal = {
      cs <- cumsum(n_c); cs0 <- c(0, cs)
      outer(seq_len(k), seq_len(k), function(a, b) {
        lo <- pmin(a, b); hi <- pmax(a, b)
        (cs[hi] - cs0[lo] - (n_c[a] + n_c[b]) / 2)^2
      })
    })
  Do <- sum(o * delta) / n
  De <- sum(outer(n_c, n_c) * delta) / (n * (n - 1))
  if (De == 0) return(NA_real_)
  1 - Do / De
}

# Cohen's (weighted) kappa between two label vectors.
cohen_kappa <- function(x, y, levels, weights = c("unweighted", "linear", "quadratic")) {
  weights <- match.arg(weights)
  ok <- !is.na(x) & !is.na(y)
  x <- factor(x[ok], levels = levels); y <- factor(y[ok], levels = levels)
  if (!length(x)) return(NA_real_)
  k <- length(levels)
  tab <- table(x, y) / length(x)
  i <- matrix(seq_len(k), k, k); j <- t(i)
  w <- switch(weights,
    unweighted = (i == j) * 1,
    linear = 1 - abs(i - j) / (k - 1),
    quadratic = 1 - ((i - j) / (k - 1))^2)
  po <- sum(w * tab)
  pe <- sum(w * outer(rowSums(tab), colSums(tab)))
  if (pe == 1) return(NA_real_)
  (po - pe) / (1 - pe)
}

#' Bias and linearity of a numeric LLM pipeline against a reference
#'
#' Compares parsed numeric values with reference values per item: mean
#' bias with a t-based confidence interval overall and per prompt-model
#' combination, and a linearity check (does the bias depend on the
#' magnitude of the reference?) by regressing the bias on the reference.
#'
#' @param runs An `msa_runs` object with numeric values.
#' @param reference A named numeric vector keyed by `item_id`, a data.frame
#'   with columns `item_id` and `reference`, or a column name in `runs`.
#' @param level Confidence level.
#' @return An object of class `msa_bias`: a list with `overall`,
#'   `by_condition` and `linearity`.
#' @examples
#' msa_bias(ic50_demo, reference = "reference")
#' @export
msa_bias <- function(runs, reference, level = 0.95) {
  d <- as.data.frame(runs, stringsAsFactors = FALSE)
  stop_if_missing_cols(d, c("item_id", "prompt_id", "model_id", "value"), "runs")
  ref <- resolve_reference(reference, d)
  d$value <- suppressWarnings(as.numeric(as.character(d$value)))
  d$reference <- suppressWarnings(as.numeric(ref[d$item_id]))
  d <- d[!is.na(d$value) & !is.na(d$reference), , drop = FALSE]
  d$diff <- d$value - d$reference
  ci_row <- function(x) {
    n <- length(x); m <- mean(x); s <- stats::sd(x)
    se <- if (n > 1) s / sqrt(n) else NA
    tq <- if (n > 1) stats::qt(1 - (1 - level) / 2, n - 1) else NA
    p <- if (n > 1 && is.finite(se) && se > 0) stats::t.test(x)$p.value else NA
    c(n = n, bias = m, sd = s, lower = m - tq * se, upper = m + tq * se, p_value = p)
  }
  overall <- ci_row(d$diff)
  by_cond <- do.call(rbind, lapply(split(d, list(d$prompt_id, d$model_id), drop = TRUE), function(g) {
    data.frame(prompt_id = g$prompt_id[1], model_id = g$model_id[1], t(ci_row(g$diff)),
               stringsAsFactors = FALSE)
  }))
  rownames(by_cond) <- NULL
  lin <- stats::lm(diff ~ reference, data = d)
  cf <- summary(lin)$coefficients
  linearity <- c(intercept = unname(cf[1, 1]), slope = unname(cf[2, 1]),
                 slope_p_value = unname(cf[2, 4]))
  structure(list(overall = overall, by_condition = by_cond, linearity = linearity,
                 level = level, n_items = length(unique(d$item_id))), class = "msa_bias")
}

#' @export
print.msa_bias <- function(x, ...) {
  o <- x$overall
  cat(sprintf("Bias against reference (%d items, %d values)\n", x$n_items, as.integer(o[["n"]])))
  cat(sprintf("  mean bias %.4f  [%.0f %% CI %.4f, %.4f]  sd %.4f  p = %.3g\n",
              o[["bias"]], 100 * x$level, o[["lower"]], o[["upper"]], o[["sd"]], o[["p_value"]]))
  b <- x$by_condition
  for (nm in c("bias", "sd", "lower", "upper")) b[[nm]] <- fmt_num(b[[nm]])
  b$p_value <- formatC(b$p_value, digits = 3, format = "g")
  print(b, row.names = FALSE)
  l <- x$linearity
  cat(sprintf("  linearity: bias = %.4f + %.4f * reference (slope p = %.3g)\n",
              l[["intercept"]], l[["slope"]], l[["slope_p_value"]]))
  invisible(x)
}
