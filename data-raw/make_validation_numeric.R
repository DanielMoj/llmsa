#!/usr/bin/env Rscript
# Reproduce the public numeric validation inputs from verified local sources.
# Usage: Rscript data-raw/make_validation_numeric.R [--out <package-root>]

make_validation_numeric <- function(root, out = root) {
  for (package in c("jsonlite", "digest")) {
    if (!requireNamespace(package, quietly = TRUE)) stop("Required package is missing: ", package)
  }
  root <- normalizePath(root, mustWork = TRUE)
  field <- function(x, ...) {
    keys <- c(...)
    for (key in keys) {
      x <- x[[key]]
      if (is.null(x)) stop("Missing validation input field: ", paste(keys, collapse = "$"), call. = FALSE)
    }
    x
  }
  hash <- function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE)
  required <- c("ANK-10", "ANK-13", "ANK-14", "ANK-16", "ANK-TOL")
  anchors <- stats::setNames(lapply(required, function(id) {
    path <- file.path(root, "reference", "anchors", paste0(id, ".json"))
    if (!file.exists(path)) stop("Original validation anchor is missing: ", path, call. = FALSE)
    x <- jsonlite::fromJSON(path, simplifyVector = FALSE)
    if (!identical(x[["id"]], id)) stop("Incorrect anchor ID in ", path, call. = FALSE)
    for (key in c("value", "unit", "tolerance", "source_url", "quote", "retrieved")) field(x, key)
    x
  }), required)
  limits <- field(anchors, "ANK-TOL", "value", "data_size")
  for (key in c("file_max_bytes", "gzip_above_bytes", "folder_max_bytes", "extdata_total_max_bytes")) {
    value <- field(limits, key)
    if (!is.numeric(value) || length(value) != 1L || !is.finite(value) || value <= 0) {
      stop("Invalid data size limit: ", key, call. = FALSE)
    }
  }
  folder <- "nist-strd-anova_2026-10-22"
  originals <- file.path(dirname(root), "quellen", "daten", folder)
  if (!dir.exists(originals)) stop("Local NIST source directory is missing: ", originals, call. = FALSE)
  metadata <- field(anchors, "ANK-14", "value", "datasets")
  datasets <- lapply(metadata, function(meta) {
    path <- file.path(originals, field(meta, "file"))
    if (!file.exists(path)) stop("Local NIST source is missing: ", path, call. = FALSE)
    if (!identical(hash(path), field(meta, "sha256")) || file.info(path)$size != field(meta, "bytes")) {
      stop("NIST source hash or size differs from ANK-14: ", path, call. = FALSE)
    }
    lines <- readLines(path, warn = FALSE)
    span <- as.integer(unlist(field(meta, "data_lines")))
    if (length(span) != 2L || anyNA(span) || span[1] < 1L || span[2] > length(lines) || span[1] > span[2]) {
      stop("Invalid NIST data line range: ", path, call. = FALSE)
    }
    tokens <- strsplit(trimws(lines[seq.int(span[1], span[2])]), "[[:space:]]+")
    if (any(lengths(tokens) != 2L)) stop("Malformed NIST data row: ", path, call. = FALSE)
    treatment <- vapply(tokens, `[[`, character(1), 1L)
    value <- vapply(tokens, `[[`, character(1), 2L)
    number <- "^[+-]?[0-9]+(?:\\.[0-9]*)?(?:[Ee][+-]?[0-9]+)?$"
    if (!all(grepl("^[0-9]+$", treatment)) || !all(grepl(number, value, perl = TRUE)) ||
        any(!is.finite(as.numeric(value))) || length(value) != field(meta, "observations") ||
        length(unique(treatment)) != field(meta, "treatments") ||
        any(table(treatment) != field(meta, "replicates_per_cell"))) {
      stop("NIST schema or design differs from ANK-14: ", path, call. = FALSE)
    }
    replicate <- stats::ave(seq_along(treatment), treatment, FUN = seq_along)
    # Keep the original decimal tokens, without a double-to-text round trip.
    bytes <- charToRaw(paste0(paste(c("treatment,rep,value", paste(treatment, replicate, value, sep = ",")),
                                    collapse = "\n"), "\n"))
    list(bytes = bytes, meta = meta)
  })

  # Validate every source before staging or publishing any package input.
  stage <- tempfile("llmsa-numeric-inputs-")
  dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  data_relative <- file.path("inst", "extdata", folder)
  resource_relative <- file.path("inst", "validation", "numeric")
  data_stage <- file.path(stage, data_relative)
  resource_stage <- file.path(stage, resource_relative)
  dir.create(data_stage, recursive = TRUE)
  dir.create(file.path(resource_stage, "anchors"), recursive = TRUE)
  manifest <- list(schema = 1L, generator = "data-raw/make_validation_numeric.R",
                   anchors = list(), datasets = list())
  for (id in required) {
    original <- file.path("reference", "anchors", paste0(id, ".json"))
    copied <- file.path(resource_relative, "anchors", paste0(id, ".json"))
    if (!file.copy(file.path(root, original), file.path(stage, copied))) stop("Cannot copy anchor: ", id)
    original_hash <- hash(file.path(root, original))
    copied_hash <- hash(file.path(stage, copied))
    if (!identical(original_hash, copied_hash)) stop("Anchor copy is not byte-identical: ", id)
    manifest$anchors[[id]] <- list(original = original, copied = copied,
                                   original_sha256 = original_hash, copied_sha256 = copied_hash)
  }
  for (name in names(datasets)) {
    data <- datasets[[name]]
    compressed <- length(data$bytes) > limits[["gzip_above_bytes"]]
    filename <- paste0(name, if (compressed) ".csv.gz" else ".csv")
    path <- file.path(data_stage, filename)
    if (compressed) {
      connection <- gzfile(path, open = "wb", compression = 9)
      tryCatch(writeBin(data$bytes, connection), finally = close(connection))
      bytes <- readBin(path, "raw", n = file.info(path)$size)
      if (!identical(bytes[1:4], as.raw(c(31, 139, 8, 0)))) stop("Unexpected gzip header: ", name)
      bytes[5:8] <- as.raw(0)   # no timestamp
      bytes[10] <- as.raw(255)  # no host operating-system marker
      writeBin(bytes, path)
    } else writeBin(data$bytes, path)
    manifest$datasets[[name]] <- list(
      original = file.path("..", "quellen", "daten", folder, data$meta[["file"]]),
      original_sha256 = data$meta[["sha256"]], copied = file.path(data_relative, filename),
      copied_sha256 = hash(path), url = data$meta[["url"]], license = "Public domain (NIST)",
      columns = c("treatment", "rep", "value"), observations = data$meta[["observations"]])
  }
  provenance <- c(
    "NIST Statistical Reference Datasets: one-way analysis of variance",
    "Source: https://www.itl.nist.gov/div898/strd/anova/anova.html",
    "Frozen source collection: 2026-10-22. License: public domain (NIST).",
    "Selection: all numeric data rows of the eleven datasets declared in ANK-14.",
    "Columns: treatment, replicate within treatment, measured value.",
    "Mapping: treatment -> item; one prompt, model and block.",
    "Original decimal tokens and row order are preserved; source text is excluded.",
    "No fitted values, variance estimates or oracle outputs are stored here.",
    "Generator: Rscript data-raw/make_validation_numeric.R [--out <package-root>]",
    "Local originals: ../quellen/daten/nist-strd-anova_2026-10-22/",
    "Authority: reference/anchors/ANK-14.json; sizes: reference/anchors/ANK-TOL.json.",
    "Source and stored-file hashes are also recorded in inst/validation/numeric/SOURCES.json.",
    "Stored-file hashes below exclude SHA256SUMS itself.", "",
    unlist(lapply(names(datasets), function(name) {
      meta <- datasets[[name]]$meta
      c(paste0(name, ": ", meta[["url"]]), paste0("Source SHA-256: ", meta[["sha256"]]))
    })))
  writeLines(provenance, file.path(data_stage, "QUELLE.txt"), useBytes = TRUE)
  files <- sort(list.files(data_stage), method = "radix")
  writeLines(vapply(files, function(file) paste0(hash(file.path(data_stage, file)), "  ", file), character(1)),
             file.path(data_stage, "SHA256SUMS"), useBytes = TRUE)
  jsonlite::write_json(manifest, file.path(resource_stage, "SOURCES.json"),
                       auto_unbox = TRUE, pretty = TRUE, digits = NA)
  sizes <- file.info(list.files(data_stage, full.names = TRUE))$size
  existing <- list.files(file.path(out, "inst", "extdata"), full.names = TRUE, recursive = TRUE)
  replaced <- file.path(out, data_relative)
  existing <- existing[!startsWith(existing, paste0(replaced, .Platform$file.sep))]
  total <- sum(sizes) + sum(file.info(existing)$size)
  if (any(sizes > limits[["file_max_bytes"]]) || sum(sizes) > limits[["folder_max_bytes"]] ||
      total > limits[["extdata_total_max_bytes"]]) stop("Numeric validation inputs exceed ANK-TOL.data_size.")
  for (relative in list.files(stage, recursive = TRUE, all.files = TRUE, no.. = TRUE)) {
    destination <- file.path(out, relative)
    dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
    if (!file.copy(file.path(stage, relative), destination, overwrite = TRUE)) {
      stop("Cannot publish validation input: ", destination)
    }
  }
  cat(sprintf("Numeric validation inputs: %d NIST tables; %d byte-identical anchors; %d stored data bytes\n",
               length(datasets), length(required), sum(sizes)))
  invisible(manifest)
}

if (sys.nframe() == 0L) {
  script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
  if (length(script) != 1L) stop("Run this generator with Rscript.")
  root <- dirname(dirname(normalizePath(script, mustWork = TRUE)))
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) && (length(args) != 2L || args[1] != "--out")) {
    stop("Usage: Rscript data-raw/make_validation_numeric.R [--out <package-root>]")
  }
  make_validation_numeric(root, if (length(args)) args[2] else root)
}
