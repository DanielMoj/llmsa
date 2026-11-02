# K-M1c-6: decided by the gate mutfull (orchestrator/gates.d/88-mutfull.sh,
# operator territory): a muttest run over R/fit.R and R/grr.R, independent of
# the diff, MUT_WORKERS = 14, mutators and test folders as in the preset,
# reaches a score of at least ANK-32, counted as in 86-mutgate (Killed and
# Timeout detected, RuntimeError not counted, equivalence only after reviewer
# approval in orchestrator/handoff/M1c/MUT-EQUIV-APPROVED.json). The gate runs
# after the tests gate, so no acceptance test can see its result. The test
# below checks that the effective configuration measures what the criterion
# names: the gate is active and due in M1c, it mutates both core files, its
# threshold equals ANK-32, and the workers and test folders follow the
# criterion and AGENTS.md (no tests/simulation). Details: ACC-12.

test_that("K-M1c-6: the gate mutfull is active and due in M1c and mutates R/fit.R and R/grr.R", {
  gate <- file.path(acc_repo_root(), "orchestrator", "gates.d", "88-mutfull.sh")
  expect_true(file.exists(gate) && file.access(gate, 1L) == 0L, label = sprintf("%s is executable", gate))
  if (!file.exists(gate)) return(invisible())
  script <- readLines(gate, warn = FALSE)
  milestones <- acc_m1c_config_value("MUTFULL_MILESTONES")
  if (is.null(milestones)) {
    default <- regmatches(script, regexec("MUTFULL_MILESTONES=\"\\$\\{MUTFULL_MILESTONES:-([^}]*)\\}\"", script))
    milestones <- unlist(lapply(default, `[`, 2L))
  }
  expect_true("M1c" %in% unlist(strsplit(paste(milestones, collapse = " "), "[ ,]+")),
              label = sprintf("MUTFULL_MILESTONES (%s) contains M1c", paste(milestones, collapse = " ")))
  files <- acc_m1c_config_value("MUTFULL_FILES")
  if (is.null(files)) {
    default <- regmatches(script, regexec("MUTFULL_FILES=\"\\$\\{MUTFULL_FILES:-([^}]*)\\}\"", script))
    files <- unlist(lapply(default, `[`, 2L))
  }
  expect_setequal(unlist(strsplit(paste(files, collapse = ","), ",")), unlist(acc_m1a_value("ANK-32", "scope")))
})

test_that("K-M1c-6: the mutation threshold, floor and ratchet tolerance of the gates equal ANK-32 (ankerRef: ANK-32)", {
  for (key in names(acc_m1a_value("ANK-32", "config"))) {
    v <- acc_m1c_config_value(key)
    expect_false(is.null(v), label = sprintf("orchestrator/config.env sets %s", key))
    expect_equal(suppressWarnings(as.numeric(v)), as.numeric(acc_m1a_value("ANK-32", "config", key)),
                 label = sprintf("%s in orchestrator/config.env", key))
  }
  expect_equal(as.numeric(acc_m1a_value("ANK-32", "config", "MUT_SCORE_MIN")), as.numeric(acc_m1a_value("ANK-32", "threshold_pct")))
})

test_that("K-M1c-6: the mutation run uses 14 workers and the test folders of the preset without tests/simulation", {
  expect_identical(acc_m1c_config_value("MUT_WORKERS"), "14")
  dirs <- strsplit(acc_m1c_config_value("MUT_TEST_DIRS") %||% "", "[[:space:]]+")[[1]]
  expect_true(all(c("tests/testthat", "tests/acceptance") %in% dirs), label = sprintf("MUT_TEST_DIRS (%s)", paste(dirs, collapse = " ")))
  expect_false("tests/simulation" %in% dirs, label = "tests/simulation is not in MUT_TEST_DIRS (AGENTS.md)")
})
