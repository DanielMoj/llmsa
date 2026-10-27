test_that("the validation report renders", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")
  skip_on_cran()
  fit <- msa_fit(ic50_demo, type = "numeric")
  lv <- c("B", "LB", "VUS", "LP", "P")
  ag <- msa_agreement(acmg_demo, levels = lv, reference = "reference")
  d <- pb_design(list(a = c(0, 1), b = c(0, 1), c = c(0, 1)), seed = 1)
  ro <- msa_robustness(d, c(0.9, 0.91, 0.8, 0.92, 0.81, 0.9, 0.79, 0.93))
  out <- tempfile(fileext = ".html")
  res <- msa_report(msa_grr(fit), runs = ic50_demo, agreement = ag,
                    bias = msa_bias(ic50_demo, "reference"), robustness = ro,
                    cou = "test", question = "test?", risk = "low", acceptance = "none",
                    output_file = out)
  expect_true(file.exists(out))
  html <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_true(grepl("Total gauge R&amp;R|Total gauge R&R", html))
  expect_true(grepl("Krippendorff", html))
  expect_true(grepl("Traceability", html))
})

test_that("assessment is validated before rendering and does not alter the generic API defaults", {
  grr <- structure(list(), class = "msa_grr")
  valid <- list(criteria = data.frame(criterion = "synthetic criterion", band = "not assessed"),
                verdict = "not assessed", sections = list(Note = list(text = "Synthetic note")))
  expect_invisible(validate_assessment(valid))
  for (bad in list(list(), within(valid, rm(verdict)), within(valid, criteria <- list()),
                   within(valid, verdict <- NA_character_), within(valid, sections <- list(list(text = "unnamed"))),
                   within(valid, sections <- list(Note = list(text = "x", table = 1))))) {
    expect_error(msa_report(grr, assessment = bad), "assessment")
  }
  expect_null(formals(msa_report)$assessment)
})

test_that("AP1 reports render provenance, overall criteria, warnings, policies and the PB plot", {
  for (pkg in c("rmarkdown", "knitr")) skip_if_not_installed(pkg)
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")
  p <- ap1_test_plan(); r <- ap1_test_runs(p)
  r$protein <- "p.SyntheticProtected"
  # Use controlled fits here to exercise reporting; direct numeric equivalence
  # and actual ordinal fits are covered independently.
  local_mocked_bindings(msa_fit = function(runs, type = c("numeric", "ordinal", "binary"), ...) {
    type <- match.arg(type)
    if (type == "ordinal") warning("Model failed to converge: synthetic reporting case")
    ap1_test_fit_stub(runs, type, ...)
  })
  ids <- unique(r$item_id)
  pb <- expand.grid(item_id = ids, prompt_id = unlist(p$robustness$pb_design$prompt_ids),
                     model_id = names(acmg_models(p)), stringsAsFactors = FALSE)
  pb$rep <- 1L; pb$block <- 1L; pb$value <- acmg_classes(p)[1]
  pb$error <- NA_character_; pb$meta <- '{"mock":true}'; pb$protein <- "p.SyntheticProtected"
  for (column in setdiff(names(r), names(pb))) {
    pb[[column]] <- r[[column]][match(pb$item_id, r$item_id)]
  }
  pb <- pb[, names(r)]
  # An incomplete main plan must override a computed GRR classification in the conclusion.
  result <- acmg_evaluate(rbind(r[-1, ], pb), p)
  for (model in result$models) expect_true(file.exists(model$report))
  html <- paste(readLines(result$models$sol$report, warn = FALSE), collapse = " ")
  html <- gsub("[[:space:]]+", " ", html)
  for (text in c("synthetic", "Statistics are provisional until M1", "overall verdict is", "NOT ASSESSED",
                 "Model failed to converge: synthetic reporting case", "Complete-case agreement diagnostics",
                 "Half-normal plot of robustness effects", "Frozen data provenance", "insaid_references_loaded")) {
    expect_true(grepl(text, html, fixed = TRUE), info = text)
  }
  for (policy in p$reporting$policies) expect_true(grepl(policy$url, html, fixed = TRUE))
  expect_true(grepl("data:image/png;base64", html, fixed = TRUE))
  expect_false(grepl("p.SyntheticProtected", html, fixed = TRUE))
  expect_false(grepl("insaid-[0-9a-f]{16}", html))
  expect_identical(result$models$sol$verdict, "not assessed")
  expect_false(result$models$sol$grr$verdict == result$models$sol$verdict)
})
