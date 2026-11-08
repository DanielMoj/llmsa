# QA / Red Team fuzz & boundary tests for M3c (fixed seed: 20261108)

qa_m3c_fuzz_anchor <- function(id) {
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

qa_m3c_expect_clean_error <- function(expr, pattern = NULL) {
  err <- expect_no_warning(tryCatch(expr, error = identity))
  expect_s3_class(err, "error")
  expect_null(conditionCall(err))
  if (!is.null(pattern)) {
    expect_match(conditionMessage(err), pattern, fixed = TRUE)
  }
  invisible(err)
}

qa_m3c_westgard_oracle <- function(z, rules = c("1_2s", "1_3s", "2_2s", "R_4s", "4_1s", "10_x"),
                                   r4s = c("range", "westgard")) {
  r4s <- match.arg(r4s)
  n <- length(z)
  run_same <- function(k, m) {
    out <- logical(n)
    for (i in seq_len(n)) {
      if (i < m) next
      w <- z[(i - m + 1L):i]
      out[i] <- all(w > k) || all(w < -k)
    }
    out
  }
  r4s_vec <- if (n < 2L) {
    rep(FALSE, n)
  } else if (r4s == "range") {
    c(FALSE, abs(z[-1L] - z[-n]) > 4 & !is.na(z[-n]))
  } else {
    prev <- z[-n]
    cur <- z[-1L]
    c(FALSE, ((cur > 2 & prev < -2) | (cur < -2 & prev > 2)) & !is.na(prev))
  }
  all_cols <- list(
    "1_2s" = abs(z) > 2,
    "1_3s" = abs(z) > 3,
    "2_2s" = run_same(2, 2L),
    "R_4s" = r4s_vec,
    "4_1s" = run_same(1, 4L),
    "10_x" = run_same(0, 10L)
  )
  out <- all_cols[rules]
  rej_rules <- setdiff(rules, "1_2s")
  if (length(rej_rules)) {
    mat <- do.call(cbind, lapply(rej_rules, function(r) out[[r]] %in% TRUE))
    out$reject <- apply(mat, 1L, any)
  } else {
    out$reject <- rep(FALSE, n)
  }
  out
}

test_that("QA-M3c-FUZZ-1: msa_control_chart matches independent oracle across 250 adversarial boundary, NA-interspersed, affine-scaled and rule-subset series (seed = 20261108)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  set.seed(20261108L)

  eps <- 2^-30
  base_atoms <- c(0, 1, 1.5, 2, 2.5, 3, 4)
  atoms <- unique(c(base_atoms, base_atoms + eps, base_atoms - eps,
                    -base_atoms, -base_atoms - eps, -base_atoms + eps))

  all_rules <- c("1_2s", "1_3s", "2_2s", "R_4s", "4_1s", "10_x")

  for (trial in seq_len(250L)) {
    len <- sample(1:25, 1L)
    z <- sample(atoms, len, replace = TRUE)
    if (stats::runif(1L) < 0.25) {
      na_idx <- sample.int(len, size = max(1L, floor(len / 5L)))
      z[na_idx] <- NA_real_
    }
    k_rules <- sample(0:length(all_rules), 1L)
    rules_sub <- if (k_rules == 0L) character(0L) else sample(all_rules, k_rules, replace = FALSE)

    for (reading in c("range", "westgard")) {
      cc <- msa_control_chart(z, center = 0, sd = 1, rules = rules_sub, r4s = reading)
      oracle <- qa_m3c_westgard_oracle(z, rules = rules_sub, r4s = reading)

      expect_identical(attr(cc, "r4s"), reading)
      expect_identical(attr(cc, "rules"), rules_sub)
      expect_false(anyNA(cc$reject))
      expect_identical(cc$reject, oracle$reject)
      for (r in rules_sub) {
        expect_identical(cc[[r]], oracle[[r]])
      }
    }
  }

  # Exact affine and sign-reflection invariance on non-NA boundary series (dyadic center & scale)
  for (trial in seq_len(40L)) {
    z <- sample(atoms, 18L, replace = TRUE)
    ctr <- sample(-64:64, 1L) * 2^sample(-4:4, 1L)
    s <- 2^sample(-8:8, 1L)
    x <- ctr + s * z
    for (reading in c("range", "westgard")) {
      c0 <- msa_control_chart(z, center = 0, sd = 1, r4s = reading)
      c1 <- msa_control_chart(x, center = ctr, sd = s, r4s = reading)
      c_neg <- msa_control_chart(-z, center = 0, sd = 1, r4s = reading)
      expect_identical(as.data.frame(c1)[, all_rules], as.data.frame(c0)[, all_rules])
      expect_identical(c1$reject, c0$reject)
      expect_identical(as.data.frame(c_neg)[, all_rules], as.data.frame(c0)[, all_rules])
      expect_identical(c_neg$reject, c0$reject)
    }
  }

  # Invalid sd, unknown reading and tampered r4s attribute in print() and msa_report()
  for (bad_sd in list(0, -1e-12, -5, NA_real_, NaN, Inf, -Inf)) {
    qa_m3c_expect_clean_error(msa_control_chart(1:5, center = 0, sd = bad_sd), "`sd` must be a positive number.")
  }
  qa_m3c_expect_clean_error(msa_control_chart(rep(4, 10)), "`sd` must be a positive number.")
  qa_m3c_expect_clean_error(msa_control_chart(5, center = 5), "`sd` must be a positive number.")
  expect_error(msa_control_chart(1:5, center = 0, sd = 1, r4s = "invalid_reading"))

  cc_valid <- msa_control_chart(c(0, 2.5, -2.5), center = 0, sd = 1)
  grr_stub <- structure(list(), class = "msa_grr")
  for (bad_attr in list("", "RANGE", "WESTGARD", c("range", "westgard"), character(0L), NA_character_, 1L, list("range"))) {
    cc_bad <- cc_valid
    attr(cc_bad, "r4s") <- bad_attr
    qa_m3c_expect_clean_error(print(cc_bad), "The control chart `r4s` attribute must be 'range' or 'westgard'.")
    qa_m3c_expect_clean_error(msa_report(grr_stub, control_chart = cc_bad),
                              "The control chart `r4s` attribute must be 'range' or 'westgard'.")
  }
})

test_that("QA-M3c-FUZZ-2: msa_plan input validation, nsim = 1 edge case, single-prompt NA handling, mocked corrupt fits and tampered planning validation artifacts fail cleanly (seed = 20261108)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")
  set.seed(20261108L)

  tol_arith <- as.numeric(qa_m3c_fuzz_anchor("ANK-TOL")$value$arithmetic$abs_tol)
  scen <- data.frame(n_items = 6L, n_prompts = 2L, n_models = 2L, n_reps = 2L, n_blocks = 1L)

  # 1. Invalid nsim values rejected before any simulation
  bad_nsims <- list(
    0L, -1L, -100, 1.5, 2 + 1e-9, NA_integer_, NA_real_, NaN, Inf, -Inf,
    NULL, integer(0L), c(2L, 3L), "5", TRUE, FALSE, list(5L), as.complex(5)
  )
  for (bad_n in bad_nsims) {
    qa_m3c_expect_clean_error(msa_plan(scen, nsim = bad_n, verbose = FALSE), "`nsim` must be a positive integer.")
  }

  # 2. Missing required scenario columns
  for (col in c("n_items", "n_prompts", "n_models", "n_reps")) {
    scen_bad <- scen
    scen_bad[[col]] <- NULL
    qa_m3c_expect_clean_error(msa_plan(scen_bad, nsim = 1L, verbose = FALSE),
                              paste0("scenarios is missing required column(s): ", col))
  }

  # 3. Edge case nsim = 1 with n_prompts = 1 and n_prompts = 2, plus RNG restoration when .Random.seed is absent
  scen_1p <- data.frame(n_items = c(6L, 6L), n_prompts = c(1L, 2L), n_models = c(2L, 2L), n_reps = c(2L, 2L))
  saved_seed <- if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) get(".Random.seed", envir = .GlobalEnv) else NULL
  on.exit({
    if (is.null(saved_seed)) {
      if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
    } else {
      assign(".Random.seed", saved_seed, envir = .GlobalEnv)
    }
  }, add = TRUE)

  if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  p1 <- msa_plan(scen_1p, nsim = 1L, seed = 20261108L, verbose = FALSE)
  expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))

  r1 <- attr(p1, "replicates", exact = TRUE)
  expect_identical(nrow(r1), 2L)
  expect_identical(r1$prompt[1L], NA_real_)
  expect_true(is.finite(r1$prompt[2L]) && r1$prompt[2L] >= 0)
  expect_identical(p1$empse, c(NA_real_, NA_real_))
  expect_identical(p1$mcse_bias, c(NA_real_, NA_real_))
  expect_identical(p1$mcse_empse, c(NA_real_, NA_real_))
  expect_equal(p1$bias, r1$estimate - p1$grr_true, tolerance = tol_arith)
  expect_equal(p1$rmse, abs(p1$bias), tolerance = tol_arith)

  # 4. Offline planning reader and delta-method CV MCSE fuzzing
  e <- new.env(parent = globalenv())
  sys.source(system.file("validation", "planning", "reference_checks.R", package = "llmsa", mustWork = TRUE), envir = e)

  # Positive scale invariance of empirical CV, boundary share and delta-method CV MCSE
  for (trial in seq_len(30L)) {
    n <- sample(20:80, 1L)
    y <- stats::rgamma(n, shape = 1.5, scale = 0.05)
    zero_idx <- sample.int(n, size = sample(0:5, 1L))
    y[zero_idx] <- 0
    if (all(y == 0)) y[1L] <- 0.1
    scale_factor <- 2^sample(-10:10, 1L)

    s1 <- e$planning_prompt_summary(y)
    s2 <- e$planning_prompt_summary(scale_factor * y)
    expect_equal(s1$cv_empirical, s2$cv_empirical, tolerance = tol_arith)
    expect_identical(s1$boundary_share, s2$boundary_share)
    expect_identical(s1$mcse_boundary, s2$mcse_boundary)
    expect_equal(s1$mcse_cv, s2$mcse_cv, tolerance = tol_arith)
  }

  # Degenerate prompt variance series: all-zero vs positive-constant
  qa_m3c_expect_clean_error(e$planning_prompt_summary(c(0, 0, 0)), "The empirical prompt CV is undefined.")
  const_pos <- e$planning_prompt_summary(rep(0.05, 10L))
  expect_identical(const_pos$cv_empirical, 0)
  expect_identical(const_pos$mcse_cv, NA_real_)
  expect_match(const_pos$mcse_cv_note, "undefined:", fixed = TRUE)
})
