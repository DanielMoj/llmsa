# Small synthetic inputs exercise the preparation rules, not the raw archives.
m1d_data_helpers <- function() {
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  e <- new.env(parent = globalenv())
  sys.source(system.file("validation", "m1d", "prepare.R", package = "llmsa", mustWork = TRUE), envir = e)
  e
}

m1d_data_anchor <- function(id) {
  jsonlite::fromJSON(system.file("validation", "m1d", "anchors", paste0(id, ".json"),
                                package = "llmsa", mustWork = TRUE), simplifyVector = FALSE)$value
}

test_that("label parsing distinguishes words, quotations, ambiguity and missing responses", {
  e <- m1d_data_helpers()
  # Synthetic English phrases, including articles and pronouns, are not raw responses.
  response <- c("A clever question! (I)", "I chose (A).", "A", "The answer is A",
                "(a)", "(A) then (A)", "(A) or (B)", "\"(B)\" then (A)",
                "\"(A)\"", "( A )", "", NA_character_, "(Z)")
  options <- rep(list(c("(A)", "(B)", "(I)")), length(response))
  parsed <- e$m1d_parse_answers(response, options)
  expect_identical(parsed$answer, c("(I)", "(A)", NA, NA, "(A)", "(A)", NA, NA, "(A)", NA, NA, NA, NA))
  expect_identical(parsed$reason, c("parsed", "parsed", "no_label", "no_label", "parsed", "parsed",
                                   "ambiguous", "ambiguous", "parsed", "no_label", "empty", "empty", "no_label"))
  reversed <- e$m1d_parse_answers(rev(response), rev(options))
  expect_identical(rev(reversed$answer), parsed$answer)
  expect_identical(e$m1d_correct(parsed$answer[1:3], c("(I)", "(B)", "(A)")), c(TRUE, FALSE, NA))
  expect_identical(e$m1d_correct(parsed$answer[1:3], c("text key", "(A)", "(B)")), c(FALSE, TRUE, NA))
  expect_error(e$m1d_correct("(A)", NA_character_), "answer key")
  expect_error(e$m1d_parse_answers(response, options[-1L]), "mismatched")
})

test_that("navigation parsing uses whole words and never resolves conflicting labels", {
  e <- m1d_data_helpers()
  response <- c("YES!", "No.", "yesterday", "nope", "No, yes", "yes_yes", "Yes 1", "1yes", "Yes yes")
  parsed <- e$m1d_parse_answers(response, rep(list(c("Yes", "No")), length(response)))
  expect_identical(parsed$answer, c("Yes", "No", NA, NA, NA, NA, "Yes", NA, "Yes"))
  expect_identical(e$m1d_options(c("Choices: (A) red, (B) blue", "Navigate back?"), c("synthetic", "navigate")),
                   list(c("(A)", "(B)"), c("Yes", "No")))
  expect_error(e$m1d_options("no options", "synthetic"), "without option")
})

test_that("complete item grids reject missing, duplicate and conflicting source records", {
  e <- m1d_data_helpers()
  # A synthetic source contract with two models, three runs and two items.
  a <- list(tasks = "synthetic", models = c("m1", "m2"), runs = 0:2,
            items_per_task = list(synthetic = 2L))
  d <- expand.grid(task = a$tasks, model = a$models, run = a$runs, item_id = 0:1,
                    stringsAsFactors = FALSE)
  d$gt <- "(A)"; d$question <- "(A) red, (B) blue"; d$response <- "(A)"
  expect_equal(nrow(e$m1d_validate_llm(d, a)), 2L)
  expect_equal(nrow(e$m1d_validate_llm(d[nrow(d):1, ], a)), 2L)
  expect_error(e$m1d_validate_llm(d[-1L, ], a), "incomplete.*grid")
  expect_error(e$m1d_validate_llm(rbind(d, d[1L, ]), a), "duplicate")
  bad <- d; bad$gt[1L] <- "(B)"
  expect_error(e$m1d_validate_llm(bad, a), "conflicting.*key")
})

test_that("ClinVar filtering precedes distinct submitter counts across input blocks", {
  e <- m1d_data_helpers()
  schema <- m1d_data_anchor("ANK-63")
  spec <- m1d_data_anchor("ANK-47")
  ids <- c(2, 2, 2, 10, 10, 10, 20, 20, 20, 30)
  names <- c("A", "A", "B", "C", "C", "D", "E", "F", "G", "H")
  classes <- rep(spec$classes[[1L]], length(ids))
  classes[c(6L, 10L)] <- "synthetic excluded term"
  header <- paste0("unused", seq_len(schema$n_columns_file))
  header[unlist(schema$columns)] <- names(schema$columns)
  data <- matrix("-", nrow = length(ids), ncol = length(header), dimnames = list(NULL, header))
  data[, "VariationID"] <- ids; data[, "Submitter"] <- names; data[, "ClinicalSignificance"] <- classes
  path <- tempfile(fileext = ".tsv.gz")
  on.exit(unlink(path), add = TRUE)
  write_source <- function(data) {
    con <- gzfile(path, "wt", encoding = "UTF-8")
    on.exit(close(con), add = TRUE)
    writeLines(paste0("#", paste(header, collapse = "\t")), con)
    utils::write.table(data, con, sep = "\t", quote = FALSE, row.names = FALSE, col.names = FALSE)
  }
  write_source(data)
  indexed <- e$m1d_clinvar_index(path, spec, schema, chunk_size = 2L)
  expect_identical(indexed$counts, data.frame(variation_id = c(2L, 10L, 20L), submitters = c(2L, 1L, 3L)))
  expect_identical(indexed$excluded_ids, c(10L, 30L))
  expect_identical(indexed$n_rows, length(ids))
  write_source(data[nrow(data):1, ])
  expect_identical(e$m1d_clinvar_index(path, spec, schema, chunk_size = 3L)$counts, indexed$counts)
  bad <- schema; bad$columns$Submitter <- 1L
  expect_error(e$m1d_clinvar_index(path, spec, bad), "header differs from ANK-63")
})

test_that("ClinVar draws use numeric order and preserve the caller RNG state", {
  e <- m1d_data_helpers()
  # Synthetic sample parameters, not empirical reference constants.
  spec <- list(min_distinct_submitters = 2L, n_variants = 2L, seed = 731L)
  counts <- data.frame(variation_id = c(100L, 2L, 10L, 30L), submitters = c(3L, 2L, 2L, 1L))
  set.seed(17L)
  before <- .Random.seed; kind <- RNGkind()
  draw <- e$m1d_draw_variants(counts, spec)
  expect_identical(e$m1d_draw_variants(counts[4:1, ], spec), draw)
  expect_identical(.Random.seed, before)
  expect_identical(RNGkind(), kind)
  expect_true(all(draw %in% c(2L, 10L, 100L)))
  one <- spec; one$n_variants <- 1L
  expect_identical(e$m1d_draw_variants(counts[1L, ], one), 100L)
  expect_error(e$m1d_draw_variants(counts[1L, ], spec), "too few")
})

test_that("gene joins preserve lists and missing values but reject contradictory assemblies", {
  e <- m1d_data_helpers()
  d <- data.frame(variation_id = c(2L, 1L, 2L, 3L), gene = c("A;B", "C", "A;B", NA_character_))
  mapped <- e$m1d_gene_map(d)
  expect_identical(mapped$gene, c("C", "A;B", NA_character_))
  expect_identical(e$m1d_gene_member(c("AA", "A;B", "C", NA_character_), "A"), c(FALSE, TRUE, FALSE, FALSE))
  expect_true(is.na(mapped$gene[match(4L, mapped$variation_id)]))
  bad <- d; bad$gene[3L] <- "B"
  expect_error(e$m1d_gene_map(bad), "conflicting gene mappings")
  expect_error(e$m1d_ids(c("1", "x")), "invalid VariationID")
})

test_that("dates and UTF-8 gzip CSV survive punctuation and locale changes exactly", {
  e <- m1d_data_helpers()
  schema <- m1d_data_anchor("ANK-63")
  time <- Sys.getlocale("LC_TIME")
  expect_identical(e$m1d_dates(c("Jan 02, 2001", "Dec 31, 2002", "-", NA), schema),
                   c("2001-01-02", "2002-12-31", NA, NA))
  expect_identical(Sys.getlocale("LC_TIME"), time)
  expect_error(e$m1d_dates("invalid date", schema), "unreadable ClinVar")
  path <- tempfile(fileext = ".csv.gz"); other <- tempfile(fileext = ".csv.gz")
  on.exit(unlink(c(path, other)), add = TRUE)
  d <- data.frame(id = c(2L, 1L, 3L), submitter = c('Lab, "B"', "L\u00e4bor", NA_character_),
                   value = c(TRUE, FALSE, NA))
  e$m1d_write_csv(e$m1d_order(d), path)
  collate <- Sys.getlocale("LC_COLLATE")
  on.exit(Sys.setlocale("LC_COLLATE", collate), add = TRUE)
  Sys.setlocale("LC_COLLATE", "C")
  e$m1d_write_csv(e$m1d_order(d[3:1, ]), other)
  expect_identical(e$m1d_sha256(path), e$m1d_sha256(other))
  con <- gzfile(path, "rt", encoding = "UTF-8")
  read <- utils::read.csv(con, na.strings = "", encoding = "UTF-8"); close(con)
  expect_equal(read, e$m1d_order(d))
  expect_identical(readBin(path, "raw", 8L)[5:8], as.raw(rep(0, 4)))
})

test_that("streamed UTF-8 text keeps its literal bytes in the native C locale", {
  e <- m1d_data_helpers()
  work <- tempfile("synthetic-utf8-"); dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  ctype <- Sys.getlocale("LC_CTYPE")
  on.exit(Sys.setlocale("LC_CTYPE", ctype), add = TRUE)
  raw <- file.path(work, "source.tsv.gz")
  con <- gzfile(raw, "wb")
  writeBin(charToRaw(enc2utf8('#ID\tText\n2\tLab, "B"\n1\tL\u00e4bor\n3\t\u4e2d\u6587\n')), con)
  close(con)
  freeze <- function(out) {
    parts <- list()
    e$m1d_stream_tsv(raw, c("ID", "Text"), function(d) parts[[length(parts) + 1L]] <<- d, chunk_size = 1L)
    e$m1d_write_csv(e$m1d_order(do.call(rbind, parts)), out)
  }
  native <- file.path(work, "native.csv.gz"); portable <- file.path(work, "c.csv.gz")
  freeze(native)
  Sys.setlocale("LC_CTYPE", "C")
  expect_warning(freeze(portable), NA)
  expect_identical(e$m1d_sha256(native), e$m1d_sha256(portable))
  con <- gzfile(portable, "rb")
  bytes <- readBin(con, "raw", n = file.info(raw)$size * 10L); close(con)
  expected <- charToRaw(enc2utf8('\"ID\",\"Text\"\n\"1\",\"L\u00e4bor\"\n\"2\",\"Lab, \"\"B\"\"\"\n\"3\",\"\u4e2d\u6587\"\n'))
  expect_identical(bytes, expected)
  # CSV reading needs a text connection for pushBack, without transcoding the
  # stream. The encoding argument marks the resulting strings as UTF-8.
  con <- gzfile(portable, "rt")
  read <- utils::read.csv(con, colClasses = "character", encoding = "UTF-8"); close(con)
  roundtrip <- file.path(work, "roundtrip.csv.gz")
  e$m1d_write_csv(read, roundtrip)
  expect_identical(e$m1d_sha256(portable), e$m1d_sha256(roundtrip))
})

test_that("invalid inputs and size limits leave previously published data intact", {
  e <- m1d_data_helpers()
  work <- tempfile("synthetic-publish-"); dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  target <- file.path(work, "frozen"); stage <- file.path(work, "stage")
  dir.create(target); dir.create(stage)
  writeLines("original", file.path(target, "data.txt"))
  e$m1d_write_text("replacement", file.path(stage, "data.txt"))
  e$m1d_manifest(stage)
  original <- e$m1d_sha256(file.path(target, "data.txt"))
  expect_error(e$m1d_input(work, "missing", "file", "irrelevant"), "quellen")
  limits <- m1d_data_anchor("ANK-TOL")$data_size
  strict <- limits; strict$file_max_bytes <- 1L # Synthetic limit failure.
  expect_error(e$m1d_check_sizes(stage, target, strict), "file exceeds")
  expect_identical(e$m1d_sha256(file.path(target, "data.txt")), original)
  e$m1d_check_sizes(stage, target, limits)
  e$m1d_publish(stage, target)
  expect_identical(readLines(file.path(target, "data.txt")), "replacement")
  expect_setequal(list.files(work), "frozen")
  expect_true(grepl(e$m1d_sha256(file.path(target, "data.txt")), readLines(file.path(target, "SHA256SUMS")), fixed = TRUE))
})
