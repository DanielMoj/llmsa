#' Internal AP1 application pipeline
#'
#' Frozen configuration, local item import, prompt construction and evaluation
#' for the operator-approved AP1 study. These functions are internal: they do
#' not extend the domain-independent public API.
#'
#' @param path Optional YAML file; the default is the shipped AP1 plan.
#' @param insaid_path Optional local INSAID TSV. Its reference classes and
#'   protein notation are joined in memory, never saved by this importer.
#' @param pilot Read the disjoint pilot items instead of the main items.
#' @param robustness Return the twelve PB templates and their coded factors.
#' @param runs Main and optional PB responses as an `msa_runs`, with item
#'   columns `reference`, `source` and `prior_differs_sol/llama/qwen`.
#' @param plan A list read by `acmg_plan()`.
#' @return `acmg_plan()` returns a validated list. `acmg_items()` returns a
#'   data.frame. `acmg_prompts()` returns named templates, or a PB data.frame.
#'   `acmg_evaluate()` returns `models` keyed by model and a joint `msa_fit`.
#'   Each model includes GRR, fit diagnostics, modal responses, item-bootstrap
#'   kappa, agreement, stratified rates, robustness with backend errors per PB
#'   run, completeness, provenance, criteria bands and an external rendered
#'   report. Incomplete results are not assessed.
#' @name acmg
#' @keywords internal
NULL

acmg_require <- function(packages) {
  for (p in packages) if (!requireNamespace(p, quietly = TRUE)) {
    stop("AP1 requires package `", p, "` from the frozen dependency environment.", call. = FALSE)
  }
}

acmg_resource <- function(...) {
  p <- system.file(..., package = "llmsa")
  if (!nzchar(p) || !file.exists(p)) stop("AP1 package resource missing: ", paste(c(...), collapse = "/"), call. = FALSE)
  p
}

#' @rdname acmg
acmg_plan <- function(path = NULL) {
  acmg_require("yaml")
  if (is.null(path)) path <- acmg_resource("validation", "ap1", "plan.yaml")
  if (!file.exists(path)) stop("AP1 plan file missing: ", path, call. = FALSE)
  p <- yaml::read_yaml(path, eval.expr = FALSE)
  acmg_validate_plan(p)
  p
}

acmg_scalar <- function(x, type = "character", empty = FALSE) {
  if (length(x) != 1L || is.na(x)) return(FALSE)
  if (type == "character") is.character(x) && (empty || nzchar(x)) else
    is.numeric(x) && is.finite(x)
}

acmg_validate_plan <- function(p) {
  fail <- function(field) stop("Invalid AP1 plan field: ", field, call. = FALSE)
  need <- c("cou", "risk", "acceptance", "models", "design", "pilot", "robustness",
            "evaluation", "budget", "cutoff_date", "classes", "aliases", "templates", "tokens", "reporting")
  if (!is.list(p) || !all(need %in% names(p))) fail(paste(setdiff(need, names(p)), collapse = ", "))
  if (!acmg_scalar(p$cou)) fail("cou")
  if (!p$risk$tier %in% c("low", "medium", "high")) fail("risk.tier")
  classes <- unlist(p$classes, use.names = FALSE)
  if (!is.character(classes) || length(classes) < 2L || anyNA(classes) ||
      any(!nzchar(classes)) || anyDuplicated(classes)) fail("classes")
  tpl <- unlist(p$templates)
  if (!is.character(tpl) || !identical(names(tpl), c("concise", "role", "json")) || anyNA(tpl)) fail("templates")
  for (s in tpl) {
    placeholders <- regmatches(s, gregexpr("\\{[A-Za-z_][A-Za-z0-9_]*\\}", s))[[1L]]
    if (!setequal(placeholders, c("{gene}", "{hgvs}"))) fail("templates placeholders")
  }
  if (!is.list(p$aliases) || !setequal(names(p$aliases), classes)) fail("aliases")
  model_fields <- c("key", "id", "endpoint", "provider_order", "quantizations", "reasoning",
                    "temperature", "seed", "timeout_s", "knowledge_cutoff", "price_in", "price_out")
  if (!is.list(p$models) || !length(p$models)) fail("models")
  for (m in p$models) {
    if (!is.list(m) || !all(model_fields %in% names(m))) fail("models: required fields")
    for (nm in c("key", "id", "endpoint", "knowledge_cutoff")) if (!acmg_scalar(m[[nm]])) fail(paste("models", nm))
    for (nm in c("seed", "price_in", "price_out")) {
      if (!acmg_scalar(m[[nm]], "numeric") || m[[nm]] < 0) fail(paste("models", nm))
    }
    if (m$seed != floor(m$seed) || m$seed > .Machine$integer.max) fail("models.seed")
    if (!acmg_scalar(m$timeout_s, "numeric") || m$timeout_s <= 0) fail("models.timeout_s")
    if (!is.null(m$temperature) && !acmg_scalar(m$temperature, "numeric")) fail("models.temperature")
    if (!is.null(m$reasoning) && !acmg_scalar(m$reasoning)) fail("models.reasoning")
    route <- unlist(m$provider_order, use.names = FALSE)
    quant <- unlist(m$quantizations, use.names = FALSE)
    if (length(route) != length(quant) || anyNA(c(route, quant)) || any(!nzchar(c(route, quant)))) fail("models routing")
    if (length(route) && !acmg_scalar(m$provider_name)) fail("models.provider_name")
    if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", m$knowledge_cutoff) ||
        is.na(as.Date(m$knowledge_cutoff, format = "%Y-%m-%d"))) fail("models.knowledge_cutoff")
  }
  keys <- vapply(p$models, `[[`, "", "key")
  if (anyDuplicated(keys) || !setequal(keys, c("sol", "llama", "qwen"))) fail("models.key")
  for (nm in c("items", "prompts", "models", "replicates", "blocks", "seed")) {
    v <- p$design[[nm]]
    if (!acmg_scalar(v, "numeric") || v < 1 || v != floor(v)) fail(paste0("design.", nm))
  }
  if (p$design$seed > .Machine$integer.max || !identical(p$design$order, "replicate_random")) fail("design seed/order")
  if (p$design$models != length(keys) || p$design$prompts != length(tpl)) fail("design model/prompt counts")
  for (nm in c("pilot_items", "replicates", "templates", "calls_per_model", "parser_hits_min", "parser_hits_of")) {
    v <- p$pilot[[nm]]
    if (!acmg_scalar(v, "numeric") || v < 1 || v != floor(v)) fail(paste0("pilot.", nm))
  }
  if (p$pilot$calls_per_model != p$pilot$pilot_items * p$pilot$templates * p$pilot$replicates ||
      p$pilot$parser_hits_of != p$pilot$calls_per_model || p$pilot$parser_hits_min > p$pilot$parser_hits_of ||
      p$pilot$templates != length(tpl)) fail("pilot counts")
  for (v in c(p$pilot$cost_quantile, p$pilot$error_share_trigger, p$evaluation$kappa_bootstrap$level)) {
    if (!acmg_scalar(v, "numeric") || v <= 0 || v >= 1) fail("probability")
  }
  if (p$evaluation$modal_calls_per_item_and_model !=
      p$design$prompts * p$design$replicates * p$design$blocks) fail("evaluation.modal_calls_per_item_and_model")
  bt <- p$evaluation$kappa_bootstrap
  for (nm in c("replicates", "seed", "quantile_type")) {
    if (!acmg_scalar(bt[[nm]], "numeric") || bt[[nm]] < 1 || bt[[nm]] != floor(bt[[nm]])) fail(paste0("evaluation.kappa_bootstrap.", nm))
  }
  if (bt$seed > .Machine$integer.max || !bt$quantile_type %in% seq_len(9)) fail("evaluation.kappa_bootstrap")
  scores <- unlist(p$evaluation$fallback_fit$scores)
  if (!setequal(names(scores), classes) || !is.numeric(scores) || anyNA(scores)) fail("evaluation.fallback_fit.scores")
  if (!identical(names(p$robustness$factors), paste0("F", seq_len(8))) ||
      p$robustness$runs != length(p$robustness$pb_design$prompt_ids)) fail("robustness")
  for (v in c(p$budget$budget_eur, p$tokens$input, p$tokens$output_max, p$robustness$response$correction)) {
    if (!acmg_scalar(v, "numeric") || v <= 0) fail("budget/tokens/robustness correction")
  }
  a <- p$acceptance
  if (!is.list(a) || !all(c("grr_pct_study_var", "kappa_linear_modal", "dangerous_errors", "robustness", "bands_in_order") %in% names(a))) fail("acceptance")
  thresholds <- c(a$grr_pct_study_var$acceptable_below, a$grr_pct_study_var$marginal_below,
                  a$kappa_linear_modal$acceptable_min, a$kappa_linear_modal$marginal_min,
                  a$dangerous_errors$acceptable_max, a$dangerous_errors$marginal_max,
                  a$robustness$delta_p_limit, a$robustness$sme_alpha)
  if (length(thresholds) != 8L || !is.numeric(thresholds) || any(!is.finite(thresholds)) ||
      a$grr_pct_study_var$acceptable_below >= a$grr_pct_study_var$marginal_below ||
      a$kappa_linear_modal$acceptable_min <= a$kappa_linear_modal$marginal_min ||
      a$dangerous_errors$acceptable_max >= a$dangerous_errors$marginal_max ||
      a$robustness$delta_p_limit <= 0 || a$robustness$delta_p_limit >= 1 ||
      a$robustness$sme_alpha <= 0 || a$robustness$sme_alpha >= 1 ||
      !identical(unlist(a$bands_in_order, use.names = FALSE), c("acceptable", "marginal", "unacceptable"))) fail("acceptance thresholds")
  invisible(p)
}

acmg_models <- function(plan) stats::setNames(plan$models, vapply(plan$models, `[[`, "", "key"))
acmg_classes <- function(plan) unlist(plan$classes, use.names = FALSE)
acmg_parser <- function(plan) {
  aliases <- unlist(lapply(names(plan$aliases), function(cl) {
    stats::setNames(rep(cl, length(plan$aliases[[cl]])), unlist(plan$aliases[[cl]]))
  }))
  parse_choice(acmg_classes(plan), aliases, whole_word = TRUE)
}

# Restore both RNG configuration and state, even if there was no prior state.
acmg_seeded <- function(seed, expr) {
  old <- .Random.seed_get()
  kind <- RNGkind()
  on.exit({ do.call(RNGkind, as.list(kind)); .Random.seed_set(old) }, add = TRUE)
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  set.seed(seed)
  force(expr)
}

acmg_columns <- function() {
  c("item_id", "source", "gene", "transcript", "hgvs", "protein", "reference", "panel",
    paste0("prior_clinvar_class_", c("sol", "llama", "qwen")),
    paste0("prior_date_", c("sol", "llama", "qwen")),
    paste0("prior_differs_", c("sol", "llama", "qwen")))
}

acmg_hash <- function(path) {
  acmg_require("digest")
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

acmg_insaid_hash <- function() {
  provenance <- readLines(acmg_resource("extdata", "items_ap1_2026-10-24", "QUELLE.txt"), warn = FALSE)
  line <- provenance[startsWith(provenance, "INSAID SHA-256: ")]
  hash <- sub("^INSAID SHA-256: ", "", line)
  if (length(hash) != 1L || !grepl("^[0-9a-f]{64}$", hash)) stop("AP1 INSAID SHA-256 missing from QUELLE.txt.", call. = FALSE)
  hash
}

acmg_check_insaid <- function(path, expected_hash) {
  if (is.null(path) || length(path) != 1L || !file.exists(path)) {
    stop("AP1 INSAID file missing; supply --insaid-path for API robustness.", call. = FALSE)
  }
  if (!identical(acmg_hash(path), expected_hash)) stop("AP1 INSAID SHA-256 mismatch.", call. = FALSE)
  invisible(path)
}

acmg_import_insaid <- function(path, items, expected_hash, parser) {
  acmg_check_insaid(path, expected_hash)
  d <- utils::read.delim(path, quote = "", comment.char = "#", check.names = FALSE,
                         colClasses = "character", na.strings = character(), fileEncoding = "UTF-8")
  stop_if_missing_cols(d, c("gene", "cdna", "protein", "classification", "status"), "INSAID TSV")
  id <- paste(d$gene, d$cdna, sep = ":")
  if (anyDuplicated(id)) stop("INSAID TSV has duplicate gene/cDNA keys.", call. = FALSE)
  take <- which(items$source == "insaid")
  hit <- match(paste(items$gene[take], sub("^[^:]+:", "", items$hgvs[take]), sep = ":"), id)
  if (anyNA(hit) || any(d$status[hit] != "Validated")) stop("INSAID TSV does not match the selected Validated items.", call. = FALSE)
  labels <- vapply(d$classification[hit], parser, "", USE.NAMES = FALSE)
  if (anyNA(labels)) stop("INSAID TSV contains an unreadable classification.", call. = FALSE)
  items$reference[take] <- labels
  items$protein[take] <- sub("^p\\.\\((.*)\\)$", "p.\\1", d$protein[hit])
  attr(items, "insaid_loaded") <- length(take) > 0L
  items
}

#' @rdname acmg
acmg_items <- function(insaid_path = NULL, pilot = FALSE) {
  if (!is.logical(pilot) || length(pilot) != 1L || is.na(pilot)) stop("`pilot` must be TRUE or FALSE.", call. = FALSE)
  p <- acmg_resource("extdata", "items_ap1_2026-10-24", if (pilot) "pilot.csv" else "items.csv")
  d <- utils::read.csv(p, colClasses = "character", na.strings = "", check.names = FALSE, fileEncoding = "UTF-8")
  if (!identical(names(d), acmg_columns()) || anyNA(d$item_id) || anyDuplicated(d$item_id)) {
    stop("Invalid frozen AP1 item schema or duplicate item_id.", call. = FALSE)
  }
  for (s in c("sol", "llama", "qwen")) {
    field <- paste0("prior_differs_", s)
    if (any(!is.na(d[[field]]) & !d[[field]] %in% c("TRUE", "FALSE"))) stop("Invalid AP1 prior_differs field.", call. = FALSE)
    d[[field]] <- as.logical(d[[field]])
  }
  # Text fields used for prompt rendering stay empty rather than NA.
  for (col in c("protein", "panel")) d[[col]][is.na(d[[col]])] <- ""
  attr(d, "insaid_loaded") <- FALSE
  if (!is.null(insaid_path) && file.exists(insaid_path)) {
    d <- acmg_import_insaid(insaid_path, d, acmg_insaid_hash(), acmg_parser(acmg_plan()))
  }
  d
}

acmg_pb <- function(plan) {
  pb_design(length(plan$robustness$factors), n_runs = plan$robustness$runs, seed = plan$design$seed)
}

acmg_prompt_table <- function(plan) {
  design <- acmg_pb(plan)
  d <- as.data.frame(attr(design, "coded"))
  d$prompt_id <- unlist(plan$robustness$pb_design$prompt_ids, use.names = FALSE)
  b <- plan$robustness$blocks
  comp <- plan$robustness$composition
  d$template <- vapply(seq_len(nrow(d)), function(i) {
    lang <- if (d$F8[i] > 0) "de" else "en"
    task <- b[[if (d$F3[i] > 0) "task_typo" else "task"]][[lang]]
    format <- b[[if (d$F7[i] > 0) "format_abbrev" else "format_full"]][[lang]]
    sentence <- if (d$F4[i] > 0) c(format, task) else c(task, format)
    text <- paste(sentence, collapse = comp$sentence_separator)
    if (d$F5[i] > 0) text <- paste0(b$context[[lang]], comp$context_separator, text)
    text
  }, "")
  d$system <- ifelse(d$F6 > 0, b$system$en, "")
  d[, c("prompt_id", names(plan$robustness$factors), "template", "system")]
}

#' @rdname acmg
acmg_prompts <- function(robustness = FALSE) {
  if (!is.logical(robustness) || length(robustness) != 1L || is.na(robustness)) stop("`robustness` must be TRUE or FALSE.", call. = FALSE)
  p <- acmg_plan()
  if (robustness) acmg_prompt_table(p) else unlist(p$templates)
}

acmg_variant_text <- function(items, factors, plan) {
  text <- if (factors$F1 > 0) sub("^[^:]+:", "", items$hgvs) else items$hgvs
  has <- !is.na(items$protein) & nzchar(items$protein)
  if (factors$F2 > 0) text[has] <- paste0(text[has], sprintf(plan$robustness$composition$protein_suffix, items$protein[has]))
  text
}

acmg_design <- function(items, plan, part) {
  models <- vapply(acmg_models(plan), `[[`, "", "id")
  items$text <- items$hgvs
  acmg_seeded(plan$design$seed, {
    if (part == "robustness") {
      p <- acmg_prompt_table(plan)
      chunks <- lapply(seq_len(nrow(p)), function(i) {
        variant <- items
        variant$hgvs <- acmg_variant_text(items, p[i, ], plan)
        d <- msa_design(variant, stats::setNames(p$template[i], p$prompt_id[i]), models,
                        reps = plan$robustness$replicates, blocks = 1, order = "fixed")
        d$system <- p$system[i]
        d
      })
      d <- do.call(rbind, chunks)
      attr(d, "items") <- items
      d <- d[sample.int(nrow(d)), , drop = FALSE]
      d$position <- seq_len(nrow(d))
    } else {
      d <- msa_design(items, unlist(plan$templates), models,
                      reps = if (part == "pilot") plan$pilot$replicates else plan$design$replicates,
                      blocks = if (part == "pilot") 1 else plan$design$blocks, order = "fixed")
      # Draw the complete plan before selecting a block, so resume has the same order.
      index <- unlist(lapply(unique(d$block), function(b) {
        unlist(lapply(sort(unique(d$rep)), function(r) {
          at <- which(d$block == b & d$rep == r)
          at[sample.int(length(at))]
        }), use.names = FALSE)
      }), use.names = FALSE)
      d <- d[index, , drop = FALSE]
      d$position <- as.integer(stats::ave(seq_len(nrow(d)), d$block, FUN = seq_along))
    }
    rownames(d) <- NULL
    d
  })
}

# This is an explicitly synthetic latent simulation. It never reads reference
# classes, prior flags or protected TSV data. Seed and scale belong to the mock.
acmg_mock_backend <- function(items, plan) {
  classes <- acmg_classes(plan)
  truth <- acmg_seeded(plan$design$seed, stats::setNames(stats::rnorm(nrow(items)), items$item_id))
  backend <- backend_mock(truth, levels = classes,
                          thresholds = stats::qnorm(seq_len(length(classes) - 1L) / length(classes)),
                          sd_prompt = 0.2, sd_model = 0.2, sd_rep = 0.3,
                          p_fail = 0.02, seed = plan$design$seed)
  field_parser <- acmg_parser(plan)
  function(prompt, model, row) {
    result <- backend(prompt, model, row)
    if (row$prompt_id == "json") {
      label <- field_parser(result$text)
      if (!is.na(label)) result$text <- as.character(jsonlite::toJSON(list(classification = label), auto_unbox = TRUE))
    }
    result
  }
}

acmg_api_backends <- function(plan) {
  acmg_validate_plan(plan)
  acmg_require("httr2")
  settings <- lapply(acmg_models(plan), function(m) {
    ep <- httr2::url_parse(m$endpoint)
    host <- tolower(ep$hostname %||% "")
    if (!identical(ep$scheme, "https") || !host %in% c("api.openai.com", "openrouter.ai") ||
        nzchar(ep$username %||% "") || nzchar(ep$password %||% "") ||
        length(ep$query) || nzchar(ep$fragment %||% "") || !is.null(ep$port)) {
      stop("Unsupported AP1 HTTPS endpoint.", call. = FALSE)
    }
    route <- unlist(m$provider_order, use.names = FALSE)
    quant <- unlist(m$quantizations, use.names = FALSE)
    if ((host == "openrouter.ai" && (!length(route) || !length(quant))) ||
        (host == "api.openai.com" && (length(route) || length(quant)))) {
      stop("Inconsistent AP1 provider routing for endpoint.", call. = FALSE)
    }
    variable <- if (host == "api.openai.com") "OPENAI_API_KEY" else "OPENROUTER_API_KEY"
    key <- Sys.getenv(variable, unset = "")
    if (!nzchar(trimws(key))) stop("AP1 requires environment variable ", variable, ".", call. = FALSE)
    args <- list(base_url = sub("/chat/completions$", "", sub("/+$", "", m$endpoint)),
                 api_key = key, temperature = m$temperature, timeout = m$timeout_s, seed = m$seed)
    if (!is.null(m$reasoning)) args$reasoning_effort <- m$reasoning
    if (length(route)) args$provider <- list(order = as.list(route), allow_fallbacks = FALSE, quantizations = as.list(quant))
    args
  })
  # Validate all hosts, routes and credentials before constructing any backend.
  lapply(settings, function(args) do.call(backend_openai_compatible, args))
}

# Pure source-data helpers are kept here so small synthetic cases can be tested
# in the installed package. Only data-raw/make_items_ap1.R reads the raw corpus.
acmg_erepo_pool <- function(x, cutoff, parser) {
  stop_if_missing_cols(x, c("#Variation", "Retracted", "Approval Date", "Published Date",
                           "HGNC Gene Symbol", "Assertion", "Expert Panel", "ClinVar Variation Id"), "ERepo")
  pattern <- "^(NM_[0-9]+\\.[0-9]+)(?:\\(([^()]+)\\))?:(c\\.[^[:space:]]+?)(?: \\((p\\.[^()]*)\\))?$"
  parts <- regmatches(x[["#Variation"]], regexec(pattern, x[["#Variation"]], perl = TRUE))
  good <- lengths(parts) == 5L
  column <- function(k) vapply(parts, function(p) if (length(p) == 5L) p[k] else "", "")
  tx <- column(2); gene <- column(3); cdna <- column(4); protein <- column(5)
  good <- good & (nzchar(gene) | !nzchar(protein))
  dates <- lapply(x[c("Approval Date", "Published Date")], as.Date, format = "%Y-%m-%d")
  keep <- good & x$Retracted == "false" & dates[[1]] > as.Date(cutoff) & dates[[2]] > as.Date(cutoff)
  if (anyNA(keep)) stop("ERepo has missing or invalid eligibility dates.", call. = FALSE)
  out <- data.frame(gene = x[["HGNC Gene Symbol"]][keep], transcript = tx[keep],
                    hgvs = paste0(tx[keep], ":", cdna[keep]), protein = protein[keep],
                    reference = vapply(x$Assertion[keep], parser, "", USE.NAMES = FALSE),
                    panel = x[["Expert Panel"]][keep], clinvar_id = x[["ClinVar Variation Id"]][keep],
                    stringsAsFactors = FALSE)
  if (anyNA(out$reference) || anyDuplicated(out$hgvs)) stop("ERepo pool has invalid classes or duplicate HGVS.", call. = FALSE)
  out[order(out$hgvs, method = "radix"), , drop = FALSE]
}

acmg_check_pool <- function(pool, expected, parser) {
  sizes <- c(classifications = nrow(pool), genes = length(unique(pool$gene)), panels = length(unique(pool$panel)))
  want <- unlist(expected[names(sizes)], use.names = FALSE)
  counts <- table(pool$reference)
  labels <- vapply(names(expected$per_class), parser, "")
  if (!identical(as.numeric(sizes), as.numeric(want)) ||
      !identical(as.numeric(counts[labels]), as.numeric(unlist(expected$per_class)))) {
    stop("ERepo pool differs from ANK-51 (counts by classification, gene, panel or class).", call. = FALSE)
  }
  invisible(pool)
}

acmg_round_robin <- function(pool, group, count) {
  # Canonical group and candidate order precedes every seeded draw (ADR-005).
  groups <- sort(unique(pool[[group]]), method = "radix")
  candidates <- lapply(groups, function(g) which(pool[[group]] == g))
  sizes <- lengths(candidates)
  if (sum(sizes) < count) stop("Insufficient candidates for AP1 round-robin selection.", call. = FALSE)
  priority <- order(-sizes, stats::runif(length(groups)), method = "radix")
  candidates <- lapply(candidates[priority], function(i) i[sample.int(length(i))])
  chosen <- integer()
  depth <- 1L
  while (length(chosen) < count) {
    for (indices in candidates) {
      if (length(indices) >= depth) chosen <- c(chosen, indices[depth])
      if (length(chosen) == count) break
    }
    depth <- depth + 1L
  }
  pool[chosen, , drop = FALSE]
}

acmg_clinvar_dates <- function(x) {
  old <- Sys.getlocale("LC_TIME")
  on.exit(Sys.setlocale("LC_TIME", old), add = TRUE)
  Sys.setlocale("LC_TIME", "C")
  out <- as.Date(x, format = "%b %d, %Y")
  if (any(is.na(out) & !is.na(x) & !x %in% c("", "-"))) stop("Invalid ClinVar DateLastEvaluated.", call. = FALSE)
  out
}

acmg_prior <- function(rows, cutoff, panel, reference, classes, expert_status) {
  stop_if_missing_cols(rows, c("date", "ClinicalSignificance", "ReviewStatus", "Submitter"), "ClinVar rows")
  norm <- function(s) tolower(gsub("[[:space:]]+", " ", trimws(s)))
  stem <- norm(sub("[[:space:]]+vcep[[:space:]]*$", "", panel, ignore.case = TRUE))
  expert <- rows$ReviewStatus == expert_status
  own <- expert & grepl(stem, norm(rows$Submitter), fixed = TRUE)
  fallback <- !any(own)
  if (fallback) own <- expert
  label <- classes[match(tolower(rows$ClinicalSignificance), tolower(classes))]
  use <- !is.na(rows$date) & rows$date < as.Date(cutoff) & !is.na(label) & !own
  if (!any(use)) return(list(class = "none", date = "", differs = FALSE, panel_fallback = fallback))
  recent <- max(rows$date[use])
  frequency <- table(label[use & rows$date == recent])
  top <- names(frequency)[frequency == max(frequency)]
  winner <- if (length(top) == 1L) top else "conflicting"
  list(class = winner, date = format(recent, "%Y-%m-%d"),
       differs = tolower(winner) != tolower(reference), panel_fallback = fallback)
}

acmg_meta <- function(runs) {
  acmg_require("jsonlite")
  if (!"meta" %in% names(runs)) return(rep(list(list()), nrow(runs)))
  lapply(runs$meta, function(text) {
    if (is.na(text) || !nzchar(text)) return(list())
    value <- tryCatch(jsonlite::fromJSON(text, simplifyVector = FALSE), error = function(e) {
      stop("AP1 response meta is not valid JSON.", call. = FALSE)
    })
    if (is.null(value)) return(list())
    if (!is.list(value)) stop("AP1 response meta must be a JSON object.", call. = FALSE)
    value
  })
}

acmg_meta_kind <- function(meta) vapply(meta, function(m) {
  if (isTRUE(m[["mock"]])) "mock" else if (acmg_scalar(m[["id"]]) && acmg_scalar(m[["model_snapshot"]])) "api" else "unknown"
}, "")

acmg_meta_text <- function(meta, field) vapply(meta, function(m) {
  value <- m[[field]]
  if (acmg_scalar(value) && nzchar(trimws(value))) value else NA_character_
}, "")

acmg_provenance <- function(runs) {
  row_kind <- acmg_meta_kind(acmg_meta(runs))
  successful <- row_kind[!acmg_errors(runs)]
  known <- intersect(unique(successful), c("mock", "api"))
  marker <- attr(runs, "ap1_mode", exact = TRUE)
  if (!is.null(marker) && (!acmg_scalar(marker) || !marker %in% c("mock", "api"))) stop("Invalid AP1 store provenance.", call. = FALSE)
  # Explicit metadata may not contradict a persisted mode, even on a failed
  # row. Only successful rows establish an otherwise unknown provenance.
  recorded <- intersect(unique(row_kind), c("mock", "api"))
  if (length(known) > 1L || (!is.null(marker) && any(recorded != marker))) {
    stop("AP1 mixed mock/API provenance is not permitted.", call. = FALSE)
  }
  if ("mock" %in% known || identical(marker, "mock")) return("synthetic")
  if (!any(successful == "unknown") && ("api" %in% known || identical(marker, "api"))) return("api")
  "unverified"
}

acmg_errors <- function(runs) {
  if (!"error" %in% names(runs)) return(rep(FALSE, nrow(runs)))
  !is.na(runs$error) & nzchar(runs$error)
}

# A number alone is not an HTTP status. httr2 uses "HTTP 400 Bad Request";
# also accept "HTTP status 400" and a protocol version before the status.
acmg_http_4xx <- function(error) {
  !is.na(error) & grepl("\\bHTTP(?:/[0-9.]+)?[[:space:]]+(?:status(?:[[:space:]]+code)?[[:space:]:=]*)?4[0-9]{2}\\b",
                       error, ignore.case = TRUE, perl = TRUE)
}

acmg_pilot <- function(runs, plan, items = acmg_items(pilot = TRUE)) {
  keys <- names(acmg_models(plan))
  keep <- runs$item_id %in% items$item_id & runs$prompt_id %in% names(plan$templates)
  data <- runs[keep, , drop = FALSE]
  meta <- acmg_meta(data)
  kind <- acmg_meta_kind(meta)
  complete <- stats::setNames(rep(FALSE, length(keys)), keys)
  costs <- stats::setNames(rep(NA_real_, length(keys)), keys)
  projected_calls <- plan$design$items * (plan$design$prompts * plan$design$replicates * plan$design$blocks +
                                          plan$robustness$runs * plan$robustness$replicates)
  result <- list(); summary <- list(); tokens <- list()
  for (key in keys) {
    idx <- which(data$model_id == key)
    r <- data[idx, , drop = FALSE]; m <- meta[idx]; k <- kind[idx]
    model <- acmg_models(plan)[[key]]
    expected <- expand.grid(block = 1L, item_id = items$item_id, prompt_id = names(plan$templates),
                            model_id = key, rep = seq_len(plan$pilot$replicates), stringsAsFactors = FALSE)
    actual_keys <- run_key(r)
    complete[key] <- nrow(r) == plan$pilot$calls_per_model &&
      !anyDuplicated(actual_keys) && setequal(actual_keys, run_key(expected))
    success <- !acmg_errors(r)
    errors <- if ("error" %in% names(r)) r$error else rep(NA_character_, nrow(r))
    parameter_ok <- !any(acmg_http_4xx(errors))
    responses <- m[success]
    from_api <- length(responses) > 0L && all(k[success] == "api")
    if (length(unlist(model$provider_order))) {
      providers <- acmg_meta_text(responses, "provider")
      provider_ok <- from_api && !anyNA(providers) && all(providers == model$provider_name)
      missing <- which(is.na(providers))
      reason <- if (length(missing)) {
        ids <- acmg_meta_text(responses[missing], "id")
        ids[is.na(ids)] <- "unavailable"
        paste("missing provider; operator sample GET /api/v1/generation using meta$id:",
              paste(ids, collapse = ", "), "; plan changes require an ADR")
      } else paste("requested", model$provider_name, "; reported", paste(unique(providers), collapse = ", "))
    } else {
      provider_ok <- from_api
      reason <- "direct endpoint; requires API id and model_snapshot on every successful response"
    }
    if (!from_api) reason <- paste(reason, "; missing API evidence: requires non-mock successful responses with meta$id and meta$model_snapshot")
    hits <- sum(success & !is.na(r$value) & r$value %in% acmg_classes(plan))
    numeric_token <- function(m, reasoning = FALSE) {
      value <- if (reasoning) m[["usage"]][["completion_tokens_details"]][["reasoning_tokens"]] else m[["usage"]][["completion_tokens"]]
      if (acmg_scalar(value, "numeric") && value >= 0) as.numeric(value) else NA_real_
    }
    completion <- vapply(responses, numeric_token, 0)
    reasoning <- vapply(responses, numeric_token, 0, reasoning = TRUE)
    usage_value <- function(m, field) {
      value <- if (is.list(m[["usage"]])) m[["usage"]][[field]]
      if (acmg_scalar(value, "numeric") && value >= 0) as.numeric(value) else NA_real_
    }
    prompt_tokens <- vapply(responses, usage_value, 0, field = "prompt_tokens")
    billed <- vapply(responses, usage_value, 0, field = "cost")
    # Second evidence of the cost calculation for routed models (ADR-011 no. 5):
    # billed usage.cost against the tokens at the plan prices. Both sums need the
    # field on every successful response; the direct OpenAI endpoint reports no cost.
    routed <- length(unlist(model$provider_order)) > 0L
    sum_all <- function(x) if (routed && length(x) && !anyNA(x)) sum(x) else NA_real_
    q <- function(x, prob) if (!length(x) || all(is.na(x))) NA_real_ else
      unname(stats::quantile(x, prob, na.rm = TRUE, type = plan$evaluation$kappa_bootstrap$quantile_type))
    q90 <- q(completion, plan$pilot$cost_quantile)
    if (from_api && length(completion) && !anyNA(completion)) {
      costs[key] <- projected_calls * (plan$tokens$input * model$price_in + q90 * model$price_out) / 1e6
    }
    # Backend errors as in the repeat-day trigger (ADR-014): rows with a recorded
    # error among the stored pilot rows; unreadable answers do not count.
    error_rows <- sum(!success)
    error_share <- if (nrow(r)) error_rows / nrow(r) else NA_real_
    errors_ok <- is.finite(error_share) && error_share <= plan$pilot$error_share_trigger
    errors_reason <- if (!nrow(r)) "no stored pilot calls" else
      sprintf("%d of %d backend errors (share %s %s %s)", error_rows, nrow(r), format(error_share),
              if (errors_ok) "<=" else ">", format(plan$pilot$error_share_trigger))
    lat <- if ("latency_s" %in% names(r)) r$latency_s else numeric()
    latency_max <- if (any(!is.na(lat))) max(lat, na.rm = TRUE) else NA_real_
    summary[[key]] <- data.frame(model = key, complete = unname(complete[key]), planned = nrow(expected),
                                  stored = nrow(r), recognized = hits, projected_usd = unname(costs[key]),
                                  completion_q90 = q90, latency_median = q(lat, 0.5), latency_max = latency_max,
                                  reasoning_median = q(reasoning, 0.5), reasoning_q90 = q(reasoning, plan$pilot$cost_quantile),
                                  reasoning_exceeds_completion = sum(reasoning > completion, na.rm = TRUE),
                                  usage_cost_usd = sum_all(billed),
                                  recomputed_cost_usd = sum_all((prompt_tokens * model$price_in + completion * model$price_out) / 1e6))
    tokens[[key]] <- data.frame(model = rep(key, sum(success)),
                                id = acmg_meta_text(responses, "id"),
                                completion_tokens = completion, reasoning_tokens = reasoning)
    result[[key]] <- data.frame(model = key, rule = c("4xx", "provider", "parser", "cost", "backend_errors"),
                                passed = c(parameter_ok, provider_ok, complete[key] && hits >= plan$pilot$parser_hits_min, FALSE, errors_ok),
                                reason = c(if (parameter_ok) "no HTTP 4xx backend error" else "HTTP 4xx backend error recorded",
                                           reason, sprintf("%d recognized of %d planned; complete=%s", hits, nrow(expected), complete[key]),
                                           "cost pending", errors_reason), stringsAsFactors = FALSE)
  }
  total <- if (anyNA(costs)) NA_real_ else sum(costs)
  cost_ok <- is.finite(total) && total < plan$budget$budget_eur
  for (key in keys) {
    at <- result[[key]]$rule == "cost"
    result[[key]]$passed[at] <- cost_ok
    result[[key]]$reason[at] <- sprintf("projected USD %s; sum USD %s < %s required; complete API usage required; no exchange rate",
                                      format(costs[key]), format(total), format(plan$budget$budget_eur))
  }
  rules <- do.call(rbind, result)
  list(rules = rules, summary = do.call(rbind, summary), tokens = do.call(rbind, tokens),
       complete = complete, projected_usd = total, passed = all(complete) && all(rules$passed))
}

acmg_print_pilot <- function(pilot) {
  for (i in seq_len(nrow(pilot$rules))) {
    r <- pilot$rules[i, ]
    cat(sprintf("%s %s %s: %s\n", r$model, r$rule, if (r$passed) "passed" else "failed", r$reason))
  }
  print(pilot$summary, row.names = FALSE)
  invisible(pilot)
}

acmg_repeat_day <- function(runs, plan) {
  out <- list()
  for (block in sort(unique(runs$block))) for (key in names(acmg_models(plan))) {
    r <- runs[runs$block == block & runs$model_id == key, , drop = FALSE]
    if (!nrow(r)) next
    m <- acmg_meta(r)
    model <- acmg_models(plan)[[key]]
    provider <- acmg_meta_text(m, "provider")
    providers <- unique(provider[!is.na(provider)])
    snapshots <- unique(unlist(lapply(m, `[[`, "model_snapshot"), use.names = FALSE))
    provider_change <- length(providers) > 1L ||
      (length(model$provider_name) > 0L &&
         (any(providers != model$provider_name) || any(is.na(provider) & !acmg_errors(r))))
    share <- mean(acmg_errors(r))
    out[[length(out) + 1L]] <- data.frame(block = block, model = key, provider_change = provider_change,
                                        model_change = length(snapshots) > 1L, backend_error_share = share,
                                        error_trigger = is.finite(share) && share > plan$pilot$error_share_trigger)
  }
  do.call(rbind, out)
}

# Backend errors per model and PB run (ADR-011 no. 6; docs/03 A.8 no. 4). Only
# rows with a recorded error count; unreadable answers are not backend errors.
# Above error_share_trigger the operator repeats the robustness part on the
# store copy taken before the robustness runs; nothing is enforced here.
acmg_robustness_errors <- function(runs, plan) {
  ids <- unlist(plan$robustness$pb_design$prompt_ids, use.names = FALSE)
  out <- list()
  for (key in names(acmg_models(plan))) for (id in ids) {
    r <- runs[which(runs$model_id == key & runs$prompt_id == id), , drop = FALSE]
    if (!nrow(r)) next
    errors <- sum(acmg_errors(r))
    out[[length(out) + 1L]] <- data.frame(model = key, prompt_id = id, rows = nrow(r), error_rows = errors,
                                          backend_error_share = errors / nrow(r),
                                          error_trigger = errors / nrow(r) > plan$pilot$error_share_trigger)
  }
  if (!length(out)) {
    return(data.frame(model = character(), prompt_id = character(), rows = integer(), error_rows = integer(),
                      backend_error_share = numeric(), error_trigger = logical()))
  }
  do.call(rbind, out)
}

# Resolve the existing prefix (including symlinks) before checking descendants.
acmg_resolve_path <- function(path) {
  if (!acmg_scalar(path)) stop("AP1 path must be a non-empty string.", call. = FALSE)
  path <- path.expand(path)
  if (!grepl("^(/|[A-Za-z]:[/\\\\])", path)) path <- file.path(getwd(), path)
  suffix <- character()
  while (!file.exists(path) && !dir.exists(path)) {
    parent <- dirname(path)
    if (identical(parent, path)) stop("Cannot resolve AP1 path.", call. = FALSE)
    suffix <- c(basename(path), suffix)
    path <- parent
  }
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  for (part in suffix) {
    if (part == "..") path <- dirname(path) else if (part != ".") path <- file.path(path, part)
  }
  path
}

acmg_external_path <- function(path, root = acmg_resource()) {
  resolved <- acmg_resolve_path(path)
  root <- acmg_resolve_path(root)
  compare <- function(x) if (.Platform$OS.type == "windows") tolower(x) else x
  if (compare(resolved) == compare(root) || startsWith(compare(resolved), paste0(compare(root), "/"))) {
    stop("AP1 store and reports must be outside the package working tree.", call. = FALSE)
  }
  resolved
}

acmg_store_read <- function(path, mode) {
  acmg_require(c("DBI", "RSQLite", "jsonlite"))
  if (!is_sqlite_path(path)) stop("AP1 --store requires .sqlite, .sqlite3 or .db.", call. = FALSE)
  if (!file.exists(path)) {
    rows <- empty_runs(); attr(rows, "ap1_mode") <- mode
    return(rows)
  }
  con <- DBI::dbConnect(RSQLite::SQLite(), path, flags = RSQLite::SQLITE_RO)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  tables <- DBI::dbListTables(con)
  if (!"runs" %in% tables) stop("AP1 store has no runs table.", call. = FALSE)
  rows <- DBI::dbReadTable(con, "runs")
  stop_if_missing_cols(rows, names(empty_runs()), "AP1 store")
  rows$value <- as.character(rows$value)
  if ("ap1_metadata" %in% tables) {
    meta <- DBI::dbReadTable(con, "ap1_metadata")
    stop_if_missing_cols(meta, c("key", "value"), "AP1 store metadata")
    marker <- meta$value[meta$key == "backend"]
    if (length(marker) != 1L || !marker %in% c("api", "mock")) stop("AP1 store provenance is not established.", call. = FALSE)
    attr(rows, "ap1_mode") <- marker
  }
  provenance <- acmg_provenance(rows)
  if (provenance == "unverified") {
    unverified <- sum(!acmg_errors(rows) & acmg_meta_kind(acmg_meta(rows)) == "unknown")
    if (unverified > 0L) {
      stop(sprintf("AP1 store backend/provenance is unverified: %d successful responses lack valid meta$id or meta$model_snapshot; use a new store; store unchanged.",
                   unverified), call. = FALSE)
    }
  }
  actual <- switch(provenance, synthetic = "mock", api = "api", "unknown")
  if (!identical(actual, mode)) stop("AP1 store backend/provenance does not match --backend; store unchanged.", call. = FALSE)
  attr(rows, "ap1_mode") <- actual
  rows
}

acmg_store_init <- function(path, mode) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  con <- DBI::dbConnect(RSQLite::SQLite(), path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  DBI::dbWithTransaction(con, {
    if (!DBI::dbExistsTable(con, "runs")) DBI::dbWriteTable(con, "runs", empty_runs())
    if (!DBI::dbExistsTable(con, "ap1_metadata")) {
      DBI::dbWriteTable(con, "ap1_metadata", data.frame(key = "backend", value = mode))
    }
  })
  invisible(path)
}

acmg_join_items <- function(runs, items) {
  idx <- match(runs$item_id, items$item_id)
  if (anyNA(idx)) stop("AP1 store contains unknown item identifiers.", call. = FALSE)
  mode <- attr(runs, "ap1_mode", exact = TRUE)
  for (nm in setdiff(names(items), "item_id")) runs[[nm]] <- items[[nm]][idx]
  result <- as_msa_runs(runs)
  attr(result, "ap1_mode") <- mode
  result
}

acmg_run_cli <- function(args) {
  allowed <- c("--part", "--block", "--backend", "--store", "--insaid-path", "--report-dir", "--evaluate-only")
  opt <- list(); i <- 1L
  while (i <= length(args)) {
    name <- args[i]
    if (!name %in% allowed || name %in% names(opt)) stop("Unknown or repeated AP1 option: ", name, call. = FALSE)
    if (name == "--evaluate-only") { opt[[name]] <- TRUE; i <- i + 1L } else {
      if (i == length(args) || startsWith(args[i + 1L], "--")) stop("Missing value for ", name, call. = FALSE)
      opt[[name]] <- args[i + 1L]; i <- i + 2L
    }
  }
  mode <- opt[["--backend"]]
  if (is.null(mode) || !mode %in% c("mock", "api")) stop("AP1 requires explicit --backend mock|api.", call. = FALSE)
  evaluate <- isTRUE(opt[["--evaluate-only"]])
  part <- opt[["--part"]]
  if (!evaluate && (is.null(part) || !part %in% c("pilot", "main", "robustness"))) stop("AP1 requires --part pilot|main|robustness.", call. = FALSE)
  if (evaluate && (!is.null(part) || !is.null(opt[["--block"]]))) stop("--evaluate-only does not accept --part or --block.", call. = FALSE)
  plan <- acmg_plan()
  block <- NULL
  if (!is.null(opt[["--block"]])) {
    raw <- opt[["--block"]]
    if (part != "main" || !grepl("^[0-9]+$", raw) || !as.numeric(raw) %in% seq_len(plan$design$blocks)) {
      stop("AP1 --block must select a main-plan block.", call. = FALSE)
    }
    block <- as.integer(raw)
  }
  acmg_require(c("jsonlite", "DBI", "RSQLite"))
  root <- getOption("llmsa.ap1.root", acmg_resource())
  store <- acmg_external_path(opt[["--store"]] %||% file.path(root, "..", "llmsa-runs", "ap1_runs.sqlite"), root)
  if (!is_sqlite_path(store)) stop("AP1 --store requires .sqlite, .sqlite3 or .db.", call. = FALSE)
  if (!is.null(opt[["--report-dir"]])) plan$reporting$output_dir <- acmg_external_path(opt[["--report-dir"]], root)
  rows <- acmg_store_read(store, mode)
  insaid <- opt[["--insaid-path"]]
  if (!evaluate && mode == "api" && part == "robustness") acmg_check_insaid(insaid, acmg_insaid_hash())
  items <- acmg_items(insaid_path = insaid)
  pilot_items <- acmg_items(pilot = TRUE)
  if (evaluate) {
    if (!file.exists(store)) stop("AP1 evaluation store is missing.", call. = FALSE)
    if (mode == "api" && !isTRUE(attr(items, "insaid_loaded"))) {
      message("AP1: INSAID references not loaded; reference metrics use available ERepo references only.")
    }
    return(invisible(acmg_evaluate(acmg_join_items(rows, rbind(items, pilot_items)), plan)))
  }
  if (mode == "api" && part %in% c("main", "robustness")) {
    pilot <- acmg_pilot(rows, plan, pilot_items)
    if (!pilot$passed) {
      failed <- pilot$rules[!pilot$rules$passed, ]
      stop("AP1 pilot has not passed: ", paste(paste(failed$model, failed$rule), collapse = ", "),
           "; no API calls made.", call. = FALSE)
    }
  }
  selected <- if (part == "pilot") pilot_items else items
  design <- acmg_design(selected, plan, part)
  backends <- if (mode == "api") acmg_api_backends(plan) else NULL
  backend <- if (mode == "mock") acmg_mock_backend(selected, plan) else function(prompt, model, row) {
    backends[[row$model_id]](prompt, model, row)
  }
  parser <- acmg_parser(plan)
  extract <- parse_json_field("classification")
  parse_json <- function(text) parser(extract(text))
  acmg_store_init(store, mode)
  blocks <- block %||% unique(design$block)
  for (b in blocks) {
    msa_run(design, backend, parse = parser, parse_by_prompt = list(json = parse_json),
             block = b, store = store, resume = TRUE, verbose = FALSE)
    rows <- acmg_store_read(store, mode)
    if (part == "main") {
      main <- rows[rows$item_id %in% items$item_id & rows$prompt_id %in% names(plan$templates) & rows$block == b, ]
      cat("AP1 repeat-day diagnostics (operator decision; no automatic repeat):\n")
      print(acmg_repeat_day(main, plan), row.names = FALSE)
    }
  }
  cat(sprintf("AP1 %s backend=%s; stored calls=%d; store=%s\n", part, mode, nrow(rows), store))
  if (part == "pilot") acmg_print_pilot(acmg_pilot(rows, plan, pilot_items))
  if (part == "robustness") {
    cat(sprintf("AP1 robustness backend errors per PB run; error_trigger marks shares above %s (operator decision on the store copy taken before the robustness runs; no automatic repeat):\n",
                format(plan$pilot$error_share_trigger)))
    print(acmg_robustness_errors(rows, plan), row.names = FALSE)
  }
  invisible(rows)
}

acmg_capture_fit <- function(expr) {
  warnings <- character()
  value <- withCallingHandlers(tryCatch(force(expr), error = function(e) e), warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  })
  list(value = value, warnings = warnings, error = inherits(value, "error"))
}

acmg_convergence_warning <- function(text) {
  # ADR-006: diagnostic numbers and a mere optimiser switch are not triggers.
  grepl("converge|Hessian|max\\|grad|gradient|unidentifiable", text, ignore.case = TRUE)
}

acmg_fit <- function(runs, plan) {
  ord <- acmg_capture_fit(msa_fit(runs, type = "ordinal", levels = acmg_classes(plan), link = "probit"))
  trigger <- ord$warnings[acmg_convergence_warning(ord$warnings)]
  reason <- c(if (ord$error) conditionMessage(ord$value), trigger)
  fallback <- length(reason) > 0L
  diagnostics <- list(iterations = NULL, max_gradient = NULL, hessian_condition = NULL)
  if (!ord$error) {
    m <- ord$value$model
    diagnostics$iterations <- m$optRes$iterations %||% m$Niter
    if (length(m$gradient)) diagnostics$max_gradient <- max(abs(m$gradient))
    if (!is.null(m$Hessian) && all(is.finite(m$Hessian))) {
      diagnostics$hessian_condition <- kappa(m$Hessian, exact = TRUE)
    }
  }
  num_warnings <- character()
  if (fallback) {
    numeric_runs <- runs
    scores <- unlist(plan$evaluation$fallback_fit$scores)
    numeric_runs$value <- unname(scores[as.character(runs$value)])
    num <- acmg_capture_fit(msa_fit(numeric_runs, type = "numeric"))
    if (num$error) stop("AP1 numeric fallback failed: ", conditionMessage(num$value), call. = FALSE)
    fit <- num$value
    num_warnings <- num$warnings
  } else fit <- ord$value
  list(fit = fit, fallback = fallback, fallback_reason = reason,
       warnings = list(ordinal = ord$warnings, numeric = num_warnings), diagnostics = diagnostics)
}

acmg_modal <- function(values) {
  categories <- unique(values)
  frequency <- tabulate(match(values, categories), nbins = length(categories))
  if (!length(frequency)) return(list(modal = NA_character_, has_modal = FALSE))
  winner <- which(frequency == max(frequency))
  list(modal = if (length(winner) == 1L) as.character(categories[winner]) else NA_character_,
       has_modal = length(winner) == 1L)
}

acmg_modal_table <- function(runs, item_ids = runs$item_id, item_runs = runs) {
  ids <- sort(unique(as.character(item_ids)), method = "radix")
  modes <- lapply(ids, function(id) acmg_modal(runs$value[runs$item_id == id]))
  out <- data.frame(item_id = ids, modal = vapply(modes, `[[`, "", "modal"),
                    has_modal = vapply(modes, `[[`, logical(1), "has_modal"), stringsAsFactors = FALSE)
  item_runs <- item_runs[item_runs$item_id %in% ids, , drop = FALSE]
  columns <- c("reference", "source", paste0("prior_differs_", c("sol", "llama", "qwen")))
  for (col in columns) {
    # Conflicting item metadata are invalid input, not a choice of join order.
    by_item <- split(item_runs[[col]], as.character(item_runs$item_id))
    if (any(lengths(lapply(by_item, unique)) != 1L)) stop("AP1 inconsistent item column: ", col, call. = FALSE)
    out[[col]] <- item_runs[[col]][match(ids, item_runs$item_id)]
  }
  out$reference <- as.character(out$reference)
  out$reference[!is.na(out$reference) & !nzchar(out$reference)] <- NA_character_
  out
}

acmg_kappa <- function(rated, reference, classes) {
  n <- length(rated); k <- length(classes)
  if (!n || length(reference) != n) return(NA_real_)
  i <- match(rated, classes); i[is.na(rated)] <- k + 1L
  j <- match(reference, classes)
  if (anyNA(i) || anyNA(j)) return(NA_real_)
  counts <- matrix(tabulate(i + (j - 1L) * (k + 1L), nbins = (k + 1L) * k), nrow = k + 1L) / n
  weight <- rbind(1 - abs(outer(seq_len(k), seq_len(k), "-")) / (k - 1L), rep(0, k))
  observed <- sum(weight * counts)
  expected <- sum(weight * tcrossprod(rowSums(counts), colSums(counts)))
  if (!is.finite(expected) || expected >= 1) NA_real_ else (observed - expected) / (1 - expected)
}

acmg_kappa_interval <- function(modal, plan) {
  eligible <- modal$has_modal & !is.na(modal$reference)
  rated <- modal$modal[eligible]; reference <- modal$reference[eligible]
  bt <- plan$evaluation$kappa_bootstrap
  estimate <- acmg_kappa(rated, reference, acmg_classes(plan))
  bootstrap <- if (!length(rated)) rep(NA_real_, bt$replicates) else acmg_seeded(bt$seed, {
    vapply(seq_len(bt$replicates), function(b) {
      i <- sample.int(length(rated), length(rated), replace = TRUE)
      acmg_kappa(rated[i], reference[i], acmg_classes(plan))
    }, 0)
  })
  valid <- is.finite(bootstrap)
  alpha <- (1 - bt$level) / 2
  limits <- if (any(valid)) unname(stats::quantile(bootstrap[valid], c(alpha, 1 - alpha), type = bt$quantile_type)) else c(NA_real_, NA_real_)
  list(estimate = estimate, lower = limits[1], upper = limits[2], n = length(rated),
       valid = sum(valid), discarded = sum(!valid), replicates = bt$replicates,
       seed = bt$seed, level = bt$level)
}

acmg_reference_metrics <- function(modal, key, plan) {
  groups <- list(list(by = "all", group = "all", rows = rep(TRUE, nrow(modal))))
  for (source in c("erepo", "insaid")) {
    groups[[length(groups) + 1L]] <- list(by = "source", group = source, rows = modal$source %in% source)
  }
  for (s in unique(c("sol", key))) for (g in c("TRUE", "FALSE")) {
    field <- paste0("prior_differs_", s)
    groups[[length(groups) + 1L]] <- list(by = field, group = g, rows = toupper(as.character(modal[[field]])) %in% g)
  }
  rows <- lapply(groups, function(g) {
    use <- g$rows & modal$has_modal & !is.na(modal$reference)
    hits <- sum((!is.na(modal$modal[use]) & modal$modal[use] == modal$reference[use]) %in% TRUE)
    n <- sum(use)
    data.frame(by = g$by, group = g$group, n = n, hits = hits,
                rate = if (n) hits / n else NA_real_,
                estimate = acmg_kappa(modal$modal[use], modal$reference[use], acmg_classes(plan)))
  })
  both <- do.call(rbind, rows)
  list(hit_rate = both[, c("by", "group", "n", "hits", "rate")], kappa_by = both[, c("by", "group", "n", "estimate")])
}

acmg_robustness <- function(runs, modal, item_ids, plan) {
  if (!nrow(runs)) return(NULL)
  ids <- unlist(plan$robustness$pb_design$prompt_ids, use.names = FALSE)
  counts <- table(factor(runs$item_id, levels = item_ids), factor(runs$prompt_id, levels = ids))
  # The evaluator requires all design columns. Compact internal count tables
  # may omit constant design columns; any supplied keys must match the plan.
  design_complete <- all(runs$rep %in% seq_len(plan$robustness$replicates)) &&
    all(runs$block %in% 1L) && !anyDuplicated(run_key(runs))
  complete <- nrow(runs) == length(item_ids) * length(ids) && all(counts == 1L) && design_complete
  if (!complete) return(list(complete = FALSE, counts = counts, effects = NULL, band = "not assessed",
                             reason = paste("Robustness requires exactly one row per item and PB prompt,",
                                            "planned replicate keys, block 1 and no duplicate run_key.")))
  response <- do.call(rbind, lapply(ids, function(id) {
    r <- runs[runs$prompt_id == id, , drop = FALSE]
    reference <- modal[match(r$item_id, modal$item_id), , drop = FALSE]
    agrees <- !acmg_errors(r) & !is.na(r$value) & reference$has_modal &
      !is.na(reference$modal) & r$value == reference$modal
    # Evaluated PB runs always carry their own references. Retain support for
    # compact internal tables whose only reference column is supplied in modal.
    truth <- if ("reference" %in% names(r)) as.character(r$reference) else reference$reference
    eligible <- !is.na(truth) & nzchar(truth)
    hits <- sum((!acmg_errors(r) & !is.na(r$value) & eligible & r$value == truth) %in% TRUE)
    data.frame(prompt_id = id, x = sum(agrees %in% TRUE), n = nrow(r),
                reference_n = sum(eligible), reference_hits = hits,
                reference_rate = if (sum(eligible)) hits / sum(eligible) else NA_real_)
  }))
  correction <- plan$robustness$response$correction
  response$y <- log((response$x + correction) / (response$n - response$x + correction))
  effects <- msa_robustness(acmg_pb(plan), response$y, alpha = plan$acceptance$robustness$sme_alpha)
  e <- stats::setNames(effects$effect, effects$factor)[names(plan$robustness$factors)]
  intercept <- mean(response$y)
  delta <- stats::plogis(intercept + e / 2) - stats::plogis(intercept - e / 2)
  large <- abs(delta) > plan$acceptance$robustness$delta_p_limit
  band <- if (!any(large)) "acceptable" else if (any(large & abs(e) > attr(effects, "sme"))) "unacceptable" else "marginal"
  list(complete = TRUE, response = response, effects = effects, delta_p = delta, band = band, intercept = intercept)
}

acmg_bands <- function(grr, kappa, dangerous, robustness, plan) {
  a <- plan$acceptance
  band_g <- if (!is.finite(grr)) "not assessed" else if (grr < a$grr_pct_study_var$acceptable_below) "acceptable" else
    if (grr <= a$grr_pct_study_var$marginal_below) "marginal" else "unacceptable"
  band_k <- if (!is.finite(kappa)) "not assessed" else if (kappa >= a$kappa_linear_modal$acceptable_min) "acceptable" else
    if (kappa >= a$kappa_linear_modal$marginal_min) "marginal" else "unacceptable"
  band_d <- if (!is.finite(dangerous)) "not assessed" else if (dangerous <= a$dangerous_errors$acceptable_max) "acceptable" else
    if (dangerous <= a$dangerous_errors$marginal_max) "marginal" else "unacceptable"
  c(grr = band_g, kappa = band_k, dangerous = band_d, robustness = robustness %||% "not assessed")
}

acmg_worst <- function(bands, plan) {
  rank <- match(bands, unlist(plan$acceptance$bands_in_order))
  if (!length(rank) || anyNA(rank)) "not assessed" else unlist(plan$acceptance$bands_in_order, use.names = FALSE)[max(rank)]
}

acmg_assessment <- function(result, key, runs, joint, plan) {
  model <- acmg_models(plan)[[key]]
  meta <- acmg_meta(runs)
  successful <- !acmg_errors(runs)
  missing <- function(field) sum(successful & is.na(acmg_meta_text(meta, field)))
  reported <- function(field) {
    v <- unique(unlist(lapply(meta, `[[`, field), use.names = FALSE))
    if (!length(v)) "not reported" else paste(v, collapse = ", ")
  }
  warning_text <- c(result$warnings$ordinal, result$warnings$numeric)
  fit_text <- c(if (result$fallback) paste("Numeric fallback on class scores:", paste(result$fallback_reason, collapse = "; ")) else "Ordinal probit fit on the latent scale.",
                if (length(warning_text)) paste("Fit warnings:", paste(warning_text, collapse = "; ")) else "No fit warnings.",
                paste("Ordinal diagnostics:", paste(names(result$diagnostics), vapply(result$diagnostics, function(x) if (length(x)) paste(x, collapse = ", ") else "not available", ""), sep = " = ", collapse = "; ")))
  k <- result$kappa
  kappa_text <- sprintf("Linear weighted modal kappa %.6g; %.0f%% percentile item-bootstrap interval [%.6g, %.6g]. %d eligible items; %d finite replicates, %d discarded, seed %s.",
                        k$estimate, 100 * k$level, k$lower, k$upper, k$n, k$valid, k$discarded, k$seed)
  rules <- paste(plan$evaluation$modal_rule, plan$evaluation$na_rule)
  rules <- paste(rules, "Prior dates are strictly before the model cutoff; only five-class entries count, flagged submissions remain. Exclude the own expert panel by normalised name, otherwise all expert panels; use latest date and majority, with ties conflicting (ADR-005).")
  sections <- list(
    "Provenance and status" = list(text = c(paste("Provenance:", result$provenance), plan$reporting$provisional,
                                            sprintf("Main plan complete: %s. Design keys valid: %s. Items with incorrect call counts: %d.", result$complete, result$design_complete, sum(!result$completeness$complete)))),
    "Fit and fallback" = list(text = fit_text),
    "Decision metrics" = list(text = c(kappa_text, rules,
         sprintf("Missing response share: %.6g; items without a modal response: %d; dangerous ERepo modal errors: %d.", result$na_share, result$n_no_modal, result$dangerous)),
                              table = result$reference_basis),
    "Reference hit rates" = list(text = "Modal responses, including NA errors; ties and missing references excluded. Unknown prior flags belong to neither TRUE nor FALSE.", table = result$hit_rate),
    "Stratified kappa" = list(text = "Same eligibility and missing-value rule as the decision kappa; memorisation is a limitation of accuracy, not of precision.", table = result$kappa_by),
    "Completeness" = list(text = "Counts include backend failures. Missing or duplicated design cells prevent full assessment.",
                         table = result$completeness[, c("expected", "observed", "complete"), drop = FALSE]),
    "Model and routing" = list(text = c(paste("Requested model:", model$id, "; reported:", reported("model_snapshot")),
        paste("Requested provider:", model$provider_name %||% "direct OpenAI endpoint", "; reported:", reported("provider")),
        paste("Requested endpoint tags:", paste(unlist(model$provider_order), collapse = ", "), "; quantizations:", paste(unlist(model$quantizations), collapse = ", "), "; allow_fallbacks: false for routed requests."),
        paste("Configured temperature:", model$temperature %||% "omitted (provider default)", "; reasoning effort:", model$reasoning %||% "omitted"),
        paste("Recorded request seed:", reported("seed"), "; temperature:", reported("temperature"), "; reasoning effort:", reported("reasoning_effort")),
        paste("Knowledge cutoff:", model$knowledge_cutoff, "; system fingerprint:", reported("system_fingerprint")),
        sprintf("Successful responses without provider: %d of %d; without system_fingerprint: %d of %d.",
                missing("provider"), sum(successful), missing("system_fingerprint"), sum(successful)),
        paste("API seed:", model$seed, "; design seed:", plan$design$seed, "; RNG:", plan$provenance$rng))),
    "Joint research fit" = list(text = c(paste("Joint fit type:", joint$type, "; numeric fallback:", joint$fallback, "; no verdict."),
         paste("Joint fit warnings:", paste(unlist(joint$warnings), collapse = "; "))), table = joint$vc),
    "Limitations" = list(text = unlist(plan$reporting$limitations, use.names = FALSE)))
  if (!is.null(result$robustness) && isTRUE(result$robustness$complete)) {
    rb <- result$robustness
    table <- as.data.frame(rb$effects)
    table$delta_p <- unname(rb$delta_p[table$factor])
    sections[["Robustness decision"]] <- list(text = paste("Empirical logit with correction", plan$robustness$response$correction,
         "; delta_p evaluated at the mean logit of the PB runs; practical limit", plan$acceptance$robustness$delta_p_limit, "; band:", rb$band), table = table)
    sections[["Robustness reference accuracy"]] <- list(text = "Secondary rates against available reference classes, not the stability response.",
                                                         table = rb$response[, c("prompt_id", "reference_n", "reference_hits", "reference_rate")])
  } else sections[["Robustness decision"]] <- list(text = result$robustness$reason %||% "Robustness not assessed: PB runs absent.")
  if (!is.null(result$robustness$errors)) {
    sections[["Robustness backend errors"]] <- list(text = sprintf(
      "Backend errors per PB run (rows with a recorded error; unreadable answers do not count). error_trigger marks shares above %s; the operator then repeats the robustness part on the store copy taken before the robustness runs (docs/03 A.8 no. 4). Nothing is enforced.",
      format(plan$pilot$error_share_trigger)), table = result$robustness$errors)
  }
  for (policy in plan$reporting$policies) {
    sections[[paste("Data policy:", policy$provider)]] <- list(text = paste(policy$summary, "Snapshot:", policy$snapshot_date,
         ";", policy$location, ";", policy$url, "Quoted evidence:", policy$quote))
  }
  provenance <- readLines(acmg_resource("extdata", "items_ap1_2026-10-24", "SHA256SUMS"), warn = FALSE)
  sections[["Frozen data provenance"]] <- list(text = c("SHA-256 of the shipped data and provenance files:", provenance))
  sections[["Pilot rules"]] <- list(text = c(unlist(plan$pilot$pass_rules, use.names = FALSE),
       "Projected USD = planned main and PB calls per model times (input token assumption times input price + completion-token 90th percentile times output price) / 1e6. Sum across models; no exchange rate or duplicate reasoning-token charge.",
       paste("Backend error trigger:", plan$pilot$error_share_trigger, "; repeat days are operator decisions on pre-block store copies.")))
  if (!is.null(result$pilot)) {
    sections[["Pilot result"]] <- list(text = "Pilot facts from the supplied runs; absent calls remain missing. Provider and cost rules cannot pass on mock metadata.", table = result$pilot$rules)
    sections[["Pilot measurements"]] <- list(text = "Latency and token summaries use available recorded values. Costs use usage.completion_tokens, which includes reasoning. Reasoning token counts are shown as reported by the API; for Qwen3-32B via DeepInfra they can exceed completion_tokens and are then not on the model's token scale.", table = result$pilot$summary)
  }
  sections[["Repeat-day diagnostics"]] <- list(text = "Backend errors, provider changes and model-snapshot changes are reported per block. The operator decides on a repeat day.", table = acmg_repeat_day(runs, plan))
  a <- plan$acceptance
  thresholds <- c(sprintf("Acceptable < %g%%; marginal through %g%%; both boundary values marginal.", a$grr_pct_study_var$acceptable_below, a$grr_pct_study_var$marginal_below),
                  sprintf("Acceptable >= %g; marginal >= %g; point estimate.", a$kappa_linear_modal$acceptable_min, a$kappa_linear_modal$marginal_min),
                  sprintf("ERepo only: acceptable <= %g; marginal <= %g.", a$dangerous_errors$acceptable_max, a$dangerous_errors$marginal_max),
                  sprintf("Acceptable if all |delta_p| <= %g; unacceptable if a larger effect also exceeds SME (alpha %g).", a$robustness$delta_p_limit, a$robustness$sme_alpha))
  rb_value <- if (length(result$robustness$delta_p)) max(abs(result$robustness$delta_p)) else NA_real_
  list(criteria = data.frame(criterion = names(result$verdicts), band = unname(result$verdicts),
                              value = c(unname(result$grr$summary[["grr_pct_study_var"]]), k$estimate, result$dangerous, rb_value),
                              note = thresholds),
       verdict = result$verdict, sections = sections)
}

#' @rdname acmg
acmg_evaluate <- function(runs, plan) {
  acmg_validate_plan(plan)
  if (!inherits(runs, "msa_runs")) stop("AP1 runs must be an msa_runs object.", call. = FALSE)
  stop_if_missing_cols(runs, c("item_id", "prompt_id", "model_id", "rep", "block", "value", "reference", "source",
                              paste0("prior_differs_", c("sol", "llama", "qwen"))), "AP1 runs")
  provenance <- acmg_provenance(runs)
  ids <- acmg_items()$item_id
  main <- runs[runs$item_id %in% ids & runs$prompt_id %in% names(plan$templates), , drop = FALSE]
  if (!nrow(main)) stop("AP1 main-plan responses are missing.", call. = FALSE)
  pb <- runs[grepl("^pb", runs$prompt_id), , drop = FALSE]
  evaluated <- rbind(main, pb)
  if (any(!is.na(evaluated$value) & !as.character(evaluated$value) %in% acmg_classes(plan)) ||
      any(!is.na(evaluated$reference) & nzchar(as.character(evaluated$reference)) & !as.character(evaluated$reference) %in% acmg_classes(plan))) {
    stop("AP1 runs contain unknown response or reference classes.", call. = FALSE)
  }
  keys <- names(acmg_models(plan))
  if (!setequal(unique(main$model_id), keys)) stop("AP1 requires main responses for each planned model.", call. = FALSE)
  joint_result <- acmg_fit(main, plan)
  joint <- joint_result$fit
  for (nm in setdiff(names(joint_result), "fit")) joint[[nm]] <- joint_result[[nm]]
  models <- stats::setNames(vector("list", length(keys)), keys)
  for (key in keys) {
    data <- main[main$model_id == key, , drop = FALSE]
    fit_result <- acmg_fit(data, plan)
    grr <- msa_grr(fit_result$fit)
    modal <- acmg_modal_table(data, item_ids = ids, item_runs = runs)
    kappa <- acmg_kappa_interval(modal, plan)
    metrics <- acmg_reference_metrics(modal, key, plan)
    low <- utils::head(acmg_classes(plan), 2L); high <- utils::tail(acmg_classes(plan), 2L)
    dangerous <- sum(modal$source == "erepo" & modal$has_modal &
                        ((modal$modal %in% low & modal$reference %in% high) |
                         (modal$modal %in% high & modal$reference %in% low)))
    observed <- as.integer(table(factor(data$item_id, levels = ids)))
    completeness <- data.frame(item_id = ids, expected = plan$evaluation$modal_calls_per_item_and_model,
                                observed = observed, complete = observed == plan$evaluation$modal_calls_per_item_and_model)
    # Count and design-key checks protect against replacing a missing call with a duplicate.
    design_complete <- all(data$rep %in% seq_len(plan$design$replicates)) &&
      all(data$block %in% seq_len(plan$design$blocks)) && !anyDuplicated(run_key(data))
    complete <- all(completeness$complete) && design_complete
    rb <- pb[pb$model_id == key, , drop = FALSE]
    robustness <- acmg_robustness(rb, modal, ids, plan)
    if (!is.null(robustness)) robustness$errors <- acmg_robustness_errors(rb, plan)
    verdicts <- acmg_bands(grr$summary[["grr_pct_study_var"]], kappa$estimate, dangerous, robustness$band, plan)
    if (!complete) verdicts[] <- "not assessed"
    basis <- data.frame(kappa_items = kappa$n, excluded_no_modal = sum(!modal$has_modal),
                         excluded_missing_reference = sum(modal$has_modal & is.na(modal$reference)),
                         insaid_reference_items = sum(modal$source == "insaid" & !is.na(modal$reference)),
                         insaid_references_loaded = any(modal$source == "insaid" & !is.na(modal$reference)))
    models[[key]] <- c(list(grr = grr), fit_result,
                       list(modal = modal[, c("item_id", "modal", "has_modal")], n_no_modal = sum(!modal$has_modal),
                            kappa = kappa, agreement = msa_agreement(data, levels = acmg_classes(plan), reference = "reference", weights = "linear"),
                            hit_rate = metrics$hit_rate, kappa_by = metrics$kappa_by, na_share = mean(is.na(data$value)),
                            dangerous = dangerous, robustness = robustness, verdicts = verdicts, verdict = acmg_worst(verdicts, plan),
                            complete = complete, completeness = completeness, design_complete = design_complete,
                            reference_basis = basis, provenance = provenance))
  }
  output <- acmg_external_path(plan$reporting$output_dir %||% tempfile("ap1-reports-"))
  dir.create(output, showWarnings = FALSE, recursive = TRUE)
  pilot <- acmg_pilot(runs, plan)
  for (key in keys) {
    data <- main[main$model_id == key, , drop = FALSE]
    models[[key]]$pilot <- list(rules = pilot$rules[pilot$rules$model == key, , drop = FALSE],
                                summary = pilot$summary[pilot$summary$model == key, , drop = FALSE])
    m <- models[[key]]
    assessment <- acmg_assessment(m, key, data, joint, plan)
    # No per-item reference or protein table is ever passed as an assessment section.
    models[[key]]$report <- msa_report(m$grr, runs = data, agreement = m$agreement, robustness = m$robustness$effects,
        cou = plan$cou, risk = plan$risk$tier, acceptance = paste(plan$acceptance$overall, "Thresholds: see criteria and the approved AP1 plan."),
        question = "Does this preclassification pipeline satisfy the approved AP1 criteria?",
        title = paste("AP1", key, "-", provenance, "- provisional"),
        output_file = file.path(output, paste0("ap1-", key, ".html")), assessment = assessment)
  }
  list(models = models, joint = joint, provenance = provenance)
}
