# K-M2-4: backend_openai_compatible() with fixed routing, replayed against the
# recordings under tests/fixtures/api/ (ANK-94) with httr2::local_mocked_responses().
# Production settings come from ANK-53, ANK-54, ANK-55 and ANK-61; field names of
# meta follow ACC-10 (orchestrator/handoff/M2/CRITERIA.json).

test_that("K-M2-4: the recordings are the anchored, unchanged response bodies (ankerRef: ANK-94)", {
  files <- acc_anchor("ANK-94")$value$files
  for (f in names(files)) {
    path <- file.path(acc_m2_fixture_dir(), f)
    expect_true(file.exists(path), info = f)
    expect_identical(acc_sha256(path), files[[f]]$sha256, info = f)
  }
})

test_that("K-M2-4: the replay mock matches URL and model of the JSON body and stops instead of returning NULL", {
  sink <- new.env()
  mock <- acc_m2_replay(sink)
  s <- acc_m2_model_settings()
  req <- httr2::req_body_json(httr2::request(paste0(s$llama$base_url, "/chat/completions")),
                              list(seed = 1, model = s$llama$model, messages = list(list(role = "user", content = "x"))))
  resp <- mock(req)
  expect_identical(httr2::resp_body_json(resp)$provider, acc_anchor("ANK-94")$value$files$llama.json$response_provider)
  wrong_model <- httr2::req_body_json(httr2::request(paste0(s$llama$base_url, "/chat/completions")), list(model = "other/model"))
  expect_error(mock(wrong_model), "no recording")
  wrong_url <- httr2::req_body_json(httr2::request("https://example.invalid/v1/chat/completions"), list(model = s$llama$model))
  expect_error(mock(wrong_url), "no recording")
})

test_that("K-M2-4: extra body fields reach the JSON body unchanged; temperature = NULL omits the field (ankerRef: ANK-53, ANK-54, ANK-55, ANK-61)", {
  pol <- acc_anchor("ANK-61")$value
  for (key in names(acc_m2_model_settings())) {
    s <- acc_m2_model_settings()[[key]]
    sink <- new.env()
    httr2::local_mocked_responses(acc_m2_replay(sink))
    bk <- acc_m2_backend(s)
    res <- bk("Classify the germline variant PAH NM_000277.2:c.1A>G.", s$model, list(item_id = "x", prompt_id = "concise", model_id = key))
    expect_length(sink$requests, 1L)
    sent <- sink$requests[[1]]
    body <- sent$body
    expect_identical(body$model, s$model, info = key)
    expect_identical(body$seed, pol[[key]]$seed, info = key)
    if (key == "sol") {
      expect_false("temperature" %in% names(body), info = key)
      expect_false(grepl("\"temperature\"", sent$text, fixed = TRUE), info = key)
      expect_identical(body$reasoning_effort, acc_anchor("ANK-53")$value$reasoning_plan)
      expect_false("provider" %in% names(body))
    } else {
      expect_identical(body$temperature, pol[[key]]$temperature, info = key)
      a <- acc_anchor(if (key == "llama") "ANK-54" else "ANK-55")$value
      expect_identical(body$provider$order, list(a$endpoint_tag), info = key)
      expect_identical(body$provider$allow_fallbacks, FALSE, info = key)
      expect_identical(body$provider$quantizations, list(a$quantization), info = key)
      expect_false("reasoning" %in% names(body), info = key)
    }
    expect_identical(vapply(body$messages, `[[`, "", "role"), "user", info = key)
    expect_identical(res$text, acc_anchor("ANK-94")$value$files[[s$file]]$content, info = key)
  }
})

test_that("K-M2-4: meta holds model, usage, system_fingerprint, id, the requested routing and the serving provider of the recording (ankerRef: ANK-60, ANK-94)", {
  files <- acc_anchor("ANK-94")$value$files
  for (key in names(acc_m2_model_settings())) {
    s <- acc_m2_model_settings()[[key]]
    httr2::local_mocked_responses(acc_m2_replay(new.env()))
    meta <- acc_m2_backend(s)("Which class?", s$model, list(item_id = "x"))$meta
    rec <- jsonlite::fromJSON(file.path(acc_m2_fixture_dir(), s$file), simplifyVector = FALSE)
    f <- files[[s$file]]
    expect_identical(meta$model_snapshot, f$response_model, info = key)
    expect_identical(meta$id, f$response_id, info = key)
    expect_identical(meta$usage, rec$usage, info = key)
    # all three recordings carry "system_fingerprint": null; meta keeps the key
    expect_true("system_fingerprint" %in% names(meta), info = key)
    expect_null(meta$system_fingerprint)
    expect_true(grepl("\"system_fingerprint\":null", gsub("[[:space:]]", "",
                                                         jsonlite::toJSON(meta, auto_unbox = TRUE, null = "null")), fixed = TRUE), info = key)
    if (key == "sol") {
      expect_null(meta$provider)
      expect_null(meta$provider_order)
    } else {
      a <- acc_anchor(if (key == "llama") "ANK-54" else "ANK-55")$value
      expect_identical(meta$provider, f$response_provider, info = key)
      expect_identical(meta$provider, a$provider_name, info = key)
      expect_identical(unlist(meta$provider_order), a$endpoint_tag, info = key)
      expect_identical(unlist(meta$quantizations), a$quantization, info = key)
      expect_identical(meta$allow_fallbacks, FALSE, info = key)
    }
  }
})

test_that("K-M2-4: msa_run() writes meta as JSON into the store", {
  s <- acc_m2_model_settings()
  d <- llmsa::msa_design(data.frame(item_id = "v1", text = "PAH NM_000277.2:c.1A>G", stringsAsFactors = FALSE),
                         prompts = c(concise = "Classify {text}."),
                         models = c(sol = s$sol$model, llama = s$llama$model, qwen = s$qwen$model),
                         reps = 1, blocks = 1, order = "fixed")
  backends <- lapply(s, acc_m2_backend)
  bk <- function(prompt, model, row) backends[[row$model_id]](prompt, model, row)
  store <- tempfile(fileext = ".sqlite")
  httr2::local_mocked_responses(acc_m2_replay(new.env()))
  runs <- llmsa::msa_run(d, bk, parse = llmsa::parse_choice(acc_m2_classes(), whole_word = TRUE), store = store, verbose = FALSE)
  stored <- acc_m2_store_rows(store)
  expect_identical(nrow(stored), 3L)
  files <- acc_anchor("ANK-94")$value$files
  for (i in seq_len(nrow(stored))) {
    key <- stored$model_id[i]
    meta <- jsonlite::fromJSON(stored$meta[i], simplifyVector = FALSE)
    expect_identical(meta$id, files[[s[[key]]$file]]$response_id, info = key)
    expect_identical(meta$model_snapshot, files[[s[[key]]$file]]$response_model, info = key)
    if (key != "sol") expect_identical(meta$provider, files[[s[[key]]$file]]$response_provider, info = key)
    expect_identical(stored$value[i], "Uncertain significance", info = key)
  }
})

test_that("K-M2-4: an HTTP 4xx answer becomes an error entry of msa_run(), the run continues", {
  s <- acc_m2_model_settings()
  d <- llmsa::msa_design(data.frame(item_id = c("v1", "v2"), text = c("a", "b"), stringsAsFactors = FALSE),
                         prompts = c(concise = "Classify {text}."), models = c(llama = s$llama$model),
                         reps = 1, blocks = 1, order = "fixed")
  calls <- 0L
  httr2::local_mocked_responses(function(req) {
    calls <<- calls + 1L
    if (calls == 1L) {
      return(httr2::response(status_code = 400L, url = httr2::req_get_url(req), method = "POST",
                             headers = list("Content-Type" = "application/json"),
                             body = charToRaw("{\"error\":{\"message\":\"Unsupported parameter\",\"code\":400}}")))
    }
    acc_m2_replay(new.env())(req)
  })
  runs <- llmsa::msa_run(d, acc_m2_backend(s$llama), parse = llmsa::parse_choice(acc_m2_classes(), whole_word = TRUE),
                         verbose = FALSE)
  expect_identical(nrow(runs), 2L)
  first <- runs[runs$position == 1L, , drop = FALSE]
  second <- runs[runs$position == 2L, , drop = FALSE]
  expect_false(is.na(first$error))
  expect_true(grepl("400", first$error, fixed = TRUE))
  expect_true(is.na(first$value))
  expect_true(is.na(second$error))
  expect_identical(second$value, "Uncertain significance")
})

test_that("K-M2-4: the interface of backend_openai_compatible() is unchanged and NEWS.md records the temperature fix (ankerRef: ANK-02)", {
  snap <- acc_api_snapshot()$functions$backend_openai_compatible
  have <- acc_signature(llmsa::backend_openai_compatible)
  expect_identical(vapply(have, `[[`, "", "name"), vapply(snap, `[[`, "", "name"))
  expect_identical(lapply(have, `[[`, "default"), lapply(snap, `[[`, "default"))
  news <- readLines(acc_m2_require_file(file.path(acc_repo_root(), "NEWS.md"), "NEWS.md"), warn = FALSE)
  starts <- grep("^\\s*([*-]|#)", news)
  blocks <- split(news, cumsum(seq_along(news) %in% starts))
  hit <- vapply(blocks, function(b) {
    t <- paste(b, collapse = " ")
    grepl("backend_openai_compatible", t, fixed = TRUE) && grepl("temperature", t, ignore.case = TRUE) && grepl("NULL", t, fixed = TRUE)
  }, NA)
  expect_true(any(hit))
})
