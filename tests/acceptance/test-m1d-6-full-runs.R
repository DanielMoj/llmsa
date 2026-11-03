# K-M1d-6: the full class-B runs are complete and reproducible:
# inst/validation/sim/<study>_results.csv, _replicates.csv and _session.txt of
# ordinal_recovery, binary_recovery, two_level and boot_coverage with every
# scenario of the study, every estimand and measure of docs/01 §8,
# n_sim >= ANK-06 and an mcse per measure; the first ANK-TOL.n_check
# repetitions of every study (boot_coverage: S-boot-1 and S-boot-7) are
# reproduced with the same seed byte for byte after format(x, digits = 15);
# every session file names seed, RNG, R and package versions. A missing file
# fails the test, it never skips it. The contracts of the scripts are those of
# M1b and M1c (ADR-023, ADR-042; helpers in setup-m1b.R and setup-m1c.R); the
# reruns are shared with test-m1b-2, test-m1b-3 and test-m1c-4 (ACC-9).

for (study in acc_m1d_studies) {
  test_that(sprintf("K-M1d-6: %s: results, replicates and session file of the full run exist", study), {
    for (kind in c("results", "replicates", "session")) {
      path <- acc_m1d_full_path(study, kind)
      expect_true(file.exists(path), label = sprintf("%s exists (docs/02 M1d, Voraussetzung)", basename(path)))
    }
  })

  test_that(sprintf("K-M1d-6: %s: every scenario, estimand and measure with mcse, n_sim >= ANK-06 (ankerRef: ANK-06)", study), {
    path <- acc_m1d_full_path(study, "results")
    expect_true(file.exists(path), label = basename(path))
    if (!file.exists(path)) return(invisible())
    res <- acc_m1b_read_csv(path)
    ids <- acc_m1d_study_ids(study)
    n_sim <- unique(as.numeric(res$n_sim))
    expect_identical(length(n_sim), 1L, label = sprintf("%s: one n_sim for all rows (found %s)", study, paste(n_sim, collapse = ", ")))
    if (length(n_sim) != 1L) return(invisible())
    expect_gte(n_sim, acc_m1d_n_min(), label = sprintf("%s: n_sim", study))
    if (study == "boot_coverage") acc_m1c_expect_results_schema(res, ids, n_sim, study)
    else acc_m1b_expect_results_schema(res, study, ids, n_sim, study)
  })

  test_that(sprintf("K-M1d-6: %s: the replicates hold every repetition and the results follow from them", study), {
    rpath <- acc_m1d_full_path(study, "results")
    ppath <- acc_m1d_full_path(study, "replicates")
    expect_true(file.exists(rpath) && file.exists(ppath), label = paste(basename(rpath), "and", basename(ppath)))
    if (!file.exists(rpath) || !file.exists(ppath)) return(invisible())
    res <- acc_m1b_read_csv(rpath)
    rep <- acc_m1b_read_csv(ppath)
    ids <- acc_m1d_study_ids(study)
    n_sim <- max(as.numeric(res$n_sim))
    if (study == "boot_coverage") {
      acc_m1c_expect_replicates_design(rep, ids, n_sim, study)
      acc_m1c_expect_results_recomputed(res, rep, ids, study)
    } else {
      acc_m1b_expect_replicates_design(rep, study, ids, n_sim, study)
      acc_m1b_expect_results_recomputed(res, rep, study, ids, study)
    }
  })

  test_that(sprintf("K-M1d-6: %s: a rerun with the same seed reproduces the first ANK-TOL.n_check repetitions byte for byte (ankerRef: ANK-TOL.n_check)", study), {
    rpath <- acc_m1d_full_path(study, "results")
    ppath <- acc_m1d_full_path(study, "replicates")
    expect_true(file.exists(rpath) && file.exists(ppath), label = paste(basename(rpath), "and", basename(ppath)))
    if (!file.exists(rpath) || !file.exists(ppath)) return(invisible())
    n_check <- acc_m1b_n_check()
    ids <- if (study == "boot_coverage") acc_m1c_check_scenarios else acc_m1d_study_ids(study)
    run <- if (study == "boot_coverage") acc_m1c_rerun() else acc_m1b_rerun(study)
    acc_m1b_expect_run_ok(run, study)
    new_path <- acc_m1b_out_file(run$out, study, "replicates")
    if (!file.exists(new_path)) return(invisible())
    full <- acc_m1b_read_csv(ppath)
    head <- full[full$scenario %in% ids & as.integer(full$rep) <= n_check, , drop = FALSE]
    acc_m1b_expect_same_replicates(acc_m1b_read_csv(new_path), head, sprintf("%s: rerun against the first %d repetitions of the full run", study, n_check))
    seeds_full <- unique(acc_m1b_read_csv(rpath)[c("scenario", "seed")])
    seeds_new <- unique(acc_m1b_read_csv(acc_m1b_out_file(run$out, study, "results"))[c("scenario", "seed")])
    for (id in ids) {
      expect_identical(as.numeric(seeds_new$seed[seeds_new$scenario == id]), as.numeric(seeds_full$seed[seeds_full$scenario == id]),
                       label = sprintf("%s, %s: seed of the rerun equals the seed of the full run", study, id))
    }
  })

  test_that(sprintf("K-M1d-6: %s: the session file names seed, RNG, R and package versions", study), {
    rpath <- acc_m1d_full_path(study, "results")
    spath <- acc_m1d_full_path(study, "session")
    expect_true(file.exists(rpath) && file.exists(spath), label = paste(basename(rpath), "and", basename(spath)))
    if (!file.exists(rpath) || !file.exists(spath)) return(invisible())
    res <- acc_m1b_read_csv(rpath)
    if (study == "boot_coverage") acc_m1c_expect_session(spath, res, study)
    else acc_m1b_expect_session(spath, res, study, study)
  })
}
