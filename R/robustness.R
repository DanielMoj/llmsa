#' Plackett-Burman screening design for robustness testing
#'
#' Robustness in the ICH Q2(R2) sense asks whether small, deliberate
#' variations of the method leave the result unchanged. For an LLM
#' pipeline the natural perturbations are formatting and context
#' variations: number format, units, spelling errors, column order,
#' irrelevant extra context, a different system prompt, temperature, and
#' so on. A Plackett-Burman design screens up to `n_runs - 1` such factors
#' at two levels each in `n_runs` runs, with every pair of factors
#' balanced and orthogonal, so each main effect is estimated from all runs.
#'
#' @param factors A named list; each element is a length-two vector with the
#'   low (`-1`) and high (`+1`) level of one factor, for example
#'   `list(number_format = c("plain", "scientific"), typos = c("none", "two"))`.
#'   Alternatively a single integer giving the number of factors.
#' @param n_runs Number of runs: 8, 12, 16, 20 or 24. Default: the smallest
#'   design that accommodates the factors.
#' @param randomize Randomise the run order (recommended).
#' @param seed Optional seed.
#'
#' @return A data.frame of class `pb_design` with one row per run, a column
#'   `run`, one coded column per factor (`-1`/`+1`), and, when levels were
#'   given, one labelled column per factor (suffix `_level`). The design
#'   matrix is stored as attribute `coded`.
#' @references Plackett, R. L. and Burman, J. P. (1946). The design of
#'   optimum multifactorial experiments. *Biometrika* 33, 305-325.
#' @examples
#' f <- list(number_format = c("plain", "scientific"),
#'           units = c("nM", "ng/mL"), typos = c("none", "two"),
#'           extra_context = c("none", "unrelated paragraph"),
#'           system_prompt = c("A", "B"), temperature = c(0, 0.7))
#' d <- pb_design(f, seed = 1)
#' d
#' @export
pb_design <- function(factors, n_runs = NULL, randomize = TRUE, seed = NULL) {
  if (is.numeric(factors) && length(factors) == 1) {
    k <- as.integer(factors)
    factors <- stats::setNames(replicate(k, c(-1, 1), simplify = FALSE), paste0("F", seq_len(k)))
    labelled <- FALSE
  } else {
    if (!is.list(factors) || is.null(names(factors)) || any(names(factors) == ""))
      stop("`factors` must be a named list of two-level vectors.", call. = FALSE)
    if (any(lengths(factors) != 2)) stop("Every factor needs exactly two levels.", call. = FALSE)
    k <- length(factors)
    labelled <- TRUE
  }
  sizes <- c(8, 12, 16, 20, 24)
  if (is.null(n_runs)) n_runs <- sizes[which(sizes - 1 >= k)[1]]
  if (is.na(n_runs) || !n_runs %in% sizes) stop("`n_runs` must be one of 8, 12, 16, 20, 24.", call. = FALSE)
  if (k > n_runs - 1) stop(sprintf("%d factors need at least %d runs.", k, sizes[which(sizes - 1 >= k)[1]]), call. = FALSE)
  X <- pb_matrix(n_runs)[, seq_len(k), drop = FALSE]
  colnames(X) <- names(factors)
  ord <- seq_len(n_runs)
  if (randomize) {
    if (!is.null(seed)) {
      old <- .Random.seed_get(); on.exit(.Random.seed_set(old), add = TRUE); set.seed(seed)
    }
    ord <- sample.int(n_runs)
  }
  X <- X[ord, , drop = FALSE]
  out <- data.frame(run = seq_len(n_runs), X, check.names = FALSE)
  if (labelled) {
    for (nm in names(factors)) {
      out[[paste0(nm, "_level")]] <- ifelse(X[, nm] > 0, as.character(factors[[nm]][2]),
                                            as.character(factors[[nm]][1]))
    }
  }
  structure(out, class = c("pb_design", "data.frame"), coded = X, factors = factors,
            n_runs = n_runs)
}

# Plackett-Burman matrices from the published generator rows: cyclic shifts
# plus a final row of -1.
pb_matrix <- function(n) {
  gen <- switch(as.character(n),
    "8"  = "+++-+--",
    "12" = "++-+++---+-",
    "16" = "++++-+-++--+---",
    "20" = "++--++++-+-+----++-",
    "24" = "+++++-+-++--++--+-+----",
    stop("unsupported size"))
  g <- ifelse(strsplit(gen, "")[[1]] == "+", 1, -1)
  m <- n - 1
  X <- matrix(NA_real_, n, m)
  for (i in seq_len(m)) X[i, ] <- g[((seq_len(m) - i) %% m) + 1]
  X[n, ] <- -1
  X
}

#' @export
print.pb_design <- function(x, ...) {
  cat(sprintf("Plackett-Burman design: %d runs, %d factors (%d-run design screens up to %d)\n",
              nrow(x), ncol(attr(x, "coded")), attr(x, "n_runs"), attr(x, "n_runs") - 1))
  print(as.data.frame(x), row.names = FALSE)
  invisible(x)
}

#' Analyse a robustness screening experiment
#'
#' Estimates the main effect of every factor in a Plackett-Burman (or any
#' two-level orthogonal) design on a response such as accuracy, agreement
#' with the reference, or the mean parsed value, and judges which effects
#' are active with Lenth's pseudo standard error, which needs no replicate
#' runs. Effects beyond the margin of error (ME) are flagged as active at
#' the 5 % level per effect; the simultaneous margin (SME) controls the
#' family-wise error.
#'
#' @param design A `pb_design` (or a data.frame with coded `-1`/`+1`
#'   columns named in `factors`).
#' @param response Numeric response, one value per run, in the row order of
#'   `design`.
#' @param factors Factor columns to analyse; default: all coded columns.
#' @param alpha Significance level for ME and SME.
#'
#' @return An object of class `msa_robustness`: a data.frame of effects
#'   (`effect` = mean at high level minus mean at low level, `t_lenth` =
#'   effect / PSE, `active` flag) with attributes `pse`, `me`, `sme`,
#'   plus the response summary.
#' @references Lenth, R. V. (1989). Quick and easy analysis of unreplicated
#'   factorials. *Technometrics* 31, 469-473.
#' @examples
#' d <- pb_design(list(format = c("plain", "sci"), units = c("nM", "ng/mL"),
#'                     typos = c(0, 2), context = c("none", "extra"),
#'                     system = c("A", "B"), temp = c(0, 0.7)), seed = 1)
#' set.seed(7)
#' acc <- 0.9 - 0.08 * (d$typos > 0) - 0.05 * (d$temp > 0) + rnorm(nrow(d), 0, 0.01)
#' msa_robustness(d, acc)
#' @export
msa_robustness <- function(design, response, factors = NULL, alpha = 0.05) {
  X <- attr(design, "coded")
  if (is.null(X)) {
    if (is.null(factors)) stop("Give `factors` (the coded columns) for a plain data.frame design.", call. = FALSE)
    X <- as.matrix(design[, factors, drop = FALSE])
  } else if (!is.null(factors)) X <- X[, factors, drop = FALSE]
  if (length(response) != nrow(X)) stop("`response` needs one value per run.", call. = FALSE)
  if (anyNA(response)) stop("`response` must not contain NA.", call. = FALSE)
  effects <- apply(X, 2, function(x) mean(response[x > 0]) - mean(response[x < 0]))
  m <- length(effects)
  s0 <- 1.5 * stats::median(abs(effects))
  keep <- abs(effects) < 2.5 * s0
  pse <- if (any(keep)) 1.5 * stats::median(abs(effects[keep])) else s0
  df <- m / 3
  me <- stats::qt(1 - alpha / 2, df) * pse
  gamma <- (1 + (1 - alpha)^(1 / m)) / 2
  sme <- stats::qt(gamma, df) * pse
  out <- data.frame(factor = names(effects), effect = unname(effects),
                    t_lenth = if (pse > 0) unname(effects) / pse else NA_real_,
                    active = abs(unname(effects)) > me,
                    active_simultaneous = abs(unname(effects)) > sme,
                    stringsAsFactors = FALSE)
  out <- out[order(-abs(out$effect)), ]
  rownames(out) <- NULL
  structure(out, class = c("msa_robustness", "data.frame"), pse = pse, me = me, sme = sme,
            alpha = alpha, response_mean = mean(response), response_sd = stats::sd(response),
            n_runs = nrow(X))
}

#' @export
print.msa_robustness <- function(x, ...) {
  cat(sprintf("Robustness screening: %d runs, %d factors; response mean %.4f (sd %.4f)\n",
              attr(x, "n_runs"), nrow(x), attr(x, "response_mean"), attr(x, "response_sd")))
  cat(sprintf("  Lenth PSE %.4f, ME %.4f, SME %.4f (alpha = %g)\n",
              attr(x, "pse"), attr(x, "me"), attr(x, "sme"), attr(x, "alpha")))
  d <- as.data.frame(x)
  d$effect <- fmt_num(d$effect); d$t_lenth <- fmt_num(d$t_lenth, 2)
  print(d, row.names = FALSE)
  if (any(x$active)) cat("  active factors (|effect| > ME): ", paste(x$factor[x$active], collapse = ", "), "\n", sep = "")
  else cat("  no active factor: the pipeline is robust to all screened perturbations at this level\n")
  invisible(x)
}

#' @export
plot.msa_robustness <- function(x, ...) {
  a <- sort(abs(x$effect))
  m <- length(a)
  q <- stats::qnorm(0.5 + (seq_len(m) - 0.5) / (2 * m))
  graphics::plot(q, a, xlab = "half-normal quantile", ylab = "|effect|",
                 main = "Half-normal plot of robustness effects", pch = 19, ...)
  graphics::abline(h = attr(x, "me"), lty = 2)
  graphics::abline(h = attr(x, "sme"), lty = 3)
  lab <- x$factor[order(abs(x$effect))]
  graphics::text(q, a, lab, pos = 2, cex = 0.8)
  invisible(x)
}
