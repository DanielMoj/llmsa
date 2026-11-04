# Synthetic result tables test decisions independently of the full studies.
m1d_findings_helpers <- function() {
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  e <- new.env(parent = globalenv())
  sys.source(system.file("validation", "m1d", "findings.R", package = "llmsa", mustWork = TRUE), envir = e)
  e
}

test_that("recovery findings use both anchored bounds and keep component identities", {
  e <- m1d_findings_helpers(); anchors <- e$m1d_resources()
  rule <- anchors[["ANK-TOL"]]$value$bias_report
  step <- rule$rel_bias
  results <- data.frame(scenario = "synthetic", estimand = c("item", "prompt", "model", "item:model", "Residual", "icc_items"),
    measure = "rel_bias", value = c(step, -2 * step, 2 * step, 2 * step, 1, 1),
    mcse = c(0, 0, 3 * step, 0, 0, 0), stringsAsFactors = FALSE)
  found <- e$m1d_findings("ordinal_recovery", results, anchors)
  expect_identical(found$estimand, c("prompt", "item:model"))
  expect_identical(found$direction, c("underestimation", "overestimation"))
  expect_equal(found$value, c(-2 * step, 2 * step))
  adjusted <- results; adjusted$value[3L] <- rule$mcse_multiple * adjusted$mcse[3L]
  expect_false("model" %in% e$m1d_findings("binary_recovery", adjusted, anchors)$estimand)
  adjusted$value[3L] <- 2 * adjusted$value[3L]
  expect_true("model" %in% e$m1d_findings("binary_recovery", adjusted, anchors)$estimand)
  bad <- results; bad$mcse[1L] <- -step
  expect_error(e$m1d_findings("ordinal_recovery", bad, anchors), "Invalid M1d findings")
  expect_error(e$m1d_findings("ordinal_recovery", rbind(results, results[1L, ]), anchors), "Invalid M1d findings")
})

test_that("zero MCSE cannot hide coverage findings and equality is below the report trigger", {
  e <- m1d_findings_helpers(); anchors <- e$m1d_resources()
  # A synthetic nominal level makes the equality boundary exactly representable.
  nominal <- 1 / 2; multiple <- anchors[["ANK-TOL"]]$value$mc_factor$report
  results <- data.frame(scenario = paste0("synthetic-", 1:4), estimand = "ndc", measure = "coverage",
    value = c(1, 0, nominal, nominal + multiple / 16), mcse = c(0, 0, 0, 1 / 16))
  found <- e$m1d_findings("boot_coverage", results, anchors, nominal = nominal)
  expect_identical(found$scenario, c("synthetic-1", "synthetic-2"))
  expect_identical(found$direction, c("overcoverage", "undercoverage"))
  expect_error(e$m1d_findings("boot_coverage", results, anchors, nominal = NA_real_), "Invalid nominal")
  expect_error(e$m1d_findings("unknown", results, anchors), "Unknown M1d study")
})

test_that("two-level bias is always reported without inventing a resolved direction", {
  e <- m1d_findings_helpers(); anchors <- e$m1d_resources()
  multiple <- anchors[["ANK-TOL"]]$value$mc_factor$report
  results <- data.frame(scenario = paste0("synthetic-", 1:3), estimand = "model", measure = "bias",
    value = c(0, 2 * multiple, -2 * multiple), mcse = 1)
  found <- e$m1d_findings("two_level", results, anchors)
  expect_equal(nrow(found), 3L)
  expect_identical(found$direction, c("no direction resolved at the report threshold", "overestimation", "underestimation"))
  results$estimand[1L] <- "item"
  expect_error(e$m1d_findings("two_level", results, anchors), "Missing two-level")
})

test_that("sensitivity MCSE follows the independent finite-sample calculation", {
  e <- m1d_findings_helpers()
  tol <- numeric_tolerance("arithmetic", "abs_tol")
  # Hand calculation: sum of squared deviations of 1,2,3,4 is 5, df is 3.
  got <- e$m1d_performance(c(1, 2, 3, 4, NA_real_, Inf), truth = 2)
  expect_identical(got$n, 4L)
  expect_equal(got$bias, 1 / 2, tolerance = tol)
  expect_equal(got$bias_mcse, sqrt(5 / 12), tolerance = tol)
  expect_equal(got$rel_bias, 1 / 4, tolerance = tol)
  expect_equal(got$rel_bias_mcse, sqrt(5 / 48), tolerance = tol)
  expect_equal(got$empse, sqrt(5 / 3), tolerance = tol)
  expect_equal(got$empse_mcse, sqrt(5 / 18), tolerance = tol)
  scaled <- e$m1d_performance(7 * 1:4, truth = 14)
  expect_equal(scaled$rel_bias, got$rel_bias, tolerance = tol)
  expect_equal(scaled$rel_bias_mcse, got$rel_bias_mcse, tolerance = tol)
  expect_equal(scaled$empse, 7 * got$empse, tolerance = tol)
  expect_true(is.na(e$m1d_performance(3, 2)$bias_mcse))
  expect_identical(e$m1d_performance(numeric(), 2)$status, "fewer than two finite estimates")
  expect_error(e$m1d_performance(1:3, 0), "nonzero truth")
})

test_that("convergence sensitivity uses its own rows and retains finite singular fits", {
  e <- m1d_findings_helpers()
  tol <- numeric_tolerance("arithmetic", "abs_tol")
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path), add = TRUE)
  d <- data.frame(scenario = "synthetic", rep = 1:5, estimand = "item", estimate = c(1, 2, 3, 4, Inf),
    true = 2, converged = c(TRUE, FALSE, TRUE, TRUE, NA), singular = c(TRUE, FALSE, TRUE, FALSE, NA))
  other <- d; other$estimand <- "prompt"; other$estimate <- 2 * other$estimate; other$true <- 4
  d <- rbind(d, other)
  utils::write.csv(d, path, row.names = FALSE)
  result <- e$m1d_convergence_sensitivity(path)
  expect_true(result$available)
  item <- result$tables[result$tables$estimand == "item", ]
  expect_identical(item$n, c(4L, 3L))
  expect_equal(item$bias, c(1 / 2, 2 / 3), tolerance = tol)
  expect_equal(item$empse, c(sqrt(5 / 3), sqrt(7 / 3)), tolerance = tol)
  expect_equal(item$bias_mcse, c(sqrt(5 / 12), sqrt(7 / 9)), tolerance = tol)
  expect_equal(result$diagnostics$n, 5)
  expect_equal(result$diagnostics$nonconverged, 1)
  expect_equal(result$diagnostics$convergence_unknown, 1)
  expect_equal(result$diagnostics$singular_share, 2 / 5, tolerance = tol)
  expect_equal(result$diagnostics$singular_mcse, sqrt(6 / 125), tolerance = tol)
  utils::write.csv(d[nrow(d):1, ], path, row.names = FALSE)
  expect_equal(e$m1d_convergence_sensitivity(path)$tables, result$tables, tolerance = tol)
  utils::write.csv(rbind(d, d[1L, ]), path, row.names = FALSE)
  expect_error(e$m1d_convergence_sensitivity(path), "Invalid ordinal")
  unlink(path)
  missing <- e$m1d_convergence_sensitivity(path)
  expect_false(missing$available)
  expect_match(missing$reason, "replicates.csv is missing", fixed = TRUE)
})

test_that("installed anchors retain provenance and display keeps small MCSE values", {
  e <- m1d_findings_helpers()
  resources <- system.file("validation", "m1d", package = "llmsa", mustWork = TRUE)
  work <- tempfile("synthetic-m1d-resources-"); dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  stopifnot(all(file.copy(file.path(resources, c("SOURCES.json", "anchors")), work, recursive = TRUE)))
  expect_setequal(names(e$m1d_resources(work)), e$m1d_resource_ids)
  path <- file.path(work, "anchors", "ANK-47.json")
  cat("\n", file = path, append = TRUE)
  expect_error(e$m1d_resources(work), "SHA-256/provenance mismatch", fixed = TRUE)
  unlink(path)
  expect_error(e$m1d_resources(work), "directory differs")
  tiny <- data.frame(value = c(1 / 10^8, -2 / 10^9), mcse = c(3 / 10^10, 0))
  shown <- e$m1d_display(tiny)
  expect_equal(as.numeric(shown$value), tiny$value)
  expect_equal(as.numeric(shown$mcse), tiny$mcse)
  # Numeric leaves are independent of prose, including lower-bound quantities.
  a <- list(value = list(n = 7L, variants_in_alpha = 5L, ignored = "prose",
    group = list(alpha = 1 / 2, min_pct = 60)))
  table <- e$m1d_literature_table(a)
  expect_equal(table$value, c(7, 5, 1 / 2, 60))
  expect_identical(table$unit, c("count", "count", "dimensionless alpha", "percent, minimum rule"))
})
