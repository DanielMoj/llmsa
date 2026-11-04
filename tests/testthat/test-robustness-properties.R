# Small synthetic designs and responses, with no protected data or simulation.
robust_property_case <- function() {
  d <- pb_design(11, randomize = FALSE)
  X <- attr(d, "coded")
  effects <- c(2, -0.625, 0.125, -0.0625, 0.03125, -0.15625,
               0.1875, -0.21875, 0.09375, -0.25, 0.015625)
  y <- as.numeric(3 + X %*% effects / 2)
  list(d = d, X = X, y = y, effects = effects, result = msa_robustness(d, y))
}

robust_property_error <- function(expr, message) {
  err <- tryCatch(expr, error = identity)
  expect_s3_class(err, "error")
  if (inherits(err, "error")) {
    expect_identical(conditionMessage(err), message)
    expect_null(conditionCall(err))
  }
}

robust_property_rng <- function(expr) {
  kind <- RNGkind()
  had <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (had) old <- get(".Random.seed", envir = globalenv())
  on.exit({
    RNGkind(kind[1L], kind[2L], kind[3L])
    if (had) assign(".Random.seed", old, envir = globalenv()) else
      if (exists(".Random.seed", envir = globalenv(), inherits = FALSE))
        rm(".Random.seed", envir = globalenv())
  }, add = TRUE)
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  force(expr)
}

test_that("PB designs preserve coded matrices, factor metadata and literal level names", {
  d <- pb_design(9, randomize = FALSE)
  expected_names <- paste0("F", seq_len(9))
  expect_identical(class(d), c("pb_design", "data.frame"))
  expect_identical(names(d), c("run", expected_names))
  expect_identical(d$run, seq_len(nrow(d)))
  expect_identical(attr(d, "factors"),
                   stats::setNames(rep(list(c(-1, 1)), 9), expected_names))
  coded_columns <- as.matrix(d[, expected_names])
  rownames(coded_columns) <- NULL  # data.frame row names are not matrix metadata.
  expect_identical(coded_columns, attr(d, "coded"))

  levels <- list("extra context" = c("absent", "present"))
  for (randomize in c(FALSE, TRUE)) {
    one <- pb_design(levels, randomize = randomize, seed = 20261105L)
    X <- attr(one, "coded")
    expect_identical(dim(X), c(8L, 1L))
    expect_identical(colnames(X), names(levels))
    expect_identical(names(one), c("run", "extra context", "extra context_level"))
    expect_identical(attr(one, "factors"), levels)
    expect_identical(one[["extra context"]], X[, 1L])
    expect_identical(one[["extra context_level"]][X[, 1L] == -1], rep("absent", 4))
    expect_identical(one[["extra context_level"]][X[, 1L] == 1], rep("present", 4))
  }
})

test_that("PB input errors name the invalid field and required run count", {
  for (factors in list("factor", c(1, 2), list(c("low", "high")),
                       stats::setNames(list(c(0, 1), c(0, 1)), c("a", "")))) {
    robust_property_error(pb_design(factors),
                           "`factors` must be a named list of two-level vectors.")
  }
  for (levels in list(1, 1:3, numeric())) {
    robust_property_error(pb_design(list(a = levels)),
                           "Every factor needs exactly two levels.")
  }
  for (n_runs in c(10, NA_real_)) {
    robust_property_error(pb_design(3, n_runs = n_runs),
                           "`n_runs` must be one of 8, 12, 16, 20, 24.")
  }
  robust_property_error(pb_design(8, n_runs = 8), "8 factors need at least 12 runs.")
  robust_property_error(pb_design(11, n_runs = 8), "11 factors need at least 12 runs.")
  expect_error(llmsa:::pb_matrix(10), "unsupported size", fixed = TRUE)
})

test_that("a PB seed restores both existing and absent caller RNG states", {
  robust_property_rng({
    set.seed(20261106L)
    before <- get(".Random.seed", envir = globalenv())
    first <- pb_design(9, seed = 20261105L)
    expect_identical(get(".Random.seed", envir = globalenv()), before)
    stats::runif(5)
    next_state <- get(".Random.seed", envir = globalenv())
    expect_identical(pb_design(9, seed = 20261105L), first)
    expect_identical(get(".Random.seed", envir = globalenv()), next_state)

    rm(".Random.seed", envir = globalenv())
    expect_identical(pb_design(9, seed = 20261105L), first)
    expect_false(exists(".Random.seed", envir = globalenv(), inherits = FALSE))
    pb_design(9, randomize = FALSE, seed = 20261105L)
    expect_false(exists(".Random.seed", envir = globalenv(), inherits = FALSE))
  })
})

test_that("unseeded randomisation follows the caller stream and disabling it consumes none", {
  robust_property_rng({
    canonical <- pb_design(9, randomize = FALSE)
    set.seed(20261107L)
    permutation <- sample.int(nrow(canonical))
    after_sample <- get(".Random.seed", envir = globalenv())
    set.seed(20261107L)
    d <- pb_design(9)
    expect_identical(get(".Random.seed", envir = globalenv()), after_sample)
    expect_identical(attr(d, "coded"), attr(canonical, "coded")[permutation, , drop = FALSE])
    expect_identical(d$run, seq_len(nrow(d)))
    expect_identical(pb_design(9, randomize = FALSE, seed = 20261108L), canonical)
    expect_identical(get(".Random.seed", envir = globalenv()), after_sample)
  })
})

test_that("row order, factor names and column order preserve matched screening results", {
  tol <- numeric_tolerance("arithmetic", "abs_tol")
  cs <- robust_property_case()
  rows <- c(7L, 1L, 12L, 3L, 9L, 2L, 11L, 4L, 10L, 6L, 8L, 5L)
  columns <- rev(seq_len(ncol(cs$X)))
  renamed <- paste("screen", columns)
  design <- as.data.frame(cs$X[rows, columns], check.names = FALSE)
  names(design) <- renamed
  r <- msa_robustness(design, cs$y[rows], factors = renamed)
  old <- cs$result[match(colnames(cs$X)[columns], cs$result$factor), ]
  new <- r[match(renamed, r$factor), ]
  for (field in c("effect", "t_lenth")) expect_lte(max(abs(new[[field]] - old[[field]])), tol)
  expect_identical(new$active, old$active)
  expect_identical(new$active_simultaneous, old$active_simultaneous)
  for (field in c("pse", "me", "sme", "response_mean", "response_sd"))
    expect_lte(abs(attr(r, field) - attr(cs$result, field)), tol)
})

test_that("reversing a coded factor changes only its effect sign", {
  tol <- numeric_tolerance("arithmetic", "abs_tol")
  cs <- robust_property_case()
  signs <- c(-1, rep(1, ncol(cs$X) - 1L))
  design <- as.data.frame(sweep(cs$X, 2, signs, `*`))
  r <- msa_robustness(design, cs$y, factors = names(design))
  i <- match(cs$result$factor, r$factor)
  expected_sign <- signs[match(cs$result$factor, colnames(cs$X))]
  expect_lte(max(abs(r$effect[i] - cs$result$effect * expected_sign)), tol)
  expect_lte(max(abs(r$t_lenth[i] - cs$result$t_lenth * expected_sign)), tol)
  expect_identical(r$active[i], cs$result$active)
  expect_identical(r$active_simultaneous[i], cs$result$active_simultaneous)
  for (field in c("pse", "me", "sme")) expect_identical(attr(r, field), attr(cs$result, field))
})

test_that("response shifts and signed rescaling preserve screening decisions", {
  tol <- numeric_tolerance("arithmetic", "abs_tol")
  cs <- robust_property_case()
  expect_true(any(cs$result$active & !cs$result$active_simultaneous))
  expect_true(any(cs$result$active_simultaneous))
  for (scale in c(1, 3, -2)) {
    r <- msa_robustness(cs$d, 100 + scale * cs$y)
    i <- match(cs$result$factor, r$factor)
    expect_lte(max(abs(r$effect[i] - scale * cs$result$effect)), tol)
    expect_lte(max(abs(r$t_lenth[i] - sign(scale) * cs$result$t_lenth)), tol)
    expect_identical(r$active[i], cs$result$active)
    expect_identical(r$active_simultaneous[i], cs$result$active_simultaneous)
    for (field in c("pse", "me", "sme", "response_sd"))
      expect_lte(abs(attr(r, field) - abs(scale) * attr(cs$result, field)), tol)
    expect_lte(abs(attr(r, "response_mean") - (100 + scale * mean(cs$y))), tol)
  }
})

test_that("complementary probabilities and shifted log odds obey their transformations", {
  tol <- numeric_tolerance("arithmetic", "abs_tol")
  cs <- robust_property_case()
  p <- stats::plogis(cs$y)
  base <- msa_robustness(cs$d, p, transform = "logit")
  cases <- list(complement = list(p = 1 - p, sign = -1, shift = 0),
                shifted = list(p = stats::plogis(stats::qlogis(p) + 0.75), sign = 1, shift = 0.75))
  for (case in cases) {
    r <- msa_robustness(cs$d, case$p, transform = "logit")
    i <- match(base$factor, r$factor)
    expect_lte(max(abs(r$effect[i] - case$sign * base$effect)), tol)
    expect_lte(max(abs(r$t_lenth[i] - case$sign * base$t_lenth)), tol)
    expect_identical(r$active[i], base$active)
    expect_identical(r$active_simultaneous[i], base$active_simultaneous)
    for (field in c("pse", "me", "sme", "response_sd"))
      expect_lte(abs(attr(r, field) - attr(base, field)), tol)
    expect_lte(abs(attr(r, "response_mean") -
                     (case$sign * attr(base, "response_mean") + case$shift)), tol)
  }
})

test_that("Lenth statistics cover small positive PSE and constant responses", {
  tol <- numeric_tolerance("arithmetic", "abs_tol")
  cs <- robust_property_case()
  r <- cs$result
  expect_gt(attr(r, "pse"), 0)
  expect_lt(attr(r, "pse"), 1)
  expect_lte(max(abs(r$t_lenth - r$effect / attr(r, "pse"))), tol)
  expect_identical(abs(r$effect), sort(abs(r$effect), decreasing = TRUE))
  for (transform in c("none", "logit")) {
    zero <- msa_robustness(cs$d, rep(0.5, nrow(cs$d)), transform = transform)
    expect_identical(zero$effect, rep(0, nrow(zero)))
    for (field in c("pse", "me", "sme")) expect_identical(attr(zero, field), 0)
    expect_identical(zero$t_lenth, rep(NA_real_, nrow(zero)))
    expect_identical(zero$active, rep(FALSE, nrow(zero)))
    expect_identical(zero$active_simultaneous, rep(FALSE, nrow(zero)))
  }
  for (design in list(cs$d, as.data.frame(cs$X))) {
    one <- msa_robustness(design, cs$y, factors = "F3")
    expect_identical(one$factor, "F3")
    expect_lte(abs(one$effect - cs$effects[3L]), tol)
  }
})

test_that("PB printing describes run capacity, omits row names and returns invisibly", {
  d <- pb_design(9, randomize = FALSE)
  printed <- NULL
  lines <- utils::capture.output(printed <- withVisible(print(d)))
  expected <- c("Plackett-Burman design: 12 runs, 9 factors (12-run design screens up to 11)",
                utils::capture.output(print(as.data.frame(d), row.names = FALSE)))
  expect_identical(lines, expected)
  expect_identical(printed$value, d)
  expect_false(printed$visible)
})

test_that("robustness printing reports margins, rounded statistics and both activity meanings", {
  cs <- robust_property_case()
  small <- as.numeric(3 + cs$X %*% (seq_len(ncol(cs$X)) / 128))
  none <- msa_robustness(cs$d, small)
  expect_false(any(none$active))
  expect_gt(attr(none, "pse"), 0)
  expect_setequal(cs$result$factor[cs$result$active], c("F1", "F2"))
  expect_setequal(cs$result$factor[cs$result$active_simultaneous], "F1")
  constant <- msa_robustness(cs$d, rep(0.5, nrow(cs$d)))
  for (x in list(cs$result, none, constant)) {
    expected_table <- as.data.frame(x)
    expected_table$effect <- sprintf("%.4f", x$effect)
    expected_table$t_lenth <- ifelse(is.na(x$t_lenth), "NA", sprintf("%.2f", x$t_lenth))
    header <- sprintf("Robustness screening: %d runs, %d factors; response mean %.4f (sd %.4f)",
                      attr(x, "n_runs"), nrow(x), attr(x, "response_mean"), attr(x, "response_sd"))
    margins <- sprintf("  Lenth PSE %.4f, ME %.4f, SME %.4f (alpha = %g)",
                       attr(x, "pse"), attr(x, "me"), attr(x, "sme"), attr(x, "alpha"))
    conclusion <- if (any(x$active)) {
      "  active factors (|effect| > ME): F1 (also above SME), F2 (above ME only)"
    } else {
      paste0("  No factor exceeded the margin of error (ME = ",
             formatC(attr(x, "me"), format = "f", digits = 4),
             "). Smaller effects cannot be told apart from noise with this design, ",
             "so this result does not show that the pipeline is robust.")
    }
    expected <- c(header, margins,
                  utils::capture.output(print(expected_table, row.names = FALSE)), conclusion)
    printed <- NULL
    lines <- utils::capture.output(printed <- withVisible(print(x)))
    expect_identical(lines, expected)
    expect_identical(printed$value, x)
    expect_false(printed$visible)
  }
})

# Observe the drawn geometry on a null device; do not mock the graphics calls.
robust_property_plot <- function(x, ...) {
  grDevices::pdf(NULL)
  device <- grDevices::dev.cur()
  on.exit(grDevices::dev.off(device), add = TRUE)
  grDevices::dev.control("enable")
  result <- withVisible(plot(x, ...))
  calls <- list()
  for (entry in grDevices::recordPlot()[[1L]]) {
    args <- as.list(entry[[2L]])
    fn <- args[[1L]]
    if (is.list(fn) && !is.null(fn$name))
      calls <- c(calls, stats::setNames(list(args[-1L]), fn$name))
  }
  list(calls = calls, result = result)
}

test_that("the half-normal plot draws factor labels and distinct ME and SME lines", {
  tol <- numeric_tolerance("arithmetic", "abs_tol")
  x <- robust_property_case()$result
  recorded <- robust_property_plot(x, col = "navy")
  calls <- recorded$calls
  points <- calls[names(calls) == "C_plotXY"]
  titles <- calls[names(calls) == "C_title"]
  margins <- calls[names(calls) == "C_abline"]
  labels <- calls[names(calls) == "C_text"]
  expect_length(points, 1L)
  expect_length(titles, 1L)
  expect_length(margins, 2L)
  expect_length(labels, 1L)
  n <- nrow(x)
  positions <- stats::qnorm((1 + (seq_len(n) - 1 / 2) / n) / 2)
  ordered <- order(abs(x$effect))
  expect_lte(max(abs(points[[1L]][[1L]]$x - positions)), tol)
  expect_identical(points[[1L]][[1L]]$y, abs(x$effect[ordered]))
  expect_identical(points[[1L]][[2L]], "p")
  expect_identical(points[[1L]][[3L]], 19)
  expect_identical(points[[1L]][[5L]], "navy")
  expect_identical(titles[[1L]][[1L]], "Half-normal plot of robustness effects")
  expect_identical(titles[[1L]][[3L]], "Half-normal quantile (Daniel, 1959)")
  expect_identical(titles[[1L]][[4L]], "|effect|")
  expect_identical(margins[[1L]][[3L]], attr(x, "me"))
  expect_identical(margins[[1L]][[7L]], 2)
  expect_identical(margins[[2L]][[3L]], attr(x, "sme"))
  expect_identical(margins[[2L]][[7L]], 3)
  expect_lte(max(abs(labels[[1L]][[1L]]$x - positions)), tol)
  expect_identical(labels[[1L]][[1L]]$y, abs(x$effect[ordered]))
  expect_identical(labels[[1L]][[2L]], x$factor[ordered])
  expect_identical(labels[[1L]][[4L]], 2)
  expect_identical(labels[[1L]][[7L]], 0.8)
  expect_identical(recorded$result$value, x)
  expect_false(recorded$result$visible)
})
