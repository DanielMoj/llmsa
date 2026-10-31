# E27: synthetic outcomes with a fixed seed; the independent references are
# explicit label coding, direct engine fits and the latent residual formula.
latent_call_expect_components <- function(fit, direct, type, link = "probit") {
  vc <- if (type == "ordinal") ordinal::VarCorr(direct) else lme4::VarCorr(direct)
  expected <- c(vapply(vc, function(x) as.numeric(x)[1L], numeric(1)),
    Residual = if (link == "probit") 1 else pi^2 / 3)
  got <- stats::setNames(fit$vc$variance, fit$vc$source)
  expect_setequal(names(got), names(expected))
  expect_lte(max(abs(got[names(expected)] - expected)) / sum(expected),
             numeric_tolerance("engine_ordinal", "rel_tol"))
}

test_that("explicit ordinal labels take precedence over ordered factor levels (seed 20261031)", {
  runs <- latent_test_runs(items = 18L, prompts = 1L, models = 1L)
  labels <- rev(levels(runs$value))
  dat <- data.frame(item = factor(runs$item_id), y = ordered(as.character(runs$value), levels = labels))
  direct <- ordinal::clmm(y ~ 1 + (1 | item), data = dat, link = "probit")
  expect_no_error(fit <- latent_test_capture(msa_fit(runs, type = "ordinal", levels = labels))$value)
  expect_identical(fit$levels, labels)
  expect_identical(fit$data$y, dat$y)
  latent_call_expect_components(fit, direct, "ordinal")
})

test_that("exactly two ordinal categories are fitted by the direct cumulative link model (seed 20261031)", {
  runs <- latent_test_runs("binary", items = 18L, prompts = 1L, models = 1L)
  labels <- c("low", "high")
  runs$value <- ordered(labels[runs$value + 1L], levels = labels)
  dat <- data.frame(item = factor(runs$item_id), y = runs$value)
  direct <- ordinal::clmm(y ~ 1 + (1 | item), data = dat, link = "probit")
  expect_no_error(fit <- latent_test_capture(msa_fit(runs, type = "ordinal", levels = labels))$value)
  expect_identical(fit$data$y, dat$y)
  expect_length(fit$model$alpha, length(labels) - 1L)
  latent_call_expect_components(fit, direct, "ordinal")
})

test_that("a stored binary call can be evaluated outside its original frame (seed 20261031)", {
  runs <- latent_test_runs("binary", items = 18L, prompts = 1L, models = 1L)
  expect_no_error(fit <- (function(r) {
    control <- lme4::glmerControl(optimizer = "bobyqa")
    known_offset <- seq_len(nrow(r)) / nrow(r)
    latent_test_capture(msa_fit(r, type = "binary", link = "logit", control = control,
      offset = known_offset, weights = 1L + as.integer(item) %% 2L))$value
  })(runs))
  expect_identical(fit$model@call[[1L]], quote(lme4::glmer))
  expect_no_error(again <- latent_test_capture(eval(fit$model@call, envir = new.env(parent = baseenv())))$value)
  dat <- data.frame(item = factor(runs$item_id), y = runs$value)
  direct <- latent_test_capture(lme4::glmer(y ~ 1 + (1 | item), data = dat,
    family = stats::binomial("logit"), control = lme4::glmerControl(optimizer = "bobyqa"),
    offset = seq_len(nrow(dat)) / nrow(dat), weights = 1L + as.integer(dat$item) %% 2L))$value
  latent_call_expect_components(fit, direct, "binary", "logit")
  expect_equal(lme4::getME(again, "theta"), lme4::getME(direct, "theta"),
               tolerance = numeric_tolerance("engine_ordinal", "rel_tol"))
  expect_equal(stats::fitted(again), stats::fitted(direct),
               tolerance = numeric_tolerance("arithmetic", "abs_tol"))
})
