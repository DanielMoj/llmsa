# K-M1b-1: engine equality ordinal. On ordinal::wine (item = bottle, prompt =
# judge, one replicate) msa_fit(type = "ordinal", link = "logit") and
# link = "probit" give the same variance components as a direct call
# ordinal::clmm(rating ~ 1 + (1 | bottle) + (1 | judge), link = ...)
# (tolerance ANK-TOL.engine_ordinal, applied per component as a fraction of
# the total variance of the comparison calculation, docs/01 §2 Nr. 6; ACC-9),
# and the installed ordinal version reproduces the component sigma^2_judge of
# clmm2(rating ~ temp + contact, random = judge) published in the vignette
# "clmm2" (ANK-21). The residual of the latent scale is the value of ANK-28 for
# the link (docs/01 §5); the gauge R&R statistics on the latent scale
# (Formelsammlung §4) are checked against the mini-reference of Formelsammlung
# §3 built from the direct clmm components.

acc_m1b_1_fit <- function(link) acc_m1b_wine_fit(link)

# Components of the direct clmm call of the criterion in the roles of llmsa,
# with the latent residual of ANK-28.
acc_m1b_1_reference <- function(link) {
  direct <- ordinal::clmm(rating ~ 1 + (1 | bottle) + (1 | judge), data = acc_m1b_wine(), link = link)
  v <- acc_m1b_clmm_components(direct)
  c(item = v[["bottle"]], prompt = v[["judge"]], Residual = acc_m1b_latent_residual(link))
}

for (link in c("logit", "probit")) {
  test_that(sprintf("K-M1b-1: msa_fit(type = \"ordinal\", link = \"%s\") on wine gives the components of a direct ordinal::clmm (ankerRef: ANK-TOL.engine_ordinal)", link), {
    fit <- acc_m1b_1_fit(link)
    expect_s3_class(fit, "msa_fit")
    ref <- acc_m1b_1_reference(link)
    acc_m1a_expect_components(acc_m1a_components(fit), ref, acc_m1b_engine_tol(), sum(ref),
                              sprintf("wine, link %s", link))
  })

  test_that(sprintf("K-M1b-1: the residual of the ordinal fit (%s) is the latent-scale value of ANK-28 (ankerRef: ANK-28)", link), {
    v <- acc_m1a_components(acc_m1b_1_fit(link))
    expect_true("Residual" %in% names(v))
    if (!"Residual" %in% names(v)) return(invisible())
    expect_lte(abs(v[["Residual"]] - acc_m1b_latent_residual(link)), acc_m1b_arith_tol(),
               label = sprintf("|Residual %.17g - ANK-28 %s|", v[["Residual"]], link))
  })

  test_that(sprintf("K-M1b-1: msa_grr() of the ordinal wine fit (%s) follows Formelsammlung §3 on the latent scale", link), {
    g <- msa_grr(acc_m1b_1_fit(link))
    r <- acc_m1a_grr_reference(acc_m1b_1_reference(link))
    # precondition of the test data: ndc away from a rounding step (ANK-TOL.reml_anova)
    expect_gte(abs(r$ndc_raw - round(r$ndc_raw)), acc_m1a_tol("reml_anova", "ndc_min_distance_to_integer"))
    tol <- acc_m1b_engine_tol()
    for (s in c("grr_pct_study_var", "grr_pct_contribution", "icc_items")) {
      acc_m1a_expect_relative(acc_m1a_summary(g, s), r[[s]], tol, sprintf("wine %s, %s", link, s))
    }
    expect_identical(as.numeric(acc_m1a_summary(g, "ndc")), as.numeric(r$ndc))
  })
}

test_that("K-M1b-1: the installed ordinal reproduces sigma^2_judge of the vignette \"clmm2\", Laplace and nAGQ = 10 (ankerRef: ANK-21)", {
  a <- acc_anchor("ANK-21")
  # clmm2 evaluates an unqualified call to clm2 in its calling frame; the calls
  # of the vignette are evaluated in an environment that holds `wine` and
  # inherits from the ordinal namespace (no package is attached).
  e <- new.env(parent = asNamespace("ordinal"))
  e$wine <- acc_m1b_wine()
  fits <- list(
    laplace = eval(quote(clmm2(rating ~ temp + contact, random = judge, data = wine)), e),
    nagq10 = eval(quote(clmm2(rating ~ temp + contact, random = judge, data = wine, Hess = TRUE, nAGQ = 10)), e)
  )
  for (key in names(fits)) {
    sd <- as.numeric(fits[[key]]$stDev)
    pub <- a$value[[key]]
    tol <- a$tolerance[[key]]
    expect_lte(abs(sd^2 - as.numeric(pub$variance)), as.numeric(tol$variance),
               label = sprintf("ANK-21 %s: |variance %.10g - published %s|", key, sd^2, format(pub$variance)))
    expect_lte(abs(sd - as.numeric(pub$sd)), as.numeric(tol$sd),
               label = sprintf("ANK-21 %s: |sd %.10g - published %s|", key, sd, format(pub$sd)))
  }
})
