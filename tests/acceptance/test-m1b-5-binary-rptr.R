# K-M1b-5: engine equality and literature value binary. On rptR::BeetlesMale
# (item = Population, one prompt, one model) msa_fit(type = "binary",
# link = "logit") gives an ICC_items equal to the link-scale point estimate of
# rptR::rptBinary(Colour ~ (1 | Population), grname = "Population",
# link = "logit", expect = "liability"), to performance::icc() on the same
# glmer model and to the recalculation sigma^2_Population /
# (sigma^2_Population + pi^2/3) (ANK-28), tolerance ANK-TOL.rptr.live_tol; the
# installed rptR reproduces with its default call rptR::rptBinary(Colour ~
# (1 | Population), grname = "Population", link = "logit") the point estimates
# published in its vignette (ANK-25, tolerance ANK-TOL.rptr.vignette_tol).
# Those compute the link scale with the observation-level variance
# 1/(p(1 - p)) (default expect = "meanobs") and are no reference value for
# ICC_items.
#
# Wording of docs/02 since the operator decision ADR-024 (variant A,
# 31.10.2026), which resolved the contradiction of the earlier wording
# (CRITERIA.json, open ACC-1): the comparison of ICC_items with the vignette
# value of ANK-25 is no longer part of the criterion.
# rptBinary runs without bootstrap and permutation (nboot = 0, npermut = 0):
# the point estimate does not depend on them (ACC-14).

acc_m1b_5_rpt <- function(...) {
  acc_m1a_quiet(rptR::rptBinary(Colour ~ (1 | Population), grname = "Population", data = acc_m1b_beetles(),
                                link = "logit", nboot = 0, npermut = 0, ...))
}

acc_m1b_5_point <- function(rpt, scale) as.numeric(rpt$R[scale, "Population"])

acc_m1b_5_live_tol <- function() as.numeric(acc_m1a_tol("rptr", "live_tol"))

test_that("K-M1b-5: ICC_items of msa_fit(type = \"binary\", link = \"logit\") on BeetlesMale equals the link-scale point estimate of rptR::rptBinary(..., expect = \"liability\") (ankerRef: ANK-TOL.rptr.live_tol)", {
  icc <- acc_m1b_beetles_icc()
  r_link <- acc_m1b_5_point(acc_m1b_5_rpt(expect = "liability"), "R_link")
  expect_lte(abs(icc - r_link), acc_m1b_5_live_tol(),
             label = sprintf("|ICC_items %.15g - rptBinary(expect = \"liability\") R_link %.15g|", icc, r_link))
})

test_that("K-M1b-5: ICC_items equals performance::icc() on the same glmer model (ankerRef: ANK-TOL.rptr.live_tol)", {
  icc <- acc_m1b_beetles_icc()
  tol <- acc_m1b_5_live_tol()
  m <- acc_m1a_quiet(lme4::glmer(Colour ~ 1 + (1 | Population), data = acc_m1b_beetles(), family = stats::binomial("logit")))
  ref <- as.numeric(performance::icc(m)$ICC_adjusted)
  expect_lte(abs(icc - ref), tol, label = sprintf("|ICC_items %.15g - performance::icc(glmer) %.15g|", icc, ref))
  fit <- acc_m1b_beetles_fit()
  expect_true(inherits(fit$model, "glmerMod"), label = "msa_fit keeps the glmer model")
  if (inherits(fit$model, "glmerMod")) {
    own <- as.numeric(performance::icc(fit$model)$ICC_adjusted)
    expect_lte(abs(icc - own), tol, label = sprintf("|ICC_items %.15g - performance::icc(fit$model) %.15g|", icc, own))
  }
})

test_that("K-M1b-5: ICC_items equals the recalculation sigma^2_Population / (sigma^2_Population + pi^2/3) (Formelsammlung §4; ankerRef: ANK-28, ANK-TOL.rptr.live_tol)", {
  icc <- acc_m1b_beetles_icc()
  m <- acc_m1a_quiet(lme4::glmer(Colour ~ 1 + (1 | Population), data = acc_m1b_beetles(), family = stats::binomial("logit")))
  v <- acc_m1b_glmer_components(m)[["Population"]]
  ref <- v / (v + acc_m1b_latent_residual("logit"))
  expect_lte(abs(icc - ref), acc_m1b_5_live_tol(), label = sprintf("|ICC_items %.15g - mini-reference %.15g|", icc, ref))
  comps <- acc_m1a_components(acc_m1b_beetles_fit())
  expect_true("Residual" %in% names(comps) && abs(comps[["Residual"]] - acc_m1b_latent_residual("logit")) <= acc_m1b_arith_tol(),
              label = "the residual of the binary fit is the value of ANK-28 for logit")
})

test_that("K-M1b-5: the installed rptR reproduces the published point estimates of ANK-25 with its default call (ankerRef: ANK-25, ANK-TOL.rptr.vignette_tol)", {
  rpt <- acc_m1b_5_rpt()
  tol <- as.numeric(acc_m1a_tol("rptr", "vignette_tol"))
  expect_equal(as.numeric(acc_anchor("ANK-25")$tolerance), tol, label = "tolerance of ANK-25 vs ANK-TOL.rptr.vignette_tol")
  for (k in list(c("R_link", "link_scale"), c("R_org", "original_scale"))) {
    got <- acc_m1b_5_point(rpt, k[1])
    pub <- as.numeric(acc_m1a_value("ANK-25", k[2]))
    expect_lte(abs(got - pub), tol, label = sprintf("|rptBinary %s %.15g - ANK-25 %s|", k[1], got, format(pub)))
  }
})
