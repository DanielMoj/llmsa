test_that("latent anchor copies and both tolerance copies retain complete provenance", {
  e <- latent_test_helpers()
  context <- e$latent_context(repo_root = "")
  anchors <- e$latent_anchors(context)
  expect_identical(context$mode, "public")
  expect_setequal(names(anchors), e$latent_anchor_ids)
  expect_setequal(list.files(file.path(context$resource_dir, "anchors")), paste0(e$latent_anchor_ids, ".json"))
  expect_identical(anchors[["ANK-TOL"]][["value"]], numeric_anchor("ANK-TOL"))
  numeric_path <- system.file("validation", "numeric", "anchors", "ANK-TOL.json", package = "llmsa", mustWork = TRUE)
  expect_identical(digest::digest(file = numeric_path, algo = "sha256", serialize = FALSE),
    context$manifest$anchors[["ANK-TOL"]]$copied_sha256)
  expect_error(e$latent_get(anchors, "ANK-TOL", "missing"), "Missing latent validation field")
  anchors[["ANK-TOL"]]$value$arithmetic$abs_tol <- -1
  expect_error(e$latent_tolerance(anchors, "arithmetic", "abs_tol"), "Invalid latent validation tolerance")
})

test_that("latent copies match the original anchors when the repository is available", {
  e <- latent_test_helpers()
  root <- numeric_validation_helpers()$validation_find_repo()
  if (is.null(root)) skip("Original-anchor comparison requires the repository (standalone tarball check).")
  expect_no_error(e$latent_context(repo_root = root))
})

test_that("latent validation never falls back from missing or corrupted requested originals", {
  e <- latent_test_helpers()
  root <- tempfile("synthetic-repository-")
  dir.create(root)
  expect_error(e$latent_context(repo_root = root), "Invalid REPO_ROOT")
  writeLines("Package: llmsa", file.path(root, "DESCRIPTION"))
  dir.create(file.path(root, "reference", "anchors"), recursive = TRUE)
  expect_error(e$latent_context(repo_root = root), "input is missing")
  source <- system.file("validation", "latent", "anchors", package = "llmsa", mustWork = TRUE)
  stopifnot(all(file.copy(list.files(source, full.names = TRUE), file.path(root, "reference", "anchors"))))
  expect_identical(e$latent_context(repo_root = root)$mode, "full")
  cat("\n", file = file.path(root, "reference", "anchors", "ANK-28.json"), append = TRUE)
  expect_error(e$latent_context(repo_root = root), "SHA-256 mismatch")
})

test_that("latent resources reject altered files, malformed schemas and extra entries", {
  e <- latent_test_helpers()
  resource <- latent_test_resource_copy()
  original <- file.path(resource, "anchors", "ANK-28.json")
  manifest_path <- file.path(resource, "SOURCES.json")
  raw <- readBin(original, "raw", n = file.info(original)$size)
  unlink(original)
  expect_error(e$latent_verify_resources(resource), "directory differs from the manifest")
  writeBin(raw, original)
  cat("\n", file = original, append = TRUE)
  expect_error(e$latent_verify_resources(resource), "SHA-256 mismatch")
  writeBin(raw, original)
  writeLines("synthetic extra file", file.path(resource, "anchors", "extra.txt"))
  expect_error(e$latent_verify_resources(resource), "directory differs from the manifest")
  unlink(file.path(resource, "anchors", "extra.txt"))
  manifest <- e$latent_json(manifest_path)
  anchor <- e$latent_json(original)
  anchor$quote <- NULL
  jsonlite::write_json(anchor, original, auto_unbox = TRUE, digits = NA)
  hash <- digest::digest(file = original, algo = "sha256", serialize = FALSE)
  manifest$anchors[["ANK-28"]]$original_sha256 <- hash
  manifest$anchors[["ANK-28"]]$copied_sha256 <- hash
  jsonlite::write_json(manifest, manifest_path, auto_unbox = TRUE, digits = NA)
  expect_error(e$latent_verify_resources(resource), "Missing latent validation field: quote", fixed = TRUE)
  manifest$anchors <- manifest$anchors[-1L]
  jsonlite::write_json(manifest, manifest_path, auto_unbox = TRUE)
  expect_error(e$latent_verify_resources(resource), "manifest is incomplete")
  writeLines("{not JSON", manifest_path)
  expect_error(e$latent_verify_resources(resource), "Cannot read latent validation JSON")
})

test_that("live latent reference checks separate ICC from published installation estimates", {
  skip_if_not_installed("rptR")
  skip_if_not_installed("performance")
  e <- latent_test_helpers()
  checked <- e$latent_reference_checks(e$latent_anchors(e$latent_context(repo_root = "")))
  for (name in c("wine", "ordinal_installation", "binary", "rptr_installation")) {
    expect_true(all(checked[[name]]$Result == "PASS"), info = name)
    expect_true(all(is.finite(checked[[name]]$Expected) & is.finite(checked[[name]]$Observed)))
  }
  expect_false(any(grepl("ANK-25", checked$binary$Anchor, fixed = TRUE)))
  expect_true(all(grepl("ANK-25", checked$rptr_installation$Anchor, fixed = TRUE)))
  expect_setequal(checked$rptr_installation$Quantity, c("R_link", "R_org"))
  expect_identical(e$latent_compare("synthetic", "algebra", "square", 1, 2, 0)$Result, "FAIL")
  expect_error(e$latent_compare("synthetic", "algebra", "missing", 1, NA_real_, 0), "Non-finite latent comparison")
})

test_that("result readers prefer full files and reject invalid existing full files", {
  e <- latent_test_helpers(TRUE)
  directory <- tempfile("synthetic-results-")
  dir.create(directory)
  study <- "two_level"
  # A reader fixture exercises selection and schema only, never recovery.
  fixture <- do.call(rbind, lapply(e$sim_scenarios(study), function(s) {
    targets <- names(e$sim_truth(s))
    d <- expand.grid(estimand = targets, measure = c("bias", "rel_bias", "empse", "rmse"), stringsAsFactors = FALSE)
    d <- rbind(d, data.frame(estimand = "model", measure = "derived_share"))
    data.frame(scenario = s$id, d, value = seq_len(nrow(d)) / 10000,
      mcse = 1 / 100000, n_sim = 7L, seed = e$sim_seed(s, 1L))
  }))
  short_path <- file.path(directory, paste0(study, "_check_results.csv"))
  full_path <- file.path(directory, paste0(study, "_results.csv"))
  utils::write.csv(fixture, short_path, row.names = FALSE)
  expect_identical(e$latent_read_results(study, directory)$mode, "check")
  full <- fixture
  full$n_sim <- 11L; full$value <- full$value + 1 / 2
  utils::write.csv(full, full_path, row.names = FALSE)
  read <- e$latent_read_results(study, directory)
  expect_identical(read$mode, "full")
  expect_identical(read$n_sim, 11L)
  expect_equal(read$data$value, full$value, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  invalid <- list(full[-1L, ], rbind(full, full[1L, ]), full[full$scenario == "S-two-1", ], full[, -4L])
  negative <- full; negative$mcse[1L] <- -1
  not_finite <- full; not_finite$value[1L] <- Inf
  bad_n <- full; bad_n$n_sim[1L] <- 1
  for (bad in c(invalid, list(negative, not_finite, bad_n))) {
    utils::write.csv(bad, full_path, row.names = FALSE)
    expect_error(e$latent_read_results(study, directory))
  }
  unlink(c(full_path, short_path))
  expect_error(e$latent_read_results(study, directory), "results are missing")
  expect_error(e$latent_read_results("unknown", directory), "Unknown latent study")
})

test_that("latent display retains significant digits and documentation traces every source", {
  e <- latent_test_helpers()
  small <- data.frame(value = c(1 / 10^8, 1234567 / 10^14), mcse = c(1 / 10^9, 1 / 10^12))
  display <- e$latent_display(small)
  expect_true(all(as.numeric(display$value) > 0))
  expect_true(all(as.numeric(display$mcse) > 0))
  rmd <- system.file("doc", "validation.Rmd", package = "llmsa")
  if (!nzchar(rmd)) rmd <- file.path(test_path("..", ".."), "vignettes", "validation.Rmd")
  expect_true(file.exists(rmd))
  sources <- latent_test_documentation_sources(rmd)
  expect_true(normalizePath(system.file("validation", "latent", "reference_checks.R", package = "llmsa", mustWork = TRUE),
                            mustWork = TRUE) %in% sources)
  leaves <- function(x) if (is.list(x)) unlist(lapply(x, leaves), use.names = FALSE) else if (is.numeric(x)) x else numeric()
  anchors <- e$latent_anchors(e$latent_context(repo_root = ""))
  values <- leaves(lapply(anchors[c("ANK-21", "ANK-25", "ANK-28")], `[[`, "value"))
  for (study in e$latent_studies) {
    result <- e$latent_read_results(study)$data
    values <- c(values, result$value, result$mcse)
  }
  for (path in sources) {
    expect_identical(latent_test_literal_hits(readLines(path, warn = FALSE), values), character(), info = path)
  }
  injected <- format(e$latent_get(anchors, "ANK-28", "value", "logit"), digits = 15L, scientific = TRUE)
  expect_length(latent_test_literal_hits(paste0("`r ", injected, "`"), values), 1L)
  directory <- tempfile("synthetic-documentation-"); dir.create(directory)
  file <- file.path(directory, "test.Rmd")
  writeLines(c("```{r}", "source('child.R')", "```"), file)
  writeLines(paste0("x <- ", injected), file.path(directory, "child.R"))
  tree <- latent_test_documentation_sources(file)
  expect_length(tree, 2L)
  expect_length(latent_test_literal_hits(readLines(tree[2L]), values), 1L)
  writeLines("`r source(dynamic_path)`", file)
  expect_error(latent_test_documentation_sources(file), "Unresolved documentation dependency")
})
