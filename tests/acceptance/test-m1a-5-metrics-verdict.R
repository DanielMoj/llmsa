# K-M1a-5: AIAG statistics and verdict of msa_grr() on constructed components:
# % contribution 100 sigma2_X / sigma2_TV, % study variation 100 sigma_X /
# sigma_TV, ndc = floor(1.41 sigma_PV / sigma_GRR), ICC_items = sigma2_PV /
# sigma2_TV (Formelsammlung §3); verdict marginal at exactly 10.0 % and 30.0 %,
# acceptable just below 10, marginal just below 30, marginal just above 10,
# unacceptable just above 30 (thresholds and constant ankerRef: ANK-16);
# sigma2_GRR = 0 gives ndc = Inf and "acceptable", sigma2_TV = 0 gives
# "undetermined" without error. Constructed components replace the variances of
# a real msa_fit; recomputation with ANK-TOL.arithmetic (ACC-12). ndc is only
# checked from 1 upwards (ACC-7).

acc_m1a_5_sources <- c("item", "prompt", "model", "block", "item:prompt", "item:model", "prompt:model", "Residual")

# An msa_fit of a small simulated study with all eight sources.
acc_m1a_5_base <- function() {
  if (!is.null(acc_m1a$base_fit)) return(acc_m1a$base_fit)
  runs <- acc_m1a_with_seed(1L, msa_simulate(8, 3, 3, 2, 2,
    vc = list(item = 1, prompt = 0.1, model = 0.1, block = 0.05, item_prompt = 0.05, item_model = 0.05,
              prompt_model = 0.05, residual = 0.1), seed = 1L))
  fit <- acc_m1a_quiet(msa_fit(runs, type = "numeric"))
  if (!setequal(names(acc_m1a_components(fit)), acc_m1a_5_sources)) {
    stop("acceptance: the base fit does not have the eight sources ", paste(acc_m1a_5_sources, collapse = ", "),
         call. = FALSE)
  }
  acc_m1a$base_fit <- fit
  fit
}

# The base fit with constructed variances (sources not given are 0).
acc_m1a_5_construct <- function(...) {
  v <- c(...)
  if (!all(names(v) %in% acc_m1a_5_sources)) stop("acceptance: unknown source", call. = FALSE)
  fit <- acc_m1a_5_base()
  full <- stats::setNames(rep(0, length(acc_m1a_5_sources)), acc_m1a_5_sources)
  full[names(v)] <- v
  fit$vc$variance <- unname(full[as.character(fit$vc$source)])
  fit
}

test_that("K-M1a-5: msa_grr() computes % contribution, % study variation, ndc and ICC_items by Formelsammlung §3 (ankerRef: ANK-16)", {
  v <- c(item = 2.3, prompt = 0.07, model = 0.11, block = 0.013, "item:prompt" = 0.021, "item:model" = 0.047,
         "prompt:model" = 0.009, Residual = 0.19)
  g <- msa_grr(acc_m1a_5_construct(v))
  tol <- acc_m1a_tol("arithmetic", "abs_tol")
  repro <- c("prompt", "model", "block", "prompt:model", "item:prompt", "item:model")
  sigma2 <- c(GRR = sum(v[names(v) != "item"]), EV = v[["Residual"]], AV = sum(v[repro]), PV = v[["item"]],
              v[repro])
  total <- sigma2[["GRR"]] + sigma2[["PV"]]
  sigma2 <- c(sigma2, TV = total)
  for (k in names(sigma2)) {
    expect_lte(abs(acc_m1a_cell(g, k, "variance") - sigma2[[k]]), tol, label = paste("variance", k))
    expect_lte(abs(acc_m1a_cell(g, k, "sd") - sqrt(sigma2[[k]])), tol, label = paste("sd", k))
    expect_lte(abs(acc_m1a_cell(g, k, "pct_contribution") - 100 * sigma2[[k]] / total), tol,
               label = paste("% contribution", k))
    expect_lte(abs(acc_m1a_cell(g, k, "pct_study_var") - 100 * sqrt(sigma2[[k]]) / sqrt(total)), tol,
               label = paste("% study variation", k))
  }
  r <- acc_m1a_grr_reference(v)
  expect_lte(abs(acc_m1a_summary(g, "grr_pct_study_var") - r$grr_pct_study_var), tol)
  expect_lte(abs(acc_m1a_summary(g, "grr_pct_contribution") - r$grr_pct_contribution), tol)
  expect_lte(abs(acc_m1a_summary(g, "icc_items") - r$icc_items), tol)
  expect_lte(abs(acc_m1a_summary(g, "repeatability_pct_study_var") - 100 * sqrt(sigma2[["EV"]] / total)), tol)
  expect_lte(abs(acc_m1a_summary(g, "reproducibility_pct_study_var") - 100 * sqrt(sigma2[["AV"]] / total)), tol)
  expect_true(isTRUE(acc_m1a_summary(g, "ndc") == r$ndc))
})

test_that("K-M1a-5: ndc = floor(1.41 sigma_PV / sigma_GRR) with the constant of ANK-16, not sqrt(2) (ankerRef: ANK-16)", {
  k <- acc_m1a_ndc_constant()
  # ratio sigma_PV / sigma_GRR; 3.54 separates 1.41 (4.99 -> 4) from sqrt(2) (5.006 -> 5)
  for (ratio in c(3.54, 1.2, 2.5, 3.4472, 7.3, 12.9)) {
    g <- msa_grr(acc_m1a_5_construct(item = ratio^2, Residual = 0.6, prompt = 0.4))
    expected <- floor(k * ratio)
    expect_true(expected >= 1)
    expect_true(isTRUE(acc_m1a_summary(g, "ndc") == expected),
                label = sprintf("ratio %.4f: ndc %s, expected floor(%.4f) = %d", ratio,
                                format(acc_m1a_summary(g, "ndc")), k * ratio, expected))
  }
  expect_false(floor(k * 3.54) == floor(sqrt(2) * 3.54))
})

test_that("K-M1a-5: %GRR exactly 10.0 % and exactly 30.0 % are marginal (ankerRef: ANK-16)", {
  t <- acc_m1a_thresholds()
  # GRR / TV = (t / 100)^2 with exactly representable components
  cases <- list(
    list(grr = c(Residual = 0.5, prompt = 0.5), item = 99, pct = t[1]),
    list(grr = c(Residual = 0.25), item = 24.75, pct = t[1]),
    list(grr = c(Residual = 4, model = 3, "item:prompt" = 2), item = 91, pct = t[2]),
    list(grr = c(Residual = 0.5625), item = 5.6875, pct = t[2])
  )
  for (cs in cases) {
    total <- sum(cs$grr) + cs$item
    expect_identical(100 * sqrt(sum(cs$grr) / total), cs$pct)
    g <- msa_grr(acc_m1a_5_construct(c(cs$grr, item = cs$item)))
    expect_identical(g$verdict, "marginal",
                     label = sprintf("verdict at %%GRR %g (GRR %g, PV %g)", cs$pct, sum(cs$grr), cs$item))
  }
})

test_that("K-M1a-5: just below and just above 10 % and 30 % (ankerRef: ANK-16)", {
  t <- acc_m1a_thresholds()
  cases <- c(t[1] - 0.01, t[1] + 0.01, t[2] - 0.01, t[2] + 0.01)
  expected <- c("acceptable", "marginal", "marginal", "unacceptable")
  for (i in seq_along(cases)) {
    share <- (cases[i] / 100)^2
    g <- msa_grr(acc_m1a_5_construct(Residual = share * 0.7, prompt = share * 0.3, item = 1 - share))
    expect_lte(abs(acc_m1a_summary(g, "grr_pct_study_var") - cases[i]), acc_m1a_tol("arithmetic", "abs_tol"))
    expect_identical(acc_m1a_verdict_reference(cases[i]), expected[i])
    expect_identical(g$verdict, expected[i], label = sprintf("verdict at %%GRR %.2f", cases[i]))
  }
})

test_that("K-M1a-5: sigma2_GRR = 0 gives ndc = Inf and the verdict acceptable (ankerRef: ANK-16)", {
  g <- msa_grr(acc_m1a_5_construct(item = 1.7))
  expect_identical(acc_m1a_summary(g, "ndc"), Inf)
  expect_identical(g$verdict, "acceptable")
})

test_that("K-M1a-5: sigma2_TV = 0 gives the verdict undetermined without error", {
  fit <- acc_m1a_5_construct(item = 0)
  expect_no_error(g <- msa_grr(fit))
  expect_identical(g$verdict, "undetermined")
})
