# K-M3b-4: the half-normal plot of plot.msa_robustness uses the positions
# q_(i) = Phi^-1(1/2 + (i - 1/2)/(2m)) after Daniel (1959) (ankerRef: ANK-82),
# names the convention in the axis label or legend, and the positions agree for
# m = 31 with the example of the source. The plot is recorded on a null PDF
# device and read from the display list (setup-m3b.R); the ordered |effects|
# are plotted against the positions (Formelsammlung §7: "Die nach Größe
# geordneten |Ê|_(i) gegen die Quantile"), the positions on the x axis (ACC-8).

acc_m3b_4_cases <- function() {
  d <- pb_design(11L, n_runs = 12L, seed = 3L)
  y <- acc_m3b_with_seed(3L, as.numeric(acc_m3b_coded(d) %*% seq(-1, 1, length.out = 11) + stats::rnorm(12L, 0, 0.05)))
  list(
    "pb_design(11)" = msa_robustness(d, y),
    "m = 31" = acc_m3b_robustness_m(31L),
    "m = 26" = acc_m3b_robustness_m(26L),
    "m = 7" = acc_m3b_robustness_m(7L)
  )
}

# Positions and |effects| of the point set for all m effects, ordered by position.
acc_m3b_4_points <- function(r) {
  m <- nrow(as.data.frame(r))
  pts <- acc_m3b_effect_points(acc_m3b_plot_record(r), m)
  if (!length(pts)) stop("acceptance: plot() of the msa_robustness object draws no point set with ", m, " points", call. = FALSE)
  lapply(pts, function(p) {
    o <- order(p$x)
    list(x = p$x[o], y = p$y[o])
  })
}

test_that("K-M3b-4: plot.msa_robustness() places the ordered |effects| at q_(i) = qnorm(1/2 + (i - 1/2)/(2m)) (Daniel 1959, ankerRef: ANK-82)", {
  tol <- acc_m3b_arith()
  cases <- acc_m3b_4_cases()
  for (nm in names(cases)) {
    r <- cases[[nm]]
    m <- nrow(as.data.frame(r))
    for (p in acc_m3b_4_points(r)) {
      expect_lte(max(abs(p$x - acc_m3b_halfnormal_q(m))), tol, label = sprintf("%s: positions against the formula", nm))
      expect_lte(max(abs(p$y - sort(abs(r$effect)))), tol, label = sprintf("%s: ordered |effects| at the positions", nm))
    }
  }
})

test_that("K-M3b-4: for m = 31 the positions agree with the example of Daniel (1959): 22nd contrast at P' = 0.693, nearest to 0.683, topmost at 0.984; topmost of the revised 26 at 0.981 (ankerRef: ANK-82)", {
  ex <- acc_m3b_value("ANK-82", "example")
  tol <- acc_anchor("ANK-82")$tolerance
  if (!is.numeric(tol$p_prime) || !is.numeric(tol$p_prime_22)) {
    stop("acceptance: ANK-82 lacks the tolerances p_prime and p_prime_22", call. = FALSE)
  }
  arith <- acc_m3b_arith()
  expect_identical(as.integer(ex$n), 31L)
  p31 <- acc_m3b_4_points(acc_m3b_robustness_m(as.integer(ex$n)))
  for (p in p31) {
    prime <- 2 * stats::pnorm(p$x) - 1
    expect_lte(abs(prime[ex$i] - ex$p_prime), tol$p_prime_22 + arith,
               label = sprintf("P' of contrast %d of %d: %.6f, printed %s", ex$i, ex$n, prime[ex$i], format(ex$p_prime)))
    expect_identical(which.min(abs(prime - ex$p_prime_nearest_target)), as.integer(ex$i))
    expect_lte(abs(prime[ex$topmost_i] - ex$topmost_p_prime), tol$p_prime + arith,
               label = sprintf("P' of the largest of %d: %.6f, printed %s", ex$n, prime[ex$topmost_i], format(ex$topmost_p_prime)))
  }
  p26 <- acc_m3b_4_points(acc_m3b_robustness_m(as.integer(ex$revised_n)))
  for (p in p26) {
    prime <- 2 * stats::pnorm(p$x) - 1
    top <- as.integer(ex$revised_n)
    expect_lte(abs(prime[top] - ex$revised_topmost_p_prime), tol$p_prime + arith,
               label = sprintf("P' of the largest of %d: %.6f, printed %s", top, prime[top], format(ex$revised_topmost_p_prime)))
  }
})

test_that("K-M3b-4: an axis label or the legend of the half-normal plot names the convention of Daniel (1959)", {
  cases <- acc_m3b_4_cases()
  for (nm in c("pb_design(11)", "m = 31")) {
    rec <- acc_m3b_plot_record(cases[[nm]])
    texts <- c(rec$xlab, rec$ylab, rec$mtext, rec$text)
    named <- grepl("Daniel", texts, fixed = TRUE) & grepl("1959", texts, fixed = TRUE)
    expect_true(any(named),
                label = sprintf("%s: one axis label, margin text or legend entry names Daniel (1959); drawn: %s",
                                nm, paste(shQuote(unique(c(rec$xlab, rec$ylab, rec$mtext))), collapse = ", ")))
  }
})
