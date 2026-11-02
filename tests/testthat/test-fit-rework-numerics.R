test_that("conditioning has exact small-input values and a defined overflow scale", {
  expected <- list(y = c(-1 / 6, 5 / 6, -2 / 3), origin = 10,
                   center = 1 / 6, scale = 4, binary_scale = 1)
  expect_equal(msa_numeric_condition(c(10, 14, 8)), expected,
               tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  y <- c(-1, 1, 0) * (.Machine$double.xmax * (3 / 4))
  binary <- 2^floor(log2(max(abs(y))))
  reduced <- y / binary
  delta <- reduced - reduced[1L]
  scale <- max(abs(delta))
  expected <- list(y = (reduced - mean(reduced)) / scale, origin = y[1L],
                   center = mean(delta) / scale, scale = scale, binary_scale = binary)
  expect_equal(msa_numeric_condition(y), expected, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  # log2(double.xmax) rounds up to double.max.exp. The largest finite
  # binary scale is still 2^(double.max.exp - 1), not that rounded power.
  y <- c(-.Machine$double.xmax, .Machine$double.xmax, 0)
  reduced <- y / 2^(.Machine$double.max.exp - 1)
  scale <- max(reduced - reduced[1L])
  expect_equal(msa_numeric_condition(y), list(y = reduced / scale, origin = y[1L],
    center = -reduced[1L] / scale, scale = scale, binary_scale = 2^(.Machine$double.max.exp - 1)),
    tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  rework_error(msa_numeric_condition(c(3, 3)), "Numeric response cannot be scaled.")
  rework_error(msa_numeric_condition(c(-Inf, Inf)), "Numeric response cannot be scaled.")
})

test_that("default balanced interaction and block estimates equal independent ANOVA equations", {
  # Expected mean squares from Formelsammlung section 2: a row contains a
  # component iff its factor set is included in that component's factor set.
  for (block in c(1L, 2L)) for (interactions in c(FALSE, TRUE)) {
    r <- msa_simulate(12, 3, 3, 2, block,
      vc = list(item = 1, prompt = 0.2, model = 0.3, block = 0.1,
                item_prompt = 0.1, item_model = 0.1, prompt_model = 0.1, residual = 0.1), seed = 1L)
    d <- numeric_test_frame(r)
    factors <- c("item", "prompt", "model", if (block > 1L) "block")
    labels <- c(factors, if (interactions) c("item:prompt", "item:model", "prompt:model"))
    terms <- strsplit(labels, ":", fixed = TRUE)
    anova <- summary(stats::aov(stats::reformulate(labels, response = "y"), data = d))[[1L]]
    rownames(anova) <- trimws(rownames(anova))
    sizes <- vapply(d[factors], nlevels, integer(1))
    coefficients <- matrix(0, length(labels), length(labels), dimnames = list(labels, labels))
    for (i in seq_along(terms)) for (j in seq_along(terms)) {
      if (all(terms[[i]] %in% terms[[j]])) coefficients[i, j] <- nrow(d) / prod(sizes[terms[[j]]])
    }
    error <- anova["Residuals", "Mean Sq"]
    reference <- c(solve(coefficients, anova[labels, "Mean Sq"] - error), Residual = error)
    expect_true(all(reference >= 0))
    f <- suppressMessages(msa_fit(r, interactions = interactions))
    expect_identical(f$numerics$method, "closed_form")
    expect_lte(max(abs(numeric_components(f)[names(reference)] - reference)) / sum(reference),
                numeric_tolerance("arithmetic", "abs_tol"))
    # The EMS equations are translation invariant even before the public
    # fitting path conditions the response. Compare the helper to ANOVA too.
    d$y <- d$y + 16
    expect_equal(msa_numeric_balanced(d, terms), unname(reference[labels] / error),
                 tolerance = numeric_tolerance("oracle", "closed_form_rel_tol"))
  }
})

test_that("balanced applicability distinguishes one observation, incomplete and unequal crossings", {
  p <- lme4::Penicillin
  r <- as_msa_runs(data.frame(item_id = p$sample, prompt_id = p$plate, model_id = "M",
                              rep = 1L, value = p$diameter))
  expect_identical(msa_fit(r, interactions = FALSE)$numerics$method, "closed_form")
  r <- numeric_test_runs()
  incomplete <- r[!(r$item_id == "I001" & r$prompt_id == "P1"), ]
  for (rows in list(incomplete, r[-1L, ])) {
    expect_identical(suppressMessages(msa_fit(rows))$numerics$method, "analytic_reml")
  }
  d <- data.frame(item = factor(1:3), y = c(1, 2, 4))
  rework_error(msa_numeric_balanced(d, list("item")), "Numeric model has no residual degrees of freedom.")
  # A 2x2 additive design with one observation per cell has exactly one
  # residual degree of freedom, and its independent ANOVA remains defined.
  d <- expand.grid(item = factor(1:2), prompt = factor(1:2))
  d$y <- c(0, 1, 2, 4)
  a <- summary(stats::aov(y ~ item + prompt, data = d))[[1L]]
  error <- a[["Mean Sq"]][3L]
  reference <- (a[["Mean Sq"]][1:2] - error) / (2 * error)
  expect_equal(msa_numeric_balanced(d, list("item", "prompt")), reference,
               tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  # Six integer observations give MS_between = MS_within = 2 exactly.
  d <- data.frame(item = factor(rep(1:3, each = 2)), y = c(-2, 0, -1, 1, 0, 2))
  expect_identical(msa_numeric_balanced(d, list("item")), 0)
  d$y <- rep(c(-1, 1), 3)
  expect_identical(msa_numeric_balanced(d, list("item")), 0)
  runs <- as_msa_runs(data.frame(item_id = d$item, prompt_id = "P", model_id = "M", rep = rep(1:2, 3), value = d$y))
  f <- suppressMessages(msa_fit(runs))
  expect_equal(stats::sigma(f$model)^2, stats::var(d$y), tolerance = numeric_tolerance("arithmetic", "abs_tol"))
})

test_that("vanishing residual variance has a named diagnostic and omitted effects remain estimable", {
  d <- expand.grid(item_id = letters[1:4], prompt_id = c("p", "q"), rep = 1:2,
                    model_id = "M", stringsAsFactors = FALSE)
  d$value <- rep(c(1.1, 2.3, 0.7, 4.5, 3.2, 1.8, 5.1, 0.9), 2)
  r <- as_msa_runs(d)
  out <- rework_error(msa_fit(r), "Degenerate numeric model: residual variance is zero at working precision.")
  expect_length(out$warnings, 0L)
  # Same cell means, different model: omitted interaction contributes to the
  # residual and must not be rejected merely because replicates are identical.
  f <- suppressMessages(msa_fit(r, interactions = FALSE))
  expect_gt(stats::sigma(f$model)^2, 0)
  one <- data.frame(item_id = rep(letters[1:4], c(2, 2, 2, 3)), prompt_id = "P", model_id = "M",
                     rep = c(1, 2, 1, 2, 1, 2, 1, 2, 3), value = rep(c(10, 20, 35, 50), c(2, 2, 2, 3)))
  out <- rework_error(msa_fit(as_msa_runs(one)), "Degenerate numeric model: residual variance is zero at working precision.")
  expect_length(out$warnings, 0L)
  d <- data.frame(item = factor(rep(1:3, each = 2)), y = rep(c(0, 1, 1), each = 2))
  rework_error(msa_numeric_balanced(d, list("item")),
               "Degenerate numeric model: residual variance is zero at working precision.")
  # Positive relative variation is supported at two very different scales.
  # /10 keeps a distance to the documented working-precision limit: /100 ends with
  # "Analytic REML did not converge" on macos-latest, /1000 also on Linux (ADR-039).
  one$value <- one$value + rep(c(-1, 1, 0), 3) / 10
  reference <- suppressMessages(msa_fit(as_msa_runs(one)))
  for (scale in c(1e-150, 1e-100, 1e100)) {
    scaled <- one
    scaled$value <- scaled$value * scale
    fit <- suppressMessages(msa_fit(as_msa_runs(scaled)))
    expect_lte(max(abs(numeric_components(fit) / scale^2 - numeric_components(reference))) /
                 sum(reference$vc$variance), numeric_tolerance("invariance", "component_tol_fraction_of_total_variance"))
  }
})

test_that("the residual roundoff bound is relative and rejects equality", {
  # ADR-020's backward-error bound, expressed as exact binary squares.
  for (total in c(1 / 4, 4)) {
    bound <- (64 * .Machine$double.eps)^2 * total
    for (square in c(0, bound / 2, bound)) {
      rework_error(msa_numeric_check_residual(square, total),
                   "Degenerate numeric model: residual variance is zero at working precision.")
    }
    expect_no_error(msa_numeric_check_residual((65 * .Machine$double.eps)^2 * total, total))
  }
  rework_error(msa_numeric_check_residual(Inf, 1),
               "Degenerate numeric model: residual variance is zero at working precision.")
})

test_that("original-scale precision is checked against centered data and NIST certification", {
  tolerance <- numeric_tolerance("invariance", "component_tol_fraction_of_total_variance")
  r <- numeric_test_runs()
  for (scale in c(1e-161, 1e-160, 1e155)) {
    scaled <- r
    scaled$value <- scaled$value * scale
    out <- rework_error(msa_fit(scaled),
                         "Numeric model variance is not representable on the original scale at working precision.")
    expect_length(out$warnings, 0L)
  }
  # All between-item means are zero, so only the residual is positive.
  # Its representability must still be checked when every theta is zero.
  residual_only <- as_msa_runs(data.frame(item_id = rep(letters[1:3], each = 2),
    prompt_id = "P", model_id = "M", rep = rep(1:2, 3), value = rep(c(-1, 1), 3) * 1e-161))
  rework_error(msa_fit(residual_only),
               "Numeric model variance is not representable on the original scale at working precision.")
  shifted <- ic50_demo
  shifted$value <- shifted$value + 1e10
  centered <- shifted
  centered$value <- centered$value - 1e10
  reference <- suppressMessages(msa_fit(centered))
  answer <- rework_capture(msa_fit(shifted))$value
  if (inherits(answer, "error")) {
    expect_identical(conditionMessage(answer),
                     "Numeric model variance is not representable on the original scale at working precision.")
    expect_null(conditionCall(answer))
  } else {
    expect_lte(max(abs(numeric_components(answer) - numeric_components(reference))) / sum(reference$vc$variance), tolerance)
  }
  e <- numeric_validation_helpers()
  context <- e$validation_context(repo_root = "")
  anchors <- e$validation_anchors(context)
  for (name in c("SmLs06", "SmLs09")) {
    table <- e$validation_nist(name, context, anchors)
    runs <- e$validation_runs(item = table$treatment, rep = table$rep, value = table$value)
    out <- rework_capture(msa_fit(runs))
    if (name == "SmLs06") expect_s3_class(out$value, "msa_fit")
    if (inherits(out$value, "error")) {
      expect_identical(conditionMessage(out$value),
                       "Numeric model variance is not representable on the original scale at working precision.")
      expect_null(conditionCall(out$value))
    } else {
      d <- numeric_test_frame(runs)
      d$y <- d$y - d$y[1L]
      a <- summary(stats::aov(y ~ item, data = d))[[1L]]
      expected <- c(item = (a[["Mean Sq"]][1L] - a[["Mean Sq"]][2L]) / table(table$treatment)[1L],
                    Residual = a[["Mean Sq"]][2L])
      names(expected) <- c("item", "Residual")
      expect_lte(max(abs(numeric_components(out$value)[names(expected)] - expected)) / sum(expected), tolerance)
    }
  }
})

test_that("REML information equals the independent dense projected covariance formula", {
  d <- numeric_test_frame(numeric_test_runs()[-c(1, 7, 18), ])
  lf <- lme4::lFormula(y ~ 1 + (1 | item) + (1 | prompt) + (1 | item:prompt), data = d)
  Z <- t(as.matrix(lf$reTrms$Zt))
  groups <- rep(seq_along(lf$reTrms$cnms), diff(lf$reTrms$Gp))
  evaluator <- msa_numeric_reml(lf$reTrms$Zt, groups, d$y)
  lambda <- c(0, 2, 1 / 2)
  kernels <- lapply(seq_along(lambda), function(j) tcrossprod(Z[, groups == j, drop = FALSE]))
  H <- diag(nrow(d)) + Reduce(`+`, Map(`*`, kernels, lambda))
  inverse <- solve(H)
  x <- rep(1, nrow(d))
  P <- inverse - tcrossprod(inverse %*% x) / as.numeric(crossprod(x, inverse %*% x))
  projected <- lapply(kernels, function(K) P %*% K)
  traces <- vapply(projected, function(A) sum(diag(A)), numeric(1))
  expected <- outer(seq_along(lambda), seq_along(lambda), Vectorize(function(i, j) {
    sum(diag(projected[[i]] %*% projected[[j]])) - traces[i] * traces[j] / (nrow(d) - 1)
  }))
  expect_equal(evaluator(lambda)$information, expected, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  zero <- msa_numeric_reml(lf$reTrms$Zt, groups, rep(0, nrow(d)))
  rework_error(zero(lambda), "Degenerate numeric model: residual variance is zero at working precision.")
  # A singular factorization is an observable failure, not a swallowed Matrix warning.
  local_mocked_bindings(Cholesky = function(...) warning("Synthetic factorization warning"), .package = "Matrix")
  out <- rework_error(evaluator(lambda), "Numeric model residual variance cannot be resolved at working precision.")
  expect_length(out$warnings, 0L)
})

test_that("Newton directions and projected scores obey independent constrained quadratic solutions", {
  tolerance <- numeric_tolerance("arithmetic", "abs_tol")
  state <- list(gradient = c(-4, 6), Hessian = diag(c(2, 3)), df = 5)
  expect_equal(msa_numeric_step(state, c(2, 3)),
                list(step = c(2, -2), score = 18 / 5, correction = 1, positive = TRUE), tolerance = tolerance)
  # Inverse of [[2,1],[1,2]] gives (-8/3,19/3); the first coordinate
  # cannot move below zero. Re-solving the free coordinate gives 10/2.
  state <- list(gradient = c(-1, -10), Hessian = matrix(c(2, 1, 1, 2), 2), df = 2)
  expect_equal(msa_numeric_step(state, c(0, 1)),
                list(step = c(0, 5), score = 5, correction = 5, positive = TRUE), tolerance = tolerance)
  state <- list(gradient = c(0, 2), Hessian = diag(2), df = 3)
  expect_identical(msa_numeric_step(state, c(0, 0)),
                   list(step = c(0, 0), score = 0, correction = 0, positive = TRUE))
  state <- list(gradient = c(1, -8), Hessian = diag(c(-2, 4)), df = 7)
  bound <- 4 * sqrt(.Machine$double.eps)
  expect_equal(msa_numeric_step(state, c(1, 0)),
                list(step = c(-1 / bound, 2), score = 8 / 7, correction = 1 / bound, positive = FALSE), tolerance = tolerance)
  state <- list(gradient = 1, Hessian = matrix(0), df = 1)
  expect_identical(msa_numeric_step(state, 1)$positive, FALSE)
  expect_identical(msa_numeric_step(state, 1)$step, -1 / sqrt(.Machine$double.eps))
  # The positive one-sided derivative pins a component to zero regardless
  # of negative curvature further inside the feasible region.
  state <- list(gradient = 1 / 2, Hessian = matrix(-1), df = 1)
  expect_identical(msa_numeric_step(state, 0),
                   list(step = 0, score = 0, correction = 0, positive = TRUE))
})

test_that("analytic completion records exact constraint transitions and evaluation counts", {
  quadratic <- function(x) list(value = sum((x - c(2, -1))^2), gradient = 2 * (x - c(2, -1)),
                                Hessian = diag(2, 2), information = diag(2), df = 1)
  got <- msa_numeric_optimize(quadratic, c(0, 3))
  # Two Newton steps: (0,3) -> (3/2,0) -> (2,0); one initial evaluation.
  expect_equal(got$lambda, c(2, 0), tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  expect_identical(got[c("iterations", "evaluations", "step_halvings", "entered", "released")],
                   list(iterations = 2L, evaluations = 3L, step_halvings = 0L, entered = 1L, released = 1L))
  at_optimum <- msa_numeric_optimize(quadratic, c(2, 0))
  expect_identical(at_optimum[c("iterations", "evaluations", "step_halvings", "entered", "released")],
                   list(iterations = 0L, evaluations = 1L, step_halvings = 0L, entered = 0L, released = 0L))
  rework_error(msa_numeric_optimize(quadratic, c(0, 3), max_iterations = 1L),
               "Analytic REML did not converge (iterations 1, scaled score 24, scaled step 2).")
  # (1/2) - ((1/2)/(49/2))*(49/2) has a positive rounding remainder.
  # The constrained optimum of (x+24)^2/2 is exactly zero, in one step.
  visited <- numeric()
  boundary <- function(x) {
    visited <<- c(visited, x)
    list(value = (x + 24)^2 / 2, gradient = x + 24, Hessian = matrix(1), information = matrix(1), df = 1)
  }
  got <- msa_numeric_optimize(boundary, 1 / 2)
  expect_identical(visited, c(1 / 2, 0))
  expect_identical(got$lambda, 0)
  expect_identical(got[c("iterations", "evaluations", "entered", "released")],
                   list(iterations = 1L, evaluations = 2L, entered = 1L, released = 0L))
  # Separate entry from release; equal totals in a multivariate example do
  # not distinguish the two observable constraint counters.
  for (optimum in c(-1, 1)) {
    quadratic <- function(x) list(value = (x - optimum)^2, gradient = 2 * (x - optimum),
      Hessian = matrix(2), information = matrix(1), df = 1)
    got <- msa_numeric_optimize(quadratic, if (optimum < 0) 1 else 0)
    expect_identical(got$entered, if (optimum < 0) 1L else 0L)
    expect_identical(got$released, if (optimum < 0) 0L else 1L)
  }
})

test_that("line search separately enforces sufficient decrease and the rounding reserve", {
  # A known quadratic with deliberately underestimated supplied curvature:
  # candidate 4 fails, candidate 2 fails, candidate 1 is the optimum.
  quadratic <- function(x) list(value = (x - 1)^2, gradient = 2 * (x - 1),
                                Hessian = matrix(1 / 2), information = matrix(1), df = 1)
  got <- msa_numeric_optimize(quadratic, 0)
  expect_equal(got$lambda, 1, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  expect_identical(got[c("iterations", "evaluations", "step_halvings")],
                   list(iterations = 1L, evaluations = 4L, step_halvings = 2L))
  # Synthetic roundoff in the function value, exact quadratic derivatives.
  # The slightly larger value cannot satisfy Armijo, but its score is zero.
  noisy <- function(x) list(value = 1 + 8 * .Machine$double.eps * x,
                            gradient = 2 * (x - 1), Hessian = matrix(2), information = matrix(1), df = 1)
  got <- msa_numeric_optimize(noisy, 0)
  expect_equal(got$lambda, 1, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  expect_identical(got[c("iterations", "evaluations", "step_halvings")],
                   list(iterations = 1L, evaluations = 2L, step_halvings = 0L))
  # An explicitly inconsistent synthetic evaluator never offers descent or
  # an improved score. Exhausting backtracking must fail, not return a start.
  inconsistent <- function(x) list(value = x, gradient = -1, Hessian = matrix(1), information = matrix(1), df = 1)
  rework_error(msa_numeric_optimize(inconsistent, 0),
               "Analytic REML did not converge (iterations 1, scaled score 1, scaled step 1).")
})

test_that("information rank distinguishes identified and confounded directions at machine precision", {
  stationary <- function(info) function(x) list(value = 0, gradient = c(0, 0),
                                                Hessian = diag(2), information = info, df = 1)
  expect_identical(msa_numeric_optimize(stationary(diag(c(1, 4 * .Machine$double.eps))), c(1, 1))$iterations, 0L)
  expect_identical(msa_numeric_optimize(stationary(diag(c(.Machine$double.eps, 1))), c(4, 1))$iterations, 0L)
  expect_identical(msa_numeric_optimize(stationary(diag(c(.Machine$double.eps / 4, 1))), c(4, 1))$iterations, 0L)
  for (info in list(diag(c(1, 0)), diag(c(1, 2 * .Machine$double.eps)))) {
    rework_error(msa_numeric_optimize(stationary(info), c(1, 1)), "Numeric variance components are not identifiable.")
  }
  rework_error(msa_numeric_optimize(stationary(diag(c(8, 16 * .Machine$double.eps))), c(1, 1)),
               "Numeric variance components are not identifiable.")
})

test_that("start fits, final-model derivatives and update retain lme4 semantics", {
  initial_lambda <- NULL
  optimize <- msa_numeric_optimize
  local_mocked_bindings(msa_numeric_optimize = function(evaluate, lambda, ...) {
    initial_lambda <<- lambda
    optimize(evaluate, lambda, ...)
  })
  r <- numeric_test_runs()[-c(1, 7), ]
  f <- suppressMessages(msa_fit(r))
  d <- f$data
  # Conditioning is independently reconstructed from the documented rule.
  # The engine comparison needs the documented order of floating operations.
  differences <- d$y - d$y[1L]
  scaled_differences <- differences / max(abs(differences))
  d$y <- scaled_differences - mean(scaled_differences)
  start <- suppressMessages(lme4::lmer(f$formula, data = d, REML = TRUE,
                                       control = lme4::lmerControl(optimizer = "nloptwrap")))
  expect_equal(f$numerics$start$theta, lme4::getME(start, "theta"), tolerance = numeric_tolerance("engine_boot", "tol"))
  # lme4 supplies standard-deviation ratios; the analytic criterion takes
  # variance ratios, independently obtained by squaring the oracle values.
  expect_equal(initial_lambda, lme4::getME(start, "theta")^2, tolerance = numeric_tolerance("engine_boot", "tol"))
  expect_identical(f$model@optinfo$message, "REML solution: analytic_reml")
  expect_identical(names(f$model@optinfo$completion), c("method", "iterations", "scaled_score", "scaled_step", "active"))
  expect_identical(stats::getCall(f$model)[[1L]], quote(lme4::lmer))
  expect_identical(stats::getCall(f$model)$REML, TRUE)
  updated <- suppressMessages(stats::update(f$model))
  direct <- suppressMessages(lme4::lmer(f$formula, data = f$data, REML = TRUE,
                                        control = lme4::lmerControl(optimizer = "nloptwrap")))
  expect_equal(lme4::getME(updated, "theta"), lme4::getME(direct, "theta"),
               tolerance = numeric_tolerance("engine_boot", "tol"))
  lf <- lme4::lFormula(f$formula, data = f$data, REML = TRUE)
  deviance <- do.call(lme4::mkLmerDevfun, lf)
  theta <- lme4::getME(f$model, "theta")
  finite_differences <- function(h) {
    k <- length(theta)
    steps <- diag(h, k)
    gradient <- numeric(k)
    Hessian <- matrix(0, k, k)
    center <- deviance(theta)
    for (i in seq_len(k)) {
      plus <- deviance(theta + steps[, i])
      minus <- deviance(theta - steps[, i])
      gradient[i] <- (plus - minus) / (2 * h[i])
      Hessian[i, i] <- (plus - 2 * center + minus) / h[i]^2
      if (i > 1L) for (j in seq_len(i - 1L)) {
        Hessian[i, j] <- Hessian[j, i] <- (deviance(theta + steps[, i] + steps[, j]) -
          deviance(theta + steps[, i] - steps[, j]) - deviance(theta - steps[, i] + steps[, j]) +
          deviance(theta - steps[, i] - steps[, j])) / (4 * h[i] * h[j])
      }
    }
    list(gradient = gradient, Hessian = Hessian)
  }
  h <- .Machine$double.eps^(1 / 6) * pmax(1, theta)
  coarse <- finite_differences(h)
  fine <- finite_differences(h / 2)
  for (key in c("gradient", "Hessian")) {
    reference <- (4 * fine[[key]] - coarse[[key]]) / 3
    expect_equal(unname(f$model@optinfo$derivs[[key]]), reference,
                 tolerance = numeric_tolerance("oracle", "closed_form_rel_tol"))
  }
  r <- numeric_test_runs()
  r$value <- r$value - stats::ave(r$value, r$prompt_id) + mean(r$value)
  boundary <- suppressMessages(msa_fit(r))
  expect_true(boundary$singular)
  expect_identical(boundary$numerics$active, names(boundary$numerics$lambda)[boundary$numerics$lambda == 0])
  expect_true("prompt" %in% boundary$numerics$active)
})

test_that("failed completion re-emits the original start warning without an internal call", {
  original <- lme4::lmer
  local_mocked_bindings(lmer = function(...) {
    warning("Synthetic start warning", call. = FALSE)
    original(...)
  }, .package = "lme4")
  local_mocked_bindings(msa_numeric_optimize = function(...) stop("Synthetic completion failure", call. = FALSE))
  out <- rework_error(msa_fit(numeric_test_runs()[-1L, ]), "Synthetic completion failure")
  expect_identical(vapply(out$warnings, conditionMessage, ""), "Synthetic start warning")
  expect_null(conditionCall(out$warnings[[1L]]))
})

test_that("boundary model curvature retains the one-sided variance score", {
  r <- numeric_test_runs()
  r$value <- r$value - stats::ave(r$value, r$prompt_id) + mean(r$value)
  f <- suppressMessages(msa_fit(r))
  theta <- lme4::getME(f$model, "theta")
  zero <- which(theta == 0)
  expect_gt(length(zero), 0L)
  deviance <- do.call(lme4::mkLmerDevfun, lme4::lFormula(f$formula, data = f$data, REML = TRUE))
  for (j in zero) {
    second <- function(h) {
      change <- numeric(length(theta))
      change[j] <- h
      (deviance(theta + change) - 2 * deviance(theta) + deviance(theta - change)) / h^2
    }
    h <- .Machine$double.eps^(1 / 6)
    expected <- (4 * second(h / 2) - second(h)) / 3
    expect_gt(expected, 0)
    expect_equal(f$model@optinfo$derivs$Hessian[j, j], expected,
                 tolerance = numeric_tolerance("oracle", "closed_form_rel_tol"))
    # The deviance is even in a zero standard-deviation ratio.
    expect_identical(unname(f$model@optinfo$derivs$gradient[j]), 0)
  }
})

test_that("both convergence norms and the exact rounding reserve control completion", {
  target <- sqrt(.Machine$double.eps)
  for (case in list(list(gradient = target, curvature = 1, iterations = 0L),
                    list(gradient = target, curvature = 1 / 2, iterations = 1L),
                    list(gradient = 2 * target, curvature = 2, iterations = 1L))) {
    optimum <- 1 - case$gradient / case$curvature
    objective <- function(x) list(value = case$curvature * (x - optimum)^2 / 2,
      gradient = case$curvature * (x - optimum), Hessian = matrix(case$curvature), information = matrix(1), df = 1)
    result <- msa_numeric_optimize(objective, 1)
    expect_identical(result$iterations, case$iterations)
  }
  # ADR-020 defines the rounding reserve as 64 eps max(1, |F|).
  for (noise in c(64, 65)) {
    noisy <- function(x) list(value = 1 + noise * .Machine$double.eps * x,
      gradient = 2 * (x - 1), Hessian = matrix(2), information = matrix(1), df = 1)
    result <- msa_numeric_optimize(noisy, 0)
    expect_identical(result$iterations, if (noise == 64) 1L else 2L)
    expect_identical(result$evaluations, if (noise == 64) 2L else 4L)
    expect_identical(result$step_halvings, if (noise == 64) 0L else 1L)
  }
  noisy <- function(x) list(value = 8 * .Machine$double.eps * x,
    gradient = 2 * (x - 1), Hessian = matrix(2), information = matrix(1), df = 1)
  expect_identical(msa_numeric_optimize(noisy, 0)$iterations, 1L)
})

test_that("Armijo acceptance and rejection of a stationary maximum are observable", {
  # Quartics with F(0)=1, F'(0)=-1, F''(0)=1, F'(1)=2 and
  # F(1)=1-1/m. The full Newton step lands exactly at the sufficient-decrease
  # boundary for m=10000; for m=10001 it must be halved, since the score worsens.
  for (denominator in c(10000, 10001)) {
    visited <- numeric()
    objective <- function(x) {
      visited <<- c(visited, x)
      list(value = 1 - x + x^2 / 2 - 4 * x^3 / denominator + (1 / 2 + 3 / denominator) * x^4,
        gradient = -1 + x - 12 * x^2 / denominator + (2 + 12 / denominator) * x^3,
        Hessian = matrix(1 - 24 * x / denominator + (6 + 36 / denominator) * x^2),
        information = matrix(1), df = 1)
    }
    rework_error(msa_numeric_optimize(objective, 0, max_iterations = 1L),
                 "Analytic REML did not converge (iterations 1, scaled score 1, scaled step 1).")
    expect_identical(visited, if (denominator == 10000) c(0, 1) else c(0, 1, 1 / 2))
  }
  visited <- numeric()
  maximum <- function(x) {
    visited <<- c(visited, x)
    list(value = -(x - 1)^2 / 2, gradient = -(x - 1), Hessian = matrix(-1), information = matrix(1), df = 1)
  }
  rework_error(msa_numeric_optimize(maximum, 1),
               "Analytic REML did not converge (iterations 1, scaled score 0, scaled step 0).")
  expect_identical(visited, rep(1, 51))
  # Explicit synthetic line-search states: the full step fails, the half
  # step is on the Armijo boundary, and neither improves the projected score.
  visited <- numeric()
  half_boundary <- function(x) {
    visited <<- c(visited, x)
    list(value = if (x == 0) 1 else if (x == 1 / 2) 1 - 1 / 20000 else 2,
      gradient = if (x == 0) -1 else 2, Hessian = matrix(1), information = matrix(1), df = 1)
  }
  rework_error(msa_numeric_optimize(half_boundary, 0, max_iterations = 1L),
               "Analytic REML did not converge (iterations 1, scaled score 1, scaled step 1).")
  expect_identical(visited, c(0, 1, 1 / 2))
})
