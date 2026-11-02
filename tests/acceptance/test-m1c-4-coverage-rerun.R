# K-M1c-4: reproducibility of the short run: `Rscript
# inst/validation/sim/boot_coverage.R --n-sim <ANK-TOL.n_check> --scenarios
# S-boot-1,S-boot-7 --out <tmp>` gives the same single estimates as
# boot_coverage_check_replicates.csv (byte-identical after format(x, digits =
# 15)) and all measures with mcse, stays under ANK-TOL.sim_runtime, and
# boot_coverage_check_session.txt names seed, RNG, R and package versions.
# Besides, a run with --n-sim 2 and only S-boot-7 reproduces replications 1
# and 2 of S-boot-7 in the short run: K-M1d-6 compares the first n_check
# replications of the operator's full run (all scenarios, n_sim >= ANK-06) with
# a rerun (docs/01 §8). Contract: CRITERIA.json M1c, open ACC-3 to ACC-8.

test_that("K-M1c-4: rerunning the short run gives byte-identical single estimates (format(x, digits = 15))", {
  run <- acc_m1c_rerun()
  acc_m1b_expect_run_ok(run, acc_m1c_study)
  new <- acc_m1b_read_csv(acc_m1b_out_file(run$out, acc_m1c_study, "replicates"))
  old <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1c_study, "replicates"))
  acc_m1b_expect_same_replicates(new, old, "boot_coverage rerun vs short run")
})

test_that("K-M1c-4: the rerun writes results with every scenario, estimand and measure with mcse, consistent with its replicates", {
  run <- acc_m1c_rerun()
  acc_m1b_expect_run_ok(run, acc_m1c_study)
  res <- acc_m1b_read_csv(acc_m1b_out_file(run$out, acc_m1c_study, "results"))
  rep <- acc_m1b_read_csv(acc_m1b_out_file(run$out, acc_m1c_study, "replicates"))
  acc_m1c_expect_results_schema(res, acc_m1c_check_scenarios, acc_m1b_n_check(), "boot_coverage rerun")
  acc_m1c_expect_replicates_design(rep, acc_m1c_check_scenarios, acc_m1b_n_check(), "boot_coverage rerun")
  acc_m1c_expect_results_recomputed(res, rep, acc_m1c_check_scenarios, "boot_coverage rerun")
  old <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1c_study, "results"))
  expect_setequal(unique(as.numeric(res$seed)), unique(as.numeric(old$seed)))
})

test_that("K-M1c-4: boot_coverage_check_session.txt and the session file of the rerun name seed, RNG, R and package versions", {
  old <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1c_study, "results"))
  acc_m1c_expect_session(acc_m1b_check_file(acc_m1c_study, "session"), old, "boot_coverage_check_session.txt")
  run <- acc_m1c_rerun()
  acc_m1b_expect_run_ok(run, acc_m1c_study)
  res <- acc_m1b_read_csv(acc_m1b_out_file(run$out, acc_m1c_study, "results"))
  acc_m1c_expect_session(acc_m1b_out_file(run$out, acc_m1c_study, "session"), res, "boot_coverage rerun")
})

test_that("K-M1c-4: the rerun of the short run stays under ANK-TOL.sim_runtime (ankerRef: ANK-TOL.sim_runtime)", {
  limit <- 60 * as.numeric(acc_m1a_tol("sim_runtime", "minutes"))
  run <- acc_m1c_rerun()
  acc_m1b_expect_run_ok(run, acc_m1c_study)
  expect_lte(run$elapsed, limit, label = sprintf("wall-clock seconds of the boot_coverage short run (%.1f s)", run$elapsed))
})

test_that("K-M1c-4: a run with --n-sim 2 and only S-boot-7 reproduces replications 1 and 2 of S-boot-7 in the short run (docs/01 §8, K-M1d-6)", {
  run <- acc_m1c_script_run("prefix", 2L, "S-boot-7")
  acc_m1b_expect_run_ok(run, acc_m1c_study)
  res <- acc_m1b_read_csv(acc_m1b_out_file(run$out, acc_m1c_study, "results"))
  expect_setequal(unique(res$scenario), "S-boot-7")
  new <- acc_m1b_read_csv(acc_m1b_out_file(run$out, acc_m1c_study, "replicates"))
  old <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1c_study, "replicates"))
  old <- old[old$scenario == "S-boot-7" & as.integer(old$rep) %in% 1:2, , drop = FALSE]
  acc_m1b_expect_same_replicates(new, old, "boot_coverage prefix run vs short run")
})
