test_that("the CLI API constructor serializes the approved request and the right credential", {
  skip_if_not_installed("httr2", "1.0.0")
  p <- ap1_test_plan(); ap1_test_keys()
  on.exit(Sys.unsetenv(c("OPENAI_API_KEY", "OPENROUTER_API_KEY")), add = TRUE)
  for (full_url in c(FALSE, TRUE)) {
    config <- p
    if (full_url) config$models <- lapply(config$models, function(m) { m$endpoint <- paste0(m$endpoint, "/chat/completions"); m })
    b <- acmg_api_backends(config)
    for (key in names(b)) {
      model <- acmg_models(p)[[key]]
      calls <- 0L
      httr2::local_mocked_responses(function(req) {
        calls <<- calls + 1L
        body <- ap1_test_request_body(req)
        expect_identical(httr2::req_get_url(req), paste0(model$endpoint, "/chat/completions"))
        expect_identical(httr2::req_get_headers(req, redacted = "reveal")[["Authorization"]],
                         paste("Bearer", if (key == "sol") "synthetic-openai-key" else "synthetic-router-key"))
        expect_identical(body$model, model$id)
        expect_equal(body$seed, model$seed)
        expect_false(any(c("reasoning", "max_tokens") %in% names(body)))
        expect_false(grepl("/no_think", body$messages[[1]]$content, fixed = TRUE))
        if (key == "sol") {
          expect_false(any(c("temperature", "provider") %in% names(body)))
          expect_identical(body$reasoning_effort, model$reasoning)
        } else {
          expect_equal(body$temperature, model$temperature)
          expect_identical(body$provider$order, as.list(unlist(model$provider_order, use.names = FALSE)))
          expect_identical(body$provider$quantizations, as.list(unlist(model$quantizations, use.names = FALSE)))
          expect_identical(body$provider$allow_fallbacks, FALSE)
        }
        ap1_test_response(list(id = "synthetic-id", model = model$id, system_fingerprint = NULL,
                                  choices = list(list(message = list(content = "Uncertain significance", reasoning = "Pathogenic")))))
      })
      r <- b[[key]]("Synthetic test prompt", model$id, list(model_id = key))
      expect_identical(calls, 1L)
      expect_identical(r$text, "Uncertain significance")
      expect_true("system_fingerprint" %in% names(r$meta))
      expect_false(grepl("synthetic-.*-key", jsonlite::toJSON(r$meta, auto_unbox = TRUE)))
    }
  }
})

test_that("API configuration fails before requests for missing keys, wrong hosts and routes", {
  skip_if_not_installed("httr2")
  p <- ap1_test_plan(); ap1_test_keys()
  on.exit(Sys.unsetenv(c("OPENAI_API_KEY", "OPENROUTER_API_KEY")), add = TRUE)
  calls <- 0L
  httr2::local_mocked_responses(function(req) { calls <<- calls + 1L; stop("Unexpected network request") })
  Sys.unsetenv("OPENROUTER_API_KEY")
  expect_error(acmg_api_backends(p), "OPENROUTER_API_KEY")
  ap1_test_keys(); Sys.unsetenv("OPENAI_API_KEY")
  expect_error(acmg_api_backends(p), "OPENAI_API_KEY")
  ap1_test_keys()
  for (url in c("http://api.openai.com/v1", "https://api.openai.com.evil.invalid/v1", "https://openrouter.ai@evil.invalid/v1")) {
    bad <- p; bad$models[[1]]$endpoint <- url
    expect_error(acmg_api_backends(bad), "endpoint")
  }
  bad <- p; bad$models[[2]]$provider_order <- list()
  expect_error(acmg_api_backends(bad), "routing")
  expect_identical(calls, 0L)
})

test_that("HTTP metadata separates response identity from request routing and preserves system precedence", {
  skip_if_not_installed("httr2")
  p <- ap1_test_plan(); settings <- acmg_models(p)$llama
  cases <- list(list(row = "From row", arg = "From argument", want = "From row"),
                list(row = "", arg = "From argument", want = "From argument"),
                list(row = NA_character_, arg = "From argument", want = "From argument"),
                list(row = NULL, arg = NULL, want = NULL))
  for (case in cases) {
    response <- list(id = "synthetic-response", model = "synthetic-snapshot", provider = settings$provider_name,
                     system_fingerprint = NULL, usage = list(completion_tokens = 100, completion_tokens_details = list(reasoning_tokens = 40)),
                     choices = list(list(message = list(content = "Benign", reasoning = "Pathogenic"))))
    httr2::local_mocked_responses(function(req) {
      body <- ap1_test_request_body(req)
      roles <- vapply(body$messages, `[[`, "", "role")
      expect_identical(roles, if (is.null(case$want)) "user" else c("system", "user"))
      if (!is.null(case$want)) expect_identical(body$messages[[1]]$content, case$want)
      expect_identical(body$messages[[length(roles)]]$content, "Synthetic prompt")
      ap1_test_response(response)
    })
    backend <- backend_openai_compatible(settings$endpoint, api_key = "synthetic-key", temperature = NULL,
       system = case$arg, seed = settings$seed,
       provider = list(order = as.list(unlist(settings$provider_order)), quantizations = as.list(unlist(settings$quantizations)), allow_fallbacks = FALSE))
    got <- backend("Synthetic prompt", settings$id, list(system = case$row))
    expect_identical(got$text, "Benign")
    expect_identical(got$meta$id, response$id)
    expect_identical(got$meta$model_snapshot, response$model)
    expect_identical(got$meta$provider, response$provider)
    expect_equal(got$meta$usage, response$usage)
    expect_true("system_fingerprint" %in% names(got$meta))
    expect_null(got$meta$system_fingerprint)
    expect_identical(unlist(got$meta$provider_order), unlist(settings$provider_order))
    expect_identical(unlist(got$meta$quantizations), unlist(settings$quantizations))
    expect_identical(got$meta$allow_fallbacks, FALSE)
    expect_identical(got$meta$seed, settings$seed)
    expect_false("temperature" %in% names(got$meta))
    stored <- meta_to_json(got$meta)
    expect_false(grepl("synthetic-key|Authorization|Synthetic prompt|Benign", stored))
    # ADR-011 no. 7: the reasoning text is stored as metadata; the parsed text stays message.content.
    expect_identical(got$meta$reasoning, "Pathogenic")
    expect_true(grepl('"system_fingerprint":null', stored, fixed = TRUE))
  }
})

test_that("the API pilot runs through the same CLI driver with synthetic HTTP replies", {
  for (pkg in c("httr2", "DBI", "RSQLite")) skip_if_not_installed(pkg)
  p <- ap1_test_plan(); ap1_test_keys()
  on.exit(Sys.unsetenv(c("OPENAI_API_KEY", "OPENROUTER_API_KEY")), add = TRUE)
  calls <- 0L
  httr2::local_mocked_responses(function(req) {
    body <- ap1_test_request_body(req)
    models <- acmg_models(p)
    key <- names(models)[vapply(models, function(m) identical(m$id, body$model), logical(1))]
    if (length(key) != 1L) stop("Unexpected model in synthetic HTTP test")
    calls <<- calls + 1L
    is_json <- startsWith(body$messages[[1]]$content, "Return a JSON object")
    reply <- jsonlite::fromJSON(ap1_test_meta(key, p), simplifyVector = FALSE)
    reply$model <- reply$model_snapshot; reply$model_snapshot <- NULL
    reply$choices <- list(list(message = list(content = if (is_json) '{"classification":"Benign"}' else "Benign")))
    ap1_test_response(reply)
  })
  store <- tempfile(fileext = ".sqlite")
  output <- capture.output(acmg_run_cli(c("--part", "pilot", "--backend", "api", "--store", store)))
  expect_identical(calls, as.integer(length(p$models) * p$pilot$calls_per_model))
  expect_true(any(grepl("cost passed", output, fixed = TRUE)))
  rows <- acmg_store_read(store, "api")
  expect_true(acmg_pilot(rows, p)$passed)
  capture.output(acmg_run_cli(c("--part", "pilot", "--backend", "api", "--store", store)))
  expect_identical(calls, nrow(rows))
  expect_identical(acmg_store_read(store, "api")$meta, rows$meta)
  # The store contains neither item references nor the rendered prompt/protein.
  expect_false(any(c("reference", "protein", "prompt", "system") %in% names(rows)))
})

test_that("an HTTP 400 becomes a stored error and the next call retains response metadata", {
  for (pkg in c("httr2", "DBI", "RSQLite")) skip_if_not_installed(pkg)
  p <- ap1_test_plan(); calls <- 0L
  httr2::local_mocked_responses(function(req) {
    calls <<- calls + 1L
    if (calls == 1L) return(httr2::response_json(status_code = 400, body = list(error = list(message = "Synthetic bad parameter"))))
    ap1_test_response(list(id = "synthetic-success", model = "synthetic-snapshot", system_fingerprint = NULL,
                           choices = list(list(message = list(content = "Benign")))))
  })
  d <- msa_design(c(x = "Synthetic x", y = "Synthetic y"), "{text}", "synthetic-model", reps = 1, order = "fixed")
  backend <- backend_openai_compatible(api_key = "synthetic-key", temperature = NULL)
  store <- tempfile(fileext = ".sqlite")
  result <- msa_run(d, backend, parse = acmg_parser(p), store = store, verbose = FALSE)
  expect_identical(calls, 2L)
  expect_match(result$error[1], "HTTP 400")
  expect_true(is.na(result$value[1]))
  expect_true(is.na(result$error[2]))
  expect_identical(result$value[2], "Benign")
  persisted <- read_store(store)
  expect_identical(persisted$error, result$error)
  meta <- jsonlite::fromJSON(persisted$meta[2], simplifyVector = FALSE)
  expect_identical(meta$id, "synthetic-success")
  expect_true("system_fingerprint" %in% names(meta))
  expect_null(meta$system_fingerprint)
})

test_that("JSON metadata preserve small and fractional numeric values in SQLite", {
  for (pkg in c("jsonlite", "DBI", "RSQLite")) skip_if_not_installed(pkg)
  # Synthetic values with no empirical meaning; neither may be rounded away.
  usage <- list(cost = 1 / 10^6, details = list(amount = 1 / 3))
  meta <- list(mock = TRUE, usage = usage, system_fingerprint = NULL)
  backend <- function(prompt, model, row) list(text = "Synthetic reply", meta = meta)
  d <- msa_design("Synthetic item", "{text}", "synthetic", reps = 1, order = "fixed")
  store <- tempfile(fileext = ".sqlite")
  runs <- msa_run(d, backend, store = store, verbose = FALSE)
  persisted <- read_store(store)
  expect_identical(runs$meta, persisted$meta)
  got <- jsonlite::fromJSON(persisted$meta, simplifyVector = FALSE)
  expect_identical(got$usage, usage)
  expect_true("system_fingerprint" %in% names(got))
  expect_null(got$system_fingerprint)
})
