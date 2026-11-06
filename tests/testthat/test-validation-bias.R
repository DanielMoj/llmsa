# These deliberately small synthetic runs test plumbing and reproducibility,
# not coverage. The vignette and class A acceptance use the full ANK-06 size.
m3a_coverage_helpers <- function() {
  e <- new.env(parent = globalenv())
  sys.source(system.file("validation", "agreement", "bias_coverage.R", package = "llmsa", mustWork = TRUE), envir = e)
  e
}

m3a_coverage_anchors <- function() {
  latent <- latent_test_helpers()
  latent$latent_anchors(latent$latent_context())
}

m3a_restore_rng <- function(code) {
  kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (had_seed) seed <- get(".Random.seed", envir = globalenv(), inherits = FALSE)
  on.exit({
    RNGkind(kind[1], kind[2], kind[3])
    if (had_seed) assign(".Random.seed", seed, envir = globalenv()) else
      if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) rm(".Random.seed", envir = globalenv())
  }, add = TRUE)
  force(code)
}

test_that("bias coverage uses every interval and agrees with independent t calculations", {
  h <- m3a_coverage_helpers()
  anchors <- m3a_coverage_anchors()
  r <- h$agreement_bias_coverage(anchors, n_sim = 7L)
  expect_identical(r$n_min, anchors[["ANK-06"]]$value$n_sim_min)
  expect_identical(r$pass_factor, anchors[["ANK-TOL"]]$value$mc_factor$pass)
  expect_identical(r$report_factor, anchors[["ANK-TOL"]]$value$mc_factor$report)
  expect_identical(r$settings$rng, c("Mersenne-Twister", "Inversion", "Rejection"))
  expect_identical(r$settings$scenarios$seed, c(20261106L, 20261107L))
  expect_identical(nrow(r$replicates), 14L)
  expect_identical(names(r$versions), c("R", "llmsa"))
  expect_identical(r$versions[["llmsa"]], as.character(packageVersion("llmsa")))
  expect_true(is.finite(r$elapsed) && r$elapsed >= 0)
  m3a_restore_rng({
    RNGkind("Mersenne-Twister", "Inversion", "Rejection")
    for (i in seq_len(nrow(r$settings$scenarios))) {
      sc <- r$settings$scenarios[i, ]
      set.seed(sc$seed)
      per_item <- sc$prompts * sc$models * sc$reps
      oracle <- t(vapply(seq_len(7L), function(iteration) {
        truth <- stats::rnorm(sc$items, 0, sqrt(sc$item))
        reference <- rep(truth, each = per_item)
        values <- reference + sc$bias + stats::rnorm(length(reference), 0, sqrt(sc$residual))
        as.numeric(stats::t.test(values - reference, conf.level = r$settings$level)$conf.int)
      }, numeric(2)))
      rows <- r$replicates[r$replicates$scenario == sc$scenario, ]
      expect_equal(unname(as.matrix(rows[c("lower", "upper")])), unname(oracle),
                   tolerance = numeric_tolerance("package_compare", "abs_tol"))
      covered <- oracle[, 1] <= sc$bias & oracle[, 2] >= sc$bias
      expect_identical(rows$covered, covered)
      summary <- r$summary[i, ]
      expect_identical(summary$n_sim, 7L)
      expect_equal(summary$coverage, sum(covered) / length(covered))
      expect_equal(summary$MCSE, sqrt(summary$coverage * (1 - summary$coverage) / length(covered)))
      expect_false(is.nan(summary$distance_mcse))
    }
  })
  table <- h$agreement_coverage_table(r)
  expect_identical(names(table), c("scenario", "coverage", "MCSE", "n_sim", "distance to level (MCSE)", "finding"))
  expect_identical(table$n_sim, rep("7", 2))
  for (nm in c("coverage", "MCSE")) expect_identical(table[[nm]], formatC(r$summary[[nm]], format = "f", digits = 6))
})

test_that("coverage is deterministic and preserves the caller RNG including absence", {
  h <- m3a_coverage_helpers()
  anchors <- m3a_coverage_anchors()
  m3a_restore_rng({
    RNGkind("L'Ecuyer-CMRG", "Inversion", "Rejection")
    set.seed(17)
    original <- .Random.seed
    first <- h$agreement_bias_coverage(anchors, n_sim = 3L)
    expect_identical(.Random.seed, original)
    expect_identical(RNGkind(), c("L'Ecuyer-CMRG", "Inversion", "Rejection"))
    set.seed(81)
    second <- h$agreement_bias_coverage(anchors, n_sim = 3L)
    expect_identical(first$summary, second$summary)
    expect_identical(first$replicates, second$replicates)
    rm(".Random.seed", envir = globalenv())
    before_kind <- RNGkind()
    h$agreement_bias_coverage(anchors, n_sim = 1L)
    expect_false(exists(".Random.seed", envir = globalenv(), inherits = FALSE))
    expect_identical(RNGkind(), before_kind)
  })
})

test_that("coverage follows the loaded namespace and does not omit failed repetitions", {
  h <- m3a_coverage_helpers()
  anchors <- m3a_coverage_anchors()
  calls <- 0L
  local_mocked_bindings(msa_bias = function(runs, reference, level) {
    calls <<- calls + 1L
    # Deliberate test double, not empirical input. All intervals miss truth.
    list(overall = c(lower = -3, upper = -2))
  }, .package = "llmsa")
  r <- h$agreement_bias_coverage(anchors, n_sim = 5L)
  expect_identical(calls, 10L)
  expect_identical(r$summary$coverage, c(0, 0))
  expect_identical(r$summary$MCSE, c(0, 0))
  expect_identical(r$summary$distance_mcse, c(-Inf, -Inf))
  expect_identical(r$summary$finding, c("undercoverage", "undercoverage"))
  expect_identical(r$summary$within_pass, c(FALSE, FALSE))
  expect_identical(nrow(r$replicates), 10L)
})

test_that("reporting overcoverage does not stop coverage table generation", {
  h <- m3a_coverage_helpers()
  anchors <- m3a_coverage_anchors()
  local_mocked_bindings(msa_bias = function(...) list(overall = c(lower = -1, upper = 1)), .package = "llmsa")
  r <- h$agreement_bias_coverage(anchors, n_sim = 2L)
  expect_identical(r$summary$coverage, c(1, 1))
  expect_identical(r$summary$distance_mcse, c(Inf, Inf))
  expect_identical(r$summary$finding, rep("overcoverage", 2))
  expect_identical(h$agreement_coverage_table(r)$finding, rep("overcoverage", 2))
})

test_that("coverage failures name their scenario and repetition and restore RNG", {
  h <- m3a_coverage_helpers()
  anchors <- m3a_coverage_anchors()
  calls <- 0L
  local_mocked_bindings(msa_bias = function(...) {
    calls <<- calls + 1L
    if (calls == 2L) stop("synthetic failure", call. = FALSE)
    list(overall = c(lower = -1, upper = 1))
  }, .package = "llmsa")
  m3a_restore_rng({
    set.seed(91)
    original <- .Random.seed
    original_kind <- RNGkind()
    expect_error(h$agreement_bias_coverage(anchors, n_sim = 5L),
                 "Bias coverage S-bias-1, repetition 2: synthetic failure", fixed = TRUE)
    expect_identical(calls, 2L)
    expect_identical(.Random.seed, original)
    expect_identical(RNGkind(), original_kind)
    calls <- 0L
    rm(".Random.seed", envir = globalenv())
    expect_error(h$agreement_bias_coverage(anchors, n_sim = 5L), "repetition 2", fixed = TRUE)
    expect_false(exists(".Random.seed", envir = globalenv(), inherits = FALSE))
  })
})

test_that("coverage rejects non-finite intervals and malformed calculation inputs", {
  h <- m3a_coverage_helpers()
  anchors <- m3a_coverage_anchors()
  local_mocked_bindings(msa_bias = function(...) list(overall = c(lower = -Inf, upper = 1)), .package = "llmsa")
  err <- tryCatch(h$agreement_bias_coverage(anchors, n_sim = 1), error = identity)
  expect_identical(conditionMessage(err), "Bias coverage S-bias-1, repetition 1: invalid or non-finite bias interval")
  expect_null(conditionCall(err))
  for (bad in list(numeric(), c(1, 2), NA_real_, Inf, 0, 1.5, "5")) {
    expect_error(h$agreement_bias_coverage(anchors, n_sim = bad),
                 "Bias coverage `n_sim` must be a positive whole number.", fixed = TRUE)
  }
  anchors[["ANK-TOL"]]$value$mc_factor$report <- NULL
  expect_error(h$agreement_bias_coverage(anchors, n_sim = 1),
               "Bias coverage requires valid ANK-06.n_sim_min and ANK-TOL.mc_factor anchors.", fixed = TRUE)
})

test_that("the vignette sources the installed helper and uses the full anchored size", {
  root <- Sys.getenv("REPO_ROOT", "")
  candidates <- c(if (nzchar(root)) file.path(root, "vignettes", "validation.Rmd"),
                  system.file("doc", "validation.Rmd", package = "llmsa"),
                  file.path("..", "..", "vignettes", "validation.Rmd"))
  path <- candidates[nzchar(candidates) & file.exists(candidates)][1]
  expect_true(!is.na(path), info = "the source vignette must exist in either package context")
  lines <- readLines(path, warn = FALSE)
  start <- match("## Bias interval: coverage by scenario", lines)
  end <- which(startsWith(lines, "## ") & seq_along(lines) > start)[1]
  expect_true(is.finite(start) && is.finite(end))
  section <- lines[seq(start, end - 1)]
  expect_match(paste(section, collapse = "\n"), 'agreement_validation$agreement_bias_coverage(latent_anchors)', fixed = TRUE)
  expect_false(any(grepl("n_sim[[:space:]]*=", section)))
  sources <- latent_test_documentation_sources(path)
  expect_true(normalizePath(system.file("validation", "agreement", "bias_coverage.R", package = "llmsa",
                                       mustWork = TRUE), mustWork = TRUE) %in% sources)
  expect_false(any(grepl("^[[:space:]]*(sim_|boot_)", readLines(system.file("validation", "agreement", "bias_coverage.R", package = "llmsa")))))
})
