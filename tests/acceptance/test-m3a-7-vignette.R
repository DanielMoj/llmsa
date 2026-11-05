# K-M3a-7 (vignette part): vignettes/validation.Rmd reports the coverage of
# the bias interval for the scenarios S-bias-1 and S-bias-2. The coverage
# itself is the class A simulation tests/simulation/test-bias-coverage.R
# (docs/01 §8), which checks that it lies within ANK-TOL.mc_factor (pass)
# Monte Carlo standard errors of 0.95 with n_sim >= ANK-06. Here: the knitted
# vignette (shared knit, acc_m1a_knit_validation()) holds a section whose
# header names the bias and the coverage, with a table that gives coverage,
# MCSE and n_sim per scenario; the shown values meet the same pass criterion,
# the MCSE is sqrt(c (1 - c) / n_sim) of the shown coverage (Formelsammlung
# §9), and no shown value is typed into the Rmd (ACC-15).
# K-M3a-7: the build of the vignette by R CMD check without ERROR and WARNING
# is decided by the lint gate (orchestrator/gates.d/20-lint.sh).

acc_m3a_7_rows <- function() {
  k <- acc_m1a_knit_validation()
  sec <- acc_m3a_coverage_section(k$lines)
  if (is.null(sec)) return(NULL)
  acc_m3a_coverage_rows(sec)
}

test_that("K-M3a-7: the knitted vignettes/validation.Rmd holds a section on the coverage of the bias interval with a table of coverage, MCSE and n_sim for S-bias-1 and S-bias-2", {
  k <- acc_m1a_knit_validation()
  expect_null(k$error)
  sec <- acc_m3a_coverage_section(k$lines)
  expect_true(!is.null(sec), label = "a section whose header names the bias and the coverage")
  if (is.null(sec)) return(invisible())
  rows <- acc_m3a_coverage_rows(sec)
  expect_true(!is.null(rows), label = "a table with the columns scenario, coverage, MCSE and n_sim and the rows S-bias-1 and S-bias-2")
})

test_that("K-M3a-7: the coverage the vignette reports for S-bias-1 and S-bias-2 lies within ANK-TOL.mc_factor (pass) MCSE of 0.95, with n_sim >= ANK-06 and MCSE = sqrt(c (1 - c) / n_sim)", {
  rows <- acc_m3a_7_rows()
  expect_true(!is.null(rows), label = "the coverage table of the vignette")
  if (is.null(rows)) return(invisible())
  n_min <- as.integer(acc_m3a_value("ANK-06", "n_sim_min"))
  k_pass <- as.numeric(acc_m3a_tol("mc_factor", "pass"))
  for (id in c("S-bias-1", "S-bias-2")) {
    r <- rows[rows$scenario == id, , drop = FALSE]
    expect_identical(nrow(r), 1L, label = sprintf("%s: one row", id))
    if (nrow(r) != 1L) next
    cov <- acc_m3a_shown_number(r$coverage)
    mcse <- acc_m3a_shown_number(r$mcse)
    n <- suppressWarnings(as.numeric(gsub("[^0-9]", "", r$n_sim)))
    expect_true(is.finite(n) && n >= n_min, label = sprintf("%s: n_sim %s >= %d", id, r$n_sim, n_min))
    expect_true(is.finite(cov[["value"]]) && cov[["value"]] >= 0 && cov[["value"]] <= 1, label = sprintf("%s: coverage %s is a proportion", id, r$coverage))
    expect_true(is.finite(mcse[["value"]]) && mcse[["value"]] > 0, label = sprintf("%s: MCSE %s is a positive number", id, r$mcse))
    if (!is.finite(n) || !is.finite(cov[["value"]]) || !is.finite(mcse[["value"]])) next
    # MCSE of the shown coverage, allowing for the rounding of both shown values.
    lo <- max(0, cov[["value"]] - cov[["half"]])
    hi <- min(1, cov[["value"]] + cov[["half"]])
    m_lo <- min(sqrt(lo * (1 - lo) / n), sqrt(hi * (1 - hi) / n))
    m_hi <- if (lo <= 0.5 && hi >= 0.5) sqrt(0.25 / n) else max(sqrt(lo * (1 - lo) / n), sqrt(hi * (1 - hi) / n))
    expect_true(mcse[["value"]] >= m_lo - mcse[["half"]] && mcse[["value"]] <= m_hi + mcse[["half"]],
                label = sprintf("%s: MCSE %s is sqrt(c (1 - c) / n_sim) of coverage %s with n_sim %s", id, r$mcse, r$coverage, r$n_sim))
    expect_lte(abs(cov[["value"]] - 0.95), k_pass * (mcse[["value"]] + mcse[["half"]]) + cov[["half"]],
               label = sprintf("%s: |coverage %s - 0.95| within %g MCSE (%s)", id, r$coverage, k_pass, r$mcse))
  }
})

test_that("K-M3a-7: no coverage or MCSE value of the table is typed into validation.Rmd", {
  rows <- acc_m3a_7_rows()
  expect_true(!is.null(rows), label = "the coverage table of the vignette")
  if (is.null(rows)) return(invisible())
  # As for K-M1c-5: shown numbers and Rmd literals with at least three
  # significant digits; the nominal 0.95 has two and stays out.
  shown <- unlist(lapply(c(rows$coverage, rows$mcse), acc_m1a_numbers))
  sig <- nchar(sub("^0+", "", gsub("[^0-9]", "", sub("[eE].*$", "", shown))))
  values <- as.numeric(shown[sig >= 3L])
  lit <- acc_m1a_rmd_literals(readLines(acc_m1a_vignette_path(), warn = FALSE))
  typed <- unique(lit$token[lit$significant >= 3L & lit$value %in% values])
  expect_identical(typed, character(), label = "numbers of the coverage table that appear as literals in validation.Rmd")
})
