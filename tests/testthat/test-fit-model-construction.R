# Synthetic E54 reproductions (REVIEW M1a round 4). Noise levels and seeds
# are inputs, not tolerances. Reference components use Formelsammlung section 2.
model_build_runs <- function(noise = 1e-3, seed = 1001L) {
  set.seed(11L)
  d <- expand.grid(item_id = paste0("I", 1:6), prompt_id = paste0("P", 1:4),
                   model_id = "M1", rep = 1:2, stringsAsFactors = FALSE)
  item <- stats::rnorm(6)
  prompt <- stats::rnorm(4, sd = 0.7)
  interaction_effect <- stats::rnorm(24, sd = 0.4)
  d$value <- item[as.integer(factor(d$item_id))] + prompt[as.integer(factor(d$prompt_id))] +
    interaction_effect[as.integer(interaction(factor(d$item_id), factor(d$prompt_id)))]
  set.seed(seed)
  d$value <- d$value + noise * stats::rnorm(nrow(d))
  as_msa_runs(d)
}

model_build_reference <- function(runs) {
  d <- numeric_test_frame(runs)
  counts <- table(d$item, d$prompt)
  expect_true(all(counts == counts[1L]))
  oracle <- stats::aov(y ~ item * prompt, data = d)
  tab <- summary(oracle)[[1L]]
  ms <- stats::setNames(tab[["Mean Sq"]], trimws(rownames(tab)))
  # Explicit two-factor EMS formulas, independent of the product's marginal
  # effects and general EMS solver. stats::aov supplies the mean squares.
  components <- c(item = (ms[["item"]] - ms[["item:prompt"]]) / (nlevels(d$prompt) * counts[1L]),
                  prompt = (ms[["prompt"]] - ms[["item:prompt"]]) / (nlevels(d$item) * counts[1L]),
                  "item:prompt" = (ms[["item:prompt"]] - ms[["Residuals"]]) / counts[1L],
                  Residual = ms[["Residuals"]])
  expect_gt(stats::df.residual(oracle), 0)
  expect_gt(sum(stats::residuals(oracle)^2) / sum((d$y - mean(d$y))^2),
             (64 * .Machine$double.eps)^2)
  expect_true(all(is.finite(components) & components >= 0))
  components
}

model_build_expect_components <- function(fit, reference) {
  expect_s3_class(fit, "msa_fit")
  expect_identical(fit$numerics$method, "closed_form")
  observed <- numeric_components(fit)
  expect_setequal(names(observed), names(reference))
  expect_lte(max(abs(observed[names(reference)] - reference)) / sum(reference),
               numeric_tolerance("oracle", "variance_component_tol_fraction_of_total_variance"))
  expect_gt(observed[["Residual"]], 0)
  vc <- as.data.frame(lme4::VarCorr(fit$model))
  expect_identical(observed, stats::setNames(vc$vcov, vc$grp))
}

model_build_expect_failure <- function(out) {
  expect_s3_class(out$value, "simpleError")
  if (inherits(out$value, "error")) {
    # Own-output wording contract from ADR-022 section 6.2 and REVIEW E54;
    # no external numerical reference exists for the diagnostic text.
    expect_identical(conditionMessage(out$value),
      "Numeric model variance is not representable on the original scale at working precision.")
    expect_identical(class(out$value), c("simpleError", "error", "condition"))
    expect_null(conditionCall(out$value))
  }
}

# Reproductions on real rounding: which documented working-precision error
# arises depends on Matrix and CHOLMOD arithmetic (BL-89, ADR-039).
model_build_expect_named_precision_failure <- function(out) {
  expect_s3_class(out$value, "simpleError")
  if (inherits(out$value, "error")) {
    expect_true(conditionMessage(out$value) %in% c(
      "Numeric model variance is not representable on the original scale at working precision.",
      "Numeric model residual variance cannot be resolved at working precision."))
    expect_identical(class(out$value), c("simpleError", "error", "condition"))
    expect_null(conditionCall(out$value))
  }
}

for (case in list(c(noise = 1e-7, seed = 1002L), c(noise = 1e-8, seed = 1001L),
                  c(noise = 1e-8, seed = 1005L))) {
  test_that(sprintf("high repeatability gives ANOVA components or a named construction error (seed 11/%d, noise %g)",
                     case[["seed"]], case[["noise"]]), {
    runs <- model_build_runs(case[["noise"]], case[["seed"]])
    reference <- model_build_reference(runs)
    out <- rework_capture(msa_fit(runs))
    # A platform may resolve the model arithmetic; success must then agree
    # with the independent EMS result. A raw engine failure is never allowed.
    if (inherits(out$value, "error")) model_build_expect_named_precision_failure(out)
    else model_build_expect_components(out$value, reference)
    expect_false(any(grepl("CHOLMOD|Matrix|Cholesky|not positive definite",
                            vapply(out$warnings, conditionMessage, ""), ignore.case = TRUE)))
  })
}

test_that("the positive construction counterexample fits without warnings against ANOVA (seed 11/1001)", {
  runs <- model_build_runs()
  reference <- model_build_reference(runs)
  out <- rework_capture(msa_fit(runs))
  expect_length(out$warnings, 0L)
  model_build_expect_components(out$value, reference)
  expect_identical(as.numeric(stats::model.response(stats::model.frame(out$value$model))), runs$value)
})

# Inject conditions at every original-scale engine boundary. These tests do
# not depend on a particular BLAS/CHOLMOD implementation failing on real data.
for (stage in c("lFormula", "mkLmerDevfun", "devfun", "mkMerMod", "VarCorr")) {
  for (kind in c("error", "warning")) {
    test_that(sprintf("original-scale %s %s becomes a named error without leaked warnings", stage, kind), {
      cause <- structure(list(message = "Synthetic model arithmetic failure", call = quote(synthetic_model())),
                         class = c("synthetic_model_error", "error", "condition"))
      calls <- hits <- 0L
      signal <- function() {
        hits <<- hits + 1L
        if (kind == "error") stop(cause)
        warning("Synthetic model arithmetic warning", call. = FALSE)
      }
      binding <- if (stage == "devfun") "mkLmerDevfun" else stage
      engine <- get(binding, envir = asNamespace("lme4"))
      mocked <- function(...) {
        calls <<- calls + 1L
        if (stage == "lFormula" && calls == 1L) return(engine(...))
        if (stage == "devfun") {
          devfun <- engine(...)
          # Keep the real devfun environment for mkMerMod if a broken
          # implementation ignores the warning and continues.
          environment(devfun)$model_build_signal <- signal
          body(devfun) <- substitute({ model_build_signal(); original }, list(original = body(devfun)))
          return(devfun)
        }
        signal()
        engine(...)
      }
      do.call(local_mocked_bindings,
              c(stats::setNames(list(mocked), binding), list(.package = "lme4", .env = environment())))
      out <- rework_capture(msa_fit(model_build_runs()))
      model_build_expect_failure(out)
      expect_length(out$warnings, 0L)
      expect_identical(hits, 1L)
      if (stage == "lFormula") expect_identical(calls, 2L)
    })
  }
}

test_that("a deviance warning followed by an error stops before either condition escapes", {
  reached <- FALSE
  local_mocked_bindings(mkLmerDevfun = function(...) function(theta) {
    reached <<- TRUE
    warning("Synthetic CHOLMOD warning", call. = FALSE)
    stop("Synthetic deviance failure")
  }, .package = "lme4")
  out <- rework_capture(msa_fit(model_build_runs()))
  model_build_expect_failure(out)
  expect_true(reached)
  expect_length(out$warnings, 0L)
})

test_that("final convergence diagnostics remain active outside construction failure handling", {
  engine <- lme4::checkConv
  diagnostic <- NULL
  calls <- 0L
  local_mocked_bindings(checkConv = function(...) {
    calls <<- calls + 1L
    diagnostic <<- engine(...)
    warning("Synthetic final convergence warning", call. = FALSE)
    diagnostic
  }, .package = "lme4")
  runs <- model_build_runs()
  out <- rework_capture(msa_fit(runs))
  model_build_expect_components(out$value, model_build_reference(runs))
  expect_identical(calls, 1L)
  expect_identical(vapply(out$warnings, conditionMessage, ""), "Synthetic final convergence warning")
  expect_identical(out$value$model@optinfo$conv$lme4, diagnostic)
})

test_that("construction failure re-emits the analytic path's collected start warnings in order", {
  engine_start <- lme4::lmer
  engine_devfun <- lme4::mkLmerDevfun
  start_warnings <- character()
  builds <- 0L
  local_mocked_bindings(lmer = function(...) {
    initial <- withCallingHandlers(engine_start(...), warning = function(w) {
      start_warnings <<- c(start_warnings, conditionMessage(w))
    })
    warning("Synthetic first start warning", call. = FALSE)
    warning("Synthetic second start warning", call. = FALSE)
    initial
  }, mkLmerDevfun = function(...) {
    builds <<- builds + 1L
    if (builds == 2L) return(function(theta) {
      warning("Synthetic model arithmetic warning", call. = FALSE)
      stop("Synthetic model arithmetic failure")
    })
    engine_devfun(...)
  }, .package = "lme4")
  out <- rework_capture(msa_fit(numeric_test_runs()[-1L, ]))
  model_build_expect_failure(out)
  expect_identical(builds, 2L)
  expect_identical(vapply(out$warnings, conditionMessage, ""),
                     c(start_warnings, "Synthetic first start warning", "Synthetic second start warning"))
  expect_true(all(vapply(out$warnings, function(w) is.null(conditionCall(w)), logical(1))))
})

test_that("explicit fitting control preserves original engine construction conditions", {
  cause <- structure(list(message = "Synthetic direct model failure", call = quote(synthetic_model())),
                     class = c("synthetic_model_error", "error", "condition"))
  local_mocked_bindings(mkMerMod = function(...) {
    warning("Synthetic direct model warning", call. = FALSE)
    stop(cause)
  }, .package = "lme4")
  # noise = 1 keeps the input away from lme4's convergence checks: at the default
  # noise = 1e-3, macos-latest also warns about the Hessian (ADR-039).
  out <- rework_capture(msa_fit(model_build_runs(noise = 1), control = lme4::lmerControl(optimizer = "bobyqa")))
  expect_identical(out$value, cause)
  expect_identical(vapply(out$warnings, conditionMessage, ""), "Synthetic direct model warning")
})
