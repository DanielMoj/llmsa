# K-M3b-5: false alarm rate of Lenth's method (class A, docs/01 §8; docs/04
# M3b). Under the null hypothesis (all effects zero, normal noise) the share of
# effects declared active at ME lies within ANK-TOL.mc_factor (pass) Monte
# Carlo standard errors of alpha per effect, and at SME the share of plans with
# at least one active effect likewise around alpha (nominal level after Lenth
# 1989, ANK-81), for N = 12 with 8 and 11 factors, n_sim >= ANK-06.
#
# ADEMP. Aim: per-effect and family-wise false alarm rate of msa_robustness()
# under H0. Data: y ~ N(0, 1) independently per run of
# pb_design(k, n_runs = 12, randomize = FALSE), k = 8 and 11 (scenarios of the
# criterion). Estimands: P(|E_j| > ME) per effect and P(max_j |E_j| > SME) per
# plan. Method: msa_robustness(alpha = nominal level of ANK-81). Performance
# measures: the per-effect share as mean of the per-plan shares with the MCSE
# of a mean, the family share as a proportion with sqrt(p (1 - p) / n_sim)
# (Formelsammlung §9); n_sim = ANK-06 per scenario; seed, RNG, versions and
# runtime in a message. Every decision is also checked against an independent
# mini-reference of Lenth (1989), Gl. (1)-(5), on the same simulated data.
#
# Lenth (1989, p. 472-473) calls his method conservative. The reviewer's
# mini-reference gives per-effect rates of about 0.021 (m = 8) and 0.027
# (m = 11) and family rates of about 0.013 and 0.018 at alpha = 0.05 (200 000
# replications each), many MCSE below alpha: with a correct implementation
# this test fails. The contradiction between K-M3b-3 and K-M3b-5 is ACC-10 in
# orchestrator/handoff/M3b/CRITERIA.json and awaits an operator decision.

sim_lenth_seed <- 20261104L

# Mini-reference of Lenth (1989), Gl. (1)-(5), p. 470, with the constants of
# ANK-81 (`meth` = value$method of the anchor, read once per test).
sim_lenth_reference <- function(effects, alpha, meth) {
  a <- abs(unname(effects))
  m <- length(a)
  s0 <- meth$s0_factor * stats::median(a)
  pse <- meth$pse_factor * stats::median(a[a < meth$trim_factor * s0])
  d <- m / meth$df_divisor
  me <- stats::qt(1 - alpha / 2, d) * pse
  sme <- stats::qt((1 + (1 - alpha)^(1 / m)) / 2, d) * pse
  list(active = a > me, active_simultaneous = a > sme)
}

test_that("K-M3b-5: under H0 the share of effects above ME lies within ANK-TOL.mc_factor MCSE of alpha per effect, and the share of plans with an effect above SME within ANK-TOL.mc_factor MCSE of alpha (N = 12 with 8 and 11 factors, n_sim = ANK-06)", {
  t0 <- proc.time()[["elapsed"]]
  n_sim <- as.integer(sim_value("ANK-06", "n_sim_min"))
  k_pass <- as.numeric(sim_tol("mc_factor", "pass"))
  alpha <- as.numeric(sim_value("ANK-81", "method", "nominal_alpha"))
  meth <- sim_value("ANK-81", "method")
  report <- character()
  for (k in c(8L, 11L)) {
    design <- pb_design(k, n_runs = 12L, randomize = FALSE)
    X <- as.matrix(attr(design, "coded"))
    labels <- colnames(X)
    seed <- sim_lenth_seed + k
    reps <- sim_with_seed(seed, lapply(seq_len(n_sim), function(s) {
      y <- stats::rnorm(12L)
      r <- msa_robustness(design, y, alpha = alpha)
      i <- match(labels, r$factor)
      ref <- sim_lenth_reference(apply(X, 2, function(x) mean(y[x > 0]) - mean(y[x < 0])), alpha, meth)
      active <- as.logical(r$active[i])
      simultaneous <- as.logical(r$active_simultaneous[i])
      list(active = active, simultaneous = simultaneous,
           same = identical(active, ref$active) && identical(simultaneous, ref$active_simultaneous))
    }))
    share <- vapply(reps, function(z) mean(z$active), numeric(1))
    family <- vapply(reps, function(z) any(z$simultaneous), logical(1))
    ier <- mean(share)
    mcse_ier <- sim_mcse_mean(share)
    eer <- mean(family)
    mcse_eer <- sim_mcse_prop(eer, n_sim)
    agree <- sum(vapply(reps, function(z) z$same, logical(1)))
    expect_identical(agree, n_sim,
                     label = sprintf("%d factors: decisions equal to the mini-reference of Lenth (1989) in %d of %d plans", k, agree, n_sim))
    expect_lte(abs(ier - alpha), k_pass * mcse_ier,
               label = sprintf("%d factors: share of effects above ME %.5f (MCSE %.5f), alpha %g, distance %.1f MCSE",
                               k, ier, mcse_ier, alpha, abs(ier - alpha) / mcse_ier))
    expect_lte(abs(eer - alpha), k_pass * mcse_eer,
               label = sprintf("%d factors: share of plans with an effect above SME %.5f (MCSE %.5f), alpha %g, distance %.1f MCSE",
                               k, eer, mcse_eer, alpha, abs(eer - alpha) / mcse_eer))
    report <- c(report, sprintf("N = 12, %2d factors: ME %.5f (MCSE %.5f), SME family %.5f (MCSE %.5f), n_sim %d, %s",
                                k, ier, mcse_ier, eer, mcse_eer, n_sim, sim_session_note(seed)))
  }
  message("K-M3b-5 (tests/simulation/test-lenth-h0.R, ", sprintf("%.1f s", proc.time()[["elapsed"]] - t0), "):\n",
          paste(report, collapse = "\n"))
})
