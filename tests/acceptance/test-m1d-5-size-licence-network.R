# K-M1d-5: size, licence, network, listing. Every file and folder under
# inst/extdata/llm-stability_2026-10-22/ and inst/extdata/clinvar_2026-10-19/
# and inst/extdata/ as a whole keep ANK-TOL.data_size; QUELLE.txt names
# licence and selection rule; no file in the repository holds INSAID
# classifications (search pattern: column classification together with source
# insaid); both vignettes are listed under articles in _pkgdown.yml and use no
# network (no httr2, curl or download.file call in the Rmd code). Contract
# details: ACC-8.
# K-M1d-5: that R CMD check builds both vignettes is decided by the lint gate
# (orchestrator/gates.d/20-lint.sh, orchestrator/lib/r-check.sh).

acc_m1d_5_folders <- function() {
  c(file.path(acc_pkg_root(), "inst", "extdata", acc_m1d_llm_folder),
    file.path(acc_pkg_root(), "inst", "extdata", acc_m1d_clinvar_folder))
}

test_that("K-M1d-5: every file and folder of both subsets and inst/extdata/ as a whole keep ANK-TOL.data_size; files over 100 KB are gzip (ankerRef: ANK-TOL.data_size)", {
  ds <- acc_anchor("ANK-TOL")$value$data_size
  for (dir in acc_m1d_5_folders()) {
    expect_true(dir.exists(dir), label = dir)
    files <- list.files(dir, recursive = TRUE, all.files = TRUE, full.names = TRUE)
    expect_true(length(files) > 0L, label = paste("files in", basename(dir)))
    sizes <- file.size(files)
    for (i in seq_along(files)) {
      expect_lte(sizes[i], ds$file_max_bytes, label = sprintf("size of %s (bytes)", basename(files[i])))
      if (sizes[i] > ds$gzip_above_bytes) {
        expect_true(grepl("\\.csv\\.gz$", files[i]) && acc_m1d_is_gzip(files[i]),
                    label = sprintf("%s (%d bytes, over %d) is a gzip-compressed .csv.gz", basename(files[i]), sizes[i], ds$gzip_above_bytes))
      }
    }
    expect_lte(sum(sizes), ds$folder_max_bytes, label = sprintf("size of the folder %s (bytes)", basename(dir)))
  }
  ext <- list.files(file.path(acc_pkg_root(), "inst", "extdata"), recursive = TRUE, all.files = TRUE, full.names = TRUE)
  expect_lte(sum(file.size(ext)), ds$extdata_total_max_bytes, label = "size of inst/extdata/ (bytes)")
})

test_that("K-M1d-5: QUELLE.txt of llm-stability names licence and selection rule (ankerRef: ANK-40; ACC-1, ACC-8)", {
  q <- acc_m1d_text(file.path(acc_m1d_llm_dir(), "QUELLE.txt"))
  a <- acc_m1d_ank40()
  expect_true(grepl("Apache", q, fixed = TRUE) && grepl("2.0", q, fixed = TRUE), label = "licence Apache 2.0")
  for (s in c("experiments/v3/runs.tgz", "stability_eval.csv", "top_p_k")) expect_true(grepl(s, q, fixed = TRUE), label = paste("selection rule names", s))
  expect_true(grepl("zero[- ]?shot", q, ignore.case = TRUE), label = "selection rule names the zero-shot runs")
})

test_that("K-M1d-5: QUELLE.txt of ClinVar names licence and selection rule (ankerRef: ANK-47; ACC-6, ACC-8)", {
  q <- acc_m1d_text(file.path(acc_m1d_clinvar_dir(), "QUELLE.txt"))
  s47 <- acc_anchor("ANK-47")$value
  expect_true(grepl("public domain", q, ignore.case = TRUE), label = "licence public domain")
  for (cl in acc_m1d_classes()) expect_true(grepl(cl, q, fixed = TRUE), label = paste("selection rule names the class", cl))
  for (g in acc_m1d_hrf_genes) expect_true(grepl(g, q, fixed = TRUE), label = paste("selection rule names the gene", g))
  expect_true(grepl(format(s47$seed, scientific = FALSE), q, fixed = TRUE), label = "selection rule names the seed of ANK-47")
  expect_true(acc_m1d_mentions_count(q, s47$n_variants), label = "selection rule names the size of ANK-47")
  expect_true(grepl("variant_summary", q, fixed = TRUE), label = "selection rule names variant_summary as the source of gene")
})

# A table file holds INSAID classifications if it has a column named
# classification and a cell (or its path) that names the source insaid.
acc_m1d_5_insaid_table <- function(header, cells, path) {
  cols <- tolower(trimws(gsub("\"", "", header)))
  "classification" %in% cols && (any(tolower(trimws(cells)) == "insaid", na.rm = TRUE) || grepl("insaid", tolower(path), fixed = TRUE))
}

test_that("K-M1d-5: no file in the repository holds INSAID classifications (column classification together with source insaid)", {
  root <- acc_repo_root()
  files <- list.files(root, recursive = TRUE, all.files = TRUE)
  files <- files[!grepl("^(\\.git/|reference/quellen/|reference/privat/)", files)]
  hits <- character()
  for (f in files[grepl("\\.(csv|tsv|txt)(\\.gz)?$", files, ignore.case = TRUE)]) {
    path <- file.path(root, f)
    first <- tryCatch(acc_m1d_first_line(path), error = function(e) character())
    if (!length(first)) next
    sep <- if (grepl("\t", first, fixed = TRUE)) "\t" else ","
    header <- strsplit(first, sep, fixed = TRUE)[[1]]
    if (!"classification" %in% tolower(trimws(gsub("\"", "", header)))) next
    con <- if (grepl("\\.gz$", path)) gzfile(path) else file(path)
    cells <- tryCatch(unlist(utils::read.table(con, sep = sep, header = TRUE, quote = "\"", comment.char = "",
                                               colClasses = "character", fill = TRUE), use.names = FALSE),
                      error = function(e) character())
    if (acc_m1d_5_insaid_table(header, cells, f)) hits <- c(hits, f)
  }
  for (f in files[grepl("\\.(rda|rdata|rds)$", files, ignore.case = TRUE)]) {
    e <- new.env(parent = emptyenv())
    objs <- tryCatch(if (grepl("\\.rds$", f, ignore.case = TRUE)) list(x = readRDS(file.path(root, f))) else {
      load(file.path(root, f), envir = e)
      mget(ls(e), envir = e)
    }, error = function(err) list())
    for (o in objs) {
      if (is.data.frame(o) && acc_m1d_5_insaid_table(names(o), unlist(lapply(o, as.character), use.names = FALSE), f)) hits <- c(hits, f)
    }
  }
  expect_identical(unique(hits), character(), label = "files with a column classification and the source insaid")
})

test_that("K-M1d-5: both vignettes are listed under articles in _pkgdown.yml", {
  path <- acc_m1d_require(file.path(acc_repo_root(), "_pkgdown.yml"), "_pkgdown.yml")
  y <- yaml::read_yaml(path)
  expect_true(!is.null(y$articles), label = "_pkgdown.yml has an articles section")
  listed <- unlist(lapply(y$articles, function(a) unlist(a$contents)))
  for (v in c("llm-stability", "clinvar-raters")) expect_true(v %in% listed, label = paste(v, "is listed under articles"))
})

test_that("K-M1d-5: the R code of both vignettes calls neither httr2, curl nor download.file", {
  for (v in c("llm-stability", "clinvar-raters")) {
    path <- acc_m1d_vignette_path(v)
    expect_true(file.exists(path), label = path)
    if (!file.exists(path)) next
    code <- paste(acc_m1d_rmd_code(path), collapse = "\n")
    for (p in c("\\bhttr2\\b", "\\bcurl\\b", "download\\.file")) {
      expect_false(grepl(p, code, perl = TRUE), label = sprintf("%s: the R code matches %s", v, p))
    }
  }
})
