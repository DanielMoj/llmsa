planning_test_helpers <- function(generator = FALSE) {
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  env <- new.env(parent = globalenv())
  path <- if (generator) system.file("validation", "sim", "planning_rule.R", package = "llmsa", mustWork = TRUE) else
    system.file("validation", "planning", "reference_checks.R", package = "llmsa", mustWork = TRUE)
  sys.source(path, envir = env)
  env
}

planning_test_copy <- function() {
  original <- system.file("validation", "planning", package = "llmsa", mustWork = TRUE)
  target <- tempfile("planning-validation-test-")
  dir.create(target)
  stopifnot(all(file.copy(list.files(original, full.names = TRUE), target, recursive = TRUE)))
  target
}

planning_test_rehash <- function(directory, file) {
  path <- file.path(directory, "SOURCES.json")
  manifest <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  manifest$results[[file]]$sha256 <- digest::digest(file = file.path(directory, file), algo = "sha256", serialize = FALSE)
  jsonlite::write_json(manifest, path, pretty = TRUE, auto_unbox = TRUE, digits = NA)
}

test_that("planning resources reuse complete anchors and expose independently recomputable numbers", {
  e <- planning_test_helpers()
  result <- e$planning_read_results(repo_root = "")
  expect_identical(result$mode, "public")
  expect_identical(list.files(file.path(system.file("validation", "planning", package = "llmsa"), "anchors")), "ANK-89.json")
  expect_setequal(names(result$anchors), c("ANK-89", "ANK-06", "ANK-16", "ANK-TOL"))
  expect_identical(result$anchors[["ANK-16"]]$value, numeric_anchor("ANK-16"))
  expect_identical(result$anchors[["ANK-TOL"]]$value, numeric_anchor("ANK-TOL"))
  expect_identical(result$manifest$study$rng, as.list(c("Mersenne-Twister", "Inversion", "Rejection")))
  expect_identical(result$manifest$provenance$cv_mcse_method, e$planning_cv_method)
  expect_true(all(c("msa_plan", "msa_simulate", "msa_fit") %in% names(result$manifest$provenance$function_sha256)))
  expect_true(all(c("R/plan.R", "R/fit.R") %in% names(result$manifest$provenance$source_sha256)))
  expect_true(all(c("R", "llmsa", "lme4", "Matrix") %in% names(result$manifest$provenance$versions)))
  expect_true(any(grepl("RNG:", result$session, fixed = TRUE)))
  expect_true(any(grepl("elapsed seconds:", result$session, fixed = TRUE)))
  tolerance <- numeric_tolerance("arithmetic", "abs_tol")
  for (i in seq_len(nrow(result$summary))) {
    s <- result$summary[i, ]
    reps <- result$replicates[result$replicates$plan == s$plan, ]
    y <- reps$prompt
    n <- length(y)
    mu <- sum(y) / n
    empirical_sd <- sqrt(sum((y - mu)^2) / (n - 1))
    boundary <- sum(y == 0) / n
    expect_identical(n, as.integer(result$anchors[["ANK-06"]]$value$n_sim_min))
    expect_equal(s$cv_empirical, empirical_sd / mu, tolerance = tolerance)
    expect_equal(s$boundary_share, boundary, tolerance = tolerance)
    expect_equal(s$mcse_boundary, sqrt(boundary * (1 - boundary) / n), tolerance = tolerance)
    centered <- y - mu
    variance <- mean(centered^2)
    # Independent delta parameterization: mean and centered second moment.
    gradient_mean <- -empirical_sd / mu^2
    gradient_variance <- (n / (n - 1)) / (2 * mu * empirical_sd)
    influence <- gradient_mean * centered + gradient_variance * (centered^2 - variance)
    expect_equal(s$mcse_cv, sqrt(stats::var(influence) / n), tolerance = tolerance)
    x <- reps$estimate
    average <- sum(x) / n
    squares <- sum((x - average)^2)
    expect_equal(s$mean, average, tolerance = tolerance)
    expect_equal(s$bias, average - s$grr_true, tolerance = tolerance)
    expect_equal(s$empse, sqrt(squares / (n - 1)), tolerance = tolerance)
    expect_equal(s$mcse_bias, sqrt(squares / (n * (n - 1))), tolerance = tolerance)
    expect_equal(s$mcse_empse, sqrt(squares / (2 * (n - 1)^2)), tolerance = tolerance)
    expect_equal(s$rmse, sqrt(sum((x - s$grr_true)^2) / n), tolerance = tolerance)
    expect_equal(s$pct_singular, 100 * sum(reps$singular) / n, tolerance = tolerance)
  }
  # No frozen result may cause a hidden model fit at documentation time.
  fail <- function(...) stop("Unexpected simulation or fit while reading results.")
  local_mocked_bindings(msa_plan = fail, msa_simulate = fail, msa_fit = fail)
  expect_no_error(e$planning_read_results(repo_root = ""))
  expect_false(exists("planning_rule_generate", envir = e, inherits = FALSE))
})

test_that("the supplementary CV MCSE agrees with centered-moment delta arithmetic and scaling", {
  e <- planning_test_helpers()
  y <- c(0, 1, 3, 4, 8)  # Small explicitly synthetic arithmetic fixture.
  n <- length(y)
  mu <- mean(y)
  variance <- mean((y - mu)^2)
  correction <- n / (n - 1)
  sd <- sqrt(correction * variance)
  influence <- -sd / mu^2 * (y - mu) + correction / (2 * mu * sd) * ((y - mu)^2 - variance)
  expected <- sqrt(sum((influence - mean(influence))^2) / (n * (n - 1)))
  actual <- e$planning_prompt_summary(y)
  tolerance <- numeric_tolerance("arithmetic", "abs_tol")
  expect_equal(actual$mcse_cv, expected, tolerance = tolerance)
  expect_equal(actual$cv_empirical, sd / mu, tolerance = tolerance)
  expect_identical(actual$boundary_share, 1 / n)
  expect_equal(e$planning_prompt_summary(8 * y), actual, tolerance = tolerance)
  constant <- e$planning_prompt_summary(rep(2, n))
  expect_identical(constant$cv_empirical, 0)
  expect_identical(constant$mcse_cv, NA_real_)
  expect_match(constant$mcse_cv_note, "undefined:", fixed = TRUE)
  expect_identical(e$planning_display(data.frame(mcse_cv = NA_real_))$mcse_cv, "undefined")
  for (bad in list(1, c(NA, 1), c(Inf, 1), c(-1, 2), c("1", "2"))) {
    expect_error(e$planning_prompt_summary(bad), "Planning prompt estimates must be finite, nonnegative and have at least two repetitions.", fixed = TRUE)
  }
  expect_error(e$planning_prompt_summary(c(0, 0)), "The empirical prompt CV is undefined.", fixed = TRUE)
})

test_that("planning CSV preserves every double and distinguishes tiny positive estimates from zero", {
  g <- planning_test_helpers(generator = TRUE)
  e <- planning_test_helpers()
  # Serialization fixture only; these are not simulation study results.
  synthetic <- data.frame(plan = "synthetic", scenario = 1L, sim = 1:4,
    estimate = c(1 + .Machine$double.eps, pi, 100 - 2^-40, 0),
    singular = c(TRUE, FALSE, TRUE, FALSE),
    prompt = c(0, .Machine$double.xmin, .Machine$double.xmin * .Machine$double.eps, 2^-40))
  a <- tempfile(fileext = ".csv.gz")
  b <- tempfile(fileext = ".csv.gz")
  g$planning_rule_csv(synthetic, a)
  g$planning_rule_csv(synthetic, b)
  expect_identical(e$planning_csv(a), synthetic)
  expect_identical(digest::digest(file = a, algo = "sha256"), digest::digest(file = b, algo = "sha256"))
  expect_identical(which(e$planning_csv(a)$prompt == 0), 1L)
})

test_that("missing and damaged planning files fail without recomputation or fallback", {
  e <- planning_test_helpers()
  directory <- planning_test_copy()
  unlink(file.path(directory, "summary.csv"))
  expect_error(e$planning_read_results(directory, repo_root = ""), "Planning validation input is missing")
  directory <- planning_test_copy()
  cat("synthetic corruption", file = file.path(directory, "replicates.csv.gz"), append = TRUE)
  expect_error(e$planning_read_results(directory, repo_root = ""), "Planning SHA-256 mismatch")
  directory <- planning_test_copy()
  unlink(file.path(directory, "anchors", "ANK-89.json"))
  expect_error(e$planning_inputs(directory, repo_root = ""), "Planning anchor directory differs from the manifest")
  directory <- planning_test_copy()
  writeLines("{broken JSON", file.path(directory, "SOURCES.json"))
  expect_error(e$planning_inputs(directory, repo_root = ""), "Cannot read planning JSON")
  expect_error(e$planning_read_results(repo_root = tempfile()), "Invalid REPO_ROOT for planning validation")
})

test_that("planning original-anchor comparisons require every requested original to match", {
  e <- planning_test_helpers()
  input <- e$planning_inputs(repo_root = "")
  root <- tempfile("synthetic-planning-repository-")
  dir.create(file.path(root, "reference", "anchors"), recursive = TRUE)
  writeLines("Package: llmsa", file.path(root, "DESCRIPTION"))
  expect_error(e$planning_inputs(repo_root = root), "Planning validation input is missing")
  for (id in names(input$manifest$anchors)) {
    entry <- input$manifest$anchors[[id]]
    original <- system.file(sub("^inst/", "", entry$copied), package = "llmsa", mustWork = TRUE)
    stopifnot(file.copy(original, file.path(root, entry$original)))
  }
  expect_identical(e$planning_inputs(repo_root = root)$mode, "full")
  cat("\n", file = file.path(root, "reference", "anchors", "ANK-06.json"), append = TRUE)
  expect_error(e$planning_inputs(repo_root = root), "Planning SHA-256 mismatch")
})

test_that("planning readers detect incomplete keys and invalid estimates beyond file hashes", {
  e <- planning_test_helpers()
  g <- planning_test_helpers(generator = TRUE)
  original <- e$planning_read_results(repo_root = "")$replicates
  bad_cases <- list(original[-1L, ], rbind(original, original[1L, ]))
  duplicate <- original; duplicate$sim[1L] <- duplicate$sim[2L]
  wrong_scenario <- original; wrong_scenario$scenario[1L] <- 2L
  unknown_plan <- original; unknown_plan$plan[1L] <- "unknown"
  missing <- original; missing$prompt[1L] <- NA_real_
  negative <- original; negative$prompt[1L] <- -1
  infinite <- original; infinite$estimate[1L] <- Inf
  outside <- original; outside$estimate[1L] <- 101
  no_flag <- original; no_flag$singular[1L] <- NA
  no_column <- original; no_column$prompt <- NULL
  bad_cases <- c(bad_cases, list(duplicate, wrong_scenario, unknown_plan, missing, negative, infinite, outside, no_flag, no_column))
  for (bad in bad_cases) {
    directory <- planning_test_copy()
    g$planning_rule_csv(bad, file.path(directory, "replicates.csv.gz"))
    # Deliberately coherent hashes for a corrupt temporary fixture: schema and
    # arithmetic validation must independently reject it.
    planning_test_rehash(directory, "replicates.csv.gz")
    expect_error(e$planning_read_results(directory, repo_root = ""),
                  "Planning replicate keys|Planning result keys|Planning replicates contain|Invalid planning result schema")
  }
})

test_that("planning readers reject altered summaries and retain all rows after permutations", {
  e <- planning_test_helpers()
  g <- planning_test_helpers(generator = TRUE)
  original <- e$planning_read_results(repo_root = "")
  for (column in c("mean", "bias", "empse", "mcse_bias", "mcse_empse", "q2.5", "median", "q97.5", "rmse",
                   "pct_singular", "pct_misclassified", "cv_empirical", "boundary_share", "mcse_boundary", "mcse_cv", "n_sim")) {
    directory <- planning_test_copy()
    bad <- original$summary
    bad[[column]][1L] <- bad[[column]][1L] + 1
    g$planning_rule_csv(bad, file.path(directory, "summary.csv"))
    planning_test_rehash(directory, "summary.csv")
    expect_error(e$planning_read_results(directory, repo_root = ""),
                  paste0("Planning summary differs from its replicates: ", column), fixed = TRUE)
  }
  directory <- planning_test_copy()
  bad <- original$summary
  bad$mean[1L] <- Inf
  g$planning_rule_csv(bad, file.path(directory, "summary.csv"))
  planning_test_rehash(directory, "summary.csv")
  expect_error(e$planning_read_results(directory, repo_root = ""), "Planning summary contains non-finite or nonnumeric values")
  bad <- original$summary
  bad$mcse_cv_method[1L] <- "unspecified"
  g$planning_rule_csv(bad, file.path(directory, "summary.csv"))
  planning_test_rehash(directory, "summary.csv")
  expect_error(e$planning_read_results(directory, repo_root = ""), "Planning CV MCSE method or explanation differs")
  set.seed(20261112)
  shuffled <- original$replicates[sample.int(nrow(original$replicates)), ]
  g$planning_rule_csv(shuffled, file.path(directory, "replicates.csv.gz"))
  g$planning_rule_csv(original$summary[4:1, ], file.path(directory, "summary.csv"))
  planning_test_rehash(directory, "replicates.csv.gz")
  planning_test_rehash(directory, "summary.csv")
  expect_identical(e$planning_read_results(directory, repo_root = "")$table, original$table)
})

test_that("planning provenance and manifest schemas reject incomplete or fabricated entries", {
  e <- planning_test_helpers()
  directory <- planning_test_copy()
  path <- file.path(directory, "SOURCES.json")
  original <- e$planning_json(path)
  invalid <- list()
  x <- original; x$schema <- 2L; invalid[[1L]] <- x
  x <- original; x$anchors <- x$anchors[-1L]; invalid[[2L]] <- x
  x <- original; x$anchors[["ANK-89"]]$copied <- "elsewhere"; invalid[[3L]] <- x
  x <- original; x$results <- x$results[-1L]; invalid[[4L]] <- x
  x <- original; x$study$designs <- x$study$designs[-1L]; invalid[[5L]] <- x
  x <- original; x$study$designs[[1L]]$n_items <- -1L; invalid[[6L]] <- x
  x <- original; x$study$n_sim <- 1L; invalid[[7L]] <- x
  x <- original; x$study$vc$prompt <- -1; invalid[[8L]] <- x
  for (bad in invalid) {
    jsonlite::write_json(bad, path, pretty = TRUE, auto_unbox = TRUE, digits = NA)
    expect_error(e$planning_read_results(directory, repo_root = ""), "[Pp]lanning")
  }
  jsonlite::write_json(original, path, pretty = TRUE, auto_unbox = TRUE, digits = NA)
  anchor_path <- file.path(directory, "anchors", "ANK-89.json")
  anchor <- e$planning_json(anchor_path)
  anchor$quote <- NULL
  jsonlite::write_json(anchor, anchor_path, pretty = TRUE, auto_unbox = TRUE, digits = NA)
  hash <- digest::digest(file = anchor_path, algo = "sha256", serialize = FALSE)
  original$anchors[["ANK-89"]]$copied_sha256 <- hash
  original$anchors[["ANK-89"]]$original_sha256 <- hash
  jsonlite::write_json(original, path, pretty = TRUE, auto_unbox = TRUE, digits = NA)
  expect_error(e$planning_inputs(directory, repo_root = ""), "Missing planning validation field: quote", fixed = TRUE)
})
