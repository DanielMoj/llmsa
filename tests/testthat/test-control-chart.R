# Synthetic series exercise rule semantics and presentation, not reference data.
chart_expect_error <- function(expr, message) {
  error <- tryCatch(force(expr), error = identity)
  expect_s3_class(error, "error")
  expect_identical(conditionMessage(error), message)
  expect_null(conditionCall(error))
}

test_that("R_4s uses strict adjacent pairs in both orientations", {
  eps <- 2^-30
  z <- c(2, -2, 0, 2 + eps, -2 - eps, 2 + eps, 0, 2.5, -1.5 - eps)
  range <- msa_control_chart(z, center = 0, sd = 1, rules = "R_4s")
  westgard <- msa_control_chart(z, center = 0, sd = 1, rules = "R_4s", r4s = "westgard")
  expect_identical(which(range$R_4s), c(5L, 6L, 9L))
  expect_identical(which(westgard$R_4s), c(5L, 6L))
  expect_identical(range$reject, range$R_4s)
  expect_identical(westgard$reject, westgard$R_4s)
  expect_identical(attr(range, "r4s"), "range")
  expect_identical(attr(westgard, "r4s"), "westgard")
  expect_identical(range, msa_control_chart(z, 0, 1, rules = "R_4s", r4s = "range"))
  expect_error(msa_control_chart(z, 0, 1, r4s = "unknown"), "'arg' should be one of")
  expect_false(msa_control_chart(3, 0, 1, rules = "R_4s", r4s = "westgard")$R_4s)
})

test_that("chart rules preserve signs, affine scales and selected rejection rules", {
  set.seed(20261109)
  series <- c(stats::rnorm(25), rep(1.25, 11), 2.5, -2.5, 0, -3.5)
  for (reading in c("range", "westgard")) {
    a <- msa_control_chart(series, 0, 1, r4s = reading)
    for (cs in list(c(7, 2), c(-3, 0.5))) {
      b <- msa_control_chart(cs[1] + cs[2] * series, cs[1], cs[2], r4s = reading)
      expect_identical(as.data.frame(b)[, attr(a, "rules")], as.data.frame(a)[, attr(a, "rules")])
      expect_identical(b$reject, a$reject)
    }
    reverse <- msa_control_chart(-series, 0, 1, r4s = reading)
    expect_identical(as.data.frame(reverse)[, attr(a, "rules")], as.data.frame(a)[, attr(a, "rules")])
    selected <- msa_control_chart(series, 0, 1, rules = c("1_2s", "10_x"), r4s = reading)
    expect_identical(selected$reject, a$`10_x`)
    expect_identical(selected$`1_2s`, a$`1_2s`)
    only_warning <- msa_control_chart(series, 0, 1, rules = "1_2s", r4s = reading)
    expect_identical(only_warning$reject, rep(FALSE, length(series)))
    empty <- msa_control_chart(series, 0, 1, rules = character(), r4s = reading)
    expect_identical(names(empty), c("index", "x", "z", "reject"))
    expect_identical(empty$reject, rep(FALSE, length(series)))
  }
})

test_that("only missing chart parameters are estimated from the initial nonmissing baseline", {
  x <- c(9, NA, 10, 11, 100)
  center_only <- msa_control_chart(x, center = 12, n_baseline = 4)
  sd_only <- msa_control_chart(x, sd = 2, n_baseline = 4)
  both_missing <- msa_control_chart(x, n_baseline = 4)
  expect_identical(attr(center_only, "center"), 12)
  expect_identical(attr(center_only, "sd"), 1)
  expect_identical(center_only$z, x - 12)
  expect_identical(attr(sd_only, "center"), 10)
  expect_identical(attr(sd_only, "sd"), 2)
  expect_identical(sd_only$z, (x - 10) / 2)
  expect_identical(attr(both_missing, "center"), 10)
  expect_identical(attr(both_missing, "sd"), 1)
  short <- msa_control_chart(c(9, 10, 11), n_baseline = 10)
  expect_identical(short$z, c(-1, 0, 1))
  for (sd in c(0, -1, NA_real_, Inf, NaN)) {
    chart_expect_error(msa_control_chart(x, center = 10, sd = sd), "`sd` must be a positive number.")
  }
})

test_that("missing controls retain the existing vectorized rule and reject semantics", {
  z <- c(0, 2.5, -2.1, NA, 3, -0.5, 2.1, -2.1, 0)
  for (reading in c("range", "westgard")) {
    chart <- msa_control_chart(z, 0, 1, r4s = reading)
    expect_identical(chart$R_4s, c(FALSE, FALSE, TRUE, NA, FALSE, FALSE, FALSE, TRUE, FALSE))
    expect_false(anyNA(chart$reject))
    expect_identical(chart$reject, c(FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE))
  }
})

test_that("chart printing names the reading, counts fired rules and displays warning and rejection rows", {
  old_options <- options(width = 200, OutDec = ".")
  on.exit(options(old_options), add = TRUE)
  # This is a presentation assertion; rule values are tested independently above.
  for (z in list(c(0, 2.5, -1.75, 0, -2.25, 2.5, 0, 3.5), c(0, 0.5, -0.5), c(0, 2.5, 0))) {
    for (reading in c("range", "westgard")) {
      chart <- msa_control_chart(1.25 + z / 2, center = 1.25, sd = 0.5, r4s = reading)
      tab <- as.data.frame(chart)
      rows <- which(chart$reject | chart$`1_2s`)
      counts <- colSums(tab[, setdiff(attr(chart, "rules"), "1_2s"), drop = FALSE])
      counts <- counts[counts != 0]
      expected <- c(sprintf("Control chart: %d points, center 1.2500, sd 0.5000; %d rejection(s)",
                            nrow(chart), sum(chart$reject)),
                    paste0("  R_4s reading: ", reading),
                    if (length(counts)) paste0("  rules fired: ", paste0(names(counts), " (", counts, ")", collapse = ", "), " "),
                    utils::capture.output(print(tab[rows, ], row.names = FALSE)))
      result <- NULL
      output <- utils::capture.output(result <- withVisible(print(chart)))
      expect_identical(output, expected)
      expect_identical(utils::capture.output({ print(chart); cat("end\n") }), c(expected, "end"))
      expect_identical(result$value, chart)
      expect_false(result$visible)
    }
  }
  only <- msa_control_chart(c(3, -3, 0), 0, 1, rules = "R_4s")
  output <- utils::capture.output(print(only))
  table <- utils::capture.output(print(as.data.frame(only)[2L, ], row.names = FALSE))
  expect_identical(tail(output, length(table)), table)
})

test_that("old chart objects retain their reading and malformed attributes are explicit errors", {
  chart <- msa_control_chart(c(0, 2.5, -1.6), 0, 1)
  current <- utils::capture.output(print(chart))
  attr(chart, "r4s") <- NULL
  expect_identical(utils::capture.output(print(chart)), current)
  for (value in list(c("range", "westgard"), 1, character(), NA_character_, "unknown")) {
    attr(chart, "r4s") <- value
    chart_expect_error(print(chart), "The control chart `r4s` attribute must be 'range' or 'westgard'.")
  }
})

chart_record_plot <- function(chart, ...) {
  grDevices::pdf(NULL)
  device <- grDevices::dev.cur()
  on.exit(grDevices::dev.off(device), add = TRUE)
  grDevices::dev.control("enable")
  value <- withVisible(plot(chart, ...))
  calls <- list()
  for (entry in grDevices::recordPlot()[[1L]]) {
    args <- as.list(entry[[2L]])
    if (is.list(args[[1L]]) && !is.null(args[[1L]]$name)) {
      calls <- c(calls, stats::setNames(list(args[-1L]), args[[1L]]$name))
    }
  }
  list(calls = calls, value = value)
}

test_that("the control plot draws the data, rejection symbols, labels and styled limits", {
  tolerance <- numeric_tolerance("arithmetic", "abs_tol")
  # All data are within three SD, making the requested plot margin observable.
  chart <- msa_control_chart(c(5, 6.25, 3.75, 5, 5.5), center = 5, sd = 0.5)
  recorded <- chart_record_plot(chart, cex = 0.75)
  calls <- recorded$calls
  points <- calls[names(calls) == "C_plotXY"]
  window <- calls[names(calls) == "C_plot_window"]
  titles <- calls[names(calls) == "C_title"]
  limits <- calls[names(calls) == "C_abline"]
  expect_length(points, 1L)
  expect_identical(points[[1L]][[1L]]$x, as.numeric(chart$index))
  expect_identical(points[[1L]][[1L]]$y, chart$x)
  expect_identical(points[[1L]][[2L]], "b")
  expect_identical(points[[1L]][[3L]], c(1, 1, 19, 1, 1))
  expect_identical(points[[1L]][[5L]], c("black", "black", "red", "black", "black"))
  expect_identical(points[[1L]][[7L]], 0.75)
  expect_length(window, 1L)
  expect_equal(window[[1L]][[2L]], c(3.4, 6.6), tolerance = tolerance)
  expect_identical(titles[[1L]][[1L]], "System suitability control chart")
  expect_identical(titles[[1L]][[3L]], "control run")
  expect_identical(titles[[1L]][[4L]], "control statistic")
  expect_length(limits, 4L)
  expect_identical(limits[[1L]][[3L]], 5)
  expect_identical(limits[[1L]][[7L]], 1)
  for (i in seq_len(3L)) {
    expect_equal(sort(limits[[i + 1L]][[3L]]), 5 + c(-i, i) / 2, tolerance = tolerance)
    expect_identical(limits[[i + 1L]][[6L]], c("grey60", "orange", "red")[i])
    expect_identical(limits[[i + 1L]][[7L]], c(3, 2, 2)[i])
  }
  expect_identical(recorded$value$value, chart)
  expect_false(recorded$value$visible)
})
