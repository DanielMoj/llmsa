# ADR-011 no. 7: a non-empty message.reasoning is stored as meta$reasoning; the
# parsed text stays message.content and reasoning_details is never stored.

test_that("meta$reasoning is kept only for a non-empty reasoning string, never from reasoning_details", {
  skip_if_not_installed("httr2")
  details <- list(list(type = "reasoning.text", text = "Synthetic reasoning"))
  cases <- list(absent = list(content = "Benign"),
                null = list(content = "Benign", reasoning = NULL),
                empty = list(content = "Benign", reasoning = ""),
                number = list(content = "Benign", reasoning = 1),
                array = list(content = "Benign", reasoning = list("Synthetic", "reasoning")),
                details_only = list(content = "Benign", reasoning_details = details),
                text = list(content = "Benign", reasoning = "Synthetic reasoning", reasoning_details = details))
  for (name in names(cases)) {
    httr2::local_mocked_responses(function(req) {
      ap1_test_response(list(id = "synthetic-id", model = "synthetic-model", choices = list(list(message = cases[[name]]))))
    })
    got <- backend_openai_compatible(api_key = "", temperature = NULL)("Synthetic prompt", "synthetic-model")
    expect_identical(got$text, "Benign", info = name)
    expect_false("reasoning_details" %in% names(got$meta), info = name)
    if (name == "text") {
      expect_identical(got$meta$reasoning, "Synthetic reasoning")
    } else {
      expect_false("reasoning" %in% names(got$meta), info = name)
    }
  }
})

test_that("recordings: meta$reasoning equals Qwen's recorded reasoning text; Sol and Llama have no reasoning key", {
  skip_if_not_installed("httr2")
  p <- ap1_test_plan(); ap1_test_keys()
  on.exit(Sys.unsetenv(c("OPENAI_API_KEY", "OPENROUTER_API_KEY")), add = TRUE)
  httr2::local_mocked_responses(ap1_test_replay(p))
  backends <- acmg_api_backends(p)
  for (key in names(backends)) {
    message <- ap1_test_recorded_message(key)
    got <- backends[[key]]("Synthetic replay prompt", acmg_models(p)[[key]]$id, list(model_id = key))
    expect_identical(got$text, message[["content"]], info = key)
    expect_false(grepl("reasoning_details", meta_to_json(got$meta), fixed = TRUE), info = key)
    if (key == "qwen") {
      expect_true(is.character(message[["reasoning"]]) && nzchar(message[["reasoning"]]))
      expect_identical(got$meta$reasoning, message[["reasoning"]])
    } else {
      expect_false("reasoning" %in% names(got$meta), info = key)
    }
  }
})

test_that("recordings: the reasoning text survives msa_run() and the SQLite store and stays out of the parser", {
  for (pkg in c("httr2", "DBI", "RSQLite")) skip_if_not_installed(pkg)
  p <- ap1_test_plan(); ap1_test_keys()
  on.exit(Sys.unsetenv(c("OPENAI_API_KEY", "OPENROUTER_API_KEY")), add = TRUE)
  httr2::local_mocked_responses(ap1_test_replay(p))
  backends <- acmg_api_backends(p)
  models <- vapply(acmg_models(p), `[[`, "", "id")
  d <- msa_design(data.frame(item_id = "synthetic-item", text = "Synthetic replay prompt", stringsAsFactors = FALSE),
                  prompts = c(concise = "{text}"), models = models, reps = 1, blocks = 1, order = "fixed")
  store <- tempfile(fileext = ".sqlite")
  on.exit(unlink(store), add = TRUE)
  runs <- msa_run(d, function(prompt, model, row) backends[[row$model_id]](prompt, model, row),
                  parse = acmg_parser(p), store = store, verbose = FALSE)
  stored <- read_store(store)
  expect_setequal(stored$model_id, names(models))
  expect_identical(stored$meta, runs$meta[match(run_key(stored), run_key(runs))])
  for (i in seq_len(nrow(stored))) {
    key <- stored$model_id[i]
    message <- ap1_test_recorded_message(key)
    meta <- jsonlite::fromJSON(stored$meta[i], simplifyVector = FALSE)
    expect_identical(stored$response[i], message[["content"]], info = key)
    expect_identical(stored$value[i], acmg_parser(p)(message[["content"]]), info = key)
    expect_false(is.na(stored$value[i]), info = key)
    if (key == "qwen") {
      expect_identical(meta$reasoning, message[["reasoning"]])
    } else {
      expect_false("reasoning" %in% names(meta), info = key)
    }
  }
})
