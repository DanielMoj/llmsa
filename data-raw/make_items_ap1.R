#!/usr/bin/env Rscript
# Freeze AP1 from operator-provided sources. No network or synthetic fallback.
# Selection, schema and provenance: ADR-005. Seed: ANK-59.
main <- function() {
  root <- normalizePath(getwd())
  raw_root <- file.path(dirname(root), "quellen", "daten")
  if (!dir.exists(raw_root)) stop("AP1 requires ../quellen/daten/; no output changed.", call. = FALSE)
  for (p in c("jsonlite", "digest")) if (!requireNamespace(p, quietly = TRUE)) {
    stop("AP1 data generation requires the frozen package ", p, ".", call. = FALSE)
  }
  anchor <- function(id) {
    path <- file.path(root, "reference", "anchors", paste0("ANK-", id, ".json"))
    if (!file.exists(path)) stop("Missing AP1 anchor: ", path, call. = FALSE)
    jsonlite::fromJSON(path, simplifyVector = FALSE)
  }
  a <- function(id) anchor(id)$value
  helpers <- new.env(parent = globalenv())
  for (file in c("utils.R", "backends.R", "parse.R", "acmg.R")) sys.source(file.path(root, "R", file), helpers)
  classes <- unlist(a(69)$classes, use.names = FALSE)
  parser <- helpers$acmg_parser(list(classes = classes, aliases = a(69)$aliases))
  input <- c(erepo = file.path(raw_root, "clingen-erepo_2026-10-22", a(51)$file),
             insaid = file.path(raw_root, "insaid-vangijn2018_2026-10-23", a(52)$file),
             clinvar = file.path(raw_root, "clinvar_2026-10-22", "submission_summary.txt.gz"))
  want_hash <- c(erepo = a(51)$file_sha256, insaid = a(52)$sha256,
                 clinvar = a(41)$files[["submission_summary.txt.gz"]]$sha256)
  for (nm in names(input)) {
    if (!file.exists(input[[nm]])) stop("Missing quellen input: ", nm, call. = FALSE)
    if (!identical(helpers$acmg_hash(input[[nm]]), want_hash[[nm]])) stop("quellen SHA-256 mismatch: ", nm, call. = FALSE)
  }
  er <- utils::read.delim(input[["erepo"]], quote = "", comment.char = "", check.names = FALSE,
                          colClasses = "character", na.strings = character(), fileEncoding = "UTF-8")
  pool <- helpers$acmg_erepo_pool(er, a(50), parser)
  helpers$acmg_check_pool(pool, a(51)$pool, parser)
  ins <- utils::read.delim(input[["insaid"]], quote = "", comment.char = "#", check.names = FALSE,
                           colClasses = "character", na.strings = character(), fileEncoding = "UTF-8")
  helpers$stop_if_missing_cols(ins, unlist(a(52)$columns), "INSAID quellen")
  if (nrow(ins) != a(52)$variants_total || sum(ins$status == a(59)$insaid_status) != a(52)$validated ||
      anyDuplicated(paste(ins$gene, ins$cdna))) stop("Invalid INSAID quellen schema or counts.", call. = FALSE)
  ins <- ins[ins$status == a(59)$insaid_status & ins$gene %in% unlist(a(59)$insaid_genes), ]
  ins$reference <- vapply(ins$classification, parser, "", USE.NAMES = FALSE)
  if (anyNA(ins$reference)) stop("Invalid INSAID classification.", call. = FALSE)
  ins <- ins[order(ins$gene, ins$cdna, method = "radix"), ]
  selection <- helpers$acmg_seeded(a(59)$seed, {
    er_parts <- lapply(classes, function(cl) helpers$acmg_round_robin(pool[pool$reference == cl, ], "panel",
                                                                     a(59)$erepo_per_class + a(67)$pilot_per_class))
    in_parts <- lapply(classes, function(cl) helpers$acmg_round_robin(ins[ins$reference == cl, ], "gene", a(59)$insaid_per_class))
    list(main = do.call(rbind, lapply(er_parts, function(d) head(d, a(59)$erepo_per_class))),
         pilot = do.call(rbind, lapply(er_parts, function(d) tail(d, a(67)$pilot_per_class))),
         insaid = do.call(rbind, in_parts))
  })
  er_selected <- rbind(selection$main, selection$pilot)
  ids <- unique(er_selected$clinvar_id)
  layout <- a(63)
  con <- gzfile(input[["clinvar"]], "rt", encoding = "UTF-8")
  on.exit(close(con), add = TRUE)
  kept <- list(); n <- 0L; header <- NULL
  repeat {
    chunk <- readLines(con, n = 100000L, warn = FALSE)
    if (!length(chunk)) break
    if (is.null(header)) {
      head_line <- chunk[startsWith(chunk, layout$header_line_prefix)]
      if (length(head_line)) header <- strsplit(sub("^#", "", head_line[1]), "\t", fixed = TRUE)[[1]]
    }
    chunk <- chunk[!startsWith(chunk, "#")]
    hit <- sub("\t.*$", "", chunk) %in% ids
    if (any(hit)) { n <- n + 1L; kept[[n]] <- chunk[hit] }
  }
  if (is.null(header) || length(header) != layout$n_columns_file) stop("Invalid ClinVar quellen header.", call. = FALSE)
  for (nm in names(layout$columns)) if (!identical(header[layout$columns[[nm]]], nm)) {
    stop("ClinVar quellen column differs from ANK-63: ", nm, call. = FALSE)
  }
  entries <- strsplit(unlist(kept, use.names = FALSE), "\t", fixed = TRUE)
  if (any(lengths(entries) < max(unlist(layout$columns)))) stop("Truncated ClinVar quellen row.", call. = FALSE)
  rows <- as.data.frame(lapply(layout$columns, function(k) vapply(entries, `[`, "", k)), stringsAsFactors = FALSE)
  rows$date <- helpers$acmg_clinvar_dates(rows$DateLastEvaluated)
  cutoffs <- c(sol = a(50), llama = a(65), qwen = a(66))
  fallbacks <- 0L
  for (s in names(cutoffs)) {
    flags <- lapply(seq_len(nrow(er_selected)), function(i) {
      helpers$acmg_prior(rows[rows$VariationID == er_selected$clinvar_id[i], ], cutoffs[[s]],
                         er_selected$panel[i], er_selected$reference[i], classes, layout$expert_panel_review_status)
    })
    er_selected[[paste0("prior_clinvar_class_", s)]] <- vapply(flags, `[[`, "", "class")
    er_selected[[paste0("prior_date_", s)]] <- vapply(flags, `[[`, "", "date")
    er_selected[[paste0("prior_differs_", s)]] <- vapply(flags, function(x) as.character(x$differs), "")
    fallbacks <- fallbacks + sum(vapply(flags, `[[`, logical(1), "panel_fallback"))
  }
  make_ids <- function(source, gene, hgvs) paste0(source, "-", vapply(paste(source, gene, hgvs, sep = "|"),
        function(x) substr(digest::digest(x, algo = "sha256", serialize = FALSE), 1, 16), "", USE.NAMES = FALSE))
  er_selected$source <- "erepo"
  er_selected$item_id <- make_ids("erepo", er_selected$gene, er_selected$hgvs)
  in_selected <- selection$insaid
  tx <- unlist(a(64))
  in_selected$transcript <- unname(tx[in_selected$gene])
  in_selected$hgvs <- paste0(in_selected$transcript, ":", in_selected$cdna)
  in_selected$source <- "insaid"
  in_selected$item_id <- make_ids("insaid", in_selected$gene, in_selected$hgvs)
  # Only variant identifiers leave memory. IDs and final order never encode class.
  in_selected$reference <- in_selected$protein <- in_selected$panel <- ""
  for (col in helpers$acmg_columns()[9:17]) in_selected[[col]] <- ""
  columns <- helpers$acmg_columns()
  main <- rbind(er_selected[seq_len(nrow(selection$main)), columns], in_selected[, columns])
  pilot <- er_selected[nrow(selection$main) + seq_len(nrow(selection$pilot)), columns]
  main <- main[order(main$item_id, method = "radix"), ]; pilot <- pilot[order(pilot$item_id, method = "radix"), ]
  if (nrow(main) != a(59)$items_total || nrow(pilot) != a(67)$pilot_items ||
      anyDuplicated(c(main$item_id, pilot$item_id))) stop("Invalid AP1 selection counts or identities.", call. = FALSE)
  stage <- tempfile("ap1-freeze-"); dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  for (nm in c("items.csv", "pilot.csv")) utils::write.table(if (nm == "items.csv") main else pilot,
     file.path(stage, nm), sep = ",", row.names = FALSE, col.names = TRUE, na = "", qmethod = "double", fileEncoding = "UTF-8", eol = "\n")
  q <- c("AP1 item set frozen under ADR-005 and the M2 Golden ADR.",
         paste("ERepo snapshot:", a(51)$stand), paste("ERepo URL:", anchor(51)$source_url),
         "ERepo license: CC0 1.0; attribution: ClinGen Variant Curation Expert Panels.",
         paste("ERepo SHA-256:", want_hash[["erepo"]]),
         paste("ClinVar snapshot:", a(41)$stand), paste("ClinVar URL:", anchor(41)$source_url),
         paste("ClinVar submission_summary SHA-256:", want_hash[["clinvar"]]),
         "ClinVar: public NCBI submission metadata; dates use DateLastEvaluated (ANK-63).",
         paste("INSAID SHA-256:", a(52)$sha256),
         paste("INSAID source:", anchor(52)$source_url),
         "INSAID: Van Gijn et al. (2018), doi:10.1136/jmedgenet-2017-105216; March 2017 list.",
         "INSAID references and protein notation remain local (all rights reserved, no commercial use).",
         "INSAID transcript source: publication Methods, PDF page 2 (ANK-64):",
         paste(names(tx), unname(tx), collapse = "; "),
         paste("The Methods MEFV transcript takes precedence; Table 1 contradicts it with", unlist(anchor(64)$table1_contradiction), "."),
         "Selection: non-retracted ERepo NM c. classifications approved and published strictly after ANK-50;",
         "panels ranked by candidate count within class, seeded ties and candidates, round-robin without replacement.",
         "Pilot continues the same selection. INSAID uses Validated variants and the analogous gene round-robin.",
         paste("Seed:", a(59)$seed, "(ANK-59); RNG: Mersenne-Twister / Inversion / Rejection; radix sorting; UTF-8/LF."),
         "Prior flags: strictly earlier five-class submissions; flagged submissions retained; own expert panel excluded,",
         "or all expert panels if the normalised name has no match; latest date then majority, ties conflicting (ADR-005).",
         "Script: data-raw/make_items_ap1.R; inputs: ../quellen/daten/; no downloads.")
  writeLines(enc2utf8(q), file.path(stage, "QUELLE.txt"), useBytes = TRUE)
  files <- c("items.csv", "pilot.csv", "QUELLE.txt")
  sums <- vapply(file.path(stage, files), helpers$acmg_hash, "", USE.NAMES = FALSE)
  writeLines(paste(sums, files, sep = "  "), file.path(stage, "SHA256SUMS"), useBytes = TRUE)
  limits <- a("TOL")$data_size
  sizes <- file.size(file.path(stage, c(files, "SHA256SUMS")))
  if (any(sizes > limits$file_max_bytes) || any(sizes[1:2] > limits$gzip_above_bytes) ||
      sum(sizes) > limits$folder_max_bytes) stop("AP1 frozen output exceeds ANK-TOL.data_size.", call. = FALSE)
  dest <- file.path(root, "inst", "extdata", "items_ap1_2026-10-24")
  other <- list.files(file.path(root, "inst", "extdata"), recursive = TRUE, full.names = TRUE)
  other <- other[!startsWith(other, paste0(dest, "/"))]
  if (sum(file.size(other)) + sum(sizes) > limits$extdata_total_max_bytes) stop("AP1 extdata total exceeds ANK-TOL.data_size.", call. = FALSE)
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  if (!all(file.copy(file.path(stage, c(files, "SHA256SUMS")), dest, overwrite = TRUE))) stop("Could not publish AP1 frozen files.", call. = FALSE)
  cat(sprintf("AP1 freeze: pool %d classifications / %d genes / %d panels; main %d; pilot %d\n", nrow(pool), length(unique(pool$gene)), length(unique(pool$panel)), nrow(main), nrow(pilot)))
  cat("Expert-panel conservative exclusions (item/cutoff pairs):", fallbacks, "\n")
  cat(paste(sums, files, sep = "  "), sep = "\n")
}
main()
