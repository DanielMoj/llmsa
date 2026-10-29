# QA / Red Team E2E counterexamples for M1a (fixed seed: 20261029)
testthat::set_max_fails(Inf)

test_that("QA-M1a-001: msa_boot succeeds on fits created with explicit control or lme4 arguments passed via ... (seed = 20261029)", {
  set.seed(20261029L)
  runs <- msa_simulate(n_items = 6, n_prompts = 2, n_models = 1, n_reps = 2,
                       vc = list(item = 1, prompt = 0.2, residual = 0.1), seed = 20261029L)

  ctrl <- lme4::lmerControl(optimizer = "bobyqa")
  fit_bobyqa <- suppressMessages(msa_fit(runs, type = "numeric", interactions = FALSE, control = ctrl))
  expect_identical(fit_bobyqa$numerics$method, "lmer")
  expect_identical(fit_bobyqa$model@optinfo$optimizer, "bobyqa")

  # End-to-end user flow: msa_fit(..., control = ...) -> msa_grr() -> msa_boot()
  grr <- msa_grr(fit_bobyqa)
  expect_s3_class(grr, "msa_grr")
  boot_bobyqa <- tryCatch(msa_boot(fit_bobyqa, nsim = 3, seed = 20261029L), error = function(e) e)
  expect_false(inherits(boot_bobyqa, "error"),
               info = if (inherits(boot_bobyqa, "error")) conditionMessage(boot_bobyqa) else "")
  if (!inherits(boot_bobyqa, "error")) {
    expect_s3_class(boot_bobyqa, "msa_boot")
    expect_identical(nrow(attr(boot_bobyqa, "boot")), 3L)
  }

  # Also when msa_fit is called inside a helper function where local variables go out of scope:
  fit_from_helper <- (function(r) {
    local_ctrl <- lme4::lmerControl(optimizer = "bobyqa")
    suppressMessages(msa_fit(r, type = "numeric", interactions = FALSE, control = local_ctrl))
  })(runs)
  boot_helper <- tryCatch(msa_boot(fit_from_helper, nsim = 3, seed = 20261029L), error = function(e) e)
  expect_false(inherits(boot_helper, "error"),
               info = if (inherits(boot_helper, "error")) conditionMessage(boot_helper) else "")
})

test_that("QA-M1a-002: msa_fit with subset or NA-dropping lme4 arguments keeps fit$data, fit$n and input_rows consistent with fit$model (seed = 20261029)", {
  set.seed(20261029L)
  runs <- msa_simulate(n_items = 6, n_prompts = 2, n_models = 1, n_reps = 2,
                       vc = list(item = 1, prompt = 0.2, residual = 0.1), seed = 20261029L)

  # 1. Explicit subset expression using factor column names
  fit_expr <- tryCatch(
    suppressMessages(msa_fit(runs, type = "numeric", interactions = FALSE, subset = item != "I001")),
    error = function(e) e
  )
  expect_false(inherits(fit_expr, "error"),
               info = if (inherits(fit_expr, "error")) conditionMessage(fit_expr) else "")

  # 2. Numeric index subset removing all observations of item I001 (rows with item_id == "I001")
  keep_idx <- which(runs$item_id != "I001")
  fit_sub <- suppressMessages(msa_fit(runs, type = "numeric", interactions = FALSE, subset = keep_idx))
  expect_true(
    identical(fit_sub$n$observations, as.integer(stats::nobs(fit_sub$model))) &&
      identical(nrow(fit_sub$data), as.integer(stats::nobs(fit_sub$model))) &&
      identical(length(fit_sub$numerics$input_rows), as.integer(stats::nobs(fit_sub$model))) &&
      identical(fit_sub$n$items, as.integer(lme4::ngrps(fit_sub$model)[["item"]]))
  )

  # 3. Weights containing NA (dropped by lme4 na.omit during model fitting)
  w <- rep(1, nrow(runs))
  w[runs$item_id == "I001"] <- NA_real_
  fit_w <- suppressMessages(msa_fit(runs, type = "numeric", interactions = FALSE, weights = w))
  expect_true(
    identical(fit_w$n$observations, as.integer(stats::nobs(fit_w$model))) &&
      identical(nrow(fit_w$data), as.integer(stats::nobs(fit_w$model))) &&
      identical(length(fit_w$numerics$input_rows), as.integer(stats::nobs(fit_w$model))) &&
      identical(fit_w$n$items, as.integer(lme4::ngrps(fit_w$model)[["item"]]))
  )
})

test_that("QA-M1a-003: multi-factor and unbalanced designs with zero residual variance fail with named residual-variance diagnostic without CHOLMOD warnings (seed = 20261029)", {
  set.seed(20261029L)

  # Case A: Balanced 2-way crossed design (4 items x 2 prompts x 2 reps) with identical replicates in each cell
  # and non-additive cell values whose floating-point cell means leave ~1e-33 rounding residue
  runs_bal <- expand.grid(item_id = paste0("I", 1:4), prompt_id = paste0("P", 1:2),
                          model_id = "M1", rep = 1:2, stringsAsFactors = FALSE)
  cell_key <- paste(runs_bal$item_id, runs_bal$prompt_id)
  cell_vals <- c(1.1, 2.3, 0.7, 4.5, 3.2, 1.8, 5.1, 0.9)
  runs_bal$value <- cell_vals[match(cell_key, unique(cell_key))]
  runs_bal <- as_msa_runs(runs_bal)

  warn_bal <- character()
  err_bal <- tryCatch(
    withCallingHandlers(
      suppressMessages(msa_fit(runs_bal, type = "numeric", interactions = TRUE)),
      warning = function(w) {
        warn_bal <<- c(warn_bal, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) conditionMessage(e)
  )
  expect_match(as.character(err_bal), "residual variance", ignore.case = TRUE)
  expect_false(any(grepl("CHOLMOD", warn_bal, fixed = TRUE)))

  # Case B: Unbalanced 1-way design (1 replicate dropped) with identical replicates in every cell
  runs_unb <- data.frame(
    item_id = c("I1", "I1", "I2", "I2", "I3", "I3", "I4", "I4", "I4"),
    prompt_id = "P1", model_id = "M1",
    rep = c(1L, 2L, 1L, 2L, 1L, 2L, 1L, 2L, 3L),
    value = c(10, 10, 20, 20, 35, 35, 50, 50, 50),
    stringsAsFactors = FALSE
  )
  runs_unb <- as_msa_runs(runs_unb)

  warn_unb <- character()
  err_unb <- tryCatch(
    withCallingHandlers(
      suppressMessages(msa_fit(runs_unb, type = "numeric")),
      warning = function(w) {
        warn_unb <<- c(warn_unb, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) conditionMessage(e)
  )
  expect_match(as.character(err_unb), "residual variance", ignore.case = TRUE)
  expect_false(any(grepl("CHOLMOD", warn_unb, fixed = TRUE)))
})
