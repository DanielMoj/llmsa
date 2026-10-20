#' @keywords internal
"_PACKAGE"

# Internal helpers ---------------------------------------------------------

hash_text <- function(x) {
  f <- tempfile()
  on.exit(unlink(f), add = TRUE)
  writeLines(enc2utf8(paste(x, collapse = "\n")), f, useBytes = TRUE)
  unname(tools::md5sum(f))
}

hash_object <- function(x) {
  f <- tempfile()
  on.exit(unlink(f), add = TRUE)
  saveRDS(x, f, version = 2)
  unname(tools::md5sum(f))
}

`%||%` <- function(a, b) if (is.null(a)) b else a

stop_if_missing_cols <- function(x, cols, what = "data") {
  miss <- setdiff(cols, names(x))
  if (length(miss)) {
    stop(sprintf("%s is missing required column(s): %s", what,
                 paste(miss, collapse = ", ")), call. = FALSE)
  }
  invisible(TRUE)
}

fmt_num <- function(x, digits = 4) {
  ifelse(is.na(x), "NA", formatC(x, digits = digits, format = "f"))
}

fmt_pct <- function(x, digits = 1) {
  ifelse(is.na(x), "NA", paste0(formatC(x, digits = digits, format = "f"), " %"))
}

# Render a prompt template: `{text}` and `{item_id}` placeholders, plus any
# extra named fields of the item.
render_prompt <- function(template, fields) {
  out <- template
  for (nm in names(fields)) {
    out <- gsub(paste0("{", nm, "}"), as.character(fields[[nm]]), out, fixed = TRUE)
  }
  out
}

# Coerce items to a canonical data.frame with item_id and text.
as_items <- function(items) {
  if (is.character(items)) {
    ids <- names(items) %||% sprintf("I%03d", seq_along(items))
    ids[ids == ""] <- sprintf("I%03d", which(ids == ""))
    items <- data.frame(item_id = ids, text = unname(items),
                        stringsAsFactors = FALSE)
  }
  if (!is.data.frame(items)) {
    stop("`items` must be a character vector or a data.frame with columns ",
         "`item_id` and `text`.", call. = FALSE)
  }
  if (!"item_id" %in% names(items)) items$item_id <- sprintf("I%03d", seq_len(nrow(items)))
  if (!"text" %in% names(items)) {
    stop("`items` needs a `text` column (the content inserted into the prompt).",
         call. = FALSE)
  }
  items$item_id <- as.character(items$item_id)
  if (anyDuplicated(items$item_id)) stop("`item_id` must be unique.", call. = FALSE)
  items
}

# Coerce a vector of prompts / models into a named character vector.
as_named <- function(x, prefix, default = c("index", "value")) {
  default <- match.arg(default)
  if (!is.character(x) || !length(x)) {
    stop(sprintf("`%s` must be a non-empty character vector.", prefix),
         call. = FALSE)
  }
  nm <- names(x)
  if (is.null(nm)) nm <- rep("", length(x))
  fill <- if (default == "index") paste0(toupper(substr(prefix, 1, 1)), seq_along(x)) else unname(x)
  nm[nm == ""] <- fill[nm == ""]
  if (anyDuplicated(nm)) stop(sprintf("names of `%s` must be unique.", prefix), call. = FALSE)
  stats::setNames(unname(x), nm)
}
