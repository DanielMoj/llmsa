# K-M3c-4: the Shewhart limits (center +- 1, 2, 3 sd) of the chart equal
# qcc::qcc(type = "xbar.one") with the given center and std.dev, called at test
# time (tolerance ANK-TOL.oracle, value for closed forms). The limits of the
# chart are the horizontal lines that plot() draws (ACC-5); the multipliers
# come from ANK-86 (Formelsammlung §8).

acc_m3c_4_cases <- list(
  list(x = c(10.1, 9.7, 10.9, 11.2, 8.8, 10.0, 12.6, 9.4), center = 10.3, sd = 0.7),
  list(x = c(0.93, 0.91, 0.95, 0.88, 0.84, 0.92), center = 0.92, sd = 0.02),
  list(x = c(-4.5, -3.2, -6.9, -4.0, -1.1), center = -4.1, sd = 1.3))

test_that("K-M3c-4: the center line and the limits center +- 1, 2, 3 sd that plot() draws for a chart with given center and sd equal qcc::qcc(type = \"xbar.one\", center, std.dev, nsigmas) (ANK-TOL.oracle)", {
  tol <- as.numeric(acc_m3c_tol("oracle", "closed_form_rel_tol"))
  multipliers <- as.integer(unlist(acc_m3c_value("ANK-86", "shewhart_limits", "multipliers")))
  expect_identical(multipliers, 1:3, label = "ANK-86: multipliers of the Shewhart limits")
  for (case in acc_m3c_4_cases) {
    what <- sprintf("center %g, sd %g", case$center, case$sd)
    chart <- acc_m3c_chart(case$x, center = case$center, sd = case$sd)
    if (!acc_m3c_chart_ok(chart, what)) next
    h <- acc_m3c_try(acc_m3c_plot_hlines(chart))
    expect_false(inherits(h, "error"), label = sprintf("plot() of the chart (%s)", what))
    if (inherits(h, "error")) next
    hit <- function(v) any(abs(h - v) <= tol * abs(v))
    q_center <- NULL
    for (k in multipliers) {
      q <- qcc::qcc(case$x, type = "xbar.one", center = case$center, std.dev = case$sd, nsigmas = k, plot = FALSE)
      q_center <- as.numeric(q$center)
      lim <- as.numeric(q$limits)
      expect_length(lim, 2L)
      for (v in lim) expect_true(hit(v), label = sprintf("%s: the chart draws the qcc limit %.10g (nsigmas %d)", what, v, k))
    }
    expect_true(hit(q_center), label = sprintf("%s: the chart draws the qcc center %.10g", what, q_center))
    expect_identical(as.numeric(attr(chart, "center")), case$center, label = sprintf("%s: attribute center", what))
    expect_identical(as.numeric(attr(chart, "sd")), case$sd, label = sprintf("%s: attribute sd", what))
  }
})
