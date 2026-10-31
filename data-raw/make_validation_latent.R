#!/usr/bin/env Rscript
# Copy complete reviewer anchors for offline, installed latent validation.
# Usage: Rscript data-raw/make_validation_latent.R [--out <package-root>]

make_validation_latent <- function(root, out = root) {
  for (package in c("jsonlite", "digest")) {
    if (!requireNamespace(package, quietly = TRUE)) stop("Required package is missing: ", package)
  }
  root <- normalizePath(root, mustWork = TRUE)
  ids <- c("ANK-06", "ANK-21", "ANK-25", "ANK-28", "ANK-TOL")
  paths <- file.path(root, "reference", "anchors", paste0(ids, ".json"))
  for (i in seq_along(paths)) {
    if (!file.exists(paths[i])) stop("Original latent anchor is missing: ", paths[i], call. = FALSE)
    a <- jsonlite::fromJSON(paths[i], simplifyVector = FALSE)
    fields <- c("id", "value", "unit", "tolerance", "source_url", "quote", "retrieved")
    if (!identical(a[["id"]], ids[i]) || any(vapply(fields, function(k) is.null(a[[k]]), logical(1)))) {
      stop("Invalid original latent anchor: ", ids[i], call. = FALSE)
    }
  }
  stage <- tempfile("llmsa-latent-inputs-")
  dir.create(file.path(stage, "anchors"), recursive = TRUE)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  hash <- function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE)
  manifest <- list(schema = 1L, generator = "data-raw/make_validation_latent.R", anchors = list())
  for (i in seq_along(ids)) {
    name <- paste0(ids[i], ".json")
    copy <- file.path(stage, "anchors", name)
    if (!file.copy(paths[i], copy)) stop("Cannot copy latent anchor: ", ids[i])
    original_hash <- hash(paths[i])
    copied_hash <- hash(copy)
    if (!identical(original_hash, copied_hash)) stop("Latent anchor copy differs: ", ids[i])
    manifest$anchors[[ids[i]]] <- list(original = file.path("reference", "anchors", name),
      copied = file.path("inst", "validation", "latent", "anchors", name),
      original_sha256 = original_hash, copied_sha256 = copied_hash)
  }
  jsonlite::write_json(manifest, file.path(stage, "SOURCES.json"), pretty = TRUE, auto_unbox = TRUE)
  target <- file.path(out, "inst", "validation", "latent")
  dir.create(file.path(target, "anchors"), recursive = TRUE, showWarnings = FALSE)
  for (name in c("SOURCES.json", file.path("anchors", paste0(ids, ".json")))) {
    if (!file.copy(file.path(stage, name), file.path(target, name), overwrite = TRUE)) {
      stop("Cannot publish latent validation input: ", name, call. = FALSE)
    }
  }
  cat("Latent validation inputs: ", length(ids), " byte-identical anchors; SHA-256 provenance recorded\n", sep = "")
  invisible(manifest)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) && (length(args) != 2L || args[1L] != "--out" || !nzchar(args[2L]))) {
    stop("Usage: make_validation_latent.R [--out <package-root>]", call. = FALSE)
  }
  script <- sub("^--file=", "", commandArgs()[startsWith(commandArgs(), "--file=")])
  root <- dirname(dirname(normalizePath(script, mustWork = TRUE)))
  make_validation_latent(root, if (length(args)) args[2L] else root)
}
