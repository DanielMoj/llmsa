# QA / Red Team E2E tests for M3c (fixed seed: 20261108)

qa_m3c_anchor <- function(id) {
  root <- Sys.getenv("REPO_ROOT", unset = "")
  rel <- file.path("reference", "anchors", paste0(id, ".json"))
  candidates <- c(
    if (nzchar(root)) file.path(root, rel),
    testthat::test_path("..", "..", rel),
    system.file("validation", "planning", "anchors", paste0(id, ".json"), package = "llmsa"),
    system.file("validation", "numeric", "anchors", paste0(id, ".json"), package = "llmsa"),
    system.file("validation", "latent", "anchors", paste0(id, ".json"), package = "llmsa")
  )
  hit <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (!length(hit)) stop("Anchor file not found: ", id, call. = FALSE)
  jsonlite::read_json(hit[1L], simplifyVector = FALSE)
}

qa_m3c_plot_capture <- function(chart, ...) {
  grDevices::pdf(NULL)
  dev <- grDevices::dev.cur()
  on.exit(grDevices::dev.off(dev), add = TRUE)
  grDevices::dev.control("enable")
  ret <- withVisible(plot(chart, ...))
  dl <- grDevices::recordPlot()[[1L]]

  dl_name <- function(entry) {
    f <- tryCatch(entry[[2L]][[1L]], error = function(e) NULL)
    if (is.list(f) && !is.null(f$name)) as.character(f$name) else ""
  }
  fn_names <- vapply(dl, dl_name, character(1L))
  calls <- lapply(dl, `[[`, 2L)

  xy <- calls[fn_names == "C_plotXY"][[1L]]
  win <- calls[fn_names == "C_plot_window"][[1L]]
  title_call <- calls[fn_names == "C_title"][[1L]]
  ablines <- calls[fn_names == "C_abline"]

  h_lines <- unlist(lapply(ablines, function(cl) as.numeric(cl[[4L]])), use.names = FALSE)
  list(
    ret = ret,
    x = as.numeric(xy[[2L]]$x),
    y = as.numeric(xy[[2L]]$y),
    type = as.character(xy[[3L]]),
    pch = as.numeric(xy[[4L]]),
    col = as.character(xy[[6L]]),
    ylim = as.numeric(win[[3L]]),
    main = as.character(title_call[[2L]]),
    xlab = as.character(title_call[[4L]]),
    ylab = as.character(title_call[[5L]]),
    abline_h = h_lines,
    abline_col = vapply(ablines, function(cl) as.character(cl[[7L]]), character(1L)),
    abline_lty = vapply(ablines, function(cl) as.numeric(cl[[8L]]), numeric(1L))
  )
}

test_that("QA-M3c-E2E-1: Westgard control chart rules, both R_4s readings, qcc Shewhart limits, print/plot and msa_report integration hold end-to-end (seed = 20261108)", {
  old_opt <- options(testthat.progress.max_fails = Inf, width = 200, OutDec = ".")
  on.exit(options(old_opt), add = TRUE)
  skip_if_not_installed("qcc")
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  set.seed(20261108L)

  ank86 <- qa_m3c_anchor("ANK-86")$value
  ank_tol <- qa_m3c_anchor("ANK-TOL")$value
  tol_arith <- as.numeric(ank_tol$arithmetic$abs_tol)
  tol_oracle <- as.numeric(ank_tol$oracle$closed_form_rel_tol)

  expect_identical(as.integer(ank86$standardization$n0_default), 10L)

  # Construct a multi-rule control series on a custom scale (center = 12.5, sd = 0.4)
  # where position 3 has z = (2.4, -1.7) -> |diff| = 4.1 > 4 (range fires, westgard does not),
  # position 6 has z = (2.1, -2.2) -> opposite >2 / <-2 (both range and westgard fire),
  # position 9 has z = 3.2 -> 1_3s and 1_2s fire,
  # positions 11..14 have z = 1.2 -> 4_1s fires at 14.
  z_series <- c(0, 2.4, -1.7, 0, 2.1, -2.2, 0, -0.3, 3.2, 0, 1.2, 1.2, 1.2, 1.2, -0.2)
  ctr <- 12.5
  s <- 0.4
  x_series <- ctr + s * z_series

  cc_default <- msa_control_chart(x_series, center = ctr, sd = s)
  cc_range <- msa_control_chart(x_series, center = ctr, sd = s, r4s = "range")
  cc_west <- msa_control_chart(x_series, center = ctr, sd = s, r4s = "westgard")

  expect_identical(cc_default, cc_range)
  expect_identical(attr(cc_range, "r4s"), "range")
  expect_identical(attr(cc_west, "r4s"), "westgard")
  expect_identical(which(cc_range$R_4s), c(3L, 6L))
  expect_identical(which(cc_west$R_4s), 6L)
  expect_identical(which(cc_range$`1_3s`), 9L)
  expect_identical(which(cc_range$`4_1s`), 14L)
  expect_identical(which(cc_range$reject), c(3L, 6L, 9L, 14L))
  expect_identical(which(cc_west$reject), c(6L, 9L, 14L))

  # Compare Shewhart limits (center +- 1, 2, 3 sd) against qcc::qcc(type = "xbar.one")
  for (nsig in 1:3) {
    q_given <- qcc::qcc(x_series, type = "xbar.one", center = ctr, std.dev = s, nsigmas = nsig, plot = FALSE)
    expect_lte(abs(as.numeric(q_given$center) - attr(cc_range, "center")), tol_oracle)
    expect_lte(max(abs(sort(as.numeric(q_given$limits)) - (ctr + c(-nsig, nsig) * s))), tol_oracle)
  }

  rec <- qa_m3c_plot_capture(cc_range)
  expect_false(rec$ret$visible)
  expect_identical(rec$ret$value, cc_range)
  expect_equal(sort(rec$abline_h), sort(ctr + (-3:3) * s), tolerance = tol_arith)
  expect_identical(rec$pch, ifelse(cc_range$reject, 19, 1))
  expect_identical(rec$col, ifelse(cc_range$reject, "red", "black"))

  # Baseline standardization from the first n_baseline = 10 values and qcc agreement
  base10 <- 50 + c(-1.5, 1.5, -1.5, 1.5, 0, 0, 0, 0, 0, 0)
  x_base <- c(base10, 52.1, 47.8, 53.2)
  cc_base <- msa_control_chart(x_base)
  expect_equal(attr(cc_base, "center"), mean(base10), tolerance = tol_arith)
  expect_equal(attr(cc_base, "sd"), stats::sd(base10), tolerance = tol_arith)
  for (nsig in 1:3) {
    q_base <- qcc::qcc(x_base, type = "xbar.one", center = mean(base10), std.dev = stats::sd(base10),
                       nsigmas = nsig, plot = FALSE)
    expect_lte(max(abs(sort(as.numeric(q_base$limits)) - (attr(cc_base, "center") + c(-nsig, nsig) * attr(cc_base, "sd")))),
               tol_oracle)
  }

  # Print output for both readings and subset of rules without 1_2s
  out_range <- capture.output(ret_p1 <- withVisible(print(cc_range)))
  out_west <- capture.output(ret_p2 <- withVisible(print(cc_west)))
  expect_false(ret_p1$visible)
  expect_identical(ret_p1$value, cc_range)
  expect_false(ret_p2$visible)
  expect_identical(ret_p2$value, cc_west)
  expect_true(any(grepl("R_4s reading: range", out_range, fixed = TRUE)))
  expect_true(any(grepl("R_4s reading: westgard", out_west, fixed = TRUE)))
  expect_true(any(grepl("R_4s (2)", out_range, fixed = TRUE)))
  expect_true(any(grepl("R_4s (1)", out_west, fixed = TRUE)))

  cc_r4s_only <- msa_control_chart(x_series, center = ctr, sd = s, rules = "R_4s", r4s = "westgard")
  out_r4s_only <- capture.output(print(cc_r4s_only))
  expect_true(any(grepl("R_4s reading: westgard", out_r4s_only, fixed = TRUE)))
  expect_true(any(grepl("rules fired: R_4s (1)", out_r4s_only, fixed = TRUE)))
  expect_true(any(grepl("^[[:space:]]*6[[:space:]]+", out_r4s_only)))

  # End-to-end msa_report rendering in GFM Markdown and HTML for both readings and legacy chart
  grr <- msa_grr(msa_fit(ic50_demo, type = "numeric"))
  for (mode in c("range", "westgard", "legacy")) {
    chart_in <- if (mode == "westgard") cc_west else cc_range
    if (mode == "legacy") attr(chart_in, "r4s") <- NULL

    md_path <- tempfile(fileext = ".md")
    html_path <- tempfile(fileext = ".html")
    on.exit(unlink(c(md_path, html_path)), add = TRUE)

    ret_md <- withVisible(msa_report(
      grr, runs = ic50_demo, control_chart = chart_in,
      output_file = md_path,
      output_format = rmarkdown::md_document(variant = "gfm", pandoc_args = "--wrap=none"),
      quiet = TRUE
    ))
    ret_html <- withVisible(msa_report(
      grr, runs = ic50_demo, control_chart = chart_in,
      output_file = html_path,
      output_format = "html_document",
      quiet = TRUE
    ))
    expect_false(ret_md$visible)
    expect_identical(ret_md$value, normalizePath(md_path))
    expect_false(ret_html$visible)
    expect_identical(ret_html$value, normalizePath(html_path))

    md_text <- paste(readLines(md_path, warn = FALSE), collapse = " ")
    html_text <- gsub("[[:space:]]+", " ", paste(readLines(html_path, warn = FALSE), collapse = " "))

    expected_sentence <- if (mode == "westgard") {
      "R_4s uses the Westgard reading: one of two consecutive standardized values is above 2 and the other below -2."
    } else {
      "R_4s uses the range of two consecutive standardized values."
    }
    expect_match(md_text, expected_sentence, fixed = TRUE)
    expect_match(html_text, expected_sentence, fixed = TRUE)

    if (mode == "westgard") {
      expect_match(md_text, "[|][[:space:]]*R_4s[[:space:]]*[|][[:space:]]*1[[:space:]]*[|][[:space:]]*6[[:space:]]*[|]")
      expect_match(md_text, "[|][[:space:]]*reject[[:space:]]*[|][[:space:]]*3[[:space:]]*[|][[:space:]]*6, 9, 14[[:space:]]*[|]")
    } else {
      expect_match(md_text, "[|][[:space:]]*R_4s[[:space:]]*[|][[:space:]]*2[[:space:]]*[|][[:space:]]*3, 6[[:space:]]*[|]")
      expect_match(md_text, "[|][[:space:]]*reject[[:space:]]*[|][[:space:]]*4[[:space:]]*[|][[:space:]]*3, 6, 9, 14[[:space:]]*[|]")
    }
  }
})

test_that("QA-M3c-E2E-2: msa_simulate latent item truth and msa_plan replicates, hand-computed Formelsammlung §9 metrics and RNG isolation hold end-to-end (seed = 20261108)", {
  old_opt <- options(testthat.progress.max_fails = Inf, width = 220, OutDec = ".")
  on.exit(options(old_opt), add = TRUE)
  set.seed(20261108L)

  ank16 <- qa_m3c_anchor("ANK-16")$value$study_var
  tol_arith <- as.numeric(qa_m3c_anchor("ANK-TOL")$value$arithmetic$abs_tol)

  vc <- list(
    item = 1.0, prompt = 0.03, model = 0.03, block = 0.005,
    item_prompt = 0.008, item_model = 0.01, prompt_model = 0.004, residual = 0.05
  )

  # 1. msa_simulate latent item-truth verification and shift equivariance
  set.seed(20261108L)
  rng_before <- .Random.seed
  runs0 <- msa_simulate(12L, 3L, 2L, 2L, n_blocks = 2L, vc = vc, mean = 0, seed = 20261108L)
  expect_identical(.Random.seed, rng_before)
  runs_shift <- msa_simulate(12L, 3L, 2L, 2L, n_blocks = 2L, vc = vc, mean = -4.75, seed = 20261108L)

  by_item <- split(runs0$latent, runs0$item_id)
  expect_identical(length(by_item), 12L)
  expect_true(all(vapply(by_item, function(v) max(abs(v - v[1L])) == 0, logical(1L))))
  expect_gt(stats::var(vapply(by_item, `[`, numeric(1L), 1L)), 0)
  expect_lte(max(abs((runs0$value - runs0$latent) - (runs_shift$value - runs_shift$latent))), tol_arith)
  expect_lte(max(abs((runs_shift$latent - runs0$latent) - (-4.75))), tol_arith)

  # 2. msa_plan end-to-end with multiple scenarios (including 1-block and 2-block, and 1-prompt)
  scenarios <- data.frame(
    n_items = c(8L, 10L, 8L),
    n_prompts = c(3L, 2L, 1L),
    n_models = c(2L, 2L, 2L),
    n_reps = c(2L, 2L, 2L),
    n_blocks = c(1L, 2L, 1L),
    tag = c("plan_A", "plan_B", "single_prompt"),
    stringsAsFactors = FALSE
  )
  nsim <- 8L
  set.seed(20261108L)
  rng_before_plan <- .Random.seed
  plan_res <- msa_plan(scenarios, vc = vc, nsim = nsim, seed = 20261108L, verbose = FALSE)
  expect_identical(.Random.seed, rng_before_plan)
  expect_s3_class(plan_res, "msa_plan")
  expect_identical(nrow(plan_res), 3L)
  expect_identical(plan_res$tag, scenarios$tag)
  expect_identical(attr(plan_res, "nsim"), nsim)
  expect_identical(attr(plan_res, "vc"), vc)

  reps <- attr(plan_res, "replicates", exact = TRUE)
  expect_true(is.data.frame(reps))
  expect_identical(names(reps), c("scenario", "sim", "estimate", "singular", "prompt"))
  expect_identical(nrow(reps), 3L * nsim)
  expect_identical(reps$scenario, rep(1:3, each = nsim))
  expect_identical(reps$sim, rep(seq_len(nsim), times = 3L))
  expect_true(all(is.finite(reps$estimate) & reps$estimate >= 0 & reps$estimate <= 100))
  expect_true(is.logical(reps$singular) && !anyNA(reps$singular))
  expect_true(all(is.finite(reps$prompt[reps$scenario %in% 1:2]) & reps$prompt[reps$scenario %in% 1:2] >= 0))
  expect_true(all(is.na(reps$prompt[reps$scenario == 3L])))

  # Replay the RNG stream manually and verify every replicate matches msa_simulate + msa_fit + grr_stats
  set.seed(20261108L)
  for (i in seq_len(nrow(scenarios))) {
    s <- scenarios[i, ]
    for (b in seq_len(nsim)) {
      sim_runs <- msa_simulate(s$n_items, s$n_prompts, s$n_models, s$n_reps, n_blocks = s$n_blocks, vc = vc)
      fit <- suppressWarnings(suppressMessages(msa_fit(sim_runs, type = "numeric")))
      item_v <- fit$vc$variance[fit$vc$source == "item"]
      other_v <- sum(fit$vc$variance[fit$vc$source != "item"])
      est_expected <- 100 * sqrt(other_v / (other_v + item_v))
      row_idx <- (i - 1L) * nsim + b
      expect_equal(reps$estimate[row_idx], est_expected, tolerance = tol_arith)
      expect_identical(reps$singular[row_idx], isTRUE(fit$singular))
      if (s$n_prompts > 1L) {
        expect_equal(reps$prompt[row_idx], fit$vc$variance[fit$vc$source == "prompt"], tolerance = tol_arith)
      } else {
        expect_identical(reps$prompt[row_idx], NA_real_)
      }
    }
  }

  # Recompute all summary columns from replicates by hand (Formelsammlung §9)
  grr_var <- sum(unlist(vc[names(vc) != "item"]))
  true_grr <- 100 * sqrt(grr_var / (grr_var + vc$item))
  verdict_fn <- function(v) {
    ifelse(v < as.numeric(ank16$acceptable_below), "acceptable",
           ifelse(v > as.numeric(ank16$unacceptable_above), "unacceptable", "marginal"))
  }
  q7 <- function(x, p) {
    sx <- sort(x)
    n <- length(sx)
    h <- 1 + (n - 1) * p
    lo <- floor(h)
    hi <- min(lo + 1L, n)
    sx[lo] + (h - lo) * (sx[hi] - sx[lo])
  }

  for (i in seq_len(nrow(plan_res))) {
    sub <- reps[reps$scenario == i, ]
    est <- sub$estimate
    m <- sum(est) / nsim
    ss <- sum((est - m)^2)
    empse <- sqrt(ss / (nsim - 1L))
    expect_equal(plan_res$grr_true[i], true_grr, tolerance = tol_arith)
    expect_equal(plan_res$mean[i], m, tolerance = tol_arith)
    expect_equal(plan_res$bias[i], m - true_grr, tolerance = tol_arith)
    expect_equal(plan_res$empse[i], empse, tolerance = tol_arith)
    expect_equal(plan_res$mcse_bias[i], empse / sqrt(nsim), tolerance = tol_arith)
    expect_equal(plan_res$mcse_empse[i], empse / sqrt(2 * (nsim - 1L)), tolerance = tol_arith)
    expect_equal(plan_res$q2.5[i], q7(est, 0.025), tolerance = tol_arith)
    expect_equal(plan_res$median[i], q7(est, 0.50), tolerance = tol_arith)
    expect_equal(plan_res$q97.5[i], q7(est, 0.975), tolerance = tol_arith)
    expect_equal(plan_res$rmse[i], sqrt(sum((est - true_grr)^2) / nsim), tolerance = tol_arith)
    expect_equal(plan_res$pct_singular[i], 100 * sum(sub$singular) / nsim, tolerance = tol_arith)
    expect_equal(plan_res$pct_misclassified[i],
                 100 * sum(verdict_fn(est) != verdict_fn(true_grr)) / nsim,
                 tolerance = tol_arith)
  }

  out_plan <- capture.output(ret_plan <- withVisible(print(plan_res)))
  expect_false(ret_plan$visible)
  expect_identical(ret_plan$value, plan_res)
  expect_match(out_plan[1L], "Study-size planning by simulation (8 simulations per scenario)", fixed = TRUE)
  expect_match(out_plan[2L], sprintf("%.1f %%", true_grr), fixed = TRUE)
})

test_that("QA-M3c-E2E-3: offline planning reader, generator round-trip and validation vignette table & literal guards hold end-to-end (seed = 20261108)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  skip_if_not_installed("knitr")
  set.seed(20261108L)

  ank89 <- qa_m3c_anchor("ANK-89")$value
  ank06 <- qa_m3c_anchor("ANK-06")$value
  tol_arith <- as.numeric(qa_m3c_anchor("ANK-TOL")$value$arithmetic$abs_tol)

  # 1. Offline reader check (both public mode and full repo_root mode) without running any simulation or fit
  reader_env <- new.env(parent = globalenv())
  reader_path <- system.file("validation", "planning", "reference_checks.R", package = "llmsa", mustWork = TRUE)
  sys.source(reader_path, envir = reader_env)

  repo_root <- Sys.getenv("REPO_ROOT", unset = "")
  if (!nzchar(repo_root) || !file.exists(file.path(repo_root, "DESCRIPTION"))) {
    cand <- normalizePath(testthat::test_path("..", ".."), mustWork = FALSE)
    if (file.exists(file.path(cand, "DESCRIPTION"))) repo_root <- cand
  }

  res_pub <- reader_env$planning_read_results(repo_root = "")
  expect_identical(res_pub$mode, "public")
  if (nzchar(repo_root) && file.exists(file.path(repo_root, "reference", "anchors", "ANK-89.json"))) {
    res_full <- reader_env$planning_read_results(repo_root = repo_root)
    expect_identical(res_full$mode, "full")
    expect_identical(res_pub$summary, res_full$summary)
    expect_identical(res_pub$replicates, res_full$replicates)
    expect_identical(res_pub$table, res_full$table)
  }

  expect_identical(res_pub$table$plan, paste0("S-plan-", 1:4))
  expect_identical(as.integer(res_pub$table$items), c(20L, 20L, 40L, 40L))
  expect_identical(as.integer(res_pub$table$prompts), c(3L, 5L, 3L, 5L))
  expect_identical(as.integer(res_pub$table$nu), c(2L, 4L, 2L, 4L))
  expect_equal(res_pub$table$cv_rule, sqrt(as.numeric(ank89$numerator) / c(2, 4, 2, 4)), tolerance = tol_arith)
  expect_true(all(res_pub$table$n_sim >= as.integer(ank06$n_sim_min)))

  # 2. Generator settings, CSV serialization and summary round-trip check
  gen_env <- new.env(parent = globalenv())
  gen_path <- system.file("validation", "sim", "planning_rule.R", package = "llmsa", mustWork = TRUE)
  sys.source(gen_path, envir = gen_env)

  settings <- gen_env$planning_rule_settings()
  expect_identical(settings$designs$plan, paste0("S-plan-", 1:4))
  expect_identical(settings$designs$seed, 20261108L + 1:4)
  expect_identical(settings$rng, c("Mersenne-Twister", "Inversion", "Rejection"))

  tmp_csv <- tempfile(fileext = ".csv.gz")
  on.exit(unlink(tmp_csv), add = TRUE)
  gen_env$planning_rule_csv(res_pub$replicates, tmp_csv)
  re_read_reps <- reader_env$planning_csv(
    tmp_csv,
    c("character", "integer", "integer", "numeric", "logical", "numeric"),
    reader_env$planning_replicate_columns
  )
  expect_identical(re_read_reps, res_pub$replicates)

  re_summary <- reader_env$planning_summarize(
    re_read_reps,
    settings$designs,
    settings$vc,
    reader_env$planning_inputs(repo_root = "")
  )
  expect_equal(re_summary, res_pub$summary, tolerance = tol_arith)

  # 3. Knit vignettes/validation.Rmd and verify section 7 tables and prose
  vig_candidates <- c(
    if (nzchar(repo_root)) file.path(repo_root, "vignettes", "validation.Rmd"),
    testthat::test_path("..", "..", "vignettes", "validation.Rmd")
  )
  vig_file <- vig_candidates[nzchar(vig_candidates) & file.exists(vig_candidates)][1L]
  expect_true(!is.na(vig_file) && file.exists(vig_file))

  md_out <- tempfile(fileext = ".md")
  fig_dir <- paste0(tempfile("qa-m3c-vig-fig-"), "/")
  on.exit(unlink(c(md_out, fig_dir), recursive = TRUE), add = TRUE)
  old_knitr <- knitr::opts_knit$get("base.dir")
  old_chunk <- knitr::opts_chunk$get("fig.path")
  on.exit({
    knitr::opts_knit$set(base.dir = old_knitr)
    knitr::opts_chunk$set(fig.path = old_chunk)
  }, add = TRUE)
  knitr::opts_knit$set(base.dir = dirname(md_out))
  knitr::opts_chunk$set(fig.path = fig_dir)

  knit_env <- new.env(parent = globalenv())
  knitr::knit(input = vig_file, output = md_out, quiet = TRUE, envir = knit_env)
  md_lines <- readLines(md_out, warn = FALSE)
  md_full <- paste(md_lines, collapse = " ")

  expect_match(md_full, "## System suitability and simulator validation", fixed = TRUE)
  expect_match(md_full, "## Planning rule for prompt-variance precision", fixed = TRUE)
  expect_match(md_full, "ANK-86", fixed = TRUE)
  expect_match(md_full, "ANK-87", fixed = TRUE)
  expect_match(md_full, "ANK-89", fixed = TRUE)
  expect_match(md_full, "S-plan-1", fixed = TRUE)
  expect_match(md_full, "S-plan-4", fixed = TRUE)
  expect_match(md_full, "Delta method: first two empirical raw moments", fixed = TRUE)
})
