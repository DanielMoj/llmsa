test_that("latent GRR ratios use all components and preserve each derived source", {
  for (link in c("probit", "logit")) {
    fit <- latent_test_capture(msa_fit(latent_test_runs(prompts = 2L, models = 2L, blocks = 2L),
      type = "ordinal", link = link))$value
    g <- msa_grr(fit)
    v <- stats::setNames(fit$vc$variance, fit$vc$source)
    gauge <- sum(v[names(v) != "item"])
    expect_equal(unname(g$summary["icc_items"]), v[["item"]] / sum(v),
                 tolerance = numeric_tolerance("arithmetic", "abs_tol"))
    expect_equal(unname(g$summary["grr_pct_study_var"]), 100 * sqrt(gauge / sum(v)),
                 tolerance = numeric_tolerance("arithmetic", "abs_tol"))
    expect_identical(v[["Residual"]], if (link == "probit") 1 else pi^2 / 3)
    expect_identical(g$derived, attr(fit$vc, "derived"))
    expect_identical(g$derived, c("prompt", "model", "block"))
    for (object in list(fit, g)) {
      printed <- utils::capture.output(print(object))
      for (source in g$derived) {
        expect_equal(sum(grepl(paste0(source, ": range method, see ?msa_fit"), printed, fixed = TRUE)), 1L)
      }
    }
    # The vc attribute is the contract, even for an externally constructed fit.
    fit$derived <- character()
    expect_identical(msa_grr(fit)$derived, c("prompt", "model", "block"))
  }
  numeric <- msa_fit(numeric_test_runs())
  expect_null(msa_grr(numeric)$derived)
  expect_false(any(grepl("range method", utils::capture.output(print(msa_grr(numeric))), fixed = TRUE)))
})
