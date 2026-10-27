# Helpers for the M2 acceptance tests (docs/03-anwendungspipeline.md, K-M2-1 to
# K-M2-7); a setup file for the reason given in setup-acceptance.R.
#
# Reference values come from reference/anchors/ (ANK-41, ANK-50 to ANK-69, ANK-94,
# ANK-TOL). Raw data are read from ../quellen/daten/ next to the repository root
# (docs/01 §7); a missing file fails the test, it never skips it (AGENTS.md).
# The mini-references below are written independently of the package code.
# Interpretations of points on which the spec is silent are listed in
# orchestrator/handoff/M2/CRITERIA.json under "open" (ACC-n).

acc_m2 <- new.env(parent = emptyenv())   # cache for one test run

# Paths ------------------------------------------------------------------------

acc_m2_quellen <- function(...) file.path(dirname(acc_repo_root()), "quellen", "daten", ...)
acc_m2_item_dir <- function() file.path(acc_pkg_root(), "inst", "extdata", "items_ap1_2026-10-24")
acc_m2_ap1_dir <- function() file.path(acc_pkg_root(), "inst", "validation", "ap1")

acc_m2_require_file <- function(path, what) {
  if (!file.exists(path)) stop("acceptance: ", what, " missing: ", path, call. = FALSE)
  path
}

acc_m2_fn <- function(name) {
  fn <- get0(name, envir = asNamespace(acc_pkg), mode = "function", inherits = FALSE)
  if (is.null(fn)) stop("acceptance: internal function ", name, "() missing in the package", call. = FALSE)
  fn
}

# Anchor values ------------------------------------------------------------------

acc_m2_classes <- function() as.character(unlist(acc_anchor("ANK-69")$value$classes))

# Alias table of A.3 as a named character vector alias -> class.
acc_m2_aliases <- function() {
  al <- acc_anchor("ANK-69")$value$aliases
  out <- character()
  for (cl in names(al)) out <- c(out, stats::setNames(rep(cl, length(al[[cl]])), unlist(al[[cl]])))
  out
}

acc_m2_templates <- function() unlist(acc_anchor("ANK-69")$value$templates)

acc_m2_tol <- function(name) acc_anchor("ANK-TOL")$value[[name]]

acc_m2_cutoffs <- function() {
  c(sol = as.Date(acc_anchor("ANK-50")$value),
    llama = as.Date(acc_anchor("ANK-65")$value),
    qwen = as.Date(acc_anchor("ANK-66")$value))
}

# Text helpers ---------------------------------------------------------------------

acc_m2_squish <- function(x) gsub("[[:space:]]+", " ", trimws(x))

acc_m2_text_hash <- function(x) {
  f <- tempfile("acc-m2-hash-")
  on.exit(unlink(f), add = TRUE)
  writeLines(enc2utf8(paste(x, collapse = "\n")), f, useBytes = TRUE)
  unname(tools::md5sum(f))
}

# Words of a text: lower case, split at every character that is neither a letter
# nor a digit (whitespace and punctuation).
acc_m2_words <- function(text) {
  w <- strsplit(tolower(text), "[^[:alnum:]]+")[[1]]
  w[nzchar(w)]
}

# Mini-reference of parse_choice(levels, aliases, whole_word = TRUE) after K-M2-3:
# classes and aliases match only as whole words or word sequences, case-insensitive;
# longer sequences are tried first and consume their words; two different classes or
# none give NA.
acc_m2_parse_ww <- function(text, classes = acc_m2_classes(), aliases = acc_m2_aliases()) {
  if (is.null(text) || length(text) != 1L || is.na(text)) return(NA_character_)
  phrase_class <- c(stats::setNames(classes, classes), aliases)
  phrase_words <- lapply(names(phrase_class), acc_m2_words)
  size <- lengths(phrase_words)
  try_order <- order(-size)
  words <- acc_m2_words(text)
  found <- character()
  i <- 1L
  while (i <= length(words)) {
    matched <- FALSE
    for (k in try_order) {
      n <- size[k]
      if (n > 0L && i + n - 1L <= length(words) && identical(words[i:(i + n - 1L)], phrase_words[[k]])) {
        found <- c(found, unname(phrase_class[k]))
        i <- i + n
        matched <- TRUE
        break
      }
    }
    if (!matched) i <- i + 1L
  }
  found <- unique(found)
  if (length(found) == 1L) found else NA_character_
}

# Mini-reference of parse_choice(levels, aliases) as in v0.1.0 (R/parse.R at
# 332a2d5, ANK-01): case-insensitive substring search, longest key first, first
# hit wins.
acc_m2_parse_v010 <- function(text, levels, aliases = NULL) {
  if (is.null(text) || !length(text) || is.na(text)) return(NA_character_)
  keys <- tolower(levels)
  vals <- as.character(levels)
  if (!is.null(aliases)) {
    keys <- c(keys, tolower(names(aliases)))
    vals <- c(vals, as.character(unlist(aliases)))
  }
  x <- tolower(as.character(text)[1])
  for (k in order(-nchar(keys))) {
    if (grepl(keys[k], x, fixed = TRUE)) return(vals[match(keys[k], keys)])
  }
  NA_character_
}

# Maps a class name as written in a source file (ERepo "Likely Pathogenic", INSAID
# "VOUS") to the class label of A.3 (ANK-69).
acc_m2_label <- function(x) vapply(x, acc_m2_parse_ww, character(1), USE.NAMES = FALSE)

# CSV files of the item set ---------------------------------------------------------

acc_m2_columns <- function() {
  c("item_id", "source", "gene", "transcript", "hgvs", "protein", "reference", "panel",
    paste0("prior_clinvar_class_", c("sol", "llama", "qwen")),
    paste0("prior_date_", c("sol", "llama", "qwen")),
    paste0("prior_differs_", c("sol", "llama", "qwen")))
}

# Reads items.csv or pilot.csv as text: every field character, an empty field "".
acc_m2_read_csv <- function(name) {
  path <- acc_m2_require_file(file.path(acc_m2_item_dir(), name), name)
  utils::read.csv(path, colClasses = "character", na.strings = character(), check.names = FALSE,
                  encoding = "UTF-8", stringsAsFactors = FALSE)
}

acc_m2_items <- function() acc_m2_read_csv("items.csv")
acc_m2_pilot <- function() acc_m2_read_csv("pilot.csv")

# Parses a prior date in ISO form (2025-03-31) or in the form of ClinVar
# (Mar 31, 2025); "" gives NA.
acc_m2_parse_date <- function(x) {
  x <- as.character(x)
  out <- rep(as.Date(NA), length(x))
  iso <- grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", x)
  out[iso] <- as.Date(x[iso], format = "%Y-%m-%d")
  cv <- !iso & nzchar(x) & !is.na(x)
  if (any(cv)) {
    old <- Sys.getlocale("LC_TIME")
    on.exit(Sys.setlocale("LC_TIME", old), add = TRUE)
    Sys.setlocale("LC_TIME", "C")
    out[cv] <- as.Date(x[cv], format = "%b %d, %Y")
  }
  out
}

# Normalises an item table for comparisons: character columns, NA -> "", logical
# text in upper case, dates as ISO text.
acc_m2_normalise_items <- function(d) {
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  for (nm in names(d)) {
    v <- d[[nm]]
    if (inherits(v, "Date")) v <- format(v, "%Y-%m-%d")
    v <- as.character(v)
    v[is.na(v)] <- ""
    if (startsWith(nm, "prior_differs_")) v <- toupper(v)
    if (startsWith(nm, "prior_date_")) {
      parsed <- acc_m2_parse_date(v)
      v[!is.na(parsed)] <- format(parsed[!is.na(parsed)], "%Y-%m-%d")
    }
    d[[nm]] <- v
  }
  d
}

# ClinGen ERepo (ANK-51) --------------------------------------------------------------

acc_m2_erepo <- function() {
  if (!is.null(acc_m2$erepo)) return(acc_m2$erepo)
  a <- acc_anchor("ANK-51")$value
  path <- acc_m2_require_file(acc_m2_quellen("clingen-erepo_2026-10-22", a$file), "local ERepo export (ANK-51)")
  if (!identical(acc_sha256(path), a$file_sha256)) {
    stop("acceptance: ", path, " differs from ANK-51 (SHA-256)", call. = FALSE)
  }
  x <- utils::read.delim(path, quote = "", comment.char = "", check.names = FALSE, colClasses = "character",
                         na.strings = character(), encoding = "UTF-8")
  acc_m2$erepo <- x
  x
}

# Splits #Variation into transcript, c. notation and protein (K-M2-1). Accepted
# forms: <NM>(<gene>):c.<...> with an optional " (p.<...>)", or <NM>:c.<...>.
acc_m2_split_variation <- function(v) {
  out <- data.frame(ok = FALSE, transcript = "", cdna = "", protein = "", gene = "", stringsAsFactors = FALSE)
  out <- out[rep(1L, length(v)), , drop = FALSE]
  rownames(out) <- NULL
  for (i in seq_along(v)) {
    s <- v[i]
    if (!startsWith(s, "NM_")) next
    colon <- regexpr(":c.", s, fixed = TRUE)
    if (colon < 0) next
    head <- substr(s, 1L, colon - 1L)
    tail <- substr(s, colon + 1L, nchar(s))
    gene <- ""
    if (grepl("\\(", head)) {
      if (!grepl("^NM_[0-9]+\\.[0-9]+\\([^()]+\\)$", head)) next
      gene <- sub("^.*\\((.*)\\)$", "\\1", head)
      head <- sub("\\(.*$", "", head)
    } else if (!grepl("^NM_[0-9]+\\.[0-9]+$", head)) next
    protein <- ""
    p_at <- regexpr(" (p.", tail, fixed = TRUE)
    if (p_at > 0) {
      if (!nzchar(gene) || !endsWith(tail, ")")) next
      protein <- substr(tail, p_at + 2L, nchar(tail) - 1L)
      tail <- substr(tail, 1L, p_at - 1L)
    }
    if (grepl(" ", tail) || grepl("[()]", protein)) next
    out$ok[i] <- TRUE
    out$transcript[i] <- head
    out$cdna[i] <- tail
    out$protein[i] <- protein
    out$gene[i] <- gene
  }
  out
}

# Pool of K-M2-1: NM c. notation, not retracted, approval and publication after the
# cut-off date (ANK-50). One row per classification with the expected item fields.
acc_m2_pool <- function() {
  if (!is.null(acc_m2$pool)) return(acc_m2$pool)
  x <- acc_m2_erepo()
  cutoff <- as.Date(acc_anchor("ANK-50")$value)
  sp <- acc_m2_split_variation(x[["#Variation"]])
  keep <- sp$ok & x$Retracted == "false" & as.Date(x[["Approval Date"]]) > cutoff &
    as.Date(x[["Published Date"]]) > cutoff
  pool <- data.frame(
    row = which(keep),
    variation = x[["#Variation"]][keep],
    gene = x[["HGNC Gene Symbol"]][keep],
    transcript = sp$transcript[keep],
    hgvs = paste0(sp$transcript, ":", sp$cdna)[keep],
    cdna = sp$cdna[keep],
    protein = sp$protein[keep],
    reference = acc_m2_label(x$Assertion[keep]),
    panel = x[["Expert Panel"]][keep],
    clinvar_id = x[["ClinVar Variation Id"]][keep],
    stringsAsFactors = FALSE
  )
  acc_m2$pool <- pool
  pool
}

# INSAID (ANK-52, ANK-64) ---------------------------------------------------------------

acc_m2_insaid_path <- function() {
  a <- acc_anchor("ANK-52")$value
  acc_m2_require_file(acc_m2_quellen("insaid-vangijn2018_2026-10-23", a$file), "local INSAID TSV (ANK-52)")
}

acc_m2_insaid <- function() {
  if (!is.null(acc_m2$insaid)) return(acc_m2$insaid)
  path <- acc_m2_insaid_path()
  if (!identical(acc_sha256(path), acc_anchor("ANK-52")$value$sha256)) {
    stop("acceptance: ", path, " differs from ANK-52 (SHA-256)", call. = FALSE)
  }
  x <- utils::read.delim(path, quote = "", comment.char = "#", check.names = FALSE, colClasses = "character",
                         na.strings = character(), encoding = "UTF-8")
  x$label <- acc_m2_label(x$classification)
  acc_m2$insaid <- x
  x
}

# Round-robin check (K-M2-1) --------------------------------------------------------------
#
# A round-robin over groups (panels or genes) in an order sigma visits the groups in
# rounds and takes one candidate per visit until the group is exhausted. `cand`,
# `main`, `pilot` and `key` are named vectors over the same groups: candidates of
# the class, selected main items, selected pilot items, and the sort key (descending
# key = earlier in sigma; ties in any order). With key = NULL no order is required.
# The pilot items must be the picks right after the main items of the same
# round-robin. Returns character() if consistent, otherwise the violations.
acc_m2_round_robin_violations <- function(cand, main, pilot = NULL, key = NULL) {
  groups <- names(cand)
  if (is.null(pilot)) pilot <- stats::setNames(rep(0L, length(groups)), groups)
  main <- main[groups]; pilot <- pilot[groups]
  main[is.na(main)] <- 0L; pilot[is.na(pilot)] <- 0L
  m <- main + pilot
  out <- character()
  over <- groups[m > cand]
  if (length(over)) out <- c(out, paste("more picks than candidates:", paste(over, collapse = ", ")))
  rounds <- max(m)
  short <- groups[m < pmin(cand, rounds - 1L)]
  if (length(short)) out <- c(out, paste("skipped in an earlier round:", paste(short, collapse = ", ")))
  if (is.null(key)) return(out)
  before <- list()   # pairs (a, b): a must come before b in sigma
  need <- function(a, b, why) {
    if (key[[a]] < key[[b]]) {
      out <<- c(out, sprintf("%s (key %s) must precede %s (key %s): %s", a, format(key[[a]]), b, format(key[[b]]), why))
    } else if (key[[a]] == key[[b]]) {
      before[[length(before) + 1L]] <<- c(a, b)
    }
  }
  picked_last <- groups[m == rounds]
  waiting <- groups[cand >= rounds & m == rounds - 1L]
  for (a in picked_last) for (b in waiting) need(a, b, sprintf("picked in round %d", rounds))
  for (q in groups[main > 0L]) for (p in groups[pilot > 0L]) {
    if (identical(p, q)) next
    last_main <- main[[q]]
    first_pilot <- main[[p]] + 1L
    if (last_main > first_pilot) {
      out <- c(out, sprintf("main pick of %s in round %d after pilot pick of %s in round %d", q, last_main, p, first_pilot))
    } else if (last_main == first_pilot) {
      need(q, p, "main pick before pilot pick in the same round")
    }
  }
  if (length(before)) {
    nodes <- unique(unlist(before))
    edges <- do.call(rbind, before)
    while (length(nodes)) {
      free <- nodes[!nodes %in% edges[, 2]]
      if (!length(free)) {
        out <- c(out, paste("tie order is cyclic among:", paste(nodes, collapse = ", ")))
        break
      }
      nodes <- setdiff(nodes, free)
      edges <- edges[!edges[, 1] %in% free, , drop = FALSE]
    }
  }
  out
}

# ClinVar submission_summary (ANK-41, ANK-63) -----------------------------------------------

# Rows of submission_summary.txt.gz for the given ClinVar variation ids, parsed by
# the column positions of ANK-63. The file is read once per test run and the
# extract is cached in the session's temporary directory.
acc_m2_clinvar_rows <- function(ids) {
  ids <- sort(unique(as.character(ids)))
  key <- acc_m2_text_hash(ids)
  if (identical(acc_m2$clinvar_key, key)) return(acc_m2$clinvar)
  info <- acc_anchor("ANK-41")$value$files[["submission_summary.txt.gz"]]
  cols <- acc_anchor("ANK-63")$value
  path <- acc_m2_require_file(acc_m2_quellen("clinvar_2026-10-22", "submission_summary.txt.gz"),
                              "local ClinVar submission_summary (ANK-41)")
  cache <- file.path(tempdir(), paste0("acc-m2-clinvar-", info$md5, "-", key, ".rds"))
  if (file.exists(cache)) {
    rows <- readRDS(cache)
  } else {
    if (!identical(unname(tools::md5sum(path)), info$md5)) {
      stop("acceptance: ", path, " differs from ANK-41 (md5)", call. = FALSE)
    }
    con <- gzfile(path, "r")
    on.exit(close(con), add = TRUE)
    kept <- character()
    header <- NULL
    repeat {
      chunk <- readLines(con, n = 500000L, encoding = "UTF-8")
      if (!length(chunk)) break
      if (is.null(header)) {
        h <- chunk[startsWith(chunk, cols$header_line_prefix)]
        if (length(h)) header <- strsplit(sub("^#", "", h[1]), "\t", fixed = TRUE)[[1]]
      }
      chunk <- chunk[!startsWith(chunk, "#")]
      kept <- c(kept, chunk[sub("\t.*$", "", chunk) %in% ids])
    }
    if (is.null(header) || length(header) != cols$n_columns_file) {
      stop("acceptance: unexpected header in ", path, call. = FALSE)
    }
    for (nm in names(cols$columns)) {
      if (!identical(header[cols$columns[[nm]]], nm)) stop("acceptance: column ", nm, " not at ANK-63 position", call. = FALSE)
    }
    parts <- strsplit(kept, "\t", fixed = TRUE)
    pick <- function(j) vapply(parts, function(p) if (length(p) >= j) p[j] else "", character(1))
    rows <- data.frame(
      VariationID = pick(cols$columns$VariationID),
      ClinicalSignificance = pick(cols$columns$ClinicalSignificance),
      DateLastEvaluated = pick(cols$columns$DateLastEvaluated),
      ReviewStatus = pick(cols$columns$ReviewStatus),
      Submitter = pick(cols$columns$Submitter),
      stringsAsFactors = FALSE
    )
    saveRDS(rows, cache)
  }
  rows$date <- acc_m2_parse_date(ifelse(rows$DateLastEvaluated == acc_anchor("ANK-63")$value$date_missing, "",
                                        rows$DateLastEvaluated))
  acc_m2$clinvar_key <- key
  acc_m2$clinvar <- rows
  rows
}

# Admissible values of (prior_clinvar_class, prior_date) for one ERepo item and one
# cut-off date (K-M2-2). The spec fixes: latest submission of another submitter
# than the expert panel before the cut-off, majority on equal dates, "conflicting"
# on a tie, "none" without such a submission. It leaves open (ACC-6): "before" as
# < or <=; which values count as a classification (the five classes, or every
# value except "not provided" and "-"); whether flagged submissions count; whether
# all expert-panel submissions or only the item's own panel are excluded. Every
# combination of these readings is admissible. Undated submissions ("-") cannot lie
# before the cut-off and never count.
acc_m2_prior_options <- function(rows, cutoff, panel, classes = acc_m2_classes()) {
  ep_status <- acc_anchor("ANK-63")$value$expert_panel_review_status
  stem <- tolower(acc_m2_squish(sub("VCEP\\s*$", "", panel)))
  is_ep <- rows$ReviewStatus == ep_status
  own <- is_ep & grepl(stem, tolower(acc_m2_squish(rows$Submitter)), fixed = TRUE)
  if (!any(own)) own <- is_ep
  options <- list()
  for (cmp in c("lt", "le")) for (cls in c("five", "any")) for (flag in c("keep", "drop")) for (ep in c("all", "own")) {
    ok <- !is.na(rows$date) & if (cmp == "lt") rows$date < cutoff else rows$date <= cutoff
    ok <- ok & if (cls == "five") tolower(rows$ClinicalSignificance) %in% tolower(classes) else
      !rows$ClinicalSignificance %in% c("not provided", "-", "")
    if (flag == "drop") ok <- ok & rows$ReviewStatus != "flagged submission"
    ok <- ok & !(if (ep == "all") is_ep else own)
    r <- rows[ok, , drop = FALSE]
    if (!nrow(r)) {
      options[[length(options) + 1L]] <- c(class = "none", date = "")
      next
    }
    last <- r[r$date == max(r$date), , drop = FALSE]
    tab <- table(last$ClinicalSignificance)
    top <- names(tab)[tab == max(tab)]
    options[[length(options) + 1L]] <- c(class = if (length(top) == 1L) top else "conflicting",
                                         date = format(max(r$date), "%Y-%m-%d"))
  }
  unique(as.data.frame(do.call(rbind, options), stringsAsFactors = FALSE))
}

# Evaluation mini-references (K-M2-6, K-M2-7; ANK-58, ANK-68) ---------------------------------

# Modal value of one item: NA is a value of its own; a tie gives no modal value.
acc_m2_modal <- function(values) {
  v <- ifelse(is.na(values), "\001NA", as.character(values))
  tab <- table(v)
  top <- names(tab)[tab == max(tab)]
  if (length(top) != 1L) return(list(has_modal = FALSE, modal = NA_character_))
  list(has_modal = TRUE, modal = if (identical(top, "\001NA")) NA_character_ else top)
}

# Linearly weighted kappa of `rated` against `reference` over the classes in scale
# order; NA in `rated` has agreement weight 0 to every class (ANK-68).
acc_m2_kappa <- function(rated, reference, classes = acc_m2_classes()) {
  k <- length(classes)
  i <- ifelse(is.na(rated), k + 1L, match(rated, classes))
  j <- match(reference, classes)
  if (anyNA(i) || anyNA(j) || !length(i)) return(NA_real_)
  p <- table(factor(i, levels = seq_len(k + 1L)), factor(j, levels = seq_len(k))) / length(i)
  w <- outer(seq_len(k + 1L), seq_len(k), function(a, b) ifelse(a > k, 0, 1 - abs(a - b) / (k - 1)))
  po <- sum(w * p)
  pe <- sum(w * outer(rowSums(p), colSums(p)))
  if (isTRUE(all.equal(pe, 1))) return(NA_real_)
  (po - pe) / (1 - pe)
}

# Percentile bootstrap over items; also returns the replicates for the Monte-Carlo
# standard error of the interval limits.
acc_m2_kappa_boot <- function(rated, reference, replicates, level, seed, classes = acc_m2_classes()) {
  n <- length(rated)
  old <- if (exists(".Random.seed", envir = globalenv())) get(".Random.seed", envir = globalenv()) else NULL
  on.exit(if (is.null(old)) rm(".Random.seed", envir = globalenv()) else assign(".Random.seed", old, envir = globalenv()), add = TRUE)
  set.seed(seed)
  kb <- vapply(seq_len(replicates), function(b) {
    idx <- sample.int(n, n, replace = TRUE)
    acc_m2_kappa(rated[idx], reference[idx], classes)
  }, numeric(1))
  kb <- kb[is.finite(kb)]
  a <- (1 - level) / 2
  list(limits = unname(stats::quantile(kb, c(a, 1 - a))), replicates = kb, a = a)
}

# Monte-Carlo standard error of a percentile estimated from bootstrap replicates
# (resampling the replicates).
acc_m2_quantile_mcse <- function(replicates, prob, seed = 1L) {
  old <- if (exists(".Random.seed", envir = globalenv())) get(".Random.seed", envir = globalenv()) else NULL
  on.exit(if (is.null(old)) rm(".Random.seed", envir = globalenv()) else assign(".Random.seed", old, envir = globalenv()), add = TRUE)
  set.seed(seed)
  stats::sd(replicate(500L, stats::quantile(sample(replicates, replace = TRUE), prob)))
}

acc_m2_bands <- function() c("acceptable", "marginal", "unacceptable")

acc_m2_band_grr <- function(pct) {
  a <- acc_anchor("ANK-58")$value$grr_pct_study_var
  if (is.na(pct)) return(NA_character_)
  if (pct < a$acceptable_below) "acceptable" else if (pct <= a$marginal_below) "marginal" else "unacceptable"
}

acc_m2_band_kappa <- function(kappa) {
  a <- acc_anchor("ANK-58")$value$kappa_linear_modal
  if (is.na(kappa)) return(NA_character_)
  if (kappa >= a$acceptable_min) "acceptable" else if (kappa >= a$marginal_min) "marginal" else "unacceptable"
}

acc_m2_band_dangerous <- function(n) {
  a <- acc_anchor("ANK-58")$value$dangerous_errors
  if (n <= a$acceptable_max) "acceptable" else if (n <= a$marginal_max) "marginal" else "unacceptable"
}

acc_m2_band_robustness <- function(delta_p, effect, sme) {
  limit <- acc_anchor("ANK-58")$value$robustness$delta_p_limit
  large <- abs(delta_p) > limit
  if (!any(large)) "acceptable" else if (any(large & abs(effect) > sme)) "unacceptable" else "marginal"
}

acc_m2_worst <- function(bands) acc_m2_bands()[max(match(bands, acc_m2_bands()))]

acc_m2_empirical_logit <- function(x, n) {
  c0 <- acc_anchor("ANK-68")$value$robustness_response$correction
  log((x + c0) / (n - x + c0))
}

# Prompt composition (K-M2-7, ANK-62) ------------------------------------------------------

# Expected user message template and system prompt of one robustness run from its
# coded levels (-1/+1 for F1 to F8).
acc_m2_compose <- function(lev) {
  b <- acc_anchor("ANK-62")$value$blocks
  comp <- acc_anchor("ANK-62")$value$composition
  lang <- if (lev[["F8"]] > 0) "de" else "en"
  task <- if (lev[["F3"]] > 0) b$task_typo[[lang]] else b$task[[lang]]
  fmt <- if (lev[["F7"]] > 0) b$format_abbrev[[lang]] else b$format_full[[lang]]
  body <- if (lev[["F4"]] > 0) paste0(fmt, comp$sentence_separator, task) else paste0(task, comp$sentence_separator, fmt)
  if (lev[["F5"]] > 0) body <- paste0(b$context[[lang]], comp$context_separator, body)
  list(template = body, system = if (lev[["F6"]] > 0) b$system$en else "")
}

# Expected variant text in {hgvs} of one item for the levels of F1 and F2.
acc_m2_variant_text <- function(item, f1, f2) {
  cdna <- sub("^[^:]*:", "", item$hgvs)
  txt <- if (f1 > 0) cdna else item$hgvs
  if (f2 > 0 && nzchar(item$protein)) txt <- paste0(txt, sprintf(acc_anchor("ANK-62")$value$composition$protein_suffix, item$protein))
  txt
}

acc_m2_fill <- function(template, gene, hgvs) {
  out <- gsub("{gene}", gene, template, fixed = TRUE)
  gsub("{hgvs}", hgvs, out, fixed = TRUE)
}

acc_m2_pb <- function() {
  d <- llmsa::pb_design(8, n_runs = 12, seed = acc_anchor("ANK-59")$value$seed)
  x <- attr(d, "coded")
  rownames(x) <- sprintf("pb%02d", seq_len(nrow(x)))
  x
}

# Accessors for acmg_prompts() (ACC-8) ------------------------------------------------------

acc_m2_main_templates <- function() {
  p <- acc_m2_fn("acmg_prompts")()
  if (is.data.frame(p)) {
    if (!all(c("prompt_id", "template") %in% names(p))) stop("acceptance: acmg_prompts() data.frame needs prompt_id and template", call. = FALSE)
    return(stats::setNames(as.character(p$template), as.character(p$prompt_id)))
  }
  if (!is.character(p) || is.null(names(p))) stop("acceptance: acmg_prompts() must return a named character vector or a data.frame", call. = FALSE)
  p
}

# run.R and the mock store (K-M2-6, K-M2-7; ACC-11) -------------------------------------------

# Runs inst/validation/ap1/run.R of the package under test with `args`, working
# directory `wd` (default: the package root).
acc_m2_run <- function(args, wd = acc_pkg_root(), script = file.path(acc_m2_ap1_dir(), "run.R")) {
  acc_m2_require_file(script, "inst/validation/ap1/run.R")
  old <- setwd(wd)
  on.exit(setwd(old), add = TRUE)
  res <- acc_run(file.path(R.home("bin"), "Rscript"), shQuote(c(script, args)))
  res$args <- args
  res
}

acc_m2_show <- function(res) {
  paste(c(paste("run.R", paste(res$args, collapse = " "), "-> exit", res$status), utils::tail(res$stdout, 30),
          utils::tail(res$stderr, 30)), collapse = "\n")
}

acc_m2_store_rows <- function(store) {
  if (!file.exists(store)) return(NULL)
  con <- DBI::dbConnect(RSQLite::SQLite(), store)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  if (!"runs" %in% DBI::dbListTables(con)) return(NULL)
  DBI::dbReadTable(con, "runs")
}

acc_m2_count <- function(store) {
  r <- acc_m2_store_rows(store)
  if (is.null(r)) 0L else nrow(r)
}

# One store filled by run.R step by step: main block 1, main block 2, robustness,
# pilot, pilot again; and a second store with the main plan in one call. Each step
# records exit status, output and the number of stored rows. Computed once per run.
acc_m2_mock <- function() {
  if (!is.null(acc_m2$mock)) return(acc_m2$mock)
  dir <- tempfile("acc-m2-store-")
  dir.create(dir)
  store <- file.path(dir, "ap1_runs.sqlite")
  steps <- list(
    main1 = c("--part", "main", "--block", "1", "--backend", "mock", "--store", store),
    main2 = c("--part", "main", "--block", "2", "--backend", "mock", "--store", store),
    robustness = c("--part", "robustness", "--backend", "mock", "--store", store),
    pilot = c("--part", "pilot", "--backend", "mock", "--store", store),
    pilot_again = c("--part", "pilot", "--backend", "mock", "--store", store)
  )
  res <- list()
  counts <- integer()
  tree <- function() {
    f <- list.files(acc_pkg_root(), recursive = TRUE, all.files = TRUE)
    f[!grepl("^(\\.git|orchestrator|reference/quellen|reference/privat)/", f)]
  }
  before <- tree()
  for (nm in names(steps)) {
    res[[nm]] <- acc_m2_run(steps[[nm]])
    counts[[nm]] <- acc_m2_count(store)
    if (res[[nm]]$status != 0L) break
  }
  full_store <- file.path(dir, "ap1_main_full.sqlite")
  if (all(vapply(res, function(r) r$status == 0L, NA)) && length(res) == length(steps)) {
    res$main_full <- acc_m2_run(c("--part", "main", "--backend", "mock", "--store", full_store))
  }
  after <- tree()
  acc_m2$mock <- list(store = store, full_store = full_store, res = res, counts = counts,
                      new_files = setdiff(after, before))
  acc_m2$mock
}

acc_m2_mock_ok <- function() {
  m <- acc_m2_mock()
  failed <- names(m$res)[!vapply(m$res, function(r) r$status == 0L, NA)]
  if (length(failed) || length(m$res) < 6L) {
    msg <- if (length(failed)) acc_m2_show(m$res[[failed[1]]]) else "run.R steps incomplete"
    stop("acceptance: run.R with the mock backend failed\n", msg, call. = FALSE)
  }
  m
}

acc_m2_main_prompts <- function() names(acc_anchor("ANK-69")$value$templates)

# Store rows of the main plan with the item columns of acmg_items() joined, as
# msa_run() carries them along (ACC-12).
acc_m2_runs_with_items <- function(rows, items) {
  items <- as.data.frame(items, stringsAsFactors = FALSE)
  extra <- setdiff(names(items), c("item_id", names(rows)))
  for (col in extra) rows[[col]] <- items[[col]][match(rows$item_id, items$item_id)]
  llmsa::as_msa_runs(rows)
}

# Evaluation of the mock store, computed once per run (main plan and robustness).
acc_m2_evaluation <- function() {
  if (!is.null(acc_m2$evaluation)) return(acc_m2$evaluation)
  m <- acc_m2_mock_ok()
  rows <- acc_m2_store_rows(m$store)
  items_df <- acc_m2_fn("acmg_items")()
  plan <- acc_m2_fn("acmg_plan")()
  main_rows <- rows[rows$prompt_id %in% acc_m2_main_prompts() & rows$item_id %in% items_df$item_id, , drop = FALSE]
  rob_rows <- rows[grepl("^pb[0-9]{2}$", rows$prompt_id), , drop = FALSE]
  ev_main <- acc_m2_evaluate(acc_m2_runs_with_items(main_rows, items_df), plan)
  ev_all <- acc_m2_evaluate(acc_m2_runs_with_items(rbind(main_rows, rob_rows), items_df), plan)
  acc_m2$evaluation <- list(main = ev_main, all = ev_all, main_rows = main_rows, rob_rows = rob_rows,
                            items = items_df, plan = plan)
  acc_m2$evaluation
}

# Calls acmg_evaluate() in a fresh temporary working directory, so that files it
# may write (reports) never land in the repository. Only the call itself runs
# there; anchors are read before and after.
acc_m2_evaluate <- function(runs, plan) {
  evaluate <- acc_m2_fn("acmg_evaluate")
  wd <- tempfile("acc-m2-eval-wd-")
  dir.create(wd)
  old <- setwd(wd)
  on.exit(setwd(old), add = TRUE)
  evaluate(runs, plan)
}

# Expected per-model results from the stored values (mini-reference).
acc_m2_expected_model <- function(main_rows, items, key) {
  classes <- acc_m2_classes()
  r <- main_rows[main_rows$model_id == key, , drop = FALSE]
  modal <- lapply(split(r$value, r$item_id), acc_m2_modal)
  md <- data.frame(item_id = names(modal), has_modal = vapply(modal, `[[`, NA, "has_modal"),
                   modal = vapply(modal, `[[`, "", "modal"), stringsAsFactors = FALSE)
  md$reference <- items$reference[match(md$item_id, items$item_id)]
  md$reference[!nzchar(ifelse(is.na(md$reference), "", md$reference))] <- NA
  md$source <- items$source[match(md$item_id, items$item_id)]
  for (s in c("sol", "llama", "qwen")) {
    md[[paste0("prior_differs_", s)]] <- toupper(as.character(items[[paste0("prior_differs_", s)]][match(md$item_id, items$item_id)]))
  }
  use <- md$has_modal & !is.na(md$reference)
  hit <- !is.na(md$modal) & md$modal == md$reference
  rate <- function(sel) c(n = sum(use & sel), hits = sum(use & sel & hit))
  hr <- list(c(by = "all", group = "all", rate(rep(TRUE, nrow(md)))))
  for (g in c("erepo", "insaid")) hr[[length(hr) + 1L]] <- c(by = "source", group = g, rate(md$source == g))
  for (s in unique(c("sol", key))) for (g in c("TRUE", "FALSE")) {
    col <- paste0("prior_differs_", s)
    hr[[length(hr) + 1L]] <- c(by = col, group = g, rate(md[[col]] %in% g))
  }
  hr <- as.data.frame(do.call(rbind, hr), stringsAsFactors = FALSE)
  hr$n <- as.integer(hr$n); hr$hits <- as.integer(hr$hits)
  hr$rate <- ifelse(hr$n > 0, hr$hits / hr$n, NA_real_)
  pd <- c("Pathogenic", "Likely pathogenic"); bn <- c("Benign", "Likely benign")
  er <- md$source == "erepo" & md$has_modal & !is.na(md$modal) & !is.na(md$reference)
  dangerous <- sum(er & ((md$modal %in% pd & md$reference %in% bn) | (md$modal %in% bn & md$reference %in% pd)))
  list(modal = md, hit_rate = hr, na_share = mean(is.na(r$value)), dangerous = dangerous,
       n_no_modal = sum(!md$has_modal), kappa_items = md[use, , drop = FALSE], runs = r)
}

# Fits a model and records an error or warnings instead of stopping.
acc_m2_with_conditions <- function(expr) {
  warns <- character()
  value <- withCallingHandlers(tryCatch(expr, error = function(e) e), warning = function(w) {
    warns <<- c(warns, conditionMessage(w))
    invokeRestart("muffleWarning")
  })
  list(value = value, warnings = warns, failed = inherits(value, "error") || length(warns) > 0L)
}

acc_m2_scores <- function(values) {
  sc <- unlist(acc_anchor("ANK-68")$value$fallback_fit$scores)
  unname(sc[values])
}

# Accessors for the evaluation result (ACC-12) --------------------------------------------------

acc_m2_ev_model <- function(ev, key) {
  if (!is.list(ev) || !is.list(ev$models) || is.null(ev$models[[key]])) {
    stop("acceptance: acmg_evaluate() result lacks models$", key, call. = FALSE)
  }
  ev$models[[key]]
}

acc_m2_hit_row <- function(hr, by, group) {
  hr <- as.data.frame(hr, stringsAsFactors = FALSE)
  row <- hr[as.character(hr$by) == by & as.character(hr$group) == group, , drop = FALSE]
  if (nrow(row) != 1L) stop("acceptance: hit_rate has no single row by = ", by, ", group = ", group, call. = FALSE)
  row
}

# Plan helpers (K-M2-5) ---------------------------------------------------------------------

acc_m2_plan_file <- function() acc_m2_require_file(file.path(acc_m2_ap1_dir(), "plan.yaml"), "inst/validation/ap1/plan.yaml")

# All atomic leaves of a nested list, as character (numbers with 15 significant
# digits) and as numbers (NA for non-numbers).
acc_m2_leaves <- function(x) {
  v <- unlist(x, use.names = FALSE)
  if (is.null(v)) return(list(text = character(), num = numeric()))
  list(text = as.character(v), num = suppressWarnings(as.numeric(v)))
}

acc_m2_has_number <- function(leaves, value, tol = 1e-12) any(abs(leaves$num - value) <= tol * max(1, abs(value)), na.rm = TRUE)

# Names of all list elements at every depth of a nested list.
acc_m2_names_deep <- function(x) {
  if (!is.list(x)) return(character())
  c(names(x)[nzchar(names(x) %||% character())], unlist(lapply(x, acc_m2_names_deep), use.names = FALSE))
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# httr2 replay of the recordings (K-M2-4, ANK-94) --------------------------------------------

acc_m2_fixture_dir <- function() file.path(acc_repo_root(), "tests", "fixtures", "api")

# Mock function as described in tests/fixtures/api/README.md: matches on the URL and
# the field `model` of the JSON body and stops when no recording matches. Captured
# requests (URL and serialised JSON body) are appended to `sink`.
acc_m2_replay <- function(sink = new.env()) {
  files <- acc_anchor("ANK-94")$value$files
  sink$requests <- list()
  function(req) {
    body_raw <- httr2::req_dry_run(req, quiet = TRUE)$body
    body_text <- if (is.raw(body_raw)) rawToChar(body_raw) else as.character(body_raw)
    body <- jsonlite::fromJSON(body_text, simplifyVector = FALSE)
    url <- httr2::req_get_url(req)
    sink$requests[[length(sink$requests) + 1L]] <- list(url = url, body = body, text = body_text)
    hit <- names(files)[vapply(files, function(f) identical(f$request_url, url) && identical(f$request_model, body[["model"]]), NA)]
    if (length(hit) != 1L) stop("no recording for ", url, " ", format(body[["model"]]), call. = FALSE)
    path <- file.path(acc_m2_fixture_dir(), hit)
    httr2::response(status_code = 200L, url = url, method = "POST",
                    headers = list("Content-Type" = "application/json"),
                    body = readBin(path, "raw", file.size(path)))
  }
}

# Production settings of the three models from the anchors (ANK-53 to ANK-55,
# ANK-61, ANK-94): base URL, model id and the extra body fields.
acc_m2_model_settings <- function() {
  pol <- acc_anchor("ANK-61")$value
  files <- acc_anchor("ANK-94")$value$files
  base <- function(f) sub("/chat/completions$", "", files[[f]]$request_url)
  routing <- function(id) {
    a <- acc_anchor(id)$value
    list(order = list(a$endpoint_tag), allow_fallbacks = FALSE, quantizations = list(a$quantization))
  }
  list(
    sol = list(file = "sol.json", base_url = base("sol.json"), model = acc_anchor("ANK-53")$value$model_id,
               temperature = NULL, extra = list(reasoning_effort = pol$sol$reasoning_effort, seed = pol$sol$seed)),
    llama = list(file = "llama.json", base_url = base("llama.json"), model = acc_anchor("ANK-54")$value$model_slug,
                 temperature = pol$llama$temperature, extra = list(seed = pol$llama$seed, provider = routing("ANK-54"))),
    qwen = list(file = "qwen.json", base_url = base("qwen.json"), model = acc_anchor("ANK-55")$value$model_slug,
                temperature = pol$qwen$temperature, extra = list(seed = pol$qwen$seed, provider = routing("ANK-55")))
  )
}

acc_m2_backend <- function(s, system = NULL) {
  args <- c(list(base_url = s$base_url, api_key = "acc-test-key", temperature = s$temperature, system = system),
            s$extra)
  do.call(llmsa::backend_openai_compatible, args)
}

# Checks one model of an acmg_evaluate() result against the mini-references
# (K-M2-6; with robustness_expected also K-M2-7).
acc_m2_check_model <- function(ev, key, main_rows, items_csv, plan, robustness_expected = NULL, label = "") {
  classes <- acc_m2_classes()
  info <- paste(label, key)
  mo <- acc_m2_ev_model(ev, key)
  exp <- acc_m2_expected_model(main_rows, items_csv, key)
  tol <- acc_m2_tol("arithmetic")$abs_tol

  # modal answers and items without a modal answer (ANK-68)
  md <- as.data.frame(mo$modal, stringsAsFactors = FALSE)
  expect_true(all(c("item_id", "modal", "has_modal") %in% names(md)), info = info)
  md <- md[match(exp$modal$item_id, md$item_id), , drop = FALSE]
  expect_identical(as.logical(md$has_modal), exp$modal$has_modal, info = info)
  expect_identical(as.character(md$modal), exp$modal$modal, info = info)
  expect_identical(as.integer(mo$n_no_modal), as.integer(exp$n_no_modal), info = info)

  # NA share of all answers and dangerous misclassifications
  expect_lte(abs(as.numeric(mo$na_share) - exp$na_share), tol)
  expect_identical(as.integer(mo$dangerous), as.integer(exp$dangerous), info = info)

  # hit rates by source and by prior_differs (sol, own key)
  for (j in seq_len(nrow(exp$hit_rate))) {
    e <- exp$hit_rate[j, ]
    g <- acc_m2_hit_row(mo$hit_rate, e$by, e$group)
    expect_identical(as.integer(g$n), e$n, info = paste(info, e$by, e$group))
    expect_identical(as.integer(g$hits), e$hits, info = paste(info, e$by, e$group))
    if (is.na(e$rate)) expect_true(is.na(g$rate), info = paste(info, e$by, e$group)) else
      expect_lte(abs(as.numeric(g$rate) - e$rate), tol)
  }

  # linearly weighted kappa of the modal answer, NA weight 0, bootstrap interval
  ki <- exp$kappa_items
  kap <- acc_m2_kappa(ki$modal, ki$reference, classes)
  k <- mo$kappa
  expect_true(all(c("estimate", "lower", "upper") %in% names(k)), info = info)
  expect_lte(abs(as.numeric(k[["estimate"]]) - kap), tol)
  a68 <- acc_anchor("ANK-68")$value$kappa_bootstrap
  bt <- acc_m2_kappa_boot(ki$modal, ki$reference, a68$replicates, a68$level, a68$seed, classes)
  mcf <- acc_m2_tol("mc_factor")$pass
  for (side in 1:2) {
    se <- acc_m2_quantile_mcse(bt$replicates, if (side == 1) bt$a else 1 - bt$a)
    got <- as.numeric(k[[if (side == 1) "lower" else "upper"]])
    expect_lte(abs(got - bt$limits[side]), mcf * sqrt(2) * se + tol)
  }

  # msa_agreement() of the model's main-plan answers against the reference
  runs_k <- exp$runs
  runs_k$reference <- items_csv$reference[match(runs_k$item_id, items_csv$item_id)]
  runs_k$reference[!nzchar(ifelse(is.na(runs_k$reference), "", runs_k$reference))] <- NA
  expect_s3_class(mo$agreement, "msa_agreement")
  expect_identical(mo$agreement$levels, classes)
  ag <- llmsa::msa_agreement(llmsa::as_msa_runs(runs_k), levels = classes, reference = "reference",
                             weights = mo$agreement$weights)
  expect_equal(mo$agreement$alpha, ag$alpha, tolerance = tol)
  expect_equal(unname(mo$agreement$kappa), unname(ag$kappa), tolerance = tol)

  # ordinal probit fit with msa_grr() or the flagged numeric fallback (ANK-68)
  ord <- acc_m2_with_conditions(llmsa::msa_fit(llmsa::as_msa_runs(runs_k), type = "ordinal", levels = classes, link = "probit"))
  expect_s3_class(mo$grr, "msa_grr")
  etol <- acc_m2_tol("engine_ordinal")$rel_tol
  if (!ord$failed) {
    expect_false(isTRUE(mo$fallback), info = info)
    expect_identical(mo$grr$type, "ordinal")
    expect_identical(mo$grr$link, "probit")
    want <- llmsa::msa_grr(ord$value)
    expect_equal(mo$grr$summary, want$summary, tolerance = etol)
    grr_pct <- want$summary[["grr_pct_study_var"]]
  } else {
    expect_true(isTRUE(mo$fallback), info = info)
    expect_identical(mo$grr$type, "numeric")
    grr_pct <- mo$grr$summary[["grr_pct_study_var"]]
  }

  # verdicts per criterion and overall (ANK-58)
  v <- mo$verdicts
  expect_identical(unname(v[["grr"]]), acc_m2_band_grr(grr_pct), info = info)
  expect_identical(unname(v[["kappa"]]), acc_m2_band_kappa(kap), info = info)
  expect_identical(unname(v[["dangerous"]]), acc_m2_band_dangerous(exp$dangerous), info = info)
  if (is.null(robustness_expected)) {
    expect_identical(unname(v[["robustness"]]), "not assessed", info = info)
    expect_true(is.na(mo$verdict) || identical(mo$verdict, "not assessed"), info = info)
  } else {
    expect_identical(unname(v[["robustness"]]), robustness_expected, info = info)
    expect_identical(mo$verdict, acc_m2_worst(c(v[["grr"]], v[["kappa"]], v[["dangerous"]], robustness_expected)), info = info)
  }

  # rendered report, outside the repository
  expect_true(is.character(mo$report) && length(mo$report) == 1L && file.exists(mo$report), info = info)
  if (is.character(mo$report) && length(mo$report) == 1L && file.exists(mo$report)) {
    expect_gt(file.size(mo$report), 0)
    rp <- normalizePath(mo$report)
    expect_false(startsWith(rp, normalizePath(acc_repo_root())) || startsWith(rp, normalizePath(acc_pkg_root())), info = rp)
  }
  invisible(exp)
}
