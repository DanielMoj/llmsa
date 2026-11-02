# K-M1c-5: vignettes/validation.Rmd holds the section "Bootstrap intervals:
# coverage by scenario", which reads boot_coverage_results.csv if present,
# else boot_coverage_check_results.csv (no numeric literal from a results file
# in the Rmd text; n_sim named from the file) and tabulates coverage with MCSE
# per scenario. Structure and reading are tested here on the vignette knitted
# in the repository (the knit is shared with K-M1a-7 and K-M1b-7,
# acc_m1a_knit_validation()); the choice of a present boot_coverage_results.csv
# is tested in test-m1c-5-vignette-full-results.R. Contract details: ACC-11.
# K-M1c-5: the build by R CMD check without ERROR and WARNING is decided by the
# lint gate (orchestrator/gates.d/20-lint.sh, orchestrator/lib/r-check.sh).

acc_m1c_5_section <- function() acc_m1a_section(acc_m1a_knit_validation()$lines, acc_m1c_section_title)

acc_m1c_5_results_path <- function() acc_m1b_expected_results_path(acc_m1b_sim_dir(), acc_m1c_study)

test_that("K-M1c-5: vignettes/validation.Rmd holds the section \"Bootstrap intervals: coverage by scenario\"", {
  rmd <- acc_m1a_vignette_path()
  expect_true(file.exists(rmd), label = rmd)
  if (!file.exists(rmd)) return(invisible())
  expect_false(is.null(acc_m1a_section(readLines(rmd, warn = FALSE), acc_m1c_section_title)))
})

test_that("K-M1c-5: the vignette knits in the repository without error and shows the section", {
  k <- acc_m1a_knit_validation()
  expect_null(k$error)
  expect_false(is.null(acc_m1c_5_section()))
  expect_false(any(grepl("^(##|#>)[[:space:]]*Error", k$lines)), label = "no error output in the knitted vignette")
})

test_that("K-M1c-5: the section tabulates coverage with MCSE per scenario from the results file and names n_sim from it", {
  path <- acc_m1c_5_results_path()
  expect_true(file.exists(path), label = path)
  if (!file.exists(path)) return(invisible())
  res <- acc_m1b_read_csv(path)
  sec <- acc_m1c_5_section()
  expect_false(is.null(sec))
  if (is.null(sec)) return(invisible())
  cells <- tolower(unlist(lapply(acc_m1a_tables(sec), function(t) c(names(t), unlist(t, use.names = FALSE)))))
  for (w in c("coverage", "mcse")) {
    expect_true(any(grepl(w, cells, fixed = TRUE)), label = sprintf("a table of the section shows %s", w))
  }
  acc_m1c_expect_coverage_shown(sec, res, sprintf("boot_coverage (%s)", basename(path)))
  acc_m1b_expect_n_sim_shown(sec, res, "boot_coverage")
})

test_that("K-M1c-5: no numeric literal of the boot_coverage results file is typed into validation.Rmd", {
  rmd <- acc_m1a_vignette_path()
  expect_true(file.exists(rmd))
  path <- acc_m1c_5_results_path()
  expect_true(file.exists(path), label = path)
  if (!file.exists(rmd) || !file.exists(path)) return(invisible())
  lit <- acc_m1a_rmd_literals(readLines(rmd, warn = FALSE))
  res <- acc_m1b_read_csv(path)
  values <- c(as.numeric(res$value), as.numeric(res$mcse))
  values <- unique(values[is.finite(values) & values != round(values)])
  typed <- character()
  for (i in seq_len(nrow(lit))) {
    x <- lit$value[i]
    if (lit$significant[i] >= 3L && any(x == values | x == signif(values, lit$significant[i]))) typed <- c(typed, lit$token[i])
  }
  expect_identical(unique(typed), character(), label = "numeric literals in validation.Rmd that equal values of the boot_coverage results")
})
