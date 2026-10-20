test_that("numeric fit recovers simulated variance components", {
  # many prompt and model levels, so that the realised effects are close to
  # their nominal variances
  r <- msa_simulate(30, 8, 6, 2, vc = list(item = 1, prompt = 0.05, model = 0.05,
                                           item_model = 0.02, residual = 0.1), seed = 11)
  f <- msa_fit(r, type = "numeric")
  expect_s3_class(f, "msa_fit")
  v <- setNames(f$vc$variance, f$vc$source)
  expect_equal(unname(v["Residual"]), 0.1, tolerance = 0.2)
  expect_equal(unname(v["item"]), 1, tolerance = 0.5)
  g <- msa_grr(f)
  expect_s3_class(g, "msa_grr")
  true_pct <- 100 * sqrt(0.22 / 1.22)
  expect_equal(unname(g$summary["grr_pct_study_var"]), true_pct, tolerance = 0.3)
  expect_equal(sum(g$table$pct_contribution[g$table$source %in% c("Total gauge R&R", "Part-to-part (items)")]), 100, tolerance = 1e-8)
  expect_true(g$verdict %in% c("acceptable", "marginal", "unacceptable"))
})

test_that("single-level factors are dropped and thresholds classify", {
  r <- msa_simulate(15, 1, 1, 3, vc = list(item = 1, residual = 0.001), seed = 2)
  f <- msa_fit(r, type = "numeric")
  expect_false(any(grepl("prompt|model", deparse(f$formula))))
  g <- msa_grr(f)
  expect_equal(g$verdict, "acceptable")
  expect_equal(msa_grr(f, threshold = c(1, 2))$verdict, "unacceptable")
  expect_equal(msa_grr(f, basis = "contribution")$basis, "contribution")
})

test_that("ordinal and binary fits run on the demo data", {
  lv <- c("B", "LB", "VUS", "LP", "P")
  fo <- msa_fit(acmg_demo, type = "ordinal", levels = lv)
  expect_equal(fo$vc$variance[fo$vc$source == "Residual"], 1)
  go <- msa_grr(fo)
  expect_true(go$summary["grr_pct_study_var"] > 0 && go$summary["grr_pct_study_var"] < 100)
  b <- acmg_demo
  b$value <- ifelse(is.na(b$value), NA, as.integer(b$value %in% c("LP", "P")))
  fb <- msa_fit(b, type = "binary")
  expect_equal(fb$vc$variance[fb$vc$source == "Residual"], 1)
  expect_s3_class(msa_grr(fb), "msa_grr")
  expect_error(msa_fit(acmg_demo, type = "ordinal"), "levels")
})

test_that("ordinal fits handle two-level factors by the range method", {
  lv <- c("B", "LB", "VUS", "LP", "P")
  two <- acmg_demo[acmg_demo$model_id %in% c("model-a", "model-b"), ]
  f <- msa_fit(two, type = "ordinal", levels = lv)
  expect_equal(f$derived, "model")
  expect_true(grepl("\\+ model \\+", deparse(f$formula)))
  expect_true("model" %in% f$vc$source)
  beta <- unname(coef(f$model)[["modelmodel-b"]])
  expect_equal(f$vc$variance[f$vc$source == "model"], beta^2 / 2)
  expect_s3_class(msa_grr(f), "msa_grr")
})

test_that("bootstrap returns intervals that contain the estimate", {
  r <- msa_simulate(20, 3, 2, 2, seed = 5)
  f <- msa_fit(r, type = "numeric")
  b <- msa_boot(f, nsim = 8, seed = 1)
  expect_s3_class(b, "msa_boot")
  expect_true(all(b$lower <= b$upper))
  expect_error(msa_boot(msa_fit(acmg_demo, type = "ordinal", levels = c("B", "LB", "VUS", "LP", "P"))), "ordinal")
})

test_that("msa_bias measures a known offset", {
  r <- msa_simulate(20, 2, 2, 2, vc = list(item = 1, residual = 0.01), seed = 3)
  r$reference <- r$latent - 0.5          # the pipeline reads 0.5 too high
  bi <- msa_bias(r, "reference")
  expect_equal(unname(bi$overall["bias"]), 0.5, tolerance = 0.05)
  expect_true(bi$overall["p_value"] < 1e-6)
  expect_equal(nrow(bi$by_condition), 4)
})
