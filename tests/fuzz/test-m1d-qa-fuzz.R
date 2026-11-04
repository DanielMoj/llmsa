# QA / Red Team fuzz & boundary tests for M1d (fixed seed: 20261104)
testthat::set_max_fails(Inf)

qa_m1d_fuzz_env <- function(rel_path) {
  e <- new.env(parent = globalenv())
  sys.source(system.file(rel_path, package = "llmsa", mustWork = TRUE), envir = e)
  e
}

test_that("QA-M1d-FUZZ-1: prepare.R parser, variant sampler RNG isolation, CSV/gzip writer and staged publisher handle boundary and adversarial inputs (seed = 20261104)", {
  set.seed(20261104L)
  testthat::skip_if_not_installed("jsonlite")
  testthat::skip_if_not_installed("digest")

  p_env <- qa_m1d_fuzz_env(file.path("validation", "m1d", "prepare.R"))

  # 1. Answer parser boundary & adversarial cases
  opts_mc <- list(c("(A)", "(B)", "(C)", "(D)"))
  cases_mc <- list(
    list(resp = "The answer is (b); yes, definitely (B).", ans = "(B)", reason = "parsed"),
    list(resp = "Either '(A)' or (B) could work.", ans = NA_character_, reason = "ambiguous"),
    list(resp = "I think A is right, or ( A ) or (E).", ans = NA_character_, reason = "no_label"),
    list(resp = "   	
  ", ans = NA_character_, reason = "empty"),
    list(resp = NA_character_, ans = NA_character_, reason = "empty")
  )
  for (tc in cases_mc) {
    res <- p_env$m1d_parse_answers(tc$resp, opts_mc)
    expect_identical(res$answer, tc$ans)
    expect_identical(res$reason, tc$reason)
  }

  opts_nav <- list(c("Yes", "No"))
  cases_nav <- list(
    list(resp = "yesterday I noted nothing, so NO, definitely no!", ans = "No", reason = "parsed"),
    list(resp = "yesterday and notable only", ans = NA_character_, reason = "no_label"),
    list(resp = "Yes or No?", ans = NA_character_, reason = "ambiguous"),
    list(resp = "yes_no and no1 and 1yes, but YES.", ans = "Yes", reason = "parsed")
  )
  for (tc in cases_nav) {
    res <- p_env$m1d_parse_answers(tc$resp, opts_nav)
    expect_identical(res$answer, tc$ans)
    expect_identical(res$reason, tc$reason)
  }

  # 2. m1d_draw_variants RNG isolation and permutation invariance
  counts <- data.frame(
    variation_id = c(500L, 10L, 42L, 7L, 99999L, 3L, 18L),
    submitters = c(4L, 3L, 6L, 5L, 4L, 10L, 2L)
  )
  spec <- list(min_distinct_submitters = 4L, n_variants = 3L, seed = 20261025L)

  set.seed(20261104L)
  seed_before <- .Random.seed
  rng_before <- RNGkind()
  draw_a <- p_env$m1d_draw_variants(counts, spec)
  expect_identical(.Random.seed, seed_before)
  expect_identical(RNGkind(), rng_before)

  perm <- sample.int(nrow(counts))
  seed_before2 <- .Random.seed
  draw_b <- p_env$m1d_draw_variants(counts[perm, , drop = FALSE], spec)
  expect_identical(draw_a, draw_b)
  expect_identical(.Random.seed, seed_before2)

  # Single eligible variant edge case (sample.int vs sample pitfall when length(eligible) == 1)
  single_counts <- data.frame(variation_id = c(999L, 1000L), submitters = c(5L, 1L))
  single_spec <- list(min_distinct_submitters = 4L, n_variants = 1L, seed = 20261025L)
  expect_identical(p_env$m1d_draw_variants(single_counts, single_spec), 999L)

  # 3. Deterministic UTF-8 CSV/gzip serialization with quotes, commas, multibyte characters and NAs
  df_utf8 <- data.frame(
    id = c(1L, NA_integer_, 3L),
    label = c('Lab "Alpha", Inc.', "Ümläut & Co — 東京", NA_character_),
    flag = c(TRUE, FALSE, NA),
    stringsAsFactors = FALSE
  )
  gz1 <- tempfile(fileext = ".csv.gz")
  gz2 <- tempfile(fileext = ".csv.gz")
  on.exit(unlink(c(gz1, gz2)), add = TRUE)
  p_env$m1d_write_csv(df_utf8, gz1)
  p_env$m1d_write_csv(df_utf8, gz2)
  expect_identical(p_env$m1d_sha256(gz1), p_env$m1d_sha256(gz2))

  con <- gzfile(gz1, "rt", encoding = "UTF-8")
  on.exit(close(con), add = TRUE)
  roundtrip <- utils::read.csv(con, stringsAsFactors = FALSE, na.strings = "", encoding = "UTF-8")
  expect_identical(roundtrip$id, df_utf8$id)
  expect_identical(roundtrip$label, df_utf8$label)
  expect_identical(roundtrip$flag, df_utf8$flag)

  expect_error(
    p_env$m1d_write_csv(data.frame(x = 1.5), gz1),
    "CSV column must be character, integer or logical"
  )
})

test_that("QA-M1d-FUZZ-2: findings.R boundary conditions, zero-MCSE thresholds, convergence sensitivity and manifest tampering checks (seed = 20261104)", {
  set.seed(20261104L)
  testthat::skip_if_not_installed("jsonlite")
  testthat::skip_if_not_installed("digest")

  f_env <- qa_m1d_fuzz_env(file.path("validation", "m1d", "findings.R"))
  anchors <- f_env$m1d_resources()
  tol <- anchors[["ANK-TOL"]]$value

  # 1. Exact threshold boundary vs strictly above threshold in m1d_findings
  rb_thresh <- tol$bias_report$rel_bias
  mc_mult <- tol$bias_report$mcse_multiple
  mc_rep <- tol$mc_factor$report

  ord_boundary <- data.frame(
    scenario = c("S-ord-1", "S-ord-1", "S-ord-1", "S-ord-1"),
    estimand = c("item", "prompt", "model", "icc_items"),
    measure = rep("rel_bias", 4L),
    value = c(-rb_thresh, -(rb_thresh + 1e-6), rb_thresh + 0.1, -0.9),
    mcse = c(0.001, 0.001, (rb_thresh + 0.1) / mc_mult, 0.001),
    stringsAsFactors = FALSE
  )
  f_ord <- f_env$m1d_findings("ordinal_recovery", ord_boundary, anchors)
  # Only prompt exceeds BOTH rel_bias and mcse_multiple * mcse strictly; icc_items is excluded as derived ratio
  expect_identical(f_ord$estimand, "prompt")
  expect_identical(f_ord$direction, "underestimation")

  # 2. boot_coverage with mcse == 0 and exact nominal vs off-nominal coverage
  nom_bin <- 0.75
  mcse_bin <- 0.125
  boot_boundary <- data.frame(
    scenario = c("S-boot-1", "S-boot-1", "S-boot-1", "S-boot-1"),
    estimand = c("ndc", "grr_pct_study_var", "icc_items", "item"),
    measure = rep("coverage", 4L),
    value = c(1.0, nom_bin, nom_bin - mc_rep * mcse_bin, 0.25),
    mcse = c(0.0, 0.0, mcse_bin, 0.0),
    stringsAsFactors = FALSE
  )
  f_boot <- f_env$m1d_findings("boot_coverage", boot_boundary, anchors, nominal = nom_bin)
  # ndc has mcse == 0 and |1.0 - 0.75| > 0 -> overcoverage;
  # grr_pct_study_var has |0.75 - 0.75| == 0 -> not > 0;
  # icc_items has exact equality at threshold -> not > threshold;
  # item is not one of the 4 interval estimands
  expect_identical(f_boot$estimand, "ndc")
  expect_identical(f_boot$direction, "overcoverage")

  # 3. Invalid inputs to m1d_findings and m1d_performance
  expect_error(f_env$m1d_findings("unknown_study", ord_boundary, anchors), "Unknown M1d study")
  expect_error(f_env$m1d_findings("boot_coverage", boot_boundary, anchors, nominal = 1.0), "Invalid nominal coverage")
  expect_error(f_env$m1d_findings("two_level", ord_boundary, anchors), "Missing two-level model bias")
  expect_error(f_env$m1d_performance(c(1, 2), 0), "finite nonzero truth")
  expect_error(f_env$m1d_performance(c(1, 2), NA_real_), "finite nonzero truth")

  p0 <- f_env$m1d_performance(c(NA_real_, Inf, -Inf, NaN), 0.5)
  expect_identical(p0$n, 0L)
  expect_identical(p0$status, "fewer than two finite estimates")
  expect_true(is.na(p0$bias) && is.na(p0$empse) && is.na(p0$bias_mcse))

  p1 <- f_env$m1d_performance(c(0.75, NA_real_), 0.5)
  expect_identical(p1$n, 1L)
  expect_identical(p1$status, "fewer than two finite estimates")
  expect_equal(p1$bias, 0.25)
  expect_true(is.na(p1$empse) && is.na(p1$bias_mcse))

  # 4. m1d_convergence_sensitivity missing file fallback and corrupted replicate detection
  miss <- f_env$m1d_convergence_sensitivity(tempfile(fileext = ".csv"))
  expect_false(miss$available)
  expect_match(miss$reason, "not available: ordinal_recovery_replicates.csv is missing", fixed = TRUE)

  bad_csv <- tempfile(fileext = ".csv")
  on.exit(unlink(bad_csv), add = TRUE)
  bad_rep <- data.frame(
    scenario = c("S-ord-1", "S-ord-1"),
    rep = c(1L, 1L),
    estimand = c("item", "model"),
    estimate = c(0.9, 0.2),
    true = c(1.0, 0.25),
    converged = c(TRUE, FALSE),
    singular = c(FALSE, FALSE),
    stringsAsFactors = FALSE
  )
  utils::write.csv(bad_rep, bad_csv, row.names = FALSE)
  expect_error(f_env$m1d_convergence_sensitivity(bad_csv), "Conflicting replicate diagnostics")

  # 5. m1d_resources manifest tampering detection
  stage_res <- tempfile("qa-m1d-res-")
  dir.create(stage_res, recursive = TRUE)
  on.exit(unlink(stage_res, recursive = TRUE), add = TRUE)
  src_res <- system.file("validation", "m1d", package = "llmsa", mustWork = TRUE)
  expect_true(file.copy(file.path(src_res, "SOURCES.json"), stage_res))
  expect_true(file.copy(file.path(src_res, "anchors"), stage_res, recursive = TRUE))
  expect_type(f_env$m1d_resources(stage_res), "list")

  writeLines("{}", file.path(stage_res, "anchors", "ANK-40.json"))
  expect_error(f_env$m1d_resources(stage_res), "SHA-256/provenance mismatch: ANK-40")
})
