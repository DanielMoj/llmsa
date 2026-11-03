# K-M1d-3: inst/extdata/clinvar_2026-10-19/ holds two frozen subsets with
# SHA256SUMS and QUELLE.txt (state ANK-41, public domain): (a)
# hrf_submissions.csv.gz, all five-class submissions on variants in MEFV, MVK,
# NLRP3 and TNFRSF1A with at least two submitters; (b) sample_submissions.csv.gz,
# a random sample of variants over all genes after ANK-47 (filter on the five
# classes, then variants with at least three remaining submitters, then the
# draw with seed and size of ANK-47); columns variation_id, gene,
# submitter_id, classification, date_last_evaluated, review_status;
# data-raw/make_clinvar_subsets.R recreates both byte for byte from
# ../quellen/daten/clinvar_2026-10-22/. The mini-reference reads the raw files
# of ANK-41 (acc_m1d_clinvar_reference() in setup-m1d.R; rules ACC-6).

test_that("K-M1d-3: the folder holds hrf_submissions.csv.gz and sample_submissions.csv.gz (gzip), SHA256SUMS and QUELLE.txt", {
  dir <- acc_m1d_clinvar_dir()
  expect_true(dir.exists(dir), label = dir)
  for (f in c(acc_m1d_clinvar_files, "SHA256SUMS", "QUELLE.txt")) expect_true(file.exists(file.path(dir, f)), label = paste("file", f))
  for (f in acc_m1d_clinvar_files) expect_true(acc_m1d_is_gzip(file.path(dir, f)), label = paste(f, "starts with the gzip magic bytes 1f 8b"))
})

test_that("K-M1d-3: both subsets have exactly the columns variation_id, gene, submitter_id, classification, date_last_evaluated, review_status", {
  for (f in acc_m1d_clinvar_files) {
    path <- acc_m1d_require(file.path(acc_m1d_clinvar_dir(), f), f)
    header <- gsub("\"", "", strsplit(acc_m1d_first_line(path), ",", fixed = TRUE)[[1]])
    expect_identical(header, acc_m1d_clinvar_columns, label = paste("header of", f))
  }
})

test_that("K-M1d-3: SHA256SUMS lists every file of the folder with its SHA-256 (docs/01 §7)", {
  acc_m1d_expect_sha256sums(acc_m1d_clinvar_dir(), acc_m1d_clinvar_folder)
})

test_that("K-M1d-3: QUELLE.txt names the state of ANK-41, the licence (public domain) and the script (ankerRef: ANK-41)", {
  q <- acc_m1d_text(file.path(acc_m1d_clinvar_dir(), "QUELLE.txt"))
  stand <- as.Date(acc_anchor("ANK-41")$value$stand)
  expect_true(grepl(format(stand, "%Y-%m-%d"), q, fixed = TRUE), label = paste("QUELLE.txt names the state", stand))
  expect_true(grepl("public domain", q, ignore.case = TRUE), label = "QUELLE.txt names the licence public domain")
  expect_true(grepl("ftp.ncbi.nlm.nih.gov/pub/clinvar", q, fixed = TRUE), label = "QUELLE.txt names the ClinVar URL")
  for (f in names(acc_anchor("ANK-41")$value$files)) {
    sums <- acc_anchor("ANK-41")$value$files[[f]]
    expect_true(grepl(sums$sha256, q, fixed = TRUE) || grepl(sums$md5, q, fixed = TRUE),
                label = paste("QUELLE.txt names the SHA-256 or md5 of", f, "(ANK-41)"))
  }
  expect_true(grepl("data-raw/make_clinvar_subsets.R", q, fixed = TRUE), label = "QUELLE.txt names the script")
})

test_that("K-M1d-3: the raw files carry the SHA-256 of ANK-41 (ankerRef: ANK-41)", {
  for (f in names(acc_anchor("ANK-41")$value$files)) {
    path <- acc_m1d_quellen(acc_m1d_clinvar_raw_folder, f)
    expect_true(file.exists(path), label = path)
    if (file.exists(path)) expect_identical(acc_sha256(path), acc_anchor("ANK-41")$value$files[[f]]$sha256, label = paste("SHA-256 of", f))
  }
})

test_that("K-M1d-3: hrf_submissions.csv.gz holds exactly the five-class submissions on variants of MEFV, MVK, NLRP3, TNFRSF1A with at least two submitters (ankerRef: ANK-41, ANK-63)", {
  ref <- acc_m1d_clinvar_reference()
  d <- acc_m1d_clinvar_subset("hrf")
  expect_true(all(d$classification %in% acc_m1d_classes()), label = "only the five classes")
  expect_setequal(unique(d$variation_id), unique(ref$hrf$variation_id))
  a <- acc_m1d_clinvar_keys(d)
  b <- acc_m1d_clinvar_keys(ref$hrf)
  expect_identical(length(a), length(b), label = sprintf("rows of hrf_submissions.csv.gz (reference %d)", length(b)))
  expect_identical(a, b, label = sprintf("rows of hrf_submissions.csv.gz as a multiset (%d differ)", length(setdiff(union(a, b), intersect(a, b)))))
})

test_that("K-M1d-3: sample_submissions.csv.gz holds the five-class submissions of the variants drawn after ANK-47 (ankerRef: ANK-47, ANK-41, ANK-63)", {
  ref <- acc_m1d_clinvar_reference()
  d <- acc_m1d_clinvar_subset("sample")
  s47 <- acc_anchor("ANK-47")$value
  expect_identical(length(unique(d$variation_id)), as.integer(s47$n_variants), label = "number of variants (ANK-47)")
  expect_setequal(unique(d$variation_id), ref$drawn)
  expect_true(all(d$classification %in% acc_m1d_classes()), label = "only the five classes")
  per_variant <- tapply(d$submitter_id, d$variation_id, function(s) length(unique(s)))
  expect_true(all(per_variant >= s47$min_distinct_submitters), label = "every variant has at least three distinct submitters")
  a <- acc_m1d_clinvar_keys(d)
  b <- acc_m1d_clinvar_keys(ref$sample)
  expect_identical(length(a), length(b), label = sprintf("rows of sample_submissions.csv.gz (reference %d)", length(b)))
  expect_identical(a, b, label = sprintf("rows of sample_submissions.csv.gz as a multiset (%d differ)", length(setdiff(union(a, b), intersect(a, b)))))
})

test_that("K-M1d-3: QUELLE.txt counts the excluded submissions with other terms (docs/02 M1d, ClinVar mapping; ACC-6)", {
  ref <- acc_m1d_clinvar_reference()
  q <- acc_m1d_text(file.path(acc_m1d_clinvar_dir(), "QUELLE.txt"))
  expect_true(acc_m1d_mentions_count(q, ref$excluded_hrf),
              label = sprintf("QUELLE.txt names %d excluded submissions on variants of the four genes", ref$excluded_hrf))
  expect_true(acc_m1d_mentions_count(q, ref$excluded_all),
              label = sprintf("QUELLE.txt names %d excluded submissions in the whole file", ref$excluded_all))
})

test_that("K-M1d-3: data-raw/make_clinvar_subsets.R recreates both subsets byte for byte from ../quellen/daten/clinvar_2026-10-22/", {
  targets <- file.path("inst", "extdata", acc_m1d_clinvar_folder, acc_m1d_clinvar_files)
  run <- acc_m1d_run_data_raw("make_clinvar_subsets.R", remove = targets)
  on.exit(unlink(run$work, recursive = TRUE), add = TRUE)
  expect_identical(run$status, 0L, label = paste("exit status;", paste(utils::tail(c(run$stdout, run$stderr), 15), collapse = " | ")))
  for (i in seq_along(targets)) {
    made <- file.path(run$copy, targets[i])
    expect_true(file.exists(made), label = paste("the script writes", basename(made)))
    frozen <- file.path(acc_m1d_clinvar_dir(), acc_m1d_clinvar_files[[i]])
    if (file.exists(made) && file.exists(frozen)) {
      expect_identical(acc_sha256(made), acc_sha256(frozen),
                       label = paste("SHA-256 of the recreated", basename(made), "; LC_COLLATE of the run:", Sys.getenv("LC_COLLATE")))
    }
  }
})

test_that("K-M1d-3: without ../quellen/daten/ the script stops with a named error and leaves the frozen files alone (docs/01 §7)", {
  run <- acc_m1d_run_data_raw("make_clinvar_subsets.R", quellen = FALSE)
  on.exit(unlink(run$work, recursive = TRUE), add = TRUE)
  expect_false(identical(run$status, 0L), label = "exit status 0 without the raw data")
  expect_true(any(grepl("quellen", c(run$stdout, run$stderr), fixed = TRUE)),
              label = paste("the error names the missing folder:", paste(utils::tail(c(run$stdout, run$stderr), 5), collapse = " | ")))
  for (f in acc_m1d_clinvar_files) {
    frozen <- file.path(acc_m1d_clinvar_dir(), f)
    if (file.exists(frozen)) {
      expect_identical(acc_sha256(file.path(run$copy, "inst", "extdata", acc_m1d_clinvar_folder, f)), acc_sha256(frozen),
                       label = paste(f, "in the copy is unchanged"))
    }
  }
})
