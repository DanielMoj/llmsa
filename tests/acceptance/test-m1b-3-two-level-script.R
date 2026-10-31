# K-M1b-3: simulation script for the substitute procedure beta^2/2 (class B,
# first stage): inst/validation/sim/two_level.R implements S-two-1 and S-two-2
# and writes per replication the estimator beta-hat^2/2, the true component and
# whether msa_fit treated the factor as fixed, and in the results file bias,
# relative bias, EmpSE and MCSE and the share of replications with a derived
# component; short run, reproduction, schema and runtime as in K-M1b-2.
# Estimands and measures of the scenario table in docs/02 ("Schätzziele"):
# every true component, %GRR and ICC_items, each with bias, relative bias,
# EmpSE and RMSE with MCSE, for S-two additionally the share of replications
# with a derived component (ACC-3). In the replicates the rows of estimand
# "model" carry beta-hat^2/2, column true the true component and column
# derived whether model entered as a fixed effect (ACC-4). With exactly two
# models msa_fit treats the factor as fixed in every replication (K-M1b-4).

acc_m1b_3_study <- "two_level"
acc_m1b_3_subset <- "S-two-2"   # proper subset for the prefix run (ACC-6)

test_that("K-M1b-3: the scenario table of docs/02 holds S-two-1 and S-two-2 with two models and the latent residual of ANK-28", {
  scs <- acc_m1b_study_scenarios(acc_m1b_3_study)
  expect_identical(names(scs), paste0("S-two-", 1:2))
  for (sc in scs) {
    expect_identical(sc$models, 2L, label = paste(sc$id, "models"))
    expect_identical(sc$type, "ordinal", label = paste(sc$id, "outcome type"))
    expect_lte(abs(sc$components$Residual - acc_m1b_latent_residual(sc$link)), acc_m1b_arith_tol(),
               label = sprintf("%s: residual of the table vs ANK-28 (%s)", sc$id, sc$link))
  }
})

test_that("K-M1b-3: inst/validation/sim/two_level.R and its committed short run exist", {
  expect_true(file.exists(acc_m1b_script(acc_m1b_3_study)), label = acc_m1b_script(acc_m1b_3_study))
  for (kind in c("results", "replicates", "session")) {
    expect_true(file.exists(acc_m1b_check_file(acc_m1b_3_study, kind)), label = acc_m1b_check_file(acc_m1b_3_study, kind))
  }
})

test_that("K-M1b-3: two_level_check_results.csv holds bias, relative bias, EmpSE, RMSE with MCSE and the share of derived components for every scenario and estimand (ankerRef: ANK-TOL.n_check)", {
  res <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1b_3_study, "results"))
  acc_m1b_expect_results_schema(res, acc_m1b_3_study, names(acc_m1b_study_scenarios(acc_m1b_3_study)),
                                acc_m1b_n_check(), "two_level short run")
})

test_that("K-M1b-3: two_level_check_replicates.csv holds beta-hat^2/2, the true component and the fixed-effect flag per replication", {
  rep <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1b_3_study, "replicates"))
  ids <- names(acc_m1b_study_scenarios(acc_m1b_3_study))
  acc_m1b_expect_replicates_design(rep, acc_m1b_3_study, ids, acc_m1b_n_check(), "two_level short run")
  if (!all(c("estimand", "derived", "estimate") %in% names(rep))) return(invisible())
  rows <- rep[rep$estimand == acc_m1b_two_level_factor, , drop = FALSE]
  expect_true(is.logical(rows$derived) && !anyNA(rows$derived), label = "column derived is TRUE/FALSE")
  # K-M1b-4: a factor with exactly two levels always enters as a fixed effect
  expect_true(nrow(rows) > 0L && all(rows$derived %in% TRUE), label = "model is derived in every replication (K-M1b-4)")
  est <- as.numeric(rows$estimate)
  expect_true(all(is.finite(est) & est >= 0), label = "beta-hat^2/2 is finite and nonnegative")
})

test_that("K-M1b-3: the measures of two_level_check_results.csv follow from the single estimates (Formelsammlung §9; ankerRef: ANK-TOL.arithmetic)", {
  res <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1b_3_study, "results"))
  rep <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1b_3_study, "replicates"))
  acc_m1b_expect_results_recomputed(res, rep, acc_m1b_3_study, names(acc_m1b_study_scenarios(acc_m1b_3_study)),
                                    "two_level short run")
})

test_that("K-M1b-3: two_level_check_session.txt names sessionInfo(), seed, RNG and runtime", {
  res <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1b_3_study, "results"))
  acc_m1b_expect_session(acc_m1b_check_file(acc_m1b_3_study, "session"), res, acc_m1b_3_study, "two_level short run")
})

test_that("K-M1b-3: rerunning the short run of two_level gives byte-identical single estimates (format(x, digits = 15))", {
  run <- acc_m1b_rerun(acc_m1b_3_study)
  acc_m1b_expect_run_ok(run, acc_m1b_3_study)
  new <- acc_m1b_read_csv(acc_m1b_out_file(run$out, acc_m1b_3_study, "replicates"))
  old <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1b_3_study, "replicates"))
  acc_m1b_expect_same_replicates(new, old, "two_level rerun vs short run")
})

test_that("K-M1b-3: the rerun of two_level writes results with every scenario, estimand and measure with mcse, consistent with its replicates, and a session file", {
  run <- acc_m1b_rerun(acc_m1b_3_study)
  acc_m1b_expect_run_ok(run, acc_m1b_3_study)
  ids <- names(acc_m1b_study_scenarios(acc_m1b_3_study))
  res <- acc_m1b_read_csv(acc_m1b_out_file(run$out, acc_m1b_3_study, "results"))
  rep <- acc_m1b_read_csv(acc_m1b_out_file(run$out, acc_m1b_3_study, "replicates"))
  acc_m1b_expect_results_schema(res, acc_m1b_3_study, ids, acc_m1b_n_check(), "two_level rerun")
  acc_m1b_expect_replicates_design(rep, acc_m1b_3_study, ids, acc_m1b_n_check(), "two_level rerun")
  acc_m1b_expect_results_recomputed(res, rep, acc_m1b_3_study, ids, "two_level rerun")
  acc_m1b_expect_session(acc_m1b_out_file(run$out, acc_m1b_3_study, "session"), res, acc_m1b_3_study, "two_level rerun")
  old <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1b_3_study, "results"))
  expect_setequal(unique(as.numeric(res$seed)), unique(as.numeric(old$seed)))
})

test_that("K-M1b-3: the short run of two_level stays under ANK-TOL.sim_runtime (ankerRef: ANK-TOL.sim_runtime)", {
  run <- acc_m1b_rerun(acc_m1b_3_study)
  acc_m1b_expect_run_ok(run, acc_m1b_3_study)
  limit <- 60 * as.numeric(acc_m1a_tol("sim_runtime", "minutes"))
  expect_lte(run$elapsed, limit, label = sprintf("wall-clock seconds of the two_level short run (%.1f s)", run$elapsed))
})

test_that("K-M1b-3: a run of two_level with --n-sim 2 and a subset of the scenarios reproduces replications 1 and 2 of the short run (ACC-6)", {
  run <- acc_m1b_run_script(acc_m1b_3_study, 2L, acc_m1b_3_subset)
  acc_m1b_expect_run_ok(run, acc_m1b_3_study)
  res <- acc_m1b_read_csv(acc_m1b_out_file(run$out, acc_m1b_3_study, "results"))
  expect_setequal(unique(res$scenario), acc_m1b_3_subset)
  new <- acc_m1b_read_csv(acc_m1b_out_file(run$out, acc_m1b_3_study, "replicates"))
  old <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1b_3_study, "replicates"))
  old <- old[old$scenario %in% acc_m1b_3_subset & as.integer(old$rep) %in% 1:2, , drop = FALSE]
  acc_m1b_expect_same_replicates(new, old, "two_level prefix run vs short run")
})
