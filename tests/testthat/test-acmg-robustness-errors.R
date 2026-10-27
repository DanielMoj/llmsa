# ADR-011 no. 6 (docs/03 A.8 no. 4): backend errors per model and PB run, after
# run.R --part robustness, in acmg_evaluate() and in the report. Error rows are
# backend errors (column error set), not unreadable answers; nothing is enforced.

# PB runs of the first `n_items` main items from backend_mock(): `injected` names
# "<model> <prompt_id>" cells whose first calls fail with a backend error;
# p_fail adds unreadable answers, which are not backend errors.
ap1_test_pb_runs <- function(plan, n_items, injected) {
  items <- utils::head(acmg_items(), n_items)
  classes <- acmg_classes(plan)
  mock <- backend_mock(stats::setNames(seq(-2, 2, length.out = nrow(items)), items$item_id), levels = classes,
                       thresholds = stats::qnorm(seq_len(length(classes) - 1L) / length(classes)),
                       p_fail = 0.1, seed = 20261027)
  backend <- function(prompt, model, row) {
    cell <- paste(row$model_id, row$prompt_id)
    if (cell %in% names(injected) && match(row$item_id, items$item_id) <= injected[[cell]]) {
      stop("HTTP 503 Service Unavailable (synthetic)")
    }
    mock(prompt, model, row)
  }
  msa_run(acmg_design(items, plan, "robustness"), backend, parse = acmg_parser(plan), verbose = FALSE)
}

# One error row in 20 equals the trigger of 0.05 and is not marked.
ap1_test_injected <- function(plan, n_items) {
  at <- plan$pilot$error_share_trigger * n_items
  if (at != round(at) || at < 1) stop("Choose n_items so that the trigger is a whole number of rows.")
  c("sol pb12" = n_items, "llama pb03" = at + 1, "qwen pb07" = at)
}

test_that("backend errors per model and PB run count error rows only and mark shares above the trigger", {
  p <- ap1_test_plan()
  n_items <- 20L
  injected <- ap1_test_injected(p, n_items)
  runs <- ap1_test_pb_runs(p, n_items, injected)
  expect_gt(sum(is.na(runs$value) & is.na(runs$error)), 0L)
  got <- acmg_robustness_errors(runs, p)
  ids <- unlist(p$robustness$pb_design$prompt_ids, use.names = FALSE)
  keys <- names(acmg_models(p))
  cell <- paste(rep(keys, each = length(ids)), rep(ids, times = length(keys)))
  expect_identical(paste(got$model, got$prompt_id), cell)
  expect_identical(as.integer(got$rows), rep(n_items, length(cell)))
  want <- ifelse(cell %in% names(injected), injected[cell], 0)
  expect_identical(as.integer(got$error_rows), as.integer(want))
  expect_identical(sum(got$error_rows), sum(!is.na(runs$error)))
  expect_equal(got$backend_error_share, unname(want) / n_items, tolerance = ap1_test_tolerance(p, "arithmetic"))
  expect_identical(got$error_trigger, cell %in% c("sol pb12", "llama pb03"))
  # Main-plan rows and unplanned prompt ids are not PB runs.
  other <- runs[seq_len(3), ]
  other$prompt_id <- c("concise", "pb13", "pb")
  other$error <- "HTTP 500 Internal Server Error"
  expect_identical(acmg_robustness_errors(rbind(runs, other), p), got)
  expect_identical(nrow(acmg_robustness_errors(runs[0, ], p)), 0L)
})

test_that("run.R --part robustness prints the backend error table of the store and marks shares above the trigger", {
  for (pkg in c("DBI", "RSQLite")) skip_if_not_installed(pkg)
  p <- ap1_test_plan()
  n_items <- 20L
  injected <- ap1_test_injected(p, n_items)[c("llama pb03", "qwen pb07")]
  original_items <- acmg_items
  original_mock <- acmg_mock_backend
  # A short run: the first n_items main items, and backend errors around the mock.
  local_mocked_bindings(
    acmg_items = function(insaid_path = NULL, pilot = FALSE) {
      d <- original_items(insaid_path, pilot)
      if (pilot) d else utils::head(d, n_items)
    },
    acmg_mock_backend = function(items, plan) {
      inner <- original_mock(items, plan)
      function(prompt, model, row) {
        cell <- paste(row$model_id, row$prompt_id)
        if (cell %in% names(injected) && match(row$item_id, items$item_id) <= injected[[cell]]) {
          stop("HTTP 503 Service Unavailable (synthetic)")
        }
        inner(prompt, model, row)
      }
    })
  store <- tempfile(fileext = ".sqlite")
  on.exit(unlink(store), add = TRUE)
  output <- capture.output(acmg_run_cli(c("--part", "robustness", "--backend", "mock", "--store", store)))
  table <- acmg_robustness_errors(read_store(store), p)
  cell <- paste(table$model, table$prompt_id)
  expect_identical(nrow(table), length(p$models) * length(unlist(p$robustness$pb_design$prompt_ids)))
  expect_true(all(table$rows == n_items))
  expect_identical(as.integer(table$error_rows), as.integer(ifelse(cell %in% names(injected), injected[cell], 0)))
  expect_identical(table$error_trigger, cell == "llama pb03")
  header <- grep("AP1 robustness backend errors per PB run", output, fixed = TRUE)
  expect_length(header, 1L)
  expect_match(output[header], paste("marks shares above", format(p$pilot$error_share_trigger)), fixed = TRUE)
  expect_identical(output[-seq_len(header)], capture.output(print(table, row.names = FALSE)))
})

test_that("acmg_evaluate() and the report carry the same backend error table in the robustness part", {
  p <- ap1_test_plan()
  n_items <- 20L
  pb <- ap1_test_pb_runs(p, n_items, ap1_test_injected(p, n_items))
  main <- ap1_test_runs(p)
  cols <- intersect(names(main), names(pb))
  runs <- as_msa_runs(rbind(main[, cols], pb[, cols]))
  captured <- list()
  local_mocked_bindings(msa_fit = ap1_test_fit_stub, msa_report = function(grr, ..., output_file = "", assessment = NULL) {
    captured[[basename(output_file)]] <<- assessment
    output_file
  })
  ev <- acmg_evaluate(runs, p)
  for (key in names(acmg_models(p))) {
    want <- acmg_robustness_errors(pb[pb$model_id == key, , drop = FALSE], p)
    expect_identical(unique(want$model), key)
    expect_identical(ev$models[[key]]$robustness$errors, want, info = key)
    # Twenty of 100 items: robustness is not assessed, but the error table is reported.
    expect_identical(ev$models[[key]]$robustness$band, "not assessed", info = key)
    section <- captured[[paste0("ap1-", key, ".html")]]$sections[["Robustness backend errors"]]
    expect_identical(section$table, want, info = key)
    expect_match(section$text, "unreadable answers do not count", fixed = TRUE)
    expect_match(section$text, paste("marks shares above", format(p$pilot$error_share_trigger)), fixed = TRUE)
  }
  combined <- do.call(rbind, unname(lapply(ev$models, function(m) m$robustness$errors)))
  expect_identical(combined, acmg_robustness_errors(pb, p))
  # Without PB rows there is neither a robustness result nor an error table.
  local_mocked_bindings(msa_fit = ap1_test_fit_stub, msa_report = function(...) "synthetic-report-not-rendered")
  expect_null(acmg_evaluate(main, p)$models$sol$robustness)
})
