# Report provenance is computed before rendering, independently of the format.
# The canonical CSV contract is specified byte for byte in ADR-053, section 10.
msa_report_csv_text <- function(x) {
  x <- as.character(x)
  quoted <- paste0('"', gsub('"', '""', enc2utf8(x), fixed = TRUE), '"')
  quoted[is.na(x)] <- "NA"
  quoted
}

msa_report_csv_column <- function(x) {
  if (is.factor(x)) return(msa_report_csv_text(x))
  if (is.logical(x) || is.integer(x)) {
    text <- as.character(x)
    text[is.na(x)] <- "NA"
    return(text)
  }
  if (is.numeric(x) && !is.complex(x)) {
    text <- sprintf("%.17g", x)
    decimal <- Sys.localeconv()[["decimal_point"]]
    if (decimal != ".") text <- gsub(decimal, ".", text, fixed = TRUE)
    return(text)
  }
  msa_report_csv_text(x)
}

msa_report_canonical <- function(runs) {
  tab <- as.data.frame(runs)
  keys <- c("block", "item_id", "prompt_id", "model_id", "rep")
  stop_if_missing_cols(tab, keys, "runs")
  other <- setdiff(names(tab), keys)
  columns <- c(keys, other[order(enc2utf8(other), method = "radix")])
  lines <- paste(msa_report_csv_text(columns), collapse = ",")
  if (nrow(tab)) {
    cells <- lapply(tab[columns], msa_report_csv_column)
    rows <- do.call(paste, c(unname(cells), sep = ","))
    sort_keys <- lapply(tab[keys], function(x) {
      if (is.numeric(x) && !is.complex(x)) x else enc2utf8(as.character(x))
    })
    ord <- do.call(order, c(unname(sort_keys), list(rows),
                           list(na.last = TRUE, method = "radix")))
    lines <- c(lines, rows[ord])
  }
  charToRaw(enc2utf8(paste0(paste(lines, collapse = "\n"), "\n")))
}

msa_report_hash <- function(runs) {
  if (is.null(runs)) return(NA_character_)
  if (!requireNamespace("digest", quietly = TRUE)) {
    stop("Package `digest` is required to report the SHA-256 data hash.", call. = FALSE)
  }
  digest::digest(msa_report_canonical(runs), algo = "sha256", serialize = FALSE)
}

msa_report_seed <- function(x) {
  seed <- attr(x, "seed", exact = TRUE)
  if (is.null(seed) || length(seed) != 1L || is.na(seed)) return("not reported")
  format(seed, scientific = FALSE, trim = TRUE, big.mark = "", decimal.mark = ".")
}

msa_report_models <- function(runs) {
  out <- data.frame(`Model ID` = character(), Model = character(),
                    Provider = character(), Quantization = character(),
                    check.names = FALSE, stringsAsFactors = FALSE)
  notes <- character()
  if (is.null(runs) || !nrow(runs)) return(list(table = out, notes = notes))
  ids <- as.character(runs$model_id)
  models <- unique(ids)
  models <- models[order(enc2utf8(models), na.last = TRUE, method = "radix")]
  has_json <- requireNamespace("jsonlite", quietly = TRUE)
  for (id in models) {
    selected <- if (is.na(id)) is.na(ids) else !is.na(ids) & ids == id
    raw_meta <- if ("meta" %in% names(runs)) as.character(runs$meta[selected]) else
      rep(NA_character_, sum(selected))
    unreadable <- 0L
    parsed <- lapply(raw_meta, function(text) {
      if (is.na(text) || !nzchar(trimws(text))) return(NULL)
      value <- if (has_json && startsWith(trimws(text), "{")) {
        tryCatch(jsonlite::parse_json(text, simplifyVector = FALSE),
                 error = function(e) NULL, warning = function(w) NULL)
      } else NULL
      if (is.null(value)) unreadable <<- unreadable + 1L
      value
    })
    values <- function(field) {
      observed <- lapply(parsed, function(meta) {
        # Exact access: requested provider_order is not an observed provider.
        value <- meta[[field, exact = TRUE]]
        if (is.list(value) && is.null(names(value)) &&
            all(vapply(value, is.character, logical(1)))) value <- unlist(value, use.names = FALSE)
        if (!is.character(value)) value <- character()
        value <- value[!is.na(value) & nzchar(trimws(value))]
        if (!length(value)) "not reported" else value
      })
      all <- unique(enc2utf8(unlist(observed, use.names = FALSE)))
      paste(sort(all, method = "radix"), collapse = "; ")
    }
    label <- if (is.na(id)) "not reported" else id
    out[nrow(out) + 1L, ] <- c(label, values("model_snapshot"),
                              values("provider"), values("quantizations"))
    if (unreadable) {
      notes <- c(notes, sprintf("Model ID %s: unreadable metadata in %d row(s)%s.",
                                label, unreadable,
                                if (has_json) " (expected a JSON object)" else " (jsonlite is unavailable)"))
    }
  }
  list(table = out, notes = notes)
}

msa_report_control_chart <- function(chart) {
  if (is.null(chart)) return(NULL)
  rules <- c(attr(chart, "rules", exact = TRUE), "reject")
  stop_if_missing_cols(chart, c("index", rules), "control_chart")
  positions <- lapply(rules, function(rule) sort(chart$index[chart[[rule]] %in% TRUE]))
  data.frame(Rule = rules,
             Violations = vapply(rules, function(rule) sum(chart[[rule]] %in% TRUE), integer(1)),
             Positions = vapply(positions, function(x) {
               paste(format(x, scientific = FALSE, trim = TRUE, big.mark = ""), collapse = ", ")
             }, ""),
             row.names = NULL, stringsAsFactors = FALSE)
}
