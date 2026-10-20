#' Gauge repeatability and reproducibility of an LLM pipeline
#'
#' Turns the variance components of an [msa_fit()] into the statistics that
#' a measurement-system analysis reports. The vocabulary follows the AIAG
#' *Measurement Systems Analysis* manual:
#'
#' * **Repeatability**: the residual variance, i.e. variation between
#'   replicate calls under identical conditions (same item, prompt, model).
#' * **Reproducibility**: variation attributable to the measurement
#'   conditions, here prompt variant, model, block (time) and their
#'   interactions with each other and with the items.
#' * **Total gauge R&R**: repeatability + reproducibility, the variance the
#'   pipeline adds to a result.
#' * **Part-to-part**: the variance between items, the signal the pipeline
#'   is meant to resolve.
#'
#' Two ratios are reported for every source: the *percent contribution*
#' (variance / total variance) and the *percent study variation* (standard
#' deviation / total standard deviation). The AIAG rule of thumb classifies
#' a system by the percent study variation of total gauge R&R: below 10 %
#' acceptable, 10-30 % marginal (may be acceptable depending on the
#' application, cost and risk), above 30 % unacceptable. The number of
#' distinct categories (ndc) is `floor(1.41 * sd_items / sd_grr)`; a system
#' should resolve at least 5. Thresholds should be set from the model risk
#' of the context of use, not taken as universal constants.
#'
#' @param fit An `msa_fit`.
#' @param threshold Length-two vector of thresholds (acceptable / marginal)
#'   on the chosen basis, in percent.
#' @param basis `"study_var"` classifies by percent study variation (default,
#'   thresholds 10 and 30), `"contribution"` by percent contribution
#'   (typical thresholds 1 and 9).
#'
#' @return An object of class `msa_grr` with elements `table` (one row per
#'   source), `summary` (named vector: `grr_pct_study_var`,
#'   `grr_pct_contribution`, `repeatability_pct_study_var`,
#'   `reproducibility_pct_study_var`, `ndc`, `icc_items`), `verdict`, the
#'   thresholds and the outcome type.
#' @examples
#' g <- msa_grr(msa_fit(ic50_demo, type = "numeric"))
#' g
#' g$summary
#' @export
msa_grr <- function(fit, threshold = NULL, basis = c("study_var", "contribution")) {
  if (!inherits(fit, "msa_fit")) stop("`fit` must come from msa_fit().", call. = FALSE)
  basis <- match.arg(basis)
  if (is.null(threshold)) threshold <- if (basis == "study_var") c(10, 30) else c(1, 9)
  res <- grr_stats(fit$vc)
  tab <- res$table
  s <- res$summary
  crit <- if (basis == "study_var") s[["grr_pct_study_var"]] else s[["grr_pct_contribution"]]
  verdict <- if (is.na(crit)) "undetermined" else if (crit < threshold[1]) "acceptable" else
    if (crit <= threshold[2]) "marginal" else "unacceptable"
  structure(list(table = tab, summary = s, verdict = verdict, threshold = threshold,
                 basis = basis, type = fit$type, link = fit$link, singular = fit$singular,
                 n = fit$n),
            class = "msa_grr")
}

# Core computation shared with the bootstrap: variance components -> GRR table
grr_stats <- function(vc) {
  v <- stats::setNames(vc$variance, vc$source)
  get <- function(nm) if (nm %in% names(v)) unname(v[[nm]]) else NA_real_
  repeat_v <- get("Residual")
  item_v <- get("item")
  repro_sources <- c("prompt", "model", "block", "prompt:model", "item:prompt", "item:model")
  repro_parts <- stats::setNames(vapply(repro_sources, get, numeric(1)), repro_sources)
  repro_v <- sum(repro_parts, na.rm = TRUE)
  grr_v <- repeat_v + repro_v
  total_v <- grr_v + item_v
  rows <- c("Total gauge R&R" = grr_v, "  Repeatability" = repeat_v,
            "  Reproducibility" = repro_v,
            stats::setNames(repro_parts, paste0("    ", c("prompt", "model", "block (time)",
                                                        "prompt:model", "item:prompt", "item:model"))),
            "Part-to-part (items)" = item_v, "Total variation" = total_v)
  rows <- rows[!is.na(rows)]
  tab <- data.frame(source = names(rows), variance = unname(rows),
                    sd = sqrt(unname(rows)),
                    pct_contribution = 100 * unname(rows) / total_v,
                    pct_study_var = 100 * sqrt(unname(rows)) / sqrt(total_v),
                    stringsAsFactors = FALSE)
  ndc <- if (grr_v > 0) floor(1.41 * sqrt(item_v) / sqrt(grr_v)) else Inf
  s <- c(grr_pct_study_var = 100 * sqrt(grr_v / total_v),
         grr_pct_contribution = 100 * grr_v / total_v,
         repeatability_pct_study_var = 100 * sqrt(repeat_v / total_v),
         reproducibility_pct_study_var = 100 * sqrt(repro_v / total_v),
         ndc = ndc, icc_items = item_v / total_v)
  list(table = tab, summary = s)
}

#' @export
print.msa_grr <- function(x, digits = 4, ...) {
  cat("Gauge R&R of an LLM measurement system\n")
  cat(sprintf("  outcome: %s%s; %d items x %d prompts x %d models x %d block(s), %d observations\n",
              x$type, if (x$type != "numeric") " (latent scale)" else "",
              x$n$items, x$n$prompts, x$n$models, x$n$blocks, x$n$observations))
  tab <- x$table
  out <- data.frame(Source = tab$source, Variance = fmt_num(tab$variance, digits),
                    SD = fmt_num(tab$sd, digits), `% Contribution` = fmt_pct(tab$pct_contribution),
                    `% Study Var` = fmt_pct(tab$pct_study_var), check.names = FALSE)
  print(out, row.names = FALSE, right = FALSE)
  s <- x$summary
  cat(sprintf("\n  total gauge R&R: %.1f %% of study variation (%.1f %% contribution)\n",
              s[["grr_pct_study_var"]], s[["grr_pct_contribution"]]))
  cat(sprintf("  number of distinct categories (ndc): %s\n",
              if (is.finite(s[["ndc"]])) format(s[["ndc"]]) else "Inf"))
  cat(sprintf("  ICC (items): %.3f\n", s[["icc_items"]]))
  cat(sprintf("  verdict: %s  [basis: %s, thresholds %g / %g]\n", toupper(x$verdict),
              if (x$basis == "study_var") "% study variation" else "% contribution",
              x$threshold[1], x$threshold[2]))
  if (isTRUE(x$singular)) cat("  note: singular fit, see ?msa_fit\n")
  invisible(x)
}

#' Bootstrap intervals for gauge R&R statistics
#'
#' Parametric bootstrap of the fitted mixed model ([lme4::bootMer()]):
#' the model is simulated `nsim` times, refitted and the gauge R&R
#' statistics recomputed. Percentile intervals are returned. With few
#' prompt or model levels the intervals are wide and asymmetric, which is
#' the honest answer; [msa_plan()] shows how study size changes this.
#'
#' Available for numeric and binary outcomes (lme4 models). For ordinal
#' outcomes fitted with `ordinal::clmm` a parametric bootstrap is not yet
#' implemented; as a pragmatic alternative, score the categories numerically
#' and fit `type = "numeric"`, or treat the top category as a binary
#' outcome.
#'
#' @param fit An `msa_fit` of type numeric or binary.
#' @param nsim Number of bootstrap samples.
#' @param level Confidence level.
#' @param seed Optional seed.
#' @param ... Passed to [lme4::bootMer()], e.g. `parallel = "multicore"`.
#' @return A data.frame with the point estimate and interval for each
#'   statistic, plus the bootstrap replicates as attribute `boot`.
#' @examples
#' \donttest{
#' fit <- msa_fit(ic50_demo, type = "numeric")
#' msa_boot(fit, nsim = 50, seed = 1)
#' }
#' @export
msa_boot <- function(fit, nsim = 200, level = 0.95, seed = NULL, ...) {
  if (!inherits(fit, "msa_fit")) stop("`fit` must come from msa_fit().", call. = FALSE)
  if (!inherits(fit$model, "merMod")) {
    stop("msa_boot() supports numeric and binary fits (lme4). See ?msa_boot for ordinal outcomes.",
         call. = FALSE)
  }
  type <- fit$type; link <- fit$link
  stat_fun <- function(m) grr_stats(vc_from_model(m, type, link))$summary
  est <- stat_fun(fit$model)
  b <- lme4::bootMer(fit$model, FUN = stat_fun, nsim = nsim, seed = seed, type = "parametric", ...)
  t <- b$t
  colnames(t) <- names(est)
  a <- (1 - level) / 2
  ci <- t(apply(t, 2, function(col) stats::quantile(col[is.finite(col)], c(a, 1 - a), na.rm = TRUE)))
  out <- data.frame(statistic = names(est), estimate = unname(est),
                    lower = ci[, 1], upper = ci[, 2], stringsAsFactors = FALSE)
  rownames(out) <- NULL
  attr(out, "boot") <- t
  attr(out, "level") <- level
  attr(out, "n_failed") <- sum(!stats::complete.cases(t))
  class(out) <- c("msa_boot", "data.frame")
  out
}

#' @export
print.msa_boot <- function(x, ...) {
  cat(sprintf("Parametric bootstrap, %d replicates, %.0f %% percentile intervals\n",
              nrow(attr(x, "boot")), 100 * attr(x, "level")))
  d <- as.data.frame(x)
  d$estimate <- fmt_num(d$estimate, 2); d$lower <- fmt_num(d$lower, 2); d$upper <- fmt_num(d$upper, 2)
  print(d, row.names = FALSE)
  if (attr(x, "n_failed") > 0) cat(sprintf("  (%d replicate fits failed or were singular and were dropped)\n", attr(x, "n_failed")))
  invisible(x)
}
