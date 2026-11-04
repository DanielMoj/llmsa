# K-M3b-5: false alarm rate of Lenth's method (class A, docs/01 §8; docs/04
# M3b). Under the null hypothesis (all effects zero, normal noise) the share of
# effects declared active at ME per effect and the share of plans with at
# least one active effect at SME do not exceed the nominal level alpha after
# Lenth 1989 (ANK-81): measure <= alpha + ANK-TOL.mc_factor (pass) x MCSE, for
# N = 12 with 8 and 11 factors, n_sim >= ANK-06. Every decision equals the
# mini-reference of Lenth (1989), Gl. (1)-(5); the test reports both rates with
# MCSE and their distance to alpha (ADR-050 Nr. 3). The help page part of
# K-M3b-5 is tested in tests/acceptance/test-m3b-5-help-page.R.
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
# Lenth (1989, p. 472-473) calls his method conservative, and the rates lie
# well below alpha (ANK-81, observations; ADR-050). The level alone would also
# be kept by code that never flags an effect; the equality of every decision
# with the mini-reference is what checks the implementation (ADR-050 Nr. 3).

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

# Rate, MCSE and the distance to alpha, absolute and in MCSE.
sim_lenth_note <- function(rate, mcse, alpha) {
  sprintf("%.5f (MCSE %.5f), distance to alpha %g: %+.5f (%+.1f MCSE)", rate, mcse, alpha, rate - alpha, (rate - alpha) / mcse)
}

test_that("K-M3b-5: under H0 the share of effects above ME and the share of plans with an effect above SME do not exceed alpha + ANK-TOL.mc_factor MCSE, and every decision equals the mini-reference of Lenth (1989) (N = 12 with 8 and 11 factors, n_sim = ANK-06)", {
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
    expect_lte(ier, alpha + k_pass * mcse_ier,
               label = sprintf("%d factors: share of effects above ME %s", k, sim_lenth_note(ier, mcse_ier, alpha)))
    expect_lte(eer, alpha + k_pass * mcse_eer,
               label = sprintf("%d factors: share of plans with an effect above SME %s", k, sim_lenth_note(eer, mcse_eer, alpha)))
    report <- c(report, sprintf("N = 12, %2d factors: per effect (ME) %s; per plan (SME) %s; n_sim %d, %s",
                                k, sim_lenth_note(ier, mcse_ier, alpha), sim_lenth_note(eer, mcse_eer, alpha), n_sim,
                                sim_session_note(seed)))
  }
  message("K-M3b-5 (tests/simulation/test-lenth-h0.R, ", sprintf("%.1f s", proc.time()[["elapsed"]] - t0), "):\n",
          paste(report, collapse = "\n"))
})
