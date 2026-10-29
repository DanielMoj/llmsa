# Installable documentation resources retain the reviewer-owned tolerances.
numeric_anchor <- function(id) {
  testthat::skip_if_not_installed("jsonlite")
  path <- system.file("validation", "numeric", "anchors", paste0(id, ".json"), package = "llmsa")
  if (!nzchar(path)) stop("Numeric test anchor is missing: ", id, call. = FALSE)
  x <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  if (!identical(x[["id"]], id) || is.null(x[["value"]])) stop("Invalid numeric test anchor: ", id)
  x[["value"]]
}

numeric_tolerance <- function(entry, key) {
  value <- numeric_anchor("ANK-TOL")[[entry]][[key]]
  if (is.null(value) || length(value) != 1L || !is.numeric(value) || !is.finite(value) || value < 0) {
    stop("Missing or invalid numeric tolerance: ", entry, "$", key, call. = FALSE)
  }
  value
}

numeric_test_runs <- function(seed = 13L) {
  # Small, explicitly synthetic crossed study; no protected data or oracles.
  msa_simulate(6, 3, 1, 3,
    vc = list(item = 1, prompt = 0.2, item_prompt = 0.1, residual = 0.3), seed = seed)
}

numeric_test_frame <- function(r) {
  data.frame(y = r$value, item = factor(r$item_id), prompt = factor(r$prompt_id),
             model = factor(r$model_id), block = factor(r$block))
}

numeric_components <- function(f) stats::setNames(f$vc$variance, f$vc$source)

numeric_validation_helpers <- function() {
  testthat::skip_if_not_installed("jsonlite")
  testthat::skip_if_not_installed("digest")
  e <- new.env(parent = globalenv())
  source(system.file("validation", "numeric", "reference_checks.R", package = "llmsa", mustWork = TRUE),
         local = e)
  e
}
