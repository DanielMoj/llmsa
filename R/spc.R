#' Control chart with Westgard rules for ongoing system suitability
#'
#' A validation is a snapshot; providers change models silently, prompts
#' are edited and endpoints drift. Clinical laboratories handle the same
#' problem with control samples run alongside every batch and judged with
#' Westgard multi-rules. The same applies here: keep a small control set
#' with known answers, run it before every productive batch, and chart the
#' control statistic (for example the percent correct, or the mean parsed
#' value) over time.
#'
#' Implemented rules on the z-scores `(x - center) / sd`:
#' `1_2s` (warning, one value beyond 2 sd), `1_3s` (one value beyond 3 sd),
#' `2_2s` (two consecutive values beyond 2 sd on the same side),
#' `R_4s` (two consecutive values, interpreted according to `r4s`),
#' `4_1s` (four consecutive values beyond 1 sd on the same side),
#' `10_x` (ten consecutive values on the same side of the center).
#' All limits are strict, and a rule cannot fire before its window is full.
#' The baseline standard deviation uses the sample divisor (n - 1).
#'
#' The default R_4s reading uses the range of each consecutive pair. The
#' Westgard reading requires one standardized value above 2 and the other
#' below -2, in either order. Westgard's original multirule procedure uses
#' N = 2 to 4 controls within a run; R_4s is not intended for use across runs
#' (Westgard et al., 1981, pp. 498, 500). This interface has no run identifiers:
#' callers must ensure that compared neighbors belong to the same control run.
#'
#' @param x Numeric control statistic in time order.
#' @param center,sd Target center and standard deviation, typically from
#'   the validation study (e.g. the mean and sd of the control statistic
#'   across its replicates). If `NULL`, estimated from the first
#'   `n_baseline` values.
#' @param n_baseline Number of initial values used to estimate `center` and
#'   `sd` when they are not given.
#' @param rules Rules to evaluate.
#' @param r4s Reading of R_4s: `"range"` (absolute difference greater than
#'   4 sd) or `"westgard"` (one value above 2 sd and the other below -2 sd).
#' @return A data.frame of class `msa_control_chart` with `x`, `z`, a
#'   logical column per rule and `reject` (any rejection rule fired;
#'   `1_2s` is a warning only). The `r4s` attribute records the selected
#'   reading, which is also named by `print()` and [msa_report()].
#' @examples
#' set.seed(3)
#' acc <- c(rnorm(15, 0.92, 0.02), rnorm(6, 0.84, 0.02))  # drift after a silent model update
#' cc <- msa_control_chart(acc, center = 0.92, sd = 0.02)
#' cc[cc$reject, ]
#' plot(cc)
#' @export
msa_control_chart <- function(x, center = NULL, sd = NULL, n_baseline = 10,
                              rules = c("1_2s", "1_3s", "2_2s", "R_4s", "4_1s", "10_x"),
                              r4s = c("range", "westgard")) {
  r4s <- match.arg(r4s)
  x <- as.numeric(x)
  if (is.null(center) || is.null(sd)) {
    base <- x[seq_len(min(n_baseline, length(x)))]
    if (is.null(center)) center <- mean(base, na.rm = TRUE)
    if (is.null(sd)) sd <- stats::sd(base, na.rm = TRUE)
  }
  if (!is.finite(sd) || sd <= 0) stop("`sd` must be a positive number.", call. = FALSE)
  z <- (x - center) / sd
  n <- length(z)
  lagz <- function(k) c(rep(NA, k), z[seq_len(n - k)])
  same_side_run <- function(k, thr) {
    # TRUE at position i if the last k values (incl. i) are all > thr or all < -thr
    out <- logical(n)
    for (i in seq_len(n)) {
      if (i < k) next
      w <- z[(i - k + 1):i]
      out[i] <- all(w > thr) || all(w < -thr)
    }
    out
  }
  res <- data.frame(index = seq_len(n), x = x, z = z)
  # Rule limits and windows: reference/anchors/ANK-86.json (Formelsammlung 8).
  if ("1_2s" %in% rules) res$`1_2s` <- abs(z) > 2
  if ("1_3s" %in% rules) res$`1_3s` <- abs(z) > 3
  if ("2_2s" %in% rules) res$`2_2s` <- same_side_run(2, 2)
  if ("R_4s" %in% rules) {
    previous <- lagz(1)
    res$`R_4s` <- if (r4s == "range") abs(z - previous) > 4 & !is.na(previous) else
      ((z > 2 & previous < -2) | (z < -2 & previous > 2)) & !is.na(previous)
  }
  if ("4_1s" %in% rules) res$`4_1s` <- same_side_run(4, 1)
  if ("10_x" %in% rules) res$`10_x` <- same_side_run(10, 0)
  reject_rules <- setdiff(intersect(rules, names(res)), "1_2s")
  res$reject <- if (length(reject_rules)) Reduce(`|`, lapply(reject_rules, function(r) res[[r]] %in% TRUE)) else FALSE
  structure(res, class = c("msa_control_chart", "data.frame"), center = center, sd = sd, rules = rules, r4s = r4s)
}

msa_control_chart_reading <- function(x) {
  reading <- attr(x, "r4s", exact = TRUE)
  # Cards saved before the reading was selectable used the range definition.
  if (is.null(reading)) return("range")
  if (!is.character(reading) || length(reading) != 1L || is.na(reading) ||
      !reading %in% c("range", "westgard")) {
    stop("The control chart `r4s` attribute must be 'range' or 'westgard'.", call. = FALSE)
  }
  reading
}

#' @export
print.msa_control_chart <- function(x, ...) {
  reading <- msa_control_chart_reading(x)
  cat(sprintf("Control chart: %d points, center %.4f, sd %.4f; %d rejection(s)\n",
              nrow(x), attr(x, "center"), attr(x, "sd"), sum(x$reject)))
  cat("  R_4s reading: ", reading, "\n", sep = "")
  fired <- vapply(setdiff(attr(x, "rules"), "1_2s"), function(r) sum(x[[r]] %in% TRUE), numeric(1))
  if (any(fired > 0)) cat("  rules fired:", paste(sprintf("%s (%d)", names(fired)[fired > 0], fired[fired > 0]), collapse = ", "), "\n")
  warned <- if ("1_2s" %in% names(x)) x$`1_2s` %in% TRUE else FALSE
  print(as.data.frame(x)[x$reject | warned, ], row.names = FALSE)
  invisible(x)
}

#' @export
plot.msa_control_chart <- function(x, ...) {
  ctr <- attr(x, "center"); s <- attr(x, "sd")
  graphics::plot(x$index, x$x, type = "b", pch = ifelse(x$reject, 19, 1),
                 col = ifelse(x$reject, "red", "black"), xlab = "control run",
                 ylab = "control statistic", main = "System suitability control chart",
                 ylim = range(c(x$x, ctr + 3.2 * s, ctr - 3.2 * s), na.rm = TRUE), ...)
  graphics::abline(h = ctr, lty = 1)
  graphics::abline(h = ctr + c(-1, 1) * s, lty = 3, col = "grey60")
  graphics::abline(h = ctr + c(-2, 2) * s, lty = 2, col = "orange")
  graphics::abline(h = ctr + c(-3, 3) * s, lty = 2, col = "red")
  invisible(x)
}
