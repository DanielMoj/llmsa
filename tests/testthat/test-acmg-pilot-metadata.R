# Synthetic HTTP replies always run, including in the installed package.
# An explicit directory adds the operator recordings to the same test cases;
# missing recordings then fail. The package itself does not ship these files.
ap1_pilot_metadata_inputs <- function(plan) {
  synthetic <- lapply(names(acmg_models(plan)), function(key) {
    reply <- jsonlite::fromJSON(ap1_test_meta(key, plan), simplifyVector = FALSE)
    reply$model <- reply$model_snapshot
    reply$model_snapshot <- NULL
    text <- jsonlite::toJSON(list(classification = acmg_classes(plan)[1L]), auto_unbox = TRUE)
    reply$choices <- list(list(message = list(content = as.character(text))))
    reply
  })
  names(synthetic) <- names(acmg_models(plan))
  inputs <- list(synthetic = synthetic)
  directory <- getOption("llmsa.test.ap1_recordings")
  if (!is.null(directory)) {
    inputs$recorded <- lapply(names(synthetic), function(key) {
      path <- file.path(directory, paste0(key, ".json"))
      if (!file.exists(path)) stop("AP1 test recording missing: ", path)
      jsonlite::fromJSON(path, simplifyVector = FALSE)
    })
    names(inputs$recorded) <- names(synthetic)
  }
  inputs
}

ap1_pilot_metadata_replay <- function(replies, plan, sink, change = function(reply, key) reply) {
  force(replies); force(change)
  sink$calls <- 0L
  models <- acmg_models(plan)
  function(req) {
    body <- ap1_test_request_body(req)
    url <- httr2::req_get_url(req)
    keys <- names(models)[vapply(models, function(m) {
      identical(body[["model"]], m$id) && identical(url, paste0(m$endpoint, "/chat/completions"))
    }, logical(1))]
    if (length(keys) != 1L) stop("Unexpected URL or model in AP1 metadata replay")
    sink$calls <- sink$calls + 1L
    reply <- change(replies[[keys]], keys)
    httr2::new_response(method = "POST", url = url, status_code = 200L,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw(jsonlite::toJSON(reply, auto_unbox = TRUE, null = "null", digits = 17)))
  }
}

test_that("E31: missing serving providers from the real backend produce failed pilot rules", {
  skip_if_not_installed("httr2")
  p <- ap1_test_plan(); ap1_test_keys()
  on.exit(Sys.unsetenv(c("OPENAI_API_KEY", "OPENROUTER_API_KEY")), add = TRUE)
  backends <- acmg_api_backends(p)
  inputs <- ap1_pilot_metadata_inputs(p)
  for (input in names(inputs)) for (key in c("llama", "qwen")) {
    for (missing in c("absent", "null", "empty", "whitespace")) {
      sink <- new.env(parent = emptyenv())
      change <- function(reply, model) {
        reply[["provider"]] <- NULL
        if (missing != "absent") reply["provider"] <- list(switch(missing, null = NULL, empty = "", whitespace = " \t\n"))
        reply
      }
      httr2::local_mocked_responses(ap1_pilot_metadata_replay(inputs[[input]], p, sink, change))
      model <- acmg_models(p)[[key]]
      response <- backends[[key]]("Synthetic metadata test", model$id, list(model_id = key))
      expect_identical(sink$calls, 1L)
      expect_identical(response$meta[["provider_order"]], as.list(unlist(model$provider_order)))
      r <- ap1_test_pilot(p)
      at <- which(r$model_id == key)[1L]
      r$meta[at] <- meta_to_json(response$meta)
      result <- acmg_pilot(r, p)
      expect_identical(nrow(result$rules), 4L * length(p$models))
      rule <- result$rules[result$rules$model == key & result$rules$rule == "provider", ]
      expect_identical(rule$passed, FALSE)
      expect_match(rule$reason, "missing provider", fixed = TRUE)
      expect_match(rule$reason, "GET /api/v1/generation", fixed = TRUE)
      expect_match(rule$reason, inputs[[input]][[key]][["id"]], fixed = TRUE)
      expect_true(all(result$rules$passed[result$rules$rule %in% c("4xx", "parser")]))
      expect_false(result$passed)
      response$meta[["provider"]] <- model$provider_name
      r$meta[at] <- meta_to_json(response$meta)
      control <- acmg_pilot(r, p)
      other <- result$rules$rule != "provider"
      expect_identical(result$rules[other, ], control$rules[other, ])
      expect_identical(result$summary, control$summary)
      expect_identical(result$tokens, control$tokens)
      expect_true(control$rules$passed[control$rules$model == key & control$rules$rule == "provider"])
    }
  }
})

test_that("E31 and E32: API evidence requires exact field names and explains failed provider rules", {
  p <- ap1_test_plan(); r <- ap1_test_pilot(p)
  for (key in names(acmg_models(p))) for (field in c("id", "model_snapshot")) {
    at <- which(r$model_id == key)[1L]
    bad <- r
    meta <- jsonlite::fromJSON(r$meta[at], simplifyVector = FALSE)
    meta[[paste0(field, "_requested")]] <- meta[[field]]
    meta[[field]] <- NULL
    bad$meta[at] <- meta_to_json(meta)
    result <- acmg_pilot(bad, p)
    rules <- result$rules
    provider <- rules[rules$model == key & rules$rule == "provider", ]
    expect_false(provider$passed)
    expect_match(provider$reason, "missing API evidence", fixed = TRUE)
    expect_match(provider$reason, "meta$id", fixed = TRUE)
    expect_match(provider$reason, "meta$model_snapshot", fixed = TRUE)
    expect_false(any(rules$passed[rules$rule == "cost"]))
    expect_true(all(rules$passed[rules$rule %in% c("parser", "4xx")]))
    expect_identical(acmg_provenance(bad), "unverified")
    if (field == "id") {
      expect_true(is.na(result$tokens$id[which(result$tokens$model == key)[1L]]))
      if (key != "sol") {
        meta[["provider"]] <- NULL
        meta$provider_order <- acmg_models(p)[[key]]$provider_order
        bad$meta[at] <- meta_to_json(meta)
        missing <- acmg_pilot(bad, p)$rules
        reason <- missing$reason[missing$model == key & missing$rule == "provider"]
        expect_match(reason, "meta$id: unavailable", fixed = TRUE)
        expect_false(grepl(meta$id_requested, reason, fixed = TRUE))
      }
    }
  }
  extra <- r
  meta <- jsonlite::fromJSON(extra$meta[1L], simplifyVector = FALSE)
  meta$mock_description <- TRUE
  extra$meta[1L] <- meta_to_json(meta)
  expect_identical(acmg_provenance(extra), "api")
  expect_identical(acmg_pilot(extra, p), acmg_pilot(r, p))
})

test_that("E31: similarly named usage fields cannot substitute for measured token counts", {
  p <- ap1_test_plan(); r <- ap1_test_pilot(p)
  for (field in c("usage", "completion_tokens", "completion_tokens_details", "reasoning_tokens")) {
    bad <- r
    bad$meta <- vapply(r$meta, function(text) {
      meta <- jsonlite::fromJSON(text, simplifyVector = FALSE)
      if (field == "usage") {
        meta$usage_estimate <- meta$usage; meta$usage <- NULL
      } else if (field == "reasoning_tokens") {
        details <- meta$usage$completion_tokens_details
        details$reasoning_tokens_estimate <- details$reasoning_tokens; details$reasoning_tokens <- NULL
        meta$usage$completion_tokens_details <- details
      } else {
        usage <- meta$usage
        usage[[paste0(field, "_estimate")]] <- usage[[field]]; usage[[field]] <- NULL
        meta$usage <- usage
      }
      meta_to_json(meta)
    }, "")
    result <- acmg_pilot(bad, p)
    if (field %in% c("usage", "completion_tokens")) {
      expect_true(all(is.na(result$tokens$completion_tokens)))
      expect_false(any(result$rules$passed[result$rules$rule == "cost"]))
    } else {
      expect_true(all(is.na(result$tokens$reasoning_tokens)))
      expect_true(all(is.na(result$summary$reasoning_median)))
      expect_true(all(is.na(result$summary$reasoning_q90)))
      expect_identical(result$projected_usd, acmg_pilot(r, p)$projected_usd)
    }
  }
})

test_that("E31: the API pilot and resume report all rules and block collection before further calls", {
  for (pkg in c("httr2", "DBI", "RSQLite")) skip_if_not_installed(pkg)
  p <- ap1_test_plan(); ap1_test_keys()
  on.exit(Sys.unsetenv(c("OPENAI_API_KEY", "OPENROUTER_API_KEY")), add = TRUE)
  items <- acmg_items(); insaid <- items[items$source == "insaid", ]
  synthetic <- data.frame(gene = insaid$gene, cdna = sub("^[^:]+:", "", insaid$hgvs),
    protein = "p.SyntheticProtected", classification = "Benign", status = "Validated")
  path <- tempfile(fileext = ".tsv")
  on.exit(unlink(path), add = TRUE)
  utils::write.table(synthetic, path, sep = "\t", quote = FALSE, row.names = FALSE)
  expected_hash <- acmg_hash(path)
  local_mocked_bindings(acmg_insaid_hash = function() expected_hash)
  for (replies in ap1_pilot_metadata_inputs(p)) {
    sink <- new.env(parent = emptyenv())
    httr2::local_mocked_responses(ap1_pilot_metadata_replay(replies, p, sink, function(reply, key) {
      reply[["provider"]] <- NULL
      reply
    }))
    store <- tempfile(fileext = ".sqlite")
    on.exit(unlink(store), add = TRUE)
    args <- c("--part", "pilot", "--backend", "api", "--store", store)
    output <- capture.output(acmg_run_cli(args))
    expect_identical(sink$calls, as.integer(length(p$models) * p$pilot$calls_per_model))
    rows <- acmg_store_read(store, "api")
    expect_identical(nrow(rows), sink$calls)
    expect_true(all(is.na(rows$error)))
    lines <- output[grepl("^(sol|llama|qwen) (4xx|provider|parser|cost) (passed|failed):", output)]
    expect_length(lines, 4L * length(p$models))
    for (key in c("llama", "qwen")) {
      line <- lines[startsWith(lines, paste(key, "provider failed:"))]
      expect_length(line, 1L)
      expect_match(line, "GET /api/v1/generation", fixed = TRUE)
      expect_match(line, replies[[key]][["id"]], fixed = TRUE)
    }
    before <- acmg_hash(store)
    resumed <- capture.output(acmg_run_cli(args))
    expect_identical(resumed, output)
    expect_identical(acmg_hash(store), before)
    expect_error(acmg_run_cli(c("--part", "main", "--backend", "api", "--store", store)),
                 "^AP1 pilot has not passed: .*llama provider.*qwen provider.*; no API calls made\\.$")
    expect_error(acmg_run_cli(c("--part", "robustness", "--backend", "api", "--store", store,
                                "--insaid-path", path)),
                 "^AP1 pilot has not passed: .*llama provider.*qwen provider.*; no API calls made\\.$")
    expect_identical(sink$calls, nrow(rows))
    expect_identical(acmg_hash(store), before)
  }
})

test_that("E31: direct and stored evaluations retain pilot rules when providers are absent", {
  for (pkg in c("httr2", "DBI", "RSQLite")) skip_if_not_installed(pkg)
  p <- ap1_test_plan(); ap1_test_keys()
  on.exit(Sys.unsetenv(c("OPENAI_API_KEY", "OPENROUTER_API_KEY")), add = TRUE)
  assessments <- list()
  local_mocked_bindings(msa_fit = ap1_test_fit_stub, msa_report = function(..., assessment) {
    assessments[[length(assessments) + 1L]] <<- assessment
    "synthetic-report-not-rendered"
  })
  for (replies in ap1_pilot_metadata_inputs(p)) {
    sink <- new.env(parent = emptyenv())
    httr2::local_mocked_responses(ap1_pilot_metadata_replay(replies, p, sink, function(reply, key) {
      reply[["provider"]] <- NULL
      reply
    }))
    store <- tempfile(fileext = ".sqlite")
    p$reporting$output_dir <- tempfile("ap1-pilot-evaluation-")
    on.exit(unlink(c(store, p$reporting$output_dir), recursive = TRUE), add = TRUE)
    capture.output(acmg_run_cli(c("--part", "pilot", "--backend", "api", "--store", store)))
    main <- ap1_test_runs(p)
    main$meta <- vapply(main$model_id, ap1_test_meta, "", plan = p)
    stored <- empty_runs()[rep(NA_integer_, nrow(main)), ]
    for (field in intersect(names(stored), names(main))) stored[[field]] <- main[[field]]
    append_store(store, stored)
    rows <- acmg_store_read(store, "api")
    joined <- acmg_join_items(rows, rbind(acmg_items(), acmg_items(pilot = TRUE)))
    before <- acmg_hash(store)
    expected <- acmg_pilot(joined, p)$rules
    direct <- acmg_evaluate(joined, p)
    expect_message(from_cli <- acmg_run_cli(c("--evaluate-only", "--backend", "api", "--store", store,
      "--report-dir", p$reporting$output_dir)), "INSAID references not loaded")
    expect_identical(from_cli, direct)
    expect_identical(direct$provenance, "api")
    for (key in names(acmg_models(p))) {
      expect_true(direct$models[[key]]$complete)
      expect_identical(direct$models[[key]]$pilot$rules, expected[expected$model == key, ])
    }
    for (assessment in tail(assessments, 2L * length(p$models))) {
      table <- assessment$sections[["Pilot result"]]$table
      expect_identical(table, expected[expected$model == table$model[1L], ])
    }
    expect_identical(sink$calls, as.integer(length(p$models) * p$pilot$calls_per_model))
    expect_identical(acmg_hash(store), before)
  }
})

test_that("E33: unverified stores identify the missing evidence and remain unchanged", {
  for (pkg in c("DBI", "RSQLite")) skip_if_not_installed(pkg)
  p <- ap1_test_plan()
  rows <- empty_runs()[rep(NA_integer_, 3L), ]
  rows$error <- c(NA_character_, NA_character_, "HTTP 500 synthetic")
  rows$meta <- c(meta_to_json(list(id = "synthetic-id")),
                 meta_to_json(list(model_snapshot = "synthetic-model")), NA_character_)
  for (mode in c("api", "mock")) {
    store <- tempfile(fileext = ".sqlite"); acmg_store_init(store, mode)
    on.exit(unlink(store), add = TRUE)
    append_store(store, rows)
    before <- acmg_hash(store)
    if (mode == "api") {
      message <- tryCatch(acmg_store_read(store, mode), error = conditionMessage)
      expect_match(message, "AP1 store backend/provenance is unverified", fixed = TRUE)
      expect_match(message, "2 successful responses", fixed = TRUE)
      expect_match(message, "meta$id", fixed = TRUE)
      expect_match(message, "meta$model_snapshot", fixed = TRUE)
      expect_match(message, "new store", fixed = TRUE)
      expect_match(message, "store unchanged", fixed = TRUE)
      expect_false(grepl("does not match --backend", message, fixed = TRUE))
    } else {
      expect_identical(acmg_provenance(acmg_store_read(store, mode)), "synthetic")
      expect_error(acmg_store_read(store, "api"), "does not match --backend")
    }
    expect_identical(acmg_hash(store), before)
  }
})

test_that("E33: a pilot with missing API ids stops with an evidence error and preserves stored calls", {
  for (pkg in c("httr2", "DBI", "RSQLite")) skip_if_not_installed(pkg)
  p <- ap1_test_plan(); ap1_test_keys()
  on.exit(Sys.unsetenv(c("OPENAI_API_KEY", "OPENROUTER_API_KEY")), add = TRUE)
  for (replies in ap1_pilot_metadata_inputs(p)) {
    sink <- new.env(parent = emptyenv())
    httr2::local_mocked_responses(ap1_pilot_metadata_replay(replies, p, sink, function(reply, key) {
      if (key == "llama") reply[["id"]] <- NULL
      reply
    }))
    store <- tempfile(fileext = ".sqlite")
    on.exit(unlink(store), add = TRUE)
    args <- c("--part", "pilot", "--backend", "api", "--store", store)
    message <- tryCatch(acmg_run_cli(args), error = conditionMessage)
    expect_match(message, "backend/provenance is unverified", fixed = TRUE)
    expect_match(message, paste(p$pilot$calls_per_model, "successful responses"), fixed = TRUE)
    expect_match(message, "meta$id", fixed = TRUE)
    expect_match(message, "meta$model_snapshot", fixed = TRUE)
    expect_match(message, "new store", fixed = TRUE)
    expect_identical(sink$calls, as.integer(length(p$models) * p$pilot$calls_per_model))
    rows <- read_store(store)
    expect_identical(nrow(rows), sink$calls)
    expect_true(all(is.na(rows$error)))
    before <- acmg_hash(store)
    expect_error(acmg_run_cli(args), "backend/provenance is unverified")
    expect_identical(sink$calls, nrow(rows))
    expect_identical(acmg_hash(store), before)
  }
})
