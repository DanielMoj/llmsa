# K-M3c-1: every Westgard rule fires on constructed z series exactly above its
# limit and not at or just below it: 1_2s (warning) at |z| > 2, 1_3s at |z| > 3,
# 2_2s at two consecutive values > 2 or < -2 on the same side, 4_1s at four
# consecutive values > 1 or < -1 on the same side, 10_x at ten consecutive
# values on one side of 0, R_4s after K-M3c-2 (test-m3c-2-r4s-reading.R);
# standardization with the given center/sd or from the first n_baseline values
# (Formelsammlung §8). Limits, windows and roles of the rules come from ANK-86;
# the mini-reference acc_m3c_reference() (setup-m3c.R) is written from
# Formelsammlung §8 and Westgard et al. (1981), p. 494. Constructed series and
# the step acc_m3c_eps = 2^-30 above a limit: ACC-2.

test_that("K-M3c-1: the limits, windows and roles of the rules in ANK-86 are those of Formelsammlung §8", {
  expected <- list("1_2s" = c(2, 1), "1_3s" = c(3, 1), "2_2s" = c(2, 2), "4_1s" = c(1, 4), "10_x" = c(0, 10))
  for (rule in names(expected)) {
    spec <- acc_m3c_rule_spec(rule)
    expect_identical(c(as.numeric(spec$limit), as.numeric(spec$window)), expected[[rule]], label = paste("ANK-86 limit and window of", rule))
    expect_identical(spec$role, if (rule == "1_2s") "warning" else "rejection", label = paste("ANK-86 role of", rule))
  }
})

test_that("K-M3c-1: each rule fires exactly above its limit on constructed z series and not at the limit or just below it (center 0, sd 1)", {
  for (rule in names(acc_m3c_boundary_cases())) {
    case <- acc_m3c_boundary_cases()[[rule]]
    ref <- acc_m3c_reference(case$z)
    expect_identical(which(ref[[rule]]), case$fire, label = sprintf("mini-reference on the %s series", rule))
    chart <- acc_m3c_chart(case$z, center = 0, sd = 1)
    if (!acc_m3c_chart_ok(chart, paste("the", rule, "series"))) next
    expect_identical(which(acc_m3c_column(chart, rule)), case$fire, label = sprintf("positions where %s fires", rule))
    acc_m3c_expect_reference(chart, case$z, acc_m3c_rules, "range", paste("the", rule, "series"))
  }
})

test_that("K-M3c-1: 1_2s is a warning only: a series on which only 1_2s fires is never rejected, and reject is the union of the rejection rules", {
  case <- acc_m3c_boundary_cases()[["1_2s"]]
  chart <- acc_m3c_chart(case$z, center = 0, sd = 1)
  if (!acc_m3c_chart_ok(chart, "the 1_2s series")) return(invisible())
  for (rule in setdiff(acc_m3c_rules, "1_2s")) {
    expect_false(any(acc_m3c_column(chart, rule)), label = sprintf("fixture: %s fires on the 1_2s series", rule))
  }
  expect_true(any(acc_m3c_column(chart, "1_2s")), label = "1_2s fires on the 1_2s series")
  expect_identical(acc_m3c_column(chart, "reject"), rep(FALSE, length(case$z)), label = "reject on the 1_2s series")
  only13 <- acc_m3c_chart(c(0, 3 + acc_m3c_eps, 0), center = 0, sd = 1)
  if (acc_m3c_chart_ok(only13, "a single value above 3")) {
    expect_identical(acc_m3c_column(only13, "reject"), c(FALSE, TRUE, FALSE), label = "reject at a value above 3")
  }
})

test_that("K-M3c-1: with a given center and sd the chart standardizes z = (x - center) / sd and the rules fire at the same positions", {
  tol <- acc_m3c_arith()
  for (cs in list(c(5, 0.25), c(-3.5, 2))) {
    for (rule in names(acc_m3c_boundary_cases())) {
      case <- acc_m3c_boundary_cases()[[rule]]
      x <- cs[1] + case$z * cs[2]
      chart <- acc_m3c_chart(x, center = cs[1], sd = cs[2])
      if (!acc_m3c_chart_ok(chart, sprintf("the %s series with center %g and sd %g", rule, cs[1], cs[2]))) next
      expect_equal(as.numeric(attr(chart, "center")), cs[1], tolerance = 0, label = "attribute center")
      expect_equal(as.numeric(attr(chart, "sd")), cs[2], tolerance = 0, label = "attribute sd")
      expect_equal(as.numeric(chart$x), x, tolerance = 0, label = "column x")
      expect_lte(max(abs(as.numeric(chart$z) - (x - cs[1]) / cs[2])), tol, label = "max |z - (x - center) / sd|")
      expect_identical(which(acc_m3c_column(chart, rule)), case$fire,
                       label = sprintf("positions of %s with center %g and sd %g", rule, cs[1], cs[2]))
      acc_m3c_expect_reference(chart, (x - cs[1]) / cs[2], acc_m3c_rules, "range", sprintf("%s series, center %g, sd %g", rule, cs[1], cs[2]))
    }
  }
})

test_that("K-M3c-1: without center and sd the chart takes the mean and sd of the first n_baseline values (default 10) and fires at the limits on that scale", {
  e <- acc_m3c_eps
  n0 <- as.integer(acc_m3c_value("ANK-86", "standardization", "n0_default"))
  expect_identical(n0, 10L, label = "ANK-86: default n_0")
  # Baseline 10 +- 1.5 (four values) and 10 (six values): mean 10 and sd 1 exactly.
  base <- 10 + c(-1.5, 1.5, -1.5, 1.5, 0, 0, 0, 0, 0, 0)
  x <- c(base, 12, 10, 12 + e, 10, 13, 10, 13 + e, 10, 7 - e, 10)
  chart <- acc_m3c_chart(x)
  if (acc_m3c_chart_ok(chart, "a series with ten baseline values")) {
    expect_identical(as.numeric(attr(chart, "center")), mean(base), label = "center from the first 10 values")
    expect_identical(as.numeric(attr(chart, "sd")), stats::sd(base), label = "sd from the first 10 values")
    expect_identical(which(acc_m3c_column(chart, "1_2s")), c(13L, 15L, 17L, 19L), label = "1_2s on the baseline scale")
    expect_identical(which(acc_m3c_column(chart, "1_3s")), c(17L, 19L), label = "1_3s on the baseline scale")
    acc_m3c_expect_reference(chart, (x - mean(base)) / stats::sd(base), acc_m3c_rules, "range", "ten baseline values")
  }
  # Three baseline values 9, 10, 11: mean 10 and sd 1.
  x3 <- c(9, 10, 11, 12, 12 + e, 13 + e)
  chart3 <- acc_m3c_chart(x3, n_baseline = 3)
  if (acc_m3c_chart_ok(chart3, "n_baseline = 3")) {
    expect_identical(c(as.numeric(attr(chart3, "center")), as.numeric(attr(chart3, "sd"))), c(10, 1), label = "center and sd from three values")
    expect_identical(which(acc_m3c_column(chart3, "1_2s")), c(5L, 6L), label = "1_2s with n_baseline = 3")
    expect_identical(which(acc_m3c_column(chart3, "1_3s")), 6L, label = "1_3s with n_baseline = 3")
    expect_identical(which(acc_m3c_column(chart3, "2_2s")), 6L, label = "2_2s with n_baseline = 3")
  }
  # Given values take precedence over the baseline: z = (x - 10) / 0.5 is
  # -2, 0, 2, 4, 4 + 2e, 6 + 2e.
  given <- acc_m3c_chart(x3, center = 10, sd = 0.5, n_baseline = 3)
  if (acc_m3c_chart_ok(given, "given center and sd with n_baseline = 3")) {
    expect_identical(c(as.numeric(attr(given, "center")), as.numeric(attr(given, "sd"))), c(10, 0.5), label = "given center and sd")
    expect_identical(which(acc_m3c_column(given, "1_2s")), c(4L, 5L, 6L), label = "1_2s with center 10 and sd 0.5")
    expect_identical(which(acc_m3c_column(given, "1_3s")), c(4L, 5L, 6L), label = "1_3s with center 10 and sd 0.5")
  }
})

test_that("K-M3c-1: every rule column and reject equal the mini-reference on 1500 random series with values on and next to the limits (seed 31081)", {
  series <- acc_m3c_random_series(1500L, 31081L)
  bad <- character()
  for (i in seq_along(series)) {
    z <- series[[i]]
    chart <- acc_m3c_chart(z, center = 0, sd = 1)
    if (inherits(chart, "error")) {
      bad <- c(bad, sprintf("series %d: %s", i, conditionMessage(chart)))
      next
    }
    ref <- acc_m3c_reference(z)
    for (r in names(ref)) {
      if (!identical(acc_m3c_column(chart, r), ref[[r]])) bad <- c(bad, sprintf("series %d (%s), column %s", i, paste(format(z, digits = 17), collapse = " "), r))
    }
  }
  expect_identical(utils::head(bad, 5L), character(), label = sprintf("deviations from the mini-reference (%d in total)", length(bad)))
})
