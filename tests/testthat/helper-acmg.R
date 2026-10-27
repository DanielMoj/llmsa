# Small synthetic test inputs; only shipped package resources are used.
ap1_test_plan <- function() {
  for (p in c("yaml", "jsonlite", "digest")) skip_if_not_installed(p)
  acmg_plan()
}

# A tolerance of plan.yaml validation_tolerances; a missing key stops instead of
# turning into an exact comparison (ADR-012, BL-72).
ap1_test_tolerance <- function(plan, name) {
  value <- plan[["validation_tolerances"]][[name]]
  if (!is.numeric(value) || length(value) != 1L || !is.finite(value)) {
    stop("plan.yaml validation_tolerances lacks a finite value for ", name, call. = FALSE)
  }
  value
}

ap1_test_keys <- function() {
  # Never inspect real credentials in a test process.
  Sys.setenv(OPENAI_API_KEY = "synthetic-openai-key", OPENROUTER_API_KEY = "synthetic-router-key")
}

ap1_test_request_body <- function(req) {
  # Render with httr2's actual serializer without the local socket used by
  # req_dry_run(). This inspects the bytes passed to the HTTP transport.
  body <- getFromNamespace("req_body_render", "httr2")(req)
  jsonlite::fromJSON(body, simplifyVector = FALSE)
}

ap1_test_response <- function(body) {
  httr2::new_response(method = "POST", url = "https://synthetic.invalid", status_code = 200L,
                      headers = list(`Content-Type` = "application/json"),
                      body = charToRaw(jsonlite::toJSON(body, auto_unbox = TRUE, null = "null")))
}

# Operator recordings (tests/fixtures/api/, ANK-94) are not part of the built
# package (.Rbuildignore). In the source tree, or with the option
# llmsa.test.ap1_recordings, they are required; elsewhere, as in R CMD check,
# tests that replay them are skipped.
ap1_test_recording <- function(key) {
  directory <- getOption("llmsa.test.ap1_recordings")
  path <- file.path(directory %||% testthat::test_path("..", "fixtures", "api"), paste0(key, ".json"))
  if (file.exists(path)) return(path)
  if (!is.null(directory) || file.exists(testthat::test_path("..", "..", "DESCRIPTION"))) {
    stop("AP1 test recording missing: ", path, call. = FALSE)
  }
  testthat::skip("AP1 recordings under tests/fixtures/api are not part of the built package")
}

# Replays the recordings by URL and request model (tests/fixtures/api/README.md);
# an unmatched request stops instead of reaching the network.
ap1_test_replay <- function(plan) {
  models <- acmg_models(plan)
  paths <- vapply(names(models), ap1_test_recording, "")
  function(req) {
    body <- ap1_test_request_body(req)
    url <- httr2::req_get_url(req)
    key <- names(models)[vapply(models, function(m) {
      identical(body[["model"]], m$id) && identical(url, paste0(m$endpoint, "/chat/completions"))
    }, logical(1))]
    if (length(key) != 1L) stop("no recording for ", url, " ", body[["model"]], call. = FALSE)
    httr2::response(status_code = 200L, url = url, method = "POST",
                    headers = list(`Content-Type` = "application/json"),
                    body = readBin(paths[[key]], "raw", file.size(paths[[key]])))
  }
}

ap1_test_recorded_message <- function(key) {
  jsonlite::fromJSON(ap1_test_recording(key), simplifyVector = FALSE)$choices[[1]]$message
}

ap1_test_meta <- function(key, plan, completion = 100, reasoning = 40) {
  model <- acmg_models(plan)[[key]]
  m <- list(id = paste0("synthetic-", key), model_snapshot = model$id,
            usage = list(completion_tokens = completion, completion_tokens_details = list(reasoning_tokens = reasoning)))
  if (key != "sol") m$provider <- model$provider_name
  as.character(jsonlite::toJSON(m, auto_unbox = TRUE, null = "null"))
}

ap1_test_pilot <- function(plan) {
  ids <- acmg_items(pilot = TRUE)$item_id
  r <- expand.grid(block = 1L, item_id = ids, prompt_id = names(plan$templates),
                    model_id = names(acmg_models(plan)), rep = seq_len(plan$pilot$replicates), stringsAsFactors = FALSE)
  r$value <- acmg_classes(plan)[1]
  r$reference <- acmg_classes(plan)[length(plan$classes)] # Deliberately wrong: parser success is not accuracy.
  r$error <- NA_character_; r$latency_s <- 0.25
  r$meta <- vapply(r$model_id, ap1_test_meta, "", plan = plan)
  as_msa_runs(r)
}

ap1_test_runs <- function(plan, n_items = NULL) {
  items <- acmg_items()
  if (!is.null(n_items)) items <- head(items, n_items)
  r <- expand.grid(rep = seq_len(plan$design$replicates), prompt_id = names(plan$templates),
                    item_id = items$item_id, model_id = names(acmg_models(plan)),
                    block = seq_len(plan$design$blocks), stringsAsFactors = FALSE)
  # Explicitly synthetic classifications: balanced item classes and seeded noise.
  i <- match(r$item_id, items$item_id)
  k <- length(plan$classes)
  base <- (i - 1L) %% k + 1L
  shift <- acmg_seeded(plan$design$seed, sample(c(-1L, 0L, 1L), nrow(r), replace = TRUE, prob = c(0.15, 0.7, 0.15)))
  r$value <- acmg_classes(plan)[pmax(1L, pmin(k, base + shift))]
  r$error <- NA_character_
  r$meta <- '{"mock":true}'
  r <- acmg_join_items(r, items)
  r
}

ap1_test_fit_stub <- function(runs, type = c("numeric", "ordinal", "binary"), levels = NULL, link = "probit", ...) {
  type <- match.arg(type)
  # Controlled fit object for testing application decisions, not statistical validation.
  structure(list(type = type, link = link, model = list(),
                 vc = data.frame(source = c("item", "model", "Residual"), variance = c(10, 1, 1)),
                 singular = FALSE, levels = levels, derived = character(),
                 n = list(items = length(unique(runs$item_id)), prompts = length(unique(runs$prompt_id)),
                          models = length(unique(runs$model_id)), blocks = length(unique(runs$block)),
                          observations = nrow(runs), reps_per_cell = c(1L, 3L))), class = "msa_fit")
}

ap1_test_report_stub <- function(...) "synthetic-report-not-rendered"
