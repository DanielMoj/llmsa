# K-M1c-3: simulation script for coverage (class B, first stage):
# inst/validation/sim/boot_coverage.R implements S-boot-1 to S-boot-7 with all
# estimands and performance measures of section 8 of docs/01 (parameters
# --n-sim, --out, --scenarios; results, replicates and session file); the
# builder commits the short run with n_sim = ANK-TOL.n_check for the scenarios
# S-boot-1 and S-boot-7 (boot_coverage_check_results.csv,
# boot_coverage_check_replicates.csv, boot_coverage_check_session.txt); the
# documentation of msa_boot() refers to the coverage study and the table in
# vignettes/validation.Rmd. The full run follows after the acceptance of M1c
# (K-M1d-6).
# Scenarios and true components come from the table in docs/02 (estimands:
# %GRR, % contribution GRR, ndc, ICC_items and every variance component;
# measures: bias, relative bias, EmpSE and RMSE of the point estimates,
# coverage and mean width of the 95 % percentile intervals, shares of singular
# and failed bootstrap fits, all with MCSE). Contract of the script and its
# files where the spec is silent: CRITERIA.json M1c, open ACC-3 to ACC-10. The
# script runs with the package under test installed in a temporary library.
# The reproduction of the short run is K-M1c-4 (test-m1c-4-coverage-rerun.R).

acc_m1c_3_other_scenarios <- function() setdiff(names(acc_m1c_scenarios()), acc_m1c_check_scenarios)

test_that("K-M1c-3: the scenario table of docs/02 holds S-boot-1 to S-boot-7, numeric except the binary logit scenario S-boot-7 (ankerRef: ANK-28)", {
  sc <- acc_m1c_scenarios()
  expect_identical(names(sc), paste0("S-boot-", 1:7))
  expect_identical(vapply(sc, `[[`, character(1), "type"), stats::setNames(c(rep("numeric", 6), "binary"), names(sc)))
  expect_identical(sc[["S-boot-7"]]$link, "logit")
  expect_lte(abs(sc[["S-boot-7"]]$components$Residual - acc_m1b_latent_residual("logit")), acc_m1b_arith_tol())
  for (s in sc[1:6]) {
    expect_setequal(names(s$components), c("item", "prompt", "model", "block", "item:prompt", "item:model", "prompt:model", "Residual"))
  }
  expect_setequal(names(sc[["S-boot-7"]]$components), c("item", "prompt", "model", "Residual"))
})

test_that("K-M1c-3: inst/validation/sim/boot_coverage.R and its committed short run exist", {
  expect_true(file.exists(acc_m1b_script(acc_m1c_study)), label = acc_m1b_script(acc_m1c_study))
  for (kind in c("results", "replicates", "session")) {
    expect_true(file.exists(acc_m1b_check_file(acc_m1c_study, kind)), label = acc_m1b_check_file(acc_m1c_study, kind))
  }
})

test_that("K-M1c-3: boot_coverage_check_results.csv holds S-boot-1 and S-boot-7 with every estimand and measure with mcse and n_sim = ANK-TOL.n_check (ankerRef: ANK-TOL.n_check)", {
  res <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1c_study, "results"))
  acc_m1c_expect_results_schema(res, acc_m1c_check_scenarios, acc_m1b_n_check(), "boot_coverage short run")
})

test_that("K-M1c-3: boot_coverage_check_replicates.csv holds one row per replication and estimand with true values, design and bootstrap settings of the scenario table", {
  rep <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1c_study, "replicates"))
  acc_m1c_expect_replicates_design(rep, acc_m1c_check_scenarios, acc_m1b_n_check(), "boot_coverage short run")
})

test_that("K-M1c-3: the measures of boot_coverage_check_results.csv follow from the single estimates and intervals (Formelsammlung §9; ankerRef: ANK-TOL.arithmetic)", {
  res <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1c_study, "results"))
  rep <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1c_study, "replicates"))
  acc_m1c_expect_results_recomputed(res, rep, acc_m1c_check_scenarios, "boot_coverage short run")
})

test_that("K-M1c-3: boot_coverage_check_session.txt names sessionInfo(), seed, RNG and runtime", {
  res <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1c_study, "results"))
  acc_m1c_expect_session(acc_m1b_check_file(acc_m1c_study, "session"), res, "boot_coverage short run")
})

test_that("K-M1c-3: the script implements S-boot-2 to S-boot-6 as well: a run with --n-sim 2 writes all estimands and measures with the design of the table (ACC-9)", {
  ids <- acc_m1c_3_other_scenarios()
  expect_identical(ids, paste0("S-boot-", 2:6))
  run <- acc_m1c_script_run("other", 2L, ids)
  acc_m1b_expect_run_ok(run, acc_m1c_study)
  res <- acc_m1b_read_csv(acc_m1b_out_file(run$out, acc_m1c_study, "results"))
  rep <- acc_m1b_read_csv(acc_m1b_out_file(run$out, acc_m1c_study, "replicates"))
  acc_m1c_expect_results_schema(res, ids, 2L, "boot_coverage S-boot-2 to S-boot-6")
  acc_m1c_expect_replicates_design(rep, ids, 2L, "boot_coverage S-boot-2 to S-boot-6")
  acc_m1c_expect_results_recomputed(res, rep, ids, "boot_coverage S-boot-2 to S-boot-6")
  acc_m1c_expect_session(acc_m1b_out_file(run$out, acc_m1c_study, "session"), res, "boot_coverage S-boot-2 to S-boot-6")
})

test_that("K-M1c-3: the documentation of msa_boot() refers to the coverage study boot_coverage and to the table in vignettes/validation.Rmd", {
  txt <- acc_m1b_rd_text("msa_boot")
  expect_true(grepl("boot_coverage", txt, fixed = TRUE), label = "man/msa_boot.Rd names the study boot_coverage")
  expect_true(grepl("vignette(\"validation\"", txt, fixed = TRUE) || grepl("validation.Rmd", txt, fixed = TRUE),
              label = "man/msa_boot.Rd refers to vignette(\"validation\") or validation.Rmd")
})
