# QA / Red Team fuzz & boundary tests for M1a (fixed seed: 20261029)
testthat::set_max_fails(Inf)

test_that("QA-M1a-004: msa_fit handles subnormal variance scales cleanly and rejects malformed numeric/grouping inputs consistently (seed = 20261029)", {
  set.seed(20261029L)
  runs <- msa_simulate(n_items = 5, n_prompts = 2, n_models = 1, n_reps = 2,
                       vc = list(item = 1, prompt = 0.1, residual = 0.1), seed = 20261029L)
  fit_ref <- suppressMessages(msa_fit(runs, type = "numeric"))
  vc_ref <- stats::setNames(fit_ref$vc$variance, fit_ref$vc$source)

  # 1. Subnormal variance scale (1e-161 -> variance ~ 1e-322, losing > 4% accuracy due to denormal quantization):
  # Either msa_fit rejects the unrepresentable/denormal variance scale with a named error,
  # or if it returns a fit, its rescaled components must satisfy ANK-TOL.invariance (1e-6 * sigma2_TV).
  runs_sub <- runs
  runs_sub$value <- runs$value * 1e-161
  res_sub <- tryCatch(suppressMessages(msa_fit(runs_sub, type = "numeric")), error = function(e) e)
  if (!inherits(res_sub, "error")) {
    vc_sub <- stats::setNames(res_sub$vc$variance, res_sub$vc$source) / (1e-161)^2
    rel_err <- max(abs(vc_sub[names(vc_ref)] - vc_ref)) / sum(vc_ref)
    expect_lte(rel_err, 1e-6)
  } else {
    expect_match(conditionMessage(res_sub), "representable|scale", ignore.case = TRUE)
  }

  # 2. NaN vs character "NaN" consistency: numeric NaN is treated as missing without warning,
  # whereas character "NaN" must either be treated identically as missing without false parse warning,
  # or numeric NaN must be handled consistently with character "NaN" / Inf.
  runs_num_nan <- runs
  runs_num_nan$value[1] <- NaN
  runs_chr_nan <- runs
  runs_chr_nan$value <- as.character(runs$value)
  runs_chr_nan$value[1] <- "NaN"

  warn_num <- character()
  fit_num <- withCallingHandlers(
    suppressMessages(msa_fit(runs_num_nan, type = "numeric")),
    warning = function(w) { warn_num <<- c(warn_num, conditionMessage(w)); invokeRestart("muffleWarning") }
  )
  warn_chr <- character()
  fit_chr <- withCallingHandlers(
    suppressMessages(msa_fit(runs_chr_nan, type = "numeric")),
    warning = function(w) { warn_chr <<- c(warn_chr, conditionMessage(w)); invokeRestart("muffleWarning") }
  )
  expect_identical(length(warn_chr), length(warn_num))
  expect_identical(fit_chr$n$observations, fit_num$n$observations)

  # 3. Missing values (NA) in grouping columns (item_id, prompt_id, model_id, block) must be rejected
  # even when explicit lme4 arguments (...) are supplied:
  runs_na_grp <- runs
  runs_na_grp$item_id[1:2] <- NA_character_
  err_na_grp <- tryCatch(
    suppressMessages(msa_fit(runs_na_grp, type = "numeric", control = lme4::lmerControl())),
    error = function(e) conditionMessage(e)
  )
  expect_true(is.character(err_na_grp) && grepl("missing|NA", err_na_grp, ignore.case = TRUE))
})

test_that("QA-M1a-005: msa_grr validates threshold argument and validation_verify_resources checks NIST dataset manifest and unlisted anchor files (seed = 20261029)", {
  set.seed(20261029L)
  runs <- msa_simulate(n_items = 5, n_prompts = 2, n_models = 1, n_reps = 2, seed = 20261029L)
  fit <- suppressMessages(msa_fit(runs, type = "numeric", interactions = FALSE))

  # 1. Invalid threshold vectors in msa_grr() must raise a clean, named error mentioning threshold:
  bad_thresholds <- list(c(30, 10), c(10), c(10, 20, 30), c(NA_real_, 30), c(10, Inf), c(-5, 30), "invalid")
  th_ok <- vapply(bad_thresholds, function(bad_th) {
    err <- tryCatch(msa_grr(fit, threshold = bad_th), error = function(e) conditionMessage(e))
    is.character(err) && grepl("threshold", err, ignore.case = TRUE)
  }, logical(1))
  expect_true(all(th_ok))

  # 2. validation_verify_resources() must reject a manifest missing datasets or unlisted files in anchors/:
  e <- new.env(parent = globalenv())
  sys.source(system.file("validation", "numeric", "reference_checks.R", package = "llmsa", mustWork = TRUE), envir = e)
  orig <- system.file("validation", "numeric", package = "llmsa", mustWork = TRUE)

  res_extra <- tempfile("qa-res-extra-")
  dir.create(res_extra)
  on.exit(unlink(res_extra, recursive = TRUE), add = TRUE)
  stopifnot(all(file.copy(list.files(orig, full.names = TRUE), res_extra, recursive = TRUE)))
  writeLines("{}", file.path(res_extra, "anchors", "ANK-99.json"))
  err_extra <- tryCatch(e$validation_verify_resources(res_extra), error = function(err) conditionMessage(err))
  expect_true(is.character(err_extra) && grepl("anchor|manifest|unexpected|unlisted", err_extra, ignore.case = TRUE))

  res_nods <- tempfile("qa-res-nods-")
  dir.create(res_nods)
  on.exit(unlink(res_nods, recursive = TRUE), add = TRUE)
  stopifnot(all(file.copy(list.files(orig, full.names = TRUE), res_nods, recursive = TRUE)))
  mf_path <- file.path(res_nods, "SOURCES.json")
  mf <- jsonlite::fromJSON(mf_path, simplifyVector = FALSE)
  mf$datasets <- NULL
  jsonlite::write_json(mf, mf_path, auto_unbox = TRUE, pretty = TRUE, digits = NA)
  err_nods <- tryCatch(e$validation_verify_resources(res_nods), error = function(err) conditionMessage(err))
  expect_true(is.character(err_nods) && grepl("dataset|manifest|missing|incomplete", err_nods, ignore.case = TRUE))
})
