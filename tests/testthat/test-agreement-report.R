# Output-format tests: expected lines are formatted from independently tested
# result fields. These checks do not substitute for numerical validation.
m3a_print_agreement_expected <- function(x) {
  rt <- x$repeatability
  rt$pct_items_consistent <- ifelse(is.na(rt$pct_items_consistent), "NA",
                                   paste0(formatC(rt$pct_items_consistent, format = "f", digits = 1), " %"))
  al <- x$alpha
  al$alpha <- ifelse(is.na(al$alpha), "NA", formatC(al$alpha, format = "f", digits = 3))
  r <- x$reproducibility
  out <- c("Attribute agreement of an LLM measurement system",
           sprintf("  %d items, %d responses (%d missing/unparseable); categories: %s; weights: %s",
                   x$n[["items"]], x$n[["responses"]], x$n[["missing"]], paste(x$levels, collapse = " < "), x$weights),
           "", sprintf("Repeatability: %.1f %% of item-prompt-model cells have identical replicates", x$repeatability_overall),
           utils::capture.output(print(rt, row.names = FALSE)), "",
           sprintf("Reproducibility: items consistent across prompts %.1f %%, across models %.1f %%, overall %.1f %%", r[[1]], r[[2]], r[[3]]),
           "", "Krippendorff's alpha:", utils::capture.output(print(al, row.names = FALSE)))
  if (!is.null(x$fleiss)) out <- c(out, "", sprintf("Fleiss' kappa: %.3f", x$fleiss$kappa))
  if (!is.null(x$accuracy)) {
    at <- x$accuracy
    at$pct_correct <- ifelse(is.na(at$pct_correct), "NA", paste0(formatC(at$pct_correct, format = "f", digits = 1), " %"))
    out <- c(out, "", sprintf("Accuracy vs reference: %.1f %% of responses correct; %.1f %% of items correct in every call",
                              x$accuracy_overall, x$pct_items_all_correct),
             utils::capture.output(print(at, row.names = FALSE)),
             sprintf("  Cohen's kappa (%s): modal response vs reference %.3f; all responses vs reference %.3f",
                     x$weights, x$kappa[[1]], x$kappa[[2]]))
  }
  out
}

m3a_print_bias_expected <- function(x) {
  o <- x$overall
  excluded <- if ("n_excluded" %in% names(o)) format(o[["n_excluded"]], scientific = FALSE) else "not recorded"
  bc <- x$by_condition
  if (!"n_excluded" %in% names(bc)) bc$n_excluded <- "not recorded"
  for (nm in c("bias", "sd", "lower", "upper")) bc[[nm]] <- ifelse(is.na(bc[[nm]]), "NA", formatC(bc[[nm]], format = "f", digits = 4))
  bc$p_value <- formatC(bc$p_value, digits = 3, format = "g")
  l <- x$linearity
  out <- c(sprintf("Bias against reference (%d items, %d values)", x$n_items, as.integer(o[["n"]])),
           paste0("  Excluded response-reference pairs: ", excluded),
           sprintf("  mean bias %.4f  [%.0f %% CI %.4f, %.4f]  sd %.4f  p = %.3g",
                   o[["bias"]], 100 * x$level, o[["lower"]], o[["upper"]], o[["sd"]], o[["p_value"]]),
           utils::capture.output(print(bc, row.names = FALSE)),
           sprintf("  Handbook linearity: bias = %.4f + %.4f * reference (slope p = %.3g)", l[["intercept"]], l[["slope"]], l[["slope_p_value"]]))
  if ("df" %in% names(l)) out <- c(out, sprintf("    R-squared %.4f; t intercept %.3f; t slope %.3f; df %.0f; t quantile %.4f",
                                               l[["r_squared"]], l[["t_intercept"]], l[["t_slope"]], l[["df"]], l[["t_quantile"]]))
  m <- x$linearity_item_means
  if (!is.null(m)) out <- c(out, sprintf("  Item means: bias = %.4f + %.4f * reference; R-squared %.4f; t intercept %.3f; t slope %.3f; df %.0f",
                                       m[["intercept"]], m[["slope"]], m[["r_squared"]], m[["t_intercept"]], m[["t_slope"]], m[["df"]]))
  verdict <- if (is.null(x$linearity_verdict)) "not recorded" else
    if (is.na(x$linearity_verdict)) "undetermined" else x$linearity_verdict
  c(out, paste0("  Handbook linearity verdict: ", verdict), x$linearity_note)
}

m3a_report_bias <- function(constant = FALSE, one_reference = FALSE) {
  d <- expand.grid(rep = seq_len(3), item = seq_len(5))
  d$item_id <- paste0("i", d$item)
  d$prompt_id <- "p"
  d$model_id <- "m"
  d$reference <- if (one_reference) rep(2, nrow(d)) else d$item * 2
  delta <- if (constant) rep(0, nrow(d)) else
    0.1 * d$item + c(-0.2, 0.4, -0.3)[d$rep] + c(0.05, -0.1, 0, 0.1, -0.2)[d$item]
  d$value <- d$reference + delta
  d$value[c(1, 4)] <- NA_real_
  suppressMessages(msa_bias(d, "reference"))
}

test_that("agreement print formatting covers all optional fields and a final newline", {
  d <- expand.grid(rep = 1:2, prompt_id = c("p", "q"), model_id = c("m", "n"),
                    item_id = c("i1", "i2"), stringsAsFactors = FALSE)
  d$value <- rep(c("a", "a", "b", "c", "a", "b", "a", "b"), each = 2)
  for (reference in list(NULL, c(i1 = "a", i2 = "b"))) for (fleiss in c(FALSE, TRUE)) {
    a <- msa_agreement(d, levels = c("a", "b", "c"), reference = reference, weights = "quadratic", fleiss = fleiss)
    # Distinct hand-counted rates make swapped output labels observable.
    expect_identical(unname(a$reproducibility), c(25, 50, 0))
    expected <- m3a_print_agreement_expected(a)
    expect_identical(utils::capture.output(print(a)), expected)
    expect_identical(utils::capture.output({ print(a); cat("|\n") }), c(expected, "|"))
    utils::capture.output(visible <- withVisible(print(a)))
    expect_false(visible$visible)
    expect_identical(visible$value, a)
  }
  d$value[] <- NA_character_
  empty <- suppressMessages(msa_agreement(d, levels = c("a", "b", "c"), fleiss = TRUE))
  expect_identical(utils::capture.output(print(empty)), m3a_print_agreement_expected(empty))
  old <- empty
  old$alpha$n_units_excluded <- NULL
  old$fleiss <- NULL
  expect_identical(utils::capture.output(print(old)), m3a_print_agreement_expected(old))
})

test_that("bias print formatting covers undefined inference, exclusions and old objects", {
  objects <- list(m3a_report_bias(), m3a_report_bias(constant = TRUE), m3a_report_bias(one_reference = TRUE))
  old <- objects[[1]]
  old$overall <- old$overall[setdiff(names(old$overall), "n_excluded")]
  old$by_condition$n_excluded <- NULL
  old$linearity <- old$linearity[c("intercept", "slope", "slope_p_value")]
  old <- old[c("overall", "by_condition", "linearity", "level", "n_items")]
  class(old) <- "msa_bias"
  objects <- c(objects, list(old))
  for (b in objects) {
    expected <- m3a_print_bias_expected(b)
    expect_identical(utils::capture.output(print(b)), expected)
    expect_identical(utils::capture.output({ print(b); cat("|\n") }), c(expected, "|"))
    utils::capture.output(visible <- withVisible(print(b)))
    expect_false(visible$visible)
    expect_identical(visible$value, b)
  }
  expect_match(paste(utils::capture.output(print(old)), collapse = "\n"), "not recorded", fixed = TRUE)
})

test_that("bias and agreement messages state their reasons and affected analyses", {
  collect <- function(expr) {
    messages <- character()
    withCallingHandlers(expr, message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    })
    messages
  }
  expect_identical(collect(cohen_kappa("a", "a", "a")),
                   "Cohen's kappa is undefined: fewer than two scale categories.\n")
  expect_identical(collect(cohen_kappa("a", "a", c("a", "b"))),
                   "Cohen's kappa is undefined: expected agreement is one.\n")
  expect_identical(collect(cohen_kappa(NA, NA, c("a", "b"))),
                   "Cohen's kappa is undefined: no valid response-reference pairs.\n")
  expect_identical(collect(msa_fleiss_kappa(c("a", "b", "b"), c("u", "u", "v"), c("a", "b"))),
                   "Fleiss' kappa requires equal valid rating counts for every item; use Krippendorff's alpha for unequal counts.\n")
  expect_identical(collect(msa_fleiss_kappa(c("a", "b"), c("u", "v"), c("a", "b"))),
                   "Fleiss' kappa is undefined: fewer than two valid ratings per item.\n")
  expect_identical(collect(msa_fleiss_kappa(rep("a", 4), rep(c("u", "v"), each = 2), c("a", "b"))),
                   "Fleiss' kappa is undefined: all valid ratings use the same category.\n")
  expect_identical(collect(msa_bias_interval(c(1, 1, 1), 0.95, "overall")),
                   "Bias (overall) is numerically constant; the interval is a point and the p-value is undefined.\n")
  expect_identical(collect(msa_bias_regression(1:4, rep(0, 4), 0.95, "Handbook regression")),
                   "Handbook regression has numerically constant targets; R-squared, t and p are undefined; the confidence band collapses onto the fitted line.\n")
  expect_identical(collect(msa_bias_regression(1:4, 1:4, 0.95, "Regression on item means")),
                   "Regression on item means has numerically zero residual spread; t and p are undefined; the confidence band collapses onto the fitted line.\n")
  expect_identical(collect(msa_bias_regression(c(1, 2), c(1, 3), 0.95, "Handbook regression")),
                   "Handbook regression has no residual degrees of freedom; inference and the confidence band are undefined.\n")
  expect_identical(collect(msa_bias_regression(rep(1, 3), 1:3, 0.95, "Handbook regression")),
                   "Handbook regression is undefined: reference values have no range.\n")
})

test_that("reports render both regressions, valid and excluded counts, and modal policy", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")
  grr <- msa_grr(suppressMessages(msa_fit(ic50_demo, type = "numeric")))
  d <- data.frame(item_id = rep(c("a", "b", "c"), each = 2), prompt_id = "p", model_id = "m",
                  rep = rep(1:2, 3), value = c("a", "b", "b", "b", "c", "c"))
  a <- msa_agreement(d, levels = c("a", "b", "c"), reference = c(a = "a", b = "b", c = "c"), fleiss = TRUE)
  b <- m3a_report_bias()
  render <- function(bias) {
    out <- tempfile(fileext = ".md")
    on.exit(unlink(out), add = TRUE)
    msa_report(grr, agreement = a, bias = bias, output_file = out,
               output_format = rmarkdown::md_document(variant = "gfm", pandoc_args = "--wrap=none"))
    readLines(out, warn = FALSE)
  }
  lines <- render(b)
  text <- gsub("\u2019", "'", paste(lines, collapse = "\n"), fixed = TRUE)
  expect_match(text, "lowest tied category", fixed = TRUE)
  expect_match(text, "AP1 decision metrics use acmg_modal()", fixed = TRUE)
  expect_match(text, "missing answers as a category and excludes ties", fixed = TRUE)
  expect_match(text, sprintf("Fleiss' kappa: %.3f", a$fleiss$kappa), fixed = TRUE)
  expect_match(text, sprintf("Valid response-reference pairs: %d; excluded: %d.", b$overall[["n"]], b$overall[["n_excluded"]]), fixed = TRUE)
  expect_match(text, sprintf("Mean bias %.4f", b$overall[["bias"]]), fixed = TRUE)
  expect_match(text, "Unweighted item means", fixed = TRUE)
  expect_match(text, "n_excluded", fixed = TRUE)
  expect_match(text, b$linearity_note, fixed = TRUE)
  expect_match(text, paste0("Handbook linearity verdict: **", b$linearity_verdict, "**"), fixed = TRUE)
  for (field in c("linearity", "linearity_item_means")) for (key in c("r_squared", "t_intercept", "t_slope")) {
    expect_match(text, sprintf("%.4f", b[[field]][[key]]), fixed = TRUE)
  }
  undef <- m3a_report_bias(one_reference = TRUE)
  text <- paste(render(undef), collapse = "\n")
  expect_match(text, "reference values have no range", fixed = TRUE)
  expect_match(text, "Handbook linearity verdict: **undetermined**", fixed = TRUE)
  old <- b[c("overall", "by_condition", "linearity", "level", "n_items")]
  old$overall <- old$overall[setdiff(names(old$overall), "n_excluded")]
  old$by_condition$n_excluded <- NULL
  old$linearity <- old$linearity[c("intercept", "slope", "slope_p_value")]
  class(old) <- "msa_bias"
  text <- paste(render(old), collapse = "\n")
  expect_match(text, "excluded: not recorded", fixed = TRUE)
  expect_match(text, "Handbook linearity verdict: **not recorded**", fixed = TRUE)
})
