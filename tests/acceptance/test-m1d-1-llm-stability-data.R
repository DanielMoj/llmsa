# K-M1d-1: inst/extdata/llm-stability_2026-10-22/ holds the frozen item-level
# subset items.csv.gz (gzip; columns task, model, run, item_id, answer,
# correct; no raw model output), SHA256SUMS and QUELLE.txt with the commit of
# ANK-40 and the licence; data-raw/make_llm_stability.R recreates it byte for
# byte from ../quellen/daten/llm-stability_2026-10-22/; as_msa_runs() imports
# it and msa_counts() shows the structure of ANK-40 (5 models, 8 tasks, 10
# runs, items per task). Selection rule, columns and values: ACC-1 to ACC-4 in
# orchestrator/handoff/M1d/CRITERIA.json; the mini-reference reads the raw
# runs of the folders of ANK-40 (acc_m1d_llm_raw() in setup-m1d.R).

test_that("K-M1d-1: the folder holds items.csv.gz (gzip), SHA256SUMS and QUELLE.txt", {
  dir <- acc_m1d_llm_dir()
  expect_true(dir.exists(dir), label = dir)
  for (f in c("items.csv.gz", "SHA256SUMS", "QUELLE.txt")) expect_true(file.exists(file.path(dir, f)), label = paste("file", f))
  expect_true(acc_m1d_is_gzip(acc_m1d_llm_file()), label = "items.csv.gz starts with the gzip magic bytes 1f 8b")
})

test_that("K-M1d-1: items.csv.gz has exactly the columns task, model, run, item_id, answer, correct", {
  path <- acc_m1d_require(acc_m1d_llm_file(), "items.csv.gz")
  header <- gsub("\"", "", strsplit(acc_m1d_first_line(path), ",", fixed = TRUE)[[1]])
  expect_identical(header, acc_m1d_llm_columns)
})

test_that("K-M1d-1: SHA256SUMS lists every file of the folder with its SHA-256 (docs/01 §7)", {
  acc_m1d_expect_sha256sums(acc_m1d_llm_dir(), "llm-stability_2026-10-22")
})

test_that("K-M1d-1: QUELLE.txt names the commit and the licence of ANK-40 (ankerRef: ANK-40)", {
  q <- acc_m1d_text(file.path(acc_m1d_llm_dir(), "QUELLE.txt"))
  a <- acc_m1d_ank40()
  expect_true(grepl(a$commit, q, fixed = TRUE), label = paste("QUELLE.txt names commit", a$commit))
  expect_true(grepl("Apache", q, fixed = TRUE) && grepl("2.0", q, fixed = TRUE), label = "QUELLE.txt names the licence Apache 2.0")
  expect_true(grepl(a$repository, q, fixed = TRUE), label = paste("QUELLE.txt names", a$repository))
  expect_true(grepl("data-raw/make_llm_stability.R", q, fixed = TRUE), label = "QUELLE.txt names the script")
})

test_that("K-M1d-1: the subset has the structure of ANK-40: 5 models, 8 tasks, 10 runs, the items per task, one row per cell (ankerRef: ANK-40)", {
  d <- acc_m1d_llm_items()
  a <- acc_m1d_ank40()
  expect_setequal(unique(d$model), unlist(a$models))
  expect_setequal(unique(d$task), unlist(a$tasks))
  expect_setequal(unique(d$run), as.integer(unlist(a$runs)))
  expect_identical(length(unique(d$run)), as.integer(a$n_runs))
  for (t in unlist(a$tasks)) {
    n <- as.integer(a$items_per_task[[t]])
    x <- d[d$task == t, , drop = FALSE]
    expect_setequal(unique(x$item_id), seq_len(n) - 1L)
    expect_identical(nrow(x), n * length(a$models) * as.integer(a$n_runs),
                     label = sprintf("rows of task %s (items %d x models %d x runs %d)", t, n, length(a$models), a$n_runs))
  }
  key <- paste(d$task, d$model, d$run, d$item_id, sep = "|")
  expect_false(anyDuplicated(key) > 0L, label = "a task, model, run and item twice")
})

test_that("K-M1d-1: item_id, answer and correct agree with the raw runs of ANK-40; answers are option labels, never raw text (ankerRef: ANK-40)", {
  d <- acc_m1d_llm_items()
  raw <- acc_m1d_llm_raw()
  keys <- acc_m1d_llm_keys()
  dk <- paste(d$task, d$model, d$run, d$item_id, sep = "|")
  expect_setequal(dk, raw$key)
  m <- match(dk, raw$key)
  if (anyNA(m)) return(invisible())
  k <- keys[match(paste(d$task, d$item_id, sep = "|"), keys$key), , drop = FALSE]
  has <- !is.na(d$answer)
  valid <- mapply(function(a, opts, gt) a %in% c(opts, gt), d$answer[has], k$options[has], k$gt[has])
  expect_true(all(valid), label = sprintf("every answer is an option label of its item or the answer key (%d of %d invalid, first: %s)",
                                          sum(!valid), length(valid), if (any(!valid)) d$answer[has][which(!valid)[1]] else "-"))
  expect_true(max(nchar(d$answer[has]), 0L) <= max(nchar(c(unlist(k$options), k$gt))),
              label = "no answer is longer than the longest label or key")
  empty <- is.na(raw$response[m]) | !nzchar(trimws(raw$response[m]))
  expect_true(all(is.na(d$answer[empty])), label = sprintf("no answer where the raw response is empty (%d rows)", sum(empty)))
  found <- acc_m1d_answer_in_response(d$answer[has], raw$response[m][has])
  expect_true(all(found), label = sprintf("the label of every answer occurs in its raw response (%d of %d not found)", sum(!found), length(found)))
  want <- ifelse(has, d$answer == k$gt, NA)
  expect_identical(d$correct, want, label = "correct = (answer == answer key), missing where answer is missing (ACC-2)")
})

test_that("K-M1d-1: as_msa_runs() imports every task and msa_counts() shows the models and n = items x runs of ANK-40 (ankerRef: ANK-40)", {
  d <- acc_m1d_llm_items()
  a <- acc_m1d_ank40()
  for (t in unlist(a$tasks)) {
    x <- d[d$task == t, , drop = FALSE]
    runs <- acc_m1d_llm_runs(x, "correct")
    expect_s3_class(runs, "msa_runs")
    cnt <- msa_counts(runs)
    expect_setequal(cnt$model_id, unlist(a$models))
    expect_identical(nrow(cnt), length(a$models), label = paste("msa_counts() rows of task", t))
    expect_true(all(cnt$n == as.integer(a$items_per_task[[t]]) * as.integer(a$n_runs)),
                label = sprintf("msa_counts() n = %d items x %d runs for every model of task %s", as.integer(a$items_per_task[[t]]), a$n_runs, t))
    expect_identical(length(unique(runs$rep)), as.integer(a$n_runs), label = paste("runs of task", t))
    nominal <- acc_m1d_llm_runs(x, "answer")
    expect_identical(sum(is.na(nominal$value)), sum(is.na(x$answer)), label = paste("missing answers stay missing in task", t))
  }
})

test_that("K-M1d-1: data-raw/make_llm_stability.R recreates items.csv.gz byte for byte from ../quellen/daten/llm-stability_2026-10-22/", {
  target <- file.path("inst", "extdata", acc_m1d_llm_folder, "items.csv.gz")
  run <- acc_m1d_run_data_raw("make_llm_stability.R", remove = target)
  on.exit(unlink(run$work, recursive = TRUE), add = TRUE)
  expect_identical(run$status, 0L, label = paste("exit status;", paste(utils::tail(c(run$stdout, run$stderr), 15), collapse = " | ")))
  made <- file.path(run$copy, target)
  expect_true(file.exists(made), label = "the script writes items.csv.gz")
  if (file.exists(made)) {
    expect_identical(acc_sha256(made), acc_sha256(acc_m1d_llm_file()),
                     label = paste("SHA-256 of the recreated items.csv.gz; LC_COLLATE of the run:", Sys.getenv("LC_COLLATE")))
  }
})

test_that("K-M1d-1: without ../quellen/daten/ the script stops with a named error and leaves the frozen file alone (docs/01 §7)", {
  target <- file.path("inst", "extdata", acc_m1d_llm_folder, "items.csv.gz")
  run <- acc_m1d_run_data_raw("make_llm_stability.R", quellen = FALSE)
  on.exit(unlink(run$work, recursive = TRUE), add = TRUE)
  expect_false(identical(run$status, 0L), label = "exit status 0 without the raw data")
  expect_true(any(grepl("quellen", c(run$stdout, run$stderr), fixed = TRUE)),
              label = paste("the error names the missing folder:", paste(utils::tail(c(run$stdout, run$stderr), 5), collapse = " | ")))
  copied <- file.path(run$copy, target)
  if (file.exists(acc_m1d_llm_file())) {
    expect_identical(acc_sha256(copied), acc_sha256(acc_m1d_llm_file()), label = "items.csv.gz in the copy is unchanged")
  }
})
