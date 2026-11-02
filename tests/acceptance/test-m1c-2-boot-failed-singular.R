# K-M1c-2: msa_boot() counts non-finite replicates (n_failed) and singular
# replicates (n_singular) separately as attributes, keeps singular replicates
# in the quantiles, drops only non-finite ones, and print.msa_boot names both
# numbers with accurate wording (Formelsammlung §12 Nr. 5; docs/01 §3 Nr. 5).
# Failed replicates are produced by an error injected into lme4's refit for
# three of the twenty replicates; a singular replicate is a refit for which
# lme4::isSingular() is TRUE. Test form and wording rule: CRITERIA.json M1c,
# open ACC-2.

acc_m1c_2_counts <- function(run) {
  ref <- acc_m1c_reference_boot(run)
  finite <- apply(ref$t[, acc_m1c_statistics, drop = FALSE], 1L, function(r) all(is.finite(r)))
  list(failed = sum(!finite), singular = sum(ref$t[finite, "singular"] == 1), finite = finite, ref = ref)
}

test_that("K-M1c-2: the reference bootstrap with injected refit failures has failed, singular and regular replicates", {
  r <- acc_m1c_boot_runs$failed
  k <- acc_m1c_2_counts("failed")
  expect_identical(which(!k$finite), r$fail_at)
  expect_identical(k$failed, length(r$fail_at))
  expect_true(k$singular > 0L && k$singular < sum(k$finite),
              label = sprintf("singular replicates (%d) and regular replicates among the %d finite ones", k$singular, sum(k$finite)))
  expect_false(k$singular %in% c(k$failed, r$nsim, 100 * r$level),
               label = "the singular count differs from the failed count, nsim and the level, so the print test can tell them apart")
  regular <- k$finite & k$ref$t[, "singular"] == 0
  changed <- vapply(acc_m1c_statistics, function(s) {
    !isTRUE(all.equal(acc_m1c_percentile(k$ref$t[k$finite, s], r$level), acc_m1c_percentile(k$ref$t[regular, s], r$level),
                      tolerance = 0))
  }, logical(1))
  expect_true(any(changed), label = "dropping the singular replicates would change at least one quantile")
  acc_m1c_expect_ndc_away_from_integers(k$ref, "reference bootstrap with failures")
})

test_that("K-M1c-2: msa_boot() records n_failed and n_singular separately as attributes", {
  r <- acc_m1c_boot_runs$failed
  k <- acc_m1c_2_counts("failed")
  res <- acc_m1c_msa_boot("failed", r$level)
  expect_false(inherits(res$value, "error"),
               label = sprintf("msa_boot() with failed refits runs (%s)",
                               if (inherits(res$value, "error")) conditionMessage(res$value) else "ok"))
  if (inherits(res$value, "error")) return(invisible())
  for (a in c("n_failed", "n_singular")) {
    v <- attr(res$value, a)
    expect_true(is.numeric(v) && length(v) == 1L && is.finite(v), label = sprintf("attribute %s is one finite number", a))
  }
  expect_equal(as.numeric(attr(res$value, "n_failed")), k$failed, label = "attr(, \"n_failed\"): the non-finite replicates")
  expect_equal(as.numeric(attr(res$value, "n_singular")), k$singular,
               label = "attr(, \"n_singular\"): the singular replicates, without the failed ones")
})

test_that("K-M1c-2: msa_boot() keeps singular replicates in the quantiles and drops only the non-finite ones (ankerRef: ANK-TOL.engine_boot)", {
  r <- acc_m1c_boot_runs$failed
  res <- acc_m1c_msa_boot("failed", r$level)
  expect_false(inherits(res$value, "error"))
  if (inherits(res$value, "error")) return(invisible())
  acc_m1c_expect_quantiles(res$value, acc_m1c_reference_boot("failed"), r$level, "numeric fit with failed refits")
})

test_that("K-M1c-2: print.msa_boot names the failed replicates as dropped and the singular replicates as retained", {
  r <- acc_m1c_boot_runs$failed
  k <- acc_m1c_2_counts("failed")
  res <- acc_m1c_msa_boot("failed", r$level)
  expect_false(inherits(res$value, "error"))
  if (inherits(res$value, "error")) return(invisible())
  lines <- acc_m1c_print_lines(res$value)
  acc_m1c_expect_counts_printed(lines, k$failed, k$singular, "print.msa_boot with failed and singular replicates")
})

test_that("K-M1c-2: without failed and singular replicates msa_boot() records and print.msa_boot names both counts as 0", {
  r <- acc_m1c_boot_runs$zero
  k <- acc_m1c_2_counts("zero")
  expect_identical(c(k$failed, k$singular), c(0L, 0L), label = "reference counts of the design without failures and singular refits")
  acc_m1c_expect_ndc_away_from_integers(k$ref, "reference bootstrap without failures")
  res <- acc_m1c_msa_boot("zero", r$level)
  expect_false(inherits(res$value, "error"))
  if (inherits(res$value, "error")) return(invisible())
  expect_equal(as.numeric(attr(res$value, "n_failed")), 0, label = "attr(, \"n_failed\")")
  expect_equal(as.numeric(attr(res$value, "n_singular")), 0, label = "attr(, \"n_singular\")")
  acc_m1c_expect_counts_printed(acc_m1c_print_lines(res$value), 0L, 0L, "print.msa_boot without failed and singular replicates")
  acc_m1c_expect_quantiles(res$value, acc_m1c_reference_boot("zero"), r$level, "numeric fit without failures")
})
