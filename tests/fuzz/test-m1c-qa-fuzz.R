# QA / Red Team fuzz & boundary tests for M1c (fixed seed: 20261103)
testthat::set_max_fails(Inf)

test_that("QA-M1c-FUZZ-1: msa_boot handles extreme failure/singularity combinations and rejects unsupported models (seed = 20261103)", {
  set.seed(20261103L)
  fit_num <- suppressMessages(msa_fit(ic50_demo, type = "numeric"))
  stats_names <- names(msa_grr(fit_num)$summary)

  expect_error(msa_boot(list(model = fit_num$model)), "must come from msa_fit")
  fit_ord <- suppressWarnings(suppressMessages(
    msa_fit(acmg_demo, type = "ordinal", levels = c("B", "LB", "VUS", "LP", "P"), link = "probit")
  ))
  expect_error(msa_boot(fit_ord), "numeric and binary fits")

  # All replicates fail -> n_failed = nsim, n_singular = 0, lower/upper = NA
  mat_all_fail <- matrix(NA_real_, nrow = 5L, ncol = length(stats_names) + 1L)
  mat_all_fail[, length(stats_names) + 1L] <- 1
  b_all_fail <- testthat::with_mocked_bindings(
    bootMer = function(x, FUN, nsim, seed = NULL, type = "parametric", ...) {
      list(t = mat_all_fail[seq_len(nsim), , drop = FALSE])
    },
    .package = "lme4",
    msa_boot(fit_num, nsim = 5L, level = 0.95, seed = 20261103L)
  )
  expect_identical(attr(b_all_fail, "n_failed"), 5L)
  expect_identical(attr(b_all_fail, "n_singular"), 0L)
  expect_true(all(is.na(b_all_fail$lower) & is.na(b_all_fail$upper)))
  lines_fail <- capture.output(print(b_all_fail))
  expect_true(any(grepl("5 failed or non-finite replicates", lines_fail, fixed = TRUE)))
  expect_true(any(grepl("0 singular replicates retained", lines_fail, fixed = TRUE)))

  # Mixed NA, NaN, Inf, -Inf in single cells vs all-finite singular/regular rows
  base_row <- unname(msa_grr(fit_num)$summary)
  mat_mixed <- rbind(
    c(base_row * 0.9, 1),
    c(base_row * 1.0, 0),
    c(base_row * 1.1, 1),
    c(NA_real_, base_row[-1L], 1),
    c(base_row[1L], NaN, base_row[-c(1L, 2L)], 1),
    c(base_row[1:2], Inf, base_row[4:6], 0),
    c(base_row[1:3], -Inf, base_row[5:6], 1)
  )
  b_mixed <- testthat::with_mocked_bindings(
    bootMer = function(x, FUN, nsim, seed = NULL, type = "parametric", ...) {
      list(t = mat_mixed)
    },
    .package = "lme4",
    msa_boot(fit_num, nsim = nrow(mat_mixed), level = 0.90, seed = 20261103L)
  )
  expect_identical(attr(b_mixed, "n_failed"), 4L)
  expect_identical(attr(b_mixed, "n_singular"), 2L)
  expect_true(all(is.finite(b_mixed$lower) & is.finite(b_mixed$upper)))

  # Legacy object without n_singular attribute prints fallback message
  legacy <- b_mixed
  attr(legacy, "n_singular") <- NULL
  lines_legacy <- capture.output(print(legacy))
  expect_true(any(grepl("singular replicates: not recorded for this object", lines_legacy, fixed = TRUE)))
})

test_that("QA-M1c-FUZZ-2: boot_coverage CLI, seed boundaries, summarize and merge reject malformed inputs (seed = 20261103)", {
  testthat::skip_if_not_installed("jsonlite")
  testthat::skip_if_not_installed("digest")

  set.seed(20261103L)
  e <- new.env(parent = globalenv())
  sys.source(system.file("validation", "sim", "boot_coverage_helpers.R", package = "llmsa", mustWork = TRUE), envir = e)
  params <- e$boot_parameters()
  sc <- e$boot_scenarios(params)

  # Exact integer seed boundary for S-boot-7 (index 7):
  # data_seed = 20261102 + 2*(7-1) + 14*(r-1); boot_seed = data_seed + 1 <= .Machine$integer.max
  s7 <- sc[["S-boot-7"]]
  max_r <- floor((.Machine$integer.max - 1 - (20261102 + 2 * 6)) / 14) + 1
  seeds_ok <- e$boot_seeds(s7, max_r)
  expect_lte(seeds_ok$boot, .Machine$integer.max)
  expect_error(e$boot_seeds(s7, max_r + 1), "seed is out of range")
  expect_error(e$boot_seeds(s7, -1), "seed is out of range")
  expect_error(e$boot_seeds(s7, 1.5), "seed is out of range")

  # Summarize boundary rejections: reversed interval, negative/exceeding bootstrap shares, inconsistent settings
  check_reps <- e$sim_read_csv(system.file("validation", "sim", "boot_coverage_check_replicates.csv", package = "llmsa", mustWork = TRUE))
  reps_s1 <- check_reps[check_reps$scenario == "S-boot-1" & check_reps$rep %in% 1:3, , drop = FALSE]

  bad_rev <- reps_s1
  idx <- bad_rev$rep == 1L & bad_rev$estimand == "ndc"
  tmp_l <- bad_rev$lower[idx]
  bad_rev$lower[idx] <- bad_rev$upper[idx] + 1
  bad_rev$upper[idx] <- tmp_l
  expect_error(e$boot_summarize(bad_rev, sc["S-boot-1"], 3L), "Reversed coverage interval")

  bad_share <- reps_s1
  bad_share$n_singular[bad_share$rep == 1L] <- bad_share$boot_nsim[bad_share$rep == 1L] + 1
  expect_error(e$boot_summarize(bad_share, sc["S-boot-1"], 3L), "Invalid bootstrap share")

  bad_inconsistent <- reps_s1
  bad_inconsistent$boot_nsim[bad_inconsistent$rep == 1L & bad_inconsistent$estimand == "item"] <- 100
  expect_error(e$boot_summarize(bad_inconsistent, sc["S-boot-1"], 3L), "Inconsistent bootstrap settings")
})
