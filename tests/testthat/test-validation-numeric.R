numeric_resource_copy <- function() {
  path <- tempfile("numeric-resources-")
  dir.create(path)
  origin <- system.file("validation", "numeric", package = "llmsa", mustWork = TRUE)
  stopifnot(all(file.copy(list.files(origin, full.names = TRUE), path, recursive = TRUE)))
  path
}

numeric_write_json <- function(x, path) {
  jsonlite::write_json(x, path, auto_unbox = TRUE, pretty = TRUE, digits = NA)
}

# Trace source()/sys.source() dependencies instead of checking only the Rmd.
# An unresolved dynamic source path fails this guard and needs an explicit
# review. Verified anchors and NIST tables are the permitted numeric inputs.
numeric_documentation_sources <- function(rmd) {
  call_name <- function(x) {
    if (is.symbol(x)) return(as.character(x))
    if (is.call(x) && as.character(x[[1]]) %in% c("::", ":::")) return(as.character(x[[3]]))
    ""
  }
  pending <- rmd
  found <- character()
  while (length(pending)) {
    path <- normalizePath(pending[1], mustWork = TRUE)
    pending <- pending[-1]
    if (path %in% found) next
    found <- c(found, path)
    lines <- readLines(path, warn = FALSE)
    if (grepl("\\.Rmd$", path)) {
      # Both R chunks and inline expressions can source another helper.
      # Prose is also scanned for literals below.
      inline <- unlist(regmatches(lines, gregexpr("`r [^`]*`", lines)))
      inline <- sub("^`r ", "", sub("`$", "", inline))
      start <- grepl("^```\\{r(?:[ ,}]|$)", lines, perl = TRUE)
      close <- grepl("^```[[:space:]]*$", lines)
      active <- FALSE
      code <- logical(length(lines))
      for (i in seq_along(lines)) {
        if (start[i]) active <- TRUE else if (close[i]) active <- FALSE else code[i] <- active
      }
      lines <- c(lines[code], inline)
    }
    walk <- function(node) {
      if (missing(node)) return(invisible(NULL))
      if (is.call(node) && call_name(node[[1]]) %in% c("source", "sys.source")) {
        arg <- node[[2]]
        if (is.character(arg) && length(arg) == 1L) {
          dependency <- file.path(dirname(path), arg)
        } else if (is.call(arg) && call_name(arg[[1]]) == "system.file") {
          args <- as.list(arg)[-1L]
          if (!all(vapply(args, function(a) is.character(a) || is.logical(a), logical(1)))) {
            stop("Nonliteral system.file dependency in numeric validation.")
          }
          dependency <- do.call(system.file, args)
        } else stop("Unresolved source dependency in numeric validation.")
        if (length(dependency) != 1L || !nzchar(dependency) || !file.exists(dependency)) {
          stop("Missing numeric validation source dependency.")
        }
        pending <<- c(pending, dependency)
      }
      if (is.call(node) || is.expression(node) || is.pairlist(node)) {
        invisible(lapply(as.list(node), walk))
      }
    }
    walk(parse(text = lines))
  }
  found
}

numeric_literal_hits <- function(lines, anchors) {
  leaves <- function(x) {
    if (is.list(x)) return(unlist(lapply(x, leaves), use.names = FALSE))
    if (is.numeric(x)) return(as.numeric(x))
    numeric()
  }
  values <- leaves(lapply(anchors[c("ANK-10", "ANK-13", "ANK-14", "ANK-16")], `[[`, "value"))
  values <- values[is.finite(values) & values != round(values)]
  tolerances <- anchors[["ANK-TOL"]][["value"]][c("reml_anova", "oracle", "nist_digits", "invariance")]
  always <- leaves(lapply(tolerances, function(x) x[grepl("tol", names(x))]))
  scientific <- leaves(lapply(tolerances, function(x) x[!grepl("tol", names(x))]))
  pattern <- "(?<![A-Za-z0-9_.])(?:[0-9]+\\.[0-9]+|\\.[0-9]+|[0-9]+(?:\\.[0-9]+)?[eE][-+]?[0-9]+)(?![A-Za-z0-9_.])"
  text <- paste(lines, collapse = "\n")
  tokens <- regmatches(text, gregexpr(pattern, text, perl = TRUE))[[1]]
  hit <- vapply(tokens, function(token) {
    value <- as.numeric(token)
    digits <- nchar(sub("^0+", "", gsub("[^0-9]", "", sub("[eE].*$", "", token))))
    (digits >= 3L && any(value == values | value == signif(values, digits))) ||
      any(value == always) || (grepl("[eE]", token) && any(value == scientific))
  }, logical(1))
  unique(tokens[hit])
}

test_that("numeric validation copies and provenance are complete in the installed package", {
  e <- numeric_validation_helpers()
  resource <- system.file("validation", "numeric", package = "llmsa", mustWork = TRUE)
  manifest <- e$validation_verify_resources(resource)
  context <- e$validation_context(repo_root = "")
  anchors <- e$validation_anchors(context)
  expect_identical(context$mode, "public")
  expect_setequal(names(anchors), names(manifest$anchors))
  expect_setequal(list.files(file.path(resource, "anchors")), paste0(names(anchors), ".json"))
  expect_identical(e$validation_aiag(context, anchors), NULL)
  expect_error(e$validation_get(anchors, "ANK-TOL", "value", "missing"), "Missing validation field")
  expect_error(e$validation_tolerance(anchors, "reml_anova", "component_tol"), "Missing validation field")
  anchors[["ANK-TOL"]][["value"]][["arithmetic"]][["abs_tol"]] <- -1
  expect_error(e$validation_tolerance(anchors, "arithmetic", "abs_tol"), "Invalid validation tolerance")
})

test_that("numeric documentation copies match every reachable original anchor", {
  e <- numeric_validation_helpers()
  resource <- system.file("validation", "numeric", package = "llmsa", mustWork = TRUE)
  root <- e$validation_find_repo()
  if (is.null(root)) skip("Original-anchor comparison requires the repository (standalone tarball check).")
  expect_no_error(e$validation_verify_resources(resource, repo_root = root))
})

test_that("numeric validation rejects missing, changed and malformed copies", {
  e <- numeric_validation_helpers()
  resource <- numeric_resource_copy()
  file <- file.path(resource, "anchors", "ANK-10.json")
  unlink(file)
  expect_error(e$validation_verify_resources(resource), "Validation input is missing")
  file.copy(system.file("validation", "numeric", "anchors", "ANK-10.json", package = "llmsa"), file)
  cat("\n", file = file, append = TRUE)
  expect_error(e$validation_verify_resources(resource), "SHA-256 mismatch")

  manifest_file <- file.path(resource, "SOURCES.json")
  manifest <- e$validation_json(manifest_file)
  value <- e$validation_json(file)
  value[["quote"]] <- NULL
  numeric_write_json(value, file)
  hash <- digest::digest(file = file, algo = "sha256", serialize = FALSE)
  manifest$anchors[["ANK-10"]]$original_sha256 <- hash
  manifest$anchors[["ANK-10"]]$copied_sha256 <- hash
  numeric_write_json(manifest, manifest_file)
  expect_error(e$validation_verify_resources(resource), "Missing validation field: quote")
  manifest$anchors[["ANK-10"]] <- NULL
  numeric_write_json(manifest, manifest_file)
  expect_error(e$validation_verify_resources(resource), "manifest is incomplete")
  writeLines("invalid json", manifest_file)
  expect_error(e$validation_verify_resources(resource), "Cannot read validation JSON")
})

test_that("a specified or reachable repository never falls back after an input failure", {
  e <- numeric_validation_helpers()
  root <- tempfile("numeric-fake-repo-")
  dir.create(root)
  expect_error(e$validation_context(repo_root = root), "Invalid REPO_ROOT")
  writeLines("Package: llmsa", file.path(root, "DESCRIPTION"))
  writeLines("Synthetic repository marker", file.path(root, "AGENTS.md"))
  expect_identical(e$validation_find_repo(start = root, repo_root = ""), normalizePath(root))
  expect_error(e$validation_context(repo_root = root), "Original anchor directory is missing")
  resource <- numeric_resource_copy()
  expect_error(e$validation_verify_resources(resource, repo_root = root), "Validation input is missing")
  dir.create(file.path(root, "reference"))
  file.copy(file.path(resource, "anchors"), file.path(root, "reference"), recursive = TRUE)
  context <- e$validation_context(repo_root = root)
  anchors <- e$validation_anchors(context)
  expect_identical(context$mode, "full")
  expect_error(e$validation_aiag(context, anchors), "Validation input is missing")
  name <- names(anchors[["ANK-14"]][["value"]][["datasets"]])[1]
  expect_error(e$validation_nist(name, context, anchors), "Validation input is missing")
  path <- file.path(root, anchors[["ANK-10"]][["value"]][["data_file"]][["path"]])
  dir.create(dirname(path), recursive = TRUE)
  writeLines("Synthetic corrupt protected sheet", path)
  expect_error(e$validation_aiag(context, anchors), "SHA-256 mismatch")
  original <- file.path(root, "reference", "anchors", "ANK-TOL.json")
  cat("\n", file = original, append = TRUE)
  expect_error(e$validation_verify_resources(resource, repo_root = root), "SHA-256 mismatch")
  unlink(original)
  expect_error(e$validation_anchors(context), "Validation input is missing")
  expect_error(e$validation_verify_resources(resource, repo_root = root), "Validation input is missing")
})

test_that("public NIST tables have verified hashes, schema, compression and sizes", {
  e <- numeric_validation_helpers()
  context <- e$validation_context(repo_root = "")
  anchors <- e$validation_anchors(context)
  meta <- anchors[["ANK-14"]][["value"]][["datasets"]]
  expect_setequal(names(context$manifest$datasets), names(meta))
  limits <- anchors[["ANK-TOL"]][["value"]][["data_size"]]
  files <- list.files(context$nist, full.names = TRUE)
  expect_true(all(file.info(files)$size <= limits[["file_max_bytes"]]))
  expect_lte(sum(file.info(files)$size), limits[["folder_max_bytes"]])
  sums <- strsplit(readLines(file.path(context$nist, "SHA256SUMS")), "  ", fixed = TRUE)
  expect_setequal(vapply(sums, `[[`, character(1), 2L), setdiff(basename(files), "SHA256SUMS"))
  for (entry in sums) expect_no_error(e$validation_hash(file.path(context$nist, entry[2]), entry[1]))
  for (name in names(meta)) {
    d <- e$validation_nist(name, context, anchors)
    expect_identical(names(d), c("treatment", "rep", "value"))
    expect_equal(nrow(d), meta[[name]][["observations"]])
    file <- file.path(context$nist, basename(context$manifest$datasets[[name]]$copied))
    if (endsWith(file, ".gz")) {
      header <- readBin(file, "raw", n = 10L)
      expect_identical(header[5:8], rep(as.raw(0), 4L))
      expect_identical(header[10], as.raw(255))
    } else expect_lte(file.info(file)$size, limits[["gzip_above_bytes"]])
  }
  broken <- tempfile("numeric-corrupt-nist-")
  dir.create(broken)
  name <- names(meta)[1]
  file <- file.path(broken, basename(context$manifest$datasets[[name]]$copied))
  writeLines("treatment,rep,value\nsynthetic,1,0", file)
  context$nist <- broken
  expect_error(e$validation_nist(name, context, anchors), "SHA-256 mismatch")
  context$manifest$datasets[[name]]$copied_sha256 <- digest::digest(file = file, algo = "sha256", serialize = FALSE)
  expect_error(e$validation_nist(name, context, anchors), "schema or design differs")
})

test_that("AIAG presentation exposes aggregate statistics and marks public rows as not rerun", {
  e <- numeric_validation_helpers()
  anchors <- e$validation_anchors(e$validation_context(repo_root = ""))
  public <- e$validation_aiag_table(anchors)
  expect_true(all(public$Observed == "not rerun: protected data required"))
  expect_true(all(public$Result == "NOT RERUN"))
  expect_identical(names(public), c("Anchor", "Source", "Quantity", "Expected", "Observed", "Tolerance", "Result"))
  pub <- anchors[["ANK-10"]][["value"]]
  for (kind in c("variance", "sd", "pct_study_var", "pct_contribution")) for (key in names(pub[[kind]])) {
    expect_identical(public$Expected[public$Quantity == paste(key, kind)], e$validation_format(pub[[kind]][[key]]))
  }
  synthetic <- list(table = data.frame(source = c("Repeatability", "Reproducibility", "Total gauge R&R",
    "Part-to-part (items)", "Total variation"), variance = 0, sd = 0, pct_study_var = 0, pct_contribution = 0),
    summary = list(ndc = 0), raw_measurements = "DO_NOT_PUBLISH_SYNTHETIC_SENTINEL")
  full <- e$validation_aiag_table(anchors, synthetic)
  expect_identical(full$Expected, public$Expected)
  expect_true(any(full$Result == "FAIL"))
  expect_false(any(grepl(synthetic$raw_measurements, unlist(full), fixed = TRUE)))
  expect_false(any(grepl("part|appraiser|trial|raw", names(full))))
  expect_identical(e$validation_compare("synthetic", "algebra", "square", 2, -2, 0, squared = TRUE)$Result, "PASS")
  expect_identical(e$validation_compare("synthetic", "algebra", "missing", 2, NA_real_, 0)$Result, "FAIL")
})

test_that("the vignette and every sourced helper read reference numbers from anchors", {
  e <- numeric_validation_helpers()
  root <- e$validation_find_repo()
  rmd <- if (is.null(root)) system.file("doc", "validation.Rmd", package = "llmsa", mustWork = TRUE) else
    file.path(root, "vignettes", "validation.Rmd")
  sources <- numeric_documentation_sources(rmd)
  expect_true(system.file("validation", "numeric", "reference_checks.R", package = "llmsa", mustWork = TRUE) %in% sources)
  anchors <- e$validation_anchors(e$validation_context(repo_root = ""))
  for (path in sources) expect_identical(numeric_literal_hits(readLines(path, warn = FALSE), anchors), character(), info = path)
  # The guard itself must recognize a copied empirical value and tolerance.
  sample <- anchors[["ANK-10"]][["value"]][["sd"]][["EV"]]
  bound <- anchors[["ANK-TOL"]][["value"]][["reml_anova"]][["derived_rel_tol"]]
  expect_length(numeric_literal_hits(format(sample, digits = 15, scientific = TRUE), anchors), 1L)
  expect_length(numeric_literal_hits(format(bound, digits = 15, scientific = TRUE), anchors), 1L)
  dependency <- tempfile(fileext = ".R")
  writeLines("source(paste0('dynamic', '.R'))", dependency)
  expect_error(numeric_documentation_sources(dependency), "Unresolved source dependency")
  inline <- tempfile(fileext = ".Rmd")
  writeLines("`r source(paste0('dynamic', '.R'))`", inline)
  expect_error(numeric_documentation_sources(inline), "Unresolved source dependency")
})
