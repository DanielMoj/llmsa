# K-M1a-1: for balanced plans whose ANOVA estimators are all nonnegative, the
# REML variance components of msa_fit(type = "numeric") equal the ANOVA
# estimators computed here from stats::aov mean squares with the rule of the
# expected mean squares (acc_m1a_anova_estimates(), Formelsammlung §2). The fit
# runs with the optimizer settings of ANK-TOL.reml_anova (standard
# lmerControl, passed through `...`); each component within the tolerance of
# ANK-TOL.reml_anova as a fraction of the total variance of the ANOVA
# estimators, %GRR, %Contribution and ICC relative, ndc equal. Plans: four
# simulated designs from msa_simulate() (with and without interactions, with
# and without blocks; seed 1) and lme4::Penicillin (item = sample,
# prompt = plate, interactions = FALSE). Case selection and preconditions: ACC-11.

acc_m1a_1_check <- function(runs, interactions, label) {
  d <- acc_m1a_frame(runs)
  terms <- acc_m1a_terms(d, interactions)
  ref <- acc_m1a_anova_estimates(d, terms)
  r <- acc_m1a_grr_reference(ref)
  # Preconditions of the criterion and of ANK-TOL.reml_anova; a case that
  # violates them is invalid and fails.
  expect_true(all(ref >= 0),
              label = sprintf("%s: all ANOVA estimators are nonnegative (smallest %.4g)", label, min(ref)))
  dist <- abs(r$ndc_raw - round(r$ndc_raw))
  expect_gte(dist, acc_m1a_tol("reml_anova", "ndc_min_distance_to_integer"),
             label = sprintf("%s: distance of 1.41 sd_PV/sd_GRR = %.4f to the next integer", label, r$ndc_raw))

  fit <- acc_m1a_quiet(msa_fit(runs, type = "numeric", interactions = interactions, control = lme4::lmerControl()))
  acc_m1a_expect_components(acc_m1a_components(fit), ref,
                            acc_m1a_tol("reml_anova", "component_tol_fraction_of_total_variance"),
                            r$total, label)
  g <- msa_grr(fit)
  rel <- acc_m1a_tol("reml_anova", "derived_rel_tol")
  for (k in c("grr_pct_study_var", "grr_pct_contribution", "icc_items")) {
    acc_m1a_expect_relative(acc_m1a_summary(g, k), r[[k]], rel, paste0(label, ", ", k))
  }
  ndc <- acc_m1a_summary(g, "ndc")
  expect_true(isTRUE(ndc == r$ndc), label = sprintf("%s: ndc %s equals the ANOVA ndc %s", label, format(ndc), format(r$ndc)))
  invisible(fit)
}

for (name in names(acc_m1a_designs())) {
  test_that(sprintf("K-M1a-1: REML equals ANOVA on a simulated balanced plan (%s; ankerRef: ANK-TOL.reml_anova)", name), {
    design <- acc_m1a_designs()[[name]]
    runs <- acc_m1a_simulate(design, seed = 1L)
    d <- acc_m1a_frame(runs)
    expect_identical(nlevels(d$block) > 1L, design$blocks > 1)
    acc_m1a_1_check(runs, design$interactions, name)
  })
}

test_that("K-M1a-1: REML equals ANOVA on lme4::Penicillin (item = sample, prompt = plate, interactions = FALSE; ankerRef: ANK-TOL.reml_anova)", {
  e <- new.env(parent = emptyenv())
  utils::data("Penicillin", package = "lme4", envir = e)
  p <- e$Penicillin
  expect_identical(nrow(p), 144L)
  runs <- acc_m1a_runs(item = p$sample, prompt = p$plate, model = "M1", rep = 1L, value = p$diameter)
  acc_m1a_1_check(runs, interactions = FALSE, label = "Penicillin")
})

test_that("K-M1a-1: msa_fit() passes the lmerControl settings through `...` to lme4::lmer()", {
  runs <- acc_m1a_simulate(acc_m1a_designs()[["no interactions, no block"]], seed = 1L)
  fit <- acc_m1a_quiet(msa_fit(runs, type = "numeric", interactions = FALSE,
                               control = lme4::lmerControl(optimizer = "bobyqa")))
  expect_s4_class(fit$model, "merMod")
  expect_identical(fit$model@optinfo$optimizer, "bobyqa")
  fit <- acc_m1a_quiet(msa_fit(runs, type = "numeric", interactions = FALSE, control = lme4::lmerControl()))
  expect_identical(fit$model@optinfo$optimizer, lme4::lmerControl()$optimizer[[1]])
})
