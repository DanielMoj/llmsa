# K-M3c-6: msa_plan() gives per candidate plan also Bias, EmpSE and their MCSE
# (new columns, interface rule), the true %GRR of Formelsammlung §9 and the
# estimates of the repetitions as attribute replicates (new); the acceptance
# test recomputes Bias, EmpSE, MCSE, quantiles, RMSE and the share of
# misclassifications from replicates by hand after Formelsammlung §9
# (tolerance ANK-TOL.arithmetic). Column names, the form of replicates and the
# quantile definition: ACC-7. Verdict thresholds: ANK-16 (acc_m1a_verdict_reference).
# The comparison with the planning rule (vignette, class A) is
# test-m3c-6-vignette.R and tests/simulation/test-plan-satterthwaite.R.

# Two small candidate plans (one with two blocks) and components whose true
# %GRR (28.7) lies near the 30 % threshold, so that the estimates fall on both
# sides of it; 25 repetitions keep the test fast (it runs for every mutant).
acc_m3c_6_scenarios <- data.frame(n_items = c(6L, 8L), n_prompts = c(3L, 2L), n_models = c(2L, 2L),
                                  n_reps = c(2L, 2L), n_blocks = c(1L, 2L))
acc_m3c_6_vc <- list(item = 1, prompt = 0.02, model = 0.02, block = 0.005, item_prompt = 0.005,
                     item_model = 0.005, prompt_model = 0.003, residual = 0.032)
acc_m3c_6_nsim <- 25L

acc_m3c_6_plan <- function() {
  if (is.null(acc_m3c$plan)) {
    acc_m3c$plan <- acc_m3c_try(msa_plan(acc_m3c_6_scenarios, vc = acc_m3c_6_vc, nsim = acc_m3c_6_nsim,
                                         seed = 31106L, verbose = FALSE))
  }
  acc_m3c$plan
}

acc_m3c_6_ok <- function(p, what) {
  testthat::expect_false(inherits(p, "error"), label = sprintf("msa_plan() for %s (%s)", what,
                                                              if (inherits(p, "error")) conditionMessage(p) else "ok"))
  !inherits(p, "error")
}

test_that("K-M3c-6: msa_plan() has one row per candidate plan with the new columns bias, empse, mcse_bias and mcse_empse besides the columns of v0.1.0", {
  p <- acc_m3c_6_plan()
  if (!acc_m3c_6_ok(p, "two candidate plans")) return(invisible())
  expect_s3_class(p, "msa_plan")
  expect_identical(nrow(p), nrow(acc_m3c_6_scenarios), label = "rows of the plan")
  old <- c("grr_true", "mean", "q2.5", "median", "q97.5", "rmse", "pct_singular", "pct_misclassified")
  expect_identical(setdiff(c(old, acc_m3c_plan_columns), names(p)), character(), label = "missing columns")
  for (col in intersect(acc_m3c_plan_columns, names(p))) {
    expect_true(is.numeric(p[[col]]) && all(is.finite(p[[col]])), label = sprintf("column %s is finite and numeric", col))
  }
  expect_identical(as.integer(attr(p, "nsim")), acc_m3c_6_nsim, label = "attribute nsim")
})

test_that("K-M3c-6: attr(, \"replicates\") holds one row per candidate plan and repetition with the %GRR estimate, the singular flag and the prompt component", {
  p <- acc_m3c_6_plan()
  if (!acc_m3c_6_ok(p, "two candidate plans")) return(invisible())
  rep <- attr(p, "replicates", exact = TRUE)
  expect_true(is.data.frame(rep), label = "attribute replicates is a data.frame")
  if (!is.data.frame(rep)) return(invisible())
  expect_identical(setdiff(acc_m3c_replicate_columns, names(rep)), character(), label = "missing columns of replicates")
  if (!all(acc_m3c_replicate_columns %in% names(rep))) return(invisible())
  expect_identical(nrow(rep), nrow(acc_m3c_6_scenarios) * acc_m3c_6_nsim, label = "rows of replicates")
  for (i in seq_len(nrow(acc_m3c_6_scenarios))) {
    expect_identical(sort(as.integer(rep$sim[as.integer(rep$scenario) == i])), seq_len(acc_m3c_6_nsim),
                     label = sprintf("repetitions 1 to %d of candidate plan %d", acc_m3c_6_nsim, i))
  }
  expect_true(all(is.finite(rep$estimate) & rep$estimate >= 0 & rep$estimate <= 100), label = "estimates are %GRR values in [0, 100]")
  expect_true(is.logical(rep$singular) && !anyNA(rep$singular), label = "singular is logical without NA")
  expect_true(all(is.finite(rep$prompt) & rep$prompt >= 0), label = "prompt components are finite and non-negative")
})

test_that("K-M3c-6: grr_true is the true %GRR of Formelsammlung §9 from the assumed components (ANK-TOL.arithmetic)", {
  p <- acc_m3c_6_plan()
  if (!acc_m3c_6_ok(p, "two candidate plans")) return(invisible())
  tol <- acc_m3c_arith()
  expect_lte(max(abs(p$grr_true - acc_m3c_true_grr(acc_m3c_6_vc))), tol, label = "max |grr_true - 100 sqrt(GRR / (GRR + item))|")
  vc2 <- list(item = 1, prompt = 0.05, model = 0.05, residual = 0.1)
  p2 <- acc_m3c_try(msa_plan(acc_m3c_6_scenarios[1, , drop = FALSE], vc = vc2, nsim = 3L, seed = 31107L, verbose = FALSE))
  if (acc_m3c_6_ok(p2, "components with missing entries")) {
    expect_lte(abs(p2$grr_true - acc_m3c_true_grr(vc2)), tol, label = "|grr_true - reference| with missing components (zero)")
  }
})

test_that("K-M3c-6: mean, Bias, EmpSE, their MCSE, the 2.5/50/97.5 % quantiles, RMSE and the shares of singular fits and misclassifications equal the hand computation from replicates after Formelsammlung §9 (ANK-TOL.arithmetic)", {
  p <- acc_m3c_6_plan()
  if (!acc_m3c_6_ok(p, "two candidate plans")) return(invisible())
  rep <- attr(p, "replicates", exact = TRUE)
  if (!is.data.frame(rep) || !all(acc_m3c_replicate_columns %in% names(rep))) {
    expect_true(FALSE, label = "attribute replicates with its columns")
    return(invisible())
  }
  tol <- acc_m3c_arith()
  for (i in seq_len(nrow(p))) {
    sel <- as.integer(rep$scenario) == i
    ref <- acc_m3c_plan_reference(rep$estimate[sel], rep$singular[sel], p$grr_true[i])
    for (col in names(ref)) {
      expect_true(col %in% names(p), label = sprintf("column %s", col))
      if (!col %in% names(p)) next
      expect_lte(abs(p[[col]][i] - ref[[col]]), tol,
                 label = sprintf("candidate plan %d, %s: |%.12g - hand computation %.12g|", i, col, p[[col]][i], ref[[col]]))
    }
  }
})

test_that("K-M3c-6: the same seed gives the same plan and the same replicates", {
  a <- acc_m3c_try(msa_plan(acc_m3c_6_scenarios[2, , drop = FALSE], vc = acc_m3c_6_vc, nsim = 4L, seed = 31108L, verbose = FALSE))
  b <- acc_m3c_try(msa_plan(acc_m3c_6_scenarios[2, , drop = FALSE], vc = acc_m3c_6_vc, nsim = 4L, seed = 31108L, verbose = FALSE))
  if (!acc_m3c_6_ok(a, "seed 31108") || !acc_m3c_6_ok(b, "seed 31108, again")) return(invisible())
  expect_identical(a, b, label = "two plans with seed 31108")
  expect_false(is.null(attr(a, "replicates", exact = TRUE)), label = "attribute replicates")
})
