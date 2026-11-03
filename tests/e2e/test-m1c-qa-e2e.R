# QA / Red Team E2E tests for M1c (fixed seed: 20261103)
testthat::set_max_fails(Inf)

qa_m1c_numeric_runs <- function(seed = 20261103L, items = 10L, prompts = 3L,
                                models = 3L, reps = 2L, blocks = 2L) {
  set.seed(seed)
  grid <- expand.grid(
    rep = seq_len(reps),
    block = seq_len(blocks),
    model_id = paste0("M", seq_len(models)),
    prompt_id = paste0("P", seq_len(prompts)),
    item_id = sprintf("I%02d", seq_len(items)),
    stringsAsFactors = FALSE
  )
  item_eff <- stats::rnorm(items, sd = 1.0)[match(grid$item_id, sprintf("I%02d", seq_len(items)))]
  prompt_eff <- stats::rnorm(prompts, sd = 0.25)[match(grid$prompt_id, paste0("P", seq_len(prompts)))]
  model_eff <- stats::rnorm(models, sd = 0.25)[match(grid$model_id, paste0("M", seq_len(models)))]
  block_eff <- stats::rnorm(blocks, sd = 0.10)[grid$block]
  grid$value <- item_eff + prompt_eff + model_eff + block_eff + stats::rnorm(nrow(grid), sd = 0.25)
  as_msa_runs(grid)
}

qa_m1c_binary_runs <- function(seed = 20261103L, items = 24L, prompts = 3L,
                               models = 3L, reps = 2L) {
  set.seed(seed)
  grid <- expand.grid(
    rep = seq_len(reps),
    model_id = paste0("M", seq_len(models)),
    prompt_id = paste0("P", seq_len(prompts)),
    item_id = sprintf("I%02d", seq_len(items)),
    stringsAsFactors = FALSE
  )
  item_eff <- stats::rnorm(items, sd = 1.1)[match(grid$item_id, sprintf("I%02d", seq_len(items)))]
  prompt_eff <- stats::rnorm(prompts, sd = 0.35)[match(grid$prompt_id, paste0("P", seq_len(prompts)))]
  model_eff <- stats::rnorm(models, sd = 0.35)[match(grid$model_id, paste0("M", seq_len(models)))]
  eta <- item_eff + prompt_eff + model_eff
  grid$value <- stats::rbinom(nrow(grid), size = 1L, prob = stats::plogis(eta))
  as_msa_runs(grid)
}

test_that("QA-M1c-E2E-1: msa_boot matches bootMer across levels, seeds and snow clusters while separating failed and singular counts (seed = 20261103)", {
  runs_num <- qa_m1c_numeric_runs(seed = 20261103L)
  fit_num <- suppressMessages(msa_fit(runs_num, type = "numeric"))
  grr_num <- msa_grr(fit_num)

  b95_a <- suppressWarnings(msa_boot(fit_num, nsim = 12L, level = 0.95, seed = 20261103L))
  b95_b <- suppressWarnings(msa_boot(fit_num, nsim = 12L, level = 0.95, seed = 20261103L))
  expect_identical(b95_a, b95_b)
  expect_identical(b95_a$statistic, names(grr_num$summary))
  expect_equal(b95_a$estimate, unname(grr_num$summary), tolerance = 1e-12)
  expect_identical(dim(attr(b95_a, "boot")), c(12L, 6L))
  expect_identical(colnames(attr(b95_a, "boot")), names(grr_num$summary))
  expect_false(".singular" %in% colnames(attr(b95_a, "boot")))
  expect_true(is.finite(attr(b95_a, "n_failed")) && attr(b95_a, "n_failed") >= 0L)
  expect_true(is.finite(attr(b95_a, "n_singular")) && attr(b95_a, "n_singular") >= 0L)
  expect_lte(attr(b95_a, "n_failed") + attr(b95_a, "n_singular"), 12L)

  b90 <- suppressWarnings(msa_boot(fit_num, nsim = 12L, level = 0.90, seed = 20261103L))
  expect_identical(attr(b90, "boot"), attr(b95_a, "boot"))
  expect_identical(attr(b90, "n_failed"), attr(b95_a, "n_failed"))
  expect_identical(attr(b90, "n_singular"), attr(b95_a, "n_singular"))
  expect_true(all(b90$lower >= b95_a$lower - 1e-12))
  expect_true(all(b90$upper <= b95_a$upper + 1e-12))

  lines <- capture.output(ret <- withVisible(print(b95_a)))
  expect_false(ret$visible)
  expect_identical(ret$value, b95_a)
  expect_true(any(grepl(sprintf("^  %d failed or non-finite replicates", attr(b95_a, "n_failed")), lines)))
  expect_true(any(grepl(sprintf("^  %d singular replicates retained", attr(b95_a, "n_singular")), lines)))

  runs_bin <- qa_m1c_binary_runs(seed = 20261103L)
  fit_bin <- suppressWarnings(suppressMessages(msa_fit(runs_bin, type = "binary", link = "logit")))
  b_bin <- suppressWarnings(msa_boot(fit_bin, nsim = 8L, level = 0.95, seed = 20261103L))
  expect_identical(dim(attr(b_bin, "boot")), c(8L, 6L))
  expect_lte(attr(b_bin, "n_failed") + attr(b_bin, "n_singular"), 8L)
})

test_that("QA-M1c-E2E-2: latent repeatability note appears in print.msa_grr and msa_report for ordinal and binary but never for numeric (seed = 20261103)", {
  note <- paste0(
    "On the latent scale, Repeatability is the residual variance fixed by the link, ",
    "not a measurement of disagreement between replicates; see the share of cells ",
    "with identical replicates from msa_agreement()."
  )

  fit_num <- suppressMessages(msa_fit(ic50_demo, type = "numeric"))
  grr_num <- msa_grr(fit_num)
  out_num <- capture.output(print(grr_num))
  expect_false(any(grepl("On the latent scale", out_num, fixed = TRUE)))

  fit_ord <- suppressWarnings(suppressMessages(
    msa_fit(acmg_demo, type = "ordinal", levels = c("B", "LB", "VUS", "LP", "P"), link = "probit")
  ))
  grr_ord <- msa_grr(fit_ord)
  out_ord <- capture.output(print(grr_ord))
  expect_identical(sum(trimws(out_ord) == note), 1L)

  runs_bin <- qa_m1c_binary_runs(seed = 20261103L)
  fit_bin <- suppressWarnings(suppressMessages(msa_fit(runs_bin, type = "binary", link = "logit")))
  grr_bin <- msa_grr(fit_bin)
  out_bin <- capture.output(print(grr_bin))
  expect_identical(sum(trimws(out_bin) == note), 1L)

  if (requireNamespace("rmarkdown", quietly = TRUE) && rmarkdown::pandoc_available()) {
    md_fmt <- rmarkdown::md_document(variant = "gfm", pandoc_args = "--wrap=none")
    f_num <- tempfile(fileext = ".md")
    f_ord <- tempfile(fileext = ".md")
    f_bin <- tempfile(fileext = ".md")
    on.exit(unlink(c(f_num, f_ord, f_bin)), add = TRUE)

    msa_report(grr_num, output_file = f_num, output_format = md_fmt, quiet = TRUE)
    msa_report(grr_ord, output_file = f_ord, output_format = md_fmt, quiet = TRUE)
    msa_report(grr_bin, output_file = f_bin, output_format = md_fmt, quiet = TRUE)

    md_num <- readLines(f_num, warn = FALSE)
    md_ord <- readLines(f_ord, warn = FALSE)
    md_bin <- readLines(f_bin, warn = FALSE)

    expect_false(any(grepl("On the latent scale", md_num, fixed = TRUE)))
    for (lines in list(md_ord, md_bin)) {
      idx_rep <- grep("^[-*] Repeatability .* reproducibility .* of study variation", lines, ignore.case = TRUE)
      expect_length(idx_rep, 1L)
      expect_match(lines[idx_rep + 1L], "On the latent scale, Repeatability is the residual variance fixed by the link", fixed = TRUE)
    }
  }
})

test_that("QA-M1c-E2E-3: msa_fit ordinal control default, explicit control replacement and direct dot-option precedence (seed = 20261103)", {
  e <- new.env(parent = emptyenv())
  utils::data("wine", package = "ordinal", envir = e)
  w <- e$wine
  runs <- as_msa_runs(data.frame(
    item_id = as.character(w$bottle),
    prompt_id = as.character(w$judge),
    model_id = "M1",
    rep = 1L,
    value = as.character(w$rating),
    stringsAsFactors = FALSE
  ))
  lvls <- levels(w$rating)

  fit_default <- msa_fit(runs, type = "ordinal", levels = lvls, link = "probit")
  expect_identical(fit_default$model$control$optCtrl$iter.max, 2000)
  expect_identical(fit_default$model$control$optCtrl$eval.max, 4000)

  fit_empty <- msa_fit(runs, type = "ordinal", levels = lvls, link = "probit", control = list())
  expect_null(fit_empty$model$control$optCtrl$iter.max)
  expect_null(fit_empty$model$control$optCtrl$eval.max)

  fit_partial <- msa_fit(runs, type = "ordinal", levels = lvls, link = "probit", control = list(eval.max = 60))
  expect_null(fit_partial$model$control$optCtrl$iter.max)
  expect_identical(fit_partial$model$control$optCtrl$eval.max, 60)

  fit_dot <- suppressWarnings(msa_fit(runs, type = "ordinal", levels = lvls, link = "probit", iter.max = 9))
  expect_identical(fit_dot$model$control$optCtrl$iter.max, 9)
  expect_identical(fit_dot$model$control$optCtrl$eval.max, 4000)
})

test_that("QA-M1c-E2E-4: boot_coverage helpers and offline reader preserve deterministic streams, merge invariants and generator isolation (seed = 20261103)", {
  testthat::skip_if_not_installed("jsonlite")
  testthat::skip_if_not_installed("digest")

  reader_env <- new.env(parent = globalenv())
  sys.source(system.file("validation", "sim", "boot_coverage_results.R", package = "llmsa", mustWork = TRUE), envir = reader_env)
  expect_false(exists("boot_generate", envir = reader_env, inherits = FALSE))
  expect_false(exists("sim_generate", envir = reader_env, inherits = FALSE))
  checked <- reader_env$boot_read_results()
  expect_identical(checked$mode, "check")
  expect_setequal(unique(checked$data$scenario), c("S-boot-1", "S-boot-7"))

  sim_env <- new.env(parent = globalenv())
  sys.source(system.file("validation", "sim", "boot_coverage_helpers.R", package = "llmsa", mustWork = TRUE), envir = sim_env)
  sc <- sim_env$boot_scenarios()

  set.seed(20261103L)
  rng_before <- .Random.seed
  d_17 <- lapply(sc[c("S-boot-1", "S-boot-7")], sim_env$boot_generate, rep = 3L)
  d_71 <- lapply(sc[c("S-boot-7", "S-boot-1")], sim_env$boot_generate, rep = 3L)
  expect_identical(.Random.seed, rng_before)
  expect_identical(d_17[["S-boot-1"]], d_71[["S-boot-1"]])
  expect_identical(d_17[["S-boot-7"]], d_71[["S-boot-7"]])
})
