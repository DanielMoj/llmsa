#!/usr/bin/env Rscript
# Copy complete reviewer anchors, retaining their bytes and source provenance.
# Usage: Rscript data-raw/make_validation_m1d.R [--out <package-root>]

make_validation_m1d <- function(root, out = root) {
  for (p in c("jsonlite", "digest")) {
    if (!requireNamespace(p, quietly = TRUE)) stop("Required package is missing: ", p, call. = FALSE)
  }
  root <- normalizePath(root, mustWork = TRUE)
  sys.source(file.path(root, "inst", "validation", "m1d", "prepare.R"), envir = environment())
  ids <- c("ANK-06", sprintf("ANK-%02d", 40:47), "ANK-63", "ANK-TOL")
  for (id in ids) m1d_anchor(root, id)
  stage <- tempfile("llmsa-m1d-anchors-")
  dir.create(file.path(stage, "anchors"), recursive = TRUE)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  manifest <- list(schema = 1L, generator = "data-raw/make_validation_m1d.R", anchors = list())
  for (id in ids) {
    name <- paste0(id, ".json")
    from <- file.path(root, "reference", "anchors", name)
    copy <- file.path(stage, "anchors", name)
    if (!file.copy(from, copy) || !identical(m1d_sha256(from), m1d_sha256(copy))) m1d_abort("anchor copy differs: ", id)
    manifest$anchors[[id]] <- list(original = paste0("reference/anchors/", name),
      copied = paste0("inst/validation/m1d/anchors/", name),
      original_sha256 = m1d_sha256(from), copied_sha256 = m1d_sha256(copy))
  }
  m1d_write_text(jsonlite::toJSON(manifest, pretty = TRUE, auto_unbox = TRUE), file.path(stage, "SOURCES.json"))
  target <- file.path(out, "inst", "validation", "m1d")
  dir.create(file.path(target, "anchors"), recursive = TRUE, showWarnings = FALSE)
  for (name in c("SOURCES.json", file.path("anchors", paste0(ids, ".json")))) {
    if (!file.copy(file.path(stage, name), file.path(target, name), overwrite = TRUE)) m1d_abort("cannot publish anchor: ", name)
  }
  cat("M1d validation inputs: ", length(ids), " byte-identical anchors; SHA-256 provenance recorded\n", sep = "")
  invisible(manifest)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) && (length(args) != 2L || args[1L] != "--out" || !nzchar(args[2L]))) {
    stop("Usage: make_validation_m1d.R [--out <package-root>]", call. = FALSE)
  }
  script <- sub("^--file=", "", commandArgs()[startsWith(commandArgs(), "--file=")])
  root <- dirname(dirname(normalizePath(script, mustWork = TRUE)))
  make_validation_m1d(root, if (length(args)) args[2L] else root)
}
