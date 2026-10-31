# These temporary, deliberately altered CSVs are synthetic protocol fixtures;
# they are never reported as simulation findings.
test_that("latent result readers reject impossible metrics and invalid seeds", {
  e <- latent_test_helpers()
  original <- e$latent_read_results("two_level")$data
  directory <- tempfile("synthetic-latent-range-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  file <- file.path(directory, "two_level_results.csv")
  write <- function(d) utils::write.csv(d, file, row.names = FALSE)
  for (measure in c("empse", "rmse", "derived_share")) {
    for (value in if (measure == "derived_share") c(-1, 2) else -1) {
      bad <- original
      bad$value[which(bad$measure == measure)[1L]] <- value
      write(bad)
      expect_error(e$latent_read_results("two_level", directory), "measure range")
    }
  }
  for (seed in c(-10.5, 0, 1.5, .Machine$integer.max + 1)) {
    bad <- original
    bad$seed[1L] <- seed
    write(bad)
    expect_error(e$latent_read_results("two_level", directory), "result seed")
  }
  for (seed in c(1, .Machine$integer.max)) {
    valid <- original
    valid$seed <- seed
    valid$value[valid$measure %in% c("empse", "rmse")] <- 0
    for (share in 0:1) {
      valid$value[valid$measure == "derived_share"] <- share
      write(valid)
      read <- e$latent_read_results("two_level", directory)
      expect_equal(read$data$seed, rep(seed, nrow(valid)), tolerance = 0)
      expect_equal(read$data$value[read$data$measure == "derived_share"], rep(share, 2L), tolerance = 0)
    }
  }
})

test_that("scenario merges validate every design count and fit-state flag", {
  e <- latent_test_helpers(TRUE)
  study <- "two_level"
  origin <- system.file("validation", "sim", package = "llmsa", mustWork = TRUE)
  results <- e$sim_read_csv(file.path(origin, "two_level_check_results.csv"))
  replicates <- e$sim_read_csv(file.path(origin, "two_level_check_replicates.csv"))
  scenarios <- e$sim_scenarios(study)
  n <- unique(results$n_sim)
  directory <- tempfile("synthetic-latent-merge-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  parts <- file.path(directory, names(scenarios))
  for (i in seq_along(parts)) {
    paths <- e$sim_prepare_output(parts[i], study)
    id <- names(scenarios)[i]
    utils::write.csv(results[results$scenario == id, ], paths[["results"]], row.names = FALSE)
    utils::write.csv(replicates[replicates$scenario == id, ], paths[["replicates"]], row.names = FALSE)
    writeLines(c(e$sim_metadata(study, scenarios[i], n), "SYNTHETIC CSV VALIDATION FIXTURE"), paths[["session"]])
  }
  paths <- e$sim_paths(parts[1L], study)
  original <- e$sim_read_csv(paths[["replicates"]])
  write <- function(d) utils::write.csv(d, paths[["replicates"]], row.names = FALSE)
  merge <- function() e$sim_merge(study, parts, tempfile("merged-", tmpdir = directory))
  expect_output(merge(), "no fits recomputed")
  counts <- c("items", "prompts", "models", "blocks", "observations")
  for (name in counts) {
    for (value in list(-1, 999, 1.5, Inf, NA_real_, "not a count")) {
      bad <- original
      bad[[name]][1L] <- value
      write(bad)
      expect_error(merge(), paste("design count", name), fixed = TRUE)
    }
  }
  for (name in c("converged", "singular")) {
    for (value in list(NA, 1L, "not a flag")) {
      bad <- original
      bad[[name]][1L] <- value
      write(bad)
      expect_error(merge(), "fit flags")
    }
  }
  # A genuine fitting failure has no design counts or singularity result.
  failed <- original
  rows <- failed$rep == 1L
  failed$estimate[rows] <- NA_real_
  for (name in counts) failed[[name]][rows] <- NA_integer_
  failed$converged[rows] <- failed$derived[rows] <- FALSE
  failed$singular[rows] <- NA
  failed$error[rows] <- "Synthetic fitting failure"
  write(failed)
  adjusted <- e$sim_summarize(failed, scenarios[1L], n, study)
  utils::write.csv(adjusted, paths[["results"]], row.names = FALSE)
  expect_output(merge(), "no fits recomputed")
  for (name in c("converged", "derived", "singular", "items")) {
    bad <- failed
    bad[[name]][rows] <- if (name == "items") scenarios[[1L]]$items else TRUE
    write(bad)
    expect_error(merge(), "fit flags")
  }
  # A fit can exist although a later summary operation failed. Its counts
  # and singularity remain present, as sim_replicate documents.
  failed[counts] <- original[counts]
  failed$singular <- original$singular
  write(failed)
  expect_output(merge(), "no fits recomputed")
})
