# K-M3d-3: backends against recordings. The recordings under tests/fixtures/api/
# (ANK-94) are replayed with httr2::local_mocked_responses() and matched by the
# URL and the field `model` of the JSON body as in K-M2-4 (acc_m2_replay(),
# setup-m2.R). backend_openai_compatible() and backend_ellmer() return text and
# meta (model identifier model_snapshot, serving provider provider, usage usage)
# as recorded; backend_ellmer() wraps ellmer::chat_openai_compatible() objects
# for the chat-completions endpoint of the recordings (BL-60, checked by
# running it in ACCEPTANCE M3d). HTTP errors, a timeout and empty answers
# become error rows of msa_run() and do not end the run; without ellmer,
# backend_ellmer() stops with the error message its help page documents.
# Contract details: ACC-7 to ACC-9.

test_that("K-M3d-3: the recordings are the anchored, unchanged response bodies (ankerRef: ANK-94)", {
  files <- acc_anchor("ANK-94")$value$files
  expect_setequal(names(files), c("sol.json", "llama.json", "qwen.json"))
  for (f in names(files)) {
    path <- file.path(acc_m2_fixture_dir(), f)
    expect_true(file.exists(path), label = paste(f, "exists"))
    expect_identical(acc_sha256(path), files[[f]]$sha256, label = paste("SHA-256 of", f))
  }
})

# Expected meta of a recording: model, provider (if the response has the
# field) and usage of the response body.
acc_m3d_3_expect_meta <- function(meta, key, what) {
  f <- acc_anchor("ANK-94")$value$files[[paste0(key, ".json")]]
  rec <- jsonlite::fromJSON(file.path(acc_m2_fixture_dir(), paste0(key, ".json")), simplifyVector = FALSE)
  expect_true(is.list(meta), label = sprintf("%s, %s: meta is a list", what, key))
  if (!is.list(meta)) return(invisible())
  expect_identical(meta$model_snapshot, f$response_model, label = sprintf("%s, %s: meta$model_snapshot", what, key))
  expect_identical(rec$model, f$response_model)
  if (isTRUE(f$response_has_provider_field)) {
    expect_identical(meta$provider, f$response_provider, label = sprintf("%s, %s: meta$provider", what, key))
  } else {
    expect_null(meta$provider, label = sprintf("%s, %s: meta$provider (the recording has no provider field)", what, key))
  }
  expect_identical(meta$usage, rec$usage, label = sprintf("%s, %s: meta$usage", what, key))
}

test_that("K-M3d-3: backend_openai_compatible() returns the recorded text and meta (model identifier, provider, usage) (ankerRef: ANK-94)", {
  files <- acc_anchor("ANK-94")$value$files
  settings <- acc_m2_model_settings()
  for (key in names(settings)) {
    s <- settings[[key]]
    sink <- new.env()
    httr2::local_mocked_responses(acc_m2_replay(sink))
    res <- tryCatch(acc_m2_backend(s)("Which ACMG/AMP class applies?", s$model, list(item_id = "x", prompt_id = "concise", model_id = key)),
                    error = function(e) e)
    expect_false(inherits(res, "error"), label = sprintf("%s: call (%s)", key, if (inherits(res, "error")) conditionMessage(res) else "ok"))
    if (inherits(res, "error")) next
    expect_length(sink$requests, 1L)
    expect_identical(res$text, files[[s$file]]$content, label = paste(key, "text"))
    acc_m3d_3_expect_meta(res$meta, key, "backend_openai_compatible()")
  }
})

test_that("K-M3d-3: backend_ellmer() with ellmer::chat_openai_compatible() objects returns the recorded text and meta (model identifier, provider, usage) (BL-60; ankerRef: ANK-94)", {
  files <- acc_anchor("ANK-94")$value$files
  sink <- new.env()
  httr2::local_mocked_responses(acc_m2_replay(sink))
  bk <- backend_ellmer(acc_m3d_ellmer_chats())
  for (key in c("sol", "llama", "qwen")) {
    f <- files[[paste0(key, ".json")]]
    before <- length(sink$requests)
    res <- tryCatch(bk("Which ACMG/AMP class applies?", f$request_model, list(item_id = "x", prompt_id = "concise", model_id = key)),
                    error = function(e) e)
    expect_false(inherits(res, "error"), label = sprintf("%s: call (%s)", key, if (inherits(res, "error")) conditionMessage(res) else "ok"))
    if (inherits(res, "error")) next
    expect_identical(length(sink$requests) - before, 1L, label = paste(key, "requests sent"))
    sent <- sink$requests[[length(sink$requests)]]
    expect_identical(sent$url, f$request_url)
    expect_identical(sent$body$model, f$request_model)
    expect_identical(res$text, f$content, label = paste(key, "text"))
    acc_m3d_3_expect_meta(res$meta, key, "backend_ellmer()")
  }
})

test_that("K-M3d-3: msa_run() with backend_ellmer() writes the recorded meta as JSON into the store (ankerRef: ANK-94)", {
  files <- acc_anchor("ANK-94")$value$files
  d <- msa_design(data.frame(item_id = "v1", text = "PAH NM_000277.2:c.1A>G", stringsAsFactors = FALSE),
                  prompts = c(concise = "Classify {text}."),
                  models = c(sol = files$sol.json$request_model, llama = files$llama.json$request_model,
                             qwen = files$qwen.json$request_model),
                  reps = 1, blocks = 1, order = "fixed")
  httr2::local_mocked_responses(acc_m2_replay(new.env()))
  store <- tempfile("acc-m3d-3-ellmer-", fileext = ".sqlite")
  on.exit(unlink(store), add = TRUE)
  runs <- tryCatch(msa_run(d, backend_ellmer(acc_m3d_ellmer_chats()), parse = parse_choice(acc_m2_classes(), whole_word = TRUE),
                           store = store, verbose = FALSE), error = function(e) e)
  expect_false(inherits(runs, "error"), label = sprintf("msa_run() (%s)", if (inherits(runs, "error")) conditionMessage(runs) else "ok"))
  stored <- acc_m2_store_rows(store)
  expect_identical(if (is.null(stored)) 0L else nrow(stored), 3L, label = "stored rows")
  if (is.null(stored)) return(invisible())
  for (i in seq_len(nrow(stored))) {
    key <- stored$model_id[i]
    expect_true(is.na(stored$error[i]), label = paste(key, "has no error"))
    expect_identical(stored$value[i], files[[paste0(key, ".json")]]$content, label = paste(key, "value"))
    meta <- tryCatch(jsonlite::fromJSON(stored$meta[i], simplifyVector = FALSE), error = function(e) e)
    expect_false(inherits(meta, "error"), label = paste(key, "meta is JSON"))
    if (!inherits(meta, "error")) acc_m3d_3_expect_meta(meta, key, "stored meta of backend_ellmer()")
  }
})

for (backend in c("backend_openai_compatible", "backend_ellmer")) {
  test_that(sprintf("K-M3d-3: msa_run() with %s() stores HTTP errors (500, 401), a timeout and empty answers (empty body, content null, content \"\") as error rows and continues the run",
                    backend), {
    s <- acc_m2_model_settings()$llama
    httr2::local_mocked_responses(acc_m3d_failing_replay(new.env()))
    bk <- if (backend == "backend_ellmer") backend_ellmer(list(llama = acc_m3d_ellmer_chats()$llama)) else acc_m2_backend(s)
    d <- acc_m3d_failure_design(s$model)
    store <- tempfile("acc-m3d-3-failures-", fileext = ".sqlite")
    on.exit(unlink(store), add = TRUE)
    runs <- tryCatch(suppressWarnings(suppressMessages(
      msa_run(d, bk, parse = parse_choice(acc_m2_classes(), whole_word = TRUE), store = store, verbose = FALSE))),
      error = function(e) e)
    expect_false(inherits(runs, "error"), label = sprintf("msa_run() is not ended (%s)", if (inherits(runs, "error")) conditionMessage(runs) else "ok"))
    if (inherits(runs, "error")) return(invisible())
    stored <- acc_m2_store_rows(store)
    expect_identical(nrow(runs), nrow(d), label = "rows returned by msa_run()")
    expect_identical(if (is.null(stored)) 0L else nrow(stored), nrow(d), label = "rows in the store")
    content <- acc_anchor("ANK-94")$value$files$llama.json$content
    for (tab in list(list(name = "returned", rows = runs), list(name = "stored", rows = stored))) {
      if (is.null(tab$rows)) next
      for (kind in unique(d$item_id)) {
        row <- tab$rows[tab$rows$item_id == kind, , drop = FALSE]
        label <- sprintf("%s row %s", tab$name, kind)
        expect_identical(nrow(row), 1L, label = label)
        if (nrow(row) != 1L) next
        if (startsWith(kind, "ok_")) {
          expect_true(is.na(row$error), label = paste(label, "has no error"))
          expect_identical(row$value, content, label = paste(label, "value"))
        } else {
          expect_true(!is.na(row$error) && nzchar(trimws(row$error)), label = paste(label, "is an error row"))
          expect_true(is.na(row$value), label = paste(label, "has no value"))
        }
      }
    }
  })
}

test_that("K-M3d-3: without ellmer installed, backend_ellmer() stops with the error message documented on its help page", {
  lib <- tempfile("acc-m3d-3-lib-")
  fake <- file.path(lib, "ellmer")
  dir.create(fake, recursive = TRUE)
  on.exit(unlink(lib, recursive = TRUE), add = TRUE)
  # an unloadable placeholder first on the library path hides the installed ellmer
  writeLines(c("Package: ellmer", "Version: 0.0.0", "Title: Placeholder", "Description: Not loadable.", "License: MIT"),
             file.path(fake, "DESCRIPTION"))
  script <- tempfile("acc-m3d-3-noellmer-", fileext = ".R")
  on.exit(unlink(script), add = TRUE)
  writeLines(c(
    sprintf(".libPaths(c(%s, .libPaths()))", deparse(lib)),
    "cat('ellmer loadable:', requireNamespace('ellmer', quietly = TRUE), '\\n')",
    sprintf("suppressMessages(pkgload::load_all(%s, export_all = FALSE, helpers = FALSE, quiet = TRUE))", deparse(acc_pkg_root())),
    "r <- tryCatch({ backend_ellmer(list(m = 'not a chat object')); NULL }, error = function(e) e)",
    "cat('error raised:', inherits(r, 'error'), '\\n')",
    "if (inherits(r, 'error')) cat('message:', gsub('[[:space:]]+', ' ', conditionMessage(r)), '\\n')"), script)
  res <- acc_run(file.path(R.home("bin"), "Rscript"), c("--vanilla", shQuote(script)))
  out <- c(res$stdout, res$stderr)
  expect_true(any(grepl("ellmer loadable: FALSE", out, fixed = TRUE)), label = paste("ellmer hidden:", paste(out, collapse = " | ")))
  expect_true(any(grepl("error raised: TRUE", out, fixed = TRUE)), label = paste("backend_ellmer() stops:", paste(out, collapse = " | ")))
  msg <- sub("^message: ", "", grep("^message: ", res$stdout, value = TRUE))
  expect_length(msg, 1L)
  if (length(msg) != 1L) return(invisible())
  norm <- function(x) tolower(trimws(gsub("[[:space:]]+", " ", gsub("[`'\"‘’“”]", "", x))))
  expect_true(nzchar(norm(msg)))
  expect_true(grepl(norm(msg), norm(acc_m1b_rd_text("backends")), fixed = TRUE),
              label = sprintf("man/backends.Rd documents the message %s", encodeString(trimws(msg), quote = "\"")))
})
