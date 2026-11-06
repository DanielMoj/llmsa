# QA / Red Team E2E tests for M3b (fixed seed: 20261105)

qa_m3b_anchor <- function(id) {
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

qa_m3b_plot_capture <- function(x, ...) {
  grDevices::pdf(NULL)
  dev <- grDevices::dev.cur()
  on.exit(grDevices::dev.off(dev), add = TRUE)
  grDevices::dev.control("enable")
  ret <- withVisible(plot(x, ...))
  dl <- grDevices::recordPlot()[[1L]]

  dl_name <- function(entry) {
    f <- tryCatch(entry[[2L]][[1L]], error = function(e) NULL)
    if (is.list(f) && !is.null(f$name)) as.character(f$name) else ""
  }
  fn_names <- vapply(dl, dl_name, character(1L))
  calls <- lapply(dl, `[[`, 2L)

  xy <- calls[fn_names == "C_plotXY"][[1L]]
  title_call <- calls[fn_names == "C_title"][[1L]]
  ablines <- calls[fn_names == "C_abline"]
  texts <- calls[fn_names == "C_text"]
  list(
    ret = ret,
    x = as.numeric(xy[[2L]]$x),
    y = as.numeric(xy[[2L]]$y),
    pch = xy[[5L]],
    main = as.character(title_call[[2L]]),
    xlab = as.character(title_call[[4L]]),
    ylab = as.character(title_call[[5L]]),
    abline_h = vapply(ablines, function(cl) as.numeric(cl[[4L]]), numeric(1L)),
    abline_lty = vapply(ablines, function(cl) as.integer(cl[[8L]]), integer(1L)),
    text_x = as.numeric(texts[[1L]][[2L]]$x),
    text_y = as.numeric(texts[[1L]][[2L]]$y),
    text_labels = as.character(texts[[1L]][[3L]]),
    text_pos = as.integer(texts[[1L]][[5L]]),
    text_cex = as.numeric(texts[[1L]][[7L]])
  )
}

test_that("QA-M3b-E2E-1: pb_design matrices, FrF2 equivalence, smallest-size rule, level labels and RNG isolation hold end-to-end (seed = 20261105)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  skip_if_not_installed("FrF2")
  set.seed(20261105L)

  ank80 <- qa_m3b_anchor("ANK-80")$value
  coding <- unlist(ank80$coding)
  generators <- lapply(ank80$generators, function(s) {
    as.numeric(unname(coding[strsplit(s, "", fixed = TRUE)[[1L]]]))
  })
  sizes <- as.integer(ank80$sizes)

  for (n in sizes) {
    k <- n - 1L
    d <- pb_design(k, n_runs = n, randomize = FALSE)
    X <- attr(d, "coded")
    g <- generators[[as.character(n)]]

    expect_identical(dim(X), c(n, k))
    expect_identical(as.numeric(X[1L, ]), g)
    expect_identical(as.numeric(X[n, ]), rep(as.numeric(ank80$construction$final_row), k))
    for (i in 2:k) {
      expect_identical(as.numeric(X[i, ]), as.numeric(c(X[i - 1L, k], X[i - 1L, seq_len(k - 1L)])))
    }
    expect_identical(as.numeric(colSums(X)), rep(0, k))
    H <- cbind(1, X)
    expect_identical(unname(crossprod(H)), diag(as.numeric(n), n))
    expect_identical(unname(as.matrix(d[, paste0("F", seq_len(k)), drop = FALSE])), unname(X))

    frf <- suppressMessages(suppressWarnings(FrF2::pb(nruns = n, nfactors = k,
                                                      randomize = FALSE, boxtyssedal = FALSE)))
    Fmat <- apply(as.matrix(frf), 2L, function(col) ifelse(as.numeric(as.character(col)) > 0, 1, -1))
    row_minus <- which(apply(Fmat == -1, 1L, all) | apply(Fmat == 1, 1L, all))
    expect_gte(length(row_minus), 1L)
    expect_identical(unname(crossprod(cbind(1, Fmat))), diag(as.numeric(n), n))
  }

  # Smallest size selection N - 1 >= k for k = 1..max(sizes - 1)
  max_k <- sizes - 1L
  expected_n <- function(k) sizes[which(max_k >= k)[1L]]
  for (k in seq_len(max(max_k))) {
    dk <- pb_design(k, randomize = FALSE)
    expect_identical(nrow(dk), expected_n(k))
    expect_identical(ncol(attr(dk, "coded")), k)
  }

  # RNG state isolation and reproducible seeded permutation with labelled factors
  facs <- list(
    prompt_style = c("concise", "cot"),
    temperature = c("0.0", "0.7"),
    unit_format = c("SI", "conventional"),
    json_schema = c("strict", "loose"),
    context_order = c("clinical_first", "lab_first"),
    few_shot = c("0shot", "3shot"),
    stop_token = c("none", "newline"),
    system_role = c("assistant", "specialist")
  )
  set.seed(20261105L)
  seed_before <- .Random.seed
  d_seed1 <- pb_design(facs, seed = 20261105L)
  expect_identical(.Random.seed, seed_before)
  d_seed2 <- pb_design(facs, seed = 20261105L)
  expect_identical(d_seed1, d_seed2)
  d_other <- pb_design(facs, seed = 20261106L)
  expect_false(identical(attr(d_seed1, "coded"), attr(d_other, "coded")))

  X_seed <- attr(d_seed1, "coded")
  for (nm in names(facs)) {
    lvl_col <- d_seed1[[paste0(nm, "_level")]]
    expect_identical(lvl_col, ifelse(X_seed[, nm] > 0, facs[[nm]][2L], facs[[nm]][1L]))
  }

  hdr <- capture.output(ret <- withVisible(print(d_seed1)))
  expect_false(ret$visible)
  expect_identical(ret$value, d_seed1)
  expect_identical(hdr[1L], "Plackett-Burman design: 12 runs, 8 factors (12-run design screens up to 11)")
})

test_that("QA-M3b-E2E-2: msa_robustness matches DoE.base::ME.Lenth and unrepx::PSE across designs and plot.msa_robustness records Daniel (1959) quantiles (seed = 20261105)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  skip_if_not_installed("unrepx")
  skip_if_not_installed("DoE.base")
  set.seed(20261105L)

  ank_tol <- qa_m3b_anchor("ANK-TOL")$value
  tol_arith <- ank_tol$arithmetic$abs_tol
  tol_frf2 <- ank_tol$frf2_unrepx$pse_me_tol
  sizes <- as.integer(qa_m3b_anchor("ANK-80")$value$sizes)

  for (n in sizes) {
    k <- n - 1L
    d <- pb_design(k, n_runs = n, seed = 20261105L + n)
    X <- attr(d, "coded")
    true_eff <- c(2.4, -1.1, rep(0, k - 2L))
    y <- as.numeric(5 + X %*% (true_eff / 2) + stats::rnorm(n, sd = 0.15))
    rob <- msa_robustness(d, y)

    # Exact level-mean difference and 2 * lm coefficient
    lm_coef <- 2 * unname(stats::coef(stats::lm(y ~ X))[-1L])
    names(lm_coef) <- colnames(X)
    expect_equal(rob$effect, unname(lm_coef[rob$factor]), tolerance = tol_arith)

    pse_unrepx <- as.numeric(unrepx::PSE(rob$effect, method = "Lenth"))
    expect_equal(attr(rob, "pse"), pse_unrepx, tolerance = tol_frf2)

    doe <- suppressMessages(DoE.base::ME.Lenth(unname(rob$effect), simulated = FALSE, alpha = 0.05))
    expect_equal(attr(rob, "pse"), as.numeric(doe$PSE), tolerance = tol_frf2)
    expect_equal(attr(rob, "me"), as.numeric(doe$ME), tolerance = tol_frf2)
    expect_equal(attr(rob, "sme"), as.numeric(doe$SME), tolerance = tol_frf2)

    rec <- qa_m3b_plot_capture(rob)
    expect_false(rec$ret$visible)
    expect_identical(rec$ret$value, rob)
    q_expected <- stats::qnorm(0.5 + (seq_len(k) - 0.5) / (2 * k))
    ord <- order(abs(rob$effect))
    expect_equal(rec$x, q_expected, tolerance = tol_arith)
    expect_equal(rec$y, abs(rob$effect)[ord], tolerance = tol_arith)
    expect_identical(rec$text_labels, rob$factor[ord])
    expect_equal(rec$abline_h, c(attr(rob, "me"), attr(rob, "sme")), tolerance = tol_arith)
    expect_identical(rec$abline_lty, c(2L, 3L))
    expect_match(rec$xlab, "Daniel.*1959|1959.*Daniel")
    expect_identical(rec$ylab, "|effect|")
  }

  # Exact trimming boundary |c_j| = 2.5 * s0: excluded by strict '< 2.5 * s0'
  d8 <- pb_design(7L, n_runs = 8L, randomize = FALSE)
  X8 <- attr(d8, "coded")
  eff_bound <- c(3.75, 2.0, 1.2, 1.0, 0.8, 0.5, 0.2)
  y_bound <- as.numeric(X8 %*% (eff_bound / 2))
  rob_bound <- msa_robustness(d8, y_bound)
  expect_equal(attr(rob_bound, "pse"), 1.5 * stats::median(eff_bound[-1L]), tolerance = tol_arith)
})

test_that("QA-M3b-E2E-3: logit transform, help-page wording and msa_report integration work end-to-end without altering transform = 'none' (seed = 20261105)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  set.seed(20261105L)

  tol_arith <- qa_m3b_anchor("ANK-TOL")$value$arithmetic$abs_tol

  facs <- list(
    fmt = c("plain", "table"),
    temp = c(0, 0.5),
    units = c("SI", "imperial"),
    typos = c("none", "mild"),
    prompt = c("v1", "v2"),
    context = c("short", "long"),
    schema = c("json", "free")
  )
  d <- pb_design(facs, seed = 20261105L)
  X <- attr(d, "coded")
  eta <- as.numeric(1.8 - 1.1 * X[, "typos"] - 0.45 * X[, "temp"] + stats::rnorm(nrow(X), sd = 0.04))
  p <- stats::plogis(eta)

  rob_default <- msa_robustness(d, p)
  rob_none <- msa_robustness(d, p, transform = "none")
  expect_identical(rob_default, rob_none)
  expect_identical(attr(rob_default, "seed", exact = TRUE), 20261105L)
  expect_identical(
    sort(names(attributes(rob_default))),
    sort(c("names", "row.names", "class", "pse", "me", "sme", "alpha", "response_mean", "response_sd", "n_runs", "seed"))
  )

  rob_logit <- msa_robustness(d, p, transform = "logit")
  rob_manual <- msa_robustness(d, stats::qlogis(p), transform = "none")
  expect_identical(rob_logit, rob_manual)
  expect_equal(attr(rob_logit, "response_mean"), mean(log(p / (1 - p))), tolerance = tol_arith)
  expect_equal(attr(rob_logit, "response_sd"), stats::sd(log(p / (1 - p))), tolerance = tol_arith)

  # Plain data.frame and subset of factors with custom alpha
  sub_factors <- c("typos", "temp", "fmt", "units")
  df_plain <- as.data.frame(X)
  rob_sub_pb <- msa_robustness(d, p, factors = sub_factors, alpha = 0.10, transform = "logit")
  rob_sub_df <- msa_robustness(df_plain, p, factors = sub_factors, alpha = 0.10, transform = "logit")
  rob_sub_man <- msa_robustness(df_plain, log(p / (1 - p)), factors = sub_factors, alpha = 0.10)
  expect_identical(attr(rob_sub_pb, "seed", exact = TRUE), 20261105L)
  expect_null(attr(rob_sub_df, "seed", exact = TRUE))
  expect_identical(structure(rob_sub_pb, seed = NULL), rob_sub_df)
  expect_equal(rob_sub_pb$effect, rob_sub_man$effect, tolerance = tol_arith)
  expect_equal(attr(rob_sub_pb, "pse"), attr(rob_sub_man, "pse"), tolerance = tol_arith)
  expect_equal(attr(rob_sub_pb, "me"), attr(rob_sub_man, "me"), tolerance = tol_arith)
  expect_equal(attr(rob_sub_pb, "sme"), attr(rob_sub_man, "sme"), tolerance = tol_arith)

  # Help page verification (from installed Rd database or repo man/msa_robustness.Rd)
  repo_root <- Sys.getenv("REPO_ROOT", unset = "")
  rd_candidates <- c(
    if (nzchar(repo_root)) file.path(repo_root, "man", "msa_robustness.Rd"),
    testthat::test_path("..", "..", "man", "msa_robustness.Rd")
  )
  rd_files <- rd_candidates[file.exists(rd_candidates)]
  rd_obj <- if (length(rd_files)) {
    tools::parse_Rd(rd_files[1L])
  } else {
    utils:::.getHelpFile(utils::help("msa_robustness", package = "llmsa"))
  }
  rd_txt <- paste(capture.output(tools::Rd2txt(
    rd_obj,
    options = list(underline_titles = FALSE, itemBullet = "* ")
  )), collapse = " ")
  expect_true(grepl("(^|[^A-Za-z])conservative([^A-Za-z]|$)", rd_txt, ignore.case = TRUE, perl = TRUE))
  expect_true(grepl("(^|[^A-Za-z])nominal([^A-Za-z]|$)", rd_txt, ignore.case = TRUE, perl = TRUE))
  expect_false(grepl("at the 5[[:space:]]*%[[:space:]]*level per effect", rd_txt, ignore.case = TRUE, perl = TRUE))

  small_runs <- as_msa_runs(data.frame(
    item_id = rep(paste0("I", 1:4), each = 4L),
    prompt_id = rep(rep(c("P1", "P2"), each = 2L), 4L),
    model_id = "M1",
    rep = rep(1:2, 8L),
    value = c(1.0, 1.1, 1.2, 1.1, 2.0, 2.1, 1.9, 2.0,
              3.1, 3.0, 3.2, 3.1, 4.0, 4.2, 4.1, 4.0),
    stringsAsFactors = FALSE
  ))
  fit_num <- suppressMessages(msa_fit(small_runs, type = "numeric"))
  grr_num <- msa_grr(fit_num)
  md_fmt <- rmarkdown::md_document(variant = "gfm", pandoc_args = "--wrap=none")
  out_md <- tempfile(fileext = ".md")
  on.exit(unlink(out_md), add = TRUE)
  msa_report(grr_num, robustness = rob_logit, output_file = out_md, output_format = md_fmt, quiet = TRUE)
  md_txt <- paste(readLines(out_md, warn = FALSE, encoding = "UTF-8"), collapse = " ")
  expect_match(md_txt, sprintf("Lenth PSE %.4f, ME %.4f, SME %.4f",
                               attr(rob_logit, "pse"), attr(rob_logit, "me"), attr(rob_logit, "sme")),
               fixed = TRUE)
  expect_match(md_txt, "typos (also above SME)", fixed = TRUE)
})
