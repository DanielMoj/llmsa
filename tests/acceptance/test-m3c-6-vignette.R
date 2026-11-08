# K-M3c-6 (vignette part): the comparison of the empirical coefficient of
# variation of the prompt component with the planning rule CV ~ sqrt(2 / nu),
# nu = a - 1 (ankerRef: ANK-89), is reported per candidate plan together with
# the share of boundary estimates in vignettes/validation.Rmd and is no pass
# criterion. Here: the knitted vignette (shared knit, acc_m1a_knit_validation())
# holds a section whose header names the planning rule with a table of the
# candidate plans S-plan-1 to S-plan-4 (acc_m3c_plans, ACC-8); nu and the rule
# value follow from the number of prompts, n_sim is at least ANK-06, the share
# of boundary estimates is a proportion with the MCSE sqrt(p (1 - p) / n_sim)
# (Formelsammlung §9), and no shown value is typed into the Rmd. That the shown
# values are those msa_plan() gives for these plans is checked by the class A
# test tests/simulation/test-plan-satterthwaite.R, which generates the numbers.
# K-M3c-6: the build of the vignette by R CMD check is decided by the lint gate.

acc_m3c_6_table <- function() {
  k <- acc_m1a_knit_validation()
  sec <- acc_m3c_plan_section(k$lines)
  if (is.null(sec)) return(NULL)
  acc_m3c_plan_table(sec)
}

test_that("K-M3c-6: the knitted vignettes/validation.Rmd holds a section on the planning rule with a table of the candidate plans S-plan-1 to S-plan-4 (plan, items, prompts, nu, cv_rule, cv_empirical, boundary_share, mcse_boundary, n_sim)", {
  k <- acc_m1a_knit_validation()
  expect_null(k$error)
  sec <- acc_m3c_plan_section(k$lines)
  expect_true(!is.null(sec), label = "a section whose header names the planning rule")
  if (is.null(sec)) return(invisible())
  tab <- acc_m3c_plan_table(sec)
  expect_true(!is.null(tab), label = sprintf("a table with exactly the columns %s", paste(acc_m3c_plan_table_columns, collapse = ", ")))
  if (is.null(tab)) return(invisible())
  expect_identical(sort(tab$plan, method = "radix"), acc_m3c_plans$plan, label = "rows of the table (one per candidate plan)")
  for (i in seq_len(nrow(acc_m3c_plans))) {
    r <- tab[tab$plan == acc_m3c_plans$plan[i], , drop = FALSE]
    if (nrow(r) != 1L) next
    expect_identical(suppressWarnings(as.integer(r$items)), acc_m3c_plans$n_items[i], label = sprintf("%s: items", r$plan))
    expect_identical(suppressWarnings(as.integer(r$prompts)), acc_m3c_plans$n_prompts[i], label = sprintf("%s: prompts", r$plan))
  }
})

test_that("K-M3c-6: per candidate plan nu = prompts - 1 and cv_rule = sqrt(2 / nu) (ankerRef: ANK-89); n_sim >= ANK-06; the boundary share is a proportion with MCSE sqrt(p (1 - p) / n_sim); cv_empirical is positive", {
  tab <- acc_m3c_6_table()
  expect_true(!is.null(tab), label = "the planning-rule table of the vignette")
  if (is.null(tab)) return(invisible())
  numerator <- as.numeric(acc_m3c_value("ANK-89", "numerator"))
  offset <- as.integer(acc_m3c_value("ANK-89", "nu_offset"))
  n_min <- as.integer(acc_m3c_value("ANK-06", "n_sim_min"))
  for (i in seq_len(nrow(tab))) {
    r <- tab[i, , drop = FALSE]
    a <- suppressWarnings(as.integer(r$prompts))
    nu <- suppressWarnings(as.integer(r$nu))
    expect_identical(nu, a - offset, label = sprintf("%s: nu %s = prompts %s - %d", r$plan, r$nu, r$prompts, offset))
    if (is.na(nu) || nu < 1L) next
    expect_true(acc_m3c_shows(r$cv_rule, sqrt(numerator / nu)), label = sprintf("%s: cv_rule %s shows sqrt(%g / %d) = %.6f", r$plan, r$cv_rule, numerator, nu, sqrt(numerator / nu)))
    n <- suppressWarnings(as.numeric(gsub("[^0-9]", "", r$n_sim)))
    expect_true(is.finite(n) && n >= n_min, label = sprintf("%s: n_sim %s >= %d", r$plan, r$n_sim, n_min))
    cv <- acc_m3c_shown(r$cv_empirical)
    expect_true(is.finite(cv[["value"]]) && cv[["value"]] > 0, label = sprintf("%s: cv_empirical %s is a positive number", r$plan, r$cv_empirical))
    expect_lte(cv[["half"]], 0.005, label = sprintf("%s: cv_empirical %s has at least two decimals", r$plan, r$cv_empirical))
    p <- acc_m3c_shown(r$boundary_share)
    m <- acc_m3c_shown(r$mcse_boundary)
    expect_true(is.finite(p[["value"]]) && p[["value"]] >= 0 && p[["value"]] <= 1, label = sprintf("%s: boundary_share %s is a proportion", r$plan, r$boundary_share))
    expect_lte(p[["half"]], 5e-4, label = sprintf("%s: boundary_share %s to 0.001 or 0.1 %%", r$plan, r$boundary_share))
    expect_lte(m[["half"]], 5e-4, label = sprintf("%s: mcse_boundary %s to 0.001 or 0.1 %%", r$plan, r$mcse_boundary))
    if (!is.finite(n) || !is.finite(p[["value"]]) || !is.finite(m[["value"]])) next
    lo <- max(0, p[["value"]] - p[["half"]])
    hi <- min(1, p[["value"]] + p[["half"]])
    m_lo <- min(sqrt(lo * (1 - lo) / n), sqrt(hi * (1 - hi) / n))
    m_hi <- if (lo <= 0.5 && hi >= 0.5) sqrt(0.25 / n) else max(sqrt(lo * (1 - lo) / n), sqrt(hi * (1 - hi) / n))
    expect_true(m[["value"]] >= m_lo - m[["half"]] - acc_m3c_arith() && m[["value"]] <= m_hi + m[["half"]] + acc_m3c_arith(),
                label = sprintf("%s: mcse_boundary %s is sqrt(p (1 - p) / n_sim) of boundary_share %s with n_sim %s", r$plan, r$mcse_boundary, r$boundary_share, r$n_sim))
  }
})

test_that("K-M3c-6: no number of the planning-rule table is typed into validation.Rmd", {
  tab <- acc_m3c_6_table()
  expect_true(!is.null(tab), label = "the planning-rule table of the vignette")
  if (is.null(tab)) return(invisible())
  # As for K-M3a-7: shown numbers with at least three significant digits.
  shown <- unlist(lapply(c(tab$cv_rule, tab$cv_empirical, tab$boundary_share, tab$mcse_boundary), acc_m1a_numbers))
  sig <- nchar(sub("^0+", "", gsub("[^0-9]", "", sub("[eE].*$", "", shown))))
  values <- as.numeric(shown[sig >= 3L])
  lit <- acc_m1a_rmd_literals(readLines(acc_m1a_vignette_path(), warn = FALSE))
  typed <- unique(lit$token[lit$significant >= 3L & lit$value %in% values])
  expect_identical(typed, character(), label = "numbers of the planning-rule table that appear as literals in validation.Rmd")
})
