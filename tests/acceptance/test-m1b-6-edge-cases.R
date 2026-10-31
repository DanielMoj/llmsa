# K-M1b-6: edge cases ordinal and binary. Fewer than three items with
# type = "ordinal" -> error with the wording of the documentation; all
# responses in one category -> error, never NaN; missing values or values not
# in `levels` are dropped with a warning and counted in n$observations; binary
# values outside {0, 1} -> error; non-convergence of clmm or glmer is passed on
# as a warning and singular/convergence is recorded in the object; a factor
# with one level is removed and not listed in formula.
# In addition, as ADR-022 Nr. 2 assigns it to M1b (BACKLOG BL-81; docs/01 §2
# Nr. 4: missing values are a mandatory edge case): a missing grouping value
# stops ordinal and binary fits with a named error.
# Contract details (error wording, field `converged`, triggers of
# non-convergence): CRITERIA.json, open ACC-10. Test data are constructed from
# the latent model (setup-m1b.R).

acc_m1b_6_levels <- acc_m1b_ordinal_levels()

acc_m1b_6_ordinal <- function(...) msa_fit(..., type = "ordinal", levels = acc_m1b_6_levels)
acc_m1b_6_binary <- function(...) msa_fit(..., type = "binary", link = "logit")

acc_m1b_6_expect_error <- function(res, pattern, label) {
  expect_s3_class(res$value, "error")
  if (inherits(res$value, "error")) {
    expect_true(grepl(pattern, conditionMessage(res$value), ignore.case = TRUE),
                label = sprintf("%s: the error message (%s) matches /%s/", label, conditionMessage(res$value), pattern))
  } else if (inherits(res$value, "msa_fit")) {
    g <- tryCatch(msa_grr(res$value), error = function(e) NULL)
    if (!is.null(g)) expect_false(any(is.nan(unlist(g$summary))), label = paste(label, ": no NaN in summary"))
  }
}

# Rows of a runs object as a new msa_runs object.
acc_m1b_6_rows <- function(runs, keep) as_msa_runs(as.data.frame(runs, stringsAsFactors = FALSE)[keep, , drop = FALSE])

test_that("K-M1b-6: fewer than three items with type = \"ordinal\" stop with an error worded as in the documentation of msa_fit()", {
  doc <- acc_m1b_rd_text("msa_fit")
  for (items in 1:2) {
    runs <- acc_m1b_ordinal_runs(seed = 61L, items = items, prompts = 3L, models = 3L, reps = 3L)
    res <- acc_m1b_catch(acc_m1b_6_ordinal(runs))
    expect_s3_class(res$value, "error")
    if (!inherits(res$value, "error")) next
    msg <- sub("[.]$", "", acc_m1b_norm(conditionMessage(res$value)))
    expect_true(nzchar(msg))
    expect_true(grepl(msg, doc, fixed = TRUE),
                label = sprintf("%d item(s): the error message \"%s\" appears word for word in man/msa_fit.Rd", items, msg))
  }
})

test_that("K-M1b-6: all ordinal responses in one category stop with an error, never NaN", {
  runs <- acc_m1b_ordinal_runs(seed = 62L)
  runs$value <- "c3"
  acc_m1b_6_expect_error(acc_m1b_catch(acc_m1b_6_ordinal(runs)), "categor|constant", "ordinal, one category")
})

test_that("K-M1b-6: all binary responses in one category (all 0, all 1) stop with an error, never NaN", {
  for (v in 0:1) {
    runs <- acc_m1b_binary_runs(seed = 62L)
    runs$value <- v
    acc_m1b_6_expect_error(acc_m1b_catch(acc_m1b_6_binary(runs)), "categor|constant", sprintf("binary, all %d", v))
  }
})

# Dropped responses: a warning, n$observations = remaining rows, and the fit is
# the fit on the remaining rows (ankerRef: ANK-TOL.engine_ordinal).
acc_m1b_6_expect_dropped <- function(runs, drop, fitter, label) {
  res <- acc_m1b_catch(fitter(runs))
  fit <- res$value
  expect_s3_class(fit, "msa_fit")
  if (!inherits(fit, "msa_fit")) return(invisible())
  expect_gte(length(res$warnings), 1L, label = paste(label, ": warnings"))
  remaining <- nrow(runs) - length(drop)
  expect_identical(as.integer(fit$n$observations), as.integer(remaining), label = paste(label, ": n$observations"))
  expect_identical(as.integer(stats::nobs(fit$model)), as.integer(remaining), label = paste(label, ": observations in the model"))
  clean <- acc_m1b_catch(fitter(acc_m1b_6_rows(runs, -drop)))$value
  expect_s3_class(clean, "msa_fit")
  if (!inherits(clean, "msa_fit")) return(invisible())
  ref <- acc_m1a_components(clean)
  acc_m1a_expect_components(acc_m1a_components(fit), ref, acc_m1b_engine_tol(), sum(ref), paste(label, ": fit on the remaining rows"))
}

acc_m1b_6_drop <- c(3L, 17L, 40L, 61L)

test_that("K-M1b-6: missing ordinal responses are dropped with a warning and n$observations counts the remaining rows", {
  runs <- acc_m1b_ordinal_runs(seed = 63L)
  runs$value[acc_m1b_6_drop] <- NA
  acc_m1b_6_expect_dropped(runs, acc_m1b_6_drop, acc_m1b_6_ordinal, "ordinal, missing values")
})

test_that("K-M1b-6: ordinal values not among `levels` are dropped with a warning and n$observations counts the remaining rows", {
  runs <- acc_m1b_ordinal_runs(seed = 64L)
  runs$value[acc_m1b_6_drop] <- "not a class"
  acc_m1b_6_expect_dropped(runs, acc_m1b_6_drop, acc_m1b_6_ordinal, "ordinal, values not in levels")
})

test_that("K-M1b-6: missing binary responses are dropped with a warning and n$observations counts the remaining rows", {
  runs <- acc_m1b_binary_runs(seed = 65L)
  runs$value[acc_m1b_6_drop] <- NA
  acc_m1b_6_expect_dropped(runs, acc_m1b_6_drop, acc_m1b_6_binary, "binary, missing values")
})

test_that("K-M1b-6: binary labels not among `levels` are dropped with a warning and n$observations counts the remaining rows", {
  runs <- acc_m1b_binary_runs(seed = 66L)
  runs$value <- c("no", "yes")[runs$value + 1L]
  runs$value[acc_m1b_6_drop] <- "maybe"
  fitter <- function(r) msa_fit(r, type = "binary", link = "logit", levels = c("no", "yes"))
  acc_m1b_6_expect_dropped(runs, acc_m1b_6_drop, fitter, "binary labels, values not in levels")
})

test_that("K-M1b-6: binary values outside {0, 1} stop with an error", {
  for (bad in c(2, -1, 0.5)) {
    runs <- acc_m1b_binary_runs(seed = 67L)
    runs$value <- as.numeric(runs$value)
    runs$value[5] <- bad
    acc_m1b_6_expect_error(acc_m1b_catch(acc_m1b_6_binary(runs)), "binary", sprintf("binary value %g", bad))
  }
})

test_that("K-M1b-6: non-convergence of clmm is passed on as a warning and recorded in the object (converged = FALSE)", {
  runs <- acc_m1b_ordinal_runs(seed = 68L, items = 20L)
  control <- ordinal::clmm.control(method = "nlminb", iter.max = 1, eval.max = 2)
  # Oracle: the same model fitted directly with clmm does not converge; clmm
  # records it in optRes without a warning of its own.
  d <- acc_m1b_frame(runs, "ordinal", acc_m1b_6_levels)
  direct <- acc_m1b_catch(ordinal::clmm(y ~ 1 + (1 | item) + (1 | prompt) + (1 | model), data = d, link = "probit",
                                        control = control))$value
  expect_true(inherits(direct, "clmm") && !identical(as.integer(direct$optRes$convergence), 0L),
              label = "precondition: the direct clmm with this control reports non-convergence")
  res <- acc_m1b_catch(acc_m1b_6_ordinal(runs, control = control))
  expect_s3_class(res$value, "msa_fit")
  expect_gte(length(res$warnings), 1L, label = "warnings reaching the caller of msa_fit()")
  if (inherits(res$value, "msa_fit")) expect_identical(res$value$converged, FALSE)
})

test_that("K-M1b-6: non-convergence of glmer is passed on as a warning and recorded in the object (converged = FALSE)", {
  runs <- acc_m1b_binary_runs(seed = 69L, items = 20L)
  control <- lme4::glmerControl(optCtrl = list(maxfun = 10))
  norm <- function(x) gsub("[[:space:]]+", " ", gsub("[0-9]+(\\.[0-9]+)?(e[-+]?[0-9]+)?", "#", x))
  d <- acc_m1b_frame(runs, "binary")
  direct <- acc_m1b_catch(lme4::glmer(y ~ 1 + (1 | item) + (1 | prompt) + (1 | model), data = d,
                                      family = stats::binomial("logit"), control = control))
  expect_gte(length(direct$warnings), 1L, label = "precondition: glmer warns for this control")
  res <- acc_m1b_catch(acc_m1b_6_binary(runs, control = control))
  expect_s3_class(res$value, "msa_fit")
  if (!inherits(res$value, "msa_fit")) return(invisible())
  expect_gte(length(res$warnings), 1L, label = "warnings reaching the caller of msa_fit()")
  conv <- res$value$model@optinfo$conv
  recorded <- c(conv$lme4$messages)
  expect_true(length(recorded) > 0L || !identical(as.integer(conv$opt), 0L),
              label = "precondition: lme4 records the non-convergence in the fitted model")
  for (m in recorded) expect_true(norm(m) %in% norm(res$warnings), label = paste("lme4 message passed on:", m))
  expect_identical(res$value$converged, FALSE)
})

test_that("K-M1b-6: converging ordinal and binary fits record converged = TRUE", {
  runs_o <- acc_m1b_ordinal_runs(seed = 70L, items = 20L, vc = list(item = 1, prompt = 0.5, model = 0.5))
  d <- acc_m1b_frame(runs_o, "ordinal", acc_m1b_6_levels)
  direct <- ordinal::clmm(y ~ 1 + (1 | item) + (1 | prompt) + (1 | model), data = d, link = "probit")
  expect_identical(as.integer(direct$optRes$convergence), 0L, label = "precondition: the direct clmm converges")
  fit <- acc_m1b_catch(acc_m1b_6_ordinal(runs_o))$value
  expect_s3_class(fit, "msa_fit")
  if (inherits(fit, "msa_fit")) expect_identical(fit$converged, TRUE)
  runs_b <- acc_m1b_binary_runs(seed = 70L, items = 40L, vc = list(item = 1, prompt = 0.5, model = 0.5))
  db <- acc_m1b_frame(runs_b, "binary")
  m <- acc_m1b_catch(lme4::glmer(y ~ 1 + (1 | item) + (1 | prompt) + (1 | model), data = db,
                                 family = stats::binomial("logit")))
  expect_true(!length(m$warnings) && identical(as.integer(m$value@optinfo$conv$opt), 0L) &&
                !length(m$value@optinfo$conv$lme4$messages) && !lme4::isSingular(m$value),
              label = "precondition: the direct glmer converges without message and is not singular")
  fitb <- acc_m1b_catch(acc_m1b_6_binary(runs_b))$value
  expect_s3_class(fitb, "msa_fit")
  if (inherits(fitb, "msa_fit")) expect_identical(fitb$converged, TRUE)
})

# Responses that do not depend on the prompt: the same values for every prompt.
acc_m1b_6_prompt_free <- function(runs) {
  d <- as.data.frame(runs, stringsAsFactors = FALSE)
  d <- d[d$prompt_id == "P1", , drop = FALSE]
  as_msa_runs(do.call(rbind, lapply(paste0("P", 1:3), function(p) transform(d, prompt_id = p))))
}

test_that("K-M1b-6: a component estimated at the boundary is recorded as singular in ordinal and binary fits", {
  runs_o <- acc_m1b_6_prompt_free(acc_m1b_ordinal_runs(seed = 71L, items = 20L, prompts = 1L))
  d <- acc_m1b_frame(runs_o, "ordinal", acc_m1b_6_levels)
  direct <- ordinal::clmm(y ~ 1 + (1 | item) + (1 | prompt) + (1 | model), data = d, link = "probit")
  expect_identical(as.numeric(acc_m1b_clmm_components(direct)[["prompt"]]), 0,
                   label = "precondition: the direct clmm estimates the prompt variance at 0")
  fit <- acc_m1b_catch(acc_m1b_6_ordinal(runs_o))$value
  expect_s3_class(fit, "msa_fit")
  if (inherits(fit, "msa_fit")) {
    expect_true(isTRUE(fit$singular), label = "ordinal fit: singular = TRUE")
    expect_true(all(fit$vc$variance >= 0), label = "ordinal fit: no negative component")
  }
  runs_b <- acc_m1b_6_prompt_free(acc_m1b_binary_runs(seed = 71L, items = 30L, prompts = 1L))
  db <- acc_m1b_frame(runs_b, "binary")
  m <- acc_m1a_quiet(lme4::glmer(y ~ 1 + (1 | item) + (1 | prompt) + (1 | model), data = db,
                                 family = stats::binomial("logit")))
  expect_true(lme4::isSingular(m), label = "precondition: the direct glmer is singular")
  fitb <- acc_m1b_catch(acc_m1b_6_binary(runs_b))$value
  expect_s3_class(fitb, "msa_fit")
  if (inherits(fitb, "msa_fit")) {
    expect_true(isTRUE(fitb$singular), label = "binary fit: singular = TRUE")
    expect_true(all(fitb$vc$variance >= 0), label = "binary fit: no negative component")
  }
})

test_that("K-M1b-6: a factor with one level is removed and not listed in formula (ordinal and binary)", {
  cases <- list(
    ordinal = list(runs = acc_m1b_ordinal_runs(seed = 72L, models = 1L), fitter = acc_m1b_6_ordinal),
    binary = list(runs = acc_m1b_binary_runs(seed = 72L, models = 1L), fitter = acc_m1b_6_binary))
  for (type in names(cases)) {
    fit <- acc_m1b_catch(cases[[type]]$fitter(cases[[type]]$runs))$value
    expect_s3_class(fit, "msa_fit")
    if (!inherits(fit, "msa_fit")) next
    for (f in c("model", "block")) {
      expect_false(f %in% all.vars(fit$formula), label = sprintf("%s: %s (one level) in formula", type, f))
      expect_false(f %in% fit$vc$source, label = sprintf("%s: %s (one level) in vc", type, f))
    }
  }
})

test_that("K-M1b-6 (ADR-022 Nr. 2, BL-81): a missing grouping value stops ordinal and binary fits with an error naming it missing", {
  for (col in c("item_id", "prompt_id", "model_id", "block")) {
    ro <- acc_m1b_ordinal_runs(seed = 73L)
    ro[[col]][7] <- NA
    acc_m1b_6_expect_error(acc_m1b_catch(acc_m1b_6_ordinal(ro)), "missing", paste("ordinal, missing", col))
    rb <- acc_m1b_binary_runs(seed = 73L)
    rb[[col]][7] <- NA
    acc_m1b_6_expect_error(acc_m1b_catch(acc_m1b_6_binary(rb)), "missing", paste("binary, missing", col))
  }
})
