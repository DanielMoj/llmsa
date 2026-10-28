# ADR-014 E2: finish_reason and native_finish_reason of the first choice are
# stored in meta under these names (exact match), only as non-empty strings, so
# that a reply cut at the token limit can be told apart from an unreadable one.

ap1_test_recorded_choice <- function(key) {
  jsonlite::fromJSON(ap1_test_recording(key), simplifyVector = FALSE)$choices[[1]]
}

test_that("finish reasons are kept only as non-empty strings under their exact names", {
  skip_if_not_installed("httr2")
  cases <- list(absent = list(),
                null = list(finish_reason = NULL, native_finish_reason = NULL),
                empty = list(finish_reason = "", native_finish_reason = ""),
                number = list(finish_reason = 1, native_finish_reason = 2),
                array = list(finish_reason = list("stop", "length"), native_finish_reason = list("STOP")),
                longer_names = list(finish_reason_detail = "length", native_finish_reason_raw = "MAX_TOKENS"),
                finish_only = list(finish_reason = "length"),
                both = list(finish_reason = "length", native_finish_reason = "MAX_TOKENS"))
  for (name in names(cases)) {
    choice <- c(list(message = list(content = "Benign")), cases[[name]])
    httr2::local_mocked_responses(function(req) {
      ap1_test_response(list(id = "synthetic-id", model = "synthetic-model", choices = list(choice)))
    })
    got <- backend_openai_compatible(api_key = "", temperature = NULL)("Synthetic prompt", "synthetic-model")
    expect_identical(got$text, "Benign", info = name)
    expect_false(any(c("finish_reason_detail", "native_finish_reason_raw") %in% names(got$meta)), info = name)
    if (name %in% c("finish_only", "both")) {
      expect_identical(got$meta$finish_reason, "length", info = name)
    } else {
      expect_false("finish_reason" %in% names(got$meta), info = name)
    }
    if (name == "both") {
      expect_identical(got$meta$native_finish_reason, "MAX_TOKENS")
    } else {
      expect_false("native_finish_reason" %in% names(got$meta), info = name)
    }
  }
})

test_that("recordings: meta$finish_reason equals the recorded value; native_finish_reason only where recorded", {
  skip_if_not_installed("httr2")
  p <- ap1_test_plan(); ap1_test_keys()
  on.exit(Sys.unsetenv(c("OPENAI_API_KEY", "OPENROUTER_API_KEY")), add = TRUE)
  httr2::local_mocked_responses(ap1_test_replay(p))
  backends <- acmg_api_backends(p)
  native <- character()
  for (key in names(backends)) {
    choice <- ap1_test_recorded_choice(key)
    got <- backends[[key]]("Synthetic replay prompt", acmg_models(p)[[key]]$id, list(model_id = key))
    expect_true(is.character(choice[["finish_reason"]]) && nzchar(choice[["finish_reason"]]), info = key)
    expect_identical(got$meta$finish_reason, choice[["finish_reason"]], info = key)
    if (is.null(choice[["native_finish_reason"]])) {
      expect_false("native_finish_reason" %in% names(got$meta), info = key)
    } else {
      native <- c(native, key)
      expect_identical(got$meta$native_finish_reason, choice[["native_finish_reason"]], info = key)
    }
  }
  # Sol's recording has no native_finish_reason; the OpenRouter recordings have one.
  expect_identical(native, c("llama", "qwen"))
})

test_that("recordings: finish reasons and timeout_s survive msa_run() and the SQLite store", {
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
    choice <- ap1_test_recorded_choice(key)
    meta <- jsonlite::fromJSON(stored$meta[i], simplifyVector = FALSE)
    expect_identical(meta$finish_reason, choice[["finish_reason"]], info = key)
    expect_identical(meta[["native_finish_reason"]], choice[["native_finish_reason"]], info = key)
    expect_identical("native_finish_reason" %in% names(meta), !is.null(choice[["native_finish_reason"]]), info = key)
    expect_equal(meta$timeout_s, acmg_models(p)[[key]]$timeout_s, info = key)
    expect_identical(stored$value[i], acmg_parser(p)(choice$message[["content"]]), info = key)
  }
})
