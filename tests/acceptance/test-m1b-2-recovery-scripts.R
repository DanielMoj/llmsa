# K-M1b-2: simulation scripts for the recovery of latent components (class B,
# first stage): inst/validation/sim/ordinal_recovery.R and binary_recovery.R
# implement S-ord-1 to S-ord-4 and S-bin-1 to S-bin-2 with all estimands and
# performance measures of section 8 of docs/01 (parameters --n-sim, --out,
# --scenarios; results, replicates and session file); the builder commits the
# short run of each study with n_sim = ANK-TOL.n_check (*_check_results.csv,
# *_check_replicates.csv, *_check_session.txt); this test reruns both short
# runs and requires byte-identical single estimates (after
# format(x, digits = 15)), finds every scenario, estimand and measure with
# mcse, and both short runs together stay under ANK-TOL.sim_runtime. The full
# runs (n_sim >= ANK-06) follow after the acceptance of M1b.
# Scenarios and true components come from the table in docs/02 (estimands:
# every true component, %GRR and ICC_items on the latent scale; measures:
# bias, relative bias, EmpSE, RMSE, each with MCSE). Contract of the scripts
# and files where the spec is silent: CRITERIA.json, open ACC-2 to ACC-8. The
# scripts run with the package under test installed in a temporary library.

acc_m1b_2_studies <- c("ordinal_recovery", "binary_recovery")
# Proper subsets for the prefix run (ACC-6); S-ord-1 is left out on purpose.
acc_m1b_2_subsets <- list(ordinal_recovery = c("S-ord-2", "S-ord-4"), binary_recovery = "S-bin-2")

test_that("K-M1b-2: the scenario table of docs/02 holds S-ord-1 to S-ord-4 and S-bin-1 to S-bin-2 with the latent residual of ANK-28", {
  expect_identical(names(acc_m1b_study_scenarios("ordinal_recovery")), paste0("S-ord-", 1:4))
  expect_identical(names(acc_m1b_study_scenarios("binary_recovery")), paste0("S-bin-", 1:2))
  for (sc in c(acc_m1b_study_scenarios("ordinal_recovery"), acc_m1b_study_scenarios("binary_recovery"))) {
    expect_lte(abs(sc$components$Residual - acc_m1b_latent_residual(sc$link)), acc_m1b_arith_tol(),
               label = sprintf("%s: residual of the table vs ANK-28 (%s)", sc$id, sc$link))
    expect_true(all(c("item", "prompt", "model") %in% names(sc$components)), label = paste(sc$id, "has item, prompt and model"))
  }
})

for (study in acc_m1b_2_studies) {
  test_that(sprintf("K-M1b-2: inst/validation/sim/%s.R and its committed short run exist", study), {
    expect_true(file.exists(acc_m1b_script(study)), label = acc_m1b_script(study))
    for (kind in c("results", "replicates", "session")) {
      expect_true(file.exists(acc_m1b_check_file(study, kind)), label = acc_m1b_check_file(study, kind))
    }
  })

  test_that(sprintf("K-M1b-2: %s_check_results.csv holds every scenario, estimand and measure with mcse and n_sim = ANK-TOL.n_check (ankerRef: ANK-TOL.n_check)", study), {
    res <- acc_m1b_read_csv(acc_m1b_check_file(study, "results"))
    acc_m1b_expect_results_schema(res, study, names(acc_m1b_study_scenarios(study)), acc_m1b_n_check(),
                                  paste(study, "short run"))
  })

  test_that(sprintf("K-M1b-2: %s_check_replicates.csv holds one estimate per replication and estimand with the true values and the design of the scenario table", study), {
    rep <- acc_m1b_read_csv(acc_m1b_check_file(study, "replicates"))
    acc_m1b_expect_replicates_design(rep, study, names(acc_m1b_study_scenarios(study)), acc_m1b_n_check(),
                                     paste(study, "short run"))
  })

  test_that(sprintf("K-M1b-2: the measures of %s_check_results.csv follow from the single estimates (Formelsammlung §9; ankerRef: ANK-TOL.arithmetic)", study), {
    res <- acc_m1b_read_csv(acc_m1b_check_file(study, "results"))
    rep <- acc_m1b_read_csv(acc_m1b_check_file(study, "replicates"))
    acc_m1b_expect_results_recomputed(res, rep, study, names(acc_m1b_study_scenarios(study)), paste(study, "short run"))
  })

  test_that(sprintf("K-M1b-2: %s_check_session.txt names sessionInfo(), seed, RNG and runtime", study), {
    res <- acc_m1b_read_csv(acc_m1b_check_file(study, "results"))
    acc_m1b_expect_session(acc_m1b_check_file(study, "session"), res, study, paste(study, "short run"))
  })

  test_that(sprintf("K-M1b-2: rerunning the short run of %s gives byte-identical single estimates (format(x, digits = 15))", study), {
    run <- acc_m1b_rerun(study)
    acc_m1b_expect_run_ok(run, study)
    new <- acc_m1b_read_csv(acc_m1b_out_file(run$out, study, "replicates"))
    old <- acc_m1b_read_csv(acc_m1b_check_file(study, "replicates"))
    acc_m1b_expect_same_replicates(new, old, paste(study, "rerun vs short run"))
  })

  test_that(sprintf("K-M1b-2: the rerun of %s writes results with every scenario, estimand and measure with mcse, consistent with its replicates, and a session file", study), {
    run <- acc_m1b_rerun(study)
    acc_m1b_expect_run_ok(run, study)
    ids <- names(acc_m1b_study_scenarios(study))
    res <- acc_m1b_read_csv(acc_m1b_out_file(run$out, study, "results"))
    rep <- acc_m1b_read_csv(acc_m1b_out_file(run$out, study, "replicates"))
    acc_m1b_expect_results_schema(res, study, ids, acc_m1b_n_check(), paste(study, "rerun"))
    acc_m1b_expect_replicates_design(rep, study, ids, acc_m1b_n_check(), paste(study, "rerun"))
    acc_m1b_expect_results_recomputed(res, rep, study, ids, paste(study, "rerun"))
    acc_m1b_expect_session(acc_m1b_out_file(run$out, study, "session"), res, study, paste(study, "rerun"))
    old <- acc_m1b_read_csv(acc_m1b_check_file(study, "results"))
    expect_setequal(unique(as.numeric(res$seed)), unique(as.numeric(old$seed)))
  })

  test_that(sprintf("K-M1b-2: a run of %s with --n-sim 2 and a subset of the scenarios reproduces replications 1 and 2 of the short run (ACC-6)", study), {
    subset <- acc_m1b_2_subsets[[study]]
    run <- acc_m1b_run_script(study, 2L, subset)
    acc_m1b_expect_run_ok(run, study)
    res <- acc_m1b_read_csv(acc_m1b_out_file(run$out, study, "results"))
    expect_setequal(unique(res$scenario), subset)
    new <- acc_m1b_read_csv(acc_m1b_out_file(run$out, study, "replicates"))
    old <- acc_m1b_read_csv(acc_m1b_check_file(study, "replicates"))
    old <- old[old$scenario %in% subset & as.integer(old$rep) %in% 1:2, , drop = FALSE]
    acc_m1b_expect_same_replicates(new, old, paste(study, "prefix run vs short run"))
  })
}

test_that("K-M1b-2: both short runs together stay under ANK-TOL.sim_runtime (ankerRef: ANK-TOL.sim_runtime)", {
  limit <- 60 * as.numeric(acc_m1a_tol("sim_runtime", "minutes"))
  elapsed <- vapply(acc_m1b_2_studies, function(s) acc_m1b_rerun(s)$elapsed, numeric(1))
  for (s in acc_m1b_2_studies) acc_m1b_expect_run_ok(acc_m1b_rerun(s), s)
  expect_lte(sum(elapsed), limit,
             label = sprintf("wall-clock seconds of both short runs (%s)",
                             paste(sprintf("%s %.1f s", names(elapsed), elapsed), collapse = ", ")))
})
