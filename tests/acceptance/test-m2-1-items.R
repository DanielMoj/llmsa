# K-M2-1: item set items_ap1_2026-10-24 (items.csv, pilot.csv, QUELLE.txt),
# data-raw/make_items_ap1.R and acmg_items(). Expected values come from the anchors
# ANK-50, ANK-51, ANK-52, ANK-59, ANK-64, ANK-67, ANK-69 and ANK-TOL and from the
# raw files they pin (ERepo export, INSAID TSV), read independently of the package.

test_that("K-M2-1: items.csv has 100 rows, the 17 columns of K-M2-1, 75 erepo and 25 insaid rows", {
  a <- acc_anchor("ANK-59")$value
  items <- acc_m2_items()
  expect_identical(nrow(items), as.integer(a$items_total))
  expect_setequal(names(items), acc_m2_columns())
  expect_length(names(items), length(acc_m2_columns()))
  expect_true(all(nzchar(items$item_id)))
  expect_false(anyDuplicated(items$item_id) > 0L)
  expect_true(all(items$source %in% c("erepo", "insaid")))
  expect_identical(sum(items$source == "erepo"), as.integer(a$erepo_items))
  expect_identical(sum(items$source == "insaid"), as.integer(a$insaid_items))
})

test_that("K-M2-1: every erepo row of items.csv and pilot.csv is a pool classification with correctly split fields (ankerRef: ANK-50, ANK-51)", {
  pool <- acc_m2_pool()
  a <- acc_anchor("ANK-51")$value
  # the mini-reference reproduces the anchored pool before it is used as reference
  expect_identical(nrow(pool), as.integer(a$pool$classifications))
  expect_identical(length(unique(pool$gene)), as.integer(a$pool$genes))
  expect_identical(length(unique(pool$panel)), as.integer(a$pool$panels))
  expect_false(anyDuplicated(pool$hgvs) > 0L)
  for (name in c("items.csv", "pilot.csv")) {
    d <- acc_m2_read_csv(name)
    er <- d[d$source == "erepo", , drop = FALSE]
    hit <- match(er$hgvs, pool$hgvs)
    expect_identical(sum(is.na(hit)), 0L, info = paste(name, "rows not in the pool:", paste(er$hgvs[is.na(hit)], collapse = ", ")))
    ok <- !is.na(hit)
    p <- pool[hit[ok], , drop = FALSE]
    e <- er[ok, , drop = FALSE]
    expect_identical(e$gene, p$gene, info = name)
    expect_identical(e$transcript, p$transcript, info = name)
    expect_identical(e$hgvs, paste0(p$transcript, ":", p$cdna), info = name)
    expect_identical(e$protein, p$protein, info = name)
    expect_identical(e$reference, p$reference, info = name)
    expect_identical(acc_m2_squish(e$panel), acc_m2_squish(p$panel), info = name)
  }
})

test_that("K-M2-1: the mini-reference splits #Variation as in the example of K-M2-1", {
  sp <- acc_m2_split_variation(c("NM_000277.2(PAH):c.1A>G (p.Met1Val)", "NM_000277.2:c.1A>G", "NC_000012.12:g.1A>G",
                                 "NR_003051.3(RMRP):n.-20_2dup", ""))
  expect_identical(sp$ok, c(TRUE, TRUE, FALSE, FALSE, FALSE))
  expect_identical(sp$transcript[1:2], c("NM_000277.2", "NM_000277.2"))
  expect_identical(paste0(sp$transcript, ":", sp$cdna)[1:2], c("NM_000277.2:c.1A>G", "NM_000277.2:c.1A>G"))
  expect_identical(sp$protein[1:2], c("p.Met1Val", ""))
  expect_identical(sp$gene[1:2], c("PAH", ""))
})

test_that("K-M2-1: 15 erepo items per class in items.csv and 2 per class in pilot.csv (ankerRef: ANK-59, ANK-67)", {
  classes <- acc_m2_classes()
  items <- acc_m2_items()
  pilot <- acc_m2_pilot()
  er <- items[items$source == "erepo", , drop = FALSE]
  expect_true(all(er$reference %in% classes))
  expect_identical(as.integer(table(factor(er$reference, levels = classes))),
                   rep(as.integer(acc_anchor("ANK-59")$value$erepo_per_class), length(classes)))
  expect_true(all(pilot$reference %in% classes))
  expect_identical(as.integer(table(factor(pilot$reference, levels = classes))),
                   rep(as.integer(acc_anchor("ANK-67")$value$pilot_per_class), length(classes)))
})

test_that("K-M2-1: panels are taken in round-robin by descending number of classifications, pilot rows are the next two of the same round-robin (ankerRef: ANK-59, ANK-67)", {
  pool <- acc_m2_pool()
  x <- acc_m2_erepo()
  items <- acc_m2_items()
  pilot <- acc_m2_pilot()
  classes <- acc_m2_classes()
  sq <- function(v) acc_m2_squish(v)
  # three readings of "Einstufungszahl" (ACC-4): within the class in the pool, within
  # the pool, within the whole ERepo export; one reading must fit all five classes
  keys <- list(
    class_pool = function(cl) table(sq(pool$panel[pool$reference == cl])),
    pool = function(cl) table(sq(pool$panel)),
    erepo = function(cl) table(sq(x[["Expert Panel"]]))
  )
  result <- list()
  for (reading in names(keys)) {
    found <- character()
    for (cl in classes) {
      cand <- table(sq(pool$panel[pool$reference == cl]))
      groups <- names(cand)
      main <- table(factor(sq(items$panel[items$source == "erepo" & items$reference == cl]), levels = groups))
      pil <- table(factor(sq(pilot$panel[pilot$reference == cl]), levels = groups))
      k <- keys[[reading]](cl)
      key <- stats::setNames(as.numeric(k[groups]), groups)
      key[is.na(key)] <- 0
      v <- acc_m2_round_robin_violations(stats::setNames(as.integer(cand), groups),
                                         stats::setNames(as.integer(main), groups),
                                         stats::setNames(as.integer(pil), groups), key)
      if (length(v)) found <- c(found, paste0(cl, ": ", v))
    }
    result[[reading]] <- found
  }
  fits <- vapply(result, function(v) !length(v), NA)
  expect_true(any(fits), info = paste(unlist(lapply(names(result), function(r) paste0("[", r, "] ", result[[r]]))), collapse = "\n"))
})

test_that("K-M2-1: the round-robin check detects wrong selections", {
  cand <- c(A = 10L, B = 5L, C = 1L, D = 3L)
  key <- c(A = 10, B = 5, C = 1, D = 3)
  # 6 picks: round 1 A, B, D, C (4 picks), round 2 A, B; pilot = round 2
  expect_identical(acc_m2_round_robin_violations(cand, c(A = 1L, B = 1L, C = 1L, D = 1L), c(A = 1L, B = 1L, C = 0L, D = 0L), key), character())
  # main gets the round-2 pick of A, pilot = round-2 B and D
  expect_identical(acc_m2_round_robin_violations(cand, c(A = 2L, B = 1L, C = 1L, D = 1L), c(A = 0L, B = 1L, C = 0L, D = 1L), key), character())
  # D before B in round 2 contradicts the descending order
  expect_true(length(acc_m2_round_robin_violations(cand, c(A = 2L, B = 1L, C = 1L, D = 2L), NULL, key)) > 0L)
  # a panel left out of round 1
  expect_true(length(acc_m2_round_robin_violations(cand, c(A = 2L, B = 2L, C = 0L, D = 1L), NULL, key)) > 0L)
  # a pilot pick before a main pick
  expect_true(length(acc_m2_round_robin_violations(cand, c(A = 1L, B = 1L, C = 1L, D = 0L), c(A = 0L, B = 0L, C = 0L, D = 1L), key)) > 0L)
  # more picks than candidates
  expect_true(length(acc_m2_round_robin_violations(cand, c(A = 1L, B = 1L, C = 2L, D = 1L), NULL, NULL)) > 0L)
})

test_that("K-M2-1: insaid rows: Validated variants, 5 per class, genes in round-robin, transcript of the publication, hgvs = transcript:cDNA, protein and reference empty (ankerRef: ANK-52, ANK-59, ANK-64)", {
  ins <- acc_m2_insaid()
  a52 <- acc_anchor("ANK-52")$value
  expect_identical(nrow(ins), as.integer(a52$variants_total))
  expect_identical(sum(ins$status == "Validated"), as.integer(a52$validated))
  a59 <- acc_anchor("ANK-59")$value
  tx <- unlist(acc_anchor("ANK-64")$value)
  items <- acc_m2_items()
  d <- items[items$source == "insaid", , drop = FALSE]
  expect_true(all(d$gene %in% unlist(a59$insaid_genes)))
  expect_identical(unname(d$transcript), unname(tx[d$gene]))
  expect_true(all(startsWith(d$hgvs, paste0(d$transcript, ":"))))
  cdna <- substr(d$hgvs, nchar(d$transcript) + 2L, nchar(d$hgvs))
  hit <- match(paste(d$gene, cdna), paste(ins$gene, ins$cdna))
  expect_identical(sum(is.na(hit)), 0L, info = paste("not in the TSV:", paste(d$hgvs[is.na(hit)], collapse = ", ")))
  t <- ins[hit[!is.na(hit)], , drop = FALSE]
  expect_true(all(t$status == a59$insaid_status))
  classes <- acc_m2_classes()
  expect_identical(as.integer(table(factor(t$label, levels = classes))),
                   rep(as.integer(a59$insaid_per_class), length(classes)))
  expect_true(all(d$protein == ""))
  expect_true(all(d$reference == ""))
  # genes in round-robin within each class (order of the genes not fixed, ACC-5)
  val <- ins[ins$status == a59$insaid_status, , drop = FALSE]
  genes <- unlist(a59$insaid_genes)
  for (cl in classes) {
    cand <- table(factor(val$gene[val$label == cl], levels = genes))
    main <- table(factor(t$gene[t$label == cl], levels = genes))
    v <- acc_m2_round_robin_violations(stats::setNames(as.integer(cand), genes), stats::setNames(as.integer(main), genes))
    expect_identical(v, character(), info = cl)
  }
})

test_that("K-M2-1: pilot.csv has the columns of items.csv, 10 erepo rows and no row of items.csv (ankerRef: ANK-67)", {
  items <- acc_m2_items()
  pilot <- acc_m2_pilot()
  expect_identical(names(pilot), names(items))
  expect_identical(nrow(pilot), as.integer(acc_anchor("ANK-67")$value$pilot_items))
  expect_true(all(pilot$source == "erepo"))
  expect_false(anyDuplicated(pilot$item_id) > 0L)
  expect_length(intersect(pilot$item_id, items$item_id), 0L)
  expect_length(intersect(pilot$hgvs, items$hgvs[items$source == "erepo"]), 0L)
})

test_that("K-M2-1: QUELLE.txt names the ERepo state, the SHA-256 of the INSAID TSV and the origin of the INSAID transcripts (ankerRef: ANK-51, ANK-52, ANK-64)", {
  path <- acc_m2_require_file(file.path(acc_m2_item_dir(), "QUELLE.txt"), "QUELLE.txt")
  q <- paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  stand <- as.Date(acc_anchor("ANK-51")$value$stand)
  expect_true(grepl(format(stand, "%Y-%m-%d"), q, fixed = TRUE) || grepl(format(stand, "%d.%m.%Y"), q, fixed = TRUE))
  expect_true(grepl(acc_anchor("ANK-52")$value$sha256, tolower(q), fixed = TRUE))
  for (t in c(unlist(acc_anchor("ANK-64")$value), unlist(acc_anchor("ANK-64")$table1_contradiction))) {
    expect_true(grepl(t, q, fixed = TRUE), info = t)
  }
  # docs/01 §7: source, URL, licence and script
  expect_true(grepl("erepo.clinicalgenome.org", q, fixed = TRUE))
  expect_true(grepl("CC0", q, fixed = TRUE))
  expect_true(grepl("data-raw/make_items_ap1.R", q, fixed = TRUE))
})

test_that("K-M2-1: the frozen folder follows docs/01 §7: SHA256SUMS line per file, size limits (ankerRef: ANK-TOL.data_size)", {
  dir <- acc_m2_item_dir()
  sums <- readLines(acc_m2_require_file(file.path(dir, "SHA256SUMS"), "SHA256SUMS"), warn = FALSE)
  sums <- sums[nzchar(trimws(sums))]
  m <- regmatches(sums, regexec("^([0-9a-fA-F]{64}) [ *]?(.+)$", sums))
  expect_true(all(lengths(m) == 3L), info = paste(sums, collapse = "\n"))
  listed <- vapply(m, function(z) z[3], "")
  hashes <- tolower(vapply(m, function(z) z[2], ""))
  expect_true(all(c("items.csv", "pilot.csv") %in% listed))
  expect_false(anyDuplicated(listed) > 0L)
  for (i in seq_along(listed)) {
    f <- file.path(dir, listed[i])
    expect_true(file.exists(f), info = listed[i])
    if (file.exists(f)) expect_identical(acc_sha256(f), hashes[i], info = listed[i])
  }
  ds <- acc_m2_tol("data_size")
  files <- list.files(dir, full.names = TRUE)
  sizes <- file.size(files)
  expect_true(all(sizes <= ds$file_max_bytes))
  csv <- grepl("\\.csv$", files)
  expect_true(all(sizes[csv] <= ds$gzip_above_bytes), info = paste(basename(files[csv]), sizes[csv], collapse = ", "))
  expect_true(sum(sizes) <= ds$folder_max_bytes)
  ext <- list.files(file.path(acc_pkg_root(), "inst", "extdata"), recursive = TRUE, full.names = TRUE)
  expect_true(sum(file.size(ext)) <= ds$extdata_total_max_bytes)
})

test_that("K-M2-1: the folder holds no INSAID classification or protein of the selected variants (docs/01 §7, ankerRef: ANK-52)", {
  items <- acc_m2_items()
  ins <- acc_m2_insaid()
  d <- items[items$source == "insaid", , drop = FALSE]
  cdna <- substr(d$hgvs, nchar(d$transcript) + 2L, nchar(d$hgvs))
  t <- ins[match(paste(d$gene, cdna), paste(ins$gene, ins$cdna)), , drop = FALSE]
  prot <- unique(t$protein[!is.na(t$protein) & nchar(t$protein) > 4L])
  files <- list.files(acc_m2_item_dir(), full.names = TRUE)
  text <- paste(vapply(files, function(f) paste(readLines(f, warn = FALSE, encoding = "UTF-8"), collapse = "\n"), ""), collapse = "\n")
  for (p in prot) expect_false(grepl(p, text, fixed = TRUE), info = p)
})

test_that("K-M2-1: data-raw/make_items_ap1.R recreates items.csv and pilot.csv byte for byte from ../quellen/daten/ with the seed of ANK-59", {
  root <- acc_repo_root()
  script <- acc_m2_require_file(file.path(root, "data-raw", "make_items_ap1.R"), "data-raw/make_items_ap1.R")
  src <- readLines(script, warn = FALSE)
  seed <- format(acc_anchor("ANK-59")$value$seed, scientific = FALSE)
  expect_true(any(grepl(seed, src, fixed = TRUE)) || any(grepl("ANK-59", src, fixed = TRUE)))
  work <- tempfile("acc-m2-dataraw-")
  copy <- file.path(work, "llmsa")
  dir.create(copy, recursive = TRUE)
  for (part in c("DESCRIPTION", "NAMESPACE", "R", "inst", "data", "data-raw")) {
    from <- if (part == "data-raw") file.path(root, part) else file.path(acc_pkg_root(), part)
    if (file.exists(from)) file.copy(from, copy, recursive = TRUE)
  }
  dir.create(file.path(copy, "reference"))
  file.copy(file.path(root, "reference", "anchors"), file.path(copy, "reference"), recursive = TRUE)
  file.symlink(file.path(dirname(root), "quellen"), file.path(work, "quellen"))
  out_dir <- file.path(copy, "inst", "extdata", "items_ap1_2026-10-24")
  unlink(file.path(out_dir, c("items.csv", "pilot.csv")))
  old <- setwd(copy)
  res <- acc_run(file.path(R.home("bin"), "Rscript"), shQuote("data-raw/make_items_ap1.R"))
  setwd(old)
  expect_identical(res$status, 0L, info = paste(c(res$stdout, res$stderr), collapse = "\n"))
  # the script runs in the environment of the test run (testthat sets LC_COLLATE=C);
  # its output must not depend on the locale (ACC-17)
  for (f in c("items.csv", "pilot.csv")) {
    made <- file.path(out_dir, f)
    expect_true(file.exists(made), info = f)
    if (file.exists(made)) {
      expect_identical(acc_sha256(made), acc_sha256(file.path(acc_m2_item_dir(), f)),
                       info = paste(f, "differs; LC_COLLATE of the run:", Sys.getenv("LC_COLLATE")))
    }
  }
  unlink(work, recursive = TRUE)
})

test_that("K-M2-1: without ../quellen/daten/ the script stops with a named error (docs/01 §7)", {
  root <- acc_repo_root()
  script <- acc_m2_require_file(file.path(root, "data-raw", "make_items_ap1.R"), "data-raw/make_items_ap1.R")
  work <- tempfile("acc-m2-noquellen-")
  copy <- file.path(work, "llmsa")
  dir.create(copy, recursive = TRUE)
  for (part in c("DESCRIPTION", "NAMESPACE", "R", "inst", "data", "data-raw")) {
    from <- if (part == "data-raw") file.path(root, part) else file.path(acc_pkg_root(), part)
    if (file.exists(from)) file.copy(from, copy, recursive = TRUE)
  }
  dir.create(file.path(copy, "reference"))
  file.copy(file.path(root, "reference", "anchors"), file.path(copy, "reference"), recursive = TRUE)
  before <- acc_sha256(file.path(copy, "inst", "extdata", "items_ap1_2026-10-24", c("items.csv", "pilot.csv")))
  old <- setwd(copy)
  res <- acc_run(file.path(R.home("bin"), "Rscript"), shQuote("data-raw/make_items_ap1.R"))
  setwd(old)
  expect_false(identical(res$status, 0L))
  expect_true(any(grepl("quellen", c(res$stdout, res$stderr), fixed = TRUE)), info = paste(c(res$stdout, res$stderr), collapse = "\n"))
  after <- acc_sha256(file.path(copy, "inst", "extdata", "items_ap1_2026-10-24", c("items.csv", "pilot.csv")))
  expect_identical(after, before)
  unlink(work, recursive = TRUE)
})

test_that("K-M2-1, K-M2-3, K-M2-5, K-M2-6: acmg_items(), acmg_prompts(), acmg_plan() and acmg_evaluate() are internal with the signatures of docs/03", {
  ns <- parseNamespaceFile(basename(acc_pkg_root()), dirname(acc_pkg_root()), mustExist = TRUE)
  want <- list(
    acmg_items = alist(insaid_path = NULL, pilot = FALSE),
    acmg_prompts = alist(robustness = FALSE),
    acmg_evaluate = alist(runs = , plan = ),
    acmg_plan = alist(path = NULL)
  )
  for (f in names(want)) {
    fn <- acc_m2_fn(f)
    expect_identical(names(formals(fn)), names(want[[f]]), info = f)
    have <- acc_signature(fn)
    for (i in seq_along(want[[f]])) {
      if (i <= length(have)) {
        expect_identical(have[[i]]$default, acc_default_text(want[[f]][[i]]), info = paste(f, names(want[[f]])[i]))
      }
    }
    expect_false(f %in% ns$exports, info = f)
    expect_false(any(vapply(ns$exportPatterns, function(p) grepl(p, f), NA)), info = f)
  }
  src <- file.path(acc_pkg_root(), "R", "acmg.R")
  expect_true(file.exists(src))
  if (file.exists(src)) {
    code <- paste(readLines(src, warn = FALSE), collapse = "\n")
    for (f in names(want)) expect_true(grepl(paste0(f, "\\s*<-\\s*function"), code), info = f)
    expect_true(grepl("@keywords internal", code, fixed = TRUE))
  }
})

test_that("K-M2-1: acmg_items() returns items.csv, pilot = TRUE returns pilot.csv, INSAID reference NA without the TSV", {
  items_fun <- acc_m2_fn("acmg_items")
  cols <- acc_m2_columns()
  for (pilot in c(FALSE, TRUE)) {
    got <- items_fun(pilot = pilot)
    want <- if (pilot) acc_m2_pilot() else acc_m2_items()
    expect_true(is.data.frame(got))
    expect_true(all(cols %in% names(got)), info = paste(setdiff(cols, names(got)), collapse = ", "))
    expect_identical(nrow(got), nrow(want))
    g <- acc_m2_normalise_items(got[match(want$item_id, got$item_id), cols, drop = FALSE])
    w <- acc_m2_normalise_items(want[, cols, drop = FALSE])
    rownames(g) <- rownames(w) <- NULL
    expect_identical(g, w, info = if (pilot) "pilot.csv" else "items.csv")
  }
  got <- items_fun()
  expect_true(all(is.na(got$reference[got$source == "insaid"])))
})

test_that("K-M2-1: acmg_items(insaid_path) adds reference and protein of the INSAID items from the TSV without saving them (ankerRef: ANK-52)", {
  items_fun <- acc_m2_fn("acmg_items")
  dir <- acc_m2_item_dir()
  files_before <- list.files(dir)
  sums_before <- acc_sha256(file.path(dir, files_before))
  wd_before <- list.files(getwd(), recursive = TRUE, all.files = TRUE)
  got <- items_fun(insaid_path = acc_m2_insaid_path())
  expect_identical(list.files(dir), files_before)
  expect_identical(acc_sha256(file.path(dir, files_before)), sums_before)
  expect_identical(list.files(getwd(), recursive = TRUE, all.files = TRUE), wd_before)
  ins <- acc_m2_insaid()
  d <- got[got$source == "insaid", , drop = FALSE]
  cdna <- substr(d$hgvs, nchar(d$transcript) + 2L, nchar(d$hgvs))
  t <- ins[match(paste(d$gene, cdna), paste(ins$gene, ins$cdna)), , drop = FALSE]
  expect_identical(as.character(d$reference), t$label)
  unwrap <- sub("^p\\.\\((.*)\\)$", "p.\\1", t$protein)
  prot <- ifelse(is.na(d$protein), "", as.character(d$protein))
  expect_true(all(prot == t$protein | prot == unwrap), info = paste(prot, t$protein, sep = " / ", collapse = "; "))
  er_got <- acc_m2_normalise_items(got[got$source == "erepo", acc_m2_columns(), drop = FALSE])
  items <- acc_m2_items()
  er_want <- acc_m2_normalise_items(items[items$source == "erepo", acc_m2_columns(), drop = FALSE])
  er_got <- er_got[match(er_want$item_id, er_got$item_id), , drop = FALSE]
  rownames(er_got) <- rownames(er_want) <- NULL
  expect_identical(er_got, er_want)
})
