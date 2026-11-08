#!/usr/bin/env Rscript
# Copy the used planning anchor and record hashes of reused installed anchors.
# Usage: Rscript data-raw/make_validation_planning.R [--out <package-root>]

make_validation_planning <- function(root, out = root) {
  for (package in c("jsonlite", "digest")) {
    if (!requireNamespace(package, quietly = TRUE)) stop("Required package is missing: ", package, call. = FALSE)
  }
  root <- normalizePath(root, mustWork = TRUE)
  locations <- c("ANK-89" = "planning", "ANK-06" = "latent", "ANK-16" = "numeric", "ANK-TOL" = "numeric")
  stage <- tempfile("planning-anchors-")
  dir.create(file.path(stage, "anchors"), recursive = TRUE)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  hash <- function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE)
  manifest <- list(schema = 1L, preparation = "data-raw/make_validation_planning.R", anchors = list())
  for (id in names(locations)) {
    name <- paste0(id, ".json")
    original <- file.path(root, "reference", "anchors", name)
    if (!file.exists(original)) stop("Original planning anchor is missing: ", original, call. = FALSE)
    a <- jsonlite::fromJSON(original, simplifyVector = FALSE)
    fields <- c("value", "unit", "tolerance", "source_url", "quote", "retrieved")
    if (!identical(a$id, id) || any(vapply(fields, function(k) is.null(a[[k]]), logical(1)))) {
      stop("Invalid original planning anchor: ", id, call. = FALSE)
    }
    copied <- file.path("inst", "validation", locations[[id]], "anchors", name)
    destination <- if (id == "ANK-89") file.path(stage, "anchors", name) else file.path(root, copied)
    if (id == "ANK-89" && !file.copy(original, destination)) stop("Cannot copy planning anchor: ", id, call. = FALSE)
    if (!file.exists(destination)) stop("Reused validation anchor is missing: ", destination, call. = FALSE)
    original_hash <- hash(original)
    copied_hash <- hash(destination)
    if (!identical(original_hash, copied_hash)) stop("Planning anchor copy differs: ", id, call. = FALSE)
    manifest$anchors[[id]] <- list(original = file.path("reference", "anchors", name), copied = copied,
                                   original_sha256 = original_hash, copied_sha256 = copied_hash)
  }
  jsonlite::write_json(manifest, file.path(stage, "SOURCES.json"), auto_unbox = TRUE, pretty = TRUE)
  target <- file.path(out, "inst", "validation", "planning")
  dir.create(file.path(target, "anchors"), recursive = TRUE, showWarnings = FALSE)
  for (name in c("anchors/ANK-89.json", "SOURCES.json")) {
    if (!file.copy(file.path(stage, name), file.path(target, name), overwrite = TRUE)) {
      stop("Cannot publish planning anchor resource: ", name, call. = FALSE)
    }
  }
  cat("Planning inputs: 1 byte-identical anchor; 3 existing anchor copies reused; SHA-256 provenance recorded.\n")
  invisible(manifest)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) && (length(args) != 2L || args[1L] != "--out" || !nzchar(args[2L]))) {
    stop("Usage: make_validation_planning.R [--out <package-root>]", call. = FALSE)
  }
  script <- sub("^--file=", "", commandArgs()[startsWith(commandArgs(), "--file=")])
  root <- dirname(dirname(normalizePath(script, mustWork = TRUE)))
  make_validation_planning(root, if (length(args)) args[2L] else root)
}
