# K-M1a-6: invariances and edge cases (numeric). Permuting the rows, renaming
# the levels of all factors and shifting all values by a constant leave the
# variance components (ankerRef: ANK-TOL.invariance as a fraction of
# sigma2_TV), %GRR (relative), ndc and verdict (equal) unchanged; scaling by c
# multiplies all variances by c^2 and leaves %GRR, % contribution, ndc, ICC and
# verdict unchanged; the test data keep the distances of ANK-TOL.invariance to
# the rounding and threshold limits. Edge cases: a true component near zero is
# reported with singular = TRUE and never negative; an unbalanced plan (cells
# and replicates removed at random) is fitted and n$reps_per_cell and
# n$observations describe it; identical values in all rows give an error or the
# verdict "undetermined", never NaN in summary; a non-converging fit passes the
# lme4 warning on. msa_fit() runs with its defaults (ADR-012 Nr. 1, BL-72;
# ACC-6, ACC-13).

acc_m1a_6_cases <- function() {
  if (is.null(acc_m1a$inv_cases)) {
    acc_m1a$inv_cases <- list(
      ic50_demo = acc_m1a_dataset("ic50_demo"),
      "simulated balanced plan" = acc_m1a_simulate(acc_m1a_designs()[["interactions, 3 blocks"]], seed = 1L)
    )
  }
  acc_m1a$inv_cases
}

acc_m1a_6_fit <- function(runs) {
  fit <- acc_m1a_quiet(msa_fit(runs, type = "numeric"))
  list(fit = fit, v = acc_m1a_components(fit), g = msa_grr(fit))
}

acc_m1a_6_original <- function(name) {
  key <- paste0("inv_original_", name)
  if (is.null(acc_m1a[[key]])) acc_m1a[[key]] <- acc_m1a_6_fit(acc_m1a_6_cases()[[name]])
  acc_m1a[[key]]
}

acc_m1a_6_frame <- function(runs) as.data.frame(runs, stringsAsFactors = FALSE)

acc_m1a_6_permute <- function(runs) {
  d <- acc_m1a_6_frame(runs)
  idx <- acc_m1a_with_seed(20261024L, sample.int(nrow(d)))
  d <- d[idx, , drop = FALSE]
  rownames(d) <- NULL
  as_msa_runs(d)
}

# New labels in reverse order of the old ones, so that the level order changes.
acc_m1a_6_relabel <- function(runs) {
  d <- acc_m1a_6_frame(runs)
  for (col in c("item_id", "prompt_id", "model_id", "block")) {
    old <- sort(unique(as.character(d[[col]])))
    new <- paste0("z", sprintf("%04d", rev(seq_along(old))))
    d[[col]] <- new[match(as.character(d[[col]]), old)]
  }
  as_msa_runs(d)
}

acc_m1a_6_affine <- function(runs, scale = 1, shift = 0) {
  d <- acc_m1a_6_frame(runs)
  d$value <- as.numeric(d$value) * scale + shift
  as_msa_runs(d)
}

# Preconditions of ANK-TOL.invariance on the untransformed fit.
acc_m1a_6_expect_distances <- function(o, name) {
  r <- acc_m1a_grr_reference(o$v)
  dist_ndc <- abs(r$ndc_raw - round(r$ndc_raw))
  expect_gte(dist_ndc, acc_m1a_tol("invariance", "ndc_min_distance_to_integer"),
             label = sprintf("%s: distance of 1.41 sd_PV/sd_GRR = %.4f to the next integer", name, r$ndc_raw))
  pct <- acc_m1a_summary(o$g, "grr_pct_study_var")
  expect_gte(min(abs(pct - acc_m1a_thresholds())), acc_m1a_tol("invariance", "grr_min_distance_to_threshold_points"),
             label = sprintf("%s: distance of %%GRR = %.3f to the thresholds", name, pct))
}

acc_m1a_6_expect_unchanged <- function(o, t, name, what, scale = 1) {
  label <- paste0(name, ", ", what)
  total <- sum(o$v)
  acc_m1a_expect_components(t$v / scale^2, o$v, acc_m1a_tol("invariance", "component_tol_fraction_of_total_variance"),
                            total, label)
  rel <- acc_m1a_tol("invariance", "derived_rel_tol")
  derived <- if (scale == 1) "grr_pct_study_var" else c("grr_pct_study_var", "grr_pct_contribution", "icc_items")
  for (k in derived) {
    acc_m1a_expect_relative(acc_m1a_summary(t$g, k), acc_m1a_summary(o$g, k), rel, paste0(label, ", ", k))
  }
  expect_true(isTRUE(acc_m1a_summary(t$g, "ndc") == acc_m1a_summary(o$g, "ndc")), label = paste0(label, ": ndc unchanged"))
  expect_identical(t$g$verdict, o$g$verdict, label = paste0(label, ": verdict"))
}

for (name in c("ic50_demo", "simulated balanced plan")) {
  test_that(sprintf("K-M1a-6: %s keeps the distances of ANK-TOL.invariance to the ndc and threshold limits (ankerRef: ANK-TOL.invariance)", name), {
    acc_m1a_6_expect_distances(acc_m1a_6_original(name), name)
  })

  test_that(sprintf("K-M1a-6: permuting the rows leaves components, %%GRR, ndc and verdict unchanged (%s; ankerRef: ANK-TOL.invariance)", name), {
    o <- acc_m1a_6_original(name)
    acc_m1a_6_expect_unchanged(o, acc_m1a_6_fit(acc_m1a_6_permute(acc_m1a_6_cases()[[name]])), name, "rows permuted")
  })

  test_that(sprintf("K-M1a-6: renaming the levels of all factors leaves components, %%GRR, ndc and verdict unchanged (%s; ankerRef: ANK-TOL.invariance)", name), {
    o <- acc_m1a_6_original(name)
    acc_m1a_6_expect_unchanged(o, acc_m1a_6_fit(acc_m1a_6_relabel(acc_m1a_6_cases()[[name]])), name, "levels renamed")
  })

  test_that(sprintf("K-M1a-6: shifting all values by a constant leaves components, %%GRR, ndc and verdict unchanged (%s; ankerRef: ANK-TOL.invariance)", name), {
    o <- acc_m1a_6_original(name)
    acc_m1a_6_expect_unchanged(o, acc_m1a_6_fit(acc_m1a_6_affine(acc_m1a_6_cases()[[name]], shift = 100)),
                               name, "shifted by 100")
  })

  test_that(sprintf("K-M1a-6: scaling by c multiplies all variances by c^2 and leaves %%GRR, %% contribution, ndc, ICC and verdict unchanged (%s; ankerRef: ANK-TOL.invariance)", name), {
    o <- acc_m1a_6_original(name)
    for (c in c(7.5, 0.02)) {
      acc_m1a_6_expect_unchanged(o, acc_m1a_6_fit(acc_m1a_6_affine(acc_m1a_6_cases()[[name]], scale = c)),
                                 name, sprintf("scaled by %g", c), scale = c)
    }
  })
}

test_that("K-M1a-6: a true component near zero is reported with singular = TRUE and never negative", {
  runs <- acc_m1a_with_seed(1L, msa_simulate(20, 4, 3, 3, 1,
    vc = list(item = 1, prompt = 0, model = 0.08, item_prompt = 0.05, item_model = 0.04, prompt_model = 0.03,
              residual = 0.1), seed = 1L))
  # equal prompt means: the prompt component is zero in the sample
  runs$value <- runs$value - stats::ave(runs$value, runs$prompt_id) + mean(runs$value)
  d <- acc_m1a_frame(runs)
  ref <- acc_m1a_anova_estimates(d, acc_m1a_terms(d, TRUE))
  expect_lt(ref[["prompt"]], 0, label = "precondition: the ANOVA estimator of the prompt component is negative")
  fit <- acc_m1a_quiet(msa_fit(runs, type = "numeric"))
  v <- acc_m1a_components(fit)
  expect_true(isTRUE(fit$singular))
  expect_true("prompt" %in% names(v))
  expect_true(all(is.finite(v)) && all(v >= 0), label = "no component of fit$vc is negative")
  g <- msa_grr(fit)
  expect_true(all(is.finite(g$table$variance)) && all(g$table$variance >= 0),
              label = "no variance in msa_grr()$table is negative")
})

test_that("K-M1a-6: an unbalanced plan (cells and replicates removed at random) is fitted; n$reps_per_cell gives the range and n$observations the remaining count", {
  runs <- acc_m1a_simulate(acc_m1a_designs()[["interactions, 3 blocks"]], seed = 1L)
  d <- acc_m1a_6_frame(runs)
  key <- function(d) paste(d$block, d$item_id, d$prompt_id, d$model_id, sep = "|")
  cells <- unique(key(d))
  # 10 % of the cells removed with all replicates (rows deleted) ...
  gone <- acc_m1a_with_seed(20261024L, sample(cells, round(0.1 * length(cells))))
  d <- d[!key(d) %in% gone, , drop = FALSE]
  # ... and in 20 % of the remaining cells one random replicate missing (value
  # NA, as for a failed call)
  left <- unique(key(d))
  thin <- acc_m1a_with_seed(20261025L, sample(left, round(0.2 * length(left))))
  rows <- acc_m1a_with_seed(20261026L, vapply(thin, function(k) {
    idx <- which(key(d) == k)
    idx[sample.int(length(idx), 1L)]
  }, integer(1)))
  d$value[rows] <- NA
  valid <- d[!is.na(d$value), , drop = FALSE]
  counts <- table(key(valid))
  expect_true(min(counts) < max(counts), label = "precondition: the plan is unbalanced")
  expect_lt(length(counts), length(cells))
  expect_lt(nrow(valid), nrow(d))
  fit <- NULL
  expect_no_error(fit <- acc_m1a_quiet(msa_fit(as_msa_runs(d), type = "numeric")))
  expect_false(is.null(fit))
  if (is.null(fit)) return(invisible())
  v <- acc_m1a_components(fit)
  expect_setequal(names(v), names(acc_m1a_6_fit(runs)$v))
  expect_true(all(is.finite(v)) && all(v >= 0))
  expect_identical(as.integer(fit$n$observations), nrow(valid))
  expect_identical(as.integer(fit$n$reps_per_cell), as.integer(range(counts)))
})

for (name in c("ic50_demo", "simulated balanced plan")) {
  test_that(sprintf("K-M1a-6: identical values in all rows give an error or the verdict undetermined, never NaN in summary (%s design)", name), {
    d <- acc_m1a_6_frame(acc_m1a_6_cases()[[name]])
    d$value <- 1.5
    res <- tryCatch(list(fit = suppressWarnings(acc_m1a_quiet(msa_fit(as_msa_runs(d), type = "numeric")))),
                    error = function(e) e)
    if (inherits(res, "error")) {
      expect_true(nzchar(conditionMessage(res)), label = "msa_fit() stops with a message")
      return(invisible())
    }
    g <- tryCatch(msa_grr(res$fit), error = function(e) e)
    if (inherits(g, "error")) {
      expect_true(nzchar(conditionMessage(g)), label = "msa_grr() stops with a message")
      return(invisible())
    }
    expect_identical(g$verdict, "undetermined")
    expect_false(any(is.nan(unlist(g$summary))), label = "summary holds no NaN")
  })
}

test_that("K-M1a-6: a non-converging fit passes the lme4 warning on", {
  runs <- acc_m1a_simulate(acc_m1a_designs()[["interactions, no block"]], seed = 1L)
  control <- lme4::lmerControl(optCtrl = list(maxeval = 5))
  catch <- function(expr) {
    found <- character()
    value <- withCallingHandlers(suppressMessages(expr), warning = function(w) {
      found <<- c(found, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
    list(value = value, warnings = found)
  }
  norm <- function(x) gsub("[[:space:]]+", " ", gsub("[0-9]+(\\.[0-9]+)?(e[-+]?[0-9]+)?", "#", x))
  # Oracle: the same model fitted directly with lme4 does not converge either.
  d <- acc_m1a_frame(runs)
  direct <- catch(lme4::lmer(y ~ 1 + (1 | item) + (1 | prompt) + (1 | model) + (1 | item:prompt) +
                               (1 | item:model) + (1 | prompt:model), data = d, REML = TRUE, control = control))
  expect_gte(length(direct$warnings), 1L, label = "precondition: lme4 warns for this control")
  res <- catch(msa_fit(runs, type = "numeric", control = control))
  expect_gte(length(res$warnings), 1L, label = "warnings reaching the caller of msa_fit()")
  conv <- res$value$model@optinfo$conv
  recorded <- c(conv$lme4$messages)
  expect_true(length(recorded) > 0L || !identical(as.integer(conv$opt), 0L),
              label = "precondition: lme4 records the non-convergence in the fitted model")
  for (m in recorded) {
    expect_true(norm(m) %in% norm(res$warnings), label = paste("lme4 message passed on:", m))
  }
  if (!identical(as.integer(conv$opt), 0L)) {
    expect_true(any(grepl("convergence code", res$warnings, fixed = TRUE)),
                label = "the optimizer warning of lme4 (convergence code) is passed on")
  }
})
