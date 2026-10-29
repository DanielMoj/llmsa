test_that("GRR recomputes all sources and includes block and interactions", {
  v <- c(item = 4, prompt = 1 / 8, model = 1 / 4, block = 1 / 16,
          "item:prompt" = 1 / 32, "item:model" = 1 / 64, "prompt:model" = 1 / 128, Residual = 1 / 2)
  f <- structure(list(vc = data.frame(source = names(v), variance = unname(v), sd = -1,
                                     pct_contribution = -1), type = "numeric", link = "probit"), class = "msa_fit")
  g <- msa_grr(f)
  av <- sum(v[!names(v) %in% c("item", "Residual")])
  grr <- av + v[["Residual"]]
  total <- sum(v)
  tolerance <- numeric_tolerance("arithmetic", "abs_tol")
  expect_equal(g$summary[["reproducibility_pct_study_var"]], 100 * sqrt(av / total), tolerance = tolerance)
  expect_equal(g$summary[["repeatability_pct_study_var"]], 100 * sqrt(v[["Residual"]] / total), tolerance = tolerance)
  expect_equal(g$summary[["grr_pct_study_var"]], 100 * sqrt(grr / total), tolerance = tolerance)
  expect_equal(g$summary[["grr_pct_contribution"]], 100 * grr / total, tolerance = tolerance)
  expect_equal(g$summary[["icc_items"]], v[["item"]] / total, tolerance = tolerance)
  expect_equal(g$table$pct_contribution, 100 * g$table$variance / total, tolerance = tolerance)
  expect_equal(g$table$pct_study_var, 100 * sqrt(g$table$variance / total), tolerance = tolerance)
  expect_identical(msa_grr(f, threshold = c(1, 2))$verdict, "unacceptable")
  convention <- numeric_anchor("ANK-16")[["contribution"]]
  expect_identical(msa_grr(f, basis = "contribution")$threshold,
                   as.numeric(c(convention[["acceptable_below"]], convention[["unacceptable_above"]])))
})

test_that("zero total, zero gauge and zero item variances have distinct results and prints", {
  f <- suppressMessages(msa_fit(numeric_test_runs(), interactions = FALSE))
  f$vc$variance <- 0
  g <- msa_grr(f)
  expect_identical(g$verdict, "undetermined")
  expect_true(all(is.na(g$summary) & !is.nan(g$summary)))
  expect_true(all(is.na(g$table$pct_study_var) & !is.nan(g$table$pct_study_var)))
  expect_true(all(is.na(g$table$pct_contribution) & !is.nan(g$table$pct_contribution)))
  expect_true(all(g$table$variance == 0 & g$table$sd == 0))
  for (x in list(f, g)) {
    text <- paste(capture.output(print(x)), collapse = "\n")
    expect_match(text, "NA")
    expect_false(grepl("NaN|Inf", text))
  }
  f$vc$variance[f$vc$source == "item"] <- 1
  g <- msa_grr(f)
  expect_identical(g$summary[["ndc"]], Inf)
  expect_identical(g$verdict, "acceptable")
  expect_output(print(g), "ndc.*Inf")
  f$vc$variance[f$vc$source == "item"] <- 0
  f$vc$variance[f$vc$source == "Residual"] <- 1
  g <- msa_grr(f)
  expect_identical(g$summary[["ndc"]], as.numeric(numeric_anchor("ANK-16")[["ndc"]][["minimum"]]))
  expect_identical(g$verdict, "unacceptable")
})

test_that("bootstrap counts undefined GRR statistics as failed replicates", {
  f <- suppressMessages(msa_fit(numeric_test_runs(), interactions = FALSE))
  local_mocked_bindings(vc_from_model = function(...) {
    data.frame(source = c("item", "Residual"), variance = c(0, 0))
  })
  result <- msa_boot(f, nsim = 2, seed = 20261029)
  expect_identical(attr(result, "n_failed"), 2L)
  expect_true(all(is.na(attr(result, "boot"))))
  expect_false(any(is.nan(attr(result, "boot"))))
})
