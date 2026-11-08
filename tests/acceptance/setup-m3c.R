# Helpers for the M3c acceptance tests (docs/04-weitere-bausteine.md, K-M3c-1
# to K-M3c-6); a setup file for the reason given in setup-acceptance.R.
#
# Reference values come from reference/anchors/ (ANK-86 Westgard et al. 1981
# with the derivations of Formelsammlung §8, ANK-87 Parvin 1992, ANK-89 the
# planning rule after Burdick & Graybill 1992, ANK-16, ANK-06, ANK-TOL) or from
# the oracle the criterion names (qcc::qcc for K-M3c-4), called at test time.
# Scenario values (S-boot-1 components, S-sim-1 design) are settings of the
# spec, not anchors (docs/01 §8).
# K-M3c-3 (false alarm rates against ANK-86 and Parvin 1992, ANK-87) and
# K-M3c-5 (recovery of the components with msa_fit) are class A simulations
# under tests/simulation/ (test-westgard-false-alarm.R and
# test-simulator-recovery.R); the deterministic part of K-M3c-5 (the column
# latent) is test-m3c-5-simulator-latent.R. K-M3c-6 has its class A part in
# tests/simulation/test-plan-satterthwaite.R. Those tests source this file for
# the mini-reference of the rules, the candidate plans and the vignette table.
# The mini-references (rules of Formelsammlung §8, performance measures of
# Formelsammlung §9) are written independently of R/spc.R and R/plan.R.
# Interpretations of points on which the spec is silent are listed in
# orchestrator/handoff/M3c/CRITERIA.json under "open" (ACC-n).

acc_m3c <- new.env(parent = emptyenv())   # cache for one test run

# Anchors ---------------------------------------------------------------------------

# Anchor values are read once per test run (the mini-reference asks for them
# for every series).
acc_m3c_anchor_value <- function(id) {
  key <- paste0("anchor_", id)
  if (is.null(acc_m3c[[key]])) acc_m3c[[key]] <- acc_anchor(id)$value
  acc_m3c[[key]]
}

acc_m3c_value <- function(id, ...) {
  path <- c(...)
  v <- acc_m3c_anchor_value(id)
  for (k in path) {
    v <- v[[k]]
    if (is.null(v)) stop("acceptance: ", id, " has no value ", paste(path, collapse = "$"), call. = FALSE)
  }
  v
}

acc_m3c_tol <- function(entry, key) {
  e <- acc_anchor("ANK-TOL")$value[[entry]]
  if (is.null(e)) stop("acceptance: ANK-TOL has no entry ", entry, call. = FALSE)
  v <- e[[key]]
  if (is.null(v)) stop("acceptance: ANK-TOL.", entry, " has no key ", key, call. = FALSE)
  v
}

acc_m3c_arith <- function() as.numeric(acc_m3c_tol("arithmetic", "abs_tol"))

# Evaluates `expr`; an error becomes the value (muffled messages and warnings).
acc_m3c_try <- function(expr) {
  withCallingHandlers(tryCatch(expr, error = function(e) e),
                      message = function(m) invokeRestart("muffleMessage"),
                      warning = function(w) invokeRestart("muffleWarning"))
}

# Westgard rules (K-M3c-1 to K-M3c-3) -----------------------------------------------

acc_m3c_rules <- c("1_2s", "1_3s", "2_2s", "R_4s", "4_1s", "10_x")
acc_m3c_readings <- c("range", "westgard")

# A small step above a limit that keeps sums with the limits exact in binary
# floating point (ACC-2).
acc_m3c_eps <- 2^-30

# Rule entry of ANK-86; R_4s maps to the entry of the reading.
acc_m3c_rule_spec <- function(rule, r4s = "range") {
  key <- if (rule == "R_4s") paste0("R_4s_", r4s) else rule
  spec <- acc_m3c_value("ANK-86", "rules", key)
  for (f in c("kind", "limit", "window", "role")) {
    if (is.null(spec[[f]])) stop("acceptance: ANK-86 rule ", key, " lacks ", f, call. = FALSE)
  }
  spec
}

# Probability that a rule fires at a position with a complete window when the z
# are independent standard normal (Formelsammlung §8, ANK-86$value$probability).
acc_m3c_rule_probability <- function(spec) {
  k <- as.numeric(spec$limit)
  m <- as.numeric(spec$window)
  tail <- 1 - stats::pnorm(k)
  switch(spec$kind,
    single = 2 * tail,
    same_side_run = 2 * tail^m,
    range = 2 * (1 - stats::pnorm(k / sqrt(2))),
    opposite_pair = 2 * tail^2,
    stop("acceptance: unknown rule kind ", spec$kind, call. = FALSE))
}

# Mini-reference of one rule on a z series without missing values: single
# values beyond the limit, runs counted value by value on each side (a run of
# `window` values beyond the limit on one side fires at its last value and at
# every further value of the run), the absolute difference of a value and its
# predecessor, and a pair with one value above +limit and the other below
# -limit. Nothing fires before the window is complete.
acc_m3c_fire <- function(z, spec) {
  n <- length(z)
  k <- as.numeric(spec$limit)
  m <- as.integer(spec$window)
  out <- logical(n)
  if (spec$kind == "single") return(abs(z) > k)
  if (spec$kind == "same_side_run") {
    up <- 0L
    down <- 0L
    for (t in seq_len(n)) {
      up <- if (z[t] > k) up + 1L else 0L
      down <- if (z[t] < -k) down + 1L else 0L
      out[t] <- up >= m || down >= m
    }
    return(out)
  }
  if (n < 2L) return(out)
  prev <- z[-n]
  cur <- z[-1L]
  out[-1L] <- switch(spec$kind,
    range = abs(cur - prev) > k,
    opposite_pair = (prev > k & cur < -k) | (prev < -k & cur > k),
    stop("acceptance: unknown rule kind ", spec$kind, call. = FALSE))
  out
}

# All rule columns and reject (any rejection rule; 1_2s is a warning).
acc_m3c_reference <- function(z, rules = acc_m3c_rules, r4s = "range") {
  out <- list()
  for (r in rules) out[[r]] <- acc_m3c_fire(z, acc_m3c_rule_spec(r, r4s))
  rejecting <- Filter(function(r) acc_m3c_rule_spec(r, r4s)$role == "rejection", rules)
  out$reject <- if (length(rejecting)) Reduce(`|`, out[rejecting]) else logical(length(z))
  out
}

# The chart or the error of the call.
acc_m3c_chart <- function(x, ...) acc_m3c_try(msa_control_chart(x, ...))

acc_m3c_chart_ok <- function(chart, what) {
  testthat::expect_false(inherits(chart, "error"),
                         label = sprintf("msa_control_chart() for %s (%s)", what,
                                         if (inherits(chart, "error")) conditionMessage(chart) else "ok"))
  !inherits(chart, "error")
}

# Logical column of a chart (NA, if absent).
acc_m3c_column <- function(chart, rule) {
  if (!rule %in% names(chart)) return(rep(NA, nrow(chart)))
  as.logical(chart[[rule]])
}

# Every rule column and reject of a chart equal the mini-reference.
acc_m3c_expect_reference <- function(chart, z, rules, r4s, label) {
  ref <- acc_m3c_reference(z, rules, r4s)
  for (r in names(ref)) {
    testthat::expect_identical(acc_m3c_column(chart, r), ref[[r]], label = sprintf("%s: column %s", label, r))
  }
}

# Constructed z series at the limits of each rule with the positions where the
# rule must fire (ACC-2); e = acc_m3c_eps.
acc_m3c_boundary_cases <- function() {
  e <- acc_m3c_eps
  list(
    "1_2s" = list(z = c(0, 2, 0, 2 + e, 0, -2, 0, -2 - e, 0, 2 - e, 0, -2 + e), fire = c(4L, 8L)),
    "1_3s" = list(z = c(0, 3, 0, 3 + e, 0, -3, 0, -3 - e, 0, 3 - e, 0, -3 + e), fire = c(4L, 8L)),
    "2_2s" = list(z = c(2 + e, 2 + e, 0, 2, 2 + e, 0, 2 + e, 2, 0, -2 - e, -2 - e, 0, -2, -2 - e, 0,
                        2 + e, 0, 2 + e, 0, 2 + e, -2 - e), fire = c(2L, 11L)),
    "4_1s" = list(z = c(rep(1 + e, 4), 0, 1 + e, 1 + e, 1, 1 + e, 0, rep(-1 - e, 5), 0, rep(1 + e, 3), 0,
                        1 + e, -1 - e, 1 + e, -1 - e), fire = c(4L, 14L, 15L)),
    "10_x" = list(z = c(rep(e, 10), 0, rep(e, 9), 0, rep(-e, 11), 0, rep(e, 5), rep(-e, 5)), fire = c(10L, 31L, 32L)))
}

# R_4s cases with the positions of both readings (K-M3c-2).
acc_m3c_r4s_cases <- function() {
  e <- acc_m3c_eps
  list(
    range_limit = list(z = c(2, -2, 0, 2 + e, -2, 0, 2.5 + e, -1.5, 0, -2 - e, 2, 0, 2.5, -1.5, 0, -1.5, 2.5 + e, 0, 3, 0.9, 0),
                       range = c(5L, 8L, 11L, 17L), westgard = integer()),
    westgard_limit = list(z = c(2 + e, -2 - e, 0, -2 - e, 2 + e, 0, 2, -2 - e, 0, 2 + e, -2, 0, 3, -2 - e, 0, 2 + e, -1.9, 0),
                          range = c(2L, 5L, 8L, 11L, 14L), westgard = c(2L, 5L, 14L)))
}

# Random z series with values on and next to every limit (and some normal
# draws), lengths 1 to 16, generated under `seed` (docs/01 §5).
acc_m3c_random_series <- function(n, seed) {
  e <- acc_m3c_eps
  base <- c(0, 1, 1.5, 2, 2.5, 3)
  atoms <- unique(c(base, base + e, base - e, -base, -base - e, -base + e))
  acc_m3a_with_seed(seed, lapply(seq_len(n), function(i) {
    len <- sample.int(16L, 1L)
    z <- sample(atoms, len, replace = TRUE)
    normal <- stats::runif(len) < 0.25
    z[normal] <- stats::rnorm(sum(normal), 0, 1.5)
    z
  }))
}

# Horizontal lines that plot() draws for a chart: h of abline(), segments with
# equal ends and lines with a constant height (ACC-5).
acc_m3c_plot_hlines <- function(chart) {
  grDevices::pdf(NULL)
  dev <- grDevices::dev.cur()
  on.exit(grDevices::dev.off(dev), add = TRUE)
  grDevices::dev.control("enable")
  plot(chart)
  dl <- grDevices::recordPlot()[[1]]
  h <- numeric()
  for (e in dl) {
    args <- e[[2]]
    name <- tryCatch(as.character(args[[1]]$name), error = function(err) "")
    if (!length(name)) next
    if (name == "C_abline" && length(args) >= 4L && is.numeric(args[[4]])) h <- c(h, as.numeric(args[[4]]))
    if (name == "C_segments" && length(args) >= 5L) {
      y0 <- as.numeric(args[[3]])
      y1 <- as.numeric(args[[5]])
      if (length(y0) == length(y1)) h <- c(h, y0[y0 == y1])
    }
    if (name == "C_plotXY") {
      xy <- args[[2]]
      y <- as.numeric(xy$y)
      if (length(y) >= 2L && all(is.finite(y)) && length(unique(y)) == 1L && identical(as.character(args[[3]]), "l")) h <- c(h, y[1])
    }
  }
  h
}

# Report and print (K-M3c-2) ---------------------------------------------------------

# Control values on the z scale (center 0, sd 1): R_4s fires at 3 and 6 under the
# range reading, at 6 only under the Westgard reading; 1_3s fires at 10.
acc_m3c_report_z <- c(0, 2.5, -1.6, 0, 2.1, -2.1, 0, -0.5, 0.3, 3.2, 0)

# Chart of the report fixture: r4s = NULL calls msa_control_chart() without the
# argument (the default reading).
acc_m3c_report_chart <- function(r4s = NULL) {
  key <- paste0("chart_", if (is.null(r4s)) "default" else r4s)
  if (is.null(acc_m3c[[key]])) {
    acc_m3c[[key]] <- if (is.null(r4s)) acc_m3c_chart(acc_m3c_report_z, center = 0, sd = 1) else
      acc_m3c_chart(acc_m3c_report_z, center = 0, sd = 1, r4s = r4s)
  }
  acc_m3c[[key]]
}

# Rendered report with the chart of a reading (lines or the error).
acc_m3c_report <- function(r4s = NULL) {
  chart <- acc_m3c_report_chart(r4s)
  if (inherits(chart, "error")) return(chart)
  acc_m3d_report(paste0("m3c_", if (is.null(r4s)) "default" else r4s), acc_m3d_numeric_study()$grr, control_chart = chart)
}

# Lines that name R_4s (also R4s) together with a reading.
acc_m3c_r4s_lines <- function(lines) {
  n <- acc_m3d_norm(lines)
  n[grepl("(?i)\\bR[ _-]?4s\\b", n, perl = TRUE) & grepl("(?i)\\b(range|westgard)\\b", n, perl = TRUE)]
}

# Planning by simulation (K-M3c-6) ----------------------------------------------------

# Columns that msa_plan() adds (ACC-7) and the columns of attr(, "replicates").
acc_m3c_plan_columns <- c("bias", "empse", "mcse_bias", "mcse_empse")
acc_m3c_replicate_columns <- c("scenario", "sim", "estimate", "singular", "prompt")

# Quantile of definition 7 of Hyndman & Fan (1996), the R default, by hand.
acc_m3c_quantile7 <- function(x, p) {
  x <- sort(x)
  n <- length(x)
  h <- (n - 1) * p + 1
  lo <- floor(h)
  hi <- min(lo + 1, n)
  x[lo] + (h - lo) * (x[hi] - x[lo])
}

# True %GRR of Formelsammlung §9 from the assumed components (missing ones are
# zero): every component except the items belongs to GRR.
acc_m3c_true_grr <- function(vc) {
  v <- vapply(vc, as.numeric, numeric(1))
  item <- if ("item" %in% names(v)) v[["item"]] else 0
  grr <- sum(v[names(v) != "item"])
  100 * sqrt(grr / (grr + item))
}

# Performance measures of Formelsammlung §9 from the estimates of one candidate
# plan; misclassification against the verdict thresholds of ANK-16.
acc_m3c_plan_reference <- function(est, singular, truth) {
  n <- length(est)
  m <- sum(est) / n
  ss <- sum((est - m)^2)
  empse <- sqrt(ss / (n - 1))
  verdict <- vapply(est, acc_m1a_verdict_reference, "")
  list(mean = m, bias = m - truth, empse = empse, mcse_bias = sqrt(ss / (n * (n - 1))),
       mcse_empse = empse / sqrt(2 * (n - 1)),
       q2.5 = acc_m3c_quantile7(est, 0.025), median = acc_m3c_quantile7(est, 0.5), q97.5 = acc_m3c_quantile7(est, 0.975),
       rmse = sqrt(sum((est - truth)^2) / n),
       pct_singular = 100 * sum(singular) / n,
       pct_misclassified = 100 * sum(verdict != acc_m1a_verdict_reference(truth)) / n)
}

# Candidate plans of the planning-rule comparison (ACC-8): designs of 20 and 40
# items with three and five prompt variants, three models, two replicates and
# two blocks (40 items, 3 prompts: the design of S-sim-1); components of
# S-boot-1 (docs/02 M1c); one msa_plan() call per plan with its seed.
acc_m3c_plans <- data.frame(plan = sprintf("S-plan-%d", 1:4), n_items = c(20L, 20L, 40L, 40L),
                            n_prompts = c(3L, 5L, 3L, 5L), n_models = 3L, n_reps = 2L, n_blocks = 2L,
                            stringsAsFactors = FALSE)
acc_m3c_plan_vc <- list(item = 1, prompt = 0.05, model = 0.05, block = 0.01, item_prompt = 0.01,
                        item_model = 0.05, prompt_model = 0.005, residual = 0.1)
acc_m3c_plan_seed <- function(i) 20261108L + as.integer(i)

# Empirical CV of the prompt component (sd / mean over all repetitions) and the
# share of boundary estimates (prompt component exactly 0) with its MCSE.
acc_m3c_prompt_summary <- function(prompt) {
  n <- length(prompt)
  m <- sum(prompt) / n
  p <- sum(prompt == 0) / n
  list(cv = sqrt(sum((prompt - m)^2) / (n - 1)) / m, boundary = p, mcse = sqrt(p * (1 - p) / n), n = n)
}

# Vignette table of the planning-rule comparison ------------------------------------------

acc_m3c_plan_table_columns <- c("plan", "items", "prompts", "nu", "cv_rule", "cv_empirical", "boundary_share",
                                "mcse_boundary", "n_sim")

# Lines of the section of the knitted vignette whose header names the planning
# rule; NULL without such a header.
acc_m3c_plan_section <- function(lines) {
  lines <- acc_m1a_unfence(lines)
  is_header <- grepl("^#{1,6}[[:space:]]", lines)
  title <- trimws(sub("^#{1,6}[[:space:]]+", "", lines))
  hit <- which(is_header & grepl("(?i)planning rule", title, perl = TRUE))
  if (!length(hit)) return(NULL)
  start <- hit[1]
  level <- nchar(sub("^(#{1,6}).*$", "\\1", lines))
  stop_at <- which(is_header & seq_along(lines) > start & level <= level[start])
  lines[seq(start, if (length(stop_at)) stop_at[1] - 1L else length(lines))]
}

# The first table of the section with exactly the columns of
# acc_m3c_plan_table_columns (names case-insensitive, any order); NULL if none.
acc_m3c_plan_table <- function(section) {
  for (tab in acc_m1a_tables(section)) {
    nm <- tolower(trimws(names(tab)))
    if (length(nm) != length(acc_m3c_plan_table_columns) || !setequal(nm, acc_m3c_plan_table_columns)) next
    names(tab) <- nm
    tab[] <- lapply(tab, function(x) trimws(as.character(x)))
    return(tab[, acc_m3c_plan_table_columns])
  }
  NULL
}

# A number shown in a cell: value and half a unit of the last shown digit; a
# percent sign turns it into a proportion.
acc_m3c_shown <- function(cell) {
  tok <- regmatches(cell, regexpr("[-+]?(?:[0-9]+\\.?[0-9]*|\\.[0-9]+)(?:[eE][-+]?[0-9]+)?", cell, perl = TRUE))
  if (!length(tok)) return(c(value = NA_real_, half = NA_real_))
  mant <- sub("[eE].*$", "", tok)
  expo <- if (grepl("[eE]", tok)) as.numeric(sub("^.*[eE]", "", tok)) else 0
  dec <- if (grepl("\\.", mant)) nchar(sub("^[^.]*\\.", "", mant)) else 0
  scale <- if (grepl("%", cell, fixed = TRUE)) 100 else 1
  c(value = as.numeric(tok) / scale, half = 0.5 * 10^(expo - dec) / scale)
}

# TRUE if a shown cell equals `value` up to half a unit of its last digit.
acc_m3c_shows <- function(cell, value) {
  s <- acc_m3c_shown(cell)
  is.finite(s[["value"]]) && abs(s[["value"]] - value) <= s[["half"]] + acc_m3c_arith()
}
