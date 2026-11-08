# K-M3c-2: msa_control_chart() gets an argument r4s = c("range", "westgard")
# (default "range"): "range" fires at |z_t - z_(t-1)| > 4, "westgard" when one
# value is > 2 and the other < -2 within the same run (pairs of consecutive
# values); print and msa_report() name the reading used (Formelsammlung Nr. 6).
# This file also holds the R_4s part of K-M3c-1 (each rule fires exactly above
# its limit and not at it). Readings, limits and roles: ANK-86. Interface after
# docs/01 §4 (new argument with a default behind the arguments of v0.1.0, ANK-02).
# What counts as naming the reading in print and report: ACC-3.

acc_m3c_2_section <- function(lines) {
  acc_m3d_section_or_fail(lines, ".*(Westgard|control chart|system suitability)", "on Westgard rules or the control chart")
}

# Normalized non-table lines of a report section.
acc_m3c_2_text <- function(sec) acc_m3d_norm(sec[!grepl("^[[:space:]]*\\|", sec) & nzchar(trimws(sec))])

# Positions listed in the row `rule` of the violations table (NULL without the row).
acc_m3c_2_positions <- function(sec, rule) {
  tab <- acc_m3d_table(sec, c("Rule", "Violations", "Positions"))
  testthat::expect_false(is.null(tab), label = "a table with the columns Rule, Violations, Positions")
  if (is.null(tab)) return(NULL)
  rows <- acc_m3d_rows(tab, "Rule", rule)
  testthat::expect_length(rows, 1L)
  if (length(rows) != 1L) return(NULL)
  acc_m3d_integers(acc_m3d_cell(tab, rows[[1]], "Positions"))
}

test_that("K-M3c-2: msa_control_chart() has the argument r4s = c(\"range\", \"westgard\") behind the arguments of v0.1.0 (ANK-02)", {
  snapshot <- vapply(acc_anchor("ANK-02")$value$functions$msa_control_chart, function(a) a$name, "")
  fm <- formals(msa_control_chart)
  expect_identical(names(fm)[seq_along(snapshot)], snapshot, label = "arguments of v0.1.0 at their positions")
  expect_true("r4s" %in% names(fm), label = "argument r4s")
  if (!"r4s" %in% names(fm)) return(invisible())
  expect_gt(match("r4s", names(fm)), length(snapshot), label = "position of r4s after the arguments of v0.1.0")
  expect_identical(paste(deparse(fm$r4s), collapse = ""), "c(\"range\", \"westgard\")", label = "default of r4s")
  readings <- unlist(lapply(c("R_4s_range", "R_4s_westgard"), function(k) acc_m3c_value("ANK-86", "rules", k, "reading")))
  expect_identical(readings, acc_m3c_readings, label = "ANK-86: readings")
})

test_that("K-M3c-2 (and K-M3c-1 for R_4s): by default R_4s fires at |z_t - z_(t-1)| > 4 and not at a difference of exactly 4; r4s = \"range\" gives the same chart", {
  for (id in names(acc_m3c_r4s_cases())) {
    case <- acc_m3c_r4s_cases()[[id]]
    expect_identical(which(acc_m3c_reference(case$z)$R_4s), case$range, label = sprintf("mini-reference (range) on %s", id))
    by_default <- acc_m3c_chart(case$z, center = 0, sd = 1)
    if (!acc_m3c_chart_ok(by_default, paste(id, "with the default reading"))) next
    expect_identical(which(acc_m3c_column(by_default, "R_4s")), case$range, label = sprintf("R_4s positions on %s (default)", id))
    acc_m3c_expect_reference(by_default, case$z, acc_m3c_rules, "range", paste(id, "(default)"))
    by_range <- acc_m3c_chart(case$z, center = 0, sd = 1, r4s = "range")
    if (!acc_m3c_chart_ok(by_range, paste(id, "with r4s = \"range\""))) next
    expect_identical(by_range, by_default, label = sprintf("%s: r4s = \"range\" equals the default", id))
  }
})

test_that("K-M3c-2 (and K-M3c-1 for R_4s): with r4s = \"westgard\" R_4s fires when one value of a pair of consecutive values is above 2 and the other below -2, not at exactly 2 or -2; the other rules stay as they are and reject includes R_4s", {
  for (id in names(acc_m3c_r4s_cases())) {
    case <- acc_m3c_r4s_cases()[[id]]
    expect_identical(which(acc_m3c_reference(case$z, r4s = "westgard")$R_4s), case$westgard,
                     label = sprintf("mini-reference (westgard) on %s", id))
    for (cs in list(c(0, 1), c(5, 0.25))) {
      x <- cs[1] + case$z * cs[2]
      w <- acc_m3c_chart(x, center = cs[1], sd = cs[2], r4s = "westgard")
      if (!acc_m3c_chart_ok(w, sprintf("%s with r4s = \"westgard\", center %g, sd %g", id, cs[1], cs[2]))) next
      expect_identical(which(acc_m3c_column(w, "R_4s")), case$westgard, label = sprintf("R_4s positions on %s (westgard, center %g)", id, cs[1]))
      acc_m3c_expect_reference(w, case$z, acc_m3c_rules, "westgard", sprintf("%s (westgard, center %g)", id, cs[1]))
      r <- acc_m3c_chart(x, center = cs[1], sd = cs[2])
      if (!acc_m3c_chart_ok(r, paste(id, "with the default reading"))) next
      for (rule in setdiff(acc_m3c_rules, "R_4s")) {
        expect_identical(acc_m3c_column(w, rule), acc_m3c_column(r, rule), label = sprintf("%s: column %s under both readings", id, rule))
      }
    }
  }
})

test_that("K-M3c-2: both readings equal the mini-reference in every rule column and reject on 1500 random series (seed 31082)", {
  series <- acc_m3c_random_series(1500L, 31082L)
  bad <- character()
  for (i in seq_along(series)) {
    z <- series[[i]]
    for (reading in acc_m3c_readings) {
      chart <- acc_m3c_chart(z, center = 0, sd = 1, r4s = reading)
      if (inherits(chart, "error")) {
        bad <- c(bad, sprintf("series %d, %s: %s", i, reading, conditionMessage(chart)))
        next
      }
      ref <- acc_m3c_reference(z, r4s = reading)
      for (r in names(ref)) {
        if (!identical(acc_m3c_column(chart, r), ref[[r]])) bad <- c(bad, sprintf("series %d, %s, column %s", i, reading, r))
      }
    }
  }
  expect_identical(utils::head(bad, 5L), character(), label = sprintf("deviations from the mini-reference (%d in total)", length(bad)))
})

test_that("K-M3c-2: an unknown reading is an error", {
  expect_true("r4s" %in% names(formals(msa_control_chart)), label = "argument r4s")
  expect_error(msa_control_chart(c(0, 1, 2), center = 0, sd = 1, r4s = "spread"))
})

test_that("K-M3c-2: print() names the reading used: a line names R_4s and range under the default, R_4s and westgard under r4s = \"westgard\"", {
  for (z in list(acc_m3c_report_z, c(0.5, -0.5, 0.3, 0.1))) {
    d <- acc_m3c_chart(z, center = 0, sd = 1)
    w <- acc_m3c_chart(z, center = 0, sd = 1, r4s = "westgard")
    if (!acc_m3c_chart_ok(d, "the print fixture") || !acc_m3c_chart_ok(w, "the print fixture with r4s = \"westgard\"")) next
    ld <- acc_m3c_r4s_lines(utils::capture.output(print(d)))
    lw <- acc_m3c_r4s_lines(utils::capture.output(print(w)))
    expect_true(any(grepl("(?i)\\brange\\b", ld, perl = TRUE)), label = sprintf("print (default, %d values): a line names R_4s and range", length(z)))
    expect_true(any(grepl("(?i)westgard", lw, perl = TRUE)), label = sprintf("print (westgard, %d values): a line names R_4s and westgard", length(z)))
    expect_false(setequal(ld, lw), label = sprintf("print (%d values): the R_4s lines differ between the readings", length(z)))
  }
})

test_that("K-M3c-2: msa_report() names the reading of the chart and lists the R_4s positions of that reading", {
  d <- acc_m3c_report_chart(NULL)
  w <- acc_m3c_report_chart("westgard")
  if (!acc_m3c_chart_ok(d, "the report fixture") || !acc_m3c_chart_ok(w, "the report fixture with r4s = \"westgard\"")) return(invisible())
  expect_identical(which(acc_m3c_column(d, "R_4s")), c(3L, 6L), label = "fixture: R_4s positions (range)")
  expect_identical(which(acc_m3c_column(w, "R_4s")), 6L, label = "fixture: R_4s positions (westgard)")
  lines_d <- acc_m3c_report(NULL)
  lines_w <- acc_m3c_report("westgard")
  if (!acc_m3d_report_ok(lines_d, "default-reading chart") || !acc_m3d_report_ok(lines_w, "westgard-reading chart")) return(invisible())
  sec_d <- acc_m3c_2_section(lines_d)
  sec_w <- acc_m3c_2_section(lines_w)
  if (is.null(sec_d) || is.null(sec_w)) return(invisible())
  text_d <- acc_m3c_2_text(sec_d)
  text_w <- acc_m3c_2_text(sec_w)
  range_named <- grepl("(?i)\\bR[ _-]?4s\\b", text_d, perl = TRUE) & grepl("(?i)\\brange\\b", text_d, perl = TRUE) &
    grepl("(?i)consecutive|successive", text_d, perl = TRUE)
  expect_true(any(range_named), label = "default report: a line names R_4s, the range reading and consecutive values")
  westgard_named <- grepl("(?i)\\bR[ _-]?4s\\b", text_w, perl = TRUE) & grepl("(?i)westgard", text_w, perl = TRUE)
  expect_true(any(westgard_named), label = "westgard report: a line names R_4s and the Westgard reading")
  expect_false(setequal(acc_m3c_r4s_lines(sec_d), acc_m3c_r4s_lines(sec_w)), label = "the R_4s lines of the two reports differ")
  expect_identical(acc_m3c_2_positions(sec_d, "R_4s"), c(3L, 6L), label = "default report: positions of R_4s")
  expect_identical(acc_m3c_2_positions(sec_w, "R_4s"), 6L, label = "westgard report: positions of R_4s")
  expect_identical(acc_m3c_2_positions(sec_w, "reject"), which(acc_m3c_column(w, "reject")), label = "westgard report: positions of reject")
})
