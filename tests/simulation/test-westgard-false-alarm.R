# K-M3c-3: false alarms of the Westgard rules (class A, docs/01 §8; docs/04
# M3c). For independent standard normal z the probability that a rule fires
# lies, per rule and position, within ANK-TOL.mc_factor (pass) Monte Carlo
# standard errors of the analytic values of Formelsammlung §8 (ANK-86), and the
# mean rejection probability per run of the combination 1_3s/2_2s/4_1s/10_x
# without R_4s with N = 1 lies under control and for shifts of 1 sd and 2 sd
# within the tolerance of Parvin (1992), Table 1 (ANK-87); n_sim >= ANK-06.
#
# ADEMP, part 1. Aim: firing probability of each rule (both R_4s readings,
# K-M3c-2) at each position 1 to 12 of a chart. Data: 100 x ANK-06 independent
# series of 12 values z ~ N(0, 1) per reading, center 0, sd 1. Estimand: the
# probability of Formelsammlung §8 at positions with a complete window, 0
# before it. Method: msa_control_chart(r4s = reading). Performance measure:
# firing share per position with MCSE sqrt(p (1 - p) / n_sim) of the analytic
# value p (Formelsammlung §9); pass |share - p| <= ANK-TOL.mc_factor (pass) x
# MCSE, exactly 0 before the window. Every chart also equals the mini-reference
# acc_m3c_reference() (tests/acceptance/setup-m3c.R) in all columns. With
# n_sim = ANK-06 alone a rule that never fires would pass for 2_2s (0.00104 is
# within 4 MCSE of 0), hence 100 x ANK-06 (ACC-4).
#
# ADEMP, part 2. Aim: mean rejection probability per run p_cr = 1/ARL after
# Parvin (1992, p. 359 and 361), ongoing case with one control value per run.
# Data: per trial 10 in-control values (redrawn while the last of them is
# rejected), then values z + SE until the first rejection; SE = 0, 1, 2 sd;
# 20 x ANK-06 trials per condition. Method: msa_control_chart(rules = 1_3s,
# 2_2s, 4_1s, 10_x). Estimand: p_cr of Table 1, N = 1 (ANK-87). Performance
# measure: 1/mean(run length) with the MCSE of the mean run length
# (Formelsammlung §9) carried to 1/ARL by the delta method (reported only);
# pass |1/ARL - p_cr| <= the tolerance of ANK-87 (Parvin, p. 360). Seeds, RNG,
# versions and runtime are reported in a message.

sim_westgard_seed <- 20261108L
sim_westgard_workers <- 14L

# Splits n trials over the workers; worker w runs the trials of block w.
sim_westgard_share <- function(n, w, workers = sim_westgard_workers) {
  per <- ceiling(n / workers)
  max(0L, min(per, n - (w - 1L) * per))
}

test_that("K-M3c-3: for independent standard normal z the probability that each rule fires at each position lies within ANK-TOL.mc_factor MCSE of the analytic value of ANK-86 (both R_4s readings, 100 x ANK-06 series of length 12), and every chart equals the mini-reference", {
  t0 <- proc.time()[["elapsed"]]
  env <- sim_m3c_env()
  n_sim <- 100L * as.integer(sim_value("ANK-06", "n_sim_min"))
  k_pass <- as.numeric(sim_tol("mc_factor", "pass"))
  arith <- as.numeric(sim_tol("arithmetic", "abs_tol"))
  len <- 12L
  for (e in sim_value("ANK-86", "printed")) {
    key <- e$rule
    spec <- if (startsWith(key, "R_4s_")) env$acc_m3c_rule_spec("R_4s", sub("^R_4s_", "", key)) else env$acc_m3c_rule_spec(key)
    p <- env$acc_m3c_rule_probability(spec)
    expect_lte(abs(p - as.numeric(e$value)), 0.5 * 10^(-as.numeric(e$decimals)) + arith,
               label = sprintf("ANK-86: printed value %s of %s against the formula %.7f", format(e$value), key, p))
  }
  cols <- c(env$acc_m3c_rules, "reject")
  report <- character()
  for (j in seq_along(env$acc_m3c_readings)) {
    reading <- env$acc_m3c_readings[j]
    seed <- sim_westgard_seed + 100L * j
    parts <- sim_with_seed(seed, sim_parallel(seq_len(sim_westgard_workers), function(w) {
      set.seed(seed + w)
      m <- sim_westgard_share(n_sim, w)
      fired <- matrix(0, len, length(cols), dimnames = list(NULL, cols))
      mismatch <- 0L
      for (i in seq_len(m)) {
        z <- stats::rnorm(len)
        # The range reading is the default (K-M3c-2): called without r4s.
        ch <- if (reading == "range") msa_control_chart(z, center = 0, sd = 1) else msa_control_chart(z, center = 0, sd = 1, r4s = reading)
        ref <- env$acc_m3c_reference(z, r4s = reading)
        for (r in cols) {
          v <- as.logical(ch[[r]])
          if (!identical(v, ref[[r]])) mismatch <- mismatch + 1L
          fired[, r] <- fired[, r] + (v %in% TRUE)
        }
      }
      list(fired = fired, mismatch = mismatch, m = m)
    }))
    fired <- Reduce(`+`, lapply(parts, function(x) x$fired))
    mismatch <- sum(vapply(parts, function(x) x$mismatch, integer(1)))
    expect_identical(sum(vapply(parts, function(x) as.integer(x$m), integer(1))), n_sim, label = sprintf("%s: series simulated", reading))
    expect_identical(mismatch, 0L, label = sprintf("%s: columns that differ from the mini-reference", reading))
    worst_rule <- ""
    worst_position <- 0L
    worst_d <- 0
    for (rule in env$acc_m3c_rules) {
      spec <- env$acc_m3c_rule_spec(rule, reading)
      p <- env$acc_m3c_rule_probability(spec)
      mcse <- sim_mcse_prop(p, n_sim)
      for (t in seq_len(len)) {
        count <- unname(fired[t, rule])
        rate <- count / n_sim
        if (t < as.integer(spec$window)) {
          expect_identical(count, 0, label = sprintf("%s, %s: firings at position %d before the window of %d", reading, rule, t, as.integer(spec$window)))
          next
        }
        d <- as.numeric((rate - p) / mcse)
        if (abs(d) > abs(worst_d)) {
          worst_rule <- rule
          worst_position <- t
          worst_d <- d
        }
        expect_lte(abs(rate - p), k_pass * mcse,
                   label = sprintf("%s, %s, position %d: share %.6f, analytic %.6f, MCSE %.6f (%+.2f MCSE)", reading, rule, t, rate, p, mcse, d))
      }
      shares <- unname(fired[as.integer(spec$window):len, rule]) / n_sim
      report <- c(report, sprintf("%-8s %-5s analytic %.6f; share per position %.6f to %.6f (MCSE %.6f)", reading, rule, p, min(shares), max(shares), mcse))
    }
    report <- c(report, sprintf("%-8s largest deviation %s at position %d: %+.2f MCSE; n_sim %d series of %d values, %s", reading, worst_rule,
                                worst_position, worst_d, n_sim, len, sim_session_note(seed)))
  }
  message("K-M3c-3 (tests/simulation/test-westgard-false-alarm.R, firing per rule and position, ", sprintf("%.1f s", proc.time()[["elapsed"]] - t0), "):\n",
          paste(report, collapse = "\n"))
})

test_that("K-M3c-3: the mean rejection probability per run (1/ARL) of 1_3s/2_2s/4_1s/10_x without R_4s with one control value per run lies under control and for shifts of 1 sd and 2 sd within the tolerance of Parvin (1992), Table 1 (ANK-87); 20 x ANK-06 trials per condition", {
  t0 <- proc.time()[["elapsed"]]
  env <- sim_m3c_env()
  n_trials <- 20L * as.integer(sim_value("ANK-06", "n_sim_min"))
  rules <- as.character(unlist(sim_value("ANK-87", "rules")))
  expect_identical(rules, c("1_3s", "2_2s", "4_1s", "10_x"), label = "ANK-87: rules of the combination")
  expect_identical(as.integer(sim_value("ANK-87", "controls_per_run")), 1L, label = "ANK-87: one control value per run")
  history <- as.integer(sim_value("ANK-87", "procedure", "history_runs"))
  tol <- as.numeric(sim_anchor("ANK-87")$tolerance)
  report <- character()
  for (cond in sim_value("ANK-87", "p_cr")) {
    se <- as.numeric(cond$se)
    target <- as.numeric(cond$value)
    seed <- sim_westgard_seed + 1000L + as.integer(round(10 * se))
    parts <- sim_with_seed(seed, sim_parallel(seq_len(sim_westgard_workers), function(w) {
      set.seed(seed + w)
      m <- sim_westgard_share(n_trials, w)
      rl <- integer(m)
      bad <- 0L
      for (i in seq_len(m)) {
        repeat {
          h <- stats::rnorm(history)
          ch <- msa_control_chart(h, center = 0, sd = 1, rules = rules)
          ok <- !isTRUE(as.logical(ch$reject[history]))
          if (!identical(ok, !env$acc_m3c_reference(h, rules = rules)$reject[history])) bad <- bad + 1L
          if (ok) break
        }
        x <- h
        repeat {
          x <- c(x, stats::rnorm(200L) + se)
          ch <- msa_control_chart(x, center = 0, sd = 1, rules = rules)
          hit <- which(as.logical(ch$reject) & seq_along(x) > history)
          if (length(hit)) break
        }
        rl[i] <- hit[1] - history
        if (!identical(as.logical(ch$reject), env$acc_m3c_reference(x, rules = rules)$reject)) bad <- bad + 1L
      }
      list(rl = rl, bad = bad)
    }))
    rl <- unlist(lapply(parts, function(x) x$rl))
    bad <- sum(vapply(parts, function(x) x$bad, integer(1)))
    expect_identical(length(rl), n_trials, label = sprintf("SE %g: trials", se))
    expect_identical(bad, 0L, label = sprintf("SE %g: charts whose reject column differs from the mini-reference", se))
    arl <- mean(rl)
    mcse_arl <- sim_mcse_mean(rl)
    p_hat <- 1 / arl
    mcse_p <- mcse_arl / arl^2
    expect_lte(abs(p_hat - target), tol,
               label = sprintf("SE %g: 1/ARL %.5f (MCSE %.5f) against Parvin's %.3f, |difference| %.5f within %.3f", se, p_hat, mcse_p, target, abs(p_hat - target), tol))
    report <- c(report, sprintf("SE %g: ARL %.3f (MCSE %.3f), 1/ARL %.5f (MCSE %.5f), Parvin %.3f, difference %+.5f (tolerance %.3f); %d trials, %s",
                                se, arl, mcse_arl, p_hat, mcse_p, target, p_hat - target, tol, n_trials, sim_session_note(seed)))
  }
  message("K-M3c-3 (tests/simulation/test-westgard-false-alarm.R, Parvin 1992, ", sprintf("%.1f s", proc.time()[["elapsed"]] - t0), "):\n",
          paste(report, collapse = "\n"))
})
