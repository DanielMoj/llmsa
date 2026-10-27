#' Parsers for model responses
#'
#' A parser is a function that turns the raw text response of the backend
#' into a single value: a number, a category label, or `NA` if the response
#' cannot be interpreted. Parse failures are recorded in the run log and
#' reported as part of the validation (a response that cannot be parsed is a
#' failed measurement).
#'
#' @param field For `parse_json_field()`: the name of the field to extract
#'   from a JSON object in the response (the first `{...}` block is used).
#' @param levels For `parse_choice()`: the admissible labels, in the order
#'   that defines the ordinal scale. Matching is case-insensitive; the
#'   longest label occurring in the response wins, so that "likely
#'   pathogenic" is not matched as "pathogenic".
#' @param aliases Optional named list mapping additional strings to labels,
#'   e.g. `list("LP" = "Likely pathogenic")`.
#' @param whole_word If `TRUE`, split at non-alphanumeric characters and
#'   match complete word sequences, longest first. Matched words are consumed;
#'   different labels in one response give `NA`. Repeated matches of the same
#'   label are allowed. The default retains the substring parser.
#' @param decimal Decimal mark for `parse_number()`.
#' @param text The raw response text (argument of the returned parser and of
#'   `parse_identity()`).
#'
#' @return A function with signature `function(text)` returning a length-one
#'   value.
#' @name parsers
#' @examples
#' parse_number()("The IC50 is approximately 12.5 nM.")
#' parse_choice(c("Benign", "Likely benign", "VUS", "Likely pathogenic", "Pathogenic"))(
#'   "Classification: likely pathogenic (PS1, PM2)")
#' parse_json_field("class")('Result: {"class": "VUS", "criteria": ["PM2"]}')
NULL

#' @rdname parsers
#' @export
parse_identity <- function(text) {
  if (is.null(text) || !length(text)) return(NA_character_)
  trimws(as.character(text)[1])
}

#' @rdname parsers
#' @export
parse_number <- function(decimal = ".") {
  force(decimal)
  function(text) {
    if (is.null(text) || !length(text) || is.na(text)) return(NA_real_)
    x <- as.character(text)[1]
    if (decimal == ",") x <- gsub(",", ".", x, fixed = TRUE)
    num <- "[-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?"
    # prefer a number that is not glued to a letter (so "IC50 is 12.5" gives 12.5)
    m <- regmatches(x, regexpr(paste0("(?<![A-Za-z0-9_])", num), x, perl = TRUE))
    if (!length(m)) m <- regmatches(x, regexpr(num, x))
    if (!length(m)) return(NA_real_)
    suppressWarnings(as.numeric(m))
  }
}

#' @rdname parsers
#' @export
parse_choice <- function(levels, aliases = NULL, whole_word = FALSE) {
  levels <- as.character(levels)
  lookup <- stats::setNames(levels, tolower(levels))
  if (!is.null(aliases)) {
    lookup <- c(lookup, stats::setNames(unlist(aliases), tolower(names(aliases))))
  }
  if (!is.logical(whole_word) || length(whole_word) != 1L || is.na(whole_word)) {
    stop("`whole_word` must be TRUE or FALSE.", call. = FALSE)
  }
  if (whole_word) {
    words <- function(x) {
      out <- strsplit(tolower(x), "[^[:alnum:]]+")[[1L]]
      out[nzchar(out)]
    }
    phrases <- lapply(names(lookup), words)
    priority <- order(-lengths(phrases))
    return(function(text) {
      if (is.null(text) || length(text) != 1L || is.na(text)) return(NA_character_)
      tokens <- words(as.character(text))
      labels <- character()
      position <- 1L
      while (position <= length(tokens)) {
        used <- 1L
        for (i in priority) {
          size <- length(phrases[[i]])
          if (size && position + size - 1L <= length(tokens) &&
              identical(tokens[seq.int(position, length.out = size)], phrases[[i]])) {
            labels <- c(labels, unname(lookup[i]))
            used <- size
            break
          }
        }
        position <- position + used
      }
      labels <- unique(labels)
      if (length(labels) == 1L) labels else NA_character_
    })
  }
  # longest keys first so "likely pathogenic" beats "pathogenic"
  keys <- names(lookup)[order(-nchar(names(lookup)))]
  function(text) {
    if (is.null(text) || !length(text) || is.na(text)) return(NA_character_)
    x <- tolower(as.character(text)[1])
    for (k in keys) {
      if (grepl(k, x, fixed = TRUE)) return(unname(lookup[[k]]))
    }
    NA_character_
  }
}

#' @rdname parsers
#' @export
parse_json_field <- function(field) {
  force(field)
  function(text) {
    if (is.null(text) || !length(text) || is.na(text)) return(NA_character_)
    x <- as.character(text)[1]
    # first balanced {...} block
    start <- regexpr("{", x, fixed = TRUE)
    if (start < 0) return(NA_character_)
    chars <- strsplit(substr(x, start, nchar(x)), "")[[1]]
    depth <- 0; end <- NA
    for (i in seq_along(chars)) {
      if (chars[i] == "{") depth <- depth + 1
      if (chars[i] == "}") { depth <- depth - 1; if (depth == 0) { end <- i; break } }
    }
    if (is.na(end)) return(NA_character_)
    json <- paste(chars[seq_len(end)], collapse = "")
    # minimal JSON field extraction without a JSON dependency
    pat <- sprintf('"%s"\\s*:\\s*("([^"\\\\]|\\\\.)*"|[-0-9.eE+]+|true|false|null)', field)
    m <- regmatches(json, regexpr(pat, json, perl = TRUE))
    if (!length(m)) return(NA_character_)
    val <- sub(sprintf('^"%s"\\s*:\\s*', field), "", m, perl = TRUE)
    val <- gsub('^"|"$', "", val)
    gsub('\\\\"', '"', val)
  }
}
