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
#'   `unweighted` (nominal), `linear` (ordinal), `quadratic` (interval).
#'   Interval distances use category positions, not numeric label values.
#' @param fleiss Also compute Fleiss' kappa over all valid ratings of each
#'   item. Every observed item must have the same number of valid ratings,
#'   at least two. Unequal counts give `NA` with a message pointing to
#'   Krippendorff's alpha. Only the point estimate is returned; no standard
#'   error is computed.
#'
#' @details Missing responses and responses outside `levels` are excluded.
#'   Accuracy uses valid response-reference pairs. An item without a valid
#'   pair does not enter the proportion of fully correct items. Repeatability
#'   and reproducibility require at least two valid responses per unit;
#'   blocks do not split these units. Alpha counts excluded observed units
#'   in `n_units_excluded`, including units without any valid response.
#'
#'   Each item must have at most one distinct nonmissing reference. Repeated
#'   identical references are allowed; a known reference beside missing
#'   entries is used for that item. Conflicting references are errors.
#'   Nonmissing references must belong to `levels`, including when the scale
#'   is derived from responses. Supply the complete scale explicitly when
#'   some categories occur only in the reference. Undefined Cohen's kappa
#'   gives `NA` with a message, including single-category scales.
#'
#'   The modal response ignores missing answers; ties select the lowest of
#'   the tied categories in scale order. An item without a valid answer has
#'   a missing mode. These are general agreement diagnostics. The AP1
#'   application uses its own decision metric: `acmg_modal()` treats missing
#'   answers as a category and excludes tied modes from decisions. Cohen's
#'   kappa over all responses has no standard error because responses of
#'   the same item can be dependent.
#'
#' @return An object of class `msa_agreement`, a list with
#'   `repeatability` (per prompt-model cell: share of items whose replicates
#'   all agree), `reproducibility` (share of items consistent across
#'   prompts, across models and overall), `alpha` (Krippendorff's alpha
#'   within replicates, across prompts, across models, and overall), and,
#'   if a reference is given, `accuracy` (per prompt-model and overall) and
#'   `kappa` (Cohen's kappa of the modal response and of all responses
#'   against the reference). With `fleiss = TRUE`, `fleiss` is a list with
#'   the single numeric element `kappa`.
#' @examples
#' lv <- c("B", "LB", "VUS", "LP", "P")
#' ag <- msa_agreement(acmg_demo, levels = lv, reference = "reference", weights = "linear")
#' ag
#' @export
msa_agreement <- function(runs, levels = NULL, reference = NULL,
                          weights = c("unweighted", "linear", "quadratic"),
                          fleiss = FALSE) {
  weights <- msa_agreement_arg(weights, c("unweighted", "linear", "quadratic"))
  if (!is.logical(fleiss) || length(fleiss) != 1L || is.na(fleiss)) {
    stop("`fleiss` must be a single nonmissing logical value.", call. = FALSE)
  }
  d <- as.data.frame(runs, stringsAsFactors = FALSE)
  stop_if_missing_cols(d, c("item_id", "prompt_id", "model_id", "rep", "value"), "runs")
  d$value <- as.character(d$value)
  if (is.null(levels)) levels <- sort(unique(d$value[!is.na(d$value)]))
  if (!is.null(reference)) {
    ref <- resolve_reference(reference, d)
    d$reference <- unname(ref[as.character(d$item_id)])
    outside <- sort(unique(d$reference[!is.na(d$reference) & !d$reference %in% levels]))
    if (length(outside)) {
      stop("`reference` contains values outside `levels`: ",
           paste(encodeString(outside, quote = '"'), collapse = ", "), ".", call. = FALSE)
    }
  }
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
    groups <- msa_agreement_groups(d, unit_cols)
    unit <- integer(nrow(d))
    for (i in seq_along(groups)) unit[groups[[i]]] <- i
    c(alpha = krippendorff_alpha(d$value, unit, levels, metric),
      n_units_excluded = sum(vapply(groups, function(i) sum(!is.na(d$value[i])) < 2, logical(1))))
  }
  scopes <- lapply(list(c("item_id", "prompt_id", "model_id"),
                        c("item_id", "model_id"), c("item_id", "prompt_id"), "item_id"), alpha_scope)
  alpha <- data.frame(
    scope = c("replicates (within prompt & model)", "across prompts (within model)",
              "across models (within prompt)", "all conditions"),
    alpha = vapply(scopes, `[[`, numeric(1), "alpha"),
    n_units_excluded = vapply(scopes, `[[`, numeric(1), "n_units_excluded"),
    stringsAsFactors = FALSE)

  out <- list(repeatability = repeat_tab, repeatability_overall = repeat_overall,
              reproducibility = repro, alpha = alpha, levels = levels, weights = weights,
              n = c(items = length(unique(d$item_id)), responses = nrow(d), missing = n_missing))

  if (!is.null(reference)) {
    d$hit <- d$value == d$reference
    acc_tab <- stats::aggregate(hit ~ prompt_id + model_id, data = d,
                                FUN = function(v) 100 * mean_na(v), na.action = stats::na.pass)
    names(acc_tab)[3] <- "pct_correct"
    acc_overall <- 100 * mean_na(d$hit)
    item_all_correct <- stats::aggregate(hit ~ item_id, data = d,
                                         FUN = function(v) if (all(is.na(v))) NA else all(v[!is.na(v)]),
                                         na.action = stats::na.pass)
    modal <- stats::aggregate(value ~ item_id, data = d, FUN = function(v) {
      v <- v[!is.na(v)]; if (!length(v)) NA_character_ else names(which.max(table(factor(v, levels = levels))))
    }, na.action = stats::na.pass)
    modal$reference <- unname(ref[as.character(modal$item_id)])
    kappa <- c(
      kappa_modal_vs_reference = cohen_kappa(modal$value, modal$reference, levels, weights),
      kappa_all_vs_reference = cohen_kappa(d$value, d$reference, levels, weights))
    out$accuracy <- acc_tab
    out$accuracy_overall <- acc_overall
    out$pct_items_all_correct <- 100 * mean_na(item_all_correct$hit)
    out$kappa <- kappa
    out$modal <- modal
  }
  if (fleiss) out$fleiss <- list(kappa = msa_fleiss_kappa(d$value, d$item_id, levels))
  class(out) <- "msa_agreement"
  out
}

resolve_reference <- function(reference, d, as_numeric = FALSE) {
  if (is.character(reference) && length(reference) == 1 && reference %in% names(d)) {
    id <- as.character(d$item_id)
    value <- d[[reference]]
  } else if (is.data.frame(reference)) {
    stop_if_missing_cols(reference, c("item_id", "reference"), "reference")
    id <- as.character(reference$item_id)
    value <- reference$reference
  } else if (!is.null(names(reference))) {
    id <- names(reference)
    value <- reference
  } else {
    stop("`reference` must be a named vector, a data.frame (item_id, reference) or a column name.",
         call. = FALSE)
  }
  value <- if (as_numeric) msa_bias_numeric(value, "reference") else as.character(value)
  pairs <- unique(data.frame(item_id = id, reference = value, stringsAsFactors = FALSE))
  known <- pairs[!is.na(pairs$reference), , drop = FALSE]
  conflict <- sort(unique(known$item_id[duplicated(known$item_id)]))
  if (length(conflict)) {
    values <- sort(known$reference[known$item_id == conflict[1]])
    shown <- if (as_numeric) format(values, digits = 17, trim = TRUE) else values
    stop("Conflicting reference values for item_id ", encodeString(conflict[1], quote = '"'),
         ": ", paste(encodeString(shown, quote = '"'), collapse = ", "), ".", call. = FALSE)
  }
  items <- unique(id)
  stats::setNames(known$reference[match(items, known$item_id)], items)
}

# Integer codes avoid collisions when IDs contain separators such as | or .
msa_agreement_groups <- function(d, columns) {
  keys <- lapply(d[columns], function(x) match(x, unique(x)))
  split(seq_len(nrow(d)), keys, drop = TRUE)
}

msa_agreement_arg <- function(x, choices) {
  tryCatch(match.arg(x, choices),
           error = function(e) stop(conditionMessage(e), call. = FALSE))
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
  if (!is.null(x$fleiss)) cat(sprintf("\nFleiss' kappa: %.3f\n", x$fleiss$kappa))
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
  metric <- msa_agreement_arg(metric, c("nominal", "ordinal", "interval"))
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
  weights <- msa_agreement_arg(weights, c("unweighted", "linear", "quadratic"))
  x <- factor(x, levels = levels); y <- factor(y, levels = levels)
  ok <- !is.na(x) & !is.na(y)
  x <- x[ok]; y <- y[ok]
  if (!length(x)) {
    message("Cohen's kappa is undefined: no valid response-reference pairs.")
    return(NA_real_)
  }
  k <- length(levels)
  if (k < 2) {
    message("Cohen's kappa is undefined: fewer than two scale categories.")
    return(NA_real_)
  }
  tab <- table(x, y) / length(x)
  i <- matrix(seq_len(k), k, k); j <- t(i)
  w <- switch(weights,
    unweighted = (i == j) * 1,
    linear = 1 - abs(i - j) / (k - 1),
    quadratic = 1 - ((i - j) / (k - 1))^2)
  po <- sum(w * tab)
  pe <- sum(w * outer(rowSums(tab), colSums(tab)))
  if (pe >= 1) {
    message("Cohen's kappa is undefined: expected agreement is one.")
    return(NA_real_)
  }
  (po - pe) / (1 - pe)
}

msa_fleiss_kappa <- function(values, items, levels) {
  counts <- table(factor(items, levels = unique(items)), factor(values, levels = levels))
  m <- unique(rowSums(counts))
  if (length(m) != 1L) {
    message("Fleiss' kappa requires equal valid rating counts for every item; use Krippendorff's alpha for unequal counts.")
    return(NA_real_)
  }
  if (m < 2) {
    message("Fleiss' kappa is undefined: fewer than two valid ratings per item.")
    return(NA_real_)
  }
  expected <- sum((colSums(counts) / sum(counts))^2)
  if (expected >= 1) {
    message("Fleiss' kappa is undefined: all valid ratings use the same category.")
    return(NA_real_)
  }
  observed <- mean(rowSums(counts * (counts - 1)) / (m * (m - 1)))
  unname((observed - expected) / (1 - expected))
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
#'   Each item has at most one distinct readable reference; conflicting
#'   references are errors. A known value beside missing entries supplies
#'   that item's reference. Factor labels are read as numbers.
#' @param level Finite numeric confidence level strictly between zero and one.
#'
#' @details Missing, NaN and unparseable responses or references are excluded
#'   and counted once per row in `n_excluded`. Infinite inputs and overflow
#'   of the response minus reference are errors. All observed prompt-model
#'   conditions remain in the output, even with no valid pairs. If there are
#'   no valid pairs overall, the call fails with an explanatory error.
#'
#'   The bias interval and p-value use the one-sample t calculation with
#'   `n - 1` degrees of freedom. One valid pair gives its bias but no
#'   inference. Numerically constant deviations give a point interval and
#'   an undefined p-value, with a message; the measured SD is retained.
#'   Constancy means a zero standard error, or a standard error smaller than
#'   ten times machine precision times the absolute mean.
#'
#'   The handbook regression uses all valid single deviations (`N - 2`
#'   degrees of freedom, or `gm - 2` in a balanced design). The additional
#'   regression uses unweighted item means (`g - 2` degrees of freedom).
#'   Items with the same reference value remain distinct. Unequal replicate
#'   counts thus give different weighting in the two regressions. Replicates
#'   of the same item may be correlated, so the handbook calculation can
#'   overstate the information. The object and report describe this limitation.
#'
#'   The handbook confidence band for the mean bias determines the linearity
#'   verdict. Zero must lie in the band throughout the closed observed
#'   reference range, including between displayed reference values; touching
#'   the boundary counts as inclusion. This is not a prediction interval.
#'   A single reference value leaves linearity undefined without preventing
#'   bias estimation. Without residual degrees of freedom, coefficients are
#'   retained but inference and the band are undefined. Numerically constant
#'   targets have undefined R-squared. A residual norm no larger than ten
#'   times machine precision times the centered target norm is treated as
#'   zero: t and p are undefined and the band collapses onto the fitted line.
#'   These cases produce messages and `NA`, never `NaN`.
#'
#' @return An object of class `msa_bias`, with:
#'   \describe{
#'     \item{overall}{Named numeric vector `n`, `bias`, `sd`, `lower`, `upper`,
#'       `p_value`, `n_excluded`.}
#'     \item{by_condition}{The same quantities per observed prompt-model
#'       combination. With no valid pair all estimates are `NA`.}
#'     \item{linearity}{Handbook `intercept`, `slope`, `slope_p_value`,
#'       `r_squared` (proportion), `t_intercept`, `t_slope`, `df`, `t_quantile`.}
#'     \item{linearity_item_means}{Unweighted item-mean `intercept`, `slope`,
#'       `r_squared`, `t_intercept`, `t_slope`, `df`.}
#'     \item{linearity_band}{Data frame `reference`, `fit`, `lower`, `upper`,
#'       at each distinct reference value; empty when the band is undefined.}
#'     \item{linearity_in_band}{Logical scalar: zero lies in the entire
#'       handbook band, or `NA` when undefined.}
#'     \item{linearity_verdict}{`"acceptable"` when the entire band contains
#'       zero, `"unacceptable"` otherwise, or `NA_character_` when undefined.}
#'     \item{linearity_note}{Methods, both degrees of freedom, dependence
#'       limitation and any reason for undefined linearity.}
#'     \item{level, n_items}{Confidence level and count of items with valid pairs.}
#'   }
#' @examples
#' msa_bias(ic50_demo, reference = "reference")
#' @export
msa_bias <- function(runs, reference, level = 0.95) {
  if (!is.numeric(level) || is.complex(level) || length(level) != 1L ||
      !is.finite(level) || level <= 0 || level >= 1) {
    stop("`level` must be a finite numeric scalar strictly between zero and one.", call. = FALSE)
  }
  d <- as.data.frame(runs, stringsAsFactors = FALSE)
  stop_if_missing_cols(d, c("item_id", "prompt_id", "model_id", "value"), "runs")
  ref <- resolve_reference(reference, d, as_numeric = TRUE)
  d$value <- msa_bias_numeric(d$value, "value")
  d$reference <- unname(ref[as.character(d$item_id)])
  d$diff <- d$value - d$reference
  if (any(is.infinite(d$diff))) {
    stop("Bias differences overflow: `value` minus `reference` must be finite.", call. = FALSE)
  }
  valid <- !is.na(d$diff)
  if (!any(valid)) {
    stop("Bias requires at least one valid response-reference pair; ", nrow(d),
         " row(s) excluded because a response or reference is missing or unparseable.", call. = FALSE)
  }
  overall <- msa_bias_interval(d$diff, level, "overall")
  by_cond <- do.call(rbind, lapply(msa_agreement_groups(d, c("prompt_id", "model_id")), function(i) {
    g <- d[i, , drop = FALSE]
    label <- paste0("prompt ", encodeString(as.character(g$prompt_id[1]), quote = '"'),
                    ", model ", encodeString(as.character(g$model_id[1]), quote = '"'))
    data.frame(prompt_id = g$prompt_id[1], model_id = g$model_id[1], t(msa_bias_interval(g$diff, level, label)),
               stringsAsFactors = FALSE)
  }))
  rownames(by_cond) <- NULL
  d <- d[valid, , drop = FALSE]
  item_groups <- msa_agreement_groups(d, "item_id")
  item_x <- vapply(item_groups, function(i) d$reference[i[1]], numeric(1))
  item_y <- vapply(item_groups, function(i) mean(d$diff[i]), numeric(1))
  handbook <- msa_bias_regression(d$reference, d$diff, level, "Handbook regression")
  means <- msa_bias_regression(item_x, item_y, level, "Regression on item means")
  note <- sprintf(paste0("The handbook regression uses all valid single deviations (df = %s; gm - 2 in a balanced design); ",
                         "the regression on unweighted item means uses df = %s (g - 2). ",
                         "Replicates of the same item may be correlated and are not independent. ",
                         "The handbook confidence band determines the linearity verdict."),
                  format(handbook$coefficients[["df"]]), format(means$coefficients[["df"]]))
  note <- paste(c(note, handbook$note, means$note), collapse = " ")
  inside <- handbook$in_band
  structure(list(overall = overall, by_condition = by_cond, linearity = handbook$coefficients,
                 level = level, n_items = length(item_groups),
                 linearity_item_means = means$coefficients[c("intercept", "slope", "r_squared", "t_intercept", "t_slope", "df")],
                 linearity_band = handbook$band, linearity_in_band = inside,
                 linearity_verdict = if (is.na(inside)) NA_character_ else if (inside) "acceptable" else "unacceptable",
                 linearity_note = note), class = "msa_bias")
}

# Parse only text/factor labels; never round existing doubles through text.
msa_bias_numeric <- function(x, what) {
  if (is.complex(x)) stop("`", what, "` must contain real numeric values.", call. = FALSE)
  if (is.factor(x)) x <- as.character(x)
  # Unparseable strings are documented missing values, not engine failures.
  x <- suppressWarnings(as.numeric(x))
  if (any(is.infinite(x))) stop("`", what, "` must not contain infinite values.", call. = FALSE)
  x[is.nan(x)] <- NA_real_
  x
}

# Center before scaling to retain close differences; scale first only if the
# subtraction itself exceeds the floating-point range. No squared raw values.
msa_bias_center <- function(x) {
  m <- mean(x)
  # Without extended precision (Apple silicon, CRAN's noLD check) mean() can
  # overflow near .Machine$double.xmax although the mean of finite values is finite.
  if (!is.finite(m) && length(x) > 0L && all(is.finite(x))) m <- msa_bias_scaled_mean(x)
  z <- x - m
  if (all(is.finite(z))) {
    scale <- max(abs(z))
    if (scale == 0) scale <- 1
    z <- z / scale
  } else {
    scale <- max(abs(x))
    z <- x / scale - m / scale
  }
  list(mean = m, z = z, scale = scale)
}

# Mean of finite values on x / p for a power of two p near max(abs(x)). The scaling
# is exact and |x / p| < 2, so neither the sum nor the result can overflow, and an
# input without overflow gives mean(x) bit for bit.
msa_bias_scaled_mean <- function(x) {
  s <- max(abs(x))
  if (s == 0) return(0)
  p <- 2^min(floor(log2(s)), 1023)
  p * mean(x / p)
}

msa_bias_constant <- function(se, mean) {
  se == 0 || se < 10 * .Machine$double.eps * abs(mean)
}

msa_bias_interval <- function(x, level, label) {
  excluded <- sum(is.na(x))
  x <- x[!is.na(x)]
  n <- length(x)
  out <- c(n = n, bias = NA_real_, sd = NA_real_, lower = NA_real_, upper = NA_real_,
           p_value = NA_real_, n_excluded = excluded)
  if (n == 0) return(out)
  out[["bias"]] <- mean(x)
  if (n == 1) return(out)
  centered <- msa_bias_center(x)
  s <- centered$scale * sqrt(sum(centered$z^2) / (n - 1))
  se <- s / sqrt(n)
  out[["sd"]] <- s
  if (msa_bias_constant(se, out[["bias"]])) {
    out[c("lower", "upper")] <- out[["bias"]]
    message("Bias (", label, ") is numerically constant; the interval is a point and the p-value is undefined.")
  } else {
    q <- stats::qt((1 - level) / 2, n - 1, lower.tail = FALSE)
    out[c("lower", "upper")] <- out[["bias"]] + c(-1, 1) * q * se
    out[["p_value"]] <- 2 * stats::pt(-abs(out[["bias"]] / se), n - 1)
  }
  if (any(!is.finite(out[c("bias", "sd", "lower", "upper")]))) {
    stop("Bias calculation (", label, ") exceeds the finite numeric range.", call. = FALSE)
  }
  out
}

# Closed, centered OLS on all deviations or unweighted item means (ADR-052).
msa_bias_regression <- function(x, y, level, label) {
  coefficients <- c(intercept = NA_real_, slope = NA_real_, slope_p_value = NA_real_,
                    r_squared = NA_real_, t_intercept = NA_real_, t_slope = NA_real_,
                    df = NA_real_, t_quantile = NA_real_)
  out <- list(coefficients = coefficients,
              band = data.frame(reference = numeric(), fit = numeric(), lower = numeric(), upper = numeric()),
              in_band = NA, note = character())
  if (length(unique(x)) < 2L) {
    out$note <- paste0(label, " is undefined: reference values have no range.")
    message(out$note)
    return(out)
  }
  n <- length(y)
  xc <- msa_bias_center(x)
  yc <- msa_bias_center(y)
  xx <- sum(xc$z^2)
  yy <- sqrt(sum(yc$z^2))
  b <- sum(xc$z * yc$z) / xx
  slope <- b * (yc$scale / xc$scale)
  if (!is.finite(slope) || slope == 0) slope <- (b * yc$scale) / xc$scale
  intercept <- yc$mean - slope * xc$mean
  if (!is.finite(intercept)) intercept <- yc$scale * (yc$mean / yc$scale - b * (xc$mean / xc$scale))
  if (!all(is.finite(c(slope, intercept)))) {
    stop(label, " coefficients exceed the finite numeric range.", call. = FALSE)
  }
  residual_norm <- sqrt(sum((yc$z - b * xc$z)^2))
  se_mean <- yc$scale * (yy / sqrt(n - 1)) / sqrt(n)
  constant <- msa_bias_constant(se_mean, yc$mean)
  vanished <- residual_norm <= 10 * .Machine$double.eps * yy
  coefficients[c("intercept", "slope", "df")] <- c(intercept, slope, n - 2)
  if (!constant) coefficients[["r_squared"]] <- 1 - (residual_norm / yy)^2
  if (n == 2L) {
    out$coefficients <- coefficients
    out$note <- paste0(label, " has no residual degrees of freedom; inference and the confidence band are undefined.")
    message(out$note)
    return(out)
  }
  sigma <- residual_norm / sqrt(n - 2)
  if (constant || vanished) {
    sigma <- 0
    reason <- if (constant) "numerically constant targets; R-squared, t and p are undefined" else
      "numerically zero residual spread; t and p are undefined"
    out$note <- paste0(label, " has ", reason, "; the confidence band collapses onto the fitted line.")
    message(out$note)
  } else {
    coefficients[["t_slope"]] <- b / (sigma / sqrt(xx))
    coefficients[["t_intercept"]] <- (intercept / yc$scale) /
      (sigma * sqrt(1 / n + (xc$mean / xc$scale)^2 / xx))
    coefficients[["slope_p_value"]] <- 2 * stats::pt(-abs(coefficients[["t_slope"]]), n - 2)
  }
  q <- stats::qt((1 - level) / 2, n - 2, lower.tail = FALSE)
  coefficients[["t_quantile"]] <- q
  at <- sort(unique(x))
  z <- at - xc$mean
  z <- if (all(is.finite(z))) z / xc$scale else at / xc$scale - xc$mean / xc$scale
  fit <- yc$mean + yc$scale * (b * z)
  half <- yc$scale * (q * sigma * sqrt(1 / n + z^2 / xx))
  band <- data.frame(reference = at, fit = fit, lower = fit - half, upper = fit + half)
  if (any(!is.finite(as.matrix(band)))) {
    stop(label, " confidence band exceeds the finite numeric range.", call. = FALSE)
  }
  out$coefficients <- coefficients
  out$band <- band
  out$in_band <- msa_bias_in_band(yc$mean / yc$scale, b, q * sigma, xx, n, range(z))
  out
}

# Zero is in the band iff this quadratic never exceeds zero. Its maximum
# is at an endpoint or, for a concave quadratic, at its interior vertex.
# Rescaling the coefficients avoids overflow/underflow without a tolerance.
msa_bias_in_band <- function(mean, slope, width, sxx, n, range) {
  scale <- max(abs(mean), abs(slope), width)
  if (scale == 0) return(TRUE)
  mean <- mean / scale
  slope <- slope / scale
  width <- width / scale
  a <- slope^2 - width^2 / sxx
  candidates <- range
  if (a < 0) {
    vertex <- -mean * slope / a
    if (vertex > range[1] && vertex < range[2]) candidates <- c(candidates, vertex)
  }
  all((mean + slope * candidates)^2 - width^2 * (1 / n + candidates^2 / sxx) <= 0)
}

#' @export
print.msa_bias <- function(x, ...) {
  o <- x$overall
  cat(sprintf("Bias against reference (%d items, %d values)\n", x$n_items, as.integer(o[["n"]])))
  excluded <- if ("n_excluded" %in% names(o)) format(o[["n_excluded"]], scientific = FALSE) else "not recorded"
  cat(sprintf("  Excluded response-reference pairs: %s\n", excluded))
  cat(sprintf("  mean bias %.4f  [%.0f %% CI %.4f, %.4f]  sd %.4f  p = %.3g\n",
              o[["bias"]], 100 * x$level, o[["lower"]], o[["upper"]], o[["sd"]], o[["p_value"]]))
  b <- x$by_condition
  if (!"n_excluded" %in% names(b)) b$n_excluded <- "not recorded"
  for (nm in c("bias", "sd", "lower", "upper")) b[[nm]] <- fmt_num(b[[nm]])
  b$p_value <- formatC(b$p_value, digits = 3, format = "g")
  print(b, row.names = FALSE)
  l <- x$linearity
  cat(sprintf("  Handbook linearity: bias = %.4f + %.4f * reference (slope p = %.3g)\n",
              l[["intercept"]], l[["slope"]], l[["slope_p_value"]]))
  if ("df" %in% names(l)) {
    cat(sprintf("    R-squared %.4f; t intercept %.3f; t slope %.3f; df %.0f; t quantile %.4f\n",
                l[["r_squared"]], l[["t_intercept"]], l[["t_slope"]], l[["df"]], l[["t_quantile"]]))
  }
  m <- x$linearity_item_means
  if (!is.null(m)) {
    cat(sprintf("  Item means: bias = %.4f + %.4f * reference; R-squared %.4f; t intercept %.3f; t slope %.3f; df %.0f\n",
                m[["intercept"]], m[["slope"]], m[["r_squared"]], m[["t_intercept"]], m[["t_slope"]], m[["df"]]))
  }
  verdict <- x$linearity_verdict
  if (is.null(verdict)) verdict <- "not recorded" else if (is.na(verdict)) verdict <- "undetermined"
  cat(sprintf("  Handbook linearity verdict: %s\n", verdict))
  if (!is.null(x$linearity_note)) cat(x$linearity_note, "\n", sep = "")
  invisible(x)
}
