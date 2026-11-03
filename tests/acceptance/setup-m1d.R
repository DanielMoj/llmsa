# Helpers for the M1d acceptance tests (docs/02-statistikkern.md, K-M1d-1 to
# K-M1d-8); a setup file for the reason given in setup-acceptance.R.
#
# Reference values come from reference/anchors/ (ANK-06, ANK-34, ANK-40 to
# ANK-47, ANK-TOL) and from the raw data next to the repository root
# (../quellen/daten/llm-stability_2026-10-22/, ../quellen/daten/clinvar_2026-10-22/),
# whose SHA-256 the anchors fix. A missing or altered raw file fails the test,
# it never skips it (AGENTS.md). The mini-references below are written
# independently of the package code: the frozen subsets from the raw files
# (selection rules of K-M1d-1 and K-M1d-3, ANK-40, ANK-47), attribute
# repeatability and hit rate (K-M1d-2), Krippendorff's alpha after Krippendorff
# (2011) by enumeration of pairable values (K-M1d-4), the findings of the
# class-B studies (K-M1d-7) and the wording of the robustness result (K-M1d-8).
# Interpretations of points on which the spec is silent are listed in
# orchestrator/handoff/M1d/CRITERIA.json under "open" (ACC-n).

acc_m1d <- new.env(parent = emptyenv())   # cache for one test run

# General ----------------------------------------------------------------------------------

acc_m1d_require <- function(path, what) {
  if (!file.exists(path)) stop("acceptance: ", what, " missing: ", path, call. = FALSE)
  path
}

# Raw data folder next to the repository root (docs/01 §7: ../quellen/daten/<folder>/).
acc_m1d_quellen <- function(...) file.path(dirname(acc_repo_root()), "quellen", "daten", ...)

acc_m1d_is_gzip <- function(path) {
  file.exists(path) && identical(readBin(path, "raw", 2L), as.raw(c(0x1f, 0x8b)))
}

# First line of a (possibly gzip-compressed) text file.
acc_m1d_first_line <- function(path) {
  con <- if (grepl("\\.gz$", path)) gzfile(path, "rt") else file(path, "rt")
  on.exit(close(con), add = TRUE)
  readLines(con, n = 1L, warn = FALSE, encoding = "UTF-8")
}

# CSV (gzip) as character columns; "" and NA are missing.
acc_m1d_read_gz <- function(path) {
  acc_m1d_require(path, "file")
  con <- gzfile(path, "rt", encoding = "UTF-8")
  on.exit(close(con), add = TRUE)
  utils::read.csv(con, stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character",
                  na.strings = c("", "NA"), encoding = "UTF-8")
}

acc_m1d_text <- function(path) paste(readLines(acc_m1d_require(path, "file"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")

# SHA256SUMS of a frozen folder (docs/01 §7: one line per file, the stored
# file): every file of the folder except SHA256SUMS itself listed exactly once
# in sha256sum format with its SHA-256 (ACC-4).
acc_m1d_expect_sha256sums <- function(dir, label) {
  path <- file.path(dir, "SHA256SUMS")
  expect_true(file.exists(path), label = sprintf("%s: SHA256SUMS exists", label))
  if (!file.exists(path)) return(invisible())
  lines <- readLines(path, warn = FALSE)
  lines <- lines[nzchar(trimws(lines))]
  m <- regmatches(lines, regexec("^([0-9a-f]{64}) [ *]?(.+)$", lines))
  expect_true(length(lines) > 0L && all(lengths(m) == 3L),
              label = sprintf("%s: every line of SHA256SUMS reads '<sha256>  <file>' (lowercase hex)", label))
  listed <- vapply(m[lengths(m) == 3L], function(z) z[3], "")
  hashes <- vapply(m[lengths(m) == 3L], function(z) z[2], "")
  files <- setdiff(list.files(dir, all.files = TRUE, no.. = TRUE), "SHA256SUMS")
  expect_setequal(listed, files)
  expect_false(anyDuplicated(listed) > 0L, label = sprintf("%s: a file listed twice in SHA256SUMS", label))
  for (i in seq_along(listed)) {
    f <- file.path(dir, listed[i])
    if (file.exists(f)) expect_identical(acc_sha256(f), hashes[i], label = sprintf("%s: SHA-256 of %s", label, listed[i]))
  }
}

# Integer n written in a text, with or without thousands separators.
acc_m1d_mentions_count <- function(text, n) {
  d <- format(n, scientific = FALSE, trim = TRUE)
  groups <- rev(regmatches(d, gregexpr(".{1,3}(?=(.{3})*$)", d, perl = TRUE))[[1]])
  sep <- paste(rev(groups), collapse = "[,. '\u202f\u00a0]?")
  grepl(paste0("(?<![0-9.,])", sep, "(?![0-9])"), text, perl = TRUE)
}

# Number tokens of a text with thousands separators removed ("27,224" ->
# "27224"); decimals and scientific notation as in acc_m1a_numbers().
acc_m1d_numbers <- function(x) {
  x <- paste(x[!is.na(x)], collapse = " \n ")
  big <- gregexpr("(?<![0-9.])[0-9]{1,3}(?:[,\u202f\u00a0'][0-9]{3})+(?![0-9])", x, perl = TRUE)
  regmatches(x, big) <- lapply(regmatches(x, big), function(t) gsub("[,\u202f\u00a0']", "", t))
  acc_m1a_numbers(x)
}

# TRUE if a written number shows `value` (acc_m1b_shows(): equal, or at least
# two significant digits and within one unit of the last written digit), at
# one of the given scales (1 = as stored, 100 = percent, 0.01 = percent shown
# as a share).
acc_m1d_shown <- function(tokens, value, scales = 1) {
  if (!length(tokens) || !is.finite(value)) return(FALSE)
  any(vapply(value * scales, function(v) acc_m1b_shown(tokens, v), logical(1)))
}

# Plain text for comparisons: Markdown escapes, code and emphasis markers and
# quotes removed, whitespace collapsed (acc_m1c_norm_text()), HTML tags removed.
acc_m1d_norm <- function(x) acc_m1c_norm_text(gsub("<[^>]+>", " ", paste(x, collapse = " ")))

# Vignettes ---------------------------------------------------------------------------------

acc_m1d_vignette_path <- function(name) file.path(acc_repo_root(), "vignettes", paste0(name, ".Rmd"))

# Knits vignettes/<name>.Rmd once per test run like acc_m1a_knit_validation():
# R code runs in <repo>/vignettes with the package under test loaded,
# REPO_ROOT points to the repository, output goes to a temporary directory.
acc_m1d_knit <- function(name) {
  key <- paste0("knit_", name)
  if (!is.null(acc_m1d[[key]])) return(acc_m1d[[key]])
  rmd <- acc_m1d_vignette_path(name)
  if (!file.exists(rmd)) {
    k <- list(error = paste("vignette missing:", rmd), lines = character())
    acc_m1d[[key]] <- k
    return(k)
  }
  vig_dir <- dirname(rmd)
  work <- tempfile(paste0("acc-m1d-knit-", name, "-"))
  dir.create(work)
  out <- file.path(work, paste0(name, ".md"))
  old_wd <- setwd(work)
  on.exit(setwd(old_wd), add = TRUE)
  old_root <- Sys.getenv("REPO_ROOT", unset = NA)
  Sys.setenv(REPO_ROOT = acc_repo_root())
  on.exit(if (is.na(old_root)) Sys.unsetenv("REPO_ROOT") else Sys.setenv(REPO_ROOT = old_root), add = TRUE)
  old_root_dir <- knitr::opts_knit$get("root.dir")
  old_base_dir <- knitr::opts_knit$get("base.dir")
  knitr::opts_knit$set(root.dir = vig_dir, base.dir = work)
  on.exit(knitr::opts_knit$set(root.dir = old_root_dir, base.dir = old_base_dir), add = TRUE)
  old_error <- knitr::opts_chunk$get("error")
  old_fig_path <- knitr::opts_chunk$get("fig.path")
  knitr::opts_chunk$set(error = FALSE, fig.path = "figure/")
  on.exit(knitr::opts_chunk$set(error = old_error, fig.path = old_fig_path), add = TRUE)
  res <- tryCatch(
    suppressMessages(suppressWarnings(knitr::knit(rmd, output = out, quiet = TRUE, envir = new.env(parent = globalenv())))),
    error = function(e) e
  )
  k <- list(error = if (inherits(res, "error")) conditionMessage(res) else NULL,
            lines = if (file.exists(out)) readLines(out, warn = FALSE, encoding = "UTF-8") else character())
  acc_m1d[[key]] <- k
  k
}

# R code of an Rmd file: the lines of the R chunks and every inline `r ...`.
acc_m1d_rmd_code <- function(path) {
  lines <- readLines(acc_m1d_require(path, "vignette"), warn = FALSE, encoding = "UTF-8")
  open <- grepl("^[[:space:]]*```+[[:space:]]*\\{[[:space:]]*[rR]([[:space:],}].*)?$", lines)
  fence <- grepl("^[[:space:]]*```", lines)
  code <- character()
  inside <- FALSE
  for (i in seq_along(lines)) {
    if (!inside && open[i]) { inside <- TRUE; next }
    if (inside && fence[i]) { inside <- FALSE; next }
    if (inside) code <- c(code, lines[i])
  }
  inline <- unlist(regmatches(lines, gregexpr("`r [^`]+`", lines)))
  c(code, sub("`$", "", sub("^`r ", "", inline)))
}

# Text units of a knitted document: every table row (pipe or HTML) and every
# sentence of a paragraph or list item (split after "." or ";" followed by
# whitespace); fenced code blanked (ACC-10).
acc_m1d_units <- function(lines) {
  lines <- acc_m1a_unfence(lines)
  html <- paste(lines, collapse = "\n")
  units <- acc_m1a_strip_html(regmatches(html, gregexpr("(?s)<tr.*?</tr>", html, perl = TRUE))[[1]])
  lines <- gsub("(?s)<[^>]+>", " ", lines, perl = TRUE)
  blocks <- list()
  current <- character()
  item <- "^[[:space:]]*([-*+]|[0-9]+[.)])[[:space:]]"
  for (ln in lines) {
    if (grepl("^[[:space:]]*\\|", ln)) {
      if (length(current)) blocks[[length(blocks) + 1L]] <- current
      current <- character()
      units <- c(units, ln)
      next
    }
    if (!nzchar(trimws(ln)) || grepl("^#{1,6}[[:space:]]", ln) || grepl(item, ln)) {
      if (length(current)) blocks[[length(blocks) + 1L]] <- current
      current <- if (nzchar(trimws(ln)) && !grepl("^#{1,6}[[:space:]]", ln)) ln else character()
      next
    }
    current <- c(current, ln)
  }
  if (length(current)) blocks[[length(blocks) + 1L]] <- current
  for (b in blocks) units <- c(units, strsplit(paste(b, collapse = " "), "(?<=[.;])[[:space:]]+", perl = TRUE)[[1]])
  vapply(units, acc_m1d_norm, character(1), USE.NAMES = FALSE)
}

# Numeric literals of an Rmd file outside the YAML header (decimals with at
# least `min_sig` significant digits and integers of at least `min_int`)
# that equal one of `values` (also after rounding to the written digits).
acc_m1d_typed_literals <- function(path, values, min_sig = 2L, min_int = 100) {
  lines <- readLines(acc_m1d_require(path, "vignette"), warn = FALSE, encoding = "UTF-8")
  values <- unique(values[is.finite(values)])
  lit <- acc_m1a_rmd_literals(lines)
  typed <- character()
  dec <- values[values != round(values)]
  for (i in seq_len(nrow(lit))) {
    x <- lit$value[i]
    if (lit$significant[i] >= min_sig && any(x == dec | x == signif(dec, lit$significant[i]))) typed <- c(typed, lit$token[i])
  }
  if (length(lines) && trimws(lines[1]) == "---") {
    close <- which(trimws(lines) == "---")
    if (length(close) >= 2L) lines <- lines[-seq_len(close[2])]
  }
  text <- paste(lines, collapse = "\n")
  for (n in values[values == round(values) & abs(values) >= min_int]) {
    if (acc_m1d_mentions_count(text, n)) typed <- c(typed, format(n, scientific = FALSE))
  }
  unique(typed)
}

# Runs data-raw/<script> in a copy of the package (DESCRIPTION, NAMESPACE, R/,
# inst/, data/, data-raw/, reference/anchors/) whose sibling folder quellen/
# links to ../quellen/ (or is absent with quellen = FALSE), after removing
# `remove` (paths relative to the copy); working directory and REPO_ROOT are
# the copy (ACC-4); returns status, output and the copy.
acc_m1d_run_data_raw <- function(script, remove = character(), quellen = TRUE) {
  root <- acc_repo_root()
  acc_m1d_require(file.path(root, "data-raw", script), paste0("data-raw/", script))
  work <- tempfile("acc-m1d-dataraw-")
  copy <- file.path(work, "llmsa")
  dir.create(copy, recursive = TRUE)
  for (part in c("DESCRIPTION", "NAMESPACE", "R", "inst", "data", "data-raw")) {
    from <- if (part == "data-raw") file.path(root, part) else file.path(acc_pkg_root(), part)
    if (file.exists(from)) file.copy(from, copy, recursive = TRUE)
  }
  dir.create(file.path(copy, "reference"))
  file.copy(file.path(root, "reference", "anchors"), file.path(copy, "reference"), recursive = TRUE)
  if (quellen) file.symlink(file.path(dirname(root), "quellen"), file.path(work, "quellen"))
  unlink(file.path(copy, remove), recursive = TRUE)
  old <- setwd(copy)
  on.exit(setwd(old), add = TRUE)
  res <- acc_run(file.path(R.home("bin"), "Rscript"), shQuote(file.path("data-raw", script)),
                 env = paste0("REPO_ROOT=", shQuote(normalizePath(copy))))
  c(res, list(copy = copy, work = work))
}

# llm-stability (K-M1d-1, K-M1d-2) ------------------------------------------------------------

acc_m1d_llm_folder <- "llm-stability_2026-10-22"
acc_m1d_llm_columns <- c("task", "model", "run", "item_id", "answer", "correct")

acc_m1d_ank40 <- function() acc_anchor("ANK-40")$value
acc_m1d_llm_dir <- function() file.path(acc_pkg_root(), "inst", "extdata", acc_m1d_llm_folder)
acc_m1d_llm_file <- function() file.path(acc_m1d_llm_dir(), "items.csv.gz")

# The frozen subset with typed columns run, item_id (integer) and correct
# (logical; values other than TRUE, FALSE and missing stop the test).
acc_m1d_llm_items <- function() {
  if (!is.null(acc_m1d$llm_items)) return(acc_m1d$llm_items)
  d <- acc_m1d_read_gz(acc_m1d_require(acc_m1d_llm_file(), "items.csv.gz"))
  if (!identical(names(d), acc_m1d_llm_columns)) {
    stop("acceptance: items.csv.gz has the columns ", paste(names(d), collapse = ", "), call. = FALSE)
  }
  bad <- setdiff(unique(d$correct[!is.na(d$correct)]), c("TRUE", "FALSE"))
  if (length(bad)) stop("acceptance: column correct holds ", paste(head(bad, 5), collapse = ", "), call. = FALSE)
  d$run <- as.integer(d$run)
  d$item_id <- as.integer(d$item_id)
  d$correct <- as.logical(d$correct)
  acc_m1d$llm_items <- d
  d
}

# Mini-reference of the raw data (ACC-1, ACC-2): runs.tgz of ANK-40 (SHA-256
# checked) extracted once into a temporary directory; for every model and task
# the folder of ANK-40 selection.folders, all CSV files, columns task, model,
# run, item_id (= rubric_id), gt, question and response.
acc_m1d_llm_raw <- function() {
  if (!is.null(acc_m1d$llm_raw)) return(acc_m1d$llm_raw)
  a <- acc_m1d_ank40()
  tgz <- acc_m1d_require(acc_m1d_quellen(a$raw_folder, a$runs_archive$path), "llm-stability runs archive")
  if (!identical(acc_sha256(tgz), a$runs_archive$sha256)) stop("acceptance: ", tgz, " does not carry the SHA-256 of ANK-40", call. = FALSE)
  out <- tempfile("acc-m1d-llm-raw-")
  dir.create(out)
  res <- acc_run("tar", c("-xzf", shQuote(tgz), "-C", shQuote(out)))
  if (res$status != 0L) stop("acceptance: tar could not extract ", tgz, call. = FALSE)
  base <- file.path(out, a$runs_archive$top_directory)
  rows <- list()
  for (key in names(a$selection$folders)) {
    mt <- strsplit(key, "|", fixed = TRUE)[[1]]
    dir <- file.path(base, a$selection$folders[[key]])
    files <- list.files(dir, pattern = "\\.csv$", full.names = TRUE)
    if (length(files) != a$n_runs) stop("acceptance: ", dir, " holds ", length(files), " CSV files", call. = FALSE)
    for (f in files) {
      x <- utils::read.csv(f, stringsAsFactors = FALSE, encoding = "UTF-8")
      if (!all(x$model == mt[1]) || !all(x$task == mt[2])) stop("acceptance: model or task differs from the folder in ", f, call. = FALSE)
      rows[[length(rows) + 1L]] <- data.frame(task = x$task, model = x$model, run = as.integer(x$run),
                                              item_id = as.integer(x$rubric_id), gt = x$gt, question = x$question,
                                              response = x$response, stringsAsFactors = FALSE)
    }
  }
  unlink(out, recursive = TRUE)
  raw <- do.call(rbind, rows)
  raw$key <- paste(raw$task, raw$model, raw$run, raw$item_id, sep = "|")
  if (anyDuplicated(raw$key)) stop("acceptance: duplicate task, model, run and item in the raw data", call. = FALSE)
  acc_m1d$llm_raw <- raw
  raw
}

# Answer key and options of every task and item from the raw data: gt is the
# key (unique per task and item across models), the options are the labels
# "(X)" in the question; navigate has the options Yes and No (tasks/navigate.py).
acc_m1d_llm_keys <- function() {
  if (!is.null(acc_m1d$llm_keys)) return(acc_m1d$llm_keys)
  raw <- acc_m1d_llm_raw()
  k <- unique(raw[c("task", "item_id", "gt", "question")])
  if (anyDuplicated(k[c("task", "item_id")])) stop("acceptance: answer key or question not unique per task and item", call. = FALSE)
  k$options <- lapply(seq_len(nrow(k)), function(i) {
    if (k$task[i] == "navigate") return(c("Yes", "No"))
    unique(regmatches(k$question[i], gregexpr("\\([A-Z]\\)", k$question[i]))[[1]])
  })
  k$key <- paste(k$task, k$item_id, sep = "|")
  acc_m1d$llm_keys <- k
  k
}

# TRUE if the bare label of `answer` occurs in `response` as a word,
# ignoring case: "(B)" -> B, "Yes" -> Yes; a key that is a text (two
# ruin_names items) as a substring.
acc_m1d_answer_in_response <- function(answer, response) {
  out <- logical(length(answer))
  for (i in seq_along(answer)) {
    a <- answer[i]
    r <- if (is.na(response[i])) "" else response[i]
    label <- sub("^\\(([A-Z])\\)$", "\\1", a)
    out[i] <- if (grepl("^[A-Za-z]+$", label)) {
      grepl(paste0("(?i)(?<![A-Za-z0-9])", label, "(?![A-Za-z0-9])"), r, perl = TRUE)
    } else grepl(tolower(a), tolower(r), fixed = TRUE)
  }
  out
}

# Mini-reference of K-M1d-2 (ACC-5) per task and model:
# repeatability = share of the items of the task whose runs all carry a
# non-missing and the same answer (a missing answer breaks agreement, like
# TARa of the source); hit rate = share of all calls with correct == TRUE
# (a missing answer is no hit, like the accuracy of the source).
acc_m1d_llm_reference <- function(d) {
  cells <- split(d, list(d$task, d$model), drop = TRUE)
  do.call(rbind, lapply(cells, function(x) {
    by_item <- split(x$answer, x$item_id)
    same <- vapply(by_item, function(v) !anyNA(v) && length(unique(v)) == 1L, logical(1))
    data.frame(task = x$task[1], model = x$model[1], items = length(by_item),
               repeatability = mean(same), hit_rate = mean(x$correct %in% TRUE), stringsAsFactors = FALSE)
  }))
}

# msa_runs of one task (Item = item_id, Prompt = one fixed level, Model =
# model, Replicate = run; K-M1d-1 and the mapping of docs/02 M1d).
acc_m1d_llm_runs <- function(d, value = c("correct", "answer")) {
  value <- match.arg(value)
  x <- data.frame(item_id = as.character(d$item_id), prompt_id = "task", model_id = d$model, rep = d$run,
                  value = if (value == "correct") as.integer(d$correct) else d$answer, stringsAsFactors = FALSE)
  as_msa_runs(x)
}

# ClinVar (K-M1d-3, K-M1d-4) ------------------------------------------------------------------

acc_m1d_clinvar_folder <- "clinvar_2026-10-19"
acc_m1d_clinvar_raw_folder <- "clinvar_2026-10-22"
acc_m1d_clinvar_columns <- c("variation_id", "gene", "submitter_id", "classification", "date_last_evaluated", "review_status")
acc_m1d_hrf_genes <- c("MEFV", "MVK", "NLRP3", "TNFRSF1A")   # docs/02 K-M1d-3 (a)
acc_m1d_hrf_min_submitters <- 2L                              # docs/02 K-M1d-3 (a)
acc_m1d_clinvar_files <- c(hrf = "hrf_submissions.csv.gz", sample = "sample_submissions.csv.gz")

acc_m1d_clinvar_dir <- function() file.path(acc_pkg_root(), "inst", "extdata", acc_m1d_clinvar_folder)

# The five classes in scale order from the mapping of docs/02 M1d
# („Benign < Likely benign < … < Pathogenic“); ANK-47 lists the same set.
acc_m1d_classes <- function() {
  if (!is.null(acc_m1d$classes)) return(acc_m1d$classes)
  lines <- readLines(file.path(acc_repo_root(), "docs", "02-statistikkern.md"), warn = FALSE, encoding = "UTF-8")
  line <- lines[startsWith(lines, "- ClinVar: Item = Variante")]
  m <- regmatches(line, regexec("`(Benign < [^`]+)`", line))[[1]]
  if (length(line) != 1L || length(m) != 2L) stop("acceptance: class order of the ClinVar mapping not found in docs/02", call. = FALSE)
  cl <- trimws(strsplit(m[2], "<", fixed = TRUE)[[1]])
  if (!setequal(cl, unlist(acc_anchor("ANK-47")$value$classes))) stop("acceptance: classes of docs/02 and ANK-47 differ", call. = FALSE)
  acc_m1d$classes <- cl
  cl
}

# Frozen subset with integer variation_id.
acc_m1d_clinvar_subset <- function(which) {
  key <- paste0("clinvar_", which)
  if (!is.null(acc_m1d[[key]])) return(acc_m1d[[key]])
  d <- acc_m1d_read_gz(acc_m1d_require(file.path(acc_m1d_clinvar_dir(), acc_m1d_clinvar_files[[which]]), acc_m1d_clinvar_files[[which]]))
  if (!identical(names(d), acc_m1d_clinvar_columns)) {
    stop("acceptance: ", acc_m1d_clinvar_files[[which]], " has the columns ", paste(names(d), collapse = ", "), call. = FALSE)
  }
  d$variation_id <- as.integer(d$variation_id)
  acc_m1d[[key]] <- d
  d
}

# Raw files of ANK-41 with their SHA-256 checked once per test run.
acc_m1d_clinvar_raw <- function(name) {
  path <- acc_m1d_require(acc_m1d_quellen(acc_m1d_clinvar_raw_folder, name), paste("ClinVar raw file", name))
  key <- paste0("sha_", name)
  if (is.null(acc_m1d[[key]])) {
    want <- acc_anchor("ANK-41")$value$files[[name]]$sha256
    if (!identical(acc_sha256(path), want)) stop("acceptance: ", path, " does not carry the SHA-256 of ANK-41", call. = FALSE)
    acc_m1d[[key]] <- TRUE
  }
  normalizePath(path)
}

acc_m1d_pipe_table <- function(cmd, col_names, col_classes) {
  utils::read.delim(pipe(cmd), header = FALSE, quote = "", comment.char = "", na.strings = character(),
                    stringsAsFactors = FALSE, col.names = col_names, colClasses = col_classes, encoding = "UTF-8")
}

# Mini-reference of both subsets (ACC-6), computed once per test run from the
# raw files with awk (column positions of ANK-63; VariationID and GeneSymbol of
# variant_summary.txt.gz, columns 31 and 5 of its header):
# 1. submissions whose ClinicalSignificance is one of the five classes;
# 2. distinct submitters per variant among them;
# 3. HRF: variants whose GeneSymbol list (";") holds one of the four genes and
#    that have at least two distinct submitters;
# 4. sample: variants with at least ANK-47 min_distinct_submitters, sorted by
#    variation_id, set.seed(seed) and sample(…, n_variants) with the default RNG;
# 5. all five-class submissions of the selected variants; gene from
#    variant_summary, NA if the variant is missing there.
acc_m1d_clinvar_reference <- function() {
  if (!is.null(acc_m1d$clinvar_ref)) return(acc_m1d$clinvar_ref)
  sub <- acc_m1d_clinvar_raw("submission_summary.txt.gz")
  var <- acc_m1d_clinvar_raw("variant_summary.txt.gz")
  cols <- acc_anchor("ANK-63")$value$columns
  five <- acc_m1d_classes()
  s47 <- acc_anchor("ANK-47")$value
  head <- strsplit(acc_m1d_first_line(var), "\t", fixed = TRUE)[[1]]
  vcol <- match(c("VariationID", "GeneSymbol"), sub("^#", "", head))
  if (anyNA(vcol)) stop("acceptance: VariationID or GeneSymbol missing in the header of ", var, call. = FALSE)
  classes_awk <- paste0("c[\"", five, "\"]=1", collapse = "; ")
  # 1, 2: variant, submitter and class of every submission (classes counted in awk)
  tmp <- tempfile("acc-m1d-clinvar-")
  dir.create(tmp)
  pairs <- file.path(tmp, "pairs.tsv")
  counts <- file.path(tmp, "terms.tsv")
  awk1 <- sprintf("BEGIN {FS=\"\\t\"; OFS=\"\\t\"; %s} /^#/ {next} {t[$%d]++} ($%d in c) {print $%d, $%d} END {for (k in t) print k, t[k] > \"%s\"}",
                  classes_awk, cols$ClinicalSignificance, cols$ClinicalSignificance, cols$VariationID, cols$Submitter, counts)
  status <- system2("sh", c("-c", shQuote(sprintf("gzip -dc %s | awk %s > %s", shQuote(sub), shQuote(awk1), shQuote(pairs)))))
  if (status != 0L) stop("acceptance: reading ", sub, " failed", call. = FALSE)
  p <- utils::read.delim(pairs, header = FALSE, quote = "", comment.char = "", na.strings = character(),
                         col.names = c("vid", "submitter"), colClasses = c("integer", "character"), encoding = "UTF-8")
  terms <- utils::read.delim(counts, header = FALSE, quote = "", comment.char = "", na.strings = character(),
                             col.names = c("term", "n"), colClasses = c("character", "integer"), encoding = "UTF-8")
  code <- match(p$submitter, unique(p$submitter))
  if (max(code) >= 1e7) stop("acceptance: too many submitters for the pair key", call. = FALSE)
  first <- !duplicated(as.numeric(p$vid) * 1e7 + code)
  nsub <- table(p$vid[first])
  rm(p, code, first)
  eligible <- sort(as.integer(names(nsub)[nsub >= s47$min_distinct_submitters]))
  # ANK-47: set.seed(seed) and sample() over the sorted list, default RNG of R
  # (Mersenne-Twister, Inversion, Rejection; docs/01 §5)
  drawn <- acc_m1a_with_seed(s47$seed, sample(eligible, s47$n_variants))
  # 3: genes of the HRF genes and of the drawn variants from variant_summary
  keep <- file.path(tmp, "drawn.txt")
  writeLines(as.character(drawn), keep)
  genes_re <- paste0("(^|;)(", paste(acc_m1d_hrf_genes, collapse = "|"), ")(;|$)")
  awk2 <- sprintf("BEGIN {FS=\"\\t\"; OFS=\"\\t\"} NR==FNR {d[$1]=1; next} FNR==1 {next} (($%d in d) || $%d ~ /%s/) && !(($%d) in seen) {seen[$%d]=1; print $%d, $%d}",
                  vcol[1], vcol[2], genes_re, vcol[1], vcol[1], vcol[1], vcol[2])
  g <- acc_m1d_pipe_table(sprintf("gzip -dc %s | awk %s %s -", shQuote(var), shQuote(awk2), shQuote(keep)),
                          c("vid", "gene"), c("integer", "character"))
  in_hrf <- vapply(strsplit(g$gene, ";", fixed = TRUE), function(z) any(z %in% acc_m1d_hrf_genes), logical(1))
  hrf_vid <- g$vid[in_hrf]
  hrf_vid <- hrf_vid[as.integer(nsub[as.character(hrf_vid)]) >= acc_m1d_hrf_min_submitters & !is.na(nsub[as.character(hrf_vid)])]
  # 5: all five-class submissions of the selected variants
  sel <- file.path(tmp, "selected.txt")
  writeLines(as.character(unique(c(hrf_vid, drawn))), sel)
  awk3 <- sprintf("BEGIN {FS=\"\\t\"; OFS=\"\\t\"; %s} NR==FNR {d[$1]=1; next} /^#/ {next} ($%d in d) && ($%d in c) {print $%d, $%d, $%d, $%d, $%d}",
                  classes_awk, cols$VariationID, cols$ClinicalSignificance, cols$VariationID, cols$Submitter,
                  cols$ClinicalSignificance, cols$DateLastEvaluated, cols$ReviewStatus)
  rows <- acc_m1d_pipe_table(sprintf("gzip -dc %s | awk %s %s -", shQuote(sub), shQuote(awk3), shQuote(sel)),
                             c("variation_id", "submitter_id", "classification", "date_last_evaluated", "review_status"),
                             rep("character", 5))
  rows$variation_id <- as.integer(rows$variation_id)
  rows$gene <- g$gene[match(rows$variation_id, g$vid)]
  rows <- rows[acc_m1d_clinvar_columns]
  # submissions with a term outside the five classes (ACC-6): on variants of the
  # four genes (all their submissions) and in the whole file
  awk4 <- sprintf("BEGIN {FS=\"\\t\"; %s} NR==FNR {h[$1]=1; next} /^#/ {next} ($%d in h) && !($%d in c) {n++} END {print n+0}",
                  classes_awk, cols$VariationID, cols$ClinicalSignificance)
  hrf_all <- file.path(tmp, "hrf_all.txt")
  writeLines(as.character(g$vid[in_hrf]), hrf_all)
  excluded_hrf <- as.integer(system2("sh", c("-c", shQuote(sprintf("gzip -dc %s | awk %s %s -", shQuote(sub), shQuote(awk4), shQuote(hrf_all)))),
                                     stdout = TRUE))
  ref <- list(hrf = rows[rows$variation_id %in% hrf_vid, , drop = FALSE],
              sample = rows[rows$variation_id %in% drawn, , drop = FALSE],
              drawn = drawn, eligible = length(eligible),
              excluded_hrf = excluded_hrf,
              excluded_all = sum(terms$n[!terms$term %in% five]))
  unlink(tmp, recursive = TRUE)
  acc_m1d$clinvar_ref <- ref
  ref
}

# Date of a cell: ISO (YYYY-MM-DD) or the raw form "%b %d, %Y" (ANK-63, read
# in the C locale); "-", "" and NA are missing.
acc_m1d_as_date <- function(x) {
  old <- Sys.getlocale("LC_TIME")
  on.exit(Sys.setlocale("LC_TIME", old), add = TRUE)
  Sys.setlocale("LC_TIME", "C")
  x[x %in% c("-", "")] <- NA
  out <- as.Date(x, format = "%Y-%m-%d", optional = TRUE)
  raw <- is.na(out) & !is.na(x)
  out[raw] <- as.Date(x[raw], format = "%b %d, %Y", optional = TRUE)
  out
}

# Rows of a subset as sorted keys for a multiset comparison; dates as ISO.
acc_m1d_clinvar_keys <- function(d) {
  dt <- acc_m1d_as_date(d$date_last_evaluated)
  bad <- !is.na(d$date_last_evaluated) & !d$date_last_evaluated %in% c("-", "") & is.na(dt)
  if (any(bad)) stop("acceptance: unreadable date ", d$date_last_evaluated[which(bad)[1]], call. = FALSE)
  sort(paste(d$variation_id, ifelse(is.na(d$gene), "<NA>", d$gene), d$submitter_id, d$classification,
             ifelse(is.na(dt), "<NA>", format(dt)), d$review_status, sep = "\t"))
}

# msa_runs of a subset (mapping of docs/02 M1d: Item = variant, Prompt =
# submitter, Model and Block one level, Replicate 1).
acc_m1d_clinvar_runs <- function(d) {
  as_msa_runs(data.frame(item_id = as.character(d$variation_id), prompt_id = d$submitter_id, model_id = "clinvar",
                         rep = 1L, value = d$classification, stringsAsFactors = FALSE))
}

# Krippendorff's alpha after Krippendorff (2011, "Computing Krippendorff's
# Alpha-Reliability"), written independently of R/agreement.R: units with at
# least two pairable values; observed disagreement from every ordered pair of
# values within a unit, weighted 1/(m_u - 1); expected disagreement from the
# frequencies n_c of the pairable values; alpha = 1 - (n - 1) D_o / D_e.
# Nominal: delta = 1 for different values. Ordinal (values in scale order):
# delta_ck = (sum_{g=c..k} n_g - (n_c + n_k)/2)^2.
acc_m1d_kripp <- function(unit, value, levels, metric = c("nominal", "ordinal")) {
  metric <- match.arg(metric)
  ok <- !is.na(value)
  unit <- unit[ok]
  value <- match(value[ok], levels)
  if (anyNA(value)) stop("acceptance: value outside the levels", call. = FALSE)
  m <- table(unit)
  pairable <- unit %in% names(m)[m >= 2L]
  unit <- unit[pairable]
  value <- value[pairable]
  n_c <- tabulate(value, length(levels))
  n <- sum(n_c)
  cum <- cumsum(n_c)
  delta <- function(a, b) {
    if (metric == "nominal") return(as.numeric(a != b))
    lo <- pmin(a, b)
    hi <- pmax(a, b)
    (cum[hi] - c(0, cum)[lo] - (n_c[a] + n_c[b]) / 2)^2
  }
  d_obs <- 0
  for (u in split(value, unit)) {
    ij <- which(outer(seq_along(u), seq_along(u), "!="), arr.ind = TRUE)
    d_obs <- d_obs + sum(delta(u[ij[, 1]], u[ij[, 2]])) / (length(u) - 1)
  }
  ab <- expand.grid(a = seq_along(n_c), b = seq_along(n_c))
  d_exp <- sum(n_c[ab$a] * n_c[ab$b] * delta(ab$a, ab$b))
  1 - (n - 1) * d_obs / d_exp
}

# Shares over the variants with at least two submissions (ACC-7): all
# submissions in one class; submissions in at least two of the groups P/LP,
# VUS, LB/B (ClinVar conflict, ANK-46).
acc_m1d_full_agreement <- function(d) {
  v <- split(d$classification, d$variation_id)
  v <- v[lengths(v) >= 2L]
  mean(vapply(v, function(x) length(unique(x)) == 1L, logical(1)))
}

acc_m1d_conflict <- function(d) {
  cl <- acc_m1d_classes()
  group <- stats::setNames(c("B", "B", "V", "P", "P"), cl)
  v <- split(d$classification, d$variation_id)
  v <- v[lengths(v) >= 2L]
  mean(vapply(v, function(x) length(unique(group[x])) >= 2L, logical(1)))
}

# Rows with a review status that begins with "criteria provided" (ACC-7).
acc_m1d_criteria_provided <- function(d) d[startsWith(d$review_status, "criteria provided"), , drop = FALSE]

acc_m1d_literature <- c("ANK-42", "ANK-43", "ANK-44", "ANK-45", "ANK-46")

# Class-B full runs (K-M1d-6, K-M1d-7) --------------------------------------------------------

acc_m1d_studies <- c("ordinal_recovery", "binary_recovery", "two_level", "boot_coverage")

acc_m1d_full_path <- function(study, kind) acc_m1b_out_file(acc_m1b_sim_dir(), study, kind)

acc_m1d_study_ids <- function(study) {
  if (study == "boot_coverage") names(acc_m1c_scenarios()) else names(acc_m1b_study_scenarios(study))
}

acc_m1d_n_min <- function() as.numeric(acc_anchor("ANK-06")$value$n_sim_min)

# Findings of K-M1d-7 from the full results files (ACC-10):
# ordinal_recovery, binary_recovery: every true component (estimands of the
#   scenario except Residual, %GRR and ICC_items) with |rel_bias| greater than
#   max(ANK-TOL.bias_report.rel_bias, bias_report.mcse_multiple * MCSE);
# two_level: the bias of the two-level component (beta-hat^2/2) in every
#   scenario; its direction is named once |bias| > mc_factor.report * MCSE;
# boot_coverage: every coverage of an interval estimand that deviates from the
#   nominal level by more than mc_factor.report * MCSE.
# Directions: over/under (bias), under/over (coverage below/above nominal).
acc_m1d_findings <- function() {
  if (!is.null(acc_m1d$findings)) return(acc_m1d$findings)
  br <- acc_m1a_tol("bias_report", "rel_bias")
  bm <- acc_m1a_tol("bias_report", "mcse_multiple")
  report <- acc_m1a_tol("mc_factor", "report")
  rows <- list()
  add <- function(study, id, e, kind, dir, value, mcse) {
    rows[[length(rows) + 1L]] <<- data.frame(study = study, scenario = id, estimand = e, kind = kind, direction = dir,
                                             value = value, mcse = mcse, stringsAsFactors = FALSE)
  }
  pick <- function(res, id, e, m) {
    r <- res[res$scenario == id & res$estimand == e & res$measure == m, , drop = FALSE]
    if (nrow(r) != 1L) stop("acceptance: no unique row ", id, " ", e, " ", m, call. = FALSE)
    c(value = as.numeric(r$value), mcse = as.numeric(r$mcse))
  }
  for (study in c("ordinal_recovery", "binary_recovery")) {
    res <- acc_m1b_read_csv(acc_m1d_full_path(study, "results"))
    for (id in acc_m1d_study_ids(study)) {
      comps <- setdiff(names(acc_m1b_truth(acc_m1b_scenarios()[[id]])), c("grr_pct_study_var", "icc_items"))
      for (e in comps) {
        v <- pick(res, id, e, "rel_bias")
        if (abs(v[["value"]]) > max(br, bm * v[["mcse"]])) {
          add(study, id, e, "bias", if (v[["value"]] > 0) "over" else "under", v[["value"]], v[["mcse"]])
        }
      }
    }
  }
  res <- acc_m1b_read_csv(acc_m1d_full_path("two_level", "results"))
  for (id in acc_m1d_study_ids("two_level")) {
    v <- pick(res, id, acc_m1b_two_level_factor, "bias")
    dir <- if (abs(v[["value"]]) > report * v[["mcse"]]) (if (v[["value"]] > 0) "over" else "under") else "none"
    add("two_level", id, acc_m1b_two_level_factor, "bias", dir, v[["value"]], v[["mcse"]])
  }
  res <- acc_m1b_read_csv(acc_m1d_full_path("boot_coverage", "results"))
  for (id in acc_m1d_study_ids("boot_coverage")) {
    for (e in acc_m1c_interval_estimands) {
      v <- pick(res, id, e, "coverage")
      if (abs(v[["value"]] - acc_m1c_nominal_level) > report * v[["mcse"]]) {
        add("boot_coverage", id, e, "coverage", if (v[["value"]] < acc_m1c_nominal_level) "under" else "over", v[["value"]], v[["mcse"]])
      }
    }
  }
  out <- if (length(rows)) do.call(rbind, rows) else
    data.frame(study = character(), scenario = character(), estimand = character(), kind = character(),
               direction = character(), value = numeric(), mcse = numeric(), stringsAsFactors = FALSE)
  acc_m1d$findings <- out
  out
}

# Words that name a direction (ACC-10), as Perl regular expressions.
acc_m1d_direction_re <- function(kind, direction) {
  if (direction == "none") return(NULL)
  if (kind == "bias") {
    if (direction == "over") "(?i)over-?estimat" else "(?i)under-?estimat"
  } else {
    if (direction == "under") "(?i)under-?cover|below (the )?nominal" else "(?i)over-?cover|above (the )?nominal"
  }
}

acc_m1d_has_id <- function(text, id) grepl(paste0("(?<![A-Za-z0-9-])", id, "(?![0-9])"), text, perl = TRUE)
acc_m1d_has_estimand <- function(text, e) {
  if (!grepl("^[A-Za-z0-9_:]+$", e)) stop("acceptance: unexpected estimand name ", e, call. = FALSE)
  grepl(paste0("(?i)(?<![A-Za-z0-9_:])", e, "(?![A-Za-z0-9_:])"), text, perl = TRUE)
}

# Helper page of the documentation that must name the findings of a study.
acc_m1d_rd_of <- function(study) if (study == "boot_coverage") "msa_boot" else "msa_fit"

# Baseline done/M1c (ANK-34; K-M1d-8, docs/02 M1d) --------------------------------------------

acc_m1d_baseline_file <- function(path) {
  v <- acc_anchor("ANK-34")$value
  if (is.null(v$files[[path]])) stop("acceptance: ANK-34 lists no ", path, call. = FALSE)
  file <- acc_m1c_baseline_text(v$ref, path)
  if (!identical(acc_sha256(file), v$files[[path]]$sha256)) {
    stop("acceptance: ", v$ref, ":", path, " does not carry the SHA-256 of ANK-34", call. = FALSE)
  }
  file
}

# R/robustness.R and R/acmg.R of done/M1c sourced into one environment whose
# parent is the namespace under test (helpers outside the two files).
acc_m1d_baseline <- function() {
  if (!is.null(acc_m1d$baseline)) return(acc_m1d$baseline)
  env <- new.env(parent = asNamespace(acc_pkg))
  for (path in c("R/robustness.R", "R/acmg.R")) {
    file <- acc_m1d_baseline_file(path)
    sys.source(file, envir = env, keep.source = FALSE)
    unlink(file)
  }
  acc_m1d$baseline <- env
  env
}

# Lines of an R file without roxygen lines (#') (docs/02 M1d: R/fit.R and
# R/grr.R change only in the roxygen documentation).
acc_m1d_code_lines <- function(path) {
  x <- readLines(path, warn = FALSE, encoding = "UTF-8")
  x[!grepl("^[[:space:]]*#'", x)]
}

# Robustness wording (K-M1d-8; ACC-11) ---------------------------------------------------------

# The sentence quoted in docs/02 K-M1d-8 between „ and “ (the first quote).
acc_m1d_robust_sentence <- function() {
  lines <- readLines(file.path(acc_repo_root(), "docs", "02-statistikkern.md"), warn = FALSE, encoding = "UTF-8")
  line <- lines[startsWith(lines, "- **K-M1d-8:**")]
  m <- regmatches(line, regexec("„([^“]+)“", line))[[1]]
  if (length(line) != 1L || length(m) != 2L) stop("acceptance: the sentence of K-M1d-8 is not quoted in docs/02", call. = FALSE)
  if (!grepl("(ME = x)", m[2], fixed = TRUE)) stop("acceptance: the sentence of K-M1d-8 lacks „(ME = x)“", call. = FALSE)
  m[2]
}

acc_m1d_suffix_only <- "above ME only"
acc_m1d_suffix_sme <- "also above SME"
acc_m1d_old_phrase <- "robust to all screened perturbations"

# Designs and responses, searched once per test run with fixed seeds: a case
# without active factor, and a case with factors above ME only and above SME.
acc_m1d_robustness_cases <- function() {
  if (!is.null(acc_m1d$rob_cases)) return(acc_m1d$rob_cases)
  design <- pb_design(11, n_runs = 12, seed = 20261103L)
  X <- attr(design, "coded")
  draw <- function(seed, effects) acc_m1a_with_seed(seed, as.numeric(0.6 + X %*% effects + stats::rnorm(nrow(X), 0, 0.02)))
  none <- NULL
  for (s in 1:200) {
    y <- draw(s, rep(0, ncol(X)))
    r <- msa_robustness(design, y)
    if (!any(r$active)) { none <- list(design = design, response = y, seed = s); break }
  }
  mixed <- NULL
  for (s in 1:500) {
    y <- draw(s, c(0.30, 0.06, rep(0, ncol(X) - 2L)))
    r <- msa_robustness(design, y)
    if (any(r$active & !r$active_simultaneous) && any(r$active_simultaneous)) { mixed <- list(design = design, response = y, seed = s); break }
  }
  if (is.null(none) || is.null(mixed)) stop("acceptance: no robustness test case found in the seed range", call. = FALSE)
  acc_m1d$rob_cases <- list(none = none, mixed = mixed)
  acc_m1d$rob_cases
}

# ME as written in the line with PSE, ME and SME of a text ("ME 0.1234").
acc_m1d_me_in_pse_line <- function(text) {
  line <- text[grepl("PSE", text, fixed = TRUE) & grepl("SME", text, fixed = TRUE)]
  m <- regmatches(line, regexec("[^S]ME[[:space:]=:]*(-?[0-9]+\\.[0-9]+)", line))
  m <- m[lengths(m) == 2L]
  if (length(m) != 1L) return(NA_character_)
  m[[1]][2]
}

# TRUE if every active factor is followed by its suffix before the next factor
# name or the other suffix, and no inactive factor is followed by a suffix.
acc_m1d_suffixes_ok <- function(text, x) {
  text <- acc_m1d_norm(text)
  names_re <- function(f) paste0("(?<![A-Za-z0-9_])", f, "(?![A-Za-z0-9_])")
  all_pos <- sort(unlist(lapply(x$factor, function(f) {
    p <- gregexpr(names_re(f), text, perl = TRUE)[[1]]
    if (p[1] < 0) integer() else as.integer(p)
  })))
  after <- function(start, len) {
    nxt <- all_pos[all_pos > start]
    stop_at <- if (length(nxt)) nxt[1] - 1L else nchar(text)
    substr(text, start + len, stop_at)
  }
  ok <- TRUE
  for (i in seq_len(nrow(x))) {
    f <- x$factor[i]
    p <- gregexpr(names_re(f), text, perl = TRUE)[[1]]
    tails <- if (p[1] < 0) character() else vapply(seq_along(p), function(j) after(p[j], attr(p, "match.length")[j]), "")
    if (isTRUE(x$active[i])) {
      want <- if (isTRUE(x$active_simultaneous[i])) acc_m1d_suffix_sme else acc_m1d_suffix_only
      other <- setdiff(c(acc_m1d_suffix_only, acc_m1d_suffix_sme), want)
      hit <- vapply(tails, function(t) {
        a <- regexpr(want, t, fixed = TRUE)
        b <- regexpr(other, t, fixed = TRUE)
        a > 0 && (b < 0 || a < b)
      }, logical(1))
      ok <- ok && any(hit)
    } else {
      ok <- ok && !any(grepl(acc_m1d_suffix_only, tails, fixed = TRUE) | grepl(acc_m1d_suffix_sme, tails, fixed = TRUE))
    }
  }
  ok
}

# Section "6. Robustness" of the report rendered by msa_report() (GitHub
# Markdown without wrapping), once per case.
acc_m1d_report_robustness <- function(key, ro) {
  cache <- paste0("report_", key)
  if (!is.null(acc_m1d[[cache]])) return(acc_m1d[[cache]])
  if (is.null(acc_m1d$report_grr)) {
    acc_m1d$report_grr <- msa_grr(acc_m1a_quiet(msa_fit(acc_m1a_dataset("ic50_demo"), type = "numeric")))
  }
  out <- tempfile("acc-m1d-report-", fileext = ".md")
  res <- acc_m1b_catch(msa_report(acc_m1d$report_grr, robustness = ro, output_file = out, quiet = TRUE,
                                  output_format = rmarkdown::md_document(variant = "gfm", pandoc_args = "--wrap=none")))
  value <- if (inherits(res$value, "error")) res$value else {
    lines <- readLines(out, warn = FALSE, encoding = "UTF-8")
    header <- grepl("^#{1,6}[[:space:]]", lines)
    start <- which(header & grepl("^#{1,6}[[:space:]]+6\\.[[:space:]]*Robustness", lines))
    if (length(start) != 1L) character() else {
      stop_at <- which(header & seq_along(lines) > start)
      lines[seq(start, if (length(stop_at)) stop_at[1] - 1L else length(lines))]
    }
  }
  acc_m1d[[cache]] <- value
  value
}

# Synthetic robustness runs of the AP1 plan for acmg_robustness(): every item
# once per PB prompt; in PB run j, round(n * plogis(a + X_j b)) items agree
# with their modal answer and the others give the next class.
acc_m1d_pb_runs <- function(plan, b, a = 1, n = 40L) {
  classes <- llmsa:::acmg_classes(plan)
  ids <- unlist(plan$robustness$pb_design$prompt_ids, use.names = FALSE)
  X <- attr(llmsa:::acmg_pb(plan), "coded")
  items <- sprintf("acc%02d", seq_len(n))
  modal_class <- classes[(seq_len(n) %% length(classes)) + 1L]
  wrong_class <- classes[((seq_len(n) + 1L) %% length(classes)) + 1L]
  runs <- do.call(rbind, lapply(seq_along(ids), function(j) {
    agree <- round(n * stats::plogis(a + sum(X[j, ] * b)))
    data.frame(block = 1L, item_id = items, prompt_id = ids[j], model_id = "m", rep = 1L,
               value = ifelse(seq_len(n) <= agree, modal_class, wrong_class), error = NA_character_,
               stringsAsFactors = FALSE)
  }))
  modal <- data.frame(item_id = items, has_modal = TRUE, modal = modal_class, reference = modal_class,
                      stringsAsFactors = FALSE)
  list(runs = runs, modal = modal, item_ids = items)
}
