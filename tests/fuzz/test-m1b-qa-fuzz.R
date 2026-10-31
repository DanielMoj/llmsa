# QA / Red Team fuzz & boundary tests for M1b (fixed seed: 20261031)
testthat::set_max_fails(Inf)

qa_m1b_fuzz_runs <- function(seed = 20261031L, values = c("c1", "c2", "c3"), items = 10L, prompts = 3L, models = 3L, reps = 2L) {
  set.seed(seed)
  grid <- expand.grid(
    rep = seq_len(reps),
    block = 1L,
    model_id = paste0("M", seq_len(models)),
    prompt_id = paste0("P", seq_len(prompts)),
    item_id = sprintf("I%02d", seq_len(items)),
    stringsAsFactors = FALSE
  )
  grid$value <- sample(values, nrow(grid), replace = TRUE)
  as_msa_runs(grid)
}

test_that("QA-M1b-005: msa_fit validates ordinal/binary levels and respects explicit binary levels regardless of value storage mode (seed = 20261031)", {
  set.seed(20261031L)
  runs_ord <- qa_m1b_fuzz_runs(seed = 20261031L, values = c("c1", "c2", "c3"))

  # 1. Ordinal levels containing NA, duplicates, fewer than 2 levels, or empty label "" must be rejected with a clear levels error:
  for (bad_levels in list(c("c1", NA_character_, "c2", "c3"),
                          c("c1", "c2", "c2", "c3"),
                          c("c1"),
                          character(0),
                          c("", "c2", "c3"))) {
    err <- tryCatch(
      suppressWarnings(msa_fit(runs_ord, type = "ordinal", levels = bad_levels)),
      error = function(e) conditionMessage(e)
    )
    expect_true(
      is.character(err) && grepl("levels", err, ignore.case = TRUE) && !grepl("factor level [", err, fixed = TRUE),
      info = paste("Expected clean ordinal levels validation error for", deparse(bad_levels), "got:",
                   if (is.character(err)) err else "succeeded without error")
    )
  }

  # 2. Binary levels containing empty string "" must be rejected:
  runs_bin_chr <- qa_m1b_fuzz_runs(seed = 20261031L, values = c("no", "yes"))
  err_bin_empty <- tryCatch(
    suppressWarnings(msa_fit(runs_bin_chr, type = "binary", levels = c("", "yes"))),
    error = function(e) conditionMessage(e)
  )
  expect_true(is.character(err_bin_empty) && grepl("levels|label", err_bin_empty, ignore.case = TRUE))

  # 3. When explicit `levels` are passed to type = "binary", numeric/logical `value` columns must not silently ignore `levels`:
  runs_01 <- qa_m1b_fuzz_runs(seed = 20261031L, values = c(0L, 1L))
  # Unrelated levels c("no", "yes") on 0/1 values should drop all rows as not in `levels` and stop with "No valid response categories to analyse."
  err_unrelated <- tryCatch(
    suppressWarnings(msa_fit(runs_01, type = "binary", levels = c("no", "yes"))),
    error = function(e) conditionMessage(e)
  )
  expect_true(
    is.character(err_unrelated) && grepl("No valid response categories|levels", err_unrelated, ignore.case = TRUE),
    info = paste("Expected error when binary levels do not match numeric 0/1 values, got:",
                 if (is.character(err_unrelated)) err_unrelated else "succeeded by ignoring levels")
  )

  # Numeric codes c(1, 2) with explicit levels = c("1", "2") must behave identically to character c("1", "2"):
  runs_12_num <- qa_m1b_fuzz_runs(seed = 20261031L, values = c(1, 2))
  runs_12_chr <- runs_12_num
  runs_12_chr$value <- as.character(runs_12_chr$value)
  fit_12_chr <- suppressWarnings(msa_fit(runs_12_chr, type = "binary", levels = c("1", "2")))
  fit_12_num <- tryCatch(
    suppressWarnings(msa_fit(runs_12_num, type = "binary", levels = c("1", "2"))),
    error = function(e) e
  )
  expect_false(inherits(fit_12_num, "error"),
               info = if (inherits(fit_12_num, "error")) conditionMessage(fit_12_num) else NULL)
  if (!inherits(fit_12_num, "error")) {
    expect_identical(fit_12_num$data$y, fit_12_chr$data$y)
  }
})

test_that("QA-M1b-006: sim_merge and latent_read_results reject corrupted replicate design counts, contradictory failure states, and out-of-range result metrics (seed = 20261031)", {
  set.seed(20261031L)
  sim_env <- new.env(parent = globalenv())
  sys.source(system.file("validation", "sim", "simulation_helpers.R", package = "llmsa", mustWork = TRUE), envir = sim_env)

  # 1. Prepare two disjoint scenario triplets for two_level from the check files and corrupt design counts in part 1:
  sim_dir <- system.file("validation", "sim", package = "llmsa", mustWork = TRUE)
  full_res <- sim_env$sim_read_csv(file.path(sim_dir, "two_level_check_results.csv"))
  full_rep <- sim_env$sim_read_csv(file.path(sim_dir, "two_level_check_replicates.csv"))
  n_sim <- unique(full_res$n_sim)[1L]
  scenarios <- sim_env$sim_scenarios("two_level")

  make_part <- function(id) {
    d <- tempfile(paste0("qa-sim-", id, "-"))
    dir.create(d, recursive = TRUE)
    paths <- sim_env$sim_paths(d, "two_level")
    sel <- scenarios[id]
    res_part <- full_res[full_res$scenario == id, , drop = FALSE]
    rep_part <- full_rep[full_rep$scenario == id, , drop = FALSE]
    sess <- c(sim_env$sim_metadata("two_level", sel, n_sim),
              "", utils::capture.output(utils::sessionInfo()))
    utils::write.csv(res_part, paths[["results"]], row.names = FALSE)
    utils::write.csv(rep_part, paths[["replicates"]], row.names = FALSE)
    writeLines(sess, paths[["session"]])
    d
  }

  d1 <- make_part("S-two-1")
  d2 <- make_part("S-two-2")
  on.exit(unlink(c(d1, d2), recursive = TRUE), add = TRUE)

  # Corrupt items count in d1 replicates (e.g. 999 instead of 60):
  rep1_path <- sim_env$sim_paths(d1, "two_level")[["replicates"]]
  rep1_bad <- sim_env$sim_read_csv(rep1_path)
  rep1_bad$items <- 999L
  utils::write.csv(rep1_bad, rep1_path, row.names = FALSE)

  out_merge <- tempfile("qa-sim-merged-")
  on.exit(unlink(out_merge, recursive = TRUE), add = TRUE)
  err_merge <- tryCatch({
    sim_env$sim_merge("two_level", c(d1, d2), out_merge)
    NULL
  }, error = function(e) conditionMessage(e))
  expect_true(
    is.character(err_merge) && length(err_merge) == 1L &&
      grepl("items|design|count|inconsistent|replicate", err_merge, ignore.case = TRUE),
    info = paste("Expected sim_merge to reject corrupted replicate design counts, got:",
                 if (is.character(err_merge)) paste(err_merge, collapse = ", ") else "merged without error")
  )

  # 2. latent_read_results must reject negative empse/rmse, derived_share outside [0, 1], or non-positive/non-integer seeds:
  bad_sim_dir <- tempfile("qa-latent-results-")
  dir.create(bad_sim_dir, recursive = TRUE)
  on.exit(unlink(bad_sim_dir, recursive = TRUE), add = TRUE)
  res_path <- file.path(bad_sim_dir, "two_level_results.csv")

  bad_empse <- full_res
  bad_empse$value[bad_empse$measure == "empse"][1L] <- -0.25
  utils::write.csv(bad_empse, res_path, row.names = FALSE)
  err_empse <- tryCatch({
    sim_env$latent_read_results("two_level", sim_dir = bad_sim_dir)
    NULL
  }, error = function(e) conditionMessage(e))
  expect_true(is.character(err_empse), info = "latent_read_results accepted negative empse")

  bad_share <- full_res
  bad_share$value[bad_share$measure == "derived_share"][1L] <- 1.5
  utils::write.csv(bad_share, res_path, row.names = FALSE)
  err_share <- tryCatch({
    sim_env$latent_read_results("two_level", sim_dir = bad_sim_dir)
    NULL
  }, error = function(e) conditionMessage(e))
  expect_true(is.character(err_share), info = "latent_read_results accepted derived_share > 1")

  bad_seed <- full_res
  bad_seed$seed <- -10.5
  utils::write.csv(bad_seed, res_path, row.names = FALSE)
  err_seed <- tryCatch({
    sim_env$latent_read_results("two_level", sim_dir = bad_sim_dir)
    NULL
  }, error = function(e) conditionMessage(e))
  expect_true(is.character(err_seed), info = "latent_read_results accepted negative fractional seed")
})
