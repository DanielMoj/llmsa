# Helpers for the M1a acceptance tests (docs/02-statistikkern.md, K-M1a-1 to
# K-M1a-7); a setup file for the reason given in setup-acceptance.R.
#
# Reference values come from reference/anchors/ (ANK-10, ANK-13, ANK-14, ANK-16,
# ANK-TOL) or from the oracles the criteria name (stats::aov, VCA, SixSigma,
# lme4), called at test time on the same data; no package output is frozen.
# Local data: the AIAG data sheet reference/quellen/data/aiag/anova_example.csv
# (protected, git-ignored, docs/01 §6) and the NIST StRD files in
# ../quellen/daten/nist-strd-anova_2026-10-22/ next to the repository root; a
# missing or altered file fails the test, it never skips it (AGENTS.md).
# The mini-references below are written independently of the package code from
# Formelsammlung §2 (expected mean squares) and §3 (gauge R&R statistics).
# Interpretations of points on which the spec is silent are listed in
# orchestrator/handoff/M1a/CRITERIA.json under "open" (ACC-n).

acc_m1a <- new.env(parent = emptyenv())   # cache for one test run

# Anchors ------------------------------------------------------------------------

# Value of ANK-TOL entry `entry`, key `key`. A missing entry or key stops the
# test instead of turning into an exact comparison (BL-72).
acc_m1a_tol <- function(entry, key) {
  e <- acc_anchor("ANK-TOL")$value[[entry]]
  if (is.null(e)) stop("acceptance: ANK-TOL has no entry ", entry, call. = FALSE)
  v <- e[[key]]
  if (is.null(v)) stop("acceptance: ANK-TOL.", entry, " has no key ", key, call. = FALSE)
  v
}

# Nested value of an anchor, e.g. acc_m1a_value("ANK-16", "ndc", "constant").
acc_m1a_value <- function(id, ...) {
  path <- c(...)
  v <- acc_anchor(id)$value
  for (k in path) {
    v <- v[[k]]
    if (is.null(v)) {
      stop("acceptance: ", id, " has no value ", paste(path, collapse = "$"), call. = FALSE)
    }
  }
  v
}

acc_m1a_ndc_constant <- function() as.numeric(acc_m1a_value("ANK-16", "ndc", "constant"))
acc_m1a_thresholds <- function() {
  c(as.numeric(acc_m1a_value("ANK-16", "study_var", "acceptable_below")),
    as.numeric(acc_m1a_value("ANK-16", "study_var", "unacceptable_above")))
}

# Data ---------------------------------------------------------------------------

# Seeded block with the RNG of docs/01 §5; the caller's RNG state is restored.
acc_m1a_with_seed <- function(seed, expr) {
  kind <- RNGkind()
  had <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (had) old <- get(".Random.seed", envir = globalenv())
  on.exit({
    RNGkind(kind[1], kind[2], kind[3])
    if (had) assign(".Random.seed", old, envir = globalenv())
    else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) rm(".Random.seed", envir = globalenv())
  }, add = TRUE)
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  set.seed(seed)
  expr
}

# An msa_runs object from vectors in the roles of Formelsammlung §1.
acc_m1a_runs <- function(item, prompt, model, rep, value, block = 1L) {
  as_msa_runs(data.frame(block = block, item_id = as.character(item), prompt_id = as.character(prompt),
                         model_id = as.character(model), rep = as.integer(rep), value = value,
                         stringsAsFactors = FALSE))
}

# Package dataset read from data/ of the package under test.
acc_m1a_dataset <- function(name) {
  path <- file.path(acc_pkg_root(), "data", paste0(name, ".rda"))
  if (!file.exists(path)) stop("acceptance: dataset missing: ", path, call. = FALSE)
  e <- new.env(parent = emptyenv())
  load(path, envir = e)
  if (!exists(name, envir = e, inherits = FALSE)) stop("acceptance: ", path, " holds no object ", name, call. = FALSE)
  e[[name]]
}

# Factor frame for stats::aov: complete rows only, factors item, prompt, model,
# block and the response y.
acc_m1a_frame <- function(runs) {
  d <- as.data.frame(runs, stringsAsFactors = FALSE)
  d <- d[!is.na(d$value), , drop = FALSE]
  data.frame(item = factor(d$item_id), prompt = factor(d$prompt_id), model = factor(d$model_id),
             block = factor(d$block), y = as.numeric(d$value))
}

# Simulated designs of K-M1a-1: 20 items x 4 prompts x 3 models x 3 replicates,
# with or without 3 blocks, with or without two-way interactions in the
# data-generating model and in the fit. Seed 1 for every design (ACC-11).
acc_m1a_designs <- function() {
  base <- list(item = 1, prompt = 0.1, model = 0.08, residual = 0.1)
  inter <- list(item_prompt = 0.05, item_model = 0.04, prompt_model = 0.03)
  list(
    "interactions, no block" = list(blocks = 1, interactions = TRUE, vc = c(base, inter)),
    "interactions, 3 blocks" = list(blocks = 3, interactions = TRUE, vc = c(base, list(block = 0.05), inter)),
    "no interactions, no block" = list(blocks = 1, interactions = FALSE, vc = base),
    "no interactions, 3 blocks" = list(blocks = 3, interactions = FALSE, vc = c(base, list(block = 0.05)))
  )
}

acc_m1a_simulate <- function(design, seed = 1L) {
  acc_m1a_with_seed(seed, msa_simulate(20, 4, 3, 3, design$blocks, vc = design$vc, seed = seed))
}

# Random terms of the numeric model (Formelsammlung §2) for a factor frame:
# main effects of factors with more than one level and, with interactions, the
# two-way interactions among item, prompt and model.
acc_m1a_terms <- function(d, interactions) {
  main <- Filter(function(f) nlevels(d[[f]]) > 1L, c("item", "prompt", "model", "block"))
  terms <- as.list(main)
  if (interactions) {
    for (p in list(c("item", "prompt"), c("item", "model"), c("prompt", "model"))) {
      if (all(p %in% main)) terms <- c(terms, list(p))
    }
  }
  terms
}

acc_m1a_label <- function(term) paste(term, collapse = ":")

# Mini-reference: ANOVA estimators ---------------------------------------------------
#
# Balanced crossed design with N observations (Formelsammlung §2, rule of the
# expected mean squares after Cornfield & Tukey 1956): the mean square of term
# X contains the residual variance and every model term Y whose factors include
# those of X, with coefficient N / prod(levels of the factors of Y). Solving from
# the highest-order terms down gives the ANOVA estimators. Mean squares come
# from stats::aov with exactly these terms; the residual mean square pools all
# terms outside the model.
acc_m1a_anova_estimates <- function(d, terms) {
  factors <- unique(unlist(terms))
  counts <- table(d[factors])
  if (!length(counts) || any(counts != counts[[1]]) || counts[[1]] < 1) {
    stop("acceptance: the design is not balanced over ", paste(factors, collapse = ", "), call. = FALSE)
  }
  labels <- vapply(terms, acc_m1a_label, character(1))
  form <- stats::as.formula(paste("y ~", paste(labels, collapse = " + ")))
  tab <- summary(stats::aov(form, data = d))[[1]]
  ms <- stats::setNames(tab[["Mean Sq"]], trimws(rownames(tab)))
  if (!all(c(labels, "Residuals") %in% names(ms))) {
    stop("acceptance: stats::aov returned no mean square for ",
         paste(setdiff(c(labels, "Residuals"), names(ms)), collapse = ", "), call. = FALSE)
  }
  levels_n <- vapply(factors, function(f) nlevels(d[[f]]), numeric(1))
  coef <- vapply(terms, function(t) nrow(d) / prod(levels_n[t]), numeric(1))
  est <- stats::setNames(rep(NA_real_, length(terms)), labels)
  for (i in order(lengths(terms), decreasing = TRUE)) {
    above <- which(vapply(terms, function(t) length(t) > length(terms[[i]]) && all(terms[[i]] %in% t),
                          logical(1)))
    est[[i]] <- (ms[[labels[i]]] - ms[["Residuals"]] - sum(coef[above] * est[above])) / coef[[i]]
  }
  c(est, Residual = ms[["Residuals"]])
}

# Mini-reference: gauge R&R statistics --------------------------------------------------
#
# Formelsammlung §3: GRR = every source except the items (repeatability plus all
# reproducibility parts), PV = items, TV = GRR + PV; ndc with the constant of
# ANK-16, rounded down (ACC-7 for values below 1).
acc_m1a_grr_reference <- function(v) {
  if (!"item" %in% names(v)) stop("acceptance: no item component", call. = FALSE)
  item <- v[["item"]]
  grr <- sum(v[names(v) != "item"])
  total <- item + grr
  k <- acc_m1a_ndc_constant()
  list(total = total, grr = grr, item = item,
       grr_pct_study_var = 100 * sqrt(grr / total),
       grr_pct_contribution = 100 * grr / total,
       icc_items = item / total,
       ndc_raw = k * sqrt(item) / sqrt(grr),
       ndc = floor(k * sqrt(item) / sqrt(grr)))
}

# Verdict by percent study variation of GRR (ANK-16, Formelsammlung §3): below
# the first threshold acceptable, up to and including the second marginal.
acc_m1a_verdict_reference <- function(pct) {
  t <- acc_m1a_thresholds()
  if (is.na(pct)) return("undetermined")
  if (pct < t[1]) "acceptable" else if (pct <= t[2]) "marginal" else "unacceptable"
}

# Access to the package results ---------------------------------------------------------

# Variance components of an msa_fit as a named vector (source -> variance).
acc_m1a_components <- function(fit) {
  vc <- fit$vc
  if (!is.data.frame(vc) || !all(c("source", "variance") %in% names(vc))) {
    stop("acceptance: fit$vc must be a data.frame with the columns source and variance", call. = FALSE)
  }
  out <- stats::setNames(as.numeric(vc$variance), as.character(vc$source))
  if (anyDuplicated(names(out))) stop("acceptance: duplicated sources in fit$vc", call. = FALSE)
  out
}

acc_m1a_summary <- function(g, name) {
  s <- g$summary
  if (is.null(s) || !name %in% names(s)) stop("acceptance: msa_grr()$summary has no ", name, call. = FALSE)
  unname(s[[name]])
}

# Rows of msa_grr()$table by source label (trimmed, lower case; ACC-10).
acc_m1a_row_patterns <- c(
  GRR = "^total gauge r&r$", EV = "^repeatability$", AV = "^reproducibility$",
  PV = "^part-to-part", TV = "^total variation$",
  prompt = "^prompt$", model = "^model$", block = "^block",
  "prompt:model" = "^prompt:model$", "item:prompt" = "^item:prompt$", "item:model" = "^item:model$"
)

acc_m1a_grr_row <- function(g, key) {
  tab <- g$table
  if (!is.data.frame(tab) || !"source" %in% names(tab)) {
    stop("acceptance: msa_grr()$table must be a data.frame with a column source", call. = FALSE)
  }
  hit <- grep(acc_m1a_row_patterns[[key]], tolower(trimws(tab$source)))
  if (length(hit) != 1L) {
    stop("acceptance: msa_grr()$table has ", length(hit), " rows for ", key, call. = FALSE)
  }
  tab[hit, , drop = FALSE]
}

acc_m1a_cell <- function(g, key, column) {
  row <- acc_m1a_grr_row(g, key)
  if (!column %in% names(row)) stop("acceptance: msa_grr()$table has no column ", column, call. = FALSE)
  as.numeric(row[[column]])
}

# Expectations -------------------------------------------------------------------------

# Every component within `tol` times the total variance of the comparison
# calculation (docs/01 §2 Nr. 6); the sources must be the same.
acc_m1a_expect_components <- function(observed, reference, tol, total, label) {
  expect_setequal(names(observed), names(reference))
  for (s in intersect(names(reference), names(observed))) {
    dev <- abs(observed[[s]] - reference[[s]])
    expect_lte(dev, tol * total,
               label = sprintf("%s, component %s: |deviation| = %.3g sigma2_TV (observed %.10g, reference %.10g)",
                               label, s, dev / total, observed[[s]], reference[[s]]),
               expected.label = sprintf("%g sigma2_TV", tol))
  }
}

acc_m1a_expect_relative <- function(observed, reference, tol, label) {
  expect_true(length(observed) == 1L && is.finite(observed), label = sprintf("%s is finite", label))
  if (length(observed) != 1L || !is.finite(observed)) return(invisible())
  dev <- abs(observed - reference)
  expect_lte(dev, tol * abs(reference),
             label = sprintf("%s: |observed %.12g - reference %.12g| = %.3g relative", label, observed, reference,
                             dev / abs(reference)),
             expected.label = sprintf("%g relative", tol))
}

# Fit with a calling handler that keeps lme4 messages out of the test output.
acc_m1a_quiet <- function(expr) suppressMessages(expr)

# AIAG data sheet (ANK-10) -------------------------------------------------------------

acc_m1a_aiag <- function() {
  if (!is.null(acc_m1a$aiag)) return(acc_m1a$aiag)
  meta <- acc_m1a_value("ANK-10", "data_file")
  path <- file.path(acc_repo_root(), meta$path)
  if (!file.exists(path)) {
    stop("acceptance: local AIAG data sheet missing (K-M1a-2, ANK-10, docs/01 §6): ", path, call. = FALSE)
  }
  if (!identical(acc_sha256(path), meta$sha256)) {
    stop("acceptance: ", path, " is not the data sheet of ANK-10 (SHA-256 differs)", call. = FALSE)
  }
  d <- utils::read.csv(path, stringsAsFactors = FALSE)
  if (!identical(names(d), unlist(meta$columns)) || nrow(d) != meta$rows) {
    stop("acceptance: ", path, " does not have the columns and rows of ANK-10", call. = FALSE)
  }
  acc_m1a$aiag <- d
  d
}

# Item = part, prompt = appraiser, replicate = trial (docs/02 K-M1a-2).
acc_m1a_aiag_runs <- function() {
  d <- acc_m1a_aiag()
  acc_m1a_runs(item = d$part, prompt = d$appraiser, model = "gage", rep = d$trial, value = d$value)
}

# NIST StRD ANOVA (ANK-14) ---------------------------------------------------------------

acc_m1a_nist_dir <- function() {
  file.path(dirname(acc_repo_root()), "quellen", "daten", "nist-strd-anova_2026-10-22")
}

# Data lines of a NIST file as data.frame(trt, y, rep); the file must carry the
# SHA-256 of ANK-14.
acc_m1a_nist <- function(name) {
  key <- paste0("nist_", name)
  if (!is.null(acc_m1a[[key]])) return(acc_m1a[[key]])
  meta <- acc_m1a_value("ANK-14", "datasets", name)
  path <- file.path(acc_m1a_nist_dir(), meta$file)
  if (!file.exists(path)) stop("acceptance: NIST StRD file missing (K-M1a-4, ANK-14): ", path, call. = FALSE)
  if (!identical(acc_sha256(path), meta$sha256)) {
    stop("acceptance: ", path, " is not the file of ANK-14 (SHA-256 differs)", call. = FALSE)
  }
  lines <- readLines(path, warn = FALSE)
  rows <- lines[seq(meta$data_lines[[1]], meta$data_lines[[2]])]
  parts <- strsplit(trimws(rows), "[[:space:]]+")
  if (any(lengths(parts) != 2L)) stop("acceptance: unreadable data line in ", path, call. = FALSE)
  trt <- vapply(parts, `[`, character(1), 1L)
  y <- as.numeric(vapply(parts, `[`, character(1), 2L))
  if (anyNA(y) || length(y) != meta$observations) stop("acceptance: ", path, " has not ", meta$observations, " values", call. = FALSE)
  out <- list(meta = meta, data = data.frame(trt = trt, y = y, rep = stats::ave(seq_along(trt), trt, FUN = seq_along),
                                             stringsAsFactors = FALSE))
  acc_m1a[[key]] <- out
  out
}

# Item = treatment, replicate = observation (docs/02 K-M1a-4); one prompt, one
# model, one block.
acc_m1a_nist_runs <- function(name) {
  x <- acc_m1a_nist(name)$data
  acc_m1a_runs(item = x$trt, prompt = "P1", model = "M1", rep = x$rep, value = x$y)
}

# Certified reference values: residual = within mean square; item = ANOVA
# estimator from the certified mean squares, (MS_between - MS_within) / n.
acc_m1a_nist_certified <- function(name) {
  m <- acc_m1a_nist(name)$meta
  c(Residual = as.numeric(m$within$ms),
    item = (as.numeric(m$between$ms) - as.numeric(m$within$ms)) / as.numeric(m$replicates_per_cell))
}

# The same two quantities from stats::aov on the same data.
acc_m1a_nist_aov <- function(name) {
  x <- acc_m1a_nist(name)$data
  tab <- summary(stats::aov(y ~ factor(trt), data = x))[[1]]
  ms <- tab[["Mean Sq"]]
  n <- as.numeric(acc_m1a_nist(name)$meta$replicates_per_cell)
  c(Residual = ms[2], item = (ms[1] - ms[2]) / n)
}

# Log relative error (docs/02 K-M1a-4): -log10(|x - c| / |c|); Inf for x == c.
acc_m1a_lre <- function(x, c) if (isTRUE(x == c)) Inf else -log10(abs(x - c) / abs(c))

# Margin of the medium-difficulty rule, read from ANK-TOL.nist_digits (rule and
# quote must agree; ACC-9).
acc_m1a_lre_margin <- function() {
  rule <- acc_m1a_tol("nist_digits", "medium_difficulty_rule")
  quote <- acc_m1a_tol("nist_digits", "quote")
  a <- regmatches(rule, regexec("LRE\\(stats::aov\\) - ([0-9]+)", rule))[[1]]
  b <- regmatches(quote, regexec("minus ([0-9]+)", quote))[[1]]
  if (length(a) != 2L || length(b) != 2L || !identical(a[2], b[2])) {
    stop("acceptance: the margin of ANK-TOL.nist_digits is not readable", call. = FALSE)
  }
  as.numeric(a[2])
}

acc_m1a_nist_list <- function(key) as.character(unlist(acc_m1a_tol("nist_digits", key)))

# Vignette (K-M1a-7, K-M1a-4) -----------------------------------------------------------------

acc_m1a_vignette_path <- function() file.path(acc_repo_root(), "vignettes", "validation.Rmd")

acc_m1a_section_title <- "Variance components and gauge R&R (numeric)"

# Knits vignettes/validation.Rmd once per test run with knitr::knit() into a
# temporary directory: R code runs in <repo>/vignettes, REPO_ROOT points to the
# repository, figures go to the temporary directory (ACC-14). Returns the lines
# of the knitted Markdown and the files that appeared in vignettes/.
acc_m1a_knit_validation <- function() {
  if (!is.null(acc_m1a$knit)) return(acc_m1a$knit)
  rmd <- acc_m1a_vignette_path()
  if (!file.exists(rmd)) stop("acceptance: vignette missing: ", rmd, call. = FALSE)
  vig_dir <- dirname(rmd)
  before <- list.files(vig_dir, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  work <- tempfile("acc-m1a-knit-")
  dir.create(work)
  out <- file.path(work, "validation.md")
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
  after <- list.files(vig_dir, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  knit <- list(error = if (inherits(res, "error")) conditionMessage(res) else NULL,
               lines = if (file.exists(out)) readLines(out, warn = FALSE) else character(),
               new_files = setdiff(after, before))
  acc_m1a$knit <- knit
  knit
}

# Lines inside fenced code blocks (``` or ~~~) blanked, so that code output is
# never read as a header or a table.
acc_m1a_unfence <- function(lines) {
  fence <- grepl("^[[:space:]]*(```|~~~)", lines)
  inside <- (cumsum(fence) %% 2L == 1L) | fence
  lines[inside] <- ""
  lines
}

# Lines of the section with the given title, up to the next header of the same
# or a higher level, with fenced code blanked; NULL without such a header.
acc_m1a_section <- function(lines, title) {
  lines <- acc_m1a_unfence(lines)
  is_header <- grepl("^#{1,6}[[:space:]]", lines)
  level <- nchar(sub("^(#{1,6}).*$", "\\1", lines))
  text <- trimws(sub("^#{1,6}[[:space:]]+", "", lines))
  text <- trimws(sub("[[:space:]]*\\{[^}]*\\}[[:space:]]*$", "", text))
  start <- which(is_header & text == title)
  if (!length(start)) return(NULL)
  start <- start[1]
  stop_at <- which(is_header & seq_along(lines) > start & level <= level[start])
  end <- if (length(stop_at)) stop_at[1] - 1L else length(lines)
  lines[seq(start, end)]
}

acc_m1a_split_pipe <- function(line) {
  x <- trimws(line)
  x <- sub("^\\|", "", sub("\\|$", "", x))
  trimws(strsplit(x, "|", fixed = TRUE)[[1]])
}

acc_m1a_strip_html <- function(x) trimws(gsub("[[:space:]]+", " ", gsub("<[^>]+>", " ", x)))

# Tables in Markdown lines: pipe tables (header, delimiter row, body) and HTML
# tables (<table> with <th> and <td>). Each table is a data.frame of character
# cells with the header texts as names.
acc_m1a_tables <- function(lines) {
  out <- list()
  i <- 1L
  n <- length(lines)
  while (i < n) {
    if (grepl("^[[:space:]]*\\|", lines[i]) && grepl("^[[:space:]]*\\|?[[:space:]]*:?-{3,}", lines[i + 1L])) {
      header <- acc_m1a_split_pipe(lines[i])
      j <- i + 2L
      rows <- list()
      while (j <= n && grepl("^[[:space:]]*\\|", lines[j])) {
        cells <- acc_m1a_split_pipe(lines[j])
        length(cells) <- length(header)
        rows[[length(rows) + 1L]] <- cells
        j <- j + 1L
      }
      body <- if (length(rows)) do.call(rbind, rows) else matrix(character(), 0, length(header))
      tab <- as.data.frame(body, stringsAsFactors = FALSE)
      names(tab) <- header
      out[[length(out) + 1L]] <- tab
      i <- j
    } else {
      i <- i + 1L
    }
  }
  html <- paste(lines, collapse = "\n")
  for (t in regmatches(html, gregexpr("(?s)<table.*?</table>", html, perl = TRUE))[[1]]) {
    trs <- regmatches(t, gregexpr("(?s)<tr.*?</tr>", t, perl = TRUE))[[1]]
    if (!length(trs)) next
    header <- acc_m1a_strip_html(regmatches(trs[1], gregexpr("(?s)<th.*?</th>", trs[1], perl = TRUE))[[1]])
    if (!length(header)) next
    rows <- lapply(trs[-1], function(tr) {
      cells <- acc_m1a_strip_html(regmatches(tr, gregexpr("(?s)<td.*?</td>", tr, perl = TRUE))[[1]])
      length(cells) <- length(header)
      cells
    })
    body <- if (length(rows)) do.call(rbind, rows) else matrix(character(), 0, length(header))
    tab <- as.data.frame(body, stringsAsFactors = FALSE)
    names(tab) <- header
    out[[length(out) + 1L]] <- tab
  }
  out
}

# Column of a table whose header starts with `word` (case-insensitive); NULL if
# there is not exactly one.
acc_m1a_column <- function(tab, word) {
  hit <- which(startsWith(tolower(trimws(names(tab))), word))
  if (length(hit) != 1L) return(NULL)
  tab[[hit]]
}

acc_m1a_required_columns <- c("anchor", "source", "expected", "observed", "tolerance", "result")

acc_m1a_reference_tables <- function(tables) {
  Filter(function(t) all(vapply(acc_m1a_required_columns, function(w) !is.null(acc_m1a_column(t, w)), logical(1))),
         tables)
}

acc_m1a_anchor_ids <- function(x) {
  unique(unlist(regmatches(x, gregexpr("ANK-TOL\\.[a-z_]+|ANK-[0-9]+", x))))
}

# Numbers in a cell (decimal or scientific notation, Inf), with the number of
# decimals as written.
acc_m1a_numbers <- function(x) {
  tok <- unlist(regmatches(x, gregexpr("[-+]?(?:[0-9]+\\.?[0-9]*|\\.[0-9]+)(?:[eE][-+]?[0-9]+)?|[-+]?Inf", x, perl = TRUE)))
  tok
}

# TRUE if the written number `tok` shows `value` up to half a unit of its last
# written digit (or exactly).
acc_m1a_shows <- function(tok, value) {
  x <- suppressWarnings(as.numeric(tok))
  if (is.na(x)) return(FALSE)
  if (is.infinite(x) || is.infinite(value)) return(identical(x, value))
  mant <- sub("[eE].*$", "", tok)
  expo <- if (grepl("[eE]", tok)) as.numeric(sub("^.*[eE]", "", tok)) else 0
  dec <- if (grepl("\\.", mant)) nchar(sub("^[^.]*\\.", "", mant)) else 0
  half <- 0.5 * 10^(expo - dec)
  abs(x - value) <= half * (1 + 1e-9) + 1e-15 * abs(value)
}

# Numeric leaves of a JSON value (lists of lists), without integer counters.
acc_m1a_leaves <- function(v) {
  if (is.list(v)) return(unlist(lapply(v, acc_m1a_leaves), use.names = FALSE))
  if (is.numeric(v)) return(as.numeric(v))
  numeric()
}

# Numeric literals with a decimal point or an exponent in Rmd source lines
# outside the YAML header, with their significant digits.
acc_m1a_rmd_literals <- function(lines) {
  if (length(lines) && trimws(lines[1]) == "---") {
    close <- which(trimws(lines) == "---")
    if (length(close) >= 2L) lines <- lines[-seq_len(close[2])]
  }
  text <- paste(lines, collapse = "\n")
  pat <- "(?<![A-Za-z0-9_.])(?:[0-9]+\\.[0-9]+|\\.[0-9]+|[0-9]+(?:\\.[0-9]+)?[eE][-+]?[0-9]+)(?![A-Za-z0-9_.])"
  tok <- regmatches(text, gregexpr(pat, text, perl = TRUE))[[1]]
  mant <- sub("[eE].*$", "", tok)
  digits <- gsub("[^0-9]", "", mant)
  digits <- sub("^0+", "", digits)
  data.frame(token = tok, value = as.numeric(tok), significant = nchar(digits),
             scientific = grepl("[eE]", tok), stringsAsFactors = FALSE)
}
