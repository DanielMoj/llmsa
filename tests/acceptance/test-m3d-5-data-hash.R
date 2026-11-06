# K-M3d-5: data hash. The report names the algorithm SHA-256 and the hash of the
# canonical form of the run table (rows sorted by block, item, prompt, model,
# replicate; fixed column order; UTF-8; CSV without row names; decimal point;
# LF; Formelsammlung §11). The test computes it independently with
# digest::digest(algo = "sha256") over its own canonicalization
# (acc_m3d_canonical_lines(), setup-m3d.R; the byte-level rules are ACC-12) and
# gets the same value; the hash does not change when rows (or columns) are
# permuted and changes with every value change. The data hash is no longer
# called MD5 (Formelsammlung Nr. 9).

# The one data hash a rendered report names (NULL after a failed check).
acc_m3d_5_hash <- function(lines, what) {
  if (!acc_m3d_report_ok(lines, what)) return(NULL)
  h <- acc_m3d_report_hashes(lines)
  expect_length(h, 1L)
  if (length(h) != 1L) return(NULL)
  h
}

acc_m3d_5_report <- function(key, runs) acc_m3d_report(paste0("hash_", key), acc_m3d_numeric_study()$grr, runs = runs)

test_that("K-M3d-5: the report names SHA-256 and the hash of the canonical run table, computed independently with digest", {
  lines <- acc_m3d_report_main()
  h <- acc_m3d_5_hash(lines, "full")
  if (is.null(h)) return(invisible())
  expect_identical(h, acc_m3d_canonical_sha256(acc_m3d_numeric_study()$runs), label = "data hash of the msa_run() table")
  n <- acc_m3d_norm(lines)
  named <- grepl(h, tolower(n), fixed = TRUE)
  expect_true(any(named & grepl("(?i)sha-?256", n, perl = TRUE)), label = "the line with the data hash names SHA-256")
  expect_false(any(grepl("(?i)md5", n[named | grepl("(?i)data hash", n, perl = TRUE)], perl = TRUE)),
               label = "the data hash is no longer called MD5")
  tricky <- acc_m3d_hash_runs()
  h2 <- acc_m3d_5_hash(acc_m3d_5_report("tricky", tricky), "awkward run table")
  if (!is.null(h2)) expect_identical(h2, acc_m3d_canonical_sha256(tricky), label = "data hash of the run table with every column type")
})

test_that("K-M3d-5: the data hash does not change when the rows or the columns of the run table are permuted", {
  tricky <- acc_m3d_hash_runs()
  base <- acc_m3d_5_hash(acc_m3d_5_report("tricky", tricky), "awkward run table")
  if (is.null(base)) return(invisible())
  d <- as.data.frame(tricky)
  rows <- acc_m3a_with_seed(5501L, sample.int(nrow(d)))
  cols <- acc_m3a_with_seed(5502L, sample.int(ncol(d)))
  for (case in list(list(key = "rows", runs = as_msa_runs(d[rows, , drop = FALSE])),
                    list(key = "rows_reversed", runs = as_msa_runs(d[rev(seq_len(nrow(d))), , drop = FALSE])),
                    list(key = "columns", runs = as_msa_runs(d[, cols, drop = FALSE])))) {
    h <- acc_m3d_5_hash(acc_m3d_5_report(paste0("perm_", case$key), case$runs), paste("permuted", case$key))
    if (!is.null(h)) expect_identical(h, base, label = paste("data hash after permuting the", case$key))
  }
})

test_that("K-M3d-5: the data hash changes with every value change and equals the independent hash of the changed table", {
  tricky <- acc_m3d_hash_runs()
  base <- acc_m3d_canonical_sha256(tricky)
  d <- as.data.frame(tricky)
  change <- function(f) { x <- d; x <- f(x); as_msa_runs(x) }
  cases <- list(
    value_text = change(function(x) { x$value[1] <- "0.144"; x }),
    value_trailing_zero = change(function(x) { x$value[2] <- paste0(x$value[2], "0"); x }),
    value_from_na = change(function(x) { x$value[5] <- "0.000"; x }),
    value_to_na = change(function(x) { x$value[12] <- NA; x }),
    double_last_bit = change(function(x) { x$latency_s[2] <- x$latency_s[2] * (1 + .Machine$double.eps); x }),
    double_tiny = change(function(x) { x$latency_s[4] <- 2e-20; x }),
    response_char = change(function(x) { x$response[1] <- sub("quoted", "quotes", x$response[1], fixed = TRUE); x }),
    response_newline = change(function(x) { x$response[3] <- "line one\r\nline two"; x }),
    error_text = change(function(x) { x$error[7] <- "HTTP 500 Internal Server Error!"; x }),
    integer = change(function(x) { x$position[3] <- x$position[3] + 1L; x }),
    logical = change(function(x) { x$flag[3] <- !x$flag[3]; x }),
    factor = change(function(x) { x$tier[1] <- setdiff(levels(x$tier), as.character(x$tier[1]))[1]; x }),
    key_item = change(function(x) { x$item_id[1] <- "I20"; x }),
    key_rep = change(function(x) { x$rep[1] <- 3L; x }))
  for (key in names(cases)) {
    expected <- acc_m3d_canonical_sha256(cases[[key]])
    expect_false(identical(expected, base), label = paste("mini-reference: the change", key, "changes the hash"))
    h <- acc_m3d_5_hash(acc_m3d_5_report(paste0("change_", key), cases[[key]]), paste("changed", key))
    if (!is.null(h)) {
      expect_false(identical(h, base), label = paste("data hash after the change", key))
      expect_identical(h, expected, label = paste("data hash after the change", key, "equals the independent hash"))
    }
  }
})
