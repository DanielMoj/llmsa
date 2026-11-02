# K-M1c-8: iteration limit of the ordinal default path (ADR-041).
# msa_fit(type = "ordinal") without `control` calls ordinal::clmm with
# control = ordinal::clmm.control(iter.max = 2000, eval.max = 4000); with
# `control`, exactly the control of the call applies. The components on
# ordinal::wine stay equal to the direct call of K-M1b-1 (tolerance
# ANK-TOL.engine_ordinal, applied per component as a fraction of sigma^2_TV,
# docs/01 §2 Nr. 6), and ?msa_fit names both limits and that an own `control`
# replaces them. The limits are read from docs/02 at test time. Every call of
# ordinal::clmm made by msa_fit() is recorded; the control each fit stores is
# compared with the control stored by a direct clmm call with the argument the
# criterion requires (acc_m1c_8_required_control() in setup-m1c.R). Test form:
# CRITERIA.json M1c, open ACC-18 and ACC-19. The short runs of the three
# class-B studies are tested in test-m1c-8-check-runs.R (ACC-20).

# Controls of a call (ACC-18): one in the form of clmm.control() with only
# iter.max, a plain list with only eval.max, and an empty list.
acc_m1c_8_call_controls <- list(
  "ordinal::clmm.control(iter.max = 7)" = ordinal::clmm.control(iter.max = 7),
  "list(eval.max = 50)" = list(eval.max = 50),
  "list()" = list()
)

test_that("K-M1c-8: docs/02 names the limits of the ordinal default path as control = ordinal::clmm.control(iter.max = <n>, eval.max = <m>)", {
  l <- acc_m1c_8_limits()
  expect_named(l, c("iter.max", "eval.max"))
  expect_true(all(is.finite(l) & l >= 1 & l == round(l)),
              label = sprintf("limits of docs/02 K-M1c-8 (%s) are positive integers", paste(names(l), l, sep = " = ", collapse = ", ")))
})

for (link in c("probit", "logit")) {
  test_that(sprintf("K-M1c-8: msa_fit(type = \"ordinal\", link = \"%s\") without control calls ordinal::clmm with control = ordinal::clmm.control(iter.max, eval.max of docs/02)", link), {
    rec <- acc_m1c_8_wine_fit(link)
    expect_s3_class(rec$value, "msa_fit")
    expected <- acc_m1c_8_control_form(acc_m1c_8_direct_wine(link, acc_m1c_8_required_control(list()))$control)
    acc_m1c_8_expect_controls(rec, expected, sprintf("wine, %s, without control", link))
  })
}

test_that("K-M1c-8: without control, but with another engine argument (Hess = TRUE), msa_fit() calls ordinal::clmm with the limits of docs/02", {
  args <- list(Hess = TRUE)
  rec <- acc_m1c_8_wine_fit("probit", args)
  expect_s3_class(rec$value, "msa_fit")
  expected <- acc_m1c_8_control_form(acc_m1c_8_direct_wine("probit", acc_m1c_8_required_control(args))$control)
  acc_m1c_8_expect_controls(rec, expected, "wine, probit, Hess = TRUE without control")
})

test_that("K-M1c-8: without control, the ordinal fit with two models (fixed effect, derived component) calls ordinal::clmm with the limits of docs/02", {
  runs <- acc_m1b_ordinal_runs(20261108L, items = 12L, models = 2L)
  rec <- acc_m1c_8_record_clmm(msa_fit(runs, type = "ordinal", levels = acc_m1b_ordinal_levels(), link = "probit"))
  expect_s3_class(rec$value, "msa_fit")
  d <- acc_m1b_frame(runs, "ordinal", acc_m1b_ordinal_levels())
  direct <- ordinal::clmm(y ~ 1 + model + (1 | item) + (1 | prompt), data = d, link = "probit",
                          control = acc_m1c_8_required_control(list()))
  acc_m1c_8_expect_controls(rec, acc_m1c_8_control_form(direct$control), "two models, probit, without control")
})

for (name in names(acc_m1c_8_call_controls)) {
  test_that(sprintf("K-M1c-8: with control = %s, msa_fit() passes exactly this control to ordinal::clmm, and the components equal the direct call with it (ankerRef: ANK-TOL.engine_ordinal)", name), {
    args <- list(control = acc_m1c_8_call_controls[[name]])
    rec <- acc_m1c_8_wine_fit("probit", args)
    expect_s3_class(rec$value, "msa_fit")
    direct <- acc_m1c_8_direct_wine("probit", acc_m1c_8_required_control(args))
    acc_m1c_8_expect_controls(rec, acc_m1c_8_control_form(direct$control), sprintf("wine, probit, control = %s", name))
    if (!inherits(rec$value, "msa_fit")) return(invisible())
    ref <- acc_m1c_8_wine_reference(direct, "probit")
    acc_m1a_expect_components(acc_m1a_components(rec$value), ref, acc_m1b_engine_tol(), sum(ref),
                              sprintf("wine, probit, control = %s", name))
  })
}

for (link in c("logit", "probit")) {
  test_that(sprintf("K-M1c-8: the components of msa_fit(type = \"ordinal\", link = \"%s\") on wine stay equal to the direct call of K-M1b-1 (ankerRef: ANK-TOL.engine_ordinal)", link), {
    fit <- acc_m1b_wine_fit(link)
    expect_s3_class(fit, "msa_fit")
    if (!inherits(fit, "msa_fit")) return(invisible())
    ref <- acc_m1c_8_wine_reference(acc_m1c_8_direct_wine(link), link)
    acc_m1a_expect_components(acc_m1a_components(fit), ref, acc_m1b_engine_tol(), sum(ref),
                              sprintf("wine, link %s, against ordinal::clmm(rating ~ 1 + (1 | bottle) + (1 | judge))", link))
  })
}

test_that("K-M1c-8: ?msa_fit names both limits and that an own control replaces them", {
  txt <- acc_m1c_8_rd_plain("msa_fit")
  l <- acc_m1c_8_limits()
  for (k in names(l)) {
    expect_true(grepl(acc_m1c_8_limit_pattern(k, l[[k]]), txt, perl = TRUE),
                label = sprintf("man/msa_fit.Rd names %s = %s", k, format(l[[k]], scientific = FALSE)))
  }
  sentences <- acc_m1c_8_sentences(txt)
  says <- grepl("\\bcontrol\\b", sentences, ignore.case = TRUE, perl = TRUE) &
    grepl(acc_m1c_8_word_replace, sentences, ignore.case = TRUE) &
    grepl("limit|iter\\.max|eval\\.max", sentences, ignore.case = TRUE)
  expect_true(any(says),
              label = "a sentence of man/msa_fit.Rd says that an own control replaces the limits (control; replace, override, supersede, instead or precedence; limit, iter.max or eval.max)")
})
