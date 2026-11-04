#!/usr/bin/env Rscript
# Freeze five-class ClinVar submissions according to ANK-41/47/63 and ADR-049.
# Usage from the package root: Rscript data-raw/make_clinvar_subsets.R

make_clinvar_subsets <- function(root) {
  for (p in c("jsonlite", "digest")) {
    if (!requireNamespace(p, quietly = TRUE)) stop("Required package is missing: ", p, call. = FALSE)
  }
  root <- normalizePath(root, mustWork = TRUE)
  sys.source(file.path(root, "inst", "validation", "m1d", "prepare.R"), envir = environment())
  provenance <- m1d_anchor(root, "ANK-41")
  a <- provenance$value
  specification <- m1d_anchor(root, "ANK-47")$value
  schema <- m1d_anchor(root, "ANK-63")$value
  limits <- m1d_anchor(root, "ANK-TOL")$value$data_size
  paths <- vapply(names(a$files), function(f) {
    m1d_input(root, "clinvar_2026-10-22", f, a$files[[f]]$sha256)
  }, "")
  submissions <- paths[["submission_summary.txt.gz"]]
  variants <- paths[["variant_summary.txt.gz"]]
  genes <- c("MEFV", "MVK", "NLRP3", "TNFRSF1A") # K-M1d-3(a), not estimated quantities.
  index <- m1d_clinvar_index(submissions, specification, schema)
  drawn <- m1d_draw_variants(index$counts, specification)
  gene_parts <- list()
  m1d_stream_tsv(variants, c("VariationID", "GeneSymbol"), function(d) {
    gene_parts[[length(gene_parts) + 1L]] <<- m1d_gene_map(data.frame(
      variation_id = m1d_ids(d$VariationID), gene = d$GeneSymbol, stringsAsFactors = FALSE))
  })
  gene_map <- m1d_gene_map(do.call(rbind, gene_parts))
  rm(gene_parts)
  hrf_all <- gene_map$variation_id[m1d_gene_member(gene_map$gene, genes)]
  n_hrf <- index$counts$submitters[match(hrf_all, index$counts$variation_id)]
  hrf_ids <- hrf_all[!is.na(n_hrf) & n_hrf >= 2L]
  selected <- sort(unique(c(hrf_ids, drawn)), method = "radix")
  selected_genes <- gene_map$gene[match(selected, gene_map$variation_id)]
  names(selected_genes) <- as.character(selected)
  excluded_hrf <- sum(index$excluded_ids %in% hrf_all)
  excluded_all <- length(index$excluded_ids)
  eligible <- sum(index$counts$submitters >= specification$min_distinct_submitters)
  n_source <- index$n_rows
  rm(gene_map, index)
  rows <- list()
  fields <- c("VariationID", "ClinicalSignificance", "DateLastEvaluated", "ReviewStatus", "Submitter")
  m1d_stream_tsv(submissions, fields, function(d) {
    id <- m1d_ids(d$VariationID)
    keep <- id %in% selected & d$ClinicalSignificance %in% unlist(specification$classes)
    if (!any(keep)) return(invisible(NULL))
    d <- d[keep, , drop = FALSE]
    rows[[length(rows) + 1L]] <<- data.frame(variation_id = id[keep],
      gene = unname(selected_genes[as.character(id[keep])]), submitter_id = d$Submitter,
      classification = d$ClinicalSignificance,
      date_last_evaluated = m1d_dates(d$DateLastEvaluated, schema), review_status = d$ReviewStatus,
      stringsAsFactors = FALSE)
  }, positions = schema$columns, n_columns = schema$n_columns_file)
  if (!length(rows)) m1d_abort("no selected ClinVar submissions")
  all_rows <- m1d_order(do.call(rbind, rows))
  if (!setequal(unique(all_rows$variation_id), selected)) m1d_abort("selected ClinVar variants are missing")
  outputs <- list(hrf = all_rows[all_rows$variation_id %in% hrf_ids, , drop = FALSE],
                  sample = all_rows[all_rows$variation_id %in% drawn, , drop = FALSE])
  for (name in names(outputs)) {
    x <- outputs[[name]]
    counts <- m1d_submitter_counts(x$variation_id, match(x$submitter_id, unique(x$submitter_id)))
    minimum <- if (name == "hrf") 2L else specification$min_distinct_submitters
    if (!nrow(x) || any(counts$submitters < minimum)) m1d_abort("invalid selected submitter count: ", name)
  }
  source <- c(
    "Source: ClinVar submission-level public data (public domain).",
    paste("URL:", provenance$source_url), paste("State (ANK-41):", a$stand),
    "Raw folder: ../quellen/daten/clinvar_2026-10-22/.",
    vapply(names(a$files), function(f) paste(f, "SHA-256", a$files[[f]]$sha256), ""),
    "Generator: data-raw/make_clinvar_subsets.R (offline; ADR-049).",
    paste("Exact ClinicalSignificance filter:", paste(unlist(specification$classes), collapse = "; ")),
    "Filter first, then count distinct unchanged Submitter strings per VariationID.",
    "Keep every qualifying submission, including multiple SCVs from one submitter.",
    paste("HRF genes:", paste(genes, collapse = ", "), "; at least two distinct remaining submitters."),
    "gene is the unchanged GeneSymbol from variant_summary.txt.gz joined by VariationID;",
    "semicolon-separated gene lists are retained, missing joins remain NA, conflicting",
    "assembly mappings are errors. DateLastEvaluated uses ANK-63 and LC_TIME=C;",
    "'-' is missing, dates are ISO. Submitter and ReviewStatus text is unchanged.",
    paste("Sample: at least", specification$min_distinct_submitters, "distinct remaining submitters;"),
    paste("numeric ascending VariationID order, sample size", specification$n_variants,
          "and seed", format(specification$seed, scientific = FALSE), "from ANK-47."),
    "RNG: Mersenne-Twister / Inversion / Rejection; draw without replacement.",
    paste("Source submissions:", n_source), paste("Eligible sample variants:", eligible),
    paste("Excluded non-five-class submissions before thresholds, all HRF variants:", excluded_hrf),
    paste("Excluded non-five-class submissions before thresholds, whole source:", excluded_all),
    vapply(names(outputs), function(n) paste(n, ":", length(unique(outputs[[n]]$variation_id)),
      "variants;", nrow(outputs[[n]]), "submissions;", length(unique(outputs[[n]]$submitter_id)), "submitters."), ""),
    "Storage: UTF-8 CSV, quoted character fields, doubled internal quotes, LF,",
    "empty fields for NA, radix order by all six output columns (VariationID numeric);",
    "gzip without timestamp. SHA256SUMS includes this file."
  )
  target <- file.path(root, "inst", "extdata", paste0("clinvar_", a$stand))
  stage <- tempfile(".m1d-clinvar-", tmpdir = dirname(target))
  dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  for (name in names(outputs)) m1d_write_csv(outputs[[name]], file.path(stage, paste0(name, "_submissions.csv.gz")))
  m1d_write_text(source, file.path(stage, "QUELLE.txt"))
  m1d_manifest(stage)
  size <- m1d_check_sizes(stage, target, limits)
  m1d_publish(stage, target)
  cat(sprintf("ClinVar: %d eligible variants; HRF %d rows / %d variants; sample %d rows / %d variants\n",
    eligible, nrow(outputs$hrf), length(hrf_ids), nrow(outputs$sample), length(drawn)))
  cat(sprintf("Excluded before thresholds: HRF %d; all %d; %d bytes published\n", excluded_hrf, excluded_all, size))
  invisible(outputs)
}

if (sys.nframe() == 0L) {
  if (length(commandArgs(trailingOnly = TRUE))) stop("Usage: Rscript data-raw/make_clinvar_subsets.R", call. = FALSE)
  script <- sub("^--file=", "", commandArgs()[startsWith(commandArgs(), "--file=")])
  make_clinvar_subsets(dirname(dirname(normalizePath(script, mustWork = TRUE))))
}
