# K-M1c-7: "`table`, `summary` und `verdict` von `msa_grr()` und die Ergebnisse
# von `msa_boot()` bleiben bytegleich." The reference is the state before M1c:
# R/fit.R and R/grr.R of the tag done/M1b, read with git cat-file, checked
# against the SHA-256 of ANK-33 and sourced into an environment
# (acc_m1c_baseline() in setup-m1c.R). Both versions run in this process on
# the same fits, so the comparison is exact (identical()). Compared for
# msa_boot(): the data.frame and the attributes boot and level; the counts
# n_failed and n_singular belong to K-M1c-2 (ACC-13).

test_that("K-M1c-7: the reference state done/M1b of R/fit.R and R/grr.R carries the SHA-256 of ANK-33 (ankerRef: ANK-33)", {
  env <- acc_m1c_baseline()
  for (f in c("msa_grr", "grr_stats", "msa_boot", "vc_from_model", "latent_residual")) {
    expect_true(exists(f, envir = env, inherits = FALSE), label = sprintf("done/M1b defines %s", f))
  }
})

test_that("K-M1c-7: table, summary and verdict of msa_grr() are byte-identical with done/M1b (ankerRef: ANK-33)", {
  env <- acc_m1c_baseline()
  cases <- acc_m1c_grr_cases()
  for (case in names(cases)) {
    x <- cases[[case]]
    new <- do.call(msa_grr, c(list(x$fit), x$args))
    old <- do.call(get("msa_grr", envir = env, inherits = FALSE), c(list(x$fit), x$args))
    for (part in acc_m1c_grr_parts) {
      expect_identical(new[[part]], old[[part]], label = sprintf("msa_grr()$%s (%s)", part, case),
                       expected.label = "done/M1b")
    }
  }
})

for (run in c("numeric", "binary")) {
  test_that(sprintf("K-M1c-7: the results of msa_boot() on the %s fit are byte-identical with done/M1b (ankerRef: ANK-33)", run), {
    level <- if (run == "numeric") 0.95 else 0.90
    r <- acc_m1c_boot_runs[[run]]
    res <- acc_m1c_msa_boot(run, level)
    expect_false(inherits(res$value, "error"),
                 label = sprintf("msa_boot() runs (%s)", if (inherits(res$value, "error")) conditionMessage(res$value) else "ok"))
    if (inherits(res$value, "error")) return(invisible())
    old_boot <- get("msa_boot", envir = acc_m1c_baseline(), inherits = FALSE)
    fit <- acc_m1c_fit(r$design)
    old <- acc_m1c_with_rng(acc_m1b_catch(old_boot(fit, nsim = r$nsim, level = level, seed = r$seed)))
    expect_false(inherits(old$value, "error"))
    if (inherits(old$value, "error")) return(invisible())
    new_core <- acc_m1c_boot_core(res$value)
    old_core <- acc_m1c_boot_core(old$value)
    for (part in names(old_core)) {
      expect_identical(new_core[[part]], old_core[[part]], label = sprintf("msa_boot() %s (%s fit, level %s)", part, run, format(level)),
                       expected.label = "done/M1b")
    }
  })
}
