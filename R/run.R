#' Execute a design against a backend and keep an audit trail
#'
#' Runs every planned call of a design (or of one block of it), parses the
#' responses and records a full audit trail: timestamp, model identifier,
#' hash of the exact prompt, raw response, parsed value, latency and any
#' error. Rows are appended to `store` as they arrive, so that an
#' interrupted study can be resumed with `resume = TRUE` and no response is
#' ever lost.
#'
#' @param design An `msa_design` (see [msa_design()]).
#' @param backend A backend function, see [backends].
#' @param parse A parser function, see [parsers]. Default keeps the raw text.
#' @param block Optional block number(s) to run now; default runs all blocks.
#' @param store Optional path. Ending in `.sqlite` or `.db` writes to an
#'   SQLite table `runs` (requires packages DBI and RSQLite); otherwise a CSV
#'   file is appended to.
#' @param resume If `TRUE` and `store` exists, calls already present in the
#'   store (same block, item, prompt, model and rep) are skipped.
#' @param delay Seconds to wait between calls (rate limits).
#' @param verbose Print progress.
#'
#' @return A data.frame of class `msa_runs` with one row per call. Columns
#'   of `items` other than `text` (for example `reference`) are carried
#'   along.
#' @examples
#' truth <- c(v1 = 1.2, v2 = -0.4, v3 = 0.1)
#' lv <- c("Benign", "VUS", "Pathogenic")
#' d <- msa_design(c(v1 = "variant 1", v2 = "variant 2", v3 = "variant 3"),
#'                 prompts = c(a = "Classify {text}.", b = "Tier for {text}?"),
#'                 models = c("m1", "m2"), reps = 2, seed = 1)
#' bk <- backend_mock(truth, levels = lv, thresholds = c(-0.5, 0.5), seed = 2)
#' r <- msa_run(d, bk, parse = parse_choice(lv), verbose = FALSE)
#' head(r[, c("item_id", "prompt_id", "model_id", "rep", "value")])
#' @export
msa_run <- function(design, backend, parse = parse_identity, block = NULL,
                    store = NULL, resume = FALSE, delay = 0, verbose = TRUE) {
  if (!inherits(design, "msa_design")) stop("`design` must come from msa_design().", call. = FALSE)
  if (!is.function(backend)) stop("`backend` must be a function(prompt, model, row).", call. = FALSE)
  if (!is.function(parse)) stop("`parse` must be a function(text).", call. = FALSE)
  todo <- as.data.frame(design)
  if (!is.null(block)) todo <- todo[todo$block %in% block, , drop = FALSE]
  todo <- todo[order(todo$block, todo$position), , drop = FALSE]

  done <- NULL
  if (resume && !is.null(store) && file.exists(store)) {
    done <- read_store(store)
    key_done <- run_key(done)
    todo <- todo[!run_key(todo) %in% key_done, , drop = FALSE]
    if (verbose) message(sprintf("Resuming: %d calls already stored, %d to go.", nrow(done), nrow(todo)))
  }
  n <- nrow(todo)
  out <- vector("list", n)
  if (verbose && n > 0) message(sprintf("Running %d calls ...", n))
  for (i in seq_len(n)) {
    row <- todo[i, , drop = FALSE]
    t0 <- Sys.time()
    res <- tryCatch(backend(row$prompt, row$model, as.list(row)), error = function(e) e)
    lat <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    if (inherits(res, "error")) {
      txt <- NA_character_; meta <- NULL; err <- conditionMessage(res)
    } else if (is.list(res)) {
      txt <- as.character(res$text %||% NA_character_)[1]; meta <- res$meta; err <- NA_character_
    } else {
      txt <- as.character(res)[1]; meta <- NULL; err <- NA_character_
    }
    val <- tryCatch(parse(txt), error = function(e) NA)
    if (length(val) != 1) val <- NA
    rec <- data.frame(
      run_id = paste0(row$block, "-", row$position),
      timestamp = format(t0, "%Y-%m-%dT%H:%M:%OS3%z"),
      block = row$block, position = row$position,
      item_id = row$item_id, prompt_id = row$prompt_id, model_id = row$model_id,
      rep = row$rep, model = row$model, prompt_hash = hash_text(row$prompt),
      response = txt, value = as.character(val), latency_s = round(lat, 3),
      error = err,
      meta = if (is.null(meta)) NA_character_ else meta_to_json(meta),
      stringsAsFactors = FALSE)
    out[[i]] <- rec
    if (!is.null(store)) append_store(store, rec)
    if (verbose && (i %% 25 == 0 || i == n)) message(sprintf("  %d / %d", i, n))
    if (delay > 0 && i < n) Sys.sleep(delay)
  }
  runs <- if (n > 0) do.call(rbind, out) else empty_runs()
  if (!is.null(done)) runs <- rbind(done[, names(runs)], runs)
  runs <- runs[order(runs$block, runs$position), , drop = FALSE]
  # carry item metadata (e.g. a reference column) along, but never the text
  items <- attr(design, "items")
  extra <- setdiff(names(items), c("item_id", "text", names(runs)))
  for (col in extra) runs[[col]] <- items[[col]][match(runs$item_id, items$item_id)]
  rownames(runs) <- NULL
  as_msa_runs(runs, design = design)
}

run_key <- function(x) paste(x$block, x$item_id, x$prompt_id, x$model_id, x$rep, sep = "|")

empty_runs <- function() {
  data.frame(run_id = character(), timestamp = character(), block = integer(),
             position = integer(), item_id = character(), prompt_id = character(),
             model_id = character(), rep = integer(), model = character(),
             prompt_hash = character(), response = character(), value = character(),
             latency_s = numeric(), error = character(), meta = character(),
             stringsAsFactors = FALSE)
}

meta_to_json <- function(meta) {
  # minimal serialisation; uses jsonlite if available for fidelity
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    return(as.character(jsonlite::toJSON(meta, auto_unbox = TRUE, null = "null")))
  }
  paste(names(meta), vapply(meta, function(v) paste(format(unlist(v)), collapse = ","), ""),
        sep = "=", collapse = ";")
}

is_sqlite_path <- function(path) grepl("\\.(sqlite|sqlite3|db)$", path, ignore.case = TRUE)

append_store <- function(path, rec) {
  if (is_sqlite_path(path)) {
    if (!requireNamespace("DBI", quietly = TRUE) || !requireNamespace("RSQLite", quietly = TRUE)) {
      stop("Writing to SQLite needs packages DBI and RSQLite.", call. = FALSE)
    }
    con <- DBI::dbConnect(RSQLite::SQLite(), path)
    on.exit(DBI::dbDisconnect(con), add = TRUE)
    DBI::dbWriteTable(con, "runs", rec, append = TRUE)
  } else {
    utils::write.table(rec, path, sep = ",", row.names = FALSE,
                       col.names = !file.exists(path), append = file.exists(path),
                       qmethod = "double")
  }
  invisible(path)
}

read_store <- function(path) {
  if (is_sqlite_path(path)) {
    con <- DBI::dbConnect(RSQLite::SQLite(), path)
    on.exit(DBI::dbDisconnect(con), add = TRUE)
    x <- DBI::dbReadTable(con, "runs")
  } else {
    x <- utils::read.csv(path, stringsAsFactors = FALSE)
  }
  x$value <- as.character(x$value)
  x
}

#' Import results produced elsewhere
#'
#' Turns a data.frame of results from any pipeline into an `msa_runs` object,
#' so that the analysis functions can be used without running the backend
#' through this package. The minimum is one row per call with the item,
#' prompt variant, model, replicate number and parsed value.
#'
#' @param x A data.frame.
#' @param item,prompt,model,rep,value,block Column names in `x`.
#' @param design Optional `msa_design` the results belong to.
#' @return An `msa_runs` data.frame.
#' @examples
#' df <- expand.grid(item_id = paste0("I", 1:5), prompt_id = c("P1", "P2"),
#'                   model_id = c("m1", "m2"), rep = 1:2, stringsAsFactors = FALSE)
#' df$value <- rnorm(nrow(df))
#' r <- as_msa_runs(df)
#' class(r)
#' @export
as_msa_runs <- function(x, item = "item_id", prompt = "prompt_id", model = "model_id",
                        rep = "rep", value = "value", block = "block", design = NULL) {
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  need <- c(item = item, prompt = prompt, model = model, rep = rep, value = value)
  stop_if_missing_cols(x, unname(need), "results")
  names(x)[match(unname(need), names(x))] <- c("item_id", "prompt_id", "model_id", "rep", "value")
  if (!block %in% names(x)) x$block <- 1L else names(x)[names(x) == block] <- "block"
  x$item_id <- as.character(x$item_id); x$prompt_id <- as.character(x$prompt_id)
  x$model_id <- as.character(x$model_id)
  structure(x, class = c("msa_runs", "data.frame"), design = design)
}

#' @export
print.msa_runs <- function(x, ...) {
  cat(sprintf("LLM runs: %d calls, %d items, %d prompt variants, %d models, %d block(s)\n",
              nrow(x), length(unique(x$item_id)), length(unique(x$prompt_id)),
              length(unique(x$model_id)), length(unique(x$block))))
  if ("error" %in% names(x)) {
    cat(sprintf("  backend errors: %d   unparseable responses: %d\n",
                sum(!is.na(x$error)), sum(is.na(x$value) & is.na(x$error))))
  } else {
    cat(sprintf("  missing values: %d\n", sum(is.na(x$value))))
  }
  if ("latency_s" %in% names(x) && any(!is.na(x$latency_s))) {
    cat(sprintf("  median latency: %.2f s\n", stats::median(x$latency_s, na.rm = TRUE)))
  }
  print(utils::head(as.data.frame(x)[, intersect(c("block", "item_id", "prompt_id", "model_id", "rep", "value"), names(x))]), row.names = FALSE)
  invisible(x)
}

#' Realised cell counts of a study
#'
#' Tabulates how many parsed values exist per item, prompt and model, which
#' documents the realised (possibly unbalanced) design in the report.
#' @param runs An `msa_runs` object.
#' @return A data.frame with the number of planned and valid responses per
#'   prompt-model combination, plus the number of items with fewer than two
#'   valid replicates.
#' @export
msa_counts <- function(runs) {
  ok <- !is.na(runs$value)
  tab <- stats::aggregate(cbind(n = 1, n_valid = ok) ~ prompt_id + model_id, data = runs, FUN = sum)
  per_cell <- stats::aggregate(ok ~ item_id + prompt_id + model_id, data = runs, FUN = sum)
  attr(tab, "cells_under_two") <- sum(per_cell$ok < 2)
  tab
}
