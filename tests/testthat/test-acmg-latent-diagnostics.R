test_that("AP1 keeps genuine ordinal fits with range and response-exclusion warnings", {
  p <- ap1_test_plan()
  r <- latent_test_runs(models = 1L, blocks = 2L)
  r$value <- acmg_classes(p)[as.integer(r$value)]
  r$value[1L] <- NA
  r$value[2L] <- "outside"
  got <- acmg_fit(r, p)
  expect_false(got$fallback)
  expect_identical(got$fit$type, "ordinal")
  expect_true(got$fit$converged)
  expect_identical(got$fit$derived, "block")
  expect_length(got$warnings$ordinal, 3L)
  expect_true(any(grepl("range method", got$warnings$ordinal, fixed = TRUE)))
  expect_true("1 missing response(s) were dropped." %in% got$warnings$ordinal)
  expect_true("1 value(s) are not among `levels` and were dropped." %in% got$warnings$ordinal)
  expect_false(any(acmg_convergence_warning(got$warnings$ordinal)))
  expect_identical(got$fit$n$observations, nrow(r) - 2L)
})

test_that("AP1 falls back on a real clmm limit diagnosis and retains the numeric oracle", {
  p <- ap1_test_plan()
  r <- latent_test_runs(models = 1L, blocks = 2L)
  r$value <- acmg_classes(p)[as.integer(r$value)]
  original <- msa_fit
  ordinal_fit <- NULL
  local_mocked_bindings(msa_fit = function(runs, type, ...) {
    if (type == "ordinal") {
      ordinal_fit <<- original(runs, type = type, ...,
        control = ordinal::clmm.control(method = "nlminb", iter.max = 1L, eval.max = 2L))
      ordinal_fit
    } else original(runs, type = type, ...)
  })
  got <- latent_test_capture(acmg_fit(r, p))$value
  expect_false(ordinal_fit$model$optRes$convergence == 0L)
  expect_false(ordinal_fit$converged)
  expect_true(got$fallback)
  expect_true(any(grepl("Ordinal model did not converge:", got$fallback_reason, fixed = TRUE)))
  expect_true(any(grepl("range method", got$warnings$ordinal, fixed = TRUE)))
  expect_false(any(grepl("range method", got$fallback_reason, fixed = TRUE)))
  expect_identical(got$fit$type, "numeric")
  numeric <- r
  numeric$value <- unname(unlist(p$evaluation$fallback_fit$scores)[r$value])
  direct <- latent_test_capture(original(numeric, type = "numeric"))$value
  latent_test_same_components(got$fit, direct, "engine_ordinal", "rel_tol")
  expect_identical(got$diagnostics$iterations, ordinal_fit$model$optRes$iterations)
})
