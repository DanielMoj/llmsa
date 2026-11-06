# Helpers for the M3d acceptance tests (docs/04-weitere-bausteine.md, K-M3d-1
# to K-M3d-6); a setup file for the reason given in setup-acceptance.R.
#
# Reference values come from reference/anchors/ (ANK-93 rounding digits of the
# report template at commit 332a2d5, ANK-94 API recordings, ANK-16 AIAG
# conventions, ANK-54 and ANK-55 routing, ANK-TOL resume_cutpoints,
# parser_cases and arithmetic). The recordings under tests/fixtures/api/ are
# replayed with httr2::local_mocked_responses() through acc_m2_replay()
# (setup-m2.R), which matches the URL and the field `model` of the JSON body as
# in K-M2-4.
# The generators of K-M3d-2 know the expected value of every input they build;
# parse_choice() inputs are checked a second time with the mini-references of
# setup-m2.R, JSON inputs with jsonlite as the oracle of JSON validity. The
# canonical run table and its SHA-256 (K-M3d-5) follow Formelsammlung §11 and
# ACC-12, written independently of R/.
# Interpretations of points on which the spec is silent are listed in
# orchestrator/handoff/M3d/CRITERIA.json under "open" (ACC-n).

acc_m3d <- new.env(parent = emptyenv())   # cache for one test run

# Anchors ------------------------------------------------------------------------

# Nested value of an anchor, e.g. acc_m3d_value("ANK-93", "digits", "variance").
acc_m3d_value <- function(id, ...) {
  path <- c(...)
  v <- acc_anchor(id)$value
  for (k in path) {
    v <- v[[k]]
    if (is.null(v)) stop("acceptance: ", id, " has no value ", paste(path, collapse = "$"), call. = FALSE)
  }
  v
}

acc_m3d_tol <- function(entry, key) {
  e <- acc_anchor("ANK-TOL")$value[[entry]]
  if (is.null(e)) stop("acceptance: ANK-TOL has no entry ", entry, call. = FALSE)
  v <- e[[key]]
  if (is.null(v)) stop("acceptance: ANK-TOL.", entry, " has no key ", key, call. = FALSE)
  v
}

acc_m3d_arith <- function() as.numeric(acc_m3d_tol("arithmetic", "abs_tol"))

# Decimals the template at 332a2d5 fixes for a metric (ANK-93).
acc_m3d_digits <- function(key) as.integer(acc_m3d_value("ANK-93", "digits", key, "decimals"))

# K-M3d-1: resume -------------------------------------------------------------------

# Test parameters of the resume study, no reference values: two items whose ids
# look numeric (a CSV reader that guesses column types turns "001" into 1), two
# prompts, two models, two replicates, two blocks; the mock answers with numbers
# and gives an unparseable text in a share of the calls.
acc_m3d_resume_seed <- 3101L
acc_m3d_resume_truth <- c("001" = 0.8, "010" = -0.4)

acc_m3d_resume_design <- function() {
  items <- data.frame(item_id = names(acc_m3d_resume_truth),
                      text = paste("compound", names(acc_m3d_resume_truth)), stringsAsFactors = FALSE)
  msa_design(items, prompts = c(P1 = "Report the IC50 of {text}.", P2 = "IC50 of {text}, please."),
             models = c(m1 = "model-1", m2 = "model-2"), reps = 2, blocks = 2, order = "random",
             seed = acc_m3d_resume_seed)
}

# A new mock with the same arguments and seed for every run: the resumed run
# models a new R session after the interruption (ACC-2).
acc_m3d_resume_backend <- function() {
  backend_mock(acc_m3d_resume_truth, p_fail = 0.25, seed = acc_m3d_resume_seed)
}

# Wraps a backend so that the call after the first `k` calls is interrupted.
# The condition is an interrupt (as from Ctrl+C), not an error, so msa_run()
# does not record it as a failed call; the caller catches it.
acc_m3d_interrupt_after <- function(backend, k) {
  n <- 0L
  function(prompt, model, row) {
    n <<- n + 1L
    if (n > k) {
      stop(structure(class = c("acc_m3d_interrupt", "interrupt", "condition"),
                     list(message = "acceptance: simulated interruption", call = NULL)))
    }
    backend(prompt, model, row)
  }
}

acc_m3d_run_key <- function(x) paste(x$block, x$item_id, x$prompt_id, x$model_id, x$rep, sep = "|")

# Rows of a store as written: CSV fields as text, SQLite table as stored.
acc_m3d_read_store <- function(path) {
  if (!file.exists(path)) return(NULL)
  if (grepl("\\.sqlite$", path)) {
    con <- DBI::dbConnect(RSQLite::SQLite(), path)
    on.exit(DBI::dbDisconnect(con), add = TRUE)
    if (!"runs" %in% DBI::dbListTables(con)) return(NULL)
    return(DBI::dbReadTable(con, "runs"))
  }
  utils::read.csv(path, colClasses = "character", stringsAsFactors = FALSE)
}

# Store rows without the two time-dependent audit columns, sorted by run key.
acc_m3d_comparable <- function(x) {
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  x <- x[, setdiff(names(x), c("timestamp", "latency_s")), drop = FALSE]
  x <- x[order(acc_m3d_run_key(x), method = "radix"), , drop = FALSE]
  rownames(x) <- NULL
  x
}

# K-M3d-2: random parser inputs ---------------------------------------------------------

acc_m3d_pick <- function(x) x[sample.int(length(x), 1L)]

# Random upper and lower case per character.
acc_m3d_case_mix <- function(s) {
  ch <- strsplit(s, "", fixed = TRUE)[[1]]
  up <- stats::runif(length(ch)) < 0.5
  paste(ifelse(up, toupper(ch), tolower(ch)), collapse = "")
}

# parse_number(): text without any digit is invalid (NA); a valid form holds
# exactly one number not glued to a letter, with sign, decimal mark of the
# parser, optional exponent, a unit and surrounding words. Words and units may
# contain digits glued to letters (IC50, mg/m3), which name things, not values.
acc_m3d_number_prefixes <- c("The IC50 is", "IC50 =", "EC50:", "pIC50 of", "Result:", "Answer:",
                             "Estimated value", "approximately", "about", "Mean:", "value ~",
                             "≈", "Der Wert beträgt", "Wert:", "CYP3A4 activity:",
                             "Concentration (H2O phase):", "**Answer**:")
acc_m3d_number_units <- c("", "", " nM", "nM", " µM", " mg/L", " mg/m3", " µg/mL", " %", "%",
                          " °C", " mmol/l", " ng/ml", " IU", " fold", " m2", " cm3", " kDa")
acc_m3d_number_suffixes <- c("", "", ".", " (estimated).", ", approximately.", "\n", " — see the report.",
                             "!", " in total", "; uncertain.")
acc_m3d_nodigit_words <- c("Not", "determined", "N/A", "n/a", "unknown", "The", "value", "could", "not", "be",
                           "extracted", "Keine", "Angabe", "no", "numeric", "answer", "IC-fifty", "reported",
                           "none", "-", "+", ".", ",", "e", "E", "—", "approximately", "Wert:", "unbekannt",
                           "(", ")", ":", "%", "nM", "mg/L")

acc_m3d_number_case <- function() {
  decimal <- acc_m3d_pick(c(".", ","))
  if (stats::runif(1) < 0.3) {
    text <- if (stats::runif(1) < 0.15) acc_m3d_pick(list(NA_character_, "", " ", "\n"))[[1]] else
      paste(sample(acc_m3d_nodigit_words, sample.int(6L, 1L), replace = TRUE), collapse = acc_m3d_pick(c(" ", " ", "\n", ", ")))
    return(list(text = text, decimal = decimal, valid = FALSE, expected = NA_real_, form = "no number"))
  }
  # signs: hyphen-minus, plus, and in a few cases the minus sign U+2212
  sign <- if (stats::runif(1) < 0.05) "−" else acc_m3d_pick(c("", "", "-", "+"))
  lead_dot <- stats::runif(1) < 0.08
  int <- if (lead_dot) "" else if (stats::runif(1) < 0.15) "0" else
    paste0(sample(1:9, 1L), paste(sample(0:9, sample(0:4, 1L), replace = TRUE), collapse = ""))
  frac <- if (lead_dot || stats::runif(1) < 0.6) paste(sample(0:9, sample.int(5L, 1L), replace = TRUE), collapse = "") else ""
  expo <- if (stats::runif(1) < 0.2) {
    paste0(acc_m3d_pick(c("e", "E")), acc_m3d_pick(c("", "-", "+")), sample(1:9, 1L),
           if (stats::runif(1) < 0.3) sample(0:9, 1L) else "")
  } else ""
  canonical <- paste0(if (sign == "−") "-" else sign, int, if (nzchar(frac)) paste0(".", frac), expo)
  number <- paste0(sign, int, if (nzchar(frac)) paste0(decimal, frac), expo)
  open <- acc_m3d_pick(c("", "", "", "(", "[", "\"", "'"))
  close <- c("(" = ")", "[" = "]", "\"" = "\"", "'" = "'")[open]
  if (is.na(close)) close <- ""
  prefix <- if (stats::runif(1) < 0.7) paste0(acc_m3d_pick(acc_m3d_number_prefixes), acc_m3d_pick(c(" ", " ", "\n", " \t"))) else ""
  text <- paste0(prefix, open, number, acc_m3d_pick(acc_m3d_number_units), close, acc_m3d_pick(acc_m3d_number_suffixes))
  list(text = text, decimal = decimal, valid = TRUE, expected = as.numeric(canonical), form = "one number")
}

# parse_choice(): ANK-69 classes. Default (substring) mode with the aliases that
# no surrounding word contains; whole-word mode with all ANK-69 aliases. Valid:
# one class (possibly repeated, also through another alias of it) in random
# case within surrounding words; invalid: no class, and in whole-word mode two
# different classes (documented NA, K-M2-3).
acc_m3d_choice_words_substring <- c("Classification", "Answer", "Final", "class", "result", "The", "variant",
                                    "is", "considered", "according", "to", "ACMG/AMP", "criteria", "evidence",
                                    "assessment", "Interpretation", "rated", "as", "this", "change", "would",
                                    "be", "Einstufung", "Klasse", "Ergebnis", "per", "guidelines", "with",
                                    "high", "confidence")
acc_m3d_choice_words_whole <- c("Classification", "Answer", "Final", "class", "result", "The", "variant", "is",
                                "considered", "according", "to", "ACMG", "AMP", "criteria", "evidence", "PS1",
                                "PM2", "PP3", "BS1", "BP4", "PVS1", "met", "with", "high", "confidence",
                                "Einstufung", "Klasse", "ist", "per", "guidelines", "rated", "as")
acc_m3d_choice_seps <- c(" ", " ", ": ", " - ", "\n", ", ", ". ", " (", ") ", " **", "** ")

# Classes and aliases (label -> class) of ANK-69, read once per generator run.
acc_m3d_choice_context <- function() {
  al <- acc_m2_aliases()
  list(classes = acc_m2_classes(), whole = al, substring = al[toupper(names(al)) %in% c("VUS", "VOUS", "UNCERTAIN")])
}

acc_m3d_choice_case <- function(ctx) {
  whole_word <- stats::runif(1) < 0.5
  classes <- ctx$classes
  aliases <- if (whole_word) ctx$whole else ctx$substring
  labels <- c(stats::setNames(classes, classes), aliases)       # label -> class
  words <- if (whole_word) acc_m3d_choice_words_whole else acc_m3d_choice_words_substring
  join <- function(w) if (!length(w)) "" else paste0(paste(vapply(w, function(x) paste0(x, acc_m3d_pick(acc_m3d_choice_seps)), ""), collapse = ""))
  around <- function(core) paste0(join(sample(words, sample(0:4, 1L), replace = TRUE)), core,
                                   acc_m3d_pick(acc_m3d_choice_seps), join(sample(words, sample(0:4, 1L), replace = TRUE)))
  u <- stats::runif(1)
  if (u < 0.25) {
    text <- if (stats::runif(1) < 0.15) acc_m3d_pick(list(NA_character_, ""))[[1]] else
      trimws(join(sample(words, sample.int(6L, 1L), replace = TRUE)))
    return(list(text = text, whole_word = whole_word, aliases = aliases, valid = FALSE, expected = NA_character_, form = "no class"))
  }
  if (whole_word && u < 0.35) {
    two <- sample(classes, 2L)
    pick_label <- function(cl) acc_m3d_case_mix(acc_m3d_pick(names(labels)[labels == cl]))
    core <- paste0(pick_label(two[1]), acc_m3d_pick(c(" or ", " / ", ", not ", " vs. ", "\n")), pick_label(two[2]))
    return(list(text = around(core), whole_word = whole_word, aliases = aliases, valid = FALSE,
                expected = NA_character_, form = "two classes"))
  }
  cl <- acc_m3d_pick(classes)
  core <- acc_m3d_case_mix(acc_m3d_pick(names(labels)[labels == cl]))
  if (stats::runif(1) < 0.2) {
    core <- paste0(core, acc_m3d_pick(c(" (", ": ", " - ", "\n")), acc_m3d_case_mix(acc_m3d_pick(names(labels)[labels == cl])))
  }
  list(text = around(core), whole_word = whole_word, aliases = aliases, valid = TRUE, expected = cl, form = "one class")
}

# parse_json_field(): JSON built from members; strings carry escapes (quote,
# backslash, slash, control characters, \u escapes) and braces, brackets,
# colons and commas. Valid: the field is a top-level member with a string or
# number value, inside pure JSON, JSON in text or a code fence; nested objects
# may hold the same key. Invalid: no object, the field missing at the top level
# of the first object, a truncated object, a syntax error (ACC-6).
acc_m3d_json_fields <- c("classification", "class", "value", "result", "label_1", "Klasse")
acc_m3d_json_keys <- c("criteria", "evidence", "note", "reason", "confidence", "score", "details", "gene",
                       "variant", "label", "notes_2", "Begründung")
acc_m3d_json_chars <- c(letters, LETTERS, as.character(0:9), " ", " ", " ", ".", ",", ":", ";", "-", "_",
                        "(", ")", "[", "]", "{", "}", "\"", "\\", "/", "'", "\n", "\t", "é", "ü",
                        "ß", "€", "—", "%", "#", "?", "!")
acc_m3d_text_prefixes <- c("Here is my answer:", "Result", "Sure!", "Die Antwort lautet:", "Answer (JSON):",
                           "Output:", "As requested, the classification:", "**Answer**")
acc_m3d_text_suffixes <- c("Hope this helps.", "Let me know if you need more.", "(end)", "Done.",
                           "Note: based on ACMG/AMP criteria.")

acc_m3d_ws <- function() acc_m3d_pick(c("", "", " ", "\n", "  ", "\t", "\n  ", "\r\n"))

acc_m3d_random_text <- function(min = 0L, max = 20L) {
  n <- sample(min:max, 1L)
  if (!n) return("")
  paste(sample(acc_m3d_json_chars, n, replace = TRUE), collapse = "")
}

# JSON string literal of `s`: quote, backslash and control characters escaped;
# optionally "/" as "\/" and characters above U+007F as \uXXXX.
acc_m3d_json_string <- function(s, unicode = FALSE, slash = FALSE) {
  ch <- strsplit(enc2utf8(s), "", fixed = TRUE)[[1]]
  enc <- vapply(ch, function(c) {
    cp <- utf8ToInt(c)
    if (identical(c, "\"")) "\\\"" else if (identical(c, "\\")) "\\\\" else if (identical(c, "/")) {
      if (slash) "\\/" else "/"
    } else if (cp == 10L) "\\n" else if (cp == 9L) "\\t" else if (cp == 13L) "\\r" else if (cp < 32L) {
      sprintf("\\u%04x", cp)
    } else if (unicode && cp > 127L && cp < 65536L) sprintf("\\u%04x", cp) else c
  }, "", USE.NAMES = FALSE)
  paste0("\"", paste(enc, collapse = ""), "\"")
}

# A JSON number whose text R reproduces with as.character().
acc_m3d_json_number <- function() {
  repeat {
    int <- sample(0:999, 1L)
    txt <- if (stats::runif(1) < 0.5) as.character(int) else
      sprintf("%d.%s", int, paste(sample(0:9, sample.int(3L, 1L), replace = TRUE), collapse = ""))
    if (stats::runif(1) < 0.3) txt <- paste0("-", txt)
    if (identical(as.character(as.numeric(txt)), txt)) return(txt)
  }
}

acc_m3d_json_value <- function(depth, field) {
  kinds <- c("string", "number", "true", "false", "null", "array", "object")
  kind <- sample(kinds, 1L, prob = c(4, 2, 1, 1, 1, 1.5, if (depth < 2L) 1.5 else 0))
  switch(kind,
    string = acc_m3d_json_string(acc_m3d_random_text(), unicode = stats::runif(1) < 0.3, slash = stats::runif(1) < 0.2),
    number = acc_m3d_json_number(),
    true = "true", false = "false", null = "null",
    array = paste0("[", acc_m3d_ws(), paste(vapply(seq_len(sample(0:3, 1L)), function(i) acc_m3d_json_value(depth + 1L, field), ""),
                                       collapse = paste0(acc_m3d_ws(), ",", acc_m3d_ws())), acc_m3d_ws(), "]"),
    object = {
      keys <- sample(acc_m3d_json_keys, sample(0:3, 1L))
      if (stats::runif(1) < 0.3) keys <- c(keys, field)          # nested member with the same key
      members <- lapply(sample(keys), function(k) list(key = acc_m3d_json_string(k), sep = ":",
                                                       value = acc_m3d_json_value(depth + 1L, field)))
      acc_m3d_json_object(members)
    })
}

# Members: list(key = <JSON text of the key>, sep = ":", value = <JSON text>).
acc_m3d_json_object <- function(members, comma = rep(",", max(length(members) - 1L, 0L)), trailing = "") {
  if (!length(members)) return(paste0("{", acc_m3d_ws(), "}"))
  parts <- vapply(members, function(m) paste0(m$key, acc_m3d_ws(), m$sep, acc_m3d_ws(), m$value), "")
  body <- parts[1]
  for (i in seq_along(parts)[-1]) body <- paste0(body, acc_m3d_ws(), comma[i - 1L], acc_m3d_ws(), parts[i])
  paste0("{", acc_m3d_ws(), body, trailing, acc_m3d_ws(), "}")
}

acc_m3d_json_embed <- function(json) {
  switch(acc_m3d_pick(c("pure", "pure", "text", "fence")),
    pure = json,
    text = paste0(acc_m3d_pick(acc_m3d_text_prefixes), acc_m3d_pick(c(" ", "\n", "\n\n")), json,
                  acc_m3d_pick(c("", " ", "\n")), if (stats::runif(1) < 0.5) acc_m3d_pick(acc_m3d_text_suffixes) else ""),
    fence = paste0(if (stats::runif(1) < 0.5) paste0(acc_m3d_pick(acc_m3d_text_prefixes), "\n") else "",
                   "```json\n", json, "\n```", if (stats::runif(1) < 0.5) paste0("\n", acc_m3d_pick(acc_m3d_text_suffixes)) else ""))
}

acc_m3d_json_case <- function(ctx) {
  field <- acc_m3d_pick(acc_m3d_json_fields)
  if (stats::runif(1) < 0.8) {
    raw <- if (stats::runif(1) < 0.5) acc_m3d_pick(ctx$classes) else acc_m3d_random_text(1L, 20L)
    target <- list(kind = "string", raw = raw,
                   json = acc_m3d_json_string(raw, unicode = stats::runif(1) < 0.3, slash = stats::runif(1) < 0.2))
  } else {
    num <- acc_m3d_json_number()
    target <- list(kind = "number", raw = num, json = num)
  }
  others <- lapply(sample(acc_m3d_json_keys, sample(0:4, 1L)), function(k)
    list(key = acc_m3d_json_string(k, unicode = stats::runif(1) < 0.2), sep = ":", value = acc_m3d_json_value(0L, field)))
  tm <- list(key = acc_m3d_json_string(field), sep = ":", value = target$json, target = TRUE)
  members <- append(others, list(tm), after = sample(0:length(others), 1L))
  ti <- which(vapply(members, function(m) isTRUE(m$target), NA))
  valid_json <- acc_m3d_json_object(members)
  u <- stats::runif(1)
  if (u < 0.55) {
    return(list(text = acc_m3d_json_embed(valid_json), field = field, valid = TRUE, expected = target$raw,
                expected_kind = target$kind, json = valid_json, form = "valid"))
  }
  invalid <- function(text, form, json = NULL) list(text = text, field = field, valid = FALSE, expected = NA_character_,
                                                    json = json, form = form)
  if (u < 0.62) {
    text <- if (stats::runif(1) < 0.2) acc_m3d_pick(list(NA_character_, ""))[[1]] else
      paste(acc_m3d_pick(acc_m3d_text_prefixes), gsub("[{}]", "", acc_m3d_random_text(0L, 30L)))
    return(invalid(text, "no object"))
  }
  if (u < 0.72) {
    p <- sample.int(nchar(valid_json) - 1L, 1L)
    return(invalid(paste0(if (stats::runif(1) < 0.5) paste0(acc_m3d_pick(acc_m3d_text_prefixes), " ") else "",
                          substr(valid_json, 1L, p)), "truncated", substr(valid_json, 1L, p)))
  }
  if (u < 0.80) {
    json <- if (length(others) && stats::runif(1) < 0.85) acc_m3d_json_object(others) else paste0("{", acc_m3d_ws(), "}")
    if (stats::runif(1) < 0.3) {
      return(invalid(paste0(json, " and then ", valid_json), "field only in the second object", json))
    }
    return(invalid(acc_m3d_json_embed(json), "field missing", json))
  }
  mutation <- acc_m3d_pick(c("single_quotes", "unquoted_key", "missing_colon", "missing_comma", "trailing_comma",
                             "unterminated_string", "invalid_escape"))
  if (mutation == "missing_comma" && length(members) < 2L) mutation <- "missing_colon"
  if (mutation %in% c("unterminated_string", "invalid_escape") && target$kind != "string") mutation <- "unquoted_key"
  m <- members
  comma <- rep(",", length(m) - 1L)
  trailing <- ""
  switch(mutation,
    single_quotes = { m[[ti]]$key <- paste0("'", field, "'") },
    unquoted_key = { m[[ti]]$key <- field },
    missing_colon = { m[[ti]]$sep <- " " },
    missing_comma = { comma[min(ti, length(m) - 1L)] <- " " },
    trailing_comma = { trailing <- "," },
    unterminated_string = { m[[ti]]$value <- substr(m[[ti]]$value, 1L, nchar(m[[ti]]$value) - 1L) },
    invalid_escape = { v <- m[[ti]]$value; m[[ti]]$value <- paste0(substr(v, 1L, 1L), "\\x", substr(v, 2L, nchar(v))) })
  json <- acc_m3d_json_object(m, comma = comma, trailing = trailing)
  invalid(acc_m3d_json_embed(json), paste("syntax error:", mutation), json)
}

# `n` cases of a generator under one seed (RNG of docs/01 §5); `ctx` holds the
# anchor values the generator needs.
acc_m3d_cases <- function(generator, n, seed, ctx = NULL) {
  acc_m3a_with_seed(seed, lapply(seq_len(n), function(i) if (is.null(ctx)) generator() else generator(ctx)))
}

# K-M3d-2 settings from ANK-TOL.parser_cases.
acc_m3d_parser_n <- function() as.integer(acc_m3d_tol("parser_cases", "n"))
acc_m3d_parser_seed <- function() as.integer(acc_m3d_tol("parser_cases", "seed"))

# Result of a parser call or the error it raised.
acc_m3d_try <- function(f, text) tryCatch(f(text), error = function(e) e)

# Short printable form of a case for failure messages.
acc_m3d_show <- function(case, result) {
  r <- if (inherits(result, "error")) paste("error:", conditionMessage(result)) else paste(format(result), collapse = " ")
  sprintf("[%s] %s -> %s (expected %s)", case$form, encodeString(format(case$text), quote = "\""), r, format(case$expected))
}

# K-M3d-3: failures in the replay -------------------------------------------------------

# Text of the messages in a request body (OpenAI form "content": "..." and the
# content parts of ellmer).
acc_m3d_request_text <- function(req) {
  raw <- httr2::req_dry_run(req, quiet = TRUE)$body
  txt <- if (is.raw(raw)) rawToChar(raw) else as.character(raw)
  body <- jsonlite::fromJSON(txt, simplifyVector = FALSE)
  paste(unlist(lapply(body$messages, function(m) m$content)), collapse = " ")
}

# The recorded llama.json body with message.content set to JSON null or "".
acc_m3d_empty_body <- function(content) {
  rec <- jsonlite::fromJSON(file.path(acc_m2_fixture_dir(), "llama.json"), simplifyVector = FALSE)
  rec$choices[[1]]$message["content"] <- list(content)
  charToRaw(as.character(jsonlite::toJSON(rec, auto_unbox = TRUE, null = "null", digits = NA)))
}

# Failure kinds of K-M3d-3, selected by a marker "fail:<kind>" in the prompt.
acc_m3d_failure_kinds <- c("http_500", "http_401", "timeout", "empty_body", "null_content", "empty_content")

acc_m3d_failing_replay <- function(sink = new.env()) {
  replay <- acc_m2_replay(sink)
  json <- list("Content-Type" = "application/json")
  function(req) {
    txt <- acc_m3d_request_text(req)
    kind <- regmatches(txt, regexpr("fail:[a-z0-9_]+", txt))
    if (!length(kind)) return(replay(req))
    url <- httr2::req_get_url(req)
    switch(sub("^fail:", "", kind),
      http_500 = httr2::response(status_code = 500L, url = url, method = "POST", headers = json,
                                 body = charToRaw("{\"error\":{\"message\":\"Internal server error\",\"code\":500}}")),
      http_401 = httr2::response(status_code = 401L, url = url, method = "POST", headers = json,
                                 body = charToRaw("{\"error\":{\"message\":\"No auth credentials found\",\"code\":401}}")),
      timeout = stop(errorCondition("Timeout was reached [openrouter.ai]: Operation timed out after 120002 milliseconds with 0 bytes received",
                                    class = c("curl_error_operation_timedout", "curl_error"))),
      empty_body = httr2::response(status_code = 200L, url = url, method = "POST", headers = json, body = raw()),
      null_content = httr2::response(status_code = 200L, url = url, method = "POST", headers = json, body = acc_m3d_empty_body(NULL)),
      empty_content = httr2::response(status_code = 200L, url = url, method = "POST", headers = json, body = acc_m3d_empty_body("")),
      stop("acceptance: unknown failure kind ", kind, call. = FALSE))
  }
}

# Design for the failure runs: a normal call, one call per failure kind, a normal call.
acc_m3d_failure_design <- function(model) {
  kinds <- c("ok_first", acc_m3d_failure_kinds, "ok_last")
  text <- ifelse(startsWith(kinds, "ok_"), paste("PAH NM_000277.2:c.1A>G", kinds), paste0("variant [fail:", kinds, "]"))
  msa_design(data.frame(item_id = kinds, text = text, stringsAsFactors = FALSE),
             prompts = c(concise = "Classify {text}."), models = c(llama = model), reps = 1, blocks = 1, order = "fixed")
}

# ellmer chat objects for the three recordings (chat-completions endpoint,
# BL-60): base URL and model of each recording, a test key.
acc_m3d_ellmer_chats <- function() {
  files <- acc_anchor("ANK-94")$value$files
  keys <- c(sol = "sol.json", llama = "llama.json", qwen = "qwen.json")
  lapply(keys, function(f) ellmer::chat_openai_compatible(base_url = sub("/chat/completions$", "", files[[f]]$request_url),
                                                          model = files[[f]]$request_model,
                                                          credentials = function() "acc-test-key", echo = "none"))
}

# K-M3d-4 to K-M3d-6: report fixtures -----------------------------------------------

# Seeds of the report study (test parameters, named in the report by K-M3d-6).
acc_m3d_study_seeds <- c(design = 314159L, bootstrap = 271828L, plackett_burman = 161803L)

# Numeric study through msa_design(), msa_run() and backend_mock(), with a
# reference column for the bias; fitted once per test run.
acc_m3d_numeric_study <- function() {
  if (!is.null(acc_m3d$numeric)) return(acc_m3d$numeric)
  ids <- sprintf("I%02d", 1:12)
  truth <- stats::setNames(seq(-1.65, 1.65, length.out = 12L), ids)
  items <- data.frame(item_id = ids, text = paste("sample", ids), reference = unname(truth) + 0.1,
                      stringsAsFactors = FALSE)
  d <- msa_design(items, prompts = c(P1 = "IC50 of {text}?", P2 = "Report the IC50 for {text}.", P3 = "{text}: IC50"),
                  models = c(ma = "model-a", mb = "model-b", mc = "model-c"), reps = 2, blocks = 2,
                  seed = acc_m3d_study_seeds[["design"]])
  runs <- msa_run(d, backend_mock(truth, sd_prompt = 0.25, sd_model = 0.3, sd_rep = 0.2, seed = 4242L),
                  parse = parse_number(), verbose = FALSE)
  fit <- suppressMessages(suppressWarnings(msa_fit(runs, type = "numeric")))
  acc_m3d$numeric <- list(design = d, runs = runs, fit = fit, grr = msa_grr(fit))
  acc_m3d$numeric
}

# Ordinal study with a reference for agreement, accuracy and Fleiss' kappa
# (every item has the same number of valid ratings).
acc_m3d_agreement <- function() {
  if (!is.null(acc_m3d$agreement)) return(acc_m3d$agreement)
  classes <- acc_m2_classes()
  ids <- sprintf("V%02d", 1:10)
  truth <- stats::setNames(seq(-2.2, 2.2, length.out = 10L), ids)
  cuts <- c(-1.5, -0.5, 0.5, 1.5)
  items <- data.frame(item_id = ids, text = paste("variant", ids), reference = classes[findInterval(truth, cuts) + 1L],
                      stringsAsFactors = FALSE)
  d <- msa_design(items, prompts = c(concise = "Classify {text}.", role = "As a geneticist, classify {text}."),
                  models = c(ma = "model-a", mb = "model-b"), reps = 3, blocks = 1, seed = 5151L)
  runs <- msa_run(d, backend_mock(truth, levels = classes, thresholds = cuts, sd_prompt = 0.3, sd_model = 0.3,
                                  sd_rep = 0.4, seed = 5152L), parse = parse_choice(classes), verbose = FALSE)
  acc_m3d$agreement <- msa_agreement(runs, levels = classes, reference = "reference", weights = "linear", fleiss = TRUE)
  acc_m3d$agreement
}

acc_m3d_boot <- function() {
  if (is.null(acc_m3d$boot)) {
    acc_m3d$boot <- suppressMessages(suppressWarnings(
      msa_boot(acc_m3d_numeric_study()$fit, nsim = 4, seed = acc_m3d_study_seeds[["bootstrap"]])))
  }
  acc_m3d$boot
}

acc_m3d_bias <- function() {
  if (is.null(acc_m3d$bias)) acc_m3d$bias <- suppressMessages(msa_bias(acc_m3d_numeric_study()$runs, "reference"))
  acc_m3d$bias
}

acc_m3d_robustness <- function() {
  if (!is.null(acc_m3d$robustness)) return(acc_m3d$robustness)
  f <- list(format = c("plain", "table"), units = c("nM", "ng/mL"), typos = c("none", "two"), context = c("none", "extra"),
            system = c("A", "B"), order = c("asc", "desc"), language = c("en", "de"))
  d <- pb_design(f, n_runs = 8, seed = acc_m3d_study_seeds[["plackett_burman"]])
  y <- acc_m3a_with_seed(6161L, 0.9 - 0.08 * (d$typos > 0) - 0.03 * (d$context > 0) + stats::rnorm(8L, 0, 0.01))
  acc_m3d$robustness <- msa_robustness(d, y)
  acc_m3d$robustness
}

# Control values on the z scale (center 0, sd 1) that make every Westgard rule fire.
acc_m3d_chart <- function() {
  x <- c(0.5, 0.3, 2.4, 2.2, 0.4, 3.5, -1.2, 0.6, 1.2, 1.4, 1.3, 1.6, 0.8, 0.2,
         -0.3, -0.5, -0.2, -0.8, -0.4, -0.6, -0.1, -0.9, -0.3, -0.7)
  msa_control_chart(x, center = 0, sd = 1)
}

# Ordinal fits with one derived two-level source (model or block, K-M1b-4).
acc_m3d_derived_grr <- function(factor = c("model", "block")) {
  factor <- match.arg(factor)
  key <- paste0("derived_", factor)
  if (is.null(acc_m3d[[key]])) {
    runs <- if (factor == "model") {
      acc_m1b_ordinal_runs(seed = 41L, items = 15L, prompts = 3L, models = 2L, reps = 2L)
    } else {
      acc_m1b_ordinal_runs(seed = 42L, items = 15L, prompts = 3L, models = 3L, reps = 1L, blocks = 2L)
    }
    fit <- acc_m1b_catch(msa_fit(runs, type = "ordinal", levels = acc_m1b_ordinal_levels()))$value
    acc_m3d[[key]] <- if (inherits(fit, "error")) fit else msa_grr(fit)
  }
  acc_m3d[[key]]
}

# Runs of the three recorded models through msa_run() (two items each); one
# llama row reports a second serving provider (a constructed provider switch).
acc_m3d_second_provider <- "AccTestHost"

acc_m3d_meta_runs <- function() {
  if (!is.null(acc_m3d$meta_runs)) return(acc_m3d$meta_runs)
  s <- acc_m2_model_settings()
  d <- msa_design(data.frame(item_id = c("v1", "v2"), text = c("PAH NM_000277.2:c.1A>G", "BRCA1 NM_007294.4:c.68_69del"),
                             stringsAsFactors = FALSE),
                  prompts = c(concise = "Classify {text}."),
                  models = c(sol = s$sol$model, llama = s$llama$model, qwen = s$qwen$model),
                  reps = 1, blocks = 1, order = "fixed")
  backends <- lapply(s, acc_m2_backend)
  bk <- function(prompt, model, row) backends[[row$model_id]](prompt, model, row)
  httr2::local_mocked_responses(acc_m2_replay(new.env()))
  runs <- msa_run(d, bk, parse = parse_choice(acc_m2_classes(), whole_word = TRUE), verbose = FALSE)
  i <- which(runs$model_id == "llama")[2]
  meta <- jsonlite::fromJSON(runs$meta[i], simplifyVector = FALSE)
  meta$provider <- acc_m3d_second_provider
  runs$meta[i] <- as.character(jsonlite::toJSON(meta, auto_unbox = TRUE, null = "null", digits = NA))
  acc_m3d$meta_runs <- runs
  runs
}

# Distinct values of a meta field per model id, from the JSON in the runs.
acc_m3d_meta_values <- function(runs, model_id, field) {
  js <- runs$meta[runs$model_id == model_id]
  v <- unlist(lapply(js[!is.na(js)], function(x) jsonlite::fromJSON(x, simplifyVector = FALSE)[[field]]))
  unique(as.character(v))
}

# K-M3d-5: run table with every column type and awkward text (test data).
acc_m3d_hash_runs <- function() {
  g <- expand.grid(rep = 1:2, model_id = c("m-a", "m_b"), prompt_id = c("P1", "P2"), item_id = c("I10", "I2", "i3"),
                   block = 1:2, stringsAsFactors = FALSE)
  n <- nrow(g)
  d <- data.frame(block = g$block, item_id = g$item_id, prompt_id = g$prompt_id, model_id = g$model_id,
                  rep = g$rep, stringsAsFactors = FALSE)
  d$value <- sprintf("%.3f", seq_len(n) / 7)
  d$value[c(5L, 17L)] <- NA
  d$response <- paste0("Answer ", seq_len(n), ": \"quoted\", comma; éüß €")
  d$response[3L] <- "line one\nline two"
  d$response[9L] <- NA
  d$latency_s <- seq_len(n) / 3
  d$latency_s[4L] <- 1e-20
  d$latency_s[6L] <- 123456789.123456789
  d$latency_s[8L] <- -0.5
  d$latency_s[10L] <- NA
  d$error <- NA_character_
  d$error[7L] <- "HTTP 500 Internal Server Error."
  d$position <- seq_len(n)
  d$flag <- seq_len(n) %% 3L == 0L
  d$flag[11L] <- NA
  d$tier <- factor(rep(c("low", "high"), length.out = n))
  d[["Z column"]] <- seq_len(n) * 1e6
  as_msa_runs(d)
}

# Mini-reference of the canonical form (Formelsammlung §11, ACC-12): header and
# one line per row; the five sort keys first, then every other column in byte
# order of its name; text quoted with doubled quotes, numbers with %.17g,
# integers in decimal digits, logical TRUE/FALSE, missing values NA unquoted;
# rows sorted by block, item, prompt, model, replicate (numeric keys by value,
# text keys by bytes), ties by the bytes of the line.
acc_m3d_csv_text <- function(x) {
  x <- as.character(x)
  out <- paste0("\"", gsub("\"", "\"\"", enc2utf8(x), fixed = TRUE), "\"")
  out[is.na(x)] <- "NA"
  out
}

acc_m3d_canonical_cells <- function(col) {
  if (is.logical(col)) return(ifelse(is.na(col), "NA", ifelse(col, "TRUE", "FALSE")))
  if (is.factor(col)) return(acc_m3d_csv_text(as.character(col)))
  if (is.integer(col)) return(ifelse(is.na(col), "NA", as.character(col)))
  if (is.numeric(col)) return(sprintf("%.17g", col))
  acc_m3d_csv_text(as.character(col))
}

acc_m3d_canonical_lines <- function(runs) {
  d <- runs
  attributes(d) <- attributes(d)[c("names", "row.names")]
  class(d) <- "data.frame"
  keys <- c("block", "item_id", "prompt_id", "model_id", "rep")
  cols <- c(keys, sort(setdiff(names(d), keys), method = "radix"))
  cells <- lapply(d[cols], acc_m3d_canonical_cells)
  body <- do.call(paste, c(unname(cells), sep = ","))
  key_values <- lapply(keys, function(k) if (is.numeric(d[[k]])) d[[k]] else as.character(d[[k]]))
  ord <- do.call(order, c(unname(key_values), list(body), list(method = "radix", na.last = TRUE)))
  c(paste(acc_m3d_csv_text(cols), collapse = ","), body[ord])
}

acc_m3d_canonical_sha256 <- function(runs) {
  doc <- enc2utf8(paste0(paste(acc_m3d_canonical_lines(runs), collapse = "\n"), "\n"))
  digest::digest(charToRaw(doc), algo = "sha256", serialize = FALSE)
}

# Rendering and parsing the report -------------------------------------------------

# msa_report(...) rendered as GitHub Markdown without line wrapping; the lines,
# or the error the call raised. Cached per key.
acc_m3d_report <- function(key, ...) {
  cache <- paste0("report_", key)
  if (!is.null(acc_m3d[[cache]])) return(acc_m3d[[cache]])
  out <- tempfile("acc-m3d-report-", fileext = ".md")
  on.exit(unlink(out), add = TRUE)
  res <- acc_m3a_conditions(msa_report(..., output_file = out, quiet = TRUE,
                                       output_format = rmarkdown::md_document(variant = "gfm", pandoc_args = "--wrap=none")))
  value <- if (inherits(res$value, "error")) res$value else readLines(out, warn = FALSE, encoding = "UTF-8")
  acc_m3d[[cache]] <- value
  value
}

# The report of the numeric study with every object except a control chart.
acc_m3d_report_main <- function() {
  s <- acc_m3d_numeric_study()
  acc_m3d_report("main", s$grr, runs = s$runs, boot = acc_m3d_boot(), agreement = acc_m3d_agreement(),
                 bias = acc_m3d_bias(), robustness = acc_m3d_robustness())
}

# The report with a control chart (new last argument control_chart, ACC-11).
acc_m3d_report_chart <- function() {
  acc_m3d_report("chart", acc_m3d_numeric_study()$grr, control_chart = acc_m3d_chart())
}

acc_m3d_report_ok <- function(lines, what) {
  testthat::expect_false(inherits(lines, "error"),
                         label = sprintf("msa_report() renders the %s report (%s)", what,
                                         if (inherits(lines, "error")) conditionMessage(lines) else "ok"))
  !inherits(lines, "error")
}

# Text for comparison: Markdown escapes, emphasis and code marks removed, curly
# quotes straightened, dashes and the minus sign as "-", spaces collapsed.
acc_m3d_norm <- function(x) {
  x <- gsub(" ", " ", x, fixed = TRUE)
  x <- gsub("\\\\([[:punct:]])", "\\1", x)
  x <- gsub("[*`]", "", x)
  x <- gsub("[‘’]", "'", x)
  x <- gsub("[“”]", "\"", x)
  x <- gsub("[‐-―−]", "-", x)
  trimws(gsub("[[:space:]]+", " ", x))
}

# Lines of the level-2 section whose header matches `title` (case-insensitive,
# number optional), up to the next level-2 header; NULL if none or several.
acc_m3d_section <- function(lines, title) {
  h2 <- grepl("^##[[:space:]]", lines)
  hit <- which(h2 & grepl(paste0("(?i)^##\\s+(\\d+\\.\\s*)?", title), lines, perl = TRUE))
  if (length(hit) != 1L) return(NULL)
  stop_at <- which(h2 & seq_along(lines) > hit)
  lines[seq(hit, if (length(stop_at)) stop_at[1] - 1L else length(lines))]
}

acc_m3d_section_or_fail <- function(lines, title, what) {
  sec <- acc_m3d_section(lines, title)
  testthat::expect_false(is.null(sec), label = sprintf("the report has exactly one level-2 section %s", what))
  sec
}

# Cells of a pipe-table row (escaped pipes kept inside a cell), normalized.
acc_m3d_row_cells <- function(line) {
  x <- gsub("\\|", "\u0001", line, fixed = TRUE)
  x <- sub("^[[:space:]]*\\|", "", x)
  x <- sub("\\|[[:space:]]*$", "", x)
  cells <- strsplit(x, "|", fixed = TRUE)[[1]]
  acc_m3d_norm(gsub("\u0001", "|", cells, fixed = TRUE))
}

acc_m3d_tables <- function(lines) {
  is_row <- grepl("^[[:space:]]*\\|", lines)
  r <- rle(is_row)
  ends <- cumsum(r$lengths)
  starts <- ends - r$lengths + 1L
  out <- list()
  for (i in which(r$values)) {
    block <- lines[starts[i]:ends[i]]
    if (length(block) < 2L || !grepl("^[[:space:]]*\\|[-:| ]+\\|?[[:space:]]*$", block[2])) next
    out[[length(out) + 1L]] <- list(header = acc_m3d_row_cells(block[1]), rows = lapply(block[-(1:2)], acc_m3d_row_cells))
  }
  out
}

# The first table whose header holds every name in `columns` (case-insensitive).
acc_m3d_table <- function(lines, columns) {
  for (t in acc_m3d_tables(lines)) if (all(tolower(columns) %in% tolower(t$header))) return(t)
  NULL
}

acc_m3d_cell <- function(table, row, column) {
  j <- match(tolower(column), tolower(table$header))
  if (is.na(j) || j > length(row)) NA_character_ else row[[j]]
}

# Rows of a table whose cell in `column` equals `value` (after normalization).
acc_m3d_rows <- function(table, column, value) {
  Filter(function(r) identical(acc_m3d_cell(table, r, column), acc_m3d_norm(value)), table$rows)
}

# Numbers as the template prints them: decimal or NA/Inf.
acc_m3d_num_re <- "(-?[0-9]+(?:\\.[0-9]+)?|NA|-?Inf|NaN)"

# All matches of `pattern` (with capture groups) in normalized non-table lines.
acc_m3d_matches <- function(lines, pattern) {
  n <- acc_m3d_norm(lines[!grepl("^[[:space:]]*\\|", lines)])
  m <- regmatches(n, regexec(pattern, n, perl = TRUE))
  Filter(length, m)
}

acc_m3d_decimals <- function(s) if (grepl(".", s, fixed = TRUE)) nchar(sub("^[^.]*\\.", "", s)) else 0L

# A printed number equals the object value after rounding to `digits` decimals:
# the printed form has exactly `digits` decimals (ANK-93) and lies within half a
# unit of the last printed digit (docs/01 §2 Nr. 6) plus ANK-TOL.arithmetic.
acc_m3d_expect_rounded <- function(shown, value, digits, label) {
  shown <- trimws(shown)
  if (length(value) != 1L || is.na(value)) {
    testthat::expect_identical(shown, "NA", label = sprintf("%s: printed value for a missing object value", label))
    return(invisible())
  }
  form <- grepl("^-?[0-9]+(\\.[0-9]+)?$", shown)
  testthat::expect_true(form, label = sprintf("%s: printed %s is a decimal number", label, encodeString(shown, quote = "\"")))
  if (!form) return(invisible())
  testthat::expect_identical(acc_m3d_decimals(shown), as.integer(digits),
                             label = sprintf("%s: decimals of the printed %s (ANK-93: %d)", label, shown, digits))
  testthat::expect_lte(abs(as.numeric(shown) - value), 0.5 * 10^(-digits) + acc_m3d_arith(),
                       label = sprintf("%s: |printed %s - object %.15g|", label, shown, value))
}

# Integers of a text, in order; digits of a decimal number do not count, a
# full stop after the integer (end of a sentence) does not prevent it.
acc_m3d_integers <- function(x) {
  as.integer(unlist(regmatches(x, gregexpr("(?<![0-9])(?<![0-9]\\.)[0-9]+(?![0-9])(?!\\.[0-9])", x, perl = TRUE))))
}

# A standalone number in a text (not part of a longer or decimal number).
acc_m3d_has_number <- function(text, value) {
  grepl(paste0("(?<![0-9])(?<![0-9]\\.)", gsub(".", "\\.", format(value), fixed = TRUE), "(?![0-9])(?!\\.[0-9])"), text, perl = TRUE)
}

# Data hash of the report: the 64-digit hex values on lines that name SHA-256
# and the data or run table.
acc_m3d_report_hashes <- function(lines) {
  n <- acc_m3d_norm(lines)
  hit <- grepl("(?i)sha-?256", n, perl = TRUE) & grepl("(?i)data|run", n, perl = TRUE)
  h <- unlist(regmatches(n[hit], gregexpr("(?<![0-9a-fA-F])[0-9a-fA-F]{64}(?![0-9a-fA-F])", n[hit], perl = TRUE)))
  unique(tolower(h))
}
