# QA / Red Team fuzz & boundary tests for M3b (fixed seed: 20261105)

qa_m3b_fuzz_anchor <- function(id) {
  root <- Sys.getenv("REPO_ROOT", unset = "")
  rel <- file.path("reference", "anchors", paste0(id, ".json"))
  candidates <- c(
    if (nzchar(root)) file.path(root, rel),
    testthat::test_path("..", "..", rel),
    system.file("validation", "latent", "anchors", paste0(id, ".json"), package = "llmsa")
  )
  hit <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (!length(hit)) stop("Anchor file not found: ", id, call. = FALSE)
  jsonlite::read_json(hit[1L], simplifyVector = TRUE)
}

qa_m3b_expect_clean_error <- function(expr, pattern = NULL) {
  err <- expect_no_warning(tryCatch(expr, error = identity))
  expect_s3_class(err, "error")
  expect_null(conditionCall(err))
  if (!is.null(pattern)) {
    expect_match(conditionMessage(err), pattern, fixed = TRUE)
  }
  invisible(err)
}

test_that("QA-M3b-FUZZ-1: msa_robustness rejects malformed transform and out-of-range logit inputs and handles extreme IEEE-754 proportions in (0, 1) (seed = 20261105)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  set.seed(20261105L)

  tol_arith <- qa_m3b_fuzz_anchor("ANK-TOL")$value$arithmetic$abs_tol
  d <- pb_design(7L, n_runs = 8L, seed = 20261105L)
  p_valid <- stats::runif(8L, 0.05, 0.95)

  bad_transforms <- list(
    "probit", "cloglog", "log", "", "NONE", "LOGIT", "lo", "none ",
    c("none", "logit"), character(0L), NA_character_, NULL, 1L, 0, TRUE, FALSE,
    list("logit"), factor("logit")
  )
  for (tr in bad_transforms) {
    qa_m3b_expect_clean_error(
      msa_robustness(d, p_valid, transform = tr),
      "`transform` must be one of 'none' or 'logit'."
    )
  }

  # Exact boundaries 0 and 1, out-of-interval values, non-finite, complex, non-numeric, dimensioned inputs
  bad_logit_responses <- list(
    replace(p_valid, 1L, 0),
    replace(p_valid, 8L, 1),
    c(0, rep(0.5, 6L), 1),
    replace(p_valid, 3L, -tol_arith),
    replace(p_valid, 4L, 1 + tol_arith),
    replace(p_valid, 2L, -100),
    replace(p_valid, 5L, 100),
    replace(p_valid, 6L, Inf),
    replace(p_valid, 7L, -Inf),
    as.character(p_valid),
    rep(c(TRUE, FALSE), 4L),
    as.complex(p_valid),
    matrix(p_valid, nrow = 8L, ncol = 1L),
    array(p_valid, dim = c(4L, 2L)),
    as.list(p_valid)
  )
  for (bad_y in bad_logit_responses) {
    err <- qa_m3b_expect_clean_error(
      msa_robustness(d, bad_y, transform = "logit"),
      "strictly between 0 and 1 for transform = 'logit'."
    )
    expect_match(conditionMessage(err), "(^|[^0-9.])0([^0-9.]|$)", perl = TRUE)
    expect_match(conditionMessage(err), "(^|[^0-9.])1([^0-9.]|$)", perl = TRUE)
  }

  # NA and NaN fail cleanly on the NA check before transformation
  qa_m3b_expect_clean_error(
    msa_robustness(d, replace(p_valid, 2L, NA_real_), transform = "logit"),
    "`response` must not contain NA."
  )
  qa_m3b_expect_clean_error(
    msa_robustness(d, replace(p_valid, 2L, NaN), transform = "logit"),
    "`response` must not contain NA."
  )
  qa_m3b_expect_clean_error(
    msa_robustness(d, p_valid[-1L], transform = "logit"),
    "`response` needs one value per run."
  )

  # Extreme IEEE-754 proportions strictly inside (0, 1)
  p_extreme <- c(
    .Machine$double.xmin,
    1e-200,
    1e-15,
    0.25,
    0.75,
    1 - 1e-15,
    1 - 1e-16,
    1 - .Machine$double.eps / 2
  )
  expect_true(all(p_extreme > 0 & p_extreme < 1))
  rob_ext <- msa_robustness(d, p_extreme, transform = "logit")
  rob_ext_man <- msa_robustness(d, stats::qlogis(p_extreme), transform = "none")
  expect_identical(rob_ext, rob_ext_man)
  expect_true(all(is.finite(rob_ext$effect)))
  expect_true(is.finite(attr(rob_ext, "pse")))
  expect_true(is.finite(attr(rob_ext, "me")))
  expect_true(is.finite(attr(rob_ext, "sme")))

  # Complement invariance on logit scale: p -> 1 - p negates effects and preserves |effect|, PSE, ME, SME
  p_comp <- c(1 / 64, 3 / 32, 5 / 16, 7 / 16, 9 / 16, 11 / 16, 29 / 32, 61 / 64)
  r1 <- msa_robustness(d, p_comp, transform = "logit")
  r2 <- msa_robustness(d, 1 - p_comp, transform = "logit")
  r2_aligned <- r2[match(r1$factor, r2$factor), , drop = FALSE]
  expect_equal(r1$effect, -r2_aligned$effect, tolerance = tol_arith)
  expect_equal(r1$t_lenth, -r2_aligned$t_lenth, tolerance = tol_arith)
  expect_identical(r1$active, r2_aligned$active)
  expect_identical(r1$active_simultaneous, r2_aligned$active_simultaneous)
  expect_equal(attr(r1, "pse"), attr(r2, "pse"), tolerance = tol_arith)
  expect_equal(attr(r1, "me"), attr(r2, "me"), tolerance = tol_arith)
  expect_equal(attr(r1, "sme"), attr(r2, "sme"), tolerance = tol_arith)
  expect_equal(attr(r1, "response_mean"), -attr(r2, "response_mean"), tolerance = tol_arith)
  expect_equal(attr(r1, "response_sd"), attr(r2, "response_sd"), tolerance = tol_arith)
})

test_that("QA-M3b-FUZZ-2: randomized metamorphic fuzzing of row permutations, sign flips, shifts, rescalings and degenerate PSE = 0 / m = 1 cases (seed = 20261105)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  set.seed(20261105L)

  tol_arith <- qa_m3b_fuzz_anchor("ANK-TOL")$value$arithmetic$abs_tol
  sizes <- as.integer(qa_m3b_fuzz_anchor("ANK-80")$value$sizes)

  for (trial in seq_len(20L)) {
    n <- sample(sizes, 1L)
    k <- sample(seq_len(n - 1L), 1L)
    d <- pb_design(k, n_runs = n, seed = 20261105L + trial)
    X <- attr(d, "coded")
    p <- stats::runif(n, 0.02, 0.98)
    alpha <- sample(c(0.01, 0.05, 0.10, 0.20), 1L)

    base_rob <- msa_robustness(d, p, alpha = alpha, transform = "logit")

    # 1. Joint row permutation + column reordering + column sign flips + log-odds shift
    perm_rows <- sample.int(n)
    perm_cols <- sample.int(k)
    signs <- sample(c(-1, 1), k, replace = TRUE)
    shift_eta <- stats::rnorm(1L, sd = 2)
    scale_eta <- stats::runif(1L, 0.5, 3.0)

    X_mod <- sweep(X[perm_rows, perm_cols, drop = FALSE], 2L, signs, `*`)
    colnames(X_mod) <- paste0("Ren_", colnames(X)[perm_cols])
    p_shifted <- stats::plogis(stats::qlogis(p[perm_rows]) + shift_eta)

    mod_logit <- msa_robustness(as.data.frame(X_mod), p_shifted,
                                factors = colnames(X_mod), alpha = alpha, transform = "logit")
    idx <- match(paste0("Ren_", base_rob$factor), mod_logit$factor)
    orig_col_idx <- match(base_rob$factor, colnames(X)[perm_cols])
    col_signs <- signs[orig_col_idx]

    expect_equal(mod_logit$effect[idx], col_signs * base_rob$effect, tolerance = tol_arith)
    expect_equal(attr(mod_logit, "pse"), attr(base_rob, "pse"), tolerance = tol_arith)
    expect_equal(attr(mod_logit, "me"), attr(base_rob, "me"), tolerance = tol_arith)
    expect_equal(attr(mod_logit, "sme"), attr(base_rob, "sme"), tolerance = tol_arith)

    # 2. Affine shift + positive scaling on transform = "none"
    y_raw <- stats::qlogis(p)
    y_aff <- shift_eta + scale_eta * y_raw[perm_rows]
    mod_none <- msa_robustness(as.data.frame(X_mod), y_aff,
                               factors = colnames(X_mod), alpha = alpha, transform = "none")
    expect_equal(mod_none$effect[idx], scale_eta * col_signs * base_rob$effect, tolerance = tol_arith)
    expect_equal(attr(mod_none, "pse"), scale_eta * attr(base_rob, "pse"), tolerance = tol_arith)
    expect_equal(attr(mod_none, "me"), scale_eta * attr(base_rob, "me"), tolerance = tol_arith)
    expect_equal(attr(mod_none, "sme"), scale_eta * attr(base_rob, "sme"), tolerance = tol_arith)
  }

  # Degenerate case 1: constant proportion -> all effects 0, PSE = 0, t_lenth = NA, nothing active
  d12 <- pb_design(11L, n_runs = 12L, randomize = FALSE)
  rob_zero <- msa_robustness(d12, rep(0.25, 12L), transform = "logit")
  expect_identical(attr(rob_zero, "pse"), 0)
  expect_identical(attr(rob_zero, "me"), 0)
  expect_identical(attr(rob_zero, "sme"), 0)
  expect_identical(rob_zero$t_lenth, rep(NA_real_, 11L))
  expect_false(any(rob_zero$active))
  expect_false(any(rob_zero$active_simultaneous))

  # Degenerate case 2: single factor m = 1 (df = 1/3) with non-syntactic factor name
  d1 <- pb_design(list("extra context" = c("none", "paragraph")), n_runs = 8L, seed = 20261105L)
  X1 <- attr(d1, "coded")
  p1 <- ifelse(X1[, 1L] > 0, 0.8, 0.2)
  rob_one <- msa_robustness(d1, p1, transform = "logit")
  expect_identical(nrow(rob_one), 1L)
  expect_identical(rob_one$factor, "extra context")
  expect_equal(rob_one$effect, 2 * stats::qlogis(0.8), tolerance = tol_arith)
  expect_equal(attr(rob_one, "pse"), 1.5 * abs(rob_one$effect), tolerance = tol_arith)
  expect_equal(rob_one$t_lenth, 1 / 1.5, tolerance = tol_arith)

  # Boundary errors in pb_design
  qa_m3b_expect_clean_error(pb_design(list(c("a", "b"))), "`factors` must be a named list")
  qa_m3b_expect_clean_error(pb_design(stats::setNames(list(c("a", "b")), "")), "`factors` must be a named list")
  qa_m3b_expect_clean_error(pb_design(list(a = "only_one")), "Every factor needs exactly two levels")
  qa_m3b_expect_clean_error(pb_design(list(a = c("x", "y", "z"))), "Every factor needs exactly two levels")
  qa_m3b_expect_clean_error(pb_design(4L, n_runs = 10L), "`n_runs` must be one of 8, 12, 16, 20, 24")
  qa_m3b_expect_clean_error(pb_design(4L, n_runs = NA_integer_), "`n_runs` must be one of 8, 12, 16, 20, 24")
  qa_m3b_expect_clean_error(pb_design(8L, n_runs = 8L), "8 factors need at least 12 runs.")
  qa_m3b_expect_clean_error(pb_design(11L, n_runs = 8L), "11 factors need at least 12 runs.")
  qa_m3b_expect_clean_error(pb_design(24L))
  qa_m3b_expect_clean_error(msa_robustness(data.frame(F1 = c(-1, 1)), c(0.2, 0.8)), "Give `factors`")
})
