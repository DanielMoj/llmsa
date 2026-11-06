# Synthetic execution cases; no API access and no stored reference outputs.
resume_test_design <- function() {
  msa_design(c("001" = "first", "010" = "second"),
             prompts = c("01" = "Read {text}.", "10" = "Report {text}."),
             models = c("001" = "01.00"), reps = 2, blocks = 2, seed = 7501L)
}

resume_test_comparable <- function(x) {
  x <- as.data.frame(x)
  x <- x[, setdiff(names(x), c("timestamp", "latency_s")), drop = FALSE]
  rownames(x) <- NULL
  x
}

test_that("CSV resumes preserve all text columns and skip completed calls", {
  d <- resume_test_design()
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path), add = TRUE)
  backend <- function(...) list(text = "0.810", meta = list(source = "synthetic"))
  r <- msa_run(d, backend, store = path, verbose = FALSE)
  loaded <- read_store(path)
  text <- setdiff(names(loaded), c("block", "position", "rep", "latency_s"))
  expect_true(all(vapply(loaded[text], is.character, logical(1))))
  expect_true(all(vapply(loaded[c("block", "position", "rep")], is.integer, logical(1))))
  expect_type(loaded$latency_s, "double")
  expect_identical(loaded$response, rep("0.810", nrow(d)))
  expect_identical(loaded$model, rep("01.00", nrow(d)))
  expect_identical(loaded$item_id, r$item_id)
  expect_identical(loaded$prompt_id, r$prompt_id)
  expect_identical(loaded$model_id, r$model_id)
  bytes <- readBin(path, "raw", file.size(path))
  done <- msa_run(d, function(...) stop("completed calls must not run"),
                  parse = function(...) stop("stored values must not be reparsed"),
                  store = path, resume = TRUE, verbose = FALSE)
  expect_identical(done, r)
  expect_identical(readBin(path, "raw", file.size(path)), bytes)

  # Unknown columns are text too, including an all-missing column.
  loaded[["extra column"]] <- "000.10"
  loaded$missing <- NA_character_
  utils::write.csv(loaded, path, row.names = FALSE)
  again <- read_store(path)
  expect_identical(again[["extra column"]], loaded[["extra column"]])
  expect_identical(again$missing, loaded$missing)
})

test_that("non-error aborts preserve completed rows and resume a fresh mock", {
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  d <- resume_test_design()
  new_backend <- function() backend_mock(c("001" = 0.5, "010" = -0.25), p_fail = 0.4, seed = 7502L)
  reference <- msa_run(d, new_backend(), parse = parse_number(), verbose = FALSE)
  for (extension in c("csv", "sqlite")) {
    for (abort_class in c("interrupt", "synthetic_network_abort")) {
      path <- tempfile(fileext = paste0(".", extension))
      calls <- 0L
      backend <- new_backend()
      abort <- structure(list(message = "synthetic non-error abort", call = NULL),
                          class = c(abort_class, "condition"))
      interrupted <- function(...) {
        calls <<- calls + 1L
        if (calls == 5L) stop(abort)
        backend(...)
      }
      got <- tryCatch(msa_run(d, interrupted, parse = parse_number(), store = path, verbose = FALSE),
                       interrupt = identity, synthetic_network_abort = identity)
      expect_identical(got, abort)
      expect_identical(nrow(read_store(path)), 4L)
      continued <- msa_run(d, new_backend(), parse = parse_number(), store = path,
                           resume = TRUE, verbose = FALSE)
      expect_identical(resume_test_comparable(continued), resume_test_comparable(reference))
      expect_identical(anyDuplicated(run_key(read_store(path))), 0L)
      unlink(path)
    }
  }
})

test_that("stored backend failures and unparseable answers are never retried", {
  d <- resume_test_design()
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path), add = TRUE)
  backend <- function(prompt, model, row) {
    if (row$item_id == "001") stop("synthetic backend failure")
    "no measurement"
  }
  first <- msa_run(d, backend, parse = parse_number(), store = path, verbose = FALSE)
  expect_true(all(is.na(first$value)))
  expect_true(all(!is.na(first$error[first$item_id == "001"])))
  expect_true(all(is.na(first$error[first$item_id == "010"])))
  resumed <- msa_run(d, function(...) stop("must not be retried"), store = path,
                     resume = TRUE, verbose = FALSE)
  expect_identical(resumed, first)
})

test_that("store failures leave the runner and are not backend error rows", {
  d <- resume_test_design()
  calls <- 0L
  local_mocked_bindings(append_store = function(...) stop("synthetic store failure", call. = FALSE))
  expect_error(msa_run(d, function(...) { calls <<- calls + 1L; "1" },
                       store = "unused.csv", verbose = FALSE), "synthetic store failure", fixed = TRUE)
  expect_identical(calls, 1L)
})

test_that("mock row streams distinguish order, lengths, blocks and replicates", {
  truth <- stats::setNames(rep(0, 6), c("001", "010", "a:b", "a", "\u00e4", "a\u0308"))
  rows <- list(
    list(item_id = "001", prompt_id = "P", model_id = "m", block = 1L, rep = 1L),
    list(item_id = "010", prompt_id = "P", model_id = "m", block = 1L, rep = 1L),
    list(item_id = "a:b", prompt_id = "c", model_id = "m", block = 1L, rep = 1L),
    list(item_id = "a", prompt_id = "b:c", model_id = "m", block = 1L, rep = 1L),
    list(item_id = "\u00e4", prompt_id = "P", model_id = "m", block = 1L, rep = 1L),
    list(item_id = "a\u0308", prompt_id = "P", model_id = "m", block = 1L, rep = 1L))
  rows <- c(rows, list(modifyList(rows[[1L]], list(block = 2L)),
                       modifyList(rows[[1L]], list(rep = 2L))))
  fresh <- function() backend_mock(truth, sd_prompt = 0, sd_model = 0, sd_rep = 1, seed = 7503L)
  bk <- fresh()
  first <- lapply(rows, function(row) bk("synthetic", "m", row))
  expect_identical(anyDuplicated(vapply(first, function(x) x$meta$latent, 0)), 0L)
  bk <- fresh()
  expect_identical(lapply(rev(rows), function(row) bk("changed prompt text", "m", row)), rev(first))
  expect_identical(bk("synthetic", "m", rows[[1L]][c("item_id", "prompt_id", "model_id")]), first[[1L]])
  expect_identical(bk("synthetic", "m", rows[[1L]]), first[[1L]])
})

test_that("mock private draws restore existing and absent RNG state", {
  old <- .Random.seed_get()
  on.exit(.Random.seed_set(old), add = TRUE)
  row <- list(item_id = "x", prompt_id = "p", model_id = "m")
  for (failure in c(0, 1)) {
    set.seed(7504L)
    before <- .Random.seed_get()
    bk <- backend_mock(c(x = 1), seed = 7505L, p_fail = failure)
    expect_identical(.Random.seed_get(), before)
    result <- bk("synthetic", "m", row)
    expect_identical(.Random.seed_get(), before)
    .Random.seed_set(NULL)
    again <- backend_mock(c(x = 1), seed = 7505L, p_fail = failure)
    expect_null(.Random.seed_get())
    expect_identical(again("synthetic", "m", row), result)
    expect_null(.Random.seed_get())
    expect_error(again("synthetic", "m", list(item_id = "unknown")), "unknown item_id")
    expect_null(.Random.seed_get())
  }
})
