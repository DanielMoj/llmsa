# All generated runs in these tests are small synthetic fixtures. Reference
# tolerances come from the installable, reviewer-owned anchor copies.
latent_test_helpers <- function(simulation = FALSE) {
  testthat::skip_if_not_installed("jsonlite")
  testthat::skip_if_not_installed("digest")
  e <- new.env(parent = globalenv())
  path <- if (simulation) c("validation", "sim", "simulation_helpers.R") else
    c("validation", "latent", "reference_checks.R")
  sys.source(do.call(system.file, c(as.list(path), list(package = "llmsa", mustWork = TRUE))), envir = e)
  e
}

latent_test_capture <- function(expr) {
  warnings <- messages <- character()
  value <- withCallingHandlers(expr,
    warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") },
    message = function(m) { messages <<- c(messages, conditionMessage(m)); invokeRestart("muffleMessage") })
  list(value = value, warnings = warnings, messages = messages)
}

latent_test_runs <- function(type = "ordinal", items = 18L, prompts = 3L, models = 3L,
                             blocks = 1L, seed = 20261031L) {
  r <- msa_simulate(items, prompts, models, 3L, blocks,
    vc = list(item = 1, prompt = 0.3, model = 0.2, block = 0.1, residual = 1), seed = seed)
  r$value <- if (type == "binary") as.integer(r$value > 0) else
    cut(r$value, c(-Inf, -1.5, -0.5, 0.5, 1.5, Inf), labels = paste0("c", 1:5), ordered_result = TRUE)
  r
}

latent_test_same_components <- function(got, reference, entry = "invariance",
                                        key = "component_tol_fraction_of_total_variance") {
  tol <- numeric_tolerance(entry, key)
  a <- stats::setNames(got$vc$variance, got$vc$source)
  b <- stats::setNames(reference$vc$variance, reference$vc$source)
  expect_setequal(names(a), names(b))
  expect_lte(max(abs(a[names(b)] - b)) / sum(b), tol)
}

latent_test_resource_copy <- function() {
  origin <- system.file("validation", "latent", package = "llmsa", mustWork = TRUE)
  path <- tempfile("latent-test-resources-")
  dir.create(path)
  stopifnot(all(file.copy(list.files(origin, full.names = TRUE), path, recursive = TRUE)))
  path
}

latent_test_cells <- function(d) {
  lapply(d, function(x) if (is.numeric(x)) vapply(x, format, character(1), digits = 15L) else as.character(x))
}

latent_test_documentation_sources <- function(rmd) {
  name <- function(x) {
    if (is.symbol(x)) return(as.character(x))
    if (is.call(x) && as.character(x[[1L]]) %in% c("::", ":::")) return(as.character(x[[3L]]))
    ""
  }
  pending <- rmd
  found <- character()
  while (length(pending)) {
    path <- normalizePath(pending[1L], mustWork = TRUE)
    pending <- pending[-1L]
    if (path %in% found) next
    found <- c(found, path)
    lines <- readLines(path, warn = FALSE)
    if (grepl("\\.Rmd$", path)) {
      inline <- unlist(regmatches(lines, gregexpr("`r [^`]*`", lines)))
      inline <- sub("^`r ", "", sub("`$", "", inline))
      inside <- FALSE
      code <- logical(length(lines))
      for (i in seq_along(lines)) {
        if (grepl("^```\\{r(?:[ ,}]|$)", lines[i], perl = TRUE)) inside <- TRUE else
          if (grepl("^```[[:space:]]*$", lines[i])) inside <- FALSE else code[i] <- inside
      }
      lines <- c(lines[code], inline)
    }
    walk <- function(x) {
      if (missing(x)) return(invisible(NULL))
      if (is.call(x) && name(x[[1L]]) %in% c("source", "sys.source")) {
        arg <- x[[2L]]
        if (is.character(arg) && length(arg) == 1L) dependency <- file.path(dirname(path), arg) else {
          if (!is.call(arg) || name(arg[[1L]]) != "system.file") stop("Unresolved documentation dependency.")
          args <- as.list(arg)[-1L]
          if (!all(vapply(args, function(a) is.character(a) || is.logical(a), logical(1)))) {
            stop("Unresolved documentation dependency.")
          }
          dependency <- do.call(system.file, args)
        }
        if (length(dependency) != 1L || !nzchar(dependency) || !file.exists(dependency)) {
          stop("Missing documentation dependency.")
        }
        pending <<- c(pending, dependency)
      }
      if (is.call(x) || is.expression(x) || is.pairlist(x)) invisible(lapply(as.list(x), walk))
    }
    walk(parse(text = lines))
  }
  found
}

latent_test_literal_hits <- function(lines, values) {
  values <- unique(values[is.finite(values) & values != round(values)])
  pattern <- "(?<![A-Za-z0-9_.])(?:[0-9]+\\.[0-9]+|\\.[0-9]+|[0-9]+(?:\\.[0-9]+)?[eE][-+]?[0-9]+)(?![A-Za-z0-9_.])"
  text <- paste(lines, collapse = "\n")
  tokens <- regmatches(text, gregexpr(pattern, text, perl = TRUE))[[1L]]
  hits <- vapply(tokens, function(token) {
    number <- as.numeric(token)
    digits <- nchar(sub("^0+", "", gsub("[^0-9]", "", sub("[eE].*$", "", token))))
    digits >= 3L && any(number == values | number == signif(values, digits))
  }, logical(1))
  unique(tokens[hits])
}
