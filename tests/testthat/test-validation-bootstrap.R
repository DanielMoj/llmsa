bootstrap_test_helpers <- function() {
  testthat::skip_if_not_installed("jsonlite")
  testthat::skip_if_not_installed("digest")
  e <- new.env(parent = globalenv())
  sys.source(system.file("validation", "sim", "boot_coverage_helpers.R", package = "llmsa", mustWork = TRUE), e)
  e
}

test_that("coverage tables load independently of simulation generators", {
  e <- bootstrap_test_helpers()
  reader <- new.env(parent = globalenv())
  sys.source(system.file("validation", "sim", "boot_coverage_results.R", package = "llmsa", mustWork = TRUE), reader)
  expect_true(is.function(reader$boot_read_results))
  expect_false(exists("sim_generate", envir = reader, inherits = FALSE))
  expect_false(exists("boot_generate", envir = reader, inherits = FALSE))
  expect_false(exists("boot_main", envir = reader, inherits = FALSE))
  for (s in e$boot_scenarios()) {
    expect_identical(reader$boot_result_estimands(s$type == "binary"), names(e$boot_truth(s)))
  }
  result <- reader$boot_read_results()
  expect_equal(result$n_min, e$boot_parameters()$n_min, tolerance = 0)
  expect_identical(result$data, e$boot_read_results()$data)
})

bootstrap_test_fit <- function(s, rep, runs) {
  # Explicit synthetic fitted object for protocol tests, never a study result.
  v <- s$components * (rep + 3) / 4
  if (s$type == "binary") v["Residual"] <- s$components[["Residual"]]
  structure(list(vc = data.frame(source = names(v), variance = unname(v)),
    type = s$type, link = s$link, converged = rep %% 2L == 0L, singular = TRUE,
    n = list(items = length(unique(runs$item_id)), prompts = length(unique(runs$prompt_id)),
      models = length(unique(runs$model_id)), blocks = length(unique(runs$block)), observations = nrow(runs))),
    class = "msa_fit")
}

bootstrap_test_replicates <- function(e, scenarios, n = 4L) {
  parts <- lapply(scenarios, function(s) lapply(seq_len(n), function(r) {
    e$boot_replicate(s, r, fitter = function(runs, ...) {
      if (r == 2L) warning("Synthetic fit warning", call. = FALSE)
      if (r == 3L) message("Synthetic fit message")
      bootstrap_test_fit(s, r, runs)
    }, bootstrapper = function(fit, level, seed, ...) {
      expect_length(list(...), 0L)
      expect_identical(level, 0.95)
      expect_identical(seed, e$boot_seeds(s, r)$boot)
      targets <- e$boot_interval_estimands
      truth <- e$boot_truth(s)[targets]
      j <- (r - 1L) %% 4L + 1L
      b <- data.frame(statistic = targets, estimate = unname(truth),
        lower = unname(truth) + c(0, -1, 1, -2)[j],
        upper = unname(truth) + c(1, 0, 2, 1)[j])
      size <- eval(formals(llmsa::msa_boot)$nsim)
      attr(b, "boot") <- matrix(0, size, length(targets))
      attr(b, "level") <- level
      attr(b, "n_singular") <- c(0, 1, 2, 1)[j]
      attr(b, "n_failed") <- c(1, 0, 1, 2)[j]
      b
    })
  }))
  do.call(rbind, unlist(parts, recursive = FALSE))
}

test_that("coverage seeds are disjoint, stable under selection, and restore the caller RNG", {
  e <- bootstrap_test_helpers()
  sc <- e$boot_scenarios()
  expect_identical(names(sc), paste0("S-boot-", 1:7))
  all_seeds <- unlist(lapply(sc, e$boot_seeds, rep = seq_len(31L)), use.names = FALSE)
  expect_identical(anyDuplicated(all_seeds), 0L)
  set.seed(20261102L)
  old <- .Random.seed
  kind <- RNGkind()
  forward <- lapply(sc, e$boot_generate, rep = 2L)
  backward <- lapply(rev(sc), e$boot_generate, rep = 2L)
  expect_identical(forward, rev(backward))
  expect_identical(.Random.seed, old)
  expect_identical(RNGkind(), kind)
  for (i in seq_along(sc)) {
    s <- sc[[i]]
    runs <- forward[[i]]
    expect_equal(nrow(runs), s$items * s$prompts * s$models * s$blocks * s$reps)
    expect_identical(length(unique(runs$item_id)), s$items)
    expect_identical(length(unique(runs$prompt_id)), s$prompts)
    expect_false(identical(runs$value, e$boot_generate(s, 1L)$value))
    if (s$type == "binary") expect_setequal(unique(runs$value), 0:1)
  }
  local({
    on.exit(assign(".Random.seed", old, .GlobalEnv))
    rm(".Random.seed", envir = .GlobalEnv)
    e$boot_generate(sc[[1L]], 1L)
    expect_false(exists(".Random.seed", .GlobalEnv, inherits = FALSE))
  })
  expect_error(e$boot_seeds(sc[[1L]], .Machine$integer.max), "seed is out of range")
  expect_error(e$boot_seeds(sc[[1L]], 0), "seed is out of range")
})

test_that("numeric coverage effects follow their grouping and variance scaling", {
  e <- bootstrap_test_helpers()
  s <- e$boot_scenarios()[[1L]]
  s$items <- 4L
  columns <- c(item = "item_id", prompt = "prompt_id", model = "model_id", block = "block")
  for (component in setdiff(names(s$components), "Residual")) {
    one <- s
    one$components[] <- 0
    one$components[component] <- 1
    r <- e$boot_generate(one, 2L)
    groups <- interaction(r[columns[strsplit(component, ":", fixed = TRUE)[[1L]]]], drop = TRUE)
    expect_true(all(vapply(split(r$value, groups), function(x) length(unique(x)) == 1L, logical(1))))
    expect_identical(length(unique(r$value)), nlevels(groups))
  }
  r <- e$boot_generate(s, 2L)
  scaled <- s
  scaled$components <- scaled$components * 9
  scaled$mu <- 4
  expect_equal(e$boot_generate(scaled, 2L)$value, 3 * r$value + 4,
               tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  a <- e$boot_truth(s)
  b <- e$boot_truth(scaled)
  expect_equal(a[e$boot_interval_estimands], b[e$boot_interval_estimands],
               tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  expect_equal(sum(s$components[-1L]) / sum(s$components), a[["grr_pct_contribution"]] / 100,
               tolerance = numeric_tolerance("arithmetic", "abs_tol"))
})

test_that("coverage failure records distinguish missing fits from missing bootstraps", {
  e <- bootstrap_test_helpers()
  s <- e$boot_scenarios()[[1L]]
  fit_counts <- c("items", "prompts", "models", "blocks", "observations")
  boot_counts <- c("boot_nsim", "boot_level", "n_singular", "n_failed")
  failed <- e$boot_replicate(s, 1L, fitter = function(...) {
    warning("Synthetic failure warning", call. = FALSE)
    stop("Synthetic fit failure", call. = FALSE)
  }, bootstrapper = function(...) stop("Bootstrap must not be reached"))
  expect_true(all(is.na(failed[c("estimate", "lower", "upper", fit_counts, boot_counts)])))
  expect_true(all(failed$error_stage == "fit" & failed$error == "Synthetic fit failure"))
  expect_true(all(failed$warnings == "fit: Synthetic failure warning"))
  expect_setequal(failed$estimand, names(e$boot_truth(s)))
  fitted <- function(runs, ...) {
    expect_identical(list(...), list(type = "numeric"))
    f <- bootstrap_test_fit(s, 1L, runs)
    f$n$observations <- nrow(runs) - 1L
    f
  }
  b_failed <- e$boot_replicate(s, 1L, fitter = fitted, bootstrapper = function(...) {
    warning("Synthetic bootstrap warning", call. = FALSE)
    stop("Synthetic bootstrap failure", call. = FALSE)
  })
  expect_true(all(is.finite(b_failed$estimate)))
  expect_true(all(is.na(b_failed[c("lower", "upper", boot_counts)])))
  expect_true(all(b_failed$observations == nrow(e$boot_generate(s, 1L)) - 1L))
  expect_true(all(b_failed$error_stage == "bootstrap" & b_failed$error == "Synthetic bootstrap failure"))
  expect_true(all(b_failed$warnings == "bootstrap: Synthetic bootstrap warning"))
  expect_true(all(!b_failed$converged & b_failed$singular))
})

test_that("coverage measures use closed intervals and MCSE across outer repetitions", {
  e <- bootstrap_test_helpers()
  sc <- e$boot_scenarios()[1L]
  reps <- bootstrap_test_replicates(e, sc)
  reps$estimate[reps$estimand == "item"] <- c(2, 4, 8, NA_real_)
  res <- e$boot_summarize(reps, sc, 4L)
  tol <- numeric_tolerance("arithmetic", "abs_tol")
  row <- function(est, measure) res[res$estimand == est & res$measure == measure, ]
  b <- row("item", "bias")
  expect_equal(b$value, (2 + 4 + 8) / 3 - 1, tolerance = tol)
  expect_equal(b$mcse, sqrt(sum((c(2, 4, 8) - 14 / 3)^2) / (3 * 2)), tolerance = tol)
  expect_identical(b$n_finite, 3L)
  expect_identical(b$n_failed, 1L)
  for (estimand in e$boot_interval_estimands) {
    coverage <- row(estimand, "coverage")
    width <- row(estimand, "width")
    expect_equal(coverage$value, 3 / 4, tolerance = tol)
    expect_equal(coverage$mcse, sqrt((3 / 4) * (1 / 4) / 4), tolerance = tol)
    expect_equal(width$value, 3 / 2, tolerance = tol)
    expect_equal(width$mcse, 1 / 2, tolerance = tol)
  }
  B <- unique(reps$boot_nsim)
  for (kind in c("singular", "failed")) {
    q <- if (kind == "singular") c(0, 1, 2, 1) / B else c(1, 0, 1, 2) / B
    stat <- row("bootstrap", paste0(kind, "_share"))
    expect_equal(stat$value, sum(q) / 4, tolerance = tol)
    expect_equal(stat$mcse, sqrt(sum((q - mean(q))^2) / (4 * 3)), tolerance = tol)
  }
  # One failed outer bootstrap changes interval/share denominators only.
  absent <- reps$rep == 4L
  reps[absent, c("lower", "upper", "boot_nsim", "boot_level", "n_singular", "n_failed")] <- NA_real_
  res <- e$boot_summarize(reps, sc, 4L)
  expect_identical(row("icc_items", "bias")$n_finite, 4L)
  expect_identical(row("icc_items", "coverage")$n_finite, 3L)
  expect_equal(row("icc_items", "coverage")$value, 2 / 3, tolerance = tol)
  expect_identical(row("bootstrap", "failed_share")$n_finite, 3L)
})

test_that("coverage output preserves failures before a named aggregation abort", {
  e <- bootstrap_test_helpers()
  sc <- e$boot_scenarios()[1L]
  reps <- bootstrap_test_replicates(e, sc, 2L)
  reps$estimate[reps$estimand == "item"] <- NA_real_
  directory <- tempfile("synthetic-coverage-abort-")
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  paths <- e$sim_prepare_output(directory, "boot_coverage")
  expect_error(e$boot_write(paths, reps, sc, 2L, "SYNTHETIC UNIT FIXTURE"), "S-boot-1/item: fewer than two finite")
  expect_true(all(file.exists(paths[c("replicates", "session")])))
  expect_false(file.exists(paths[["results"]]))
  expect_match(paste(readLines(paths[["session"]]), collapse = " "), "Aggregation failure")
  expect_error(e$sim_prepare_output(directory, "boot_coverage"), "already exists")
  good <- bootstrap_test_replicates(e, sc)
  for (finite in 0:1) {
    bad <- good
    bad$lower[bad$rep > finite & bad$estimand == "icc_items"] <- NA_real_
    expect_error(e$boot_summarize(bad, sc, 4L), "S-boot-1/icc_items/interval: fewer than two finite")
  }
})

test_that("coverage CLI and workers reject invalid selections and overflow", {
  e <- bootstrap_test_helpers()
  params <- e$boot_parameters()
  good <- c("--out", tempfile(), "--n-sim", "2")
  expect_length(e$boot_parse(good, params)$scenarios, 7L)
  selected <- e$boot_parse(c(good, "--scenarios", "S-boot-7,S-boot-1"), params)
  expect_identical(names(selected$scenarios), c("S-boot-7", "S-boot-1"))
  for (n in c("1", "-1", "2.5", "Inf", "NA", "text")) {
    args <- good; args[4L] <- n
    expect_error(e$boot_parse(args, params), "integer of at least two")
  }
  args <- good; args[4L] <- as.character(.Machine$integer.max)
  expect_error(e$boot_parse(args, params), "seed is out of range")
  for (ids in c("S-boot-8", "S-boot-1,S-boot-1", ",S-boot-1", "S-boot-1,", "S-boot-1,,S-boot-2")) {
    expect_error(e$boot_parse(c(good, "--scenarios", ids), params), "scenario ID")
  }
  for (extra in list("--scenarios", c("--extra", "2"), c("--n-sim", "2"))) {
    expect_error(e$boot_parse(c(good, extra), params))
  }
  old_workers <- Sys.getenv("LLMSA_SIM_WORKERS", unset = NA_character_)
  on.exit(if (is.na(old_workers)) Sys.unsetenv("LLMSA_SIM_WORKERS") else
    Sys.setenv(LLMSA_SIM_WORKERS = old_workers), add = TRUE)
  for (workers in c("0", "-1", "1.5", "NA", as.character(params$cores + 1))) {
    Sys.setenv(LLMSA_SIM_WORKERS = workers)
    expect_error(e$boot_workers(params$cores, 4L), "LLMSA_SIM_WORKERS")
  }
  # ?Sys.setenv: Windows has no empty variables, Sys.setenv(FOO = "") unsets FOO.
  # The default then applies and the study runs sequentially (ADR-046).
  Sys.setenv(LLMSA_SIM_WORKERS = "")
  if (.Platform$OS.type == "windows") {
    expect_identical(Sys.getenv("LLMSA_SIM_WORKERS", unset = NA_character_), NA_character_)
    expect_identical(e$boot_workers(params$cores, 4L), 1L)
  } else {
    expect_error(e$boot_workers(params$cores, 4L), "LLMSA_SIM_WORKERS")
  }
})

test_that("coverage readers choose full results and reject corrupt files without fallback", {
  e <- bootstrap_test_helpers()
  params <- e$boot_parameters()
  sc <- e$boot_scenarios(params)
  # Entirely synthetic protocol tables; no expensive fits or bootstrap runs.
  reps <- bootstrap_test_replicates(e, sc)
  full <- e$boot_summarize(reps, sc, 4L)
  full$n_sim <- params$n_min
  check <- full[full$scenario %in% c("S-boot-1", "S-boot-7"), ]
  check$n_sim <- params$n_check
  directory <- tempfile("synthetic-coverage-reader-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  short <- file.path(directory, "boot_coverage_check_results.csv")
  path <- file.path(directory, "boot_coverage_results.csv")
  utils::write.csv(check, short, row.names = FALSE)
  expect_identical(e$boot_read_results(directory)$mode, "check")
  full$mcse <- full$mcse + 1 / 4
  full$seed <- 1 / 2  # Reader checks a number, not the study seed rule.
  utils::write.csv(full, path, row.names = FALSE)
  got <- e$boot_read_results(directory)
  expect_identical(got$mode, "full")
  expect_equal(got$n_sim, params$n_min, tolerance = 0)
  expect_equal(got$data$mcse, full$mcse, tolerance = params$arithmetic)
  bads <- list(full[-1L, ], rbind(full, full[1L, ]), full[full$scenario != "S-boot-2", ], full[, -4L])
  for (column in c("value", "mcse", "n_sim", "seed")) {
    bad <- full; bad[[column]][1L] <- Inf
    bads[[length(bads) + 1L]] <- bad
  }
  for (bad in bads) {
    utils::write.csv(bad, path, row.names = FALSE)
    expect_error(e$boot_read_results(directory))
  }
  bad <- full; bad$value[bad$measure == "coverage"] <- 2
  utils::write.csv(bad, path, row.names = FALSE)
  expect_error(e$boot_read_results(directory), "outside")
  bad <- full; bad$mcse[1L] <- -1
  utils::write.csv(bad, path, row.names = FALSE)
  expect_error(e$boot_read_results(directory), "values")
  bad <- full; bad$n_sim <- params$n_min - 1L
  utils::write.csv(bad, path, row.names = FALSE)
  expect_error(e$boot_read_results(directory), "anchored run size")
})

test_that("coverage merges retain estimates and summaries and reject incompatible provenance", {
  e <- bootstrap_test_helpers()
  sc <- e$boot_scenarios()
  directory <- tempfile("synthetic-coverage-parts-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  subsets <- list(sc[c(1L, 3L, 5L, 7L)], sc[c(2L, 4L, 6L)])
  parts <- file.path(directory, c("first", "second"))
  all <- list()
  for (i in seq_along(parts)) {
    reps <- bootstrap_test_replicates(e, subsets[[i]], 2L)
    all[[i]] <- reps
    paths <- e$sim_prepare_output(parts[i], "boot_coverage")
    e$boot_write(paths, reps, subsets[[i]], 2L,
      c(e$boot_metadata(subsets[[i]], 2L), "SYNTHETIC UNIT FIXTURE; no study findings"))
  }
  out <- file.path(directory, "merged")
  expect_output(e$boot_merge(parts, out), "no fits recomputed")
  merged <- e$sim_read_csv(e$sim_paths(out, "boot_coverage")[["replicates"]])
  expected <- do.call(rbind, all)
  expected <- expected[order(expected$scenario, expected$rep, expected$estimand), ]
  expect_identical(latent_test_cells(merged), latent_test_cells(expected))
  first <- e$sim_paths(parts[1L], "boot_coverage")
  original <- e$sim_read_csv(first[["replicates"]])
  for (field in c("data_seed", "boot_seed", "true", "items")) {
    bad <- original; bad[[field]][1L] <- bad[[field]][1L] + 1
    utils::write.csv(bad, first[["replicates"]], row.names = FALSE)
    expect_error(e$boot_merge(parts, tempfile(tmpdir = directory)), "truths or seeds|design count")
  }
  utils::write.csv(original, first[["replicates"]], row.names = FALSE)
  expect_error(e$boot_merge(parts[1L], tempfile(tmpdir = directory)), "cover all scenarios")
  lines <- readLines(first[["session"]])
  lines[startsWith(lines, "implementation:")] <- "implementation: synthetic-mismatch"
  writeLines(lines, first[["session"]])
  expect_error(e$boot_merge(parts, tempfile(tmpdir = directory)), "implementation, versions")
})
