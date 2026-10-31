simulation_test_replicates <- function(e, scenarios, n = 3L) {
  # Explicit synthetic fitted objects for arithmetic and file-protocol tests.
  # These fixtures are never shipped or described as simulation findings.
  pieces <- lapply(scenarios, function(s) lapply(seq_len(n), function(rep) {
    e$sim_replicate(s, rep, fitter = function(runs, ...) {
      v <- s$components
      v[names(v) != "Residual"] <- v[names(v) != "Residual"] * (rep + 2) / 3
      vc <- data.frame(source = names(v), variance = unname(v))
      if (s$models == 2L) attr(vc, "derived") <- "model"
      warning("Synthetic fixture diagnostic", call. = FALSE)
      if (rep == 3L) message("Synthetic third-repetition message")
      structure(list(vc = vc, type = s$type, link = s$link, converged = rep %% 2L == 0L,
        singular = TRUE, n = list(items = length(unique(runs$item_id)), prompts = length(unique(runs$prompt_id)),
          models = length(unique(runs$model_id)), blocks = length(unique(runs$block)), observations = nrow(runs))),
        class = "msa_fit")
    })
  }))
  do.call(rbind, unlist(pieces, recursive = FALSE))
}

simulation_test_part <- function(e, scenario, n = 3L, study = "binary_recovery") {
  directory <- tempfile("synthetic-simulation-part-")
  paths <- e$sim_prepare_output(directory, study)
  reps <- simulation_test_replicates(e, scenario, n)
  e$sim_write(paths, reps, scenario, n, study,
    c(e$sim_metadata(study, scenario, n), "SYNTHETIC UNIT FIXTURE; no fitted study findings"))
  directory
}

test_that("ADEMP statistics use finite observations and the stated MCSE denominators", {
  e <- latent_test_helpers(TRUE)
  x <- c(1, 3, 6, NA_real_, Inf)
  truth <- 2
  got <- e$sim_performance(x, truth)
  keep <- c(1, 3, 6)
  mean_x <- sum(keep) / length(keep)
  sample_var <- sum((keep - mean_x)^2) / (length(keep) - 1L)
  mse <- sum((keep - truth)^2) / length(keep)
  squared_error_var <- sum(((keep - truth)^2 - mse)^2) / (length(keep) - 1L)
  expected <- c(mean_x - truth, (mean_x - truth) / truth, sqrt(sample_var), sqrt(mse))
  mcse <- c(sqrt(sample_var / length(keep)), sqrt(sample_var / length(keep)) / abs(truth),
             sqrt(sample_var / (2 * (length(keep) - 1))), sqrt(squared_error_var / length(keep)) / (2 * sqrt(mse)))
  tol <- numeric_tolerance("arithmetic", "abs_tol")
  expect_equal(got$value, expected, tolerance = tol)
  expect_equal(got$mcse, mcse, tolerance = tol)
  expect_identical(got$measure, c("bias", "rel_bias", "empse", "rmse"))
  exact <- e$sim_performance(rep(truth, 3L), truth)
  expect_equal(exact$value, rep(0, 4L), tolerance = 0)
  expect_equal(exact$mcse, rep(0, 4L), tolerance = 0)
  for (bad in list(numeric(), c(NA, Inf), c(1, NA))) expect_error(e$sim_performance(bad, truth), "Fewer than two finite")
  expect_error(e$sim_performance(keep, 0), "finite nonzero truth")
})

test_that("scenario seeds and generated designs are independent of order and caller RNG", {
  e <- latent_test_helpers(TRUE)
  all <- unlist(lapply(e$latent_studies, e$sim_scenarios), recursive = FALSE)
  expect_identical(unname(vapply(all, `[[`, integer(1), "index")), seq_along(all))
  seeds <- unlist(lapply(all, function(s) e$sim_seed(s, 1:3)), use.names = FALSE)
  expect_identical(anyDuplicated(seeds), 0L)
  previous <- RNGkind()
  set.seed(1977L)
  state <- .Random.seed
  first <- lapply(all, e$sim_generate, rep = 1L)
  expect_identical(.Random.seed, state)
  expect_identical(RNGkind(), previous)
  backward <- lapply(rev(all), e$sim_generate, rep = 1L)
  expect_identical(first, rev(backward))
  for (i in seq_along(all)) {
    s <- all[[i]]; runs <- first[[i]]
    expect_equal(nrow(runs), s$items * s$prompts * s$models * s$blocks * s$reps)
    expect_identical(length(unique(runs$item_id)), s$items)
    expect_identical(length(unique(runs$prompt_id)), s$prompts)
    expect_identical(length(unique(runs$model_id)), s$models)
    expect_identical(length(unique(runs$block)), s$blocks)
    if (s$type == "binary") expect_setequal(unique(runs$value), 0:1) else
      expect_setequal(unique(runs$value), paste0("c", 1:5))
    expect_false(identical(runs$value, e$sim_generate(s, 2L)$value))
    expect_identical(s$interactions, startsWith(s$id, "S-ord-"))
    v <- s$components
    truth <- e$sim_truth(s)
    expect_equal(unname(truth["icc_items"]), v[["item"]] / sum(v), tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  }
  local({
    state <- .Random.seed
    on.exit(assign(".Random.seed", state, .GlobalEnv))
    rm(".Random.seed", envir = .GlobalEnv)
    e$sim_generate(all[[1L]], 1L)
    expect_false(exists(".Random.seed", .GlobalEnv, inherits = FALSE))
  })
})

test_that("CLI options reject ambiguity, invalid counts, seeds and existing outputs", {
  e <- latent_test_helpers(TRUE)
  good <- c("--n-sim", "3", "--out", tempfile())
  full <- e$sim_parse("ordinal_recovery", good)
  selected <- e$sim_parse("ordinal_recovery", c(good, "--scenarios", "S-ord-4,S-ord-1"))
  expect_identical(names(selected$scenarios), c("S-ord-4", "S-ord-1"))
  expect_identical(e$sim_seed(selected$scenarios[[2L]], 3L), e$sim_seed(full$scenarios[[1L]], 3L))
  for (n in c("1", "0", "-1", "2.5", "NA", "Inf", "text")) {
    bad <- good; bad[2L] <- n
    expect_error(e$sim_parse("ordinal_recovery", bad), "integer of at least two")
  }
  for (extra in list(c("--n-sim", "3"), c("--unknown", "x"), "--scenarios")) {
    expect_error(e$sim_parse("ordinal_recovery", c(good, extra)))
  }
  for (ids in c("S-ord-1,S-ord-1", "S-bin-1", "S-ord-1,", ",S-ord-1", "S-ord-1,,S-ord-2", "")) {
    expect_error(e$sim_parse("ordinal_recovery", c(good, "--scenarios", ids)))
  }
  expect_error(e$sim_parse("ordinal_recovery", c("--n-sim", as.character(.Machine$integer.max), "--out", tempfile())), "seed is out of range")
  expect_error(e$sim_parse("unknown", good), "Unknown simulation study")
  directory <- tempfile()
  paths <- e$sim_prepare_output(directory, "binary_recovery")
  writeLines("synthetic existing output", paths[["session"]])
  expect_error(e$sim_prepare_output(directory, "binary_recovery"), "already exists")
  file <- tempfile(); writeLines("file, not a directory", file)
  expect_error(e$sim_prepare_output(file, "binary_recovery"), "Cannot create")
})

test_that("ordinary CSV readers preserve absent diagnoses when a run is extended", {
  e <- latent_test_helpers(TRUE)
  scenarios <- e$sim_scenarios("binary_recovery")[1L]
  full <- simulation_test_replicates(e, scenarios, 3L)
  short <- full[full$rep <= 2L, ]
  full_path <- tempfile(fileext = ".csv")
  short_path <- tempfile(fileext = ".csv")
  utils::write.csv(full, full_path, row.names = FALSE)
  utils::write.csv(short, short_path, row.names = FALSE)
  # This intentionally uses read.csv defaults, as do independent consumers.
  extended <- utils::read.csv(full_path, stringsAsFactors = FALSE)
  prefix <- utils::read.csv(short_path, stringsAsFactors = FALSE)
  expect_identical(latent_test_cells(prefix), latent_test_cells(extended[extended$rep <= 2L, ]))
  expect_true(any(grepl("Synthetic third-repetition message", extended$messages, fixed = TRUE)))
})

test_that("failed fits retain every target and insufficient runs save diagnostics before aborting", {
  e <- latent_test_helpers(TRUE)
  scenarios <- e$sim_scenarios("two_level")[1L]
  s <- scenarios[[1L]]
  failed <- e$sim_replicate(s, 1L, fitter = function(...) {
    warning("Synthetic engine warning", call. = FALSE)
    stop("Synthetic fitting failure", call. = FALSE)
  })
  expect_setequal(failed$estimand, names(e$sim_truth(s)))
  expect_true(all(is.na(failed$estimate)))
  expect_true(all(is.na(failed[c("items", "prompts", "models", "blocks", "observations")])))
  expect_true(all(failed$warnings == "Synthetic engine warning"))
  expect_true(all(failed$error == "Synthetic fitting failure"))
  expect_false(any(failed$derived | failed$converged))
  successful <- simulation_test_replicates(e, scenarios, 2L)
  expect_true(all(successful$derived))
  expect_true(all(is.finite(successful$estimate)))
  expect_true(any(!successful$converged & successful$singular))
  stats <- e$sim_summarize(successful, scenarios, 2L, "two_level")
  expect_true(all(stats$n_finite == 2L & stats$n_failed == 0L))
  expect_identical(stats$value[stats$measure == "derived_share"], 1)
  for (finite in 0:1) {
    reps <- successful
    target <- which(reps$estimand == "item")
    reps$estimate[target] <- NA_real_
    if (finite) reps$estimate[target[1L]] <- s$components[["item"]]
    paths <- e$sim_prepare_output(tempfile("synthetic-abort-"), "two_level")
    expect_error(e$sim_write(paths, reps, scenarios, 2L, "two_level", "SYNTHETIC FAILURE TEST"),
                 "S-two-1/item: fewer than two finite", fixed = TRUE)
    expect_true(all(file.exists(paths[c("replicates", "session")])))
    expect_false(file.exists(paths[["results"]]))
    saved <- utils::read.csv(paths[["replicates"]], stringsAsFactors = FALSE,
      colClasses = c(error = "character", warnings = "character", messages = "character"))
    expect_identical(latent_test_cells(saved), latent_test_cells(reps))
    expect_true(any(grepl("Aggregation failure:", readLines(paths[["session"]]), fixed = TRUE)))
  }
})

test_that("scenario merges preserve cells and provenance and reject invalid triplets", {
  e <- latent_test_helpers(TRUE)
  scenarios <- e$sim_scenarios("binary_recovery")
  directories <- vapply(seq_along(scenarios), function(i) simulation_test_part(e, scenarios[i]), character(1))
  read <- function(directory, kind) e$sim_read_csv(e$sim_paths(directory, "binary_recovery")[[kind]])
  out <- tempfile("synthetic-merged-")
  expect_output(e$sim_merge("binary_recovery", directories, out), "no fits recomputed")
  for (kind in c("results", "replicates")) {
    expected <- do.call(rbind, lapply(directories, read, kind = kind))
    order <- if (kind == "results") order(expected$scenario, expected$estimand, expected$measure) else
      order(expected$scenario, expected$rep, expected$estimand)
    expect_identical(latent_test_cells(read(out, kind)), latent_test_cells(expected[order, ]))
  }
  session <- readLines(e$sim_paths(out, "binary_recovery")[["session"]])
  expect_equal(sum(startsWith(session, "input_sha256:")), length(directories) * 3L)
  expect_true(any(grepl("original_session: SYNTHETIC UNIT FIXTURE", session, fixed = TRUE)))
  expect_true(any(grepl("no combined run time is asserted", session, fixed = TRUE)))
  expect_error(e$sim_merge("binary_recovery", directories[1L], tempfile()), "cover the entire study")
  expect_error(e$sim_merge("binary_recovery", rep(directories[1L], 2L), tempfile()), "distinct directories")
  longer <- simulation_test_part(e, scenarios[2L], n = 4L)
  expect_error(e$sim_merge("binary_recovery", c(directories[1L], longer), tempfile()), "different n_sim")
  damaged <- tempfile(); dir.create(damaged)
  stopifnot(all(file.copy(list.files(directories[2L], full.names = TRUE), damaged)))
  paths <- e$sim_paths(damaged, "binary_recovery")
  original_session <- readLines(paths[["session"]])
  writeLines(sub("package_ordinal:.*", "package_ordinal: synthetic incompatible version", original_session), paths[["session"]])
  expect_error(e$sim_merge("binary_recovery", c(directories[1L], damaged), tempfile()), "versions, implementation, seeds or RNG differ")
  writeLines(original_session, paths[["session"]])
  original_reps <- read(damaged, "replicates")
  bad <- original_reps; bad$rep_seed[1L] <- bad$rep_seed[1L] + 1L
  utils::write.csv(bad, paths[["replicates"]], row.names = FALSE)
  expect_error(e$sim_merge("binary_recovery", c(directories[1L], damaged), tempfile()), "replicate seeds, flags or truths")
  utils::write.csv(rbind(original_reps, original_reps[1L, ]), paths[["replicates"]], row.names = FALSE)
  expect_error(e$sim_merge("binary_recovery", c(directories[1L], damaged), tempfile()), "Incomplete or duplicate repetitions")
  utils::write.csv(original_reps, paths[["replicates"]], row.names = FALSE)
  result <- read(damaged, "results"); result$value[1L] <- result$value[1L] + 1
  utils::write.csv(result, paths[["results"]], row.names = FALSE)
  expect_error(e$sim_merge("binary_recovery", c(directories[1L], damaged), tempfile()), "result differs from replicates")
  unlink(paths[["results"]])
  expect_error(e$sim_merge("binary_recovery", c(directories[1L], damaged), tempfile()), "Incomplete simulation triplet")
})
