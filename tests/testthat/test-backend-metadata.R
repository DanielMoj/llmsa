test_that("empty answers preserve metadata and never invoke a custom parser", {
  skip_if_not_installed("jsonlite")
  contents <- list(NULL, character(), NA_character_, "", " \t", "0.810")
  labels <- c("null", "zero", "missing", "empty", "whitespace", "valid")
  d <- msa_design(stats::setNames(labels, labels), prompts = "{text}",
                   models = "m", reps = 1, order = "fixed")
  seen <- character()
  parser <- function(text) { seen <<- c(seen, text); "custom value" }
  meta <- list(model_snapshot = "synthetic-snapshot", provider = "SyntheticHost",
               usage = list(cost = 0.12345678901234567, details = list(tokens = 17L)))
  backend <- function(prompt, model, row) list(text = contents[[match(row$item_id, labels)]], meta = meta)
  runs <- msa_run(d, backend, parse = parser, verbose = FALSE)
  expect_identical(seen, c(" \t", "0.810"))
  expect_identical(runs$value, c(rep(NA_character_, 4L), "custom value", "custom value"))
  for (i in seq_len(4L)) expect_true(nzchar(runs$error[[i]]))
  expect_match(runs$error[1L], "null")
  expect_match(runs$error[2L], "length zero")
  expect_match(runs$error[3L], "NA", fixed = TRUE)
  expect_match(runs$error[4L], "empty string")
  expect_identical(runs$error[5:6], c(NA_character_, NA_character_))
  for (json in runs$meta) expect_identical(jsonlite::parse_json(json), meta)
  expect_identical(runs$response[5:6], c(" \t", "0.810"))
})

test_that("a custom parser cannot turn a backend error into a value", {
  d <- msa_design(c(x = "synthetic"), prompts = "{text}", models = "m", reps = 1)
  calls <- 0L
  parser <- function(...) { calls <<- calls + 1L; "false success" }
  for (err in list(simpleError("synthetic error"), simpleError(""))) {
    r <- msa_run(d, function(...) stop(err), parse = parser, verbose = FALSE)
    expect_identical(r$value, NA_character_)
    expect_true(nzchar(trimws(r$error)))
  }
  expect_identical(calls, 0L)
  # A missing exact text member is empty, even when a longer name exists.
  r <- msa_run(d, function(...) list(text_extra = "false success"), parse = parser, verbose = FALSE)
  expect_identical(r$value, NA_character_)
  expect_identical(calls, 0L)
})

test_that("both adapters preserve recorded response metadata and ellmer isolates calls", {
  for (pkg in c("httr2", "jsonlite", "ellmer")) skip_if_not_installed(pkg)
  plan <- ap1_test_plan()
  models <- acmg_models(plan)
  replay <- ap1_test_replay(plan)
  requests <- list()
  httr2::local_mocked_responses(function(req) {
    requests[[length(requests) + 1L]] <<- ap1_test_request_body(req)
    replay(req)
  })
  chats <- lapply(models, function(model) ellmer::chat_openai_compatible(
    base_url = model$endpoint, model = model$id,
    credentials = function() "synthetic-key", echo = "none"))
  ellmer_backend <- backend_ellmer(chats)
  for (key in names(models)) {
    model <- models[[key]]
    row <- list(model_id = key)
    record <- jsonlite::fromJSON(ap1_test_recording(key), simplifyVector = FALSE)
    compatible <- backend_openai_compatible(model$endpoint, api_key = "synthetic-key")
    for (bk in list(ellmer_backend, compatible, ellmer_backend)) {
      result <- bk("Synthetic replay only", model$id, row)
      expect_identical(result$text, record$choices[[1L]]$message$content)
      expect_identical(result$meta[["model_snapshot"]], record$model)
      expect_identical(result$meta[["provider"]], record[["provider"]])
      expect_identical(result$meta[["usage"]], record$usage)
      roles <- vapply(tail(requests, 1L)[[1L]]$messages, `[[`, "", "role")
      expect_identical(sum(roles == "user"), 1L)
      expect_identical(sum(roles == "assistant"), 0L)
      # JSON persistence must retain nested usage without changing precision.
      expect_identical(jsonlite::parse_json(meta_to_json(result$meta))$usage, record$usage)
    }
    expect_length(chats[[key]]$get_turns(), 0L)
  }
  expect_length(requests, 3L * length(models))
})

test_that("both adapters continue after transport failures and empty content", {
  for (pkg in c("httr2", "jsonlite", "ellmer", "DBI", "RSQLite")) skip_if_not_installed(pkg)
  kinds <- c("ok_first", "http500", "http401", "timeout", "body", "null", "empty", "ok_last")
  d <- msa_design(stats::setNames(kinds, kinds), prompts = "{text}", models = c(m = "synthetic-model"),
                   reps = 1, order = "fixed")
  base_url <- "https://synthetic.invalid/v1"
  usage <- list(prompt_tokens = 11L, completion_tokens = 5L, total_tokens = 16L,
                 cost = 0.12345678901234567, completion_tokens_details = list(reasoning_tokens = 2L))
  httr2::local_mocked_responses(function(req) {
    body <- ap1_test_request_body(req)
    expect_identical(httr2::req_get_url(req), paste0(base_url, "/chat/completions"))
    expect_identical(body$model, "synthetic-model")
    content <- unlist(lapply(body$messages, function(message) message$content), use.names = FALSE)
    kind <- intersect(kinds, content)
    expect_length(kind, 1L)
    if (kind == "timeout") stop(errorCondition("synthetic timeout", class = "curl_error_operation_timedout"))
    if (kind %in% c("http500", "http401")) {
      return(httr2::response(status_code = if (kind == "http500") 500L else 401L,
                             headers = list(`Content-Type` = "application/json"),
                             body = charToRaw('{"error":{"message":"synthetic HTTP error"}}')))
    }
    if (kind == "body") return(httr2::response(status_code = 200L, headers = list(`Content-Type` = "application/json"), body = raw()))
    content <- if (kind == "null") NULL else if (kind == "empty") "" else "1.250"
    reply <- list(id = "synthetic-id", object = "chat.completion", model = "synthetic-snapshot",
                   provider = "SyntheticHost", usage = usage,
                   choices = list(list(index = 0L, finish_reason = "stop",
                                       message = list(role = "assistant", content = content))))
    httr2::response(status_code = 200L, headers = list(`Content-Type` = "application/json"),
                    body = charToRaw(as.character(jsonlite::toJSON(reply, auto_unbox = TRUE, null = "null", digits = 17))))
  })
  chat <- ellmer::chat_openai_compatible(base_url = base_url, model = "synthetic-model",
                                        credentials = function() "synthetic-key", echo = "none")
  for (bk in list(backend_openai_compatible(base_url, api_key = "synthetic-key"), backend_ellmer(chat))) {
    path <- tempfile(fileext = ".sqlite")
    # The two adapters can diagnose an empty body differently; both must store it.
    runs <- suppressMessages(msa_run(d, bk, parse = parse_number(), store = path, verbose = FALSE))
    expect_identical(runs$item_id, kinds)
    expect_identical(runs$value, c("1.25", rep(NA_character_, 6L), "1.25"))
    expect_true(all(nzchar(runs$error[2:7])))
    expect_true(all(is.na(runs$error[c(1L, 8L)])))
    stored <- read_store(path)
    expect_identical(as.data.frame(runs)[names(stored)], stored)
    for (i in c(1L, 6L, 7L, 8L)) {
      expect_identical(jsonlite::parse_json(stored$meta[[i]])$usage, usage)
    }
    unlink(path)
  }
})
