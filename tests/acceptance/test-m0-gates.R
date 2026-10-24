# Gate criteria of M0 (docs/01-fachspezifikation.md §9 and §10):
# - K-M0-1: decided by the deps gate; see also test-m0-deps.R.
# - K-M0-2: pass or fail of the test run is decided by the tests gate; see also
#   test-m0-testthat-count.R.
# - K-M0-3: decided by the lint gate (orchestrator/gates.d/20-lint.sh running
#   orchestrator/lib/r-check.sh: R CMD build and R CMD check --as-cran
#   --no-manual outside the repository, without ERROR and WARNING).
# - K-M0-6: decided by the aggregate orchestrator/state/M0/gates.json, which the
#   gate runner writes after this test has run: pass for deps, lint, tests,
#   trace, territory, mutgate and golden-adr, and the mutgate summary
#   "mutgate: pass (kein geänderter Mutations-Scope)".
# The runner orchestrator/verifier.sh runs exactly the executable files
# orchestrator/gates.d/NN-<name>.sh, so gates.json can only report the seven
# gates if each of them is present and executable; the test checks that.

test_that("K-M0-6: the gates deps, lint, tests, trace, territory, mutgate and golden-adr are active", {
  dir <- file.path(acc_repo_root(), "orchestrator", "gates.d")
  scripts <- list.files(dir, pattern = "^[0-9][0-9]-.+[.]sh$", full.names = TRUE)
  executable <- scripts[file.access(scripts, 1L) == 0L]
  active <- sub("[.]sh$", "", sub("^[0-9][0-9]-", "", basename(executable)))
  for (gate in c("deps", "lint", "tests", "trace", "territory", "mutgate", "golden-adr")) {
    expect_true(gate %in% active, info = gate)
  }
})
