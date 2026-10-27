test_that("fit fallback responds to each convergence family and preserves other diagnostics", {
  p <- ap1_test_plan(); r <- ap1_test_runs(p, 12)
  r <- r[r$model_id == "sol", ]
  for (message in c("Model failed to converge", "Hessian is not positive definite", "max|grad| is excessive",
                    "large gradient", "model is nearly unidentifiable")) local({
    calls <- character()
    local_mocked_bindings(msa_fit = function(runs, type = c("numeric", "ordinal", "binary"), ...) {
      type <- match.arg(type); calls <<- c(calls, type)
      if (type == "ordinal") warning(message)
      ap1_test_fit_stub(runs, type, ...)
    })
    fit <- acmg_fit(r, p)
    expect_true(fit$fallback, info = message)
    expect_identical(calls, c("ordinal", "numeric"))
    expect_identical(fit$warnings$ordinal, message)
    expect_identical(fit$fallback_reason, message)
  })
  for (message in c("cannot use ucminf optimizer; using nlminb", "singular fit: component estimated at zero",
                    "diagnostic value 0.001")) local({
    calls <- character()
    local_mocked_bindings(msa_fit = function(runs, type = c("numeric", "ordinal", "binary"), ...) {
      type <- match.arg(type); calls <<- c(calls, type)
      warning(message)
      fit <- ap1_test_fit_stub(runs, type, ...)
      fit$vc$variance[2] <- 0
      fit$model <- list(optRes = list(iterations = 4L), gradient = c(-0.001, 0.002), Hessian = diag(c(1, 2)))
      fit
    })
    fit <- acmg_fit(r, p)
    expect_false(fit$fallback, info = message)
    expect_identical(calls, "ordinal")
    expect_identical(fit$warnings$ordinal, message)
    expect_identical(fit$diagnostics$iterations, 4L)
    expect_equal(fit$diagnostics$max_gradient, 0.002, tolerance = p$validation_tolerances$arithmetic)
    expect_equal(fit$diagnostics$hessian_condition, 2, tolerance = p$validation_tolerances$arithmetic)
  })
})

test_that("numeric fallback equals a direct fit with default interactions and retains warnings", {
  p <- ap1_test_plan(); r <- ap1_test_runs(p, 30)
  r <- r[r$model_id == "sol", ]
  numeric <- r
  numeric$value <- match(r$value, acmg_classes(p))
  original <- msa_fit
  expected <- original(numeric, type = "numeric")
  calls <- list()
  local_mocked_bindings(msa_fit = function(runs, type = c("numeric", "ordinal", "binary"), ...) {
    type <- match.arg(type)
    calls[[length(calls) + 1L]] <<- list(type = type, data = runs, extra = list(...))
    if (type == "ordinal") stop("Synthetic ordinal failure")
    warning("Synthetic numeric diagnostic")
    original(runs, type = type, ...)
  })
  got <- acmg_fit(r, p)
  expect_true(got$fallback)
  expect_identical(got$fallback_reason, "Synthetic ordinal failure")
  expect_true("Synthetic numeric diagnostic" %in% got$warnings$numeric)
  expect_false("interactions" %in% names(calls[[2]]$extra))
  expect_equal(calls[[2]]$data$value, numeric$value, tolerance = 0)
  expect_identical(calls[[2]]$data$item_id, r$item_id)
  expect_equal(got$fit$vc, expected$vc, tolerance = p$validation_tolerances$engine_ordinal)
  expect_equal(msa_grr(got$fit)$summary, msa_grr(expected)$summary, tolerance = p$validation_tolerances$engine_ordinal)
  permuted <- acmg_fit(r[rev(seq_len(nrow(r))), ], p)
  variance <- stats::setNames(permuted$fit$vc$variance, permuted$fit$vc$source)[expected$vc$source]
  # A component difference is scaled by total reference variance, including
  # components near zero, as required by the validation tolerance convention.
  relative_to_total <- abs(unname(variance) - expected$vc$variance) / sum(expected$vc$variance)
  expect_lte(max(relative_to_total), p$validation_tolerances$invariance)
  local_mocked_bindings(msa_fit = function(...) stop("Synthetic total failure"))
  expect_error(acmg_fit(r, p), "AP1 numeric fallback failed: Synthetic total failure")
})

test_that("modal NA, ties, weighted kappa and bootstrap exclusions follow the item rules", {
  p <- ap1_test_plan(); classes <- acmg_classes(p)
  expect_identical(acmg_modal(c(NA, NA, classes[1])), list(modal = NA_character_, has_modal = TRUE))
  expect_identical(acmg_modal(c(NA, classes[1])), list(modal = NA_character_, has_modal = FALSE))
  expect_identical(acmg_modal(character()), list(modal = NA_character_, has_modal = FALSE))
  rated <- c(classes[c(1, 3, 4, 5)], NA, classes[2]); ref <- classes[c(1, 2, 5, 4, 3, 2)]
  # Independent pairwise computation of observed and chance agreement.
  weight <- function(a, b) if (is.na(a)) 0 else 1 - abs(match(a, classes) - match(b, classes)) / (length(classes) - 1)
  observed <- mean(mapply(weight, rated, ref))
  chance <- mean(vapply(rated, function(a) mean(vapply(ref, function(b) weight(a, b), 0)), 0))
  expect_equal(acmg_kappa(rated, ref, classes), (observed - chance) / (1 - chance), tolerance = p$validation_tolerances$arithmetic)
  expect_lt(acmg_kappa(c(classes[-5], NA), classes, classes), acmg_kappa(c(classes[-5], classes[4]), classes, classes))
  expect_true(is.na(acmg_kappa(classes[1], classes[1], classes)))
  modal <- data.frame(modal = classes[c(1, 5)], reference = classes[c(1, 5)], has_modal = TRUE)
  set.seed(81); before <- .Random.seed
  interval <- acmg_kappa_interval(modal, p)
  expect_identical(.Random.seed, before)
  expect_equal(unlist(interval[c("estimate", "lower", "upper")]), c(estimate = 1, lower = 1, upper = 1))
  expect_gt(interval$discarded, 0L); expect_gt(interval$valid, 0L)
  expect_equal(interval$valid + interval$discarded, p$evaluation$kappa_bootstrap$replicates)
  expect_identical(acmg_kappa_interval(modal, p), interval)
  modal <- modal[1, ]
  undefined <- acmg_kappa_interval(modal, p)
  expect_equal(undefined$discarded, p$evaluation$kappa_bootstrap$replicates)
  expect_true(all(is.na(unlist(undefined[c("estimate", "lower", "upper")]))))
  modal$has_modal <- FALSE
  expect_identical(acmg_kappa_interval(modal, p)$n, 0L)
})

test_that("reference strata exclude unknown flags and keep NA modal responses as errors", {
  p <- ap1_test_plan(); classes <- acmg_classes(p)
  modal <- data.frame(modal = c(classes[1], NA, classes[3], classes[4]), has_modal = c(TRUE, TRUE, FALSE, TRUE),
                       reference = c(classes[1], classes[2], classes[3], NA), source = c("erepo", "erepo", "insaid", "insaid"),
                       prior_differs_sol = c(TRUE, FALSE, NA, NA), prior_differs_llama = NA, prior_differs_qwen = NA)
  got <- acmg_reference_metrics(modal, "llama", p)
  all <- got$hit_rate[got$hit_rate$by == "all", ]
  expect_identical(all$n, 2L); expect_identical(all$hits, 1L); expect_identical(all$rate, 0.5)
  unknown <- got$hit_rate[got$hit_rate$by == "prior_differs_llama", ]
  expect_true(all(unknown$n == 0L & is.na(unknown$rate)))
  expect_identical(got$hit_rate$n[got$hit_rate$by == "source" & got$hit_rate$group == "insaid"], 0L)
})

test_that("evaluation preserves input order and item metadata and labels unverified runs", {
  p <- ap1_test_plan(); r <- ap1_test_runs(p)
  r$meta <- NULL
  insaid <- r$source == "insaid"
  r$reference[insaid] <- acmg_classes(p)[1]
  r$value[insaid] <- acmg_classes(p)[1]
  r$prior_differs_qwen[insaid] <- TRUE
  r <- r[rev(seq_len(nrow(r))), ]
  r$item_id <- factor(r$item_id, levels = rev(unique(r$item_id)))
  captured <- list()
  local_mocked_bindings(msa_fit = function(runs, ...) {
    captured[[length(captured) + 1L]] <<- runs
    ap1_test_fit_stub(runs, ...)
  }, msa_report = ap1_test_report_stub)
  result <- acmg_evaluate(r, p)
  expect_identical(result$provenance, "unverified")
  expect_identical(captured[[1]], r)
  for (i in seq_along(result$models)) {
    key <- names(result$models)[i]
    expect_identical(captured[[i + 1L]], r[r$model_id == key, ])
    model <- result$models[[key]]
    rates <- model$hit_rate[model$hit_rate$by == "source" & model$hit_rate$group == "insaid", ]
    expect_equal(rates$n, length(unique(r$item_id[insaid])))
    expect_identical(rates$rate, 1)
    expect_true(model$reference_basis$insaid_references_loaded)
    expect_true(model$complete)
    expect_identical(model$provenance, "unverified")
  }
  expect_s3_class(result$joint, "msa_fit")
  expect_null(result$joint$verdict)
  permuted <- acmg_evaluate(r[order(r$item_id, r$model_id, r$rep), ], p)
  for (key in names(result$models)) {
    expect_equal(result$models[[key]]$kappa, permuted$models[[key]]$kappa, tolerance = p$validation_tolerances$invariance)
    expect_identical(result$models[[key]]$hit_rate, permuted$models[[key]]$hit_rate)
  }
  r$reference <- NULL
  expect_error(acmg_evaluate(r, p), "reference")
})

test_that("mixed provenance fails before fitting and incomplete main designs have no assessment", {
  p <- ap1_test_plan(); r <- ap1_test_runs(p)
  calls <- 0L
  local_mocked_bindings(msa_fit = function(runs, ...) { calls <<- calls + 1L; ap1_test_fit_stub(runs, ...) },
                        msa_report = ap1_test_report_stub)
  mixed <- r; mixed$meta[1] <- ap1_test_meta("sol", p)
  expect_error(acmg_evaluate(mixed, p), "mixed")
  expect_identical(calls, 0L)
  cases <- list(missing = r[-1, ], extra = rbind(r, r[1, ]))
  replaced <- r; replaced[2, ] <- replaced[1, ]; cases$duplicate_instead_of_missing <- replaced
  wrong_rep <- r; wrong_rep$rep[1] <- p$design$replicates + 1; cases$extra_rep <- wrong_rep
  for (name in names(cases)) {
    got <- acmg_evaluate(cases[[name]], p)
    expect_false(got$models$sol$complete, info = name)
    expect_true(all(got$models$sol$verdicts == "not assessed"), info = name)
    expect_identical(got$models$sol$verdict, "not assessed", info = name)
    expect_identical(got$models$sol$provenance, "synthetic")
  }
  band <- acmg_bands(NA_real_, NA_real_, 0, NULL, p)
  expect_identical(unname(band[c("grr", "kappa", "robustness")]), rep("not assessed", 3))
  expect_identical(acmg_worst(band, p), "not assessed")
  a <- p$acceptance
  expect_identical(unname(acmg_bands(a$grr_pct_study_var$acceptable_below, a$kappa_linear_modal$acceptable_min,
                                     a$dangerous_errors$acceptable_max, "acceptable", p)),
                   c("marginal", "acceptable", "acceptable", "acceptable"))
  expect_identical(unname(acmg_bands(a$grr_pct_study_var$marginal_below, a$kappa_linear_modal$marginal_min,
                                     a$dangerous_errors$marginal_max, "marginal", p)), rep("marginal", 4))
})

test_that("PB stability retains failures in denominators and uses the corrected logit and Lenth effects", {
  p <- ap1_test_plan(); ids <- paste0("synthetic-", seq_len(10)); prompts <- unlist(p$robustness$pb_design$prompt_ids)
  modal <- data.frame(item_id = ids, modal = acmg_classes(p)[1], has_modal = TRUE, reference = acmg_classes(p)[1])
  modal$modal[1] <- NA; modal$has_modal[2] <- FALSE
  r <- expand.grid(item_id = ids, prompt_id = prompts, stringsAsFactors = FALSE)
  d <- acmg_pb(p)
  desired <- ifelse(d$F1 > 0, 8L, 4L)
  r$value <- ifelse(match(r$item_id, ids) <= desired[match(r$prompt_id, prompts)], acmg_classes(p)[1], acmg_classes(p)[5])
  r$error <- NA_character_
  r$error[r$item_id == ids[3]] <- "Synthetic backend error"
  r$value[r$item_id == ids[4]] <- NA_character_
  result <- acmg_robustness(r, modal, ids, p)
  expect_true(result$complete)
  expect_identical(result$response$x, desired - 4L)
  expect_true(all(result$response$n == length(ids)))
  y <- log((desired - 4 + p$robustness$response$correction) / (length(ids) - desired + 4 + p$robustness$response$correction))
  expect_true(all(is.finite(y)))
  expect_equal(result$response$y, y, tolerance = p$validation_tolerances$arithmetic)
  expected <- msa_robustness(d, y, alpha = p$acceptance$robustness$sme_alpha)
  expect_equal(result$effects, expected, tolerance = p$validation_tolerances$arithmetic)
  b <- mean(y)
  e <- stats::setNames(expected$effect, expected$factor)[names(p$robustness$factors)]
  delta <- 1 / (1 + exp(-b - e / 2)) - 1 / (1 + exp(-b + e / 2))
  expect_equal(result$delta_p, delta, tolerance = p$validation_tolerances$arithmetic)
  expect_identical(result$band, "unacceptable")
  expect_true(all(result$response$reference_n == length(ids)))
  for (bad in list(r[-1, ], rbind(r, r[1, ]), rbind(r[-2, ], r[1, ]))) {
    incomplete <- acmg_robustness(bad, modal, ids, p)
    expect_false(incomplete$complete)
    expect_identical(incomplete$band, "not assessed")
    expect_null(incomplete$effects)
  }
})
