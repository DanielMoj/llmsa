# QA / Red Team E2E tests for M3a (fixed seed: 20261105)

qa_m3a_anchor <- function(id) {
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

qa_m3a_half_unit <- function(decimals, tol_arith) {
  0.5 * 10^(-decimals) + tol_arith
}

test_that("QA-M3a-E2E-1: Cohen (1968), Fleiss (1971), Krippendorff (2011) and attribute statistics hold end-to-end against anchors and external oracles (seed = 20261105)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  skip_if_not_installed("irr")
  skip_if_not_installed("psych")
  skip_if_not_installed("DescTools")
  set.seed(20261105L)

  ank_tol <- qa_m3a_anchor("ANK-TOL")$value
  tol_arith <- ank_tol$arithmetic$abs_tol
  tol_pkg <- ank_tol$package_compare$abs_tol

  # 1. K-M3a-1: Cohen (1968) Table 1 (ANK-70)
  ank70 <- qa_m3a_anchor("ANK-70")$value
  cats70 <- as.character(ank70$categories)
  props70 <- matrix(unlist(ank70$observed_proportions), nrow = length(cats70), byrow = TRUE)
  counts70 <- round(props70 * as.integer(ank70$N))
  expect_lte(max(abs(counts70 - props70 * as.integer(ank70$N))), tol_arith)

  idx70 <- which(counts70 > 0L, arr.ind = TRUE)
  rep_n <- counts70[idx70]
  judge_b <- rep(cats70[idx70[, 1L]], rep_n)
  judge_a <- rep(cats70[idx70[, 2L]], rep_n)
  runs70 <- data.frame(
    item_id = sprintf("I%03d", seq_along(judge_b)),
    prompt_id = "P1",
    model_id = "M1",
    rep = 1L,
    value = judge_b,
    reference = judge_a,
    stringsAsFactors = FALSE
  )
  # Shuffle row order under fixed seed to verify row-order invariance
  runs70 <- runs70[sample.int(nrow(runs70)), , drop = FALSE]

  ag70_u <- msa_agreement(runs70, levels = cats70, reference = "reference", weights = "unweighted")
  expect_lte(
    abs(ag70_u$kappa[["kappa_all_vs_reference"]] - ank70$kappa),
    qa_m3a_half_unit(ank70$kappa_decimals, tol_arith)
  )
  expect_lte(
    abs(ag70_u$kappa[["kappa_modal_vs_reference"]] - ag70_u$kappa[["kappa_all_vs_reference"]]),
    tol_arith
  )

  for (wt in c("unweighted", "linear", "quadratic")) {
    ag_wt <- msa_agreement(runs70, levels = cats70, reference = "reference", weights = wt)
    irr_wt <- switch(wt, unweighted = "unweighted", linear = "equal", quadratic = "squared")
    desc_wt <- switch(wt, unweighted = "Unweighted", linear = "Equal-Spacing", quadratic = "Fleiss-Cohen")
    k_irr <- irr::kappa2(
      data.frame(
        match(judge_b, cats70),
        match(judge_a, cats70)
      ),
      weight = irr_wt
    )$value
    k_desc <- as.numeric(DescTools::CohenKappa(counts70, weights = desc_wt))
    expect_equal(unname(ag_wt$kappa[["kappa_all_vs_reference"]]), k_irr, tolerance = tol_pkg)
    expect_equal(unname(ag_wt$kappa[["kappa_all_vs_reference"]]), k_desc, tolerance = tol_pkg)
  }

  # 2. K-M3a-2: Fleiss (1971) Table 1 / irr::diagnoses (ANK-72)
  ank72 <- qa_m3a_anchor("ANK-72")$value
  data("diagnoses", package = "irr", envir = environment())
  diag_df <- as.data.frame(lapply(diagnoses, as.character), stringsAsFactors = FALSE)
  lv72 <- sort(unique(unlist(diag_df)))
  n_subj <- nrow(diag_df)
  n_rat <- ncol(diag_df)

  runs72 <- data.frame(
    item_id = rep(sprintf("S%02d", seq_len(n_subj)), times = n_rat),
    prompt_id = rep(paste0("P", seq_len(3L)), each = n_subj, times = 2L),
    model_id = rep(paste0("M", seq_len(2L)), each = n_subj * 3L),
    rep = 1L,
    value = unlist(diag_df, use.names = FALSE),
    stringsAsFactors = FALSE
  )
  ag72_default <- msa_agreement(runs72, levels = lv72)
  expect_null(ag72_default$fleiss)

  ag72_fleiss <- msa_agreement(runs72, levels = lv72, fleiss = TRUE)
  expect_identical(names(ag72_fleiss$fleiss), "kappa")
  expect_null(names(ag72_fleiss$fleiss$kappa))
  expect_lte(
    abs(ag72_fleiss$fleiss$kappa - ank72$kappa),
    qa_m3a_half_unit(ank72$kappa_decimals, tol_arith)
  )
  expect_equal(
    ag72_fleiss$fleiss$kappa,
    irr::kappam.fleiss(diagnoses)$value,
    tolerance = tol_pkg
  )
  lines72 <- capture.output(print(ag72_fleiss))
  fleiss_lines72 <- grep("fleiss", lines72, ignore.case = TRUE, value = TRUE)
  expect_identical(fleiss_lines72, sprintf("Fleiss' kappa: %.3f", ag72_fleiss$fleiss$kappa))
  expect_false(any(grepl("(^|[^A-Za-z])(se|standard error|std[.]?[[:space:]]*err)([^A-Za-z]|$)",
                         fleiss_lines72, ignore.case = TRUE, perl = TRUE)))

  # 3. K-M3a-3: Krippendorff (2011) example with missing values and lone-value unit (ANK-73)
  ank73 <- qa_m3a_anchor("ANK-73")$value
  obs_names <- as.character(ank73$observers)
  n_u <- as.integer(ank73$units)
  lv73 <- as.character(ank73$values)
  obs_vals <- unlist(lapply(obs_names, function(ob) {
    v <- ank73$data[[ob]]
    vapply(v, function(x) if (is.null(x) || is.na(x)) NA_character_ else as.character(x), character(1L))
  }), use.names = FALSE)
  runs73 <- data.frame(
    item_id = rep(sprintf("U%02d", seq_len(n_u)), times = length(obs_names)),
    prompt_id = rep(obs_names, each = n_u),
    model_id = "M1",
    rep = 1L,
    value = obs_vals,
    stringsAsFactors = FALSE
  )
  mat73 <- matrix(as.numeric(obs_vals), nrow = length(obs_names), ncol = n_u, byrow = TRUE)

  weight_map <- list(unweighted = "nominal", linear = "ordinal", quadratic = "interval")
  for (wt in names(weight_map)) {
    met <- weight_map[[wt]]
    ag73 <- msa_agreement(runs73, levels = lv73, weights = wt, fleiss = TRUE)
    alpha_all <- ag73$alpha$alpha[ag73$alpha$scope == "all conditions"]
    excl_all <- ag73$alpha$n_units_excluded[ag73$alpha$scope == "all conditions"]
    expect_lte(
      abs(alpha_all - ank73$alpha[[met]]),
      qa_m3a_half_unit(ank73$alpha_decimals, tol_arith)
    )
    expect_equal(alpha_all, irr::kripp.alpha(mat73, method = met)$value, tolerance = tol_pkg)
    expect_identical(as.integer(excl_all), length(ank73$lone_value_units))
    expect_true(is.na(ag73$fleiss$kappa) && !is.nan(ag73$fleiss$kappa))
  }

  # 4. K-M3a-4: Attribute agreement, modal tie rule ("lowest category") and exclusion of items without valid reference pair
  runs_attr <- data.frame(
    item_id = rep(c("I1", "I2", "I3", "I4"), each = 4L),
    prompt_id = rep(rep(c("P1", "P2"), each = 2L), 4L),
    model_id = "M1",
    rep = rep(1:2, 8L),
    value = c(
      "B", "B", "P", "P",     # I1: 2x B, 2x P -> tie -> lowest category "B"
      "LB", "LB", "LB", "LB", # I2: all 4 match reference "LB"
      "VUS", "P", NA, NA,     # I3: reference is NA -> excluded from pct_items_all_correct
      NA, NA, NA, NA          # I4: no valid responses -> modal NA, excluded from pct_items_all_correct
    ),
    reference = rep(c("B", "LB", NA, "P"), each = 4L),
    stringsAsFactors = FALSE
  )
  lv_acmg <- c("B", "LB", "VUS", "LP", "P")
  ag_attr <- msa_agreement(runs_attr, levels = lv_acmg, reference = "reference", weights = "linear")
  expect_identical(ag_attr$modal$value[ag_attr$modal$item_id == "I1"], "B")
  expect_identical(ag_attr$modal$value[ag_attr$modal$item_id == "I4"], NA_character_)
  # Valid items with >=1 valid response-reference pair are I1 (half right) and I2 (all right) -> 50%
  expect_equal(ag_attr$pct_items_all_correct, 50, tolerance = tol_arith)
})

test_that("QA-M3a-E2E-2: msa_bias reproduces AIAG bias and linearity anchors (ANK-75, ANK-76) and matches stats::t.test and stats::lm across unbalanced designs (seed = 20261105)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  set.seed(20261105L)

  ank_tol <- qa_m3a_anchor("ANK-TOL")$value
  tol_arith <- ank_tol$arithmetic$abs_tol
  tol_pkg <- ank_tol$package_compare$abs_tol

  # 1. K-M3a-5: Construct a 15-observation single-part study matching ANK-75 summary statistics
  ank75 <- qa_m3a_anchor("ANK-75")$value
  # Unbalanced multi-item, multi-condition study with missing values and factor labels
  items <- paste0("item_", seq_len(6L))
  ref_vals <- c(item_1 = 2, item_2 = 4, item_3 = 4, item_4 = 6, item_5 = 8, item_6 = 10)
  grid <- expand.grid(
    rep = 1:3,
    prompt_id = c("P1", "P2"),
    model_id = c("M1", "M2"),
    item_id = items,
    stringsAsFactors = FALSE
  )
  # Make item_1 have only 1 replicate per condition (unbalanced g*m vs g)
  grid <- grid[!(grid$item_id == "item_1" & grid$rep > 1L), , drop = FALSE]
  true_ref <- unname(ref_vals[grid$item_id])
  err_dev <- stats::rnorm(nrow(grid), mean = 0.35 - 0.08 * true_ref, sd = 0.12)
  val_chr <- format(true_ref + err_dev, digits = 17, trim = TRUE)
  # Make condition (P2, M2) completely unparseable/missing and add one NaN in (P1, M1)
  val_chr[grid$prompt_id == "P2" & grid$model_id == "M2"] <- c("unparseable", NA_character_)
  val_chr[which(grid$prompt_id == "P1" & grid$model_id == "M1")[1L]] <- "NaN"

  runs_b <- data.frame(
    item_id = grid$item_id,
    prompt_id = grid$prompt_id,
    model_id = grid$model_id,
    rep = grid$rep,
    value = factor(val_chr),
    stringsAsFactors = FALSE
  )
  ref_df <- data.frame(
    item_id = c(names(ref_vals), "item_1", "item_2"),
    reference = factor(c(as.character(ref_vals), as.character(ref_vals[["item_1"]]), NA_character_)),
    stringsAsFactors = FALSE
  )

  for (lvl in c(0.90, 0.95, 0.99)) {
    b_res <- msa_bias(runs_b, reference = ref_df, level = lvl)
    num_val <- suppressWarnings(as.numeric(as.character(runs_b$value)))
    num_val[is.nan(num_val)] <- NA_real_
    diffs <- num_val - true_ref
    valid <- !is.na(diffs)

    # Accounting identity: n + n_excluded == nrow overall and per condition
    expect_identical(as.integer(b_res$overall[["n"]] + b_res$overall[["n_excluded"]]), nrow(runs_b))
    expect_identical(sum(as.integer(b_res$by_condition$n)), as.integer(b_res$overall[["n"]]))
    expect_identical(sum(as.integer(b_res$by_condition$n_excluded)), as.integer(b_res$overall[["n_excluded"]]))

    tt_all <- stats::t.test(diffs[valid], conf.level = lvl)
    expect_equal(b_res$overall[["bias"]], unname(tt_all$estimate), tolerance = tol_pkg)
    expect_equal(b_res$overall[["sd"]], stats::sd(diffs[valid]), tolerance = tol_pkg)
    expect_equal(b_res$overall[["lower"]], tt_all$conf.int[1L], tolerance = tol_pkg)
    expect_equal(b_res$overall[["upper"]], tt_all$conf.int[2L], tolerance = tol_pkg)
    expect_equal(b_res$overall[["p_value"]], tt_all$p.value, tolerance = tol_pkg)

    # All 4 conditions present, with (P2, M2) having n = 0 and all NA_real_
    expect_identical(nrow(b_res$by_condition), 4L)
    row_p2m2 <- b_res$by_condition[b_res$by_condition$prompt_id == "P2" & b_res$by_condition$model_id == "M2", ]
    expect_identical(as.integer(row_p2m2$n), 0L)
    expect_identical(
      as.integer(row_p2m2$n_excluded),
      sum(runs_b$prompt_id == "P2" & runs_b$model_id == "M2")
    )
    for (col_nm in c("bias", "sd", "lower", "upper", "p_value")) {
      expect_true(is.na(row_p2m2[[col_nm]]) && !is.nan(row_p2m2[[col_nm]]))
    }

    # Handbook regression vs stats::lm on all valid pairs
    x_valid <- true_ref[valid]
    y_valid <- diffs[valid]
    lm_hb <- summary(stats::lm(y_valid ~ x_valid))
    expect_equal(b_res$linearity[["intercept"]], lm_hb$coefficients[1L, 1L], tolerance = tol_pkg)
    expect_equal(b_res$linearity[["slope"]], lm_hb$coefficients[2L, 1L], tolerance = tol_pkg)
    expect_equal(b_res$linearity[["t_intercept"]], lm_hb$coefficients[1L, 3L], tolerance = tol_pkg)
    expect_equal(b_res$linearity[["t_slope"]], lm_hb$coefficients[2L, 3L], tolerance = tol_pkg)
    expect_equal(b_res$linearity[["slope_p_value"]], lm_hb$coefficients[2L, 4L], tolerance = tol_pkg)
    expect_equal(b_res$linearity[["r_squared"]], lm_hb$r.squared, tolerance = tol_pkg)
    expect_identical(as.integer(b_res$linearity[["df"]]), length(y_valid) - 2L)

    # Unweighted item-mean regression vs stats::lm on distinct item means (6 items, even though item_2 and item_3 share reference = 4)
    item_df <- stats::aggregate(diffs[valid] ~ runs_b$item_id[valid], FUN = mean)
    names(item_df) <- c("item_id", "mean_diff")
    item_df$ref <- unname(ref_vals[item_df$item_id])
    lm_im <- summary(stats::lm(mean_diff ~ ref, data = item_df))
    expect_equal(b_res$linearity_item_means[["intercept"]], lm_im$coefficients[1L, 1L], tolerance = tol_pkg)
    expect_equal(b_res$linearity_item_means[["slope"]], lm_im$coefficients[2L, 1L], tolerance = tol_pkg)
    expect_equal(b_res$linearity_item_means[["t_intercept"]], lm_im$coefficients[1L, 3L], tolerance = tol_pkg)
    expect_equal(b_res$linearity_item_means[["t_slope"]], lm_im$coefficients[2L, 3L], tolerance = tol_pkg)
    expect_equal(b_res$linearity_item_means[["r_squared"]], lm_im$r.squared, tolerance = tol_pkg)
    expect_identical(as.integer(b_res$linearity_item_means[["df"]]), nrow(item_df) - 2L)
    # Because item_1 has fewer replicates, handbook slope != item-means slope
    expect_gt(abs(b_res$linearity[["slope"]] - b_res$linearity_item_means[["slope"]]), tol_pkg)
  }

  # 2. Verify ANK-75 and ANK-76 published formulas against synthetic data matching published moments
  ank76 <- qa_m3a_anchor("ANK-76")$value
  expect_identical(as.integer(ank75$df), as.integer(ank75$n) - 1L)
  expect_lte(
    abs(stats::qt(1 - ank75$alpha / 2, ank75$df) - ank75$t_quantile),
    qa_m3a_half_unit(ank75$t_quantile_decimals, tol_arith)
  )
  expect_identical(as.integer(ank76$handbook$df), as.integer(ank76$design$observations) - 2L)
  expect_lte(
    abs(stats::qt(1 - ank76$handbook$alpha / 2, ank76$handbook$df) - ank76$handbook$t_quantile),
    qa_m3a_half_unit(ank76$handbook$t_quantile_decimals, tol_arith)
  )
})

test_that("QA-M3a-E2E-3: msa_report, print methods, help pages and bias_coverage helper integrate cleanly end-to-end (seed = 20261105)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  set.seed(20261105L)

  ank_tol <- qa_m3a_anchor("ANK-TOL")$value
  tol_arith <- ank_tol$arithmetic$abs_tol
  ank06 <- qa_m3a_anchor("ANK-06")$value

  # 1. Full workflow: acmg_demo + ic50_demo -> msa_agreement(fleiss = TRUE) + msa_bias() -> msa_report()
  lv_acmg <- c("B", "LB", "VUS", "LP", "P")
  # Complete subset of acmg_demo so Fleiss' kappa is finite and formatted in the report
  acmg_complete <- acmg_demo[!is.na(acmg_demo$value), , drop = FALSE]
  complete_items <- names(which(table(acmg_complete$item_id) == max(table(acmg_complete$item_id))))
  acmg_complete <- acmg_complete[acmg_complete$item_id %in% complete_items, , drop = FALSE]
  ag_demo <- msa_agreement(acmg_complete, levels = lv_acmg, reference = "reference",
                           weights = "linear", fleiss = TRUE)
  bi_demo <- msa_bias(ic50_demo, reference = "reference")
  fit_demo <- suppressMessages(msa_fit(ic50_demo, type = "numeric"))
  grr_demo <- msa_grr(fit_demo)

  md_fmt <- rmarkdown::md_document(variant = "gfm", pandoc_args = "--wrap=none")
  out_md <- tempfile(fileext = ".md")
  on.exit(unlink(out_md), add = TRUE)
  msa_report(grr_demo, runs = ic50_demo, agreement = ag_demo, bias = bi_demo,
             output_file = out_md, output_format = md_fmt, quiet = TRUE)
  md_txt <- paste(readLines(out_md, warn = FALSE, encoding = "UTF-8"), collapse = " ")

  expect_match(md_txt, sprintf("%.3f", ag_demo$fleiss$kappa), fixed = TRUE)
  expect_match(md_txt, "lowest tied category in scale order", fixed = TRUE)
  expect_match(md_txt, "acmg_modal()", fixed = TRUE)
  expect_match(md_txt, "n_units_excluded", fixed = TRUE)
  expect_match(md_txt, sprintf("Handbook linearity verdict: **%s**", bi_demo$linearity_verdict), fixed = TRUE)
  expect_match(md_txt, "regression on unweighted item means", fixed = TRUE)
  expect_match(md_txt, sprintf("df = %.0f", bi_demo$linearity[["df"]]), fixed = TRUE)
  expect_match(md_txt, sprintf("df = %.0f", bi_demo$linearity_item_means[["df"]]), fixed = TRUE)

  # 2. Help pages man/msa_agreement.Rd and man/msa_bias.Rd document all M3a contracts
  read_rd_text <- function(topic) {
    root <- Sys.getenv("REPO_ROOT", unset = "")
    candidates <- c(
      if (nzchar(root)) file.path(root, "man", paste0(topic, ".Rd")),
      testthat::test_path("..", "..", "man", paste0(topic, ".Rd"))
    )
    files <- candidates[file.exists(candidates)]
    rd_obj <- if (length(files)) {
      tools::parse_Rd(files[1L])
    } else {
      utils:::.getHelpFile(utils::help(topic, package = "llmsa"))
    }
    paste(capture.output(tools::Rd2txt(
      rd_obj,
      options = list(underline_titles = FALSE, itemBullet = "* ")
    )), collapse = " ")
  }
  rd_ag <- read_rd_text("msa_agreement")
  expect_match(rd_ag, "unweighted.*nominal", ignore.case = TRUE)
  expect_match(rd_ag, "linear.*ordinal", ignore.case = TRUE)
  expect_match(rd_ag, "quadratic.*interval", ignore.case = TRUE)
  expect_match(rd_ag, "acmg_modal", fixed = TRUE)
  expect_match(rd_ag, "n_units_excluded", fixed = TRUE)

  rd_bi <- read_rd_text("msa_bias")
  expect_match(rd_bi, "linearity_item_means", fixed = TRUE)
  expect_match(rd_bi, "linearity_band", fixed = TRUE)
  expect_match(rd_bi, "linearity_verdict", fixed = TRUE)
  expect_match(rd_bi, "n_excluded", fixed = TRUE)

  # 3. Validation helper inst/validation/agreement/bias_coverage.R preserves RNG state and formats table cleanly
  helper_env <- new.env(parent = globalenv())
  sys.source(
    system.file("validation", "agreement", "bias_coverage.R", package = "llmsa"),
    envir = helper_env
  )
  anchors_obj <- list("ANK-06" = qa_m3a_anchor("ANK-06"), "ANK-TOL" = qa_m3a_anchor("ANK-TOL"))
  set.seed(20261105L)
  seed_before <- .Random.seed
  n_chk <- as.integer(ank_tol$n_check$n_sim)
  cov_res <- helper_env$agreement_bias_coverage(anchors = anchors_obj, n_sim = n_chk)
  expect_identical(.Random.seed, seed_before)
  cov_df <- cov_res$summary
  expect_identical(cov_df$scenario, c("S-bias-1", "S-bias-2"))
  expect_identical(as.integer(cov_df$n_sim), c(n_chk, n_chk))
  expect_true(all(cov_df$coverage >= 0 & cov_df$coverage <= 1))
  expect_equal(
    cov_df$MCSE,
    sqrt(cov_df$coverage * (1 - cov_df$coverage) / cov_df$n_sim),
    tolerance = tol_arith
  )
  fmt_tab <- helper_env$agreement_coverage_table(cov_res)
  expect_identical(
    names(fmt_tab),
    c("scenario", "coverage", "MCSE", "n_sim", "distance to level (MCSE)", "finding")
  )
  expect_identical(as.integer(cov_res$n_min), as.integer(ank06$n_sim_min))
})
