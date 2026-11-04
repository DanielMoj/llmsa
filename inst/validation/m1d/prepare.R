# Offline preparation helpers for the M1d datasets (ADR-049).
# These functions neither load llmsa nor access the network.

m1d_abort <- function(...) stop("M1d preparation: ", ..., call. = FALSE)

m1d_anchor <- function(root, id) {
  path <- file.path(root, "reference", "anchors", paste0(id, ".json"))
  if (!file.exists(path)) m1d_abort("missing anchor: ", path)
  a <- tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE),
    error = function(e) m1d_abort("cannot read anchor ", id, ": ", conditionMessage(e)))
  fields <- c("id", "value", "unit", "tolerance", "source_url", "quote", "retrieved")
  if (!identical(a$id, id) || !all(fields %in% names(a))) m1d_abort("invalid anchor: ", id)
  a
}

m1d_sha256 <- function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE)

m1d_input <- function(root, folder, name, sha256) {
  path <- file.path(dirname(root), "quellen", "daten", folder, name)
  if (!file.exists(path)) m1d_abort("missing quellen input: ", path)
  if (!identical(m1d_sha256(path), sha256)) m1d_abort("quellen SHA-256 mismatch: ", path)
  path
}

m1d_order <- function(d, columns = names(d)) {
  ord <- do.call(order, c(unname(d[columns]), list(na.last = TRUE, method = "radix")))
  d <- d[ord, , drop = FALSE]
  rownames(d) <- NULL
  d
}

m1d_options <- function(question, task) {
  if (length(question) != length(task) || anyNA(question) || anyNA(task)) {
    m1d_abort("missing or mismatched question/task fields")
  }
  lapply(seq_along(question), function(i) {
    if (task[i] == "navigate") return(c("Yes", "No"))
    opts <- unique(regmatches(question[i], gregexpr("\\([A-Z]\\)", question[i]))[[1L]])
    if (!length(opts)) m1d_abort("question without option labels in task ", task[i])
    opts
  })
}

# Only parenthesized ASCII letters are labels; bare articles/pronouns are not.
# All occurrences count, including quoted alternatives. Repeating one label is
# unambiguous, but two distinct valid labels are not. No answer key is an input.
m1d_parse_answers <- function(response, options) {
  if (length(response) != length(options)) m1d_abort("mismatched response/options fields")
  answer <- rep(NA_character_, length(response))
  reason <- rep("empty", length(response))
  for (i in seq_along(response)) {
    r <- response[i]
    if (is.na(r) || !nzchar(trimws(r))) next
    if (setequal(options[[i]], c("Yes", "No"))) {
      found <- regmatches(r, gregexpr("(?i)(?<![A-Za-z0-9_])(yes|no)(?![A-Za-z0-9_])", r, perl = TRUE))[[1L]]
      found <- ifelse(tolower(found) == "yes", "Yes", "No")
    } else {
      found <- toupper(regmatches(r, gregexpr("\\([A-Za-z]\\)", r))[[1L]])
    }
    found <- unique(found[found %in% options[[i]]])
    reason[i] <- if (!length(found)) "no_label" else if (length(found) > 1L) "ambiguous" else "parsed"
    if (length(found) == 1L) answer[i] <- found
  }
  data.frame(answer = answer, reason = reason, stringsAsFactors = FALSE)
}

m1d_correct <- function(answer, key) {
  if (length(answer) != length(key) || anyNA(key)) m1d_abort("missing or mismatched answer key")
  ifelse(is.na(answer), NA, answer == key)
}

m1d_config <- function(x) {
  # The evaluation table uses single-quoted dictionaries of scalar values.
  # Parse this restricted representation as JSON, never as executable code.
  tryCatch(jsonlite::fromJSON(gsub("'", "\"", x, fixed = TRUE), simplifyVector = FALSE),
    error = function(e) m1d_abort("invalid source configuration: ", conditionMessage(e)))
}

m1d_same_config <- function(got, expected) {
  setequal(names(got), names(expected)) &&
    all(vapply(names(expected), function(k) isTRUE(all.equal(got[[k]], expected[[k]])), logical(1)))
}

m1d_validate_llm <- function(d, anchor) {
  required <- c("task", "model", "run", "item_id", "gt", "question", "response")
  if (!all(required %in% names(d)) || anyNA(d[c("task", "model", "run", "item_id", "gt", "question")])) {
    m1d_abort("incomplete llm-stability schema or keys")
  }
  if (!setequal(unique(d$task), unlist(anchor$tasks)) ||
      !setequal(unique(d$model), unlist(anchor$models)) ||
      !setequal(unique(d$run), unlist(anchor$runs))) m1d_abort("llm-stability levels differ from ANK-40")
  if (anyDuplicated(d[c("task", "model", "run", "item_id")])) m1d_abort("duplicate llm-stability key")
  for (task in unlist(anchor$tasks)) {
    x <- d[d$task == task, , drop = FALSE]
    ids <- seq_len(anchor$items_per_task[[task]]) - 1L
    for (model in unlist(anchor$models)) for (run in unlist(anchor$runs)) {
      got <- x$item_id[x$model == model & x$run == run]
      if (!setequal(got, ids) || length(got) != length(ids)) {
        m1d_abort("incomplete llm-stability item grid: ", task, "/", model, "/", run)
      }
    }
  }
  keys <- unique(d[c("task", "item_id", "gt", "question")])
  if (anyDuplicated(keys[c("task", "item_id")])) m1d_abort("conflicting llm-stability question or key")
  invisible(keys)
}

# Read only requested TSV columns, in bounded blocks. Quotation marks in the
# source are literal characters (not CSV quoting). The header determines the
# column positions; the submission header is additionally checked with ANK-63.
m1d_stream_tsv <- function(path, fields, consume, positions = NULL, n_columns = NULL,
                           chunk_size = 25000L) {
  # Binary connections preserve UTF-8 bytes even when the native locale is C.
  # readLines marks the strings as UTF-8; it must not transcode to native text.
  con <- gzfile(path, "rb")
  on.exit(close(con), add = TRUE)
  repeat {
    line <- readLines(con, n = 1L, warn = FALSE, encoding = "UTF-8")
    if (!length(line)) m1d_abort("TSV header missing: ", path)
    header <- strsplit(sub("^#", "", line), "\t", fixed = TRUE)[[1L]]
    if (all(fields %in% header)) break
    if (!startsWith(line, "#")) m1d_abort("data before TSV header: ", path)
  }
  if (anyDuplicated(header) || (!is.null(n_columns) && length(header) != n_columns)) {
    m1d_abort("invalid TSV header: ", path)
  }
  if (!is.null(positions) && !identical(as.integer(match(names(positions), header)), as.integer(unlist(positions)))) {
    m1d_abort("submission header differs from ANK-63: ", path)
  }
  classes <- rep("NULL", length(header))
  classes[match(fields, header)] <- "character"
  total <- 0L
  repeat {
    lines <- readLines(con, n = chunk_size, warn = FALSE, encoding = "UTF-8")
    if (!length(lines)) break
    if (any(!nzchar(lines)) || any(startsWith(lines, "#"))) m1d_abort("unexpected blank/comment row: ", path)
    block <- tryCatch(utils::read.delim(text = paste(lines, collapse = "\n"), header = FALSE,
      col.names = header, colClasses = classes, quote = "", comment.char = "", fill = FALSE,
      na.strings = character(), stringsAsFactors = FALSE, check.names = FALSE, encoding = "UTF-8"),
      error = function(e) m1d_abort("cannot parse TSV ", path, ": ", conditionMessage(e)))
    if (nrow(block) != length(lines)) m1d_abort("TSV row count changed while parsing: ", path)
    consume(block[fields])
    total <- total + nrow(block)
  }
  if (!total) m1d_abort("TSV has no data rows: ", path)
  invisible(total)
}

m1d_ids <- function(x) {
  if (anyNA(x) || any(!grepl("^[0-9]+$", x))) m1d_abort("invalid VariationID")
  out <- suppressWarnings(as.integer(x))
  if (anyNA(out) || any(out <= 0L)) m1d_abort("VariationID outside the positive integer range")
  out
}

# Counts distinct pairs without constructing multi-million-element string keys.
m1d_submitter_counts <- function(ids, submitter_codes) {
  if (length(ids) != length(submitter_codes) || anyNA(ids) || anyNA(submitter_codes)) {
    m1d_abort("missing or mismatched variant/submitter codes")
  }
  if (!length(ids)) return(data.frame(variation_id = integer(), submitters = integer()))
  ord <- order(ids, submitter_codes, method = "radix")
  ids <- ids[ord]
  codes <- submitter_codes[ord]
  first <- c(TRUE, diff(ids) != 0L | diff(codes) != 0L)
  counts <- rle(ids[first])
  data.frame(variation_id = counts$values, submitters = counts$lengths)
}

m1d_draw_variants <- function(counts, specification) {
  eligible <- sort(unique(counts$variation_id[counts$submitters >= specification$min_distinct_submitters]),
                   method = "radix")
  if (length(eligible) < specification$n_variants) m1d_abort("too few eligible ClinVar variants")
  rng <- RNGkind()
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  seed <- if (had_seed) get(".Random.seed", envir = .GlobalEnv) else NULL
  on.exit({
    do.call(RNGkind, as.list(rng))
    if (had_seed) assign(".Random.seed", seed, envir = .GlobalEnv) else
      if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  set.seed(specification$seed)
  # sample.int also handles a population consisting of one numeric identifier.
  eligible[sample.int(length(eligible), specification$n_variants)]
}

m1d_gene_map <- function(d) {
  if (anyNA(d$variation_id)) m1d_abort("missing ClinVar gene-map VariationID")
  d <- m1d_order(d[c("variation_id", "gene")])
  if (!nrow(d)) return(d)
  same_id <- c(FALSE, diff(d$variation_id) == 0L)
  previous <- c(NA_character_, head(d$gene, -1L))
  same_gene <- (is.na(d$gene) & is.na(previous)) |
    (!is.na(d$gene) & !is.na(previous) & d$gene == previous)
  if (any(same_id & !same_gene)) {
    m1d_abort("conflicting gene mappings across ClinVar assembly rows")
  }
  d[!same_id, , drop = FALSE]
}

m1d_gene_member <- function(gene, genes) {
  vapply(strsplit(gene, ";", fixed = TRUE), function(x) any(x %in% genes), logical(1))
}

m1d_dates <- function(x, specification) {
  old <- Sys.getlocale("LC_TIME")
  on.exit(Sys.setlocale("LC_TIME", old), add = TRUE)
  if (!nzchar(Sys.setlocale("LC_TIME", "C"))) m1d_abort("cannot select the C date locale")
  x[x %in% c(specification$date_missing, "")] <- NA_character_
  dates <- as.Date(x, format = specification$date_format)
  if (any(!is.na(x) & is.na(dates))) m1d_abort("unreadable ClinVar DateLastEvaluated")
  format(dates, "%Y-%m-%d")
}

m1d_clinvar_index <- function(path, specification, schema, chunk_size = 25000L) {
  pairs <- excluded <- list()
  submitters <- character()
  total <- 0L
  m1d_stream_tsv(path, c("VariationID", "ClinicalSignificance", "Submitter"), function(d) {
    ids <- m1d_ids(d$VariationID)
    keep <- d$ClinicalSignificance %in% unlist(specification$classes)
    total <<- total + nrow(d)
    excluded[[length(excluded) + 1L]] <<- ids[!keep]
    names <- d$Submitter[keep]
    if (anyNA(names) || any(!nzchar(names))) m1d_abort("missing ClinVar Submitter")
    submitters <<- c(submitters, setdiff(unique(names), submitters))
    pairs[[length(pairs) + 1L]] <<- unique(data.frame(variation_id = ids[keep],
      submitter = match(names, submitters)))
  }, positions = schema$columns, n_columns = schema$n_columns_file, chunk_size = chunk_size)
  p <- do.call(rbind, pairs)
  list(counts = m1d_submitter_counts(p$variation_id, p$submitter),
       excluded_ids = unlist(excluded, use.names = FALSE), n_rows = total)
}

m1d_write_text <- function(lines, path) {
  writeBin(charToRaw(paste0(paste(enc2utf8(lines), collapse = "\n"), "\n")), path)
}

m1d_write_csv <- function(d, path) {
  # Frozen schemas contain character, integer and logical columns. Serialize
  # those explicitly: write.table transcodes UTF-8 to native text (or <U+...>)
  # in the C locale even when its output connection is binary.
  quote_text <- function(x) paste0('"', gsub('"', '""', enc2utf8(x), fixed = TRUE, useBytes = TRUE), '"')
  columns <- lapply(d, function(x) {
    missing <- is.na(x)
    if (is.character(x)) out <- quote_text(x) else if (is.integer(x) || is.logical(x)) out <- as.character(x) else
      m1d_abort("CSV column must be character, integer or logical")
    out[missing] <- ""
    out
  })
  lines <- c(paste(quote_text(names(d)), collapse = ","),
             if (nrow(d)) do.call(paste, c(columns, list(sep = ","))) else character())
  con <- gzfile(path, "wb", compression = 9L)
  on.exit(close(con), add = TRUE)
  writeLines(lines, con, sep = "\n", useBytes = TRUE)
}

m1d_manifest <- function(stage) {
  files <- sort(setdiff(list.files(stage, all.files = TRUE, no.. = TRUE), "SHA256SUMS"), method = "radix")
  hashes <- vapply(file.path(stage, files), m1d_sha256, "")
  m1d_write_text(paste(hashes, files, sep = "  "), file.path(stage, "SHA256SUMS"))
}

m1d_check_sizes <- function(stage, target, limits) {
  files <- list.files(stage, full.names = TRUE, recursive = TRUE, all.files = TRUE)
  sizes <- file.size(files)
  if (any(sizes > limits$file_max_bytes)) m1d_abort("file exceeds ANK-TOL.data_size")
  large <- files[sizes > limits$gzip_above_bytes]
  if (any(!grepl("\\.csv\\.gz$", large))) m1d_abort("large file must be .csv.gz")
  if (sum(sizes) > limits$folder_max_bytes) m1d_abort("folder exceeds ANK-TOL.data_size")
  other <- list.files(dirname(target), full.names = TRUE, recursive = TRUE, all.files = TRUE)
  other <- other[!startsWith(other, paste0(target, "/")) & !startsWith(other, paste0(stage, "/"))]
  if (sum(sizes) + sum(file.size(other)) > limits$extdata_total_max_bytes) {
    m1d_abort("inst/extdata exceeds ANK-TOL.data_size")
  }
  invisible(sum(sizes))
}

# Stage on the target filesystem. Validate before replacing any frozen file;
# restore the original directory if the final rename fails.
m1d_publish <- function(stage, target) {
  backup <- tempfile(".m1d-previous-", tmpdir = dirname(target))
  had_target <- dir.exists(target)
  if (had_target && !file.rename(target, backup)) m1d_abort("cannot preserve previous dataset: ", target)
  if (!file.rename(stage, target)) {
    if (had_target && !file.rename(backup, target)) m1d_abort("publication failed; original preserved at ", backup)
    m1d_abort("cannot publish dataset: ", target)
  }
  if (had_target) unlink(backup, recursive = TRUE)
  invisible(target)
}
