# K-M0-2 has two parts. Whether the testthat run over tests/testthat,
# tests/acceptance, tests/e2e and tests/fuzz ends without failures and errors is
# decided by the tests gate (orchestrator/gates.d/30-tests.sh, verdict in
# orchestrator/state/M0/gates.json). The gate does not check how many tests run
# under tests/testthat/; the test below does.

test_that("K-M0-2: at least ANK-03 tests run under tests/testthat/ (ankerRef: ANK-03)", {
  minimum <- acc_anchor("ANK-03")$value
  dir <- file.path(acc_pkg_root(), "tests", "testthat")
  expect_true(dir.exists(dir), info = dir)
  results <- testthat::test_dir(
    dir, reporter = "silent", stop_on_failure = FALSE, load_package = "none"
  )
  # Counted like orchestrator/lib/r-tests.R and ANK-03: one row per test_that()
  # block that ran, skipped blocks included (CRITERIA.json, open item ACC-3).
  expect_gte(nrow(as.data.frame(results)), minimum)
})
