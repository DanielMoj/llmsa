test_that("binary fractions and non-finite codes are rejected before fitting", {
  r <- latent_test_runs("binary")
  for (value in c(-1, 2, 0.5, 1.9, Inf, -Inf)) {
    for (as_text in c(FALSE, TRUE)) {
      bad <- r
      bad$value[3L] <- value
      if (as_text) bad$value <- as.character(bad$value)
      expect_error(msa_fit(bad, type = "binary"), "Binary values must be 0 or 1.", fixed = TRUE)
    }
  }
  for (lv in list(character(), "only", c("no", "yes", "maybe"), c("yes", "yes"), c("no", NA))) {
    expect_error(msa_fit(r, type = "binary", levels = lv), "two distinct, non-missing labels", fixed = TRUE)
  }
})

test_that("binary event labels are explicit and invariant with bobyqa on both stages", {
  r <- latent_test_runs("binary", models = 1L, prompts = 1L)
  event <- r$value
  r$value <- factor(ifelse(event == 1L, "yes", "no"), levels = c("yes", "no"))
  expect_error(msa_fit(r, type = "binary"), "labels with `levels` given", fixed = TRUE)
  # Use the public control argument to resolve optimization error below the
  # unchanged invariance bound. Default-engine differences are recorded in ADR-026.
  control <- lme4::glmerControl(optimizer = "bobyqa",
    optCtrl = list(rhoend = numeric_tolerance("engine_boot", "tol")))
  base <- latent_test_capture(msa_fit(r, type = "binary", levels = c("no", "yes"), control = control))$value
  expect_identical(base$data$y, event)
  permuted <- latent_test_capture(msa_fit(r[rev(seq_len(nrow(r))), ], type = "binary", levels = c("no", "yes"), control = control))$value
  expect_identical(permuted$data$y, rev(event))
  latent_test_same_components(permuted, base)
  reversed <- latent_test_capture(msa_fit(r, type = "binary", levels = c("yes", "no"), control = control))$value
  expect_identical(reversed$data$y, 1L - event)
  latent_test_same_components(reversed, base)
  for (f in list(permuted, reversed)) {
    expect_equal(msa_grr(f)$summary[c("icc_items", "grr_pct_study_var")],
                 msa_grr(base)$summary[c("icc_items", "grr_pct_study_var")],
                 tolerance = numeric_tolerance("invariance", "derived_rel_tol"))
  }
})

test_that("categorical exclusions have counted warnings, actual counts and independent clean fits", {
  for (type in c("ordinal", "binary")) {
    r <- latent_test_runs(type, models = 1L, prompts = 1L)
    lv <- if (type == "ordinal") paste0("c", 1:5) else c("no", "yes")
    r$value <- if (type == "ordinal") as.character(r$value) else lv[r$value + 1L]
    r$value[1L] <- NA
    r$value[2L] <- "outside"
    got <- latent_test_capture(msa_fit(r, type = type, levels = lv, interactions = TRUE))
    expect_identical(got$warnings, c("1 missing response(s) were dropped.",
                                    "1 value(s) are not among `levels` and were dropped."))
    fit <- got$value
    clean <- latent_test_capture(msa_fit(r[-c(1L, 2L), ], type = type, levels = lv, interactions = TRUE))$value
    latent_test_same_components(fit, clean, "engine_ordinal", "rel_tol")
    expect_identical(fit$n$observations, nrow(r) - 2L)
    expect_equal(stats::nobs(fit$model), fit$n$observations)
    expect_identical(fit$n$reps_per_cell, c(1L, 3L))
    expect_false(any(c("prompt", "model", "block") %in% all.vars(fit$formula)))
    for (group in c("item_id", "prompt_id", "model_id", "block")) {
      bad <- r
      bad[[group]][1L] <- NA  # Even a row whose response would be discarded.
      expect_error(msa_fit(bad, type = type, levels = lv), "grouping factors must not contain missing values", fixed = TRUE)
    }
    all_missing <- r
    all_missing$value[] <- NA
    out <- rework_capture(msa_fit(all_missing, type = type, levels = lv))
    expect_match(conditionMessage(out$value), "No valid", fixed = TRUE)
    expect_identical(conditionMessage(out$warnings[[1L]]), paste(nrow(r), "missing response(s) were dropped."))
    outside <- r
    outside$value[] <- "outside"
    out <- rework_capture(msa_fit(outside, type = type, levels = lv))
    expect_identical(conditionMessage(out$value), "No valid response categories to analyse.")
    constant <- r
    constant$value[] <- lv[1L]
    expect_error(msa_fit(constant, type = type, levels = lv), "Response is constant", fixed = TRUE)
  }
})

test_that("two-level contrasts retain the range component under ucminf recoding and renaming", {
  r <- latent_test_runs(prompts = 2L, models = 2L, blocks = 2L)
  # One random term permits ucminf. Its standard settings resolve this
  # parameterization comparison; overly small gradient settings need not do so.
  control <- ordinal::clmm.control(method = "ucminf")
  fit <- latent_test_capture(msa_fit(r, type = "ordinal", control = control))
  expect_true(fit$value$converged)
  expect_identical(fit$value$derived, c("prompt", "model", "block"))
  expect_length(fit$warnings, 1L)
  expect_match(fit$warnings, "E[beta-hat^2/2] = sigma^2 + Var(beta-hat)/2", fixed = TRUE)
  for (source in fit$value$derived) {
    coefficient <- fit$value$model$beta[[paste0(source, levels(fit$value$data[[source]])[2L])]]
    expect_equal(fit$value$vc$variance[fit$value$vc$source == source], coefficient^2 / 2,
                 tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  }
  sum_fit <- local({
    old <- options(contrasts = c("contr.sum", "contr.poly"))
    on.exit(options(old))
    latent_test_capture(msa_fit(r, type = "ordinal", control = control))$value
  })
  for (source in sum_fit$derived) {
    # Sum coding puts effects +b and -b on the two levels: Var(+b, -b) = 2b^2.
    coefficient <- sum_fit$model$beta[[paste0(source, "1")]]
    expect_equal(sum_fit$vc$variance[sum_fit$vc$source == source], stats::var(c(coefficient, -coefficient)),
                 tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  }
  latent_test_same_components(sum_fit, fit$value)
  expect_true(sum_fit$converged)
  renamed <- r[rev(seq_len(nrow(r))), ]
  for (source in c("prompt_id", "model_id", "block")) {
    renamed[[source]] <- ifelse(renamed[[source]] == unique(r[[source]])[1L], "z", "a")
  }
  again <- latent_test_capture(msa_fit(renamed, type = "ordinal", control = control))
  expect_true(again$value$converged)
  expect_length(again$warnings, 1L)
  latent_test_same_components(again$value, fit$value)
})
