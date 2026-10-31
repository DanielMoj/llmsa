test_that("genuine ucminf, matrix and multi-term clmm paths use the actual optimizer", {
  r <- latent_test_runs(prompts = 1L, models = 1L)
  control <- ordinal::clmm.control(method = "ucminf")
  one <- latent_test_capture(msa_fit(r, type = "ordinal", control = control))
  expect_s3_class(one$value$model$optRes, "ucminf")
  expect_true(one$value$model$optRes$convergence %in% c(1L, 2L))
  expect_true(one$value$converged)
  expect_false(any(grepl("did not converge", one$warnings, fixed = TRUE)))
  matrix <- latent_test_capture(msa_fit(r, type = "ordinal",
    control = ordinal::clmm.control(method = "ucminf", useMatrix = TRUE)))
  multi <- latent_test_capture(msa_fit(latent_test_runs(models = 1L), type = "ordinal", control = control))
  for (result in list(matrix, multi)) {
    expect_identical(result$value$model$control$method, "ucminf")
    expect_false(inherits(result$value$model$optRes, "ucminf"))
    expect_identical(result$value$model$optRes$convergence, 0L)
    expect_true(result$value$converged)
    expect_false(any(grepl("did not converge", result$warnings, fixed = TRUE)))
  }
  slow <- latent_test_capture(msa_fit(latent_test_runs(), type = "ordinal",
    control = ordinal::clmm.control(method = "nlminb", iter.max = 1L, eval.max = 2L)))
  expect_false(slow$value$model$optRes$convergence == 0L)
  expect_false(slow$value$converged)
  expect_true(any(grepl("Ordinal model did not converge:", slow$warnings, fixed = TRUE)))
})

test_that("singular glmer success and optimizer failure have independent flags", {
  r <- latent_test_runs("binary", prompts = 1L, models = 1L)
  r <- do.call(rbind, lapply(paste0("P", 1:3), function(p) transform(r, prompt_id = p)))
  singular <- latent_test_capture(msa_fit(r, type = "binary", link = "logit"))
  expect_true(lme4::isSingular(singular$value$model))
  expect_identical(as.integer(singular$value$model@optinfo$conv$opt), 0L)
  expect_identical(singular$value$model@optinfo$conv$lme4$messages,
                   "boundary (singular) fit: see help('isSingular')")
  expect_true(singular$value$singular)
  expect_true(singular$value$converged)
  expect_length(singular$warnings, 0L)
  failed <- latent_test_capture(msa_fit(latent_test_runs("binary"), type = "binary", link = "logit",
    control = lme4::glmerControl(optCtrl = list(maxfun = 10L))))
  expect_false(failed$value$converged)
  expect_gt(length(failed$warnings), 0L)
  expect_true(all(failed$value$model@optinfo$conv$lme4$messages %in% failed$warnings))
})

test_that("numeric completion and direct lmer report final status without extra warnings", {
  r <- msa_simulate(18, 1, 1, 3, vc = list(item = 1, residual = 1), seed = 1729)
  balanced <- latent_test_capture(msa_fit(r))
  unbalanced <- latent_test_capture(msa_fit(r[-1L, ]))
  direct <- latent_test_capture(msa_fit(r, control = lme4::lmerControl()))
  expect_identical(balanced$value$numerics$method, "closed_form")
  expect_identical(unbalanced$value$numerics$method, "analytic_reml")
  expect_identical(direct$value$numerics$method, "lmer")
  for (result in list(balanced, unbalanced, direct)) {
    expect_identical(as.integer(result$value$model@optinfo$conv$opt), 0L)
    expect_null(result$value$model@optinfo$conv$lme4$messages)
    expect_true(result$value$converged)
    expect_length(result$warnings, 0L)
  }
  failed <- latent_test_capture(msa_fit(r,
    control = lme4::lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 1L))))
  expect_false(failed$value$converged)
  oracle <- latent_test_capture(lme4::lmer(y ~ (1 | item), data = numeric_test_frame(r), REML = TRUE,
    control = lme4::lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 1L))))
  expect_identical(failed$warnings, oracle$warnings)
  # Controlled final diagnostics complement the genuine engine runs above.
  model <- balanced$value$model
  start <- list(warnings = "Synthetic initialization Hessian diagnostic")
  local_mocked_bindings(msa_numeric_fit = function(...) list(model = model,
    numerics = list(method = "closed_form", start = start)))
  got <- latent_test_capture(msa_fit(r))
  expect_true(got$value$converged)
  expect_identical(got$value$numerics$start, start)
  expect_length(got$warnings, 0L)
  model@optinfo$conv$lme4$messages <- "Synthetic final Hessian diagnostic"
  got <- latent_test_capture(msa_fit(r))
  expect_false(got$value$converged)
  expect_identical(got$value$model@optinfo$conv$lme4$messages, "Synthetic final Hessian diagnostic")
  expect_length(got$warnings, 0L)
})

test_that("unusual and missing optimizer codes never become assumed success", {
  for (code in list(NULL, NA_real_, NaN, Inf, "unreadable", list(0), numeric(), c(0, 1))) {
    expect_identical(msa_mer_converged(list(opt = code)), FALSE)
    expect_identical(msa_clmm_converged(list(ST = list(item = matrix(1)),
      control = list(method = "nlminb"), optRes = list(convergence = code))), FALSE)
  }
  for (code in 0:4) for (method in c("nlminb", "ucminf", "unknown")) {
    expected <- if (method == "nlminb") code == 0L else if (method == "ucminf") code %in% c(1L, 2L) else FALSE
    expect_identical(msa_clmm_converged(list(ST = list(item = matrix(1)),
      control = list(method = method), optRes = list(convergence = code))), expected)
  }
  expect_false(msa_clmm_converged(list(ST = list(item = matrix(1)), optRes = list(convergence = 0L))))
  expect_false(msa_mer_converged(list(opt = 0L, lme4 = list(messages = "large gradient"))))
})
