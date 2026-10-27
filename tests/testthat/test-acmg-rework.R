# Regression inputs are synthetic; plan values come from shipped resources.

test_that("E21: each model report contains diagnostics from that model's observed blocks", {
  p <- ap1_test_plan(); r <- ap1_test_runs(p)
  r$meta <- vapply(r$model_id, ap1_test_meta, "", plan = p)
  llama <- which(r$model_id == "llama" & r$block == 1L)
  n_error <- floor(length(llama) * p$pilot$error_share_trigger) + 1L
  r$error[llama[seq_len(n_error)]] <- "HTTP 500 synthetic failure"
  r$value[llama[seq_len(n_error)]] <- NA_character_
  changed <- llama[n_error + 1L]
  meta <- jsonlite::fromJSON(r$meta[changed], simplifyVector = FALSE)
  meta$provider <- "Synthetic changed provider"
  meta$model_snapshot <- "synthetic-changed-model"
  r$meta[changed] <- meta_to_json(meta)
  captured <- list()
  local_mocked_bindings(msa_fit = ap1_test_fit_stub,
    msa_report = function(..., output_file, assessment) {
      captured[[basename(output_file)]] <<- assessment
      output_file
    })
  acmg_evaluate(r, p)
  for (key in names(acmg_models(p))) {
    table <- captured[[paste0("ap1-", key, ".html")]]$sections[["Repeat-day diagnostics"]]$table
    expect_identical(unique(table$model), key)
    expect_identical(table$block, seq_len(p$design$blocks))
    expect_false(anyNA(table$backend_error_share))
    if (key == "llama") {
      expect_true(table$provider_change[table$block == 1L])
      expect_true(table$model_change[table$block == 1L])
      expect_true(table$error_trigger[table$block == 1L])
      expect_equal(table$backend_error_share[table$block == 1L], n_error / length(llama),
                   tolerance = p$validation_tolerances$arithmetic)
    } else {
      expect_false(any(table$provider_change | table$model_change | table$error_trigger))
    }
  }
  partial <- r[r$model_id == "sol" & r$block == 1L, ]
  diagnostic <- acmg_repeat_day(partial, p)
  expect_identical(diagnostic$model, "sol")
  expect_identical(diagnostic$block, 1L)
  expect_null(acmg_repeat_day(partial[FALSE, ], p))
})

test_that("E22: missing providers trigger only for successful routed responses", {
  p <- ap1_test_plan()
  for (key in names(acmg_models(p))) {
    r <- data.frame(block = 1L, model_id = key, error = NA_character_,
                     meta = rep(ap1_test_meta(key, p), 2L))
    expect_false(acmg_repeat_day(r, p)$provider_change)
    for (missing in list(NULL, "", "  ", NA_character_)) {
      meta <- jsonlite::fromJSON(r$meta[2L], simplifyVector = FALSE)
      meta$provider <- missing
      changed <- r; changed$meta[2L] <- meta_to_json(meta)
      expect_identical(acmg_repeat_day(changed, p)$provider_change, key != "sol")
      all_missing <- changed; all_missing$meta[1L] <- all_missing$meta[2L]
      expect_identical(acmg_repeat_day(all_missing, p)$provider_change, key != "sol")
      changed$error[2L] <- "HTTP 500 synthetic failure"
      expect_false(acmg_repeat_day(changed, p)$provider_change)
    }
  }
})

test_that("E23: provenance uses successful row evidence and retains synthetic labels", {
  p <- ap1_test_plan()
  api <- ap1_test_meta("sol", p)
  mock <- '{"mock":true}'
  classify <- function(meta, error = rep(NA_character_, length(meta)), marker = NULL) {
    r <- data.frame(meta = meta, error = error)
    attr(r, "ap1_mode") <- marker
    acmg_provenance(r)
  }
  for (missing in c(NA_character_, "", "{}", "null")) {
    expect_identical(classify(c(api, missing)), "unverified")
    expect_identical(classify(c(api, missing), marker = "api"), "unverified")
    expect_identical(classify(missing, marker = "api"), "unverified")
    expect_identical(classify(c(mock, missing)), "synthetic")
    expect_identical(classify(c(mock, missing), marker = "mock"), "synthetic")
    expect_identical(classify(missing, marker = "mock"), "synthetic")
    expect_identical(classify(c(api, missing), c(NA, "HTTP 500")), "api")
  }
  expect_identical(classify(api), "api")
  expect_identical(classify(api, "HTTP 500"), "unverified")
  expect_identical(classify(mock, "HTTP 500"), "unverified")
  expect_identical(classify(NA_character_, "HTTP 500", "api"), "api")
  expect_identical(classify(NA_character_, "HTTP 500", "mock"), "synthetic")
  expect_identical(classify(c(api, mock), c(NA, "HTTP 500")), "api")
  expect_identical(classify(c(mock, api), c(NA, "HTTP 500")), "synthetic")
  expect_error(classify(c(api, mock)), "mixed mock/API")
  expect_error(classify(api, marker = "mock"), "mixed mock/API")
  expect_error(classify(mock, marker = "api"), "mixed mock/API")
  # Explicit metadata contradicting a persisted mode remains invalid, including
  # the pre-existing failed-row store case from test-acmg-pipeline.R.
  expect_error(classify(api, "HTTP 500", "mock"), "mixed mock/API")
})

test_that("E23: unverified API stores are rejected without changing bytes", {
  skip_if_not_installed("DBI"); skip_if_not_installed("RSQLite")
  p <- ap1_test_plan()
  rec <- empty_runs()[NA_integer_, ]
  rec$item_id <- acmg_items()$item_id[1L]
  rec$model_id <- "sol"; rec$prompt_id <- "concise"
  rec$rep <- 1L; rec$block <- 1L; rec$value <- acmg_classes(p)[1L]
  rec$error <- NA_character_; rec$meta <- NA_character_
  for (mode in c("api", "mock")) {
    store <- tempfile(fileext = ".sqlite")
    acmg_store_init(store, mode)
    append_store(store, rec)
    before <- acmg_hash(store)
    if (mode == "api") {
      expect_error(acmg_store_read(store, mode), "backend/provenance.*store unchanged")
    } else {
      expect_identical(acmg_provenance(acmg_store_read(store, mode)), "synthetic")
    }
    expect_identical(acmg_hash(store), before)
    unlink(store)
  }
})

test_that("E24: missing main items remain counted and PB accuracy uses PB references", {
  p <- ap1_test_plan(); items <- acmg_items(); main <- ap1_test_runs(p)
  absent <- items$item_id[items$source == "erepo"][1:2]
  main <- main[!(main$item_id == absent[1L] & main$model_id == "sol") &
                 main$item_id != absent[2L], ]
  pb <- acmg_design(items, p, "robustness")
  pb$value <- items$reference[match(pb$item_id, items$item_id)]
  pb$error <- NA_character_; pb$meta <- '{"mock":true}'
  pb <- acmg_join_items(pb, items)
  columns <- intersect(names(main), names(pb))
  r <- as_msa_runs(rbind(main[, columns], pb[, columns]))
  local_mocked_bindings(msa_fit = ap1_test_fit_stub, msa_report = ap1_test_report_stub)
  result <- acmg_evaluate(r, p)
  sol <- result$models$sol
  expect_setequal(sol$modal$item_id, items$item_id)
  expect_true(all(is.na(sol$modal$modal[sol$modal$item_id %in% absent])))
  expect_false(any(sol$modal$has_modal[sol$modal$item_id %in% absent]))
  expect_gte(sol$n_no_modal, length(absent))
  basis <- sol$reference_basis
  expect_equal(basis$kappa_items + basis$excluded_no_modal + basis$excluded_missing_reference, nrow(items))
  expect_identical(basis$excluded_no_modal, sol$n_no_modal)
  expect_false(sol$complete)
  expect_true(all(sol$verdicts == "not assessed"))
  expect_identical(sol$verdict, "not assessed")
  expect_true(sol$robustness$complete)
  n_reference <- sum(!is.na(items$reference))
  expect_true(all(sol$robustness$response$reference_n == n_reference))
  expect_true(all(sol$robustness$response$reference_hits == n_reference))
  expect_true(all(sol$robustness$response$reference_rate == 1))
  # An item absent everywhere has no imported metadata, even though the shipped
  # items file supplies its identifier. Metadata from PB rows fills the other.
  missing_everywhere <- r[r$item_id != absent[1L], ]
  modal <- acmg_modal_table(main[main$model_id == "sol", ], items$item_id, missing_everywhere)
  row <- modal[modal$item_id == absent[1L], ]
  expect_true(all(is.na(row[, c("reference", "source", "prior_differs_sol", "prior_differs_llama", "prior_differs_qwen")])))
  expect_false(row$has_modal)
  row <- modal[modal$item_id == absent[2L], ]
  expect_identical(row$reference, items$reference[match(absent[2L], items$item_id)])
  expect_identical(row$source, "erepo")
  expect_identical(acmg_modal_table(main[main$model_id == "sol", ], items$item_id,
                                    missing_everywhere[rev(seq_len(nrow(missing_everywhere))), ]), modal)
  conflict <- r
  at <- which(conflict$item_id == absent[2L])[1L]
  conflict$reference[at] <- setdiff(acmg_classes(p), conflict$reference[at])[1L]
  expect_error(acmg_evaluate(conflict, p), "inconsistent item column: reference")
})

test_that("E25: all evaluated response and reference classes are checked before fitting", {
  p <- ap1_test_plan(); main <- ap1_test_runs(p)
  pb <- main[1L, ]; pb$prompt_id <- unlist(p$robustness$pb_design$prompt_ids)[1L]
  calls <- 0L
  local_mocked_bindings(msa_fit = function(...) { calls <<- calls + 1L; stop("Unexpected fit") },
                        msa_report = ap1_test_report_stub)
  for (field in c("value", "reference")) for (value in c("Likely Pathogenic", "Uncertain Significance", "VOUS", "Synthetic invalid class")) {
    bad <- pb; bad[[field]] <- value
    expect_error(acmg_evaluate(as_msa_runs(rbind(main, bad)), p),
                 "AP1 runs contain unknown response or reference classes.", fixed = TRUE)
  }
  expect_identical(calls, 0L)
})

test_that("E25: PB completeness requires planned keys and its own reference column", {
  p <- ap1_test_plan(); items <- acmg_items()[1:6, ]
  pb <- acmg_design(items, p, "robustness")
  pb <- pb[pb$model_id == "sol", ]
  pb$value <- acmg_classes(p)[1L]; pb$reference <- acmg_classes(p)[1L]
  pb$error <- NA_character_
  modal <- data.frame(item_id = items$item_id, modal = acmg_classes(p)[1L],
                       has_modal = TRUE, reference = acmg_classes(p)[length(p$classes)])
  good <- acmg_robustness(pb, modal, items$item_id, p)
  expect_true(good$complete)
  expect_true(all(good$response$reference_hits == nrow(items)))
  expect_true(all(good$response$reference_n == nrow(items)))
  unknown <- pb; unknown$reference <- NA_character_
  missing <- acmg_robustness(unknown, modal, items$item_id, p)
  expect_true(all(missing$response$reference_n == 0L))
  expect_true(all(is.na(missing$response$reference_rate)))
  cases <- list()
  for (value in c(0, p$robustness$replicates + 1L, 1.5, NA)) {
    bad <- pb; bad$rep[1L] <- value; cases[[length(cases) + 1L]] <- bad
  }
  for (value in c(0L, 2L, NA_integer_)) {
    bad <- pb; bad$block[1L] <- value; cases[[length(cases) + 1L]] <- bad
  }
  bad <- pb; bad[2L, ] <- bad[1L, ]; cases[[length(cases) + 1L]] <- bad
  bad <- pb; bad$item_id[1L] <- "synthetic-unplanned-item"; cases[[length(cases) + 1L]] <- bad
  bad <- pb; bad$prompt_id[1L] <- "pb-unplanned"; cases[[length(cases) + 1L]] <- bad
  for (bad in cases) {
    result <- acmg_robustness(bad, modal, items$item_id, p)
    expect_false(result$complete)
    expect_identical(result$band, "not assessed")
    expect_null(result$effects)
    expect_match(result$reason, "planned replicate keys, block 1 and no duplicate run_key", fixed = TRUE)
  }
})

test_that("E26: a pilot response without an API id blocks provider and all cost rules", {
  p <- ap1_test_plan(); r <- ap1_test_pilot(p)
  for (key in names(acmg_models(p))) {
    bad <- r; at <- which(r$model_id == key)[1L]
    meta <- jsonlite::fromJSON(bad$meta[at], simplifyVector = FALSE)
    meta$id <- NULL; bad$meta[at] <- meta_to_json(meta)
    result <- acmg_pilot(bad, p)
    rules <- result$rules
    expect_false(rules$passed[rules$model == key & rules$rule == "provider"])
    expect_false(any(rules$passed[rules$rule == "cost"]))
    expect_true(all(rules$passed[rules$rule %in% c("parser", "4xx")]))
    expect_true(is.na(result$projected_usd))
    expect_false(result$passed)
    expect_true(all(grepl("complete API usage required", rules$reason[rules$rule == "cost"], fixed = TRUE)))
  }
})

test_that("E27: rendered reports count missing provider and fingerprint fields on successful responses", {
  skip_if_not_installed("rmarkdown"); skip_if_not_installed("knitr")
  p <- ap1_test_plan(); r <- ap1_test_runs(p)
  p$reporting$output_dir <- tempfile("ap1-missing-metadata-reports-")
  on.exit(unlink(p$reporting$output_dir, recursive = TRUE), add = TRUE)
  r$meta <- vapply(r$model_id, function(key) {
    meta <- jsonlite::fromJSON(ap1_test_meta(key, p), simplifyVector = FALSE)
    meta$system_fingerprint <- "synthetic-fingerprint"
    meta_to_json(meta)
  }, "")
  at <- which(r$model_id == "llama")[1:3]
  for (i in at) {
    meta <- jsonlite::fromJSON(r$meta[i], simplifyVector = FALSE)
    meta$provider <- if (i == at[1L]) NULL else ""
    if (i != at[2L]) meta$system_fingerprint <- NULL
    r$meta[i] <- meta_to_json(meta)
  }
  r$error[at[3L]] <- "HTTP 500 synthetic failure"
  r$value[at[3L]] <- NA_character_
  local_mocked_bindings(msa_fit = ap1_test_fit_stub)
  result <- acmg_evaluate(r, p)
  html <- paste(readLines(result$models$llama$report, warn = FALSE), collapse = "\n")
  html <- gsub("[[:space:]]+", " ", html)
  successful <- sum(r$model_id == "llama" & is.na(r$error))
  expect_match(html, sprintf("Successful responses without provider: 2 of %d; without system_fingerprint: 1 of %d.",
                             successful, successful), fixed = TRUE)
  expect_match(html, acmg_models(p)$llama$provider_name, fixed = TRUE)
  expect_match(html, "synthetic-fingerprint", fixed = TRUE)
})
