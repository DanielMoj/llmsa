# K-M3a-7: coverage of the bias interval (class A, docs/01 §8; docs/04 M3a).
# For the scenarios S-bias-1 (items 20, prompts 3, models 3, replicates 3,
# residual sigma² 0.1, item sigma² 1, true bias 0.2) and S-bias-2 (as
# S-bias-1, residual sigma² 0.5, bias 0) the measured coverage of the 95 %
# interval lies within ANK-TOL.mc_factor (pass) Monte Carlo standard errors of
# 0.95 (n_sim >= ANK-06). The vignette part of K-M3a-7 is tested in
# tests/acceptance/test-m3a-7-vignette.R. The scenario values are settings of
# the spec, not anchors (docs/01 §8).
#
# ADEMP. Aim: coverage of the t interval of msa_bias() for the mean bias.
# Data: a reference x_i ~ N(0, item sigma²) per item (the item truth) and
# answers y = x_i + bias + e with e ~ N(0, residual sigma²), independent for
# every item, prompt, model and replicate (the scenarios name no prompt,
# model or block component; ACC-14). Estimand: the true bias. Method:
# msa_bias(level = 0.95), interval overall[c("lower", "upper")]. Performance
# measure: coverage = share of repetitions with lower <= bias <= upper, with
# MCSE sqrt(c (1 - c) / n_sim) (Formelsammlung §9); n_sim = ANK-06 per
# scenario; pass |c - 0.95| <= ANK-TOL.mc_factor (pass) x MCSE. Every interval
# also equals the mini-reference t interval of AIAG (2010), p. 88-89, on the
# same simulated data (ANK-TOL.package_compare). Seed, RNG, versions and
# runtime are reported in a message.

sim_bias_seed <- 20261105L

sim_bias_scenarios <- list(
  "S-bias-1" = list(items = 20L, prompts = 3L, models = 3L, reps = 3L, residual = 0.1, item = 1, bias = 0.2),
  "S-bias-2" = list(items = 20L, prompts = 3L, models = 3L, reps = 3L, residual = 0.5, item = 1, bias = 0))

# Mini-reference of the t interval (AIAG 2010, p. 88-89; Formelsammlung §6):
# mean deviation +- t_{n-1, 1-alpha/2} s / sqrt(n).
sim_bias_t_interval <- function(d, level) {
  n <- length(d)
  m <- mean(d)
  h <- stats::qt(1 - (1 - level) / 2, n - 1) * sqrt(sum((d - m)^2) / (n - 1)) / sqrt(n)
  c(m - h, m + h)
}

test_that("K-M3a-7: the coverage of the 95 % bias interval of msa_bias() lies within ANK-TOL.mc_factor MCSE of 0.95 for S-bias-1 and S-bias-2 (n_sim = ANK-06), and every interval equals the mini-reference t interval", {
  t0 <- proc.time()[["elapsed"]]
  n_sim <- as.integer(sim_value("ANK-06", "n_sim_min"))
  k_pass <- as.numeric(sim_tol("mc_factor", "pass"))
  tol <- as.numeric(sim_tol("package_compare", "abs_tol"))
  level <- 0.95
  report <- character()
  for (i in seq_along(sim_bias_scenarios)) {
    id <- names(sim_bias_scenarios)[i]
    sc <- sim_bias_scenarios[[i]]
    seed <- sim_bias_seed + i
    g <- expand.grid(rep = seq_len(sc$reps), model = seq_len(sc$models), prompt = seq_len(sc$prompts), item = seq_len(sc$items))
    items <- sprintf("I%02d", seq_len(sc$items))
    frame <- data.frame(item_id = items[g$item], prompt_id = paste0("P", g$prompt), model_id = paste0("M", g$model),
                        rep = g$rep, stringsAsFactors = FALSE)
    res <- sim_with_seed(seed, vapply(seq_len(n_sim), function(s) {
      x <- stats::rnorm(sc$items, 0, sqrt(sc$item))
      y <- x[g$item] + sc$bias + stats::rnorm(nrow(g), 0, sqrt(sc$residual))
      frame$value <- y
      b <- msa_bias(as_msa_runs(frame), reference = data.frame(item_id = items, reference = x, stringsAsFactors = FALSE),
                    level = level)
      c(b$overall[["lower"]], b$overall[["upper"]], sim_bias_t_interval(y - x[g$item], level))
    }, numeric(4)))
    covered <- res[1, ] <= sc$bias & sc$bias <= res[2, ]
    coverage <- mean(covered)
    mcse <- sim_mcse_prop(coverage, n_sim)
    worst <- max(abs(res[1, ] - res[3, ]), abs(res[2, ] - res[4, ]))
    expect_lte(worst, tol, label = sprintf("%s: largest difference of an interval bound to the mini-reference (%.3g)", id, worst))
    expect_lte(abs(coverage - 0.95), k_pass * mcse,
               label = sprintf("%s: coverage %.4f (MCSE %.4f), distance to 0.95: %+.4f (%+.1f MCSE)", id, coverage, mcse,
                               coverage - 0.95, (coverage - 0.95) / mcse))
    report <- c(report, sprintf("%s: coverage %.4f (MCSE %.4f), distance to 0.95 %+.4f (%+.1f MCSE); n_sim %d, %s", id, coverage, mcse,
                                coverage - 0.95, (coverage - 0.95) / mcse, n_sim, sim_session_note(seed)))
  }
  message("K-M3a-7 (tests/simulation/test-bias-coverage.R, ", sprintf("%.1f s", proc.time()[["elapsed"]] - t0), "):\n",
          paste(report, collapse = "\n"))
})
