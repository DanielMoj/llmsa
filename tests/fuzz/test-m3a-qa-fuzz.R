# QA / Red Team fuzz & boundary tests for M3a (fixed seed: 20261105)

qa_m3a_fuzz_anchor <- function(id) {
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

qa_m3a_expect_clean_error <- function(expr, pattern = NULL) {
  err <- expect_no_warning(tryCatch(expr, error = identity))
  expect_s3_class(err, "error")
  expect_null(conditionCall(err))
  if (!is.null(pattern)) {
    expect_match(conditionMessage(err), pattern, fixed = TRUE)
  }
  invisible(err)
}

qa_m3a_capture_messages <- function(expr) {
  msgs <- character()
  val <- withCallingHandlers(
    expr,
    message = function(m) {
      msgs <<- c(msgs, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  list(value = val, messages = msgs)
}

test_that("QA-M3a-FUZZ-1: msa_agreement metamorphic invariances, separator-collision resistance and boundary / undefined cases (seed = 20261105)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  set.seed(20261105L)

  tol_arith <- qa_m3a_fuzz_anchor("ANK-TOL")$value$arithmetic$abs_tol

  # 1. Randomized metamorphic invariance across 15 trials:
  #    - row permutation
  #    - reversal of scale order (levels -> rev(levels)) preserves unweighted, linear, quadratic kappas and alphas
  #    - bijective relabelling of item_id / prompt_id / model_id with separator characters (|, ., :, whitespace)
  for (trial in seq_len(15L)) {
    k <- sample(2:6, 1L)
    lv <- paste0("cat_", seq_len(k))
    n_items <- sample(4:8, 1L)
    n_prompts <- sample(2:3, 1L)
    n_models <- sample(2:3, 1L)
    n_reps <- sample(2:3, 1L)

    d <- expand.grid(
      rep = seq_len(n_reps),
      prompt_id = paste0("p|", seq_len(n_prompts)),
      model_id = paste0("m.", seq_len(n_models)),
      item_id = paste0("i:", seq_len(n_items)),
      stringsAsFactors = FALSE
    )
    d$value <- sample(c(lv, NA_character_), nrow(d), replace = TRUE,
                      prob = c(rep(0.85 / k, k), 0.15))
    ref_vec <- stats::setNames(sample(lv, n_items, replace = TRUE), unique(d$item_id))

    perm <- sample.int(nrow(d))
    d_perm <- d[perm, , drop = FALSE]

    for (wt in c("unweighted", "linear", "quadratic")) {
      ag1 <- suppressMessages(msa_agreement(d, levels = lv, reference = ref_vec,
                                            weights = wt, fleiss = TRUE))
      ag2 <- suppressMessages(msa_agreement(d_perm, levels = lv, reference = ref_vec,
                                            weights = wt, fleiss = TRUE))
      expect_equal(ag1$repeatability_overall, ag2$repeatability_overall, tolerance = tol_arith)
      expect_equal(ag1$reproducibility, ag2$reproducibility, tolerance = tol_arith)
      expect_equal(ag1$alpha$alpha, ag2$alpha$alpha, tolerance = tol_arith)
      expect_identical(ag1$alpha$n_units_excluded, ag2$alpha$n_units_excluded)
      expect_equal(ag1$accuracy_overall, ag2$accuracy_overall, tolerance = tol_arith)
      expect_equal(ag1$pct_items_all_correct, ag2$pct_items_all_correct, tolerance = tol_arith)
      expect_equal(ag1$kappa, ag2$kappa, tolerance = tol_arith)
      expect_equal(ag1$fleiss$kappa, ag2$fleiss$kappa, tolerance = tol_arith)

      # Reversing scale order leaves kappa_all_vs_reference, Fleiss' kappa, and all 4 Krippendorff alphas invariant
      ag_rev <- suppressMessages(msa_agreement(d, levels = rev(lv), reference = ref_vec,
                                               weights = wt, fleiss = TRUE))
      expect_equal(ag1$alpha$alpha, ag_rev$alpha$alpha, tolerance = tol_arith)
      expect_equal(
        ag1$kappa[["kappa_all_vs_reference"]],
        ag_rev$kappa[["kappa_all_vs_reference"]],
        tolerance = tol_arith
      )
      expect_equal(ag1$fleiss$kappa, ag_rev$fleiss$kappa, tolerance = tol_arith)
    }
  }

  # 2. Separator-collision resistance when item_id + prompt_id + model_id share prefixes/delimiters
  d_sep <- data.frame(
    item_id = rep(c("a|b", "a"), each = 4L),
    prompt_id = rep(rep(c("c", "b|c"), each = 2L), 2L),
    model_id = "m.1",
    rep = rep(1:2, 4L),
    value = c("X", "X", "Y", "Y", "X", "Y", "X", "X"),
    reference = rep(c("X", "Y"), each = 4L),
    stringsAsFactors = FALSE
  )
  ag_sep <- msa_agreement(d_sep, levels = c("X", "Y"), reference = "reference", fleiss = TRUE)
  expect_identical(as.integer(ag_sep$n[["items"]]), 2L)
  expect_identical(ag_sep$alpha$n_units_excluded, c(0, 0, 0, 0))
  expect_false(any(is.nan(ag_sep$alpha$alpha)))

  # 3. Multiple reference values outside `levels` are all listed in sorted order with quotes (R/agreement.R:81)
  d_out <- data.frame(
    item_id = c("i1", "i1", "i2", "i2"),
    prompt_id = "p1",
    model_id = "m1",
    rep = c(1L, 2L, 1L, 2L),
    value = c("A", "B", NA, NA),
    reference = c("Z_high", "Z_high", "Z_low", "Z_low"),
    stringsAsFactors = FALSE
  )
  qa_m3a_expect_clean_error(
    msa_agreement(d_out, levels = c("A", "B"), reference = "reference"),
    '`reference` contains values outside `levels`: "Z_high", "Z_low".'
  )

  # 4. Conflicting categorical references including empty string "" are shown with quotes
  d_conf <- data.frame(
    item_id = c("i1", "i1"),
    prompt_id = "p1",
    model_id = "m1",
    rep = 1:2,
    value = c("A", "B"),
    reference = c("", "A"),
    stringsAsFactors = FALSE
  )
  qa_m3a_expect_clean_error(
    msa_agreement(d_conf, levels = c("", "A", "B"), reference = "reference"),
    'Conflicting reference values for item_id "i1": "", "A".'
  )

  # 5. Undefined Fleiss' kappa cases: unequal counts vs <2 ratings vs single used category
  d_unequal <- data.frame(
    item_id = c("i1", "i1", "i2", "i2"),
    prompt_id = "p1",
    model_id = "m1",
    rep = c(1L, 2L, 1L, 2L),
    value = c("A", "B", "A", NA),
    stringsAsFactors = FALSE
  )
  res_unequal <- qa_m3a_capture_messages(msa_agreement(d_unequal, levels = c("A", "B"), fleiss = TRUE))
  expect_true(is.na(res_unequal$value$fleiss$kappa) && !is.nan(res_unequal$value$fleiss$kappa))
  expect_true(any(grepl("Krippendorff", res_unequal$messages, fixed = TRUE)))

  d_one <- data.frame(
    item_id = c("i1", "i2"),
    prompt_id = "p1",
    model_id = "m1",
    rep = c(1L, 1L),
    value = c("A", "B"),
    stringsAsFactors = FALSE
  )
  res_one <- qa_m3a_capture_messages(msa_agreement(d_one, levels = c("A", "B"), fleiss = TRUE))
  expect_true(is.na(res_one$value$fleiss$kappa) && !is.nan(res_one$value$fleiss$kappa))
  expect_true(any(grepl("fewer than two valid ratings", res_one$messages, fixed = TRUE)))
  expect_false(any(grepl("Krippendorff", res_one$messages, fixed = TRUE)))

  d_same <- data.frame(
    item_id = c("i1", "i1", "i2", "i2"),
    prompt_id = "p1",
    model_id = "m1",
    rep = c(1L, 2L, 1L, 2L),
    value = c("A", "A", "A", "A"),
    stringsAsFactors = FALSE
  )
  res_same <- qa_m3a_capture_messages(msa_agreement(d_same, levels = c("A", "B"), fleiss = TRUE))
  expect_true(is.na(res_same$value$fleiss$kappa) && !is.nan(res_same$value$fleiss$kappa))
  expect_true(any(grepl("same category", res_same$messages, fixed = TRUE)))
  expect_false(any(grepl("Krippendorff", res_same$messages, fixed = TRUE)))
  expect_identical(res_same$value$reproducibility[["pct_items_consistent_overall"]], 100)
})

test_that("QA-M3a-FUZZ-2: msa_bias metamorphic invariances, 17-digit conflict detection, constancy thresholds and confidence-band extrema (seed = 20261105)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  set.seed(20261105L)

  ank_tol <- qa_m3a_fuzz_anchor("ANK-TOL")$value
  tol_arith <- ank_tol$arithmetic$abs_tol

  # 1. Randomized metamorphic invariance across 15 trials:
  #    - joint row permutation
  #    - common shift c added to both value and reference leaves diffs, bias, SD, CI, p_value, slope, R^2, t_slope and linearity_in_band invariant
  #    - positive scaling s > 0 scales bias, SD, CI, intercept, slope, band by s and leaves p_value, R^2, t_intercept, t_slope, linearity_in_band invariant
  for (trial in seq_len(15L)) {
    n_items <- sample(4:7, 1L)
    n_reps <- sample(2:4, 1L)
    refs <- sort( stats::runif(n_items, -50, 50) )
    names(refs) <- paste0("item_", seq_len(n_items))

    d <- expand.grid(
      rep = seq_len(n_reps),
      prompt_id = c("P1", "P2"),
      model_id = c("M1", "M2"),
      item_id = names(refs),
      stringsAsFactors = FALSE
    )
    x_vec <- unname(refs[d$item_id])
    d$value <- x_vec + stats::rnorm(nrow(d), mean = 0.25 - 0.05 * x_vec, sd = 0.4)
    d$reference <- x_vec

    # Permute rows
    d_perm <- d[sample.int(nrow(d)), , drop = FALSE]
    b0 <- msa_bias(d, "reference")
    b_perm <- msa_bias(d_perm, "reference")
    expect_equal(b0$overall, b_perm$overall, tolerance = tol_arith)
    expect_equal(b0$linearity, b_perm$linearity, tolerance = tol_arith)
    expect_equal(b0$linearity_item_means, b_perm$linearity_item_means, tolerance = tol_arith)
    expect_equal(b0$linearity_band, b_perm$linearity_band, tolerance = tol_arith)
    expect_identical(b0$linearity_in_band, b_perm$linearity_in_band)
    expect_identical(b0$linearity_verdict, b_perm$linearity_verdict)

    # Common shift of value and reference by shift_c (leaves differences invariant, shifts reference axis)
    shift_c <- stats::rnorm(1L, mean = 100, sd = 25)
    d_shift <- d
    d_shift$value <- d$value + shift_c
    d_shift$reference <- d$reference + shift_c
    b_shift <- msa_bias(d_shift, "reference")
    expect_equal(b0$overall, b_shift$overall, tolerance = tol_arith)
    expect_equal(b0$linearity[["slope"]], b_shift$linearity[["slope"]], tolerance = tol_arith)
    expect_equal(b0$linearity[["t_slope"]], b_shift$linearity[["t_slope"]], tolerance = tol_arith)
    expect_equal(b0$linearity[["r_squared"]], b_shift$linearity[["r_squared"]], tolerance = tol_arith)
    expect_identical(b0$linearity_in_band, b_shift$linearity_in_band)
    expect_identical(b0$linearity_verdict, b_shift$linearity_verdict)

    # Positive scaling by scale_s > 0
    scale_s <- stats::runif(1L, 0.25, 4.0)
    d_scale <- d
    d_scale$value <- d$value * scale_s
    d_scale$reference <- d$reference * scale_s
    b_scale <- msa_bias(d_scale, "reference")
    expect_equal(b_scale$overall[["bias"]], scale_s * b0$overall[["bias"]], tolerance = tol_arith)
    expect_equal(b_scale$overall[["sd"]], scale_s * b0$overall[["sd"]], tolerance = tol_arith)
    expect_equal(b_scale$overall[["lower"]], scale_s * b0$overall[["lower"]], tolerance = tol_arith)
    expect_equal(b_scale$overall[["upper"]], scale_s * b0$overall[["upper"]], tolerance = tol_arith)
    expect_equal(b_scale$overall[["p_value"]], b0$overall[["p_value"]], tolerance = tol_arith)
    expect_equal(b_scale$linearity[["intercept"]], scale_s * b0$linearity[["intercept"]], tolerance = tol_arith)
    expect_equal(b_scale$linearity[["slope"]], b0$linearity[["slope"]], tolerance = tol_arith)
    expect_equal(b_scale$linearity[["t_intercept"]], b0$linearity[["t_intercept"]], tolerance = tol_arith)
    expect_equal(b_scale$linearity[["t_slope"]], b0$linearity[["t_slope"]], tolerance = tol_arith)
    expect_equal(b_scale$linearity[["r_squared"]], b0$linearity[["r_squared"]], tolerance = tol_arith)
    expect_identical(b_scale$linearity_in_band, b0$linearity_in_band)
    expect_identical(b_scale$linearity_verdict, b0$linearity_verdict)
  }

  # 2. Numeric reference conflict at the 17th significant digit (0.1 + 0.2 vs 0.3) shows distinct values
  d_17 <- data.frame(
    item_id = c("i1", "i1", "i2", "i2"),
    prompt_id = "p1",
    model_id = "m1",
    value = c(1, 1, 2, 2),
    reference = c(0.1 + 0.2, 0.3, 2, 2),
    stringsAsFactors = FALSE
  )
  qa_m3a_expect_clean_error(
    msa_bias(d_17, "reference"),
    'Conflicting reference values for item_id "i1": "0.29999999999999999", "0.30000000000000004".'
  )

  # 3. Condition-specific constancy and overflow labels (R/agreement.R:400-401, 417)
  d_cond <- data.frame(
    item_id = rep(c("i1", "i2", "i3"), each = 2L),
    prompt_id = rep(c("p_const", "p_var"), 3L),
    model_id = rep(c("m_const", "m_var"), 3L),
    value = c(1.5, 1.2, 2.5, 2.7, 3.5, 3.1),
    reference = c(1.0, 1.0, 2.0, 2.0, 3.0, 3.0),
    stringsAsFactors = FALSE
  )
  res_cond <- qa_m3a_capture_messages(msa_bias(d_cond, "reference"))
  expect_true(any(grepl(
    'Bias (prompt "p_const", model "m_const") is numerically constant; the interval is a point and the p-value is undefined.',
    res_cond$messages,
    fixed = TRUE
  )))

  # Space separator in linearity_note when handbook$note and means$note are appended (R/agreement.R:417)
  d_two <- data.frame(
    item_id = c("i1", "i2"),
    prompt_id = "p1",
    model_id = "m1",
    value = c(1.2, 2.5),
    reference = c(1.0, 2.0),
    stringsAsFactors = FALSE
  )
  b_two <- suppressMessages(msa_bias(d_two, "reference"))
  expect_match(
    b_two$linearity_note,
    "verdict. Handbook regression has no residual degrees of freedom; inference and the confidence band are undefined. Regression on item means has no residual degrees of freedom; inference and the confidence band are undefined.",
    fixed = TRUE
  )

  # 4. Exact boundary of se_mean constancy in msa_bias_regression (R/agreement.R:512)
  eps <- .Machine$double.eps
  delta_below <- 15 * eps
  d_below <- data.frame(
    item_id = c("i1", "i2", "i3"),
    prompt_id = "p1",
    model_id = "m1",
    value = 1 + c(-delta_below, 0, delta_below) + c(-1, 0, 1) * 1e-6,
    reference = c(-1, 0, 1) * 1e-6,
    stringsAsFactors = FALSE
  )
  b_below <- suppressMessages(msa_bias(d_below, "reference"))
  expect_true(is.na(b_below$linearity[["r_squared"]]) && !is.nan(b_below$linearity[["r_squared"]]))

  delta_above <- 19 * eps
  d_above <- data.frame(
    item_id = c("i1", "i2", "i3"),
    prompt_id = "p1",
    model_id = "m1",
    value = 1 + c(-delta_above, 0, delta_above) + c(-1, 0, 1) * 1e-6,
    reference = c(-1, 0, 1) * 1e-6,
    stringsAsFactors = FALSE
  )
  b_above <- suppressMessages(msa_bias(d_above, "reference"))
  expect_equal(b_above$linearity[["r_squared"]], 1, tolerance = tol_arith)

  # 5. Confidence-band vertex and exponent witness where |slope| = 1 > width (R/agreement.R:562, 568)
  #    9 items at reference = 0 and 1 item at reference = 1: sxx = 10/9, range(z) = [-1/9, 1].
  #    At mean = 0.16, b = -1.0: critical width is 0.84.
  q8 <- stats::qt(0.975, 8L)
  x10 <- c(rep(0, 9L), 1)
  z10 <- c(rep(-1 / 9, 9L), 1)
  make_skewed <- function(target_width) {
    e <- 2 * target_width / q8
    r <- c(e, -e, rep(0, 8L))
    diffs <- 0.16 - z10 + r
    data.frame(
      item_id = sprintf("i%02d", seq_len(10L)),
      prompt_id = "p1",
      model_id = "m1",
      value = x10 + diffs,
      reference = x10,
      stringsAsFactors = FALSE
    )
  }
  b_in <- msa_bias(make_skewed(0.85), "reference")
  expect_true(b_in$linearity_in_band)
  expect_identical(b_in$linearity_verdict, "acceptable")

  b_out <- msa_bias(make_skewed(0.83), "reference")
  expect_false(b_out$linearity_in_band)
  expect_identical(b_out$linearity_verdict, "unacceptable")

  # Concave upper/lower boundary where endpoints contain 0 but interior vertex leaves the band
  x_int <- c(-1, -1, 0, 1, 1)
  y_int <- 0.25 + 0.02 * x_int + c(0.15, -0.15, 0, 0.15, -0.15)
  d_int <- data.frame(
    item_id = paste0("i", seq_along(x_int)),
    prompt_id = "p1",
    model_id = "m1",
    value = x_int + y_int,
    reference = x_int,
    stringsAsFactors = FALSE
  )
  b_int <- msa_bias(d_int, "reference")
  band_int <- b_int$linearity_band
  expect_true(band_int$lower[band_int$reference == -1] <= 0 && band_int$upper[band_int$reference == -1] >= 0)
  expect_true(band_int$lower[band_int$reference == 1] <= 0 && band_int$upper[band_int$reference == 1] >= 0)
  expect_gt(band_int$lower[band_int$reference == 0], 0)
  expect_false(b_int$linearity_in_band)
  expect_identical(b_int$linearity_verdict, "unacceptable")
})
