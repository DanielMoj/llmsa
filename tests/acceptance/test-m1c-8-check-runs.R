# K-M1c-8, short runs: "Die Kurzläufe aller drei Studien
# (`ordinal_recovery_check_*`, `binary_recovery_check_*`, `two_level_check_*`)
# sind mit diesem Code neu erzeugt, weil ihr Implementierungshash `msa_fit`
# einschließt; K-M1b-2 und K-M1b-3 bleiben grün." The session file of every
# committed short run names the implementation hash that a run with the
# package under test writes: the rerun of the short run with n_sim =
# ANK-TOL.n_check, made once per test run and shared with K-M1b-2 and K-M1b-3
# (acc_m1b_rerun() in setup-m1b.R). That rerun reproduces the committed single
# estimates byte-identically (format(x, digits = 15)), and the hash of the
# studies (sim_implementation() in inst/validation/sim/simulation_helpers.R,
# ADR-041 Nr. 4) changes with msa_fit. These tests rerun three scripts with
# the package installed in a temporary library; they belong outside the
# mutation runs like the reruns of K-M1b-2 and K-M1b-3 (ACC-14, ACC-20).

acc_m1c_8_studies <- c("ordinal_recovery", "binary_recovery", "two_level")

for (study in acc_m1c_8_studies) {
  test_that(sprintf("K-M1c-8: %s_check_session.txt names the implementation hash that a run with the code under test writes", study), {
    committed <- acc_m1b_check_file(study, "session")
    expect_true(file.exists(committed), label = committed)
    run <- acc_m1b_rerun(study)
    acc_m1b_expect_run_ok(run, study)
    written <- acc_m1b_out_file(run$out, study, "session")
    if (!file.exists(committed) || !file.exists(written)) return(invisible())
    new <- acc_m1c_8_session_field(written, "implementation")
    old <- acc_m1c_8_session_field(committed, "implementation")
    expect_false(is.na(new), label = sprintf("%s: the session file of the rerun has exactly one line implementation: <hash>", study))
    expect_identical(old, new, label = sprintf("%s: implementation hash of %s", study, basename(committed)),
                     expected.label = "the hash written by the rerun with the code under test")
  })

  test_that(sprintf("K-M1c-8: the rerun of %s with the code under test reproduces %s_check_replicates.csv byte-identically (K-M1b-2 and K-M1b-3 remain green)", study, study), {
    run <- acc_m1b_rerun(study)
    acc_m1b_expect_run_ok(run, study)
    path <- acc_m1b_out_file(run$out, study, "replicates")
    if (!file.exists(path)) return(invisible())
    new <- acc_m1b_read_csv(path)
    old <- acc_m1b_read_csv(acc_m1b_check_file(study, "replicates"))
    acc_m1b_expect_same_replicates(new, old, paste(study, "rerun vs committed short run"))
  })
}

test_that("K-M1c-8: the implementation hash of the class-B studies changes with msa_fit (sim_implementation(), ADR-041 Nr. 4)", {
  path <- file.path(acc_m1b_sim_dir(), "simulation_helpers.R")
  expect_true(file.exists(path), label = path)
  if (!file.exists(path)) return(invisible())
  e <- new.env(parent = globalenv())
  sys.source(path, envir = e)
  expect_true(is.function(e$sim_implementation), label = "simulation_helpers.R defines sim_implementation()")
  if (!is.function(e$sim_implementation)) return(invisible())
  before <- e$sim_implementation()
  changed <- get("msa_fit", envir = asNamespace(acc_pkg))
  body(changed) <- call("{", quote(invisible("acceptance K-M1c-8")), body(changed))
  after <- local({
    testthat::local_mocked_bindings(msa_fit = changed, .package = acc_pkg)
    e$sim_implementation()
  })
  expect_true(is.character(before) && length(before) == 1L && nzchar(before), label = "sim_implementation() returns a hash")
  expect_false(identical(before, after), label = "the hash of a package whose msa_fit differs equals the hash of the package under test")
})
