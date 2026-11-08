# K-M3c-5: simulator (class A, docs/01 §8; docs/04 M3c). Data from
# msa_simulate() with given components (scenario S-sim-1: items 40, prompts 3,
# models 3, replicates 2, blocks 2; components as S-boot-1) give over n_sim >=
# ANK-06 repetitions with msa_fit means of the components within
# ANK-TOL.mc_factor (pass) Monte Carlo standard errors of the given values, and
# the column latent carries the item truth. The scenario values are settings of
# the spec, not anchors (docs/01 §8; S-boot-1: docs/02 M1c). The deterministic
# part on latent is tests/acceptance/test-m3c-5-simulator-latent.R.
#
# ADEMP. Aim: recovery of the variance components by the simulator and the
# numeric fit. Data: msa_simulate(40, 3, 3, 2, 2, vc = S-boot-1 components,
# seed = seed + s) for repetition s = 1 to ANK-06. Estimands: the eight given
# components; the item truth mean + item effect. Method: msa_fit(type =
# "numeric") with its defaults. Performance measures: mean of the estimates per
# component with the MCSE of a mean (Formelsammlung §9, MCSE(Bias)); pass
# |mean - given value| <= ANK-TOL.mc_factor (pass) x MCSE. Item truth (ACC-6):
# latent is constant within every item of every repetition, and over the
# repetitions the mean of the item variance of latent (n - 1 divisor) matches
# the item component, the mean of latent the grand mean 0, the mean of
# value - latent 0 and the covariance of latent with the item means of
# value - latent 0, each within the same number of MCSE. Seed, RNG, versions
# and runtime are reported in a message.

sim_recovery_seed <- 20261108L

sim_s_sim_1 <- list(items = 40L, prompts = 3L, models = 3L, reps = 2L, blocks = 2L)
sim_s_boot_1_vc <- list(item = 1, prompt = 0.05, model = 0.05, block = 0.01, item_prompt = 0.01,
                        item_model = 0.05, prompt_model = 0.005, residual = 0.1)
# Source names of msa_fit()$vc for the components of msa_simulate().
sim_vc_sources <- c(item = "item", prompt = "prompt", model = "model", block = "block", item_prompt = "item:prompt",
                    item_model = "item:model", prompt_model = "prompt:model", residual = "Residual")

test_that("K-M3c-5: data from msa_simulate() for S-sim-1 give over n_sim = ANK-06 repetitions with msa_fit means of the eight components within ANK-TOL.mc_factor MCSE of the given components, and latent is the item truth", {
  t0 <- proc.time()[["elapsed"]]
  n_sim <- as.integer(sim_value("ANK-06", "n_sim_min"))
  k_pass <- as.numeric(sim_tol("mc_factor", "pass"))
  sc <- sim_s_sim_1
  reps <- sim_with_seed(sim_recovery_seed, sim_parallel(seq_len(n_sim), function(s) {
    r <- msa_simulate(sc$items, sc$prompts, sc$models, sc$reps, sc$blocks, vc = sim_s_boot_1_vc, seed = sim_recovery_seed + s)
    f <- suppressMessages(suppressWarnings(msa_fit(r, type = "numeric")))
    v <- stats::setNames(as.numeric(f$vc$variance), as.character(f$vc$source))
    lat <- tapply(r$latent, r$item_id, function(x) x[1])
    res <- tapply(r$value - r$latent, r$item_id, mean)
    list(v = unname(v[sim_vc_sources]),
         constant = all(tapply(r$latent, r$item_id, function(x) length(unique(x))) == 1L),
         items = length(lat), lat_mean = mean(lat), lat_var = stats::var(lat), resid_mean = mean(r$value - r$latent),
         cov = stats::cov(as.numeric(lat), as.numeric(res[names(lat)])))
  }))
  est <- do.call(rbind, lapply(reps, function(x) x$v))
  colnames(est) <- names(sim_vc_sources)
  report <- character()
  for (k in names(sim_vc_sources)) {
    x <- est[, k]
    expect_true(all(is.finite(x)), label = sprintf("%s: finite estimates in all %d repetitions", sim_vc_sources[[k]], n_sim))
    if (!all(is.finite(x))) next
    truth <- sim_s_boot_1_vc[[k]]
    mcse <- sim_mcse_mean(x)
    d <- (mean(x) - truth) / mcse
    expect_lte(abs(mean(x) - truth), k_pass * mcse,
               label = sprintf("%s: mean %.6f, given %g, MCSE %.6f (%+.2f MCSE)", sim_vc_sources[[k]], mean(x), truth, mcse, d))
    report <- c(report, sprintf("%-13s mean %.6f given %-6g bias %+.6f MCSE %.6f (%+.2f MCSE); estimates at 0: %d",
                                sim_vc_sources[[k]], mean(x), truth, mean(x) - truth, mcse, d, sum(x == 0)))
  }
  constant <- vapply(reps, function(x) isTRUE(x$constant), logical(1))
  expect_true(all(constant), label = sprintf("latent constant within every item (%d of %d repetitions)", sum(constant), n_sim))
  expect_true(all(vapply(reps, function(x) x$items, integer(1)) == sc$items), label = "one latent value for each of the 40 items")
  checks <- list(lat_var = sim_s_boot_1_vc$item, lat_mean = 0, resid_mean = 0, cov = 0)
  labels <- c(lat_var = "item variance of latent", lat_mean = "mean of latent", resid_mean = "mean of value - latent",
              cov = "covariance of latent with the item means of value - latent")
  for (k in names(checks)) {
    x <- vapply(reps, function(r) as.numeric(r[[k]]), numeric(1))
    mcse <- sim_mcse_mean(x)
    d <- (mean(x) - checks[[k]]) / mcse
    expect_lte(abs(mean(x) - checks[[k]]), k_pass * mcse,
               label = sprintf("%s: mean %.6f, expected %g, MCSE %.6f (%+.2f MCSE)", labels[[k]], mean(x), checks[[k]], mcse, d))
    report <- c(report, sprintf("%s: mean %.6f expected %g MCSE %.6f (%+.2f MCSE)", labels[[k]], mean(x), checks[[k]], mcse, d))
  }
  message("K-M3c-5 (tests/simulation/test-simulator-recovery.R, ", sprintf("%.1f s", proc.time()[["elapsed"]] - t0), "):\n",
          sprintf("S-sim-1 (items %d, prompts %d, models %d, replicates %d, blocks %d), n_sim %d, seeds %d + s, %s\n",
                  sc$items, sc$prompts, sc$models, sc$reps, sc$blocks, n_sim, sim_recovery_seed, sim_session_note(sim_recovery_seed)),
          paste(report, collapse = "\n"))
})
