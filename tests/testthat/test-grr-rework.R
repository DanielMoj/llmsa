test_that("GRR thresholds validate their domain and retain exact boundary classification", {
  f <- rework_display_fit()
  message <- "`threshold` must contain two finite, nonnegative, nondecreasing numbers."
  bad <- list(numeric(), 10, c(10, 20, 30), c(NA_real_, 30), c(10, NaN), c(10, Inf),
               c(-Inf, 30), c(-1, 30), c(30, 10), "invalid", factor(c("10", "30")), c(TRUE, FALSE),
               c(1 + 1i, 2), matrix(c(1, 2), nrow = 1), list(1, 2))
  for (threshold in bad) rework_error(msa_grr(f, threshold = threshold), message)
  f$vc$variance <- c(99, 1)
  expect_identical(msa_grr(f, threshold = c(0, 10))$verdict, "marginal")
  expect_identical(msa_grr(f, threshold = c(10, 10))$verdict, "marginal")
  expect_identical(msa_grr(f, threshold = c(0, 0))$verdict, "unacceptable")
  expect_identical(msa_grr(f, threshold = c(11, 12))$verdict, "acceptable")
  expect_identical(msa_grr(f, threshold = c(10L, 30L))$threshold, c(10L, 30L))
  rework_error(msa_grr(list()), "`fit` must come from msa_fit().")
})

test_that("GRR table labels, types and null results follow the component contract", {
  f <- rework_display_fit()
  g <- msa_grr(f)
  expect_type(g$table$source, "character")
  expect_identical(g$table$source, c("Total gauge R&R", "  Repeatability", "  Reproducibility",
                                     "Part-to-part (items)", "Total variation"))
  expected <- c(1 / 7, 1 / 7, 0, 4 / 3, 4 / 3 + 1 / 7)
  tolerance <- numeric_tolerance("arithmetic", "abs_tol")
  expect_equal(g$table$variance, expected, tolerance = tolerance)
  expect_equal(g$table$sd, sqrt(expected), tolerance = tolerance)
  expect_equal(g$table$pct_contribution, 100 * expected / tail(expected, 1), tolerance = tolerance)
  expect_equal(g$table$pct_study_var, 100 * sqrt(expected / tail(expected, 1)), tolerance = tolerance)
  anchor <- numeric_anchor("ANK-16")
  total <- 4 / 3 + 1 / 7
  expect_equal(g$summary, c(grr_pct_study_var = 100 * sqrt((1 / 7) / total),
    grr_pct_contribution = 100 * (1 / 7) / total,
    repeatability_pct_study_var = 100 * sqrt((1 / 7) / total), reproducibility_pct_study_var = 0,
    ndc = max(anchor$ndc$minimum, floor(anchor$ndc$constant * sqrt((4 / 3) / (1 / 7)))),
    icc_items = (4 / 3) / total), tolerance = tolerance)
  expect_identical(g$threshold, as.numeric(c(anchor$study_var$acceptable_below, anchor$study_var$unacceptable_above)))
  expect_gt(g$summary[["grr_pct_study_var"]], anchor$study_var$unacceptable_above)
  expect_identical(g$verdict, "unacceptable")
  # Include every optional reproducibility source. The labels characterize
  # the reporting contract; the accompanying variances follow the sum rule.
  all_sources <- f
  all_sources$vc <- data.frame(source = c("item", "Residual", "prompt", "model", "block", "prompt:model", "item:prompt", "item:model"),
    variance = c(4 / 3, 1 / 7, 1 / 4, 1 / 5, 1 / 6, 1 / 8, 1 / 9, 1 / 10))
  all <- msa_grr(all_sources)
  expect_identical(all$table$source, c("Total gauge R&R", "  Repeatability", "  Reproducibility",
    "    prompt", "    model", "    block (time)", "    prompt:model", "    item:prompt", "    item:model",
    "Part-to-part (items)", "Total variation"))
  reproducibility <- 1 / 4 + 1 / 5 + 1 / 6 + 1 / 8 + 1 / 9 + 1 / 10
  expect_equal(all$table$variance, c(reproducibility + 1 / 7, 1 / 7, reproducibility,
    1 / 4, 1 / 5, 1 / 6, 1 / 8, 1 / 9, 1 / 10, 4 / 3, reproducibility + 1 / 7 + 4 / 3), tolerance = tolerance)
  f$vc$variance <- 0
  zero <- msa_grr(f)
  expect_identical(unname(zero$summary), rep(NA_real_, 6))
  expect_identical(zero$table$pct_contribution, rep(NA_real_, 5))
  expect_identical(zero$table$pct_study_var, rep(NA_real_, 5))
})

test_that("fit print shows counts, formula, percentages and both reporting notes", {
  f <- rework_display_fit()
  # Own-output snapshot for wording and table layout only. The values are
  # constructed rationals, independently checked by the GRR formula test above.
  expected <- c("Variance components of an LLM measurement system (numeric outcome)",
    "  formula: y ~ 1 + (1 | item)",
    "  6 items x 3 prompts x 2 models x 4 block(s); 37 observations; 2-5 valid replicates per cell",
    "   source variance     sd    pct", "     item   1.3333 1.1547 90.3 %", " Residual   0.1429 0.3780  9.7 %")
  output <- capture.output(returned <- withVisible(print(f)))
  expect_identical(output, expected)
  expect_identical(returned, list(value = f, visible = FALSE))
  expect_identical(capture.output(summary(f)), expected)
  f$vc$variance <- 0
  expected[4:6] <- c("   source variance     sd pct", "     item   0.0000 0.0000  NA", " Residual   0.0000 0.0000  NA")
  expect_identical(capture.output(print(f)), expected)
  for (type in c("ordinal", "binary")) for (link in c("logit", "probit")) {
    f$type <- type
    f$link <- link
    expect_identical(capture.output(print(f))[1L],
                     sprintf("Variance components of an LLM measurement system (%s outcome, %s link, latent scale)", type, link))
  }
  for (groups in list("model", c("model", "block"))) {
    f$derived <- groups
    f$singular <- TRUE
    note <- c(paste0("note: ", paste(groups, collapse = ", "),
                      if (length(groups) == 1L) " has" else " have",
                      " only two levels and entered as fixed effect(s); the component is derived from the"),
              "      estimated difference by the range method (beta^2 / 2), as in the AIAG X-bar/R procedure.",
              "note: singular fit (at least one variance estimated at zero). With few prompt or model levels this is expected;",
              "      report bootstrap intervals (msa_boot) and consider a larger study (msa_plan).")
    expect_identical(tail(capture.output(print(f)), 4L), note)
  }
})

test_that("GRR print exposes its basis, thresholds, precision and latent-scale status", {
  f <- rework_display_fit()
  g <- msa_grr(f)
  # Own-output snapshot: wording/alignment have no independent reference.
  expected <- c("Gauge R&R of an LLM measurement system",
    "  outcome: numeric; 6 items x 3 prompts x 2 models x 4 block(s), 37 observations",
    " Source               Variance SD     % Contribution % Study Var",
    " Total gauge R&R      0.1429   0.3780 9.7 %          31.1 %",
    "   Repeatability      0.1429   0.3780 9.7 %          31.1 %",
    "   Reproducibility    0.0000   0.0000 0.0 %          0.0 %",
    " Part-to-part (items) 1.3333   1.1547 90.3 %         95.0 %",
    " Total variation      1.4762   1.2150 100.0 %        100.0 %", "",
    "  total gauge R&R: 31.1 % of study variation (9.7 % contribution)",
    "  number of distinct categories (ndc): 4", "  ICC (items): 0.903",
    "  verdict: UNACCEPTABLE  [basis: % study variation, thresholds 10 / 30]")
  output <- capture.output(returned <- withVisible(print(g)))
  # Ignore trailing padding only; column alignment and row names are checked.
  expect_identical(sub(" +$", "", output), expected)
  expect_identical(returned, list(value = g, visible = FALSE))
  expect_match(capture.output(print(g, digits = 2))[4L], "0.14     0.38", fixed = TRUE)
  f$type <- "binary"
  f$singular <- TRUE
  contribution <- msa_grr(f, basis = "contribution", threshold = c(3, 11))
  output <- capture.output(print(contribution))
  expect_identical(output[2L], "  outcome: binary (latent scale); 6 items x 3 prompts x 2 models x 4 block(s), 37 observations")
  expect_identical(tail(output, 2L), c("  verdict: MARGINAL  [basis: % contribution, thresholds 3 / 11]",
                                      "  note: singular fit, see ?msa_fit"))
})

test_that("bootstrap percentile endpoints match independent quantiles at both confidence levels", {
  f <- suppressMessages(msa_fit(numeric_test_runs()))
  for (level in c(0.8, 0.6)) {
    b <- msa_boot(f, nsim = 7, level = level, seed = 20261029L)
    replicates <- attr(b, "boot")
    expected <- vapply(seq_len(ncol(replicates)), function(j) {
      finite <- sort(replicates[is.finite(replicates[, j]), j])
      stats::quantile(finite, probs = c((1 - level) / 2, (1 + level) / 2), names = FALSE)
    }, numeric(2))
    expect_equal(b$lower, expected[1L, ], tolerance = numeric_tolerance("arithmetic", "abs_tol"))
    expect_equal(b$upper, expected[2L, ], tolerance = numeric_tolerance("arithmetic", "abs_tol"))
    expect_identical(class(b), c("msa_boot", "data.frame"))
    expect_type(b$statistic, "character")
    expect_identical(b$statistic, names(msa_grr(f)$summary))
    expect_identical(attr(b, "level"), level)
    expect_identical(attr(b, "n_failed"), sum(!stats::complete.cases(replicates)))
  }
  rework_error(msa_boot(list()), "`fit` must come from msa_fit().")
  f$model <- structure(list(), class = "clmm")
  rework_error(msa_boot(f), "msa_boot() supports numeric and binary fits (lme4). See ?msa_boot for ordinal outcomes.")
})

test_that("bootstrap print retains intervals, confidence level and failure counts", {
  # Own-output snapshot of display wording, using explicitly synthetic
  # statistics and rational values instead of fitted-output snapshots.
  b <- data.frame(statistic = c("grr_pct_study_var", "icc_items"), estimate = c(100 / 3, 2 / 3),
                   lower = c(25, 1 / 2), upper = c(50, 3 / 4))
  attr(b, "boot") <- matrix(0, 4, 2)
  attr(b, "level") <- 0.8
  attr(b, "n_failed") <- 0L
  class(b) <- c("msa_boot", "data.frame")
  expected <- c("Parametric bootstrap, 4 replicates, 80 % percentile intervals",
    "         statistic estimate lower upper", " grr_pct_study_var    33.33 25.00 50.00",
    "         icc_items     0.67  0.50  0.75")
  output <- capture.output(returned <- withVisible(print(b)))
  expect_identical(output, expected)
  expect_identical(returned, list(value = b, visible = FALSE))
  for (failed in c(1L, 2L)) {
    attr(b, "n_failed") <- failed
    expect_identical(capture.output(print(b)), c(expected,
      sprintf("  (%d replicate fits failed or were singular and were dropped)", failed)))
  }
})
