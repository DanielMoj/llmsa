rework_resource_copy <- function() {
  resource <- tempfile("rework-resources-")
  dir.create(resource)
  origin <- system.file("validation", "numeric", package = "llmsa", mustWork = TRUE)
  stopifnot(all(file.copy(list.files(origin, full.names = TRUE), resource, recursive = TRUE)))
  resource
}

test_that("the validation manifest rejects extra anchors and missing or unexpected datasets", {
  e <- numeric_validation_helpers()
  resource <- rework_resource_copy()
  on.exit(unlink(resource, recursive = TRUE), add = TRUE)
  path <- file.path(resource, "SOURCES.json")
  original <- e$validation_json(path)
  write <- function(manifest) jsonlite::write_json(manifest, path, auto_unbox = TRUE, pretty = TRUE, digits = NA)
  expect_identical(e$validation_verify_resources(resource), original)
  extra <- file.path(resource, "anchors", "ANK-99.json")
  writeLines("{}", extra)
  rework_error(e$validation_verify_resources(resource), "Numeric anchor directory differs from the manifest.")
  unlink(extra)
  bad <- original
  bad$datasets <- NULL
  write(bad)
  rework_error(e$validation_verify_resources(resource), "Missing validation field: datasets")
  for (change in c("missing", "extra", "duplicate")) {
    bad <- original
    if (change == "missing") bad$datasets[[1L]] <- NULL
    if (change == "extra") bad$datasets$unexpected <- bad$datasets[[1L]]
    if (change == "duplicate") bad$datasets <- c(bad$datasets, bad$datasets[1L])
    write(bad)
    rework_error(e$validation_verify_resources(resource), "Numeric dataset manifest differs from ANK-14.")
  }
})

test_that("dataset provenance and stored bytes are verified before validation calculations", {
  e <- numeric_validation_helpers()
  resource <- rework_resource_copy()
  data <- tempfile("rework-nist-")
  dir.create(data)
  origin <- system.file("extdata", "nist-strd-anova_2026-10-22", package = "llmsa", mustWork = TRUE)
  stopifnot(all(file.copy(list.files(origin, full.names = TRUE), data)))
  on.exit(unlink(c(resource, data), recursive = TRUE), add = TRUE)
  path <- file.path(resource, "SOURCES.json")
  original <- e$validation_json(path)
  write <- function(manifest) jsonlite::write_json(manifest, path, auto_unbox = TRUE, pretty = TRUE, digits = NA)
  name <- names(original$datasets)[1L]
  for (field in c("original_sha256", "copied")) {
    bad <- original
    bad$datasets[[name]][[field]] <- "invalid"
    write(bad)
    rework_error(e$validation_verify_resources(resource, data_dir = data), paste0("Invalid numeric dataset provenance: ", name))
  }
  write(original)
  expect_identical(e$validation_verify_resources(resource, data_dir = data), original)
  copied <- file.path(data, basename(original$datasets[[name]]$copied))
  cat("\n", file = copied, append = TRUE)
  rework_error(e$validation_verify_resources(resource, data_dir = data), paste0("Validation SHA-256 mismatch: ", copied))
  unlink(copied)
  rework_error(e$validation_verify_resources(resource, data_dir = data), paste0("Validation input is missing: ", copied))
  # The public context must honour its explicit data directory as well.
  rework_error(e$validation_context(repo_root = "", resource_dir = resource, data_dir = data),
               paste0("Validation input is missing: ", copied))
})
