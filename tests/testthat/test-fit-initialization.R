# Synthetic reproductions of REVIEW M1a round 3, E50. The noise levels are
# inputs, not numerical tolerances; stats::aov independently checks the rest.
initialization_test_runs <- function(case) {
  if (case == "removed") {
    set.seed(7L)
    d <- expand.grid(item_id = paste0("I", 1:5), prompt_id = paste0("P", 1:3),
                      model_id = "M1", rep = 1:3, stringsAsFactors = FALSE)
    d$value <- rep(stats::rnorm(15), 3)
    d <- d[-1L, ]
  } else {
    d <- expand.grid(item_id = paste0("I", 1:4), prompt_id = paste0("P", 1:2),
                      model_id = "M1", rep = 1:2, stringsAsFactors = FALSE)
    d$value <- rep(c(1.1, 2.3, 0.7, 4.5, 3.2, 1.8, 5.1, 0.9), 2)
    if (case == "missing") d$value[16L] <- NA_real_
  }
  set.seed(if (case == "missing") 1003L else 1001L)
  noise <- if (case == "balanced") 1e-9 else 1e-8
  d$value <- d$value + noise * stats::rnorm(nrow(d))
  as_msa_runs(d)
}

for (case in c("removed", "missing", "balanced")) {
  test_that(sprintf("small positive residual variance has a named start failure (%s; seeds 7/1001/1003)", case), {
    runs <- initialization_test_runs(case)
    d <- numeric_test_frame(runs[!is.na(runs$value), ])
    oracle <- stats::aov(y ~ item * prompt, data = d)
    expect_gt(stats::df.residual(oracle), 0)
    # ADR-020's relative zero bound is unchanged. These cases are positive,
    # so relabelling them as zero residual variance would be incorrect.
    expect_gt(sum(stats::residuals(oracle)^2) / sum((d$y - mean(d$y))^2),
               (64 * .Machine$double.eps)^2)
    # The direct engine supplies its own cause, rather than freezing its
    # diagnostic text. Centering and scaling are intercept invariances.
    delta <- d$y - d$y[1L]
    z <- delta / max(abs(delta))
    d$y <- z - mean(z)
    engine <- rework_capture(lme4::lmer(y ~ 1 + (1 | item) + (1 | prompt) + (1 | item:prompt),
      data = d, REML = TRUE, control = lme4::lmerControl(optimizer = "nloptwrap")))
    # Whether this direct start fails depends on rounding in the optimizer path;
    # on macos-latest two of the three inputs fit (BL-89, ADR-039). The synthetic
    # block below fixes the contract on every platform.
    if (inherits(engine$value, "error")) {
      expect_length(engine$warnings, 0L)
      # Only the diagnostic prefix is an own-output contract (no external
      # oracle for wording); the cause is from the independent lme4 call.
      out <- rework_error(msa_fit(runs, interactions = TRUE),
        paste0("Numeric model initialization failed: ", conditionMessage(engine$value)))
      expect_false(inherits(out$value, "Rcpp::exception"))
      expect_length(out$warnings, 0L)
    } else {
      out <- rework_capture(msa_fit(runs, interactions = TRUE))
      expect_false(inherits(out$value, "Rcpp::exception"))
      if (inherits(out$value, "error")) {
        # Documented in ?msa_fit: high repeatability can end any stage of the
        # default path at working precision, always under its own name.
        expect_match(conditionMessage(out$value),
                     "^(Numeric model |Degenerate numeric model: |Analytic REML did not converge )")
        expect_null(conditionCall(out$value))
      } else {
        expect_s3_class(out$value, "msa_fit")
      }
    }
  })
}

test_that("failed initialization retains its cause and re-emits every start warning in order", {
  # A synthetic engine condition isolates the warning/error contract from
  # platform-dependent optimizer roundoff. It is not a variance oracle.
  cause <- structure(list(message = "Synthetic initialization failure", call = quote(synthetic_start())),
                     class = c("synthetic_start_error", "error", "condition"))
  local_mocked_bindings(lmer = function(...) {
    warning("Synthetic first start warning", call. = FALSE)
    warning("Synthetic second start warning", call. = FALSE)
    stop(cause)
  }, .package = "lme4")
  runs <- numeric_test_runs()[-1L, ]
  out <- rework_error(msa_fit(runs),
                       "Numeric model initialization failed: Synthetic initialization failure")
  expect_false(inherits(out$value, "synthetic_start_error"))
  expect_identical(vapply(out$warnings, conditionMessage, ""),
                     c("Synthetic first start warning", "Synthetic second start warning"))
  expect_true(all(vapply(out$warnings, function(w) is.null(conditionCall(w)), logical(1))))
  # Any explicit fitting argument still selects the direct engine path.
  direct <- rework_capture(msa_fit(runs, control = NULL))
  expect_identical(direct$value, cause)
  expect_identical(vapply(direct$warnings, conditionMessage, ""),
                     vapply(out$warnings, conditionMessage, ""))
})

test_that("explicit fitting control keeps the engine outcome on the small-residual inputs", {
  control <- lme4::lmerControl()
  for (case in c("removed", "missing", "balanced")) {
    runs <- initialization_test_runs(case)
    d <- numeric_test_frame(runs[!is.na(runs$value), ])
    engine <- rework_capture(lme4::lmer(y ~ 1 + (1 | item) + (1 | prompt) + (1 | item:prompt),
      data = d, REML = TRUE, control = control))
    out <- rework_capture(msa_fit(runs, interactions = TRUE, control = control))
    expect_identical(vapply(out$warnings, conditionMessage, ""),
                       vapply(engine$warnings, conditionMessage, ""))
    if (inherits(engine$value, "error")) {
      expect_identical(class(out$value), class(engine$value))
      expect_identical(conditionMessage(out$value), conditionMessage(engine$value))
    } else {
      expect_s3_class(out$value, "msa_fit")
      expect_identical(out$value$numerics$method, "lmer")
      expect_equal(lme4::getME(out$value$model, "theta"), lme4::getME(engine$value, "theta"),
                     tolerance = numeric_tolerance("engine_boot", "tol"))
    }
  }
})

test_that("positive model residuals still fit at small absolute scales against the lmer oracle", {
  for (case in c("removed", "missing", "balanced")) {
    runs <- initialization_test_runs(case)
    d <- numeric_test_frame(runs[!is.na(runs$value), ])
    # Omitting the interaction gives an estimable residual; replicate ties
    # and a small absolute scale alone must not trigger the new error.
    oracle <- stats::aov(y ~ item + prompt, data = d)
    expect_gt(sum(stats::residuals(oracle)^2) / sum((d$y - mean(d$y))^2),
               (64 * .Machine$double.eps)^2)
    engine <- suppressMessages(lme4::lmer(y ~ 1 + (1 | item) + (1 | prompt),
      data = d, REML = TRUE, control = lme4::lmerControl(optimizer = "bobyqa")))
    vc <- as.data.frame(lme4::VarCorr(engine))
    expected <- stats::setNames(vc$vcov, vc$grp)
    for (scale in c(1, 1e-100)) {
      scaled <- runs
      scaled$value <- scaled$value * scale
      out <- rework_capture(msa_fit(scaled, interactions = FALSE))
      expect_length(out$warnings, 0L)
      expect_s3_class(out$value, "msa_fit")
      observed <- numeric_components(out$value) / scale^2
      expect_setequal(names(observed), names(expected))
      expect_lte(max(abs(observed[names(expected)] - expected)) / sum(expected),
                   numeric_tolerance("oracle", "variance_component_tol_fraction_of_total_variance"))
      expect_gt(observed[["Residual"]], 0)
    }
  }
})
