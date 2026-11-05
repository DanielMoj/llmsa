# Synthetic reference studies; stats supplies independent t and OLS oracles.
m3a_bias_runs <- function(x = c(2, 4, 6, 8, 10), reps = 4L,
                          deviations = c(-0.3, 0.2, 0.1, -0.1)) {
  item <- rep(seq_along(x), each = reps)
  data.frame(item_id = paste0("i", item), prompt_id = "p", model_id = "m",
             rep = rep(seq_len(reps), length(x)), reference = x[item],
             value = x[item] + rep(deviations, length.out = length(item)),
             stringsAsFactors = FALSE)
}

test_that("bias counts excluded pairs without dropping observed conditions", {
  d <- m3a_bias_runs()
  d$value <- as.character(d$value)
  d$value[1:4] <- c(NA, "unparsed", "NaN", "2.5")
  d$prompt_id[1:3] <- "empty"
  d$prompt_id[4] <- "singleton"
  d$reference[d$item_id == "i5"] <- NA_real_
  b <- msa_bias(d, "reference")
  expect_identical(names(b$overall), c("n", "bias", "sd", "lower", "upper", "p_value", "n_excluded"))
  expect_identical(unname(b$overall[c("n", "n_excluded")]), c(13, 7))
  expect_identical(nrow(b$by_condition), 3L)
  empty <- b$by_condition[b$by_condition$prompt_id == "empty", ]
  singleton <- b$by_condition[b$by_condition$prompt_id == "singleton", ]
  expect_identical(empty$n, 0)
  expect_identical(empty$n_excluded, 3)
  expect_true(all(is.na(empty[c("bias", "sd", "lower", "upper", "p_value")])))
  expect_identical(singleton$n, 1)
  expect_identical(singleton$bias, 0.5)
  expect_true(all(is.na(singleton[c("sd", "lower", "upper", "p_value")])))
  for (i in seq_len(nrow(b$by_condition))) {
    row <- b$by_condition[i, ]
    expect_equal(row$n + row$n_excluded, sum(d$prompt_id == row$prompt_id))
  }
  expect_identical(b$n_items, 4L)
})

test_that("one reference level still has a complete bias result", {
  d <- m3a_bias_runs(x = 6, reps = 5L, deviations = c(-0.2, -0.1, 0.1, 0.3, 0.4))
  b <- msa_bias(d, "reference")
  oracle <- stats::t.test(d$value - d$reference)
  expect_equal(b$overall[["bias"]], unname(oracle$estimate), tolerance = numeric_tolerance("package_compare", "abs_tol"))
  expect_equal(unname(b$overall[c("lower", "upper")]), unname(oracle$conf.int),
               tolerance = numeric_tolerance("package_compare", "abs_tol"), ignore_attr = TRUE)
  expect_equal(b$overall[["p_value"]], oracle$p.value, tolerance = numeric_tolerance("package_compare", "abs_tol"))
  expect_true(all(is.na(b$linearity)))
  expect_true(all(is.na(b$linearity_item_means)))
  expect_identical(b$linearity_band, data.frame(reference = numeric(), fit = numeric(), lower = numeric(), upper = numeric()))
  expect_identical(b$linearity_in_band, NA)
  expect_identical(b$linearity_verdict, NA_character_)
  expect_match(b$linearity_note, "reference.*range")
})

test_that("numeric precision is preserved in input and conflicting references", {
  d <- m3a_bias_runs(x = c(0, 1), reps = 3L)
  d$value <- c(1 / 3, 0.1 + 0.2, 10 + 1e-14, 1.4, 0.9, 1.1)
  b <- msa_bias(d, "reference")
  expect_identical(b$overall[["bias"]], mean(d$value - d$reference))
  d$reference[1:2] <- c(0.3, 0.1 + 0.2)
  err <- tryCatch(msa_bias(d, "reference"), error = identity)
  expect_s3_class(err, "error")
  expect_match(conditionMessage(err), "Conflicting reference values")
  expect_match(conditionMessage(err), "0.29999999999999999", fixed = TRUE)
  expect_match(conditionMessage(err), "0.30000000000000004", fixed = TRUE)
  expect_null(conditionCall(err))
})

test_that("numerically constant bias is reported without engine warnings or NaN", {
  for (constant in c(0, 0.3, -0.7)) {
    d <- m3a_bias_runs(reps = 12L, deviations = constant)
    b <- NULL
    expect_warning(b <- suppressMessages(msa_bias(d, "reference")), NA)
    expect_identical(unname(b$overall[c("lower", "upper")]), rep(b$overall[["bias"]], 2))
    expect_identical(b$overall[["p_value"]], NA_real_)
    expect_identical(b$linearity[["r_squared"]], NA_real_)
    expect_identical(b$linearity_item_means[["r_squared"]], NA_real_)
    expect_identical(b$linearity_in_band, constant == 0)
    expect_false(any(is.nan(unlist(b[vapply(b, is.numeric, logical(1))]))))
    expect_equal(b$linearity_band$lower, b$linearity_band$fit)
    expect_equal(b$linearity_band$upper, b$linearity_band$fit)
  }
})

m3a_bias_lm <- function(x, y) {
  fit <- stats::lm(y ~ x)
  s <- summary(fit)
  c(intercept = unname(coef(fit)[1]), slope = unname(coef(fit)[2]),
    slope_p_value = s$coefficients[2, 4], r_squared = s$r.squared,
    t_intercept = s$coefficients[1, 3], t_slope = s$coefficients[2, 3], df = fit$df.residual)
}

test_that("both regressions and the band match independent OLS on unequal item counts", {
  d <- m3a_bias_runs(x = c(1, 2, 2, 4, 7), deviations = c(-0.2, 0.3, 0.15, -0.1))
  d$value <- d$value + rep(c(-0.1, 0.2, -0.3, 0.4, 0.6), each = 4)
  d <- d[-c(1, 5, 6, 18), ]
  d$value[2] <- NA_real_
  d$prompt_id <- rep(c("p", "q"), length.out = nrow(d))
  d$model_id <- rep(c("x", "y", "z"), length.out = nrow(d))
  tol <- numeric_tolerance("package_compare", "abs_tol")
  ok <- !is.na(d$value)
  x <- d$reference[ok]
  y <- d$value[ok] - x
  means <- tapply(y, d$item_id[ok], mean)
  mx <- d$reference[match(names(means), d$item_id)]
  for (level in c(0.5, 0.9, 0.95, 0.99)) {
    b <- msa_bias(d, "reference", level = level)
    oracle <- m3a_bias_lm(x, y)
    expect_equal(b$linearity[names(oracle)], oracle, tolerance = tol)
    im <- m3a_bias_lm(mx, as.numeric(means))
    expect_equal(b$linearity_item_means, im[names(b$linearity_item_means)], tolerance = tol)
    expect_identical(b$linearity_item_means[["df"]], 3)
    expect_gt(abs(b$linearity[["slope"]] - b$linearity_item_means[["slope"]]), tol)
    band <- stats::predict(stats::lm(y ~ x), newdata = data.frame(x = b$linearity_band$reference),
                           interval = "confidence", level = level)
    expect_equal(unname(as.matrix(b$linearity_band[c("fit", "lower", "upper")])), unname(band), tolerance = tol)
    expect_identical(sort(unique(x)), b$linearity_band$reference)
    expected_q <- stats::qt((1 - level) / 2, length(y) - 2, lower.tail = FALSE)
    expect_equal(b$linearity[["t_quantile"]], expected_q, tolerance = tol)
    tt <- stats::t.test(y, conf.level = level)
    expect_equal(unname(b$overall[c("bias", "lower", "upper", "p_value")]),
                 c(unname(tt$estimate), as.numeric(tt$conf.int), tt$p.value), tolerance = tol)
    for (i in seq_len(nrow(b$by_condition))) {
      row <- b$by_condition[i, ]
      take <- ok & d$prompt_id == row$prompt_id & d$model_id == row$model_id
      delta <- d$value[take] - d$reference[take]
      if (length(delta) < 2) next
      tt <- stats::t.test(delta, conf.level = level)
      expect_equal(as.numeric(row[c("bias", "lower", "upper", "p_value")]),
                   c(unname(tt$estimate), as.numeric(tt$conf.int), tt$p.value), tolerance = tol)
    }
  }
  # An admissible confidence level near one must not round its tail to zero.
  level <- 1 - .Machine$double.eps / 2
  b <- msa_bias(d, "reference", level = level)
  q <- stats::qt((1 - level) / 2, length(y) - 1, lower.tail = FALSE)
  expected <- mean(y) + c(-1, 1) * q * stats::sd(y) / sqrt(length(y))
  expect_true(all(is.finite(b$overall[c("lower", "upper")])))
  expect_equal(unname(b$overall[c("lower", "upper")]), expected, tolerance = tol)
})

test_that("the continuous band includes a touching zero and checks interior extrema", {
  # Analytic bands in normalized coordinates: at z=0 half-width is 1/2.
  for (scale in c(1e-200, 1, 1e200)) {
    expect_identical(msa_bias_in_band(scale / 2, 0, scale, 1, 4, c(-2, 2)), TRUE)
    expect_identical(msa_bias_in_band(scale, 0, scale, 1, 4, c(-2, 2)), FALSE)
    expect_identical(msa_bias_in_band(scale, scale, 2 * scale, 1, 1, c(10, 11)), TRUE)
    expect_identical(msa_bias_in_band(0, scale, scale, 2, 1, c(-1, 1)), TRUE)
    expect_identical(msa_bias_in_band(0, 2 * scale, scale, 2, 1, c(-1, 1)), FALSE)
    expect_identical(msa_bias_in_band(scale, 0, 0, 1, 4, c(-1, 1)), FALSE)
    expect_identical(msa_bias_in_band(0, scale, 0, 1, 4, c(-1, 1)), FALSE)
  }
  expect_identical(msa_bias_in_band(0, 0, 0, 1, 4, c(-1, 1)), TRUE)
  expect_identical(msa_bias_in_band(0.5 + .Machine$double.eps, 0, 1, 1, 4, c(-2, 2)), FALSE)
  expect_identical(msa_bias_in_band(0.5 - .Machine$double.eps, 0, 1, 1, 4, c(-2, 2)), TRUE)
  # A nonzero slope moves the critical point away from the centered mean.
  # Both endpoints contain zero, but z=1/5 is an explicit interior witness:
  # 49/100 + (1/5)^2 = 53/100 > sqrt(1/4 + (1/5)^2/2).
  ends <- c(-2, 2)
  expect_true(all(abs(49 / 100 + ends / 5) < sqrt(1 / 4 + ends^2 / 2)))
  expect_gt(53 / 100, sqrt(1 / 4 + (1 / 5)^2 / 2))
  for (scale in c(1e-200, 1, 1e200)) for (sign in c(-1, 1)) {
    expect_identical(msa_bias_in_band(sign * 49 / 100 * scale, sign * scale / 5,
                                      scale, 2, 4, ends), FALSE)
  }
  # A sparse observed reference grid contains zero at each displayed point,
  # while the least-squares confidence band excludes it near the mean.
  d <- m3a_bias_runs(x = c(2, 2.1, 10), reps = 4,
                    deviations = rep(c(0.08, 0.076, 0.079), each = 4) + rep(c(0.1, -0.1), 6))
  b <- msa_bias(d, "reference")
  expect_true(all(b$linearity_band$lower <= 0 & b$linearity_band$upper >= 0))
  expect_identical(b$linearity_in_band, FALSE)
  expect_identical(b$linearity_verdict, "unacceptable")
})

test_that("bias and linearity preserve units, reference origin and row order", {
  d <- m3a_bias_runs(deviations = c(-0.25, 0.5, 0.125, -0.125))
  d$value <- d$value + rep(c(-0.125, 0.25, -0.375, 0.5, 0.75), each = 4)
  a <- msa_bias(d, "reference")
  tol <- numeric_tolerance("package_compare", "abs_tol")
  for (scale in c(1e-180, 0.5, 8, 1e180)) {
    transformed <- d[rev(seq_len(nrow(d))), ]
    transformed$value <- transformed$value * scale
    transformed$reference <- transformed$reference * scale
    b <- msa_bias(transformed, "reference")
    measures <- c("bias", "sd", "lower", "upper")
    expect_equal(b$overall[measures] / scale, a$overall[measures], tolerance = tol)
    for (field in c("linearity", "linearity_item_means")) {
      invariant <- setdiff(names(a[[field]]), "intercept")
      expect_equal(b[[field]][invariant], a[[field]][invariant], tolerance = tol)
      expect_equal(b[[field]][["intercept"]] / scale, a[[field]][["intercept"]], tolerance = tol)
    }
    expect_equal(b$linearity_band / scale, a$linearity_band, tolerance = tol)
    expect_identical(b$linearity_in_band, a$linearity_in_band)
    expect_identical(b$linearity_verdict, a$linearity_verdict)
  }
  moved <- d
  moved$value <- moved$value + 128
  moved$reference <- moved$reference + 128
  b <- msa_bias(moved, "reference")
  expect_identical(a$overall, b$overall)
  expect_equal(b$linearity[["intercept"]], a$linearity[["intercept"]] - 128 * a$linearity[["slope"]], tolerance = tol)
  expect_equal(b$linearity_band[c("fit", "lower", "upper")], a$linearity_band[c("fit", "lower", "upper")], tolerance = tol)
  expect_identical(b$linearity_in_band, a$linearity_in_band)
})

test_that("rank and residual degrees of freedom do not invalidate the bias estimate", {
  d <- m3a_bias_runs(x = c(0, 2), reps = 1, deviations = c(1, 3))
  b <- suppressMessages(msa_bias(d, "reference"))
  expect_identical(unname(b$linearity[c("intercept", "slope", "df")]), c(1, 1, 0))
  expect_true(all(is.na(b$linearity[c("t_intercept", "t_slope", "slope_p_value", "t_quantile")])))
  expect_identical(nrow(b$linearity_band), 0L)
  expect_identical(b$linearity_in_band, NA)
  expect_identical(b$linearity_verdict, NA_character_)
  expect_match(b$linearity_note, "no residual degrees of freedom")
  d <- m3a_bias_runs(x = c(0, 2), reps = 4, deviations = c(-0.1, 0.3, -0.4, 0.2))
  b <- suppressMessages(msa_bias(d, "reference"))
  expect_identical(b$linearity[["df"]], 6)
  expect_identical(b$linearity_item_means[["df"]], 0)
  expect_false(is.na(b$linearity_in_band))
  one <- suppressMessages(msa_bias(d[1, ], "reference"))
  expect_identical(unname(one$overall[c("n", "bias", "n_excluded")]), c(1, -0.1, 0))
  expect_true(all(is.na(one$overall[c("sd", "lower", "upper", "p_value")])))
})

test_that("zero slope remains representable when response and reference scales differ greatly", {
  x <- c(-3, -1, 1, 3) * 1e-200
  y <- c(1, -1, -1, 1) * 1e200
  f <- msa_bias_regression(x, y, 0.95, "Extreme orthogonal study")
  expect_identical(unname(f$coefficients[c("slope", "intercept", "t_slope", "t_intercept")]), rep(0, 4))
  expect_identical(f$coefficients[["slope_p_value"]], 1)
  expect_identical(f$in_band, TRUE)
  # Scaling precedes centering only if subtraction of finite inputs overflows.
  center <- msa_bias_center(c(-.Machine$double.xmax, .Machine$double.xmax, .Machine$double.xmax))
  expect_true(all(is.finite(center$z)))
  expect_equal(center$mean / center$scale, 1 / 3,
               tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  expect_equal(center$z, c(-4 / 3, 2 / 3, 2 / 3),
               tolerance = numeric_tolerance("arithmetic", "abs_tol"))
})

test_that("extreme finite regressions retain their band and intercept", {
  scale <- .Machine$double.xmax
  tol <- numeric_tolerance("package_compare", "abs_tol")
  # Centering the negative reference overflows before scaling. The oracle
  # fits the same regression in bounded reference units.
  x <- c(-1, 1, 1)
  y <- c(1, -1, 0)
  oracle <- stats::lm(y ~ x)
  fit <- msa_bias_regression(x * scale, y, 0.95, "Extreme references")
  expect_equal(fit$coefficients[["intercept"]], unname(coef(oracle)[1]), tolerance = tol)
  expect_equal(fit$coefficients[["slope"]] * scale, unname(coef(oracle)[2]), tolerance = tol)
  band <- stats::predict(oracle, newdata = data.frame(x = c(-1, 1)), interval = "confidence")
  expect_equal(unname(as.matrix(fit$band[c("fit", "lower", "upper")])), unname(band), tolerance = tol)
  expect_true(all(is.finite(unlist(fit[c("coefficients", "band")]))))
  # slope * mean(x) overflows although the final intercept is representable.
  # The algebraic line is y = 2*x - 4/5 in units of double.xmax.
  x <- c(7, 8, 9) / 10
  y <- c(6, 8, 10) / 10
  fit <- suppressMessages(msa_bias_regression(x * scale, y * scale, 0.95, "Extreme intercept"))
  expect_equal(fit$coefficients[["slope"]], 2, tolerance = tol)
  expect_equal(fit$coefficients[["intercept"]] / scale, -4 / 5, tolerance = tol)
  expect_equal(fit$band$fit / scale, y, tolerance = tol)
  expect_equal(fit$band$lower, fit$band$fit, tolerance = tol)
  expect_equal(fit$band$upper, fit$band$fit, tolerance = tol)
  expect_false(any(is.nan(unlist(fit[c("coefficients", "band")]))))
})

test_that("relative constancy boundaries match t inference and algebraic linear fits", {
  eps <- .Machine$double.eps
  expect_true(msa_bias_constant(0, 0))
  expect_true(msa_bias_constant(9 * eps, 1))
  expect_false(msa_bias_constant(10 * eps, 1))
  for (amplitude in c(0, 2, 8, 32, 128) * eps) {
    values <- 1 + amplitude * rep(c(-1, 1), 4)
    oracle <- tryCatch(stats::t.test(values), error = identity)
    result <- suppressMessages(msa_bias_interval(values, 0.95, "synthetic threshold"))
    if (inherits(oracle, "error")) {
      expect_identical(unname(result[c("lower", "upper")]), rep(mean(values), 2))
      expect_identical(result[["p_value"]], NA_real_)
    } else {
      expect_equal(unname(result[c("lower", "upper", "p_value")]),
                   c(as.numeric(oracle$conf.int), oracle$p.value),
                   tolerance = numeric_tolerance("package_compare", "abs_tol"))
    }
    x <- c(-1, -1, 1, 1)
    y <- x + amplitude * c(-1, 1, -1, 1)
    fit <- suppressMessages(msa_bias_regression(x, y, 0.95, "Synthetic regression"))
    expect_identical(is.na(fit$coefficients[["t_slope"]]), amplitude <= 10 * eps)
    expect_equal(unname(fit$coefficients[c("intercept", "slope")]), c(0, 1),
                 tolerance = numeric_tolerance("arithmetic", "abs_tol"))
    expect_equal(fit$coefficients[["r_squared"]], 1 / (1 + amplitude^2),
                 tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  }
})

test_that("numeric regression grids cover scales, near constants and unequal replication", {
  # Seeds and ranges are synthetic test settings, not measured tolerances.
  scenarios <- expand.grid(items = c(3L, 5L), reps = c(2L, 4L),
                            scale = c(1e-180, 1, 1e180), offset = c(0, 32),
                            noise = c(0, .Machine$double.eps, 32 * .Machine$double.eps, 1e-10, 0.2),
                            seed = c(1201L, 1202L))
  failures <- character()
  max_oracle_error <- 0
  for (i in seq_len(nrow(scenarios))) {
    sc <- scenarios[i, ]
    set.seed(sc$seed)
    x <- seq(-2, 2, length.out = sc$items) + sc$offset
    d <- m3a_bias_runs(x, reps = sc$reps, deviations = 0)
    item_bias <- rep(seq(-0.1, 0.2, length.out = sc$items), each = sc$reps)
    d$value <- d$reference + 0.3 + item_bias + sc$noise * stats::rnorm(nrow(d))
    if (sc$seed %% 2L == 0L) d <- d[-c(1, nrow(d)), ]
    d$value <- d$value * sc$scale
    d$reference <- d$reference * sc$scale
    warnings <- character()
    b <- withCallingHandlers(tryCatch(msa_bias(d, "reference"), error = identity),
      message = function(m) invokeRestart("muffleMessage"),
      warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") })
    if (inherits(b, "error")) {
      failures <- c(failures, paste(i, conditionMessage(b)))
      next
    }
    if (length(warnings) || any(rapply(b, function(x) any(is.nan(x)), how = "unlist"))) failures <- c(failures, paste(i, "warning or NaN"))
    if (sc$noise != 0.2) next
    # Normalized inputs keep the independent lm and t.test oracles in range.
    xn <- d$reference / sc$scale
    yn <- (d$value - d$reference) / sc$scale
    oracle <- m3a_bias_lm(xn, yn)
    got <- b$linearity[names(oracle)]
    got[["intercept"]] <- got[["intercept"]] / sc$scale
    tt <- stats::t.test(yn)
    max_oracle_error <- max(max_oracle_error, abs(got - oracle),
                            abs(b$overall[["p_value"]] - tt$p.value),
                            abs(b$overall[c("lower", "upper")] / sc$scale - as.numeric(tt$conf.int)))
    means <- tapply(yn, d$item_id, mean)
    mx <- xn[match(names(means), d$item_id)]
    oracle <- m3a_bias_lm(mx, as.numeric(means))
    got <- b$linearity_item_means
    got[["intercept"]] <- got[["intercept"]] / sc$scale
    max_oracle_error <- max(max_oracle_error, abs(got - oracle[names(got)]))
  }
  expect_identical(failures, character())
  expect_lte(max_oracle_error, numeric_tolerance("package_compare", "abs_tol"))
  message(sprintf("Synthetic bias grid: %d cases, seeds 1201/1202; largest normalized oracle difference %.3g", nrow(scenarios), max_oracle_error))
})

test_that("numeric reference resolution preserves factors and rejects every conflict form", {
  d <- m3a_bias_runs(x = c(2, 4), reps = 3)
  d$reference <- factor(c(NA, "2", "2.0", "4", NA, "4.0"))
  for (ref in list("reference", d[c("item_id", "reference")], stats::setNames(d$reference, d$item_id))) {
    b <- suppressMessages(msa_bias(d, ref))
    expect_identical(b$overall[["n_excluded"]], 0)
    expect_identical(b$overall[["n"]], 6)
  }
  d$reference <- c(2, 5, 2, 4, 4, 4)
  for (idx in list(seq_len(nrow(d)), rev(seq_len(nrow(d))))) {
    s <- d[idx, ]
    for (ref in list("reference", s[c("item_id", "reference")], stats::setNames(s$reference, s$item_id))) {
      err <- tryCatch(msa_bias(s, ref), error = identity)
      expect_s3_class(err, "error")
      expect_identical(conditionMessage(err), 'Conflicting reference values for item_id "i1": "2", "5".')
      expect_null(conditionCall(err))
    }
  }
  parsed <- msa_bias_numeric(factor(c("1.5", "bad", "NaN", NA)), "value")
  expect_identical(parsed, c(1.5, NA_real_, NA_real_, NA_real_))
})

test_that("bias input and numeric range errors are explicit and have no call", {
  check <- function(expr, text) {
    err <- tryCatch(expr, error = identity)
    expect_s3_class(err, "error")
    expect_identical(conditionMessage(err), text)
    expect_null(conditionCall(err))
  }
  d <- m3a_bias_runs()
  for (bad in list(NULL, numeric(), c(0.5, 0.9), NA_real_, NaN, Inf, -Inf, 0, 1, -0.1, 1.1, "0.95", TRUE, 1i)) {
    check(msa_bias(d, "reference", level = bad), "`level` must be a finite numeric scalar strictly between zero and one.")
  }
  check(msa_bias(d[setdiff(names(d), "value")], "reference"), "runs is missing required column(s): value")
  for (column in c("value", "reference")) for (infinite in c(-Inf, Inf)) {
    bad <- d
    bad[[column]][1] <- infinite
    check(msa_bias(bad, "reference"), paste0("`", column, "` must not contain infinite values."))
  }
  for (column in c("value", "reference")) {
    bad <- d
    bad[[column]] <- as.complex(bad[[column]])
    check(msa_bias(bad, "reference"), paste0("`", column, "` must contain real numeric values."))
  }
  bad <- d
  bad$value[] <- NA_real_
  check(msa_bias(bad, "reference"), "Bias requires at least one valid response-reference pair; 20 row(s) excluded because a response or reference is missing or unparseable.")
  check(msa_bias(d[FALSE, ], "reference"), "Bias requires at least one valid response-reference pair; 0 row(s) excluded because a response or reference is missing or unparseable.")
  bad <- d[1, ]
  bad$value <- .Machine$double.xmax
  bad$reference <- -.Machine$double.xmax
  check(msa_bias(bad, "reference"), "Bias differences overflow: `value` minus `reference` must be finite.")
  check(msa_bias_interval(c(-.Machine$double.xmax, .Machine$double.xmax), 0.95, "extreme"),
        "Bias calculation (extreme) exceeds the finite numeric range.")
  check(msa_bias_regression(c(-1, 0, 1) * 1e-200, c(-1, 0, 1) * 1e200, 0.95, "Extreme"),
        "Extreme coefficients exceed the finite numeric range.")
  check(msa_bias_regression(c(-1, 0, 1), c(-1, 1, -1) * .Machine$double.xmax / 2, 0.95, "Extreme"),
        "Extreme confidence band exceeds the finite numeric range.")
})
