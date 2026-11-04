# QA / Red Team E2E tests for M1d (fixed seed: 20261104)
testthat::set_max_fails(Inf)

qa_m1d_load_env <- function(rel_path) {
  e <- new.env(parent = globalenv())
  sys.source(system.file(rel_path, package = "llmsa", mustWork = TRUE), envir = e)
  e
}

test_that("QA-M1d-E2E-1: llm-stability frozen dataset, manifest and binary MSA pipeline preserve missingness and counts (seed = 20261104)", {
  set.seed(20261104L)
  testthat::skip_if_not_installed("jsonlite")
  testthat::skip_if_not_installed("digest")

  f_env <- qa_m1d_load_env(file.path("validation", "m1d", "findings.R"))
  anchors <- f_env$m1d_resources()
  a40 <- anchors[["ANK-40"]]$value

  ext_dir <- system.file("extdata", "llm-stability_2026-10-22", package = "llmsa", mustWork = TRUE)
  sums <- readLines(file.path(ext_dir, "SHA256SUMS"), warn = FALSE, encoding = "UTF-8")
  sums_parts <- strsplit(sums, "  ", fixed = TRUE)
  expect_true(all(lengths(sums_parts) == 2L))
  sums_map <- stats::setNames(vapply(sums_parts, `[`, "", 1L), vapply(sums_parts, `[`, "", 2L))
  expect_setequal(names(sums_map), c("QUELLE.txt", "items.csv.gz"))
  for (fn in names(sums_map)) {
    expect_identical(
      digest::digest(file = file.path(ext_dir, fn), algo = "sha256", serialize = FALSE),
      sums_map[[fn]]
    )
  }

  quelle <- paste(readLines(file.path(ext_dir, "QUELLE.txt"), warn = FALSE, encoding = "UTF-8"), collapse = "
")
  expect_match(quelle, a40$commit, fixed = TRUE)
  expect_match(quelle, "Apache", fixed = TRUE)
  expect_match(quelle, "Non-label answer keys:", fixed = TRUE)

  con <- gzfile(file.path(ext_dir, "items.csv.gz"), "rt")
  on.exit(close(con), add = TRUE)
  items <- utils::read.csv(con, stringsAsFactors = FALSE, na.strings = "", encoding = "UTF-8")

  expect_identical(names(items), c("task", "model", "run", "item_id", "answer", "correct"))
  expected_rows <- sum(unlist(a40$items_per_task)) * length(a40$models) * as.integer(a40$n_runs)
  expect_identical(nrow(items), expected_rows)
  expect_setequal(unique(items$task), unlist(a40$tasks))
  expect_setequal(unique(items$model), unlist(a40$models))
  expect_setequal(unique(items$run), unlist(a40$runs))
  expect_identical(is.na(items$answer), is.na(items$correct))

  # End-to-end user flow per task: observed rates + as_msa_runs -> msa_counts -> msa_fit -> msa_grr
  for (task in unique(items$task)) {
    d <- items[items$task == task, , drop = FALSE]
    for (m in unique(d$model)) {
      dm <- d[d$model == m, , drop = FALSE]
      by_item <- split(dm$answer, dm$item_id)
      rep_rate <- mean(vapply(by_item, function(x) !anyNA(x) && length(unique(x)) == 1L, logical(1)))
      hit_rate <- mean(dm$correct %in% TRUE)
      miss_rate <- mean(is.na(dm$answer))
      expect_true(rep_rate >= 0 && rep_rate <= 1)
      expect_true(hit_rate >= 0 && hit_rate <= 1 - miss_rate + 1e-12)
    }

    runs <- as_msa_runs(data.frame(
      item_id = as.character(d$item_id),
      prompt_id = "task",
      model_id = d$model,
      rep = d$run,
      value = as.integer(d$correct),
      stringsAsFactors = FALSE
    ))
    cnt <- msa_counts(runs)
    expect_identical(as.integer(sum(cnt$n)), nrow(d))
    expect_true(all(cnt$n_items == as.integer(a40$items_per_task[[task]])))
    expect_identical(nrow(cnt), length(a40$models))

    n_miss <- sum(is.na(d$correct))
    warns <- character()
    fit <- withCallingHandlers(
      suppressMessages(msa_fit(runs, type = "binary", interactions = FALSE, link = "probit")),
      warning = function(w) {
        warns <<- c(warns, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
    expect_s3_class(fit, "msa_fit")
    expect_identical(fit$n$observations, nrow(d) - n_miss)
    if (n_miss > 0L) {
      expect_true(any(grepl(paste0(n_miss, " missing response"), warns, fixed = TRUE)))
    }
    grr <- msa_grr(fit)
    expect_s3_class(grr, "msa_grr")
    expect_true(all(is.finite(grr$table$variance)))
  }
})

test_that("QA-M1d-E2E-2: ClinVar frozen subsets, agreement metrics, ordinal probit fits and review_status sensitivity match contracts (seed = 20261104)", {
  set.seed(20261104L)
  testthat::skip_if_not_installed("jsonlite")
  testthat::skip_if_not_installed("digest")

  f_env <- qa_m1d_load_env(file.path("validation", "m1d", "findings.R"))
  anchors <- f_env$m1d_resources()
  classes <- unlist(anchors[["ANK-47"]]$value$classes, use.names = FALSE)
  hrf_genes <- c("MEFV", "MVK", "NLRP3", "TNFRSF1A")

  ext_dir <- system.file("extdata", "clinvar_2026-10-19", package = "llmsa", mustWork = TRUE)
  sums <- readLines(file.path(ext_dir, "SHA256SUMS"), warn = FALSE, encoding = "UTF-8")
  sums_parts <- strsplit(sums, "  ", fixed = TRUE)
  sums_map <- stats::setNames(vapply(sums_parts, `[`, "", 1L), vapply(sums_parts, `[`, "", 2L))
  expect_setequal(names(sums_map), c("QUELLE.txt", "hrf_submissions.csv.gz", "sample_submissions.csv.gz"))
  for (fn in names(sums_map)) {
    expect_identical(
      digest::digest(file = file.path(ext_dir, fn), algo = "sha256", serialize = FALSE),
      sums_map[[fn]]
    )
  }

  read_sub <- function(fn) {
    con <- gzfile(file.path(ext_dir, fn), "rt")
    on.exit(close(con), add = TRUE)
    utils::read.csv(con, stringsAsFactors = FALSE, na.strings = "", encoding = "UTF-8")
  }
  hrf <- read_sub("hrf_submissions.csv.gz")
  smp <- read_sub("sample_submissions.csv.gz")

  expect_identical(
    names(hrf),
    c("variation_id", "gene", "submitter_id", "classification", "date_last_evaluated", "review_status")
  )
  expect_identical(names(smp), names(hrf))
  expect_true(all(hrf$classification %in% classes))
  expect_true(all(smp$classification %in% classes))
  expect_true(all(vapply(strsplit(hrf$gene, ";", fixed = TRUE), function(g) any(g %in% hrf_genes), logical(1))))
  expect_identical(length(unique(smp$variation_id)), as.integer(anchors[["ANK-47"]]$value$n_variants))

  # Distinct submitter thresholds and retention of multiple SCVs per submitter
  hrf_sub_counts <- tapply(hrf$submitter_id, hrf$variation_id, function(x) length(unique(x)))
  smp_sub_counts <- tapply(smp$submitter_id, smp$variation_id, function(x) length(unique(x)))
  expect_true(all(hrf_sub_counts >= 2L))
  expect_true(all(smp_sub_counts >= as.integer(anchors[["ANK-47"]]$value$min_distinct_submitters)))
  expect_gt(nrow(hrf), sum(hrf_sub_counts))
  expect_gt(nrow(smp), sum(smp_sub_counts))

  groups <- stats::setNames(c("B/LB", "B/LB", "VUS", "P/LP", "P/LP"), classes)
  for (d in list(hrf = hrf, sample = smp)) {
    runs <- as_msa_runs(data.frame(
      item_id = as.character(d$variation_id),
      prompt_id = d$submitter_id,
      model_id = "clinvar",
      rep = 1L,
      value = d$classification,
      stringsAsFactors = FALSE
    ))
    ag_nom <- msa_agreement(runs, levels = classes, weights = "unweighted")
    ag_ord <- msa_agreement(runs, levels = classes, weights = "linear")
    a_nom <- ag_nom$alpha$alpha[ag_nom$alpha$scope == "all conditions"]
    a_ord <- ag_ord$alpha$alpha[ag_ord$alpha$scope == "all conditions"]
    expect_true(is.finite(a_nom) && is.finite(a_ord) && a_ord > a_nom)

    by_var <- split(d$classification, d$variation_id)
    by_var <- by_var[lengths(by_var) >= 2L]
    full_ag <- mean(vapply(by_var, function(x) length(unique(x)) == 1L, logical(1)))
    conflict <- mean(vapply(by_var, function(x) length(unique(groups[x])) >= 2L, logical(1)))
    expect_true(full_ag > 0 && conflict > 0 && (full_ag + conflict) < 1)

    fit <- suppressWarnings(suppressMessages(
      msa_fit(runs, type = "ordinal", levels = classes, interactions = FALSE, link = "probit")
    ))
    expect_true(fit$converged)
    expect_false(fit$singular)
    grr <- msa_grr(fit)
    expect_true(all(is.finite(grr$table$variance)))

    # Sensitivity filter: literal prefix "criteria provided"
    keep <- !is.na(d$review_status) & startsWith(d$review_status, "criteria provided")
    expect_false(any(d$review_status[keep] == "no assertion criteria provided"))
    expect_false(any(d$review_status[keep] == "reviewed by expert panel"))
    d_sens <- d[keep, , drop = FALSE]
    runs_sens <- as_msa_runs(data.frame(
      item_id = as.character(d_sens$variation_id),
      prompt_id = d_sens$submitter_id,
      model_id = "clinvar",
      rep = 1L,
      value = d_sens$classification,
      stringsAsFactors = FALSE
    ))
    expect_true(is.finite(msa_agreement(runs_sens, levels = classes, weights = "unweighted")$alpha$alpha[1L]))
    expect_true(is.finite(msa_agreement(runs_sens, levels = classes, weights = "linear")$alpha$alpha[1L]))
  }
})

test_that("QA-M1d-E2E-3: offline resources, class-B full-run findings and ordinal convergence sensitivity are consistent (seed = 20261104)", {
  set.seed(20261104L)
  testthat::skip_if_not_installed("jsonlite")
  testthat::skip_if_not_installed("digest")

  f_env <- qa_m1d_load_env(file.path("validation", "m1d", "findings.R"))
  l_env <- qa_m1d_load_env(file.path("validation", "latent", "reference_checks.R"))
  b_env <- qa_m1d_load_env(file.path("validation", "sim", "boot_coverage_results.R"))

  anchors <- f_env$m1d_resources()
  expect_setequal(names(anchors), f_env$m1d_resource_ids)

  ord_res <- l_env$latent_read_results("ordinal_recovery")
  bin_res <- l_env$latent_read_results("binary_recovery")
  two_res <- l_env$latent_read_results("two_level")
  boot_res <- b_env$boot_read_results()

  expect_identical(ord_res$mode, "full")
  expect_identical(bin_res$mode, "full")
  expect_identical(two_res$mode, "full")
  expect_identical(boot_res$mode, "full")

  f_ord <- f_env$m1d_findings("ordinal_recovery", ord_res$data, anchors)
  f_bin <- f_env$m1d_findings("binary_recovery", bin_res$data, anchors)
  f_two <- f_env$m1d_findings("two_level", two_res$data, anchors)
  f_boot <- f_env$m1d_findings("boot_coverage", boot_res$data, anchors)

  expect_true(all(f_ord$direction == "underestimation"))
  expect_true(all(f_bin$direction == "underestimation"))
  expect_setequal(f_two$scenario, c("S-two-1", "S-two-2"))
  expect_setequal(f_boot$scenario, paste0("S-boot-", 1:7))
  expect_true(all(f_boot$estimand == "ndc" & f_boot$direction == "overcoverage"))

  sens <- f_env$m1d_convergence_sensitivity()
  expect_true(sens$available)
  expect_identical(nrow(sens$diagnostics), 4L)
  expect_identical(nrow(sens$tables), 50L)
  expect_true(all(sens$diagnostics$n == 1000L))
  expect_true(all(sens$diagnostics$nonconverged > 0L))

  # For every scenario & estimand with nonconverged fits, converged n < all n
  for (sc in unique(sens$tables$scenario)) {
    nonconv <- sens$diagnostics$nonconverged[sens$diagnostics$scenario == sc]
    sub_t <- sens$tables[sens$tables$scenario == sc, , drop = FALSE]
    n_all <- sub_t$n[sub_t$selection == "all finite estimates"]
    n_conv <- sub_t$n[sub_t$selection == "converged finite estimates"]
    expect_true(all(n_all - n_conv == nonconv))
  }
})

test_that("QA-M1d-E2E-4: robustness print and msa_report follow K-M1d-8 wording across inactive, ME-only and SME-active designs (seed = 20261104)", {
  set.seed(20261104L)
  pb <- pb_design(list(
    temperature = c(0, 0.2),
    top_p = c(0.9, 1.0),
    system_prompt = c("short", "detailed"),
    max_tokens = c(256, 512),
    stop_seq = c("none", "newline"),
    seed_mode = c("fixed", "unset"),
    format = c("json", "xml")
  ))

  # 1. No factor above ME
  y_flat <- rep(0.5, nrow(pb))
  rob_none <- msa_robustness(pb, y_flat)
  expect_false(any(rob_none$active))
  expected_sentence <- sprintf(
    paste(
      "No factor exceeded the margin of error (ME = %.4f).",
      "Smaller effects cannot be told apart from noise with this design,",
      "so this result does not show that the pipeline is robust."
    ),
    attr(rob_none, "me")
  )
  out_none <- paste(capture.output(ret <- withVisible(print(rob_none))), collapse = "\n")
  expect_false(ret$visible)
  expect_identical(ret$value, rob_none)
  expect_match(out_none, expected_sentence, fixed = TRUE)
  expect_false(grepl("robust to all screened perturbations", out_none, fixed = TRUE))
  expect_false(grepl("above ME only|also above SME", out_none))

  # 2. Mixed: one factor above SME and one factor above ME only
  # Construct effects where 5 factors have small effect 1.0 (giving PSE = 1.5),
  # one factor has effect between ME and SME, and one factor has effect > SME
  X <- attr(pb, "coded")
  k <- ncol(X)
  df <- k / 3
  pse_target <- 1.5
  me_target <- stats::qt(1 - 0.05 / 2, df = df) * pse_target
  sme_target <- stats::qt((1 + (1 - 0.05)^(1 / k)) / 2, df = df) * pse_target
  eff_target <- c(sme_target + 1.0, (me_target + sme_target) / 2, rep(1.0, k - 2L))
  y_mix <- as.numeric(10 + 0.5 * (X %*% eff_target))
  rob_mix <- msa_robustness(pb, y_mix)
  expect_identical(rob_mix$active, c(TRUE, TRUE, rep(FALSE, k - 2L)))
  expect_identical(rob_mix$active_simultaneous, c(TRUE, FALSE, rep(FALSE, k - 2L)))

  out_mix <- paste(capture.output(print(rob_mix)), collapse = " ")
  expect_match(out_mix, "temperature (also above SME), top_p (above ME only)", fixed = TRUE)
  expect_false(grepl("system_prompt (", out_mix, fixed = TRUE))
  expect_false(grepl("does not show that the pipeline is robust", out_mix, fixed = TRUE))

  if (requireNamespace("rmarkdown", quietly = TRUE) && rmarkdown::pandoc_available()) {
    fit_num <- suppressMessages(msa_fit(ic50_demo, type = "numeric"))
    grr_num <- msa_grr(fit_num)
    md_fmt <- rmarkdown::md_document(variant = "gfm", pandoc_args = "--wrap=none")
    f_none <- tempfile(fileext = ".md")
    f_mix <- tempfile(fileext = ".md")
    on.exit(unlink(c(f_none, f_mix)), add = TRUE)

    msa_report(grr_num, robustness = rob_none, output_file = f_none, output_format = md_fmt, quiet = TRUE)
    msa_report(grr_num, robustness = rob_mix, output_file = f_mix, output_format = md_fmt, quiet = TRUE)

    md_none <- paste(readLines(f_none, warn = FALSE, encoding = "UTF-8"), collapse = " ")
    md_mix <- paste(readLines(f_mix, warn = FALSE, encoding = "UTF-8"), collapse = " ")

    expect_match(md_none, expected_sentence, fixed = TRUE)
    expect_false(grepl("robust to all screened perturbations", md_none, fixed = TRUE))
    expect_false(grepl("above ME only|also above SME", md_none))

    expect_match(md_mix, "temperature (also above SME), top_p (above ME only)", fixed = TRUE)
    expect_false(grepl("system_prompt (", md_mix, fixed = TRUE))
  }
})
