# QA / Red Team E2E counterexamples for M1b (fixed seed: 20261031)
testthat::set_max_fails(Inf)

qa_m1b_binary_runs <- function(seed = 20261031L, items = 15L, prompts = 3L, models = 3L, reps = 2L, blocks = 1L) {
  set.seed(seed)
  grid <- expand.grid(
    rep = seq_len(reps),
    block = seq_len(blocks),
    model_id = paste0("M", seq_len(models)),
    prompt_id = paste0("P", seq_len(prompts)),
    item_id = sprintf("I%02d", seq_len(items)),
    stringsAsFactors = FALSE
  )
  item_eff <- stats::rnorm(items, 0, 1.2)[match(grid$item_id, sprintf("I%02d", seq_len(items)))]
  prompt_eff <- stats::rnorm(prompts, 0, 0.4)[match(grid$prompt_id, paste0("P", seq_len(prompts)))]
  model_eff <- stats::rnorm(models, 0, 0.4)[match(grid$model_id, paste0("M", seq_len(models)))]
  grid$value <- stats::rbinom(nrow(grid), size = 1L, prob = stats::plogis(item_eff + prompt_eff + model_eff))
  as_msa_runs(grid)
}

qa_m1b_ordinal_runs <- function(seed = 20261031L, items = 16L, prompts = 4L, models = 3L, reps = 2L, blocks = 1L) {
  set.seed(seed)
  grid <- expand.grid(
    rep = seq_len(reps),
    block = seq_len(blocks),
    model_id = paste0("M", seq_len(models)),
    prompt_id = paste0("P", seq_len(prompts)),
    item_id = sprintf("I%02d", seq_len(items)),
    stringsAsFactors = FALSE
  )
  item_eff <- stats::rnorm(items, 0, 1.2)[match(grid$item_id, sprintf("I%02d", seq_len(items)))]
  prompt_eff <- stats::rnorm(prompts, 0, 0.7)[match(grid$prompt_id, paste0("P", seq_len(prompts)))]
  model_eff <- stats::rnorm(models, 0, 0.5)[match(grid$model_id, paste0("M", seq_len(models)))]
  latent <- item_eff + prompt_eff + model_eff + stats::rnorm(nrow(grid))
  grid$value <- paste0("c", findInterval(latent, c(-1.5, -0.5, 0.5, 1.5)) + 1L)
  as_msa_runs(grid)
}

test_that("QA-M1b-001: msa_boot succeeds on binary fits created with explicit control or lme4 arguments passed via ... (seed = 20261031)", {
  set.seed(20261031L)
  runs <- qa_m1b_binary_runs(seed = 20261031L)

  ctrl <- lme4::glmerControl(optimizer = "bobyqa")
  fit <- suppressWarnings(msa_fit(runs, type = "binary", link = "logit", control = ctrl))
  expect_s3_class(fit, "msa_fit")

  # End-to-end user flow: msa_fit(type = "binary", control = ...) -> msa_grr -> msa_boot
  grr <- msa_grr(fit)
  expect_s3_class(grr, "msa_grr")

  boot_res <- tryCatch(
    suppressWarnings(msa_boot(fit, nsim = 2, seed = 20261031L)),
    error = function(e) e
  )
  expect_false(inherits(boot_res, "error"),
               info = if (inherits(boot_res, "error")) conditionMessage(boot_res) else NULL)
  expect_s3_class(boot_res, "msa_boot")

  # Also when msa_fit(type = "binary", control = local_ctrl) is called inside a helper function:
  fit_scoped <- (function(r) {
    local_ctrl <- lme4::glmerControl(optimizer = "bobyqa")
    suppressWarnings(msa_fit(r, type = "binary", link = "logit", control = local_ctrl))
  })(runs)
  boot_scoped <- tryCatch(
    suppressWarnings(msa_boot(fit_scoped, nsim = 2, seed = 20261031L)),
    error = function(e) e
  )
  expect_false(inherits(boot_scoped, "error"),
               info = if (inherits(boot_scoped, "error")) conditionMessage(boot_scoped) else NULL)
})

test_that("QA-M1b-002: msa_fit for ordinal and binary outcomes supports subset/weights expressions and keeps fit$data and fit$n consistent with fit$model (seed = 20261031)", {
  set.seed(20261031L)
  runs_bin <- qa_m1b_binary_runs(seed = 20261031L, items = 12L, prompts = 3L, models = 3L, reps = 2L)
  runs_ord <- qa_m1b_ordinal_runs(seed = 20261031L, items = 12L, prompts = 3L, models = 3L, reps = 2L)
  ord_levels <- paste0("c", 1:5)

  # 1. Unquoted subset expression referencing internal column `item` as documented in ?msa_fit:
  fit_bin_expr <- tryCatch(
    suppressWarnings(msa_fit(runs_bin, type = "binary", subset = item != "I01")),
    error = function(e) e
  )
  expect_false(inherits(fit_bin_expr, "error"),
               info = if (inherits(fit_bin_expr, "error")) conditionMessage(fit_bin_expr) else NULL)

  fit_ord_expr <- tryCatch(
    suppressWarnings(msa_fit(runs_ord, type = "ordinal", levels = ord_levels, subset = item != "I01")),
    error = function(e) e
  )
  expect_false(inherits(fit_ord_expr, "error"),
               info = if (inherits(fit_ord_expr, "error")) conditionMessage(fit_ord_expr) else NULL)

  # 2. Numeric index subset excluding item I01: fit$data and fit$n must match the analysed observations
  keep <- which(runs_bin$item_id != "I01")
  fit_bin_sub <- suppressWarnings(msa_fit(runs_bin, type = "binary", subset = keep))
  expect_identical(fit_bin_sub$n$observations, as.integer(stats::nobs(fit_bin_sub$model)))
  expect_identical(nrow(fit_bin_sub$data), as.integer(stats::nobs(fit_bin_sub$model)))
  expect_identical(fit_bin_sub$n$items, as.integer(lme4::ngrps(fit_bin_sub$model)[["item"]]))

  fit_ord_sub <- suppressWarnings(msa_fit(runs_ord, type = "ordinal", levels = ord_levels, subset = keep))
  expect_identical(fit_ord_sub$n$observations, as.integer(stats::nobs(fit_ord_sub$model)))
  expect_identical(nrow(fit_ord_sub$data), as.integer(stats::nobs(fit_ord_sub$model)))
  expect_identical(fit_ord_sub$n$items, nlevels(droplevels(stats::model.frame(fit_ord_sub$model)$item)))
})

test_that("QA-M1b-003: ordinal msa_fit does not falsely mark interior random-effect fits as singular when a two-level fixed factor has zero contrast, and rejects collinear two-level factors or <=2-level interactions cleanly (seed = 20261031)", {
  set.seed(20261031L)
  ord_levels <- paste0("c", 1:5)
  base_runs <- qa_m1b_ordinal_runs(seed = 20261031L, items = 20L, prompts = 4L, models = 1L, reps = 2L, blocks = 1L)

  # 1. Two blocks with zero block drift (identical responses in block 1 and block 2),
  # while random effects item and prompt have interior variances > 0.5:
  runs_2blk <- as_msa_runs(rbind(
    transform(base_runs, block = 1L),
    transform(base_runs, block = 2L)
  ))
  fit_2blk <- suppressWarnings(msa_fit(runs_2blk, type = "ordinal", levels = ord_levels))
  ranef_vars <- vapply(ordinal::VarCorr(fit_2blk$model), function(v) as.numeric(v)[1L], numeric(1))
  expect_true(all(ranef_vars > 0.1))
  expect_identical(fit_2blk$derived, "block")
  expect_false(fit_2blk$singular)

  # 2. Collinear two-level fixed factors (model M1 only in block 1, M2 only in block 2):
  # must not silently return variance = 0 for the dropped rank-deficient coefficient
  runs_conf <- runs_2blk
  runs_conf$model_id <- ifelse(runs_conf$block == 1L, "M1", "M2")
  err_conf <- tryCatch(
    suppressWarnings(msa_fit(runs_conf, type = "ordinal", levels = ord_levels)),
    error = function(e) conditionMessage(e)
  )
  expect_true(
    is.character(err_conf) && grepl("identifiable|collinear|rank|confound", err_conf, ignore.case = TRUE),
    info = paste("Expected named identifiability/rank-deficiency error, got:",
                 if (is.character(err_conf)) err_conf else "msa_fit object with silent 0 variance")
  )

  # 3. Ordinal fit with interactions = TRUE when an interaction has only 2 observed levels:
  # must not crash with raw internal stopifnot `all(sapply(gfl, nlevels) > 2) is not TRUE`
  runs_int2 <- qa_m1b_ordinal_runs(seed = 20261031L, items = 12L, prompts = 2L, models = 2L, reps = 2L, blocks = 1L)
  runs_int2 <- runs_int2[(runs_int2$prompt_id == "P1" & runs_int2$model_id == "M1") |
                           (runs_int2$prompt_id == "P2" & runs_int2$model_id == "M2"), ]
  err_int2 <- tryCatch(
    suppressWarnings(msa_fit(runs_int2, type = "ordinal", levels = ord_levels, interactions = TRUE)),
    error = function(e) conditionMessage(e)
  )
  if (is.character(err_int2)) {
    expect_false(grepl("sapply(gfl, nlevels)", err_int2, fixed = TRUE))
  }
})

test_that("QA-M1b-004: test-validation-latent.R succeeds in a staged package copy with REPO_ROOT set (as in 86-mutgate.sh / r-mutation.R) (seed = 20261031)", {
  set.seed(20261031L)
  e <- new.env(parent = globalenv())
  sys.source(system.file("validation", "numeric", "reference_checks.R", package = "llmsa", mustWork = TRUE), envir = e)
  repo_root <- e$validation_find_repo()
  skip_if(is.null(repo_root), "Repository root required for staged-copy test")

  pkg_root <- normalizePath(getNamespaceInfo(asNamespace("llmsa"), "path"), mustWork = TRUE)
  stage <- tempfile("qa-m1b-stage-")
  dir.create(stage, recursive = TRUE)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)

  for (part in c("DESCRIPTION", "NAMESPACE", "R", "inst", "data", "tests/testthat")) {
    src <- file.path(pkg_root, part)
    if (!file.exists(src)) src <- file.path(repo_root, part)
    if (file.exists(src)) {
      dst <- file.path(stage, dirname(part))
      dir.create(dst, recursive = TRUE, showWarnings = FALSE)
      expect_true(file.copy(src, dst, recursive = TRUE))
    }
  }

  old_repo <- Sys.getenv("REPO_ROOT", unset = NA_character_)
  on.exit({
    if (is.na(old_repo)) Sys.unsetenv("REPO_ROOT") else Sys.setenv(REPO_ROOT = old_repo)
  }, add = TRUE)
  Sys.setenv(REPO_ROOT = repo_root)

  res <- callr::r(
    function(stage_path, root) {
      Sys.setenv(REPO_ROOT = root)
      as.data.frame(testthat::test_file(
        file.path(stage_path, "tests/testthat/test-validation-latent.R"),
        reporter = "silent",
        load_package = "source"
      ))
    },
    args = list(stage, repo_root)
  )
  expect_identical(sum(res$failed), 0L)
  expect_false(any(res$error))
})
