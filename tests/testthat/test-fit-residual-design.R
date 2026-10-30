# Synthetic regression designs for E44 and the related E47 coverage gaps.
residual_design_runs <- function() {
  d <- expand.grid(item_id = paste0("I", 1:4), prompt_id = paste0("P", 1:2),
                    model_id = "M1", rep = 1:2, stringsAsFactors = FALSE)
  d$value <- rep(c(1.1, 2.3, 0.7, 4.5, 3.2, 1.8, 5.1, 0.9), 2)
  as_msa_runs(d)
}

residual_design_expect_zero <- function(runs, formula) {
  d <- numeric_test_frame(runs[!is.na(runs$value), ])
  # Centering is a fixed-intercept invariance and avoids roundoff from the
  # large intercept in the independently computed ANOVA residuals.
  d$y <- d$y - mean(d$y)
  oracle <- stats::aov(formula, data = d)
  expect_gt(stats::df.residual(oracle), 0)
  # Independently fitted fixed effects span the included random intercepts.
  # ADR-020 defines this relative roundoff bound; no absolute cutoff is used.
  expect_lte(sum(stats::residuals(oracle)^2) / sum((d$y - mean(d$y))^2),
             (64 * .Machine$double.eps)^2)
  result <- rework_error(msa_fit(runs, interactions = TRUE),
                         "Degenerate numeric model: residual variance is zero at working precision.")
  expect_length(result$warnings, 0L)
}

test_that("missing and removed replicates diagnose zero residual variance before the start fit", {
  complete <- residual_design_runs()
  missing <- complete
  missing$value[16L] <- NA_real_
  for (runs in list(missing, complete[-1L, ])) {
    residual_design_expect_zero(runs, y ~ item * prompt)
  }
})

test_that("unbalanced replicated cell values retain the relative residual diagnostic across scales (seed 7)", {
  set.seed(7L)
  d <- expand.grid(item_id = paste0("I", 1:5), prompt_id = paste0("P", 1:3),
                    model_id = "M1", rep = 1:3, stringsAsFactors = FALSE)
  d$value <- rep(stats::rnorm(15), 3)
  for (removed in list(1L, c(1L, 17L, 33L))) {
    for (scale in c(1, 1e-100, 1e100, -7.5)) {
      runs <- as_msa_runs(d[-removed, ])
      runs$value <- runs$value * scale
      residual_design_expect_zero(runs, y ~ item * prompt)
    }
  }
})

test_that("the residual diagnostic includes model and block effects with incomplete cells", {
  d <- expand.grid(item_id = 1:4, prompt_id = 1:2, model_id = 1:3,
                    block = 1:2, rep = 1:2)
  # A constructed response in the model span, including all pair interactions
  # and the additive block effect, with no replicate error.
  d$value <- sin(d$item_id) + cos(d$prompt_id) + sin(d$model_id) + d$block / 3 +
    d$item_id * d$prompt_id / 7 + d$item_id * d$model_id / 11 + d$prompt_id * d$model_id / 13
  d <- d[-c(1L, 17L, 33L), ]
  d <- d[!(d$item_id == 4 & d$prompt_id == 2 & d$model_id == 3), ]
  runs <- as_msa_runs(d)
  residual_design_expect_zero(runs, y ~ (item + prompt + model)^2 + block)
  reordered <- runs[rev(seq_len(nrow(runs))), ]
  for (column in c("item_id", "prompt_id", "model_id", "block")) {
    labels <- unique(reordered[[column]])
    reordered[[column]] <- paste0("level", match(reordered[[column]], rev(labels)))
  }
  reordered$value <- reordered$value + 100
  residual_design_expect_zero(reordered, y ~ (item + prompt + model)^2 + block)
})

test_that("omitted interaction variation remains estimable in unbalanced replicated studies", {
  complete <- residual_design_runs()
  missing <- complete
  missing$value[16L] <- NA_real_
  for (runs in list(missing, complete[-1L, ])) {
    d <- numeric_test_frame(runs[!is.na(runs$value), ])
    oracle <- stats::aov(y ~ item + prompt, data = d)
    expect_gt(sum(stats::residuals(oracle)^2) / sum((d$y - mean(d$y))^2),
               (64 * .Machine$double.eps)^2)
    reference <- suppressMessages(lme4::lmer(y ~ 1 + (1 | item) + (1 | prompt),
      data = d, REML = TRUE, control = lme4::lmerControl(optimizer = "bobyqa")))
    v <- as.data.frame(lme4::VarCorr(reference))
    expected <- stats::setNames(v$vcov, v$grp)
    for (scale in c(1, 1e-100, 1e100)) {
      scaled <- runs
      scaled$value <- scaled$value * scale
      fit <- suppressMessages(msa_fit(scaled, interactions = FALSE))
      expect_identical(fit$numerics$method, "analytic_reml")
      observed <- numeric_components(fit) / scale^2
      expect_setequal(names(observed), names(expected))
      expect_gt(observed[["Residual"]], 0)
      expect_lte(max(abs(observed[names(expected)] - expected)) / sum(expected),
                   numeric_tolerance("oracle", "variance_component_tol_fraction_of_total_variance"))
      expect_identical(fit$n$observations, nrow(d))
    }
  }
})

test_that("thin observed crossings use analytic REML and agree with the lmer oracle", {
  runs <- numeric_test_runs()
  runs <- runs[runs$rep == 1L, ][-c(1L, 2L), ]
  d <- numeric_test_frame(runs)
  expect_lt(nrow(d), nlevels(d$item) * nlevels(d$prompt))
  fit <- suppressMessages(msa_fit(runs, interactions = FALSE))
  expect_identical(fit$numerics$method, "analytic_reml")
  reference <- suppressMessages(lme4::lmer(y ~ 1 + (1 | item) + (1 | prompt),
    data = d, REML = TRUE, control = lme4::lmerControl(optimizer = "bobyqa")))
  v <- as.data.frame(lme4::VarCorr(reference))
  expected <- stats::setNames(v$vcov, v$grp)
  expect_lte(max(abs(numeric_components(fit)[names(expected)] - expected)) / sum(expected),
               numeric_tolerance("oracle", "variance_component_tol_fraction_of_total_variance"))
  expect_identical(fit$n$observations, nrow(runs))
  expect_identical(fit$n$reps_per_cell, c(1L, 1L))
})

test_that("a saturated fixed-effect span can still have positive REML residual variance (seed 1)", {
  set.seed(1L)
  runs <- as_msa_runs(data.frame(item_id = c(1, 1, 2, 2, 3, 4),
    prompt_id = c(1, 2, 2, 3, 3, 3), model_id = "M", rep = 1L, value = stats::rnorm(6)))
  d <- numeric_test_frame(runs)
  # With full row rank, every response is in span(1, Z). Zero OLS residuals
  # alone cannot diagnose the mixed-model residual variance in this case.
  expect_identical(stats::df.residual(stats::aov(y ~ item + prompt, data = d)), 0L)
  reference <- suppressMessages(lme4::lmer(y ~ 1 + (1 | item) + (1 | prompt),
    data = d, REML = TRUE, control = lme4::lmerControl(optimizer = "bobyqa")))
  v <- as.data.frame(lme4::VarCorr(reference))
  expected <- stats::setNames(v$vcov, v$grp)
  fit <- suppressMessages(msa_fit(runs, interactions = FALSE))
  observed <- numeric_components(fit)
  expect_identical(fit$numerics$method, "analytic_reml")
  expect_lte(max(abs(observed[names(expected)] - expected)) / sum(expected),
               numeric_tolerance("oracle", "variance_component_tol_fraction_of_total_variance"))
  expect_identical(unname(observed[c("item", "prompt")]), c(0, 0))
  # At this variance boundary, intercept-only REML has the closed solution
  # sigma_e^2 = SST / (n - 1), independently computed by var().
  expect_equal(observed[["Residual"]], stats::var(d$y),
                 tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  expect_identical(fit$n$observations, nrow(runs))
})

test_that("positive profiled Q is diagnosed at the relative roundoff bound", {
  # For y = (-1, 1, -1, 1) and Z = y, H = I + lambda * y y'. On the space
  # orthogonal to the intercept, Q = y'H^-1 y = 4 / (1 + 4 * lambda).
  # This independent rank-one covariance formula exercises Q without a
  # preceding Cholesky failure from redundant random-intercept columns.
  y <- c(-1, 1, -1, 1)
  Zt <- Matrix::Matrix(matrix(y, nrow = 1L), sparse = TRUE)
  evaluate <- msa_numeric_reml(Zt, 1L, y)
  bound <- (64 * .Machine$double.eps)^2
  for (lambda in c(1 / (8 * bound), 1 / bound)) {
    expected <- 4 / (1 + 4 * lambda)
    expect_gt(expected, 0)
    if (expected <= bound * sum(y^2)) {
      rework_error(evaluate(lambda), "Degenerate numeric model: residual variance is zero at working precision.")
    } else {
      # Profiling divides Q by the residual degrees of freedom n - 1.
      expect_equal(evaluate(lambda)$residual / (expected / (length(y) - 1)), 1,
                   tolerance = numeric_tolerance("oracle", "closed_form_rel_tol"))
    }
  }
})

test_that("explicit lme4 control preserves the engine result for the degenerate case", {
  runs <- residual_design_runs()
  runs$value[16L] <- NA_real_
  d <- numeric_test_frame(runs[!is.na(runs$value), ])
  control <- lme4::lmerControl()
  direct <- rework_capture(lme4::lmer(y ~ 1 + (1 | item) + (1 | prompt) + (1 | item:prompt),
                                      data = d, REML = TRUE, control = control))
  forwarded <- rework_capture(msa_fit(runs, interactions = TRUE, control = control))
  expect_identical(vapply(forwarded$warnings, conditionMessage, ""),
                   vapply(direct$warnings, conditionMessage, ""))
  if (inherits(direct$value, "error")) {
    expect_s3_class(forwarded$value, "error")
    expect_identical(conditionMessage(forwarded$value), conditionMessage(direct$value))
  } else {
    expect_identical(forwarded$value$numerics$method, "lmer")
    expect_equal(lme4::getME(forwarded$value$model, "theta"), lme4::getME(direct$value, "theta"),
                   tolerance = numeric_tolerance("engine_boot", "tol"))
  }
})
