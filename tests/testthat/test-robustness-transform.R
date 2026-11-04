# Small synthetic responses only; numerical tolerances come from ANK-TOL.
robust_transform_error <- function(expr, message) {
  err <- expect_no_warning(tryCatch(expr, error = identity))
  expect_s3_class(err, "error")
  if (inherits(err, "error")) {
    expect_identical(conditionMessage(err), message)
    expect_null(conditionCall(err))
  }
}

test_that("logit screening agrees with regression and separately transformed responses", {
  tol <- numeric_tolerance("arithmetic", "abs_tol")
  set.seed(20261104L)
  for (k in c(7L, 11L)) {
    d <- pb_design(k, randomize = FALSE)
    X <- attr(d, "coded")
    p <- stats::runif(nrow(d), 0.05, 0.95)
    log_odds <- log(p / (1 - p))
    for (factors in list(colnames(X), colnames(X)[c(1L, 3L, 5L)])) {
      for (design in list(d, as.data.frame(X))) {
        r <- msa_robustness(design, p, factors = factors, alpha = 0.1,
                            transform = "logit")
        separate <- msa_robustness(design, stats::qlogis(p),
                                   factors = factors, alpha = 0.1)
        expect_identical(r, separate)
        selected <- X[, factors, drop = FALSE]
        regression <- 2 * unname(stats::coef(stats::lm(log_odds ~ selected))[-1L])
        expect_lte(max(abs(r$effect[match(factors, r$factor)] - regression)), tol)
        expect_lte(abs(attr(r, "response_mean") - mean(log_odds)), tol)
        expect_lte(abs(attr(r, "response_sd") - stats::sd(log_odds)), tol)
        expect_identical(attr(r, "alpha"), 0.1)
        expect_identical(attr(r, "n_runs"), nrow(d))
      }
    }
  }
})

test_that("the transformation defaults to none and preserves the response scale", {
  expect_identical(formals(msa_robustness)$transform, "none")
  expect_identical(names(formals(msa_robustness)),
                   c("design", "response", "factors", "alpha", "transform"))
  d <- pb_design(7, randomize = FALSE)
  # Synthetic boundary proportions and arbitrary responses remain valid on
  # their original scale; there is no implicit logit or clipping.
  for (y in list(seq(0, 1, length.out = nrow(d)),
                 seq(-4, 3, length.out = nrow(d)), rep(1, nrow(d)))) {
    actual <- msa_robustness(d, y)
    expect_identical(actual, msa_robustness(d, y, transform = "none"))
    expect_identical(attr(actual, "response_mean"), mean(y))
    expect_identical(attr(actual, "response_sd"), stats::sd(y))
    expect_identical(class(actual), c("msa_robustness", "data.frame"))
    expect_identical(names(actual),
                     c("factor", "effect", "t_lenth", "active", "active_simultaneous"))
  }
})

test_that("transform requires a single exact nonmissing option", {
  d <- pb_design(7, randomize = FALSE)
  p <- seq(0.1, 0.8, length.out = nrow(d))
  invalid <- list("probit", "", "lo", "non", "LOGIT", " logit", "none ",
                  NA_character_, character(), c("none", "logit"),
                  c("logit", NA_character_), 1, TRUE, NULL,
                  list("logit"), factor("none"))
  for (option in invalid) {
    robust_transform_error(msa_robustness(d, p, transform = option),
                           "`transform` must be one of 'none' or 'logit'.")
  }
})

test_that("logit rejects invalid proportions before transforming any response", {
  d <- pb_design(7, randomize = FALSE)
  p <- seq(0.1, 0.8, length.out = nrow(d))
  message <- paste0("`response` must be a real numeric vector of finite proportions ",
                    "strictly between 0 and 1 for transform = 'logit'.")
  for (value in c(0, 1, -0.1, 1.1, -Inf, Inf)) {
    for (position in c(1L, 4L, nrow(d))) {
      bad <- p
      bad[position] <- value
      robust_transform_error(msa_robustness(d, bad, transform = "logit"), message)
    }
  }
  for (bad in list(as.character(p), rep(TRUE, nrow(d)), as.complex(p),
                   p + 1i, as.list(p), factor(p), as.raw(seq_len(nrow(d))),
                   matrix(p, ncol = 1L), array(p, dim = c(2L, 2L, 2L)))) {
    robust_transform_error(msa_robustness(d, bad, transform = "logit"), message)
  }
})

test_that("response length and missing-value errors remain explicit for both transformations", {
  d <- pb_design(7, randomize = FALSE)
  p <- seq(0.1, 0.8, length.out = nrow(d))
  for (transform in c("none", "logit")) {
    for (bad in list(p[-1L], c(p, p[1L]), numeric())) {
      robust_transform_error(msa_robustness(d, bad, transform = transform),
                             "`response` needs one value per run.")
    }
    for (missing in c(NA_real_, NaN)) {
      bad <- p
      bad[4L] <- missing
      robust_transform_error(msa_robustness(d, bad, transform = transform),
                             "`response` must not contain NA.")
    }
  }
  plain <- as.data.frame(attr(d, "coded"))
  robust_transform_error(msa_robustness(plain, p),
                         "Give `factors` (the coded columns) for a plain data.frame design.")
})

test_that("finite proportions near either boundary receive no additional cutoff", {
  tol <- numeric_tolerance("arithmetic", "abs_tol")
  d <- pb_design(7, randomize = FALSE)
  p <- c(.Machine$double.xmin, .Machine$double.eps, 0.1, 0.3,
         0.5, 0.7, 0.9, 1 - .Machine$double.eps)
  actual <- expect_no_warning(msa_robustness(d, p, transform = "logit"))
  manual <- msa_robustness(d, log(p / (1 - p)))
  expect_lte(max(abs(actual$effect - manual$effect)), tol)
  for (field in c("pse", "me", "sme", "response_mean", "response_sd")) {
    expect_true(is.finite(attr(actual, field)))
    expect_lte(abs(attr(actual, field) - attr(manual, field)), tol)
  }
  expect_identical(actual$active, manual$active)
  expect_identical(actual$active_simultaneous, manual$active_simultaneous)
})

test_that("logit screening retains a single selected factor for either design form", {
  tol <- numeric_tolerance("arithmetic", "abs_tol")
  d <- pb_design(7, randomize = FALSE)
  X <- attr(d, "coded")
  p <- seq(0.1, 0.8, length.out = nrow(d))
  for (design in list(d, as.data.frame(X))) {
    r <- msa_robustness(design, p, factors = "F3", transform = "logit")
    expect_identical(r$factor, "F3")
    coefficient <- stats::coef(stats::lm(log(p / (1 - p)) ~ X[, "F3"]))[2L]
    expect_lte(abs(r$effect - 2 * unname(coefficient)), tol)
    expect_identical(r, msa_robustness(design, stats::qlogis(p), factors = "F3"))
  }
})
