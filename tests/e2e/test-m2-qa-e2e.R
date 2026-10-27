# QA / Red Team E2E counterexamples for M2 (fixed seed: 20261027)
testthat::set_max_fails(Inf)

qa_m2_fit_stub <- function(runs, type = c("numeric", "ordinal", "binary"), levels = NULL, link = "probit", ...) {
  type <- match.arg(type)
  structure(
    list(
      type = type,
      link = link,
      model = list(),
      vc = data.frame(
        source = c("item", "model", "Residual"),
        variance = c(10, 1, 1),
        stringsAsFactors = FALSE
      ),
      singular = FALSE,
      levels = levels,
      derived = character(),
      n = list(
        items = length(unique(runs$item_id)),
        prompts = length(unique(runs$prompt_id)),
        models = length(unique(runs$model_id)),
        blocks = length(unique(runs$block)),
        observations = nrow(runs),
        reps_per_cell = c(1L, 3L)
      )
    ),
    class = "msa_fit"
  )
}

qa_m2_main_runs <- function(plan, seed = 20261027L) {
  set.seed(seed)
  items <- llmsa:::acmg_items()
  classes <- llmsa:::acmg_classes(plan)
  models <- llmsa:::acmg_models(plan)
  d <- expand.grid(
    rep = seq_len(plan$design$replicates),
    prompt_id = names(plan$templates),
    item_id = items$item_id,
    model_id = names(models),
    block = seq_len(plan$design$blocks),
    stringsAsFactors = FALSE
  )
  d$position <- as.integer(stats::ave(seq_len(nrow(d)), d$block, FUN = seq_along))
  d$value <- classes[sample.int(length(classes), nrow(d), replace = TRUE)]
  d$error <- NA_character_
  d$meta <- '{"mock":true}'
  llmsa:::acmg_join_items(d, items)
}

test_that("QA-M2-001: per-model assessment Repeat-day diagnostics must not report false FALSE/NA rows for other models (seed = 20261027)", {
  for (pkg in c("yaml", "jsonlite", "digest")) skip_if_not_installed(pkg)
  set.seed(20261027L)
  plan <- llmsa:::acmg_plan()
  plan$reporting$output_dir <- tempfile("qa-m2-001-reports-")
  on.exit(unlink(plan$reporting$output_dir, recursive = TRUE), add = TRUE)

  runs <- qa_m2_main_runs(plan, seed = 20261027L)
  models <- llmsa:::acmg_models(plan)
  runs$meta <- vapply(runs$model_id, function(k) {
    m <- models[[k]]
    out <- list(id = paste0("id-", k), model_snapshot = m$id, system_fingerprint = NULL)
    if (length(m$provider_name)) out$provider <- m$provider_name
    llmsa:::meta_to_json(out)
  }, "")

  llama_b1 <- which(runs$model_id == "llama" & runs$block == 1L)
  err_idx <- utils::head(llama_b1, 100L)
  runs$error[err_idx] <- "HTTP 500 Internal Server Error"
  runs$value[err_idx] <- NA_character_
  runs$meta[llama_b1[101L]] <- llmsa:::meta_to_json(list(
    id = "id-llama-changed",
    model_snapshot = "meta-llama/llama-3.3-70b-instruct-alt",
    provider = "UnexpectedProvider",
    system_fingerprint = NULL
  ))

  captured <- list()
  local_mocked_bindings(
    msa_fit = qa_m2_fit_stub,
    msa_report = function(grr, ..., title = "", output_file = "", assessment = NULL) {
      captured[[output_file]] <<- assessment
      output_file
    },
    .package = "llmsa"
  )

  llmsa:::acmg_evaluate(runs, plan)
  expect_length(captured, 3L)

  sol_tab <- captured[[1L]]$sections[["Repeat-day diagnostics"]]$table
  expect_false(anyNA(sol_tab$backend_error_share))
  if ("llama" %in% sol_tab$model) {
    row_b1 <- sol_tab[sol_tab$model == "llama" & sol_tab$block == 1L, , drop = FALSE]
    expect_true(isTRUE(row_b1$provider_change) && isTRUE(row_b1$model_change) && isTRUE(row_b1$error_trigger))
  }
})

test_that("QA-M2-002: acmg_repeat_day flags missing or partially missing provider fields on OpenRouter API responses (seed = 20261027)", {
  for (pkg in c("yaml", "jsonlite", "digest")) skip_if_not_installed(pkg)
  set.seed(20261027L)
  plan <- llmsa:::acmg_plan()
  models <- llmsa:::acmg_models(plan)

  meta_ok <- llmsa:::meta_to_json(list(
    id = "gen-1",
    model_snapshot = models$llama$id,
    provider = models$llama$provider_name,
    system_fingerprint = NULL
  ))
  meta_missing_provider <- llmsa:::meta_to_json(list(
    id = "gen-2",
    model_snapshot = models$llama$id,
    system_fingerprint = NULL
  ))
  meta_qwen_missing <- llmsa:::meta_to_json(list(
    id = "gen-3",
    model_snapshot = models$qwen$id,
    system_fingerprint = NULL
  ))

  runs <- data.frame(
    block = c(1L, 1L, 1L, 1L),
    model_id = c("llama", "llama", "qwen", "qwen"),
    error = NA_character_,
    meta = c(meta_ok, meta_missing_provider, meta_qwen_missing, meta_qwen_missing),
    stringsAsFactors = FALSE
  )

  diag <- llmsa:::acmg_repeat_day(runs, plan)
  llama_row <- diag[diag$block == 1L & diag$model == "llama", , drop = FALSE]
  qwen_row <- diag[diag$block == 1L & diag$model == "qwen", , drop = FALSE]

  expect_true(isTRUE(llama_row$provider_change))
  expect_true(isTRUE(qwen_row$provider_change))
})

test_that("QA-M2-003: acmg_provenance and acmg_store_read never certify non-error rows without meta as api or strip synthetic from mock runs (seed = 20261027)", {
  for (pkg in c("yaml", "jsonlite", "digest", "DBI", "RSQLite")) skip_if_not_installed(pkg)
  set.seed(20261027L)
  plan <- llmsa:::acmg_plan()

  store <- tempfile(fileext = ".sqlite")
  on.exit(unlink(store), add = TRUE)
  llmsa:::acmg_store_init(store, "api")

  rec <- llmsa:::empty_runs()[NA_integer_, ]
  rec$item_id <- "erepo-001"
  rec$model_id <- "sol"
  rec$prompt_id <- "concise"
  rec$rep <- 1L
  rec$block <- 1L
  rec$value <- "Benign"
  rec$error <- NA_character_
  rec$meta <- NA_character_
  llmsa:::append_store(store, rec)

  res_api <- tryCatch(
    {
      rows <- llmsa:::acmg_store_read(store, "api")
      llmsa:::acmg_provenance(rows)
    },
    error = function(e) "rejected"
  )
  expect_false(identical(res_api, "api"))

  mock_runs <- rbind(rec, rec)
  mock_runs$rep <- c(1L, 2L)
  mock_runs$meta <- c('{"mock":true}', NA_character_)
  res_mock <- tryCatch(
    llmsa:::acmg_provenance(mock_runs),
    error = function(e) "rejected"
  )
  expect_true(res_mock %in% c("synthetic", "rejected"))
})

test_that("QA-M2-004: incomplete main-plan runs with 0 calls for an item retain all 100 items in modal, reference_basis and PB reference_n (seed = 20261027)", {
  for (pkg in c("yaml", "jsonlite", "digest")) skip_if_not_installed(pkg)
  set.seed(20261027L)
  plan <- llmsa:::acmg_plan()
  plan$reporting$output_dir <- tempfile("qa-m2-004-reports-")
  on.exit(unlink(plan$reporting$output_dir, recursive = TRUE), add = TRUE)

  items <- llmsa:::acmg_items()
  main <- qa_m2_main_runs(plan, seed = 20261027L)
  missing_item <- items$item_id[items$source == "erepo"][1L]
  main_incomplete <- main[!(main$model_id == "sol" & main$item_id == missing_item), , drop = FALSE]

  pb <- llmsa:::acmg_design(items, plan, "robustness")
  pb$value <- llmsa:::acmg_classes(plan)[1L]
  pb$error <- NA_character_
  pb$meta <- '{"mock":true}'
  pb_runs <- llmsa:::acmg_join_items(pb, items)

  cols <- intersect(names(main_incomplete), names(pb_runs))
  combined <- llmsa::as_msa_runs(rbind(main_incomplete[, cols], pb_runs[, cols]))

  local_mocked_bindings(
    msa_fit = qa_m2_fit_stub,
    msa_report = function(..., output_file = "") output_file,
    .package = "llmsa"
  )

  ev <- llmsa:::acmg_evaluate(combined, plan)
  sol <- ev$models$sol

  expect_false(sol$complete)
  basis_total <- sol$reference_basis$kappa_items +
    sol$reference_basis$excluded_no_modal +
    sol$reference_basis$excluded_missing_reference
  expect_true(
    nrow(sol$modal) == nrow(items) &&
      missing_item %in% sol$modal$item_id &&
      identical(sol$modal$has_modal[sol$modal$item_id == missing_item], FALSE) &&
      sol$n_no_modal >= 1L &&
      as.integer(basis_total) == nrow(items)
  )
  expect_true(all(sol$robustness$response$reference_n == sum(items$source == "erepo")))
})
