#!/usr/bin/env Rscript
# Freeze the anchored v3 zero-shot runs without storing response texts.
# Usage from the package root: Rscript data-raw/make_llm_stability.R

make_llm_stability <- function(root) {
  for (p in c("jsonlite", "digest")) {
    if (!requireNamespace(p, quietly = TRUE)) stop("Required package is missing: ", p, call. = FALSE)
  }
  root <- normalizePath(root, mustWork = TRUE)
  sys.source(file.path(root, "inst", "validation", "m1d", "prepare.R"), envir = environment())
  a <- m1d_anchor(root, "ANK-40")$value
  limits <- m1d_anchor(root, "ANK-TOL")$value$data_size
  archive <- m1d_input(root, a$raw_folder, a$runs_archive$path, a$runs_archive$sha256)
  evaluation <- m1d_input(root, a$raw_folder, a$evaluation_file$path, a$evaluation_file$sha256)
  ev <- utils::read.csv(evaluation, colClasses = "character", stringsAsFactors = FALSE,
                        check.names = FALSE, encoding = "UTF-8")
  configs <- lapply(ev$model_config, m1d_config)
  tasks <- lapply(ev$task_config, m1d_config)
  selected <- vapply(seq_len(nrow(ev)), function(i) {
    m1d_same_config(configs[[i]], a$model_config) && m1d_same_config(tasks[[i]], a$selection$task_config)
  }, logical(1))
  ev <- ev[selected, , drop = FALSE]
  ev_key <- paste(ev$model, ev$task, sep = "|")
  if (anyDuplicated(ev_key) || !setequal(ev_key, names(a$selection$folders))) {
    m1d_abort("evaluation selection differs from ANK-40")
  }
  for (i in seq_len(nrow(ev))) {
    if (!endsWith(a$selection$folders[[ev_key[i]]], ev$date[i]) ||
        as.integer(ev$N[i]) != a$n_runs || as.integer(ev$num_questions[i]) != a$items_per_task[[ev$task[i]]]) {
      m1d_abort("evaluation folder or dimensions differ from ANK-40: ", ev_key[i])
    }
  }
  unpacked <- tempfile("llmsa-llm-raw-")
  dir.create(unpacked)
  on.exit(unlink(unpacked, recursive = TRUE), add = TRUE)
  members <- utils::untar(archive, list = TRUE)
  selected_files <- unlist(lapply(unlist(a$selection$folders), function(folder) {
    prefix <- paste0(a$runs_archive$top_directory, "/", folder, "/")
    files <- members[startsWith(members, prefix) & grepl("\\.csv$", members)]
    if (length(files) != a$n_runs || any(grepl("/", substring(files, nchar(prefix) + 1L), fixed = TRUE))) {
      m1d_abort("unexpected archive members in ", folder)
    }
    files
  }), use.names = FALSE)
  status <- utils::untar(archive, files = selected_files, exdir = unpacked)
  if (status != 0L) m1d_abort("cannot extract llm-stability archive")
  rows <- vector("list", length(selected_files))
  for (i in seq_along(selected_files)) {
    file <- file.path(unpacked, selected_files[i])
    x <- utils::read.csv(file, colClasses = "character", stringsAsFactors = FALSE,
                         check.names = FALSE, encoding = "UTF-8")
    needed <- c("task", "model", "run", "rubric_id", "gt", "question", "response", "model_config", "task_config")
    if (!all(needed %in% names(x))) m1d_abort("missing llm-stability columns: ", basename(file))
    for (config in unique(x$model_config)) {
      if (!m1d_same_config(m1d_config(config), a$model_config)) m1d_abort("unexpected model configuration")
    }
    for (config in unique(x$task_config)) {
      if (!m1d_same_config(m1d_config(config), a$selection$task_config)) m1d_abort("unexpected task configuration")
    }
    folder <- basename(dirname(file))
    if (length(unique(x$task)) != 1L || length(unique(x$model)) != 1L || length(unique(x$run)) != 1L ||
        !identical(a$selection$folders[[paste(x$model[1L], x$task[1L], sep = "|")]], folder)) {
      m1d_abort("source rows do not match their run folder: ", basename(file))
    }
    if (any(!grepl("^[0-9]+$", x$run)) || any(!grepl("^[0-9]+$", x$rubric_id))) m1d_abort("invalid run/item_id")
    rows[[i]] <- data.frame(task = x$task, model = x$model, run = as.integer(x$run),
      item_id = as.integer(x$rubric_id), gt = x$gt, question = x$question, response = x$response,
      stringsAsFactors = FALSE)
  }
  raw <- m1d_order(do.call(rbind, rows), c("task", "model", "run", "item_id"))
  keys <- m1d_validate_llm(raw, a)
  options <- m1d_options(keys$question, keys$task)
  key_index <- match(paste(raw$task, raw$item_id, sep = "|"), paste(keys$task, keys$item_id, sep = "|"))
  parsed <- m1d_parse_answers(raw$response, options[key_index])
  output <- raw[c("task", "model", "run", "item_id")]
  output$answer <- parsed$answer
  output$correct <- m1d_correct(output$answer, raw$gt)
  nonlabel <- !vapply(seq_len(nrow(keys)), function(i) keys$gt[i] %in% options[[i]], logical(1))
  anomalies <- paste(paste0(keys$task[nonlabel], " item_id ", keys$item_id[nonlabel]), collapse = "; ")
  counts <- as.data.frame(table(task = raw$task, model = raw$model,
                               reason = factor(parsed$reason, c("parsed", "empty", "no_label", "ambiguous"))),
                         stringsAsFactors = FALSE)
  counts <- m1d_order(counts, c("task", "model", "reason"))
  source <- c(
    "Source: llm-stability (Atil et al.), frozen v3 item-level subset.",
    paste("URL:", a$repository), paste("Commit (ANK-40):", a$commit),
    paste("License:", a$license, "(Apache License 2.0)."),
    paste("Raw folder:", a$raw_folder),
    paste("Archive:", a$runs_archive$path, "SHA-256", a$runs_archive$sha256),
    paste("Evaluation:", a$evaluation_file$path, "SHA-256", a$evaluation_file$sha256),
    "Selection: experiments/v3/runs.tgz; the zero-shot folders in ANK-40 selected",
    "by stability_eval.csv with shots = 0 and top_p_k = 1.0; no few-shot or v2 runs.",
    "Generator: data-raw/make_llm_stability.R (offline; ADR-049).",
    "Answer rule: exactly one distinct valid parenthesized ASCII letter, (A) to (Z),",
    "case-insensitive, without internal spaces. Repeated occurrences of the same",
    "label count once. Bare letters and bare answer formulas are not accepted.",
    "Quoted labels count like other labels; no priority for a final answer.",
    "For navigate, exactly one of Yes/No as a whole word, case-insensitive.",
    "Empty responses, no valid label, or multiple distinct valid labels remain NA.",
    "The key gt never selects a label; correct is answer == gt, or NA if missing.",
    paste0("Non-label answer keys: ", if (nzchar(anomalies)) anomalies else "none", "."),
    "These items can only count as misses in the hit rate under literal label/key",
    "equality, even for a semantically correct labelled answer. No key repair is made.",
    paste("Rows:", nrow(output)),
    paste("Missing answers:", sum(is.na(output$answer))),
    "Parsing counts (task | model | reason | rows):",
    apply(counts, 1L, paste, collapse = " | "),
    "Storage: UTF-8 CSV, quoted character fields, doubled internal quotes, LF,",
    "empty fields for NA; radix order task/model/run/item_id; gzip without timestamp.",
    "No response text is distributed. SHA256SUMS includes this file."
  )
  target <- file.path(root, "inst", "extdata", "llm-stability_2026-10-22")
  stage <- tempfile(".m1d-llm-", tmpdir = dirname(target))
  dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  m1d_write_csv(output, file.path(stage, "items.csv.gz"))
  m1d_write_text(source, file.path(stage, "QUELLE.txt"))
  m1d_manifest(stage)
  size <- m1d_check_sizes(stage, target, limits)
  m1d_publish(stage, target)
  cat(sprintf("llm-stability: %d rows; %d missing answers; %d non-label keys; %d bytes published\n",
              nrow(output), sum(is.na(output$answer)), sum(nonlabel), size))
  print(table(parsed$reason))
  invisible(output)
}

if (sys.nframe() == 0L) {
  if (length(commandArgs(trailingOnly = TRUE))) stop("Usage: Rscript data-raw/make_llm_stability.R", call. = FALSE)
  script <- sub("^--file=", "", commandArgs()[startsWith(commandArgs(), "--file=")])
  make_llm_stability(dirname(dirname(normalizePath(script, mustWork = TRUE))))
}
