ordinal_control_runs <- function() {
  e <- new.env(parent = emptyenv())
  utils::data("wine", package = "ordinal", envir = e)
  w <- e$wine
  as_msa_runs(data.frame(item_id = w$bottle, prompt_id = w$judge,
    model_id = "M", rep = 1L, value = w$rating))
}

test_that("ordinal default limits apply with either link and other engine arguments", {
  runs <- ordinal_control_runs()
  for (link in c("probit", "logit")) for (extra in list(list(), list(Hess = TRUE))) {
    fit <- do.call(msa_fit, c(list(runs, type = "ordinal", link = link), extra))
    control <- fit$model$control$optCtrl
    # K-M1c-8 specification limits, not empirical reference constants.
    expect_identical(control$iter.max, 2000)
    expect_identical(control$eval.max, 4000)
    expect_true(fit$converged)
  }
})

test_that("explicit ordinal control replaces the limits even when empty", {
  runs <- ordinal_control_runs()
  controls <- list(ordinal::clmm.control(iter.max = 7), list(eval.max = 50), list())
  for (control in controls) {
    result <- latent_test_capture(msa_fit(runs, type = "ordinal", control = control))
    fit <- result$value
    direct <- latent_test_capture(ordinal::clmm(y ~ 1 + (1 | item) + (1 | prompt),
      data = fit$data, link = "probit", control = control))$value
    expect_identical(fit$model$control, direct$control)
    expect_identical(fit$model$call$control, control)
    if (identical(control, controls[[1L]])) {
      expect_false(fit$converged)
      expect_match(paste(result$warnings, collapse = " "), "did not converge")
    }
  }
  expect_error(msa_fit(runs, type = "ordinal", control = NULL), "'control' should be a list", fixed = TRUE)
})

test_that("direct optimizer options keep clmm precedence over the ordinal defaults", {
  runs <- ordinal_control_runs()
  result <- latent_test_capture(msa_fit(runs, type = "ordinal", iter.max = 7))
  fit <- result$value
  expect_identical(fit$model$control$optCtrl$iter.max, 7)
  expect_identical(fit$model$control$optCtrl$eval.max, 4000)
  expect_false(fit$converged)
  expect_match(paste(result$warnings, collapse = " "), "did not converge")
})
