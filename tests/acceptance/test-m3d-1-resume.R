# K-M3d-1: resume (property test). For ANK-TOL.resume_cutpoints randomly chosen
# cut points (seeds 1 to 50) a run with backend_mock() and a fixed seed is
# interrupted and continued with resume = TRUE; the resulting store (CSV and
# SQLite) holds the same rows with the same values as an uninterrupted run,
# without duplicates (run_key unique). The interruption is an interrupt
# condition before call k + 1 (k drawn with seed s from 1 to N - 1); the
# resumed run uses a new backend_mock() with the same arguments and seed, as
# after a new R session. Compared are all stored columns except the time
# columns timestamp and latency_s; the store after the interruption holds the
# k completed calls ("ohne Datenverlust"). Design and contract: ACC-2.

acc_m3d_1_seeds <- function() {
  cp <- acc_anchor("ANK-TOL")$value$resume_cutpoints
  if (!identical(cp$seeds, sprintf("1 bis %d", as.integer(cp$n)))) {
    stop("acceptance: ANK-TOL.resume_cutpoints$seeds is not \"1 bis <n>\": ", format(cp$seeds), call. = FALSE)
  }
  seq_len(as.integer(cp$n))
}

for (ext in c("csv", "sqlite")) {
  test_that(sprintf("K-M3d-1: runs interrupted at random cut points and resumed with resume = TRUE leave the %s store equal to an uninterrupted run, without duplicate run keys (ankerRef: ANK-TOL.resume_cutpoints)",
                    toupper(ext)), {
    seeds <- acc_m3d_1_seeds()
    expect_length(seeds, 50L)
    d <- acc_m3d_resume_design()
    n_calls <- nrow(d)
    design_keys <- acc_m3d_run_key(as.data.frame(d))
    reference_path <- tempfile("acc-m3d-1-reference-", fileext = paste0(".", ext))
    on.exit(unlink(reference_path), add = TRUE)
    msa_run(d, acc_m3d_resume_backend(), parse = parse_number(), store = reference_path, verbose = FALSE)
    reference <- acc_m3d_read_store(reference_path)
    expect_identical(nrow(reference), n_calls, label = "rows of the uninterrupted store")
    expect_false(anyDuplicated(acc_m3d_run_key(reference)) > 0L, label = "duplicate run keys in the uninterrupted store")
    expected <- acc_m3d_comparable(reference)
    for (s in seeds) {
      k <- acc_m3a_with_seed(s, sample.int(n_calls - 1L, 1L))
      info <- sprintf("seed %d: interrupted before call %d of %d", s, k + 1L, n_calls)
      path <- tempfile(sprintf("acc-m3d-1-seed%02d-", s), fileext = paste0(".", ext))
      # msa_run() may pass the interrupt on or end with its own condition; it
      # must not swallow it and complete the run
      interrupted <- tryCatch({
        msa_run(d, acc_m3d_interrupt_after(acc_m3d_resume_backend(), k), parse = parse_number(), store = path,
                verbose = FALSE)
        FALSE
      }, acc_m3d_interrupt = function(cnd) TRUE, interrupt = function(cnd) TRUE, error = function(cnd) TRUE)
      expect_true(interrupted, label = paste(info, "- the interrupt ends msa_run()"))
      before <- acc_m3d_read_store(path)
      expect_identical(if (is.null(before)) 0L else nrow(before), k,
                       label = paste(info, "- rows stored before the interruption"))
      resumed <- tryCatch(msa_run(d, acc_m3d_resume_backend(), parse = parse_number(), store = path, resume = TRUE,
                                  verbose = FALSE), error = function(e) e)
      expect_false(inherits(resumed, "error"),
                   label = paste(info, "- resume:", if (inherits(resumed, "error")) conditionMessage(resumed) else "ok"))
      after <- acc_m3d_read_store(path)
      unlink(path)
      expect_false(is.null(after), label = paste(info, "- the store exists after resuming"))
      if (is.null(after)) next
      keys <- acc_m3d_run_key(after)
      expect_identical(sum(duplicated(keys)), 0L, label = paste(info, "- duplicate run keys after resuming"))
      expect_setequal(keys, design_keys)
      expect_identical(acc_m3d_comparable(after), expected,
                       label = paste(info, "- resumed store (without timestamp and latency_s) equals the uninterrupted store"))
    }
  })
}
