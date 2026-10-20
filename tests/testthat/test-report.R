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
