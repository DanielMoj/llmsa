test_that("numeric responses retain their doubles, labels and analysed row mapping", {
  r <- numeric_test_runs()
  r$value[1:3] <- c(1 / 3, 0.1 + 0.2, exp(1))
  r$value[4] <- NA_real_
  before <- r
  set.seed(20261029)
  rng <- .Random.seed
  f <- suppressMessages(msa_fit(r))
  expect_identical(r, before)
  expect_identical(.Random.seed, rng)
  expect_identical(f$data$y, r$value[-4])
  expect_identical(f$numerics$input_rows, which(!is.na(r$value)))
  expect_identical(unname(stats::model.response(stats::model.frame(f$model))), r$value[-4])
  expect_identical(as.character(f$data$item), r$item_id[-4])
  for (group in names(lme4::ranef(f$model))) {
    expect_identical(rownames(lme4::ranef(f$model)[[group]]), levels(f$model@flist[[group]]))
    expect_identical(rownames(stats::coef(f$model)[[group]]), levels(f$model@flist[[group]]))
  }
  arithmetic <- numeric_tolerance("arithmetic", "abs_tol")
  expect_equal(stats::fitted(f$model) + stats::residuals(f$model),
               stats::model.response(stats::model.frame(f$model)), tolerance = arithmetic)
  expect_equal(unname(stats::predict(f$model, newdata = f$data)),
               unname(stats::fitted(f$model)), tolerance = arithmetic)
  expect_identical(f$vc, vc_from_model(f$model, "numeric", "probit"))
  expect_equal(stats::sigma(f$model)^2, numeric_components(f)[["Residual"]], tolerance = arithmetic)
})

test_that("numeric parsing drops unreadable responses and diagnoses unusable inputs", {
  r <- numeric_test_runs()
  r$value <- as.character(r$value)
  r$value[c(1, 3)] <- "unreadable"
  r$value[4] <- NA_character_
  expect_warning(f <- suppressMessages(msa_fit(r)), "2 value.*were dropped")
  expect_identical(f$numerics$input_rows, setdiff(seq_len(nrow(r)), c(1L, 3L, 4L)))
  r$value <- factor(r$value)
  expect_warning(ff <- suppressMessages(msa_fit(r)), "2 value")
  expect_identical(ff$data, f$data)
  r$value <- "unreadable"
  expect_warning(expect_error(msa_fit(r), "No valid numeric"), "were dropped")
  r$value <- NA_real_
  expect_error(msa_fit(r), "No valid")
  r$value <- 1
  expect_error(msa_fit(r), "zero variation")
  r$value[1] <- Inf
  expect_error(msa_fit(r), "finite")
})

test_that("explicit lme4 arguments keep their original engine and data semantics", {
  r <- numeric_test_runs()
  d <- numeric_test_frame(r)
  form <- y ~ 1 + (1 | item) + (1 | prompt) + (1 | item:prompt)
  control <- lme4::lmerControl(optimizer = "bobyqa")
  configurations <- list(list(control = control), list(control = lme4::lmerControl()),
    list(weights = seq_len(nrow(d)) / nrow(d) + 1),
    list(offset = seq_len(nrow(d)) / nrow(d)), list(subset = seq_len(nrow(d) - 3L)),
    list(start = list(theta = c(1, 1, 1))))
  for (args in configurations) {
    direct <- suppressMessages(do.call(lme4::lmer, c(list(formula = form, data = d, REML = TRUE), args)))
    got <- suppressMessages(do.call(msa_fit, c(list(runs = r), args)))
    expect_identical(got$numerics$method, "lmer")
    expect_identical(got$model@optinfo$optimizer, direct@optinfo$optimizer)
    expect_equal(lme4::getME(got$model, "theta"), lme4::getME(direct, "theta"),
                 tolerance = numeric_tolerance("engine_boot", "tol"))
    expect_equal(unname(stats::fitted(got$model)), unname(stats::fitted(direct)),
                 tolerance = numeric_tolerance("engine_boot", "tol"))
    expect_identical(stats::model.response(stats::model.frame(got$model)),
                     stats::model.response(stats::model.frame(direct)))
  }
  error <- tryCatch(lme4::lmer(form, d, control = NULL), error = conditionMessage)
  expect_error(msa_fit(r, control = NULL), error, fixed = TRUE)
})

test_that("balanced REML pools omitted effects and recomputes an active one-way boundary", {
  r <- numeric_test_runs()
  d <- numeric_test_frame(r)
  a <- summary(stats::aov(y ~ item + prompt, d))[[1]]
  residual <- a[["Mean Sq"]][3]
  expected <- c(item = (a[["Mean Sq"]][1] - residual) / (nlevels(d$prompt) * 3),
                 prompt = (a[["Mean Sq"]][2] - residual) / (nlevels(d$item) * 3), Residual = residual)
  expect_true(all(expected > 0))
  f <- msa_fit(r, interactions = FALSE)
  expect_identical(f$numerics$method, "closed_form")
  expect_equal(numeric_components(f)[names(expected)], expected,
               tolerance = numeric_tolerance("oracle", "closed_form_rel_tol"))
  one <- data.frame(item_id = rep(letters[1:4], each = 3), prompt_id = "P", model_id = "M",
                    rep = rep(1:3, 4), value = rep(c(-1, 0, 1), 4))
  f <- suppressMessages(msa_fit(as_msa_runs(one)))
  expect_true(f$singular)
  expect_identical(numeric_components(f)[["item"]], 0)
  expect_equal(numeric_components(f)[["Residual"]], stats::var(one$value),
               tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  one$value <- rep(1:4, each = 3)
  expect_error(msa_fit(as_msa_runs(one)), "residual variance")
})

test_that("sparse REML score and curvature agree with an independent dense calculation", {
  d <- numeric_test_frame(numeric_test_runs()[-c(1, 7, 18), ])
  lf <- lme4::lFormula(y ~ 1 + (1 | item) + (1 | prompt) + (1 | item:prompt), data = d)
  Z <- t(as.matrix(lf$reTrms$Zt))
  groups <- rep(seq_along(lf$reTrms$cnms), diff(lf$reTrms$Gp))
  evaluator <- msa_numeric_reml(lf$reTrms$Zt, groups, d$y)
  lambda <- c(0.2, 2, 0.5)
  kernels <- lapply(seq_along(lambda), function(j) tcrossprod(Z[, groups == j, drop = FALSE]))
  H <- diag(nrow(d)) + Reduce(`+`, Map(`*`, kernels, lambda))
  inverse <- solve(H)
  x <- rep(1, nrow(d))
  P <- inverse - tcrossprod(inverse %*% x) / as.numeric(t(x) %*% inverse %*% x)
  z <- d$y - mean(d$y)
  Q <- as.numeric(t(z) %*% P %*% z)
  nu <- length(z) - 1
  gradient <- vapply(kernels, function(K) sum(diag(P %*% K)) -
    nu * as.numeric(t(z) %*% P %*% K %*% P %*% z) / Q, numeric(1))
  value <- as.numeric(determinant(H, logarithm = TRUE)$modulus) +
    log(as.numeric(t(x) %*% inverse %*% x)) + nu * log(Q / nu)
  got <- evaluator(lambda)
  expect_equal(got$value, value, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  expect_equal(got$gradient, gradient, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  h <- .Machine$double.eps^(1 / 3)
  Hdiff <- sapply(seq_along(lambda), function(j) {
    change <- rep(0, length(lambda)); change[j] <- h
    (evaluator(lambda + change)$gradient - evaluator(lambda - change)$gradient) / (2 * h)
  })
  expect_equal(got$Hessian, Hdiff, tolerance = numeric_tolerance("oracle", "closed_form_rel_tol"))
})

test_that("the active set releases zero ratios and damps overshooting Newton steps", {
  # Known constrained optima, independent of mixed-model implementation.
  quadratic <- function(x) list(value = sum((x - c(2, -1))^2), gradient = 2 * (x - c(2, -1)),
                                Hessian = diag(2, 2), information = diag(2), df = 1)
  answer <- msa_numeric_optimize(quadratic, c(0, 3))
  expect_equal(answer$lambda, c(2, 0), tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  expect_gt(answer$entered, 0)
  expect_gt(answer$released, 0)
  exponential <- function(x) list(value = exp(x) - exp(3) * x, gradient = exp(x) - exp(3),
                                  Hessian = matrix(exp(x)), information = matrix(1), df = 1)
  answer <- msa_numeric_optimize(exponential, 0)
  expect_equal(answer$lambda, 3, tolerance = numeric_tolerance("oracle", "closed_form_rel_tol"))
  expect_gt(answer$step_halvings, 0)
  expect_lte(answer$scaled_score, sqrt(.Machine$double.eps))
  expect_lte(answer$scaled_step, sqrt(.Machine$double.eps))
  expect_error(msa_numeric_optimize(exponential, 0, max_iterations = 1L), "did not converge")
})

test_that("unbalanced fits retain transformation invariance and reject nonidentifiability", {
  r <- numeric_test_runs()[-c(1, 5, 11), ]
  f <- suppressMessages(msa_fit(r))
  expect_identical(f$numerics$method, "analytic_reml")
  original <- numeric_components(f)
  modified <- r[rev(seq_len(nrow(r))), ]
  modified$value <- -7 * modified$value + 10000
  for (col in c("item_id", "prompt_id")) {
    modified[[col]] <- paste0("reversed-", rev(seq_along(unique(modified[[col]]))))[match(modified[[col]], unique(modified[[col]]))]
  }
  other <- suppressMessages(msa_fit(modified))
  expect_lte(max(abs(numeric_components(other)[names(original)] / 7^2 - original)) / sum(original),
              numeric_tolerance("invariance", "component_tol_fraction_of_total_variance"))
  r$prompt_id <- r$item_id
  # This deliberately nonidentifiable start can emit lme4 Hessian warnings;
  # provenance/propagation is tested separately below with an injected warning.
  warnings <- character()
  expect_error(withCallingHandlers(suppressMessages(msa_fit(r, interactions = FALSE)), warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  }), "not identifiable")
  expect_true(all(nzchar(warnings)))
})

test_that("conditioning handles tied scores and small representable variation", {
  r <- numeric_test_runs()
  for (pattern in list(c(rep(1, 7), 2, 3, 4), c(rep(1, 7), 2, 2, 2))) {
    r$value <- rep(pattern, length.out = nrow(r))
    expect_no_error(f <- suppressMessages(msa_fit(r)))
    expect_gt(f$numerics$conditioning$scale, 0)
    expect_true(all(is.finite(f$vc$variance)))
  }
  r <- numeric_test_runs()
  original <- numeric_components(suppressMessages(msa_fit(r)))
  for (scale in c(1e-100, 1e100)) {
    small <- r; small$value <- r$value * scale
    f <- suppressMessages(msa_fit(small))
    expect_equal(numeric_components(f)[names(original)] / scale^2, original,
                 tolerance = numeric_tolerance("invariance", "component_tol_fraction_of_total_variance"))
  }
  y <- c(-1, 1, 0) * (.Machine$double.xmax * (3 / 4))
  conditioned <- msa_numeric_condition(y)
  expect_gt(conditioned$binary_scale, 1)
  expect_true(all(is.finite(conditioned$y)))
  expect_equal(mean(conditioned$y), 0, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
})

test_that("default models survive serialization and keep ordinary lme4 refits", {
  f <- suppressMessages(msa_fit(numeric_test_runs()[-1, ]))
  f <- unserialize(serialize(f, NULL))
  expect_identical(f$model@optinfo$optimizer, "nloptwrap")
  expect_identical(f$model@optinfo$control, list())
  expect_identical(eval(f$model@call$control)$optCtrl, list())
  expect_identical(f$model@optinfo$completion$method, f$numerics$method)
  refitted <- suppressMessages(lme4::refit(f$model))
  direct <- suppressMessages(lme4::lmer(f$formula, data = f$data))
  expect_identical(refitted@optinfo$control, direct@optinfo$control)
  expected <- vc_from_model(direct, "numeric", "probit")$variance
  observed <- vc_from_model(refitted, "numeric", "probit")$variance
  expect_lte(max(abs(observed - expected)) / sum(expected),
              numeric_tolerance("reml_anova", "component_tol_fraction_of_total_variance"))
  b <- msa_boot(f, nsim = 3, seed = 37)
  reference <- lme4::bootMer(f$model, FUN = function(m) grr_stats(vc_from_model(m, "numeric", "probit"))$summary,
                             nsim = 3, seed = 37)
  expect_equal(unname(attr(b, "boot")), unname(reference$t), tolerance = numeric_tolerance("engine_boot", "tol"))
})

test_that("start warnings retain provenance and propagate when completion fails", {
  original <- lme4::lmer
  local_mocked_bindings(lmer = function(...) {
    warning("Synthetic start warning", call. = FALSE)
    original(...)
  }, .package = "lme4")
  r <- numeric_test_runs()[-1, ]
  expect_no_warning(f <- suppressMessages(msa_fit(r)))
  expect_true("Synthetic start warning" %in% f$numerics$start$warnings)
  expect_match(f$numerics$start$source, "conditioned response")
  local_mocked_bindings(msa_numeric_optimize = function(...) stop("Synthetic completion failure"))
  expect_warning(expect_error(msa_fit(r), "Synthetic completion failure"), "Synthetic start warning")
})

test_that("a degenerate planning scenario ends with the numeric diagnostic", {
  scenarios <- data.frame(n_items = 4, n_prompts = 2, n_models = 1, n_reps = 2)
  expect_error(msa_plan(scenarios, vc = list(item = 0, residual = 0), nsim = 1, seed = 1, verbose = FALSE),
               "zero variation")
})
