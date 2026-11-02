test_that("bootstrap counts every non-finite kind and keeps finite cells of partial failures", {
  fit <- suppressMessages(msa_fit(numeric_test_runs()))
  statistics <- names(msa_grr(fit)$summary)
  # Explicit synthetic bootstrap values distinguish row diagnostics from
  # the per-statistic finite values used in the percentile intervals.
  values <- matrix(seq_len(42L), nrow = 7L,
                   dimnames = list(NULL, statistics)) * 1.0
  values[1L, 2L] <- Inf
  values[2L, 3L] <- -Inf
  values[3L, 4L] <- NaN
  values[4L, 6L] <- NA_real_
  flags <- c(1, 1, 1, NA, 1, 1, 0)
  seen <- NULL
  testthat::local_mocked_bindings(bootMer = function(x, FUN, nsim, seed, type, ...) {
    seen <<- list(statistic = FUN(x), nsim = nsim, seed = seed, type = type,
                   dots = list(...))
    list(t = cbind(values, .singular = flags))
  }, .package = "lme4")
  b <- msa_boot(fit, nsim = 7L, level = 0.8, seed = 20261102L, use.u = FALSE)
  expect_identical(attr(b, "boot"), values)
  expect_identical(b$statistic, statistics)
  expect_identical(names(seen$statistic), c(statistics, ".singular"))
  expect_identical(unname(tail(seen$statistic, 1L)), as.numeric(lme4::isSingular(fit$model)))
  expect_identical(seen[c("nsim", "seed", "type", "dots")],
    list(nsim = 7L, seed = 20261102L, type = "parametric", dots = list(use.u = FALSE)))
  expect_identical(attr(b, "n_failed"), 4L)
  expect_identical(attr(b, "n_singular"), 2L)
  expect_identical(attr(b, "level"), 0.8)
  expect_identical(b$estimate, unname(msa_grr(fit)$summary))
  expected <- vapply(seq_along(statistics), function(j) {
    stats::quantile(values[is.finite(values[, j]), j], c(0.1, 0.9), names = FALSE)
  }, numeric(2))
  expect_equal(b$lower, expected[1L, ], tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  expect_equal(b$upper, expected[2L, ], tolerance = numeric_tolerance("arithmetic", "abs_tol"))

  # No finite values means unavailable intervals and zero usable singular fits.
  values[,] <- NA_real_
  empty <- msa_boot(fit, nsim = 7L, seed = 20261102L)
  expect_true(all(is.na(empty$lower) & is.na(empty$upper)))
  expect_identical(attr(empty, "n_failed"), 7L)
  expect_identical(attr(empty, "n_singular"), 0L)
})

test_that("bootstrap diagnostics come from the actual refits and exclude failed refits", {
  fit <- suppressMessages(msa_fit(numeric_test_runs()))
  original <- get("refit", asNamespace("lme4"))
  calls <- 0L
  singular <- logical()
  testthat::local_mocked_bindings(refit = function(object, newresp = NULL, ...) {
    calls <<- calls + 1L
    if (calls %in% c(2L, 4L)) stop("Synthetic refit failure", call. = FALSE)
    model <- original(object, newresp, ...)
    singular <<- c(singular, lme4::isSingular(model))
    model
  }, .package = "lme4")
  captured <- latent_test_capture(msa_boot(fit, nsim = 8L, seed = 20261103L))
  b <- captured$value
  expect_identical(calls, 8L)
  expect_match(paste(captured$warnings, collapse = " "), "bootstrap runs failed")
  expect_identical(which(!stats::complete.cases(attr(b, "boot"))), c(2L, 4L))
  expect_identical(attr(b, "n_failed"), 2L)
  expect_identical(attr(b, "n_singular"), sum(singular))
  expect_identical(dim(attr(b, "boot")), c(8L, 6L))
  lines <- capture.output(returned <- withVisible(print(b)))
  expect_identical(returned, list(value = b, visible = FALSE))
  expect_match(lines[length(lines) - 1L], "2 failed or non-finite replicates")
  expect_identical(tail(lines, 1L), sprintf("  %d singular replicates retained in the intervals", sum(singular)))
  expect_false(any(grepl("singular", lines) & grepl("dropped", lines)))
})

test_that("one bootstrap replicate retains its matrix shape and percentile endpoints", {
  fit <- suppressMessages(msa_fit(numeric_test_runs()))
  b <- msa_boot(fit, nsim = 1L, seed = 20261104L)
  expect_identical(dim(attr(b, "boot")), c(1L, 6L))
  expect_identical(b$lower, unname(attr(b, "boot")[1L, ]))
  expect_identical(b$upper, b$lower)
  expect_identical(attr(b, "n_failed"), 0L)
})

test_that("older bootstrap objects report an unrecorded singular count without inventing zero", {
  # Synthetic object in the pre-M1c format.
  old <- data.frame(statistic = "icc_items", estimate = 0.5, lower = 0.25, upper = 0.75)
  attr(old, "boot") <- matrix(c(0.25, 0.75), ncol = 1L)
  attr(old, "level") <- 0.95
  attr(old, "n_failed") <- 0L
  class(old) <- c("msa_boot", "data.frame")
  lines <- capture.output(returned <- withVisible(print(old)))
  expect_identical(tail(lines, 2L), c(
    "  0 failed or non-finite replicates (non-finite values dropped)",
    "  singular replicates: not recorded for this object"))
  expect_identical(returned, list(value = old, visible = FALSE))
  expect_null(attr(old, "n_singular"))
})
