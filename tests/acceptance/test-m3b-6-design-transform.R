# K-M3b-6: without n_runs pb_design() chooses the smallest size with
# N - 1 >= number of factors, randomises the run order reproducibly with seed
# and labels the levels with the given names; msa_robustness() logit-transforms
# responses in (0, 1) when transform = "logit" is set (new argument with
# default "none") and reports proportions of exactly 0 or 1 as an error before
# the transformation. Sizes come from ANK-80; the forms of the checks are ACC-11.

acc_m3b_6_factors <- function() {
  list(number_format = c("plain", "scientific"), units = c("nM", "ng/mL"),
       temperature = c(0, 0.7), typos = c("none", "two"),
       extra_context = c("none", "unrelated paragraph"), system_prompt = c("A", "B"))
}

acc_m3b_6_expected_size <- function(k) {
  sizes <- acc_m3b_sizes()
  sizes[which(sizes - 1L >= k)[1]]
}

# An error message names the offending proportions when it contains 0 and 1 as
# numbers of their own (ACC-11).
acc_m3b_6_names_0_and_1 <- function(msg) {
  grepl("(^|[^0-9.])0([^0-9.]|$)", msg) && grepl("(^|[^0-9.])1([^0-9.]|$)", msg)
}

test_that("K-M3b-6: without n_runs pb_design() chooses the smallest size of ANK-80 with N - 1 >= number of factors", {
  k_max <- max(acc_m3b_sizes()) - 1L
  for (k in seq_len(k_max)) {
    N <- acc_m3b_6_expected_size(k)
    d <- pb_design(k, randomize = FALSE)
    expect_identical(nrow(d), as.integer(N), label = sprintf("%d factors: runs", k))
    expect_identical(dim(acc_m3b_coded(d)), c(as.integer(N), k), label = sprintf("%d factors: coded matrix", k))
  }
  for (k in c(7L, 8L, 11L, 12L, 15L, 16L, 19L, 20L, 23L)) {
    f <- stats::setNames(replicate(k, c("low", "high"), simplify = FALSE), sprintf("factor_%02d", seq_len(k)))
    expect_identical(nrow(pb_design(f, randomize = FALSE)), as.integer(acc_m3b_6_expected_size(k)),
                     label = sprintf("named list of %d factors: runs", k))
  }
  # No size of ANK-80 holds more factors: a clear error, not a smaller design
  # (docs/01 §2 Nr. 4).
  expect_error(pb_design(k_max + 1L))
})

test_that("K-M3b-6: the coded columns for fewer factors are columns of the K-M3b-1 matrix of the chosen size", {
  for (k in c(5L, 9L, 13L, 17L, 21L)) {
    N <- acc_m3b_6_expected_size(k)
    full <- acc_m3b_coded(pb_design(N - 1L, n_runs = N, randomize = FALSE))
    X <- acc_m3b_coded(pb_design(k, randomize = FALSE))
    expect_true(all(apply(X, 2, paste, collapse = ",") %in% apply(full, 2, paste, collapse = ",")),
                label = sprintf("%d factors in %d runs", k, N))
  }
})

test_that("K-M3b-6: pb_design() randomises the run order reproducibly with seed", {
  f <- acc_m3b_6_factors()
  d1 <- acc_m3b_with_seed(1L, pb_design(f, seed = 11L))
  d2 <- acc_m3b_with_seed(2L, {
    stats::runif(3)
    pb_design(f, seed = 11L)
  })
  expect_identical(d1, d2)
  canonical <- acc_m3b_coded(pb_design(f, randomize = FALSE))
  expect_identical(acc_m3b_sorted_rows(acc_m3b_coded(d1)), acc_m3b_sorted_rows(canonical))
  orders <- vapply(1:10, function(s) paste(acc_m3b_rows(acc_m3b_coded(pb_design(f, seed = s))), collapse = "|"), "")
  expect_gt(length(unique(orders)), 1L)
  expect_false(all(orders == paste(acc_m3b_rows(canonical), collapse = "|")))
  for (o in orders) {
    expect_identical(sort(strsplit(o, "|", fixed = TRUE)[[1]], method = "radix"), acc_m3b_sorted_rows(canonical))
  }
})

test_that("K-M3b-6: pb_design() labels the levels with the given names", {
  f <- acc_m3b_6_factors()
  for (seed in c(5L, 6L)) {
    d <- pb_design(f, seed = seed)
    coded <- attr(d, "coded")
    expect_identical(colnames(coded), names(f))
    for (nm in names(f)) {
      x <- as.numeric(coded[, nm])
      expect_identical(as.numeric(d[[nm]]), x, label = sprintf("seed %d: coded column %s", seed, nm))
      lab <- d[[paste0(nm, "_level")]]
      expect_identical(as.character(lab), ifelse(x > 0, as.character(f[[nm]][2]), as.character(f[[nm]][1])),
                       label = sprintf("seed %d: level names of %s", seed, nm))
    }
  }
})

test_that("K-M3b-6: msa_robustness() has the new argument transform with default \"none\" behind the arguments of the snapshot (ANK-02)", {
  fm <- formals(msa_robustness)
  expect_true("transform" %in% names(fm))
  snapshot <- vapply(acc_anchor("ANK-02")$value$functions$msa_robustness, function(a) a$name, "")
  expect_gt(match("transform", names(fm)), max(match(snapshot, names(fm))))
  expect_identical(eval(fm$transform)[1], "none")
  d <- pb_design(7L, n_runs = 8L, seed = 2L)
  y <- acc_m3b_with_seed(2L, stats::rnorm(8L))
  expect_identical(msa_robustness(d, y), msa_robustness(d, y, transform = "none"))
})

test_that("K-M3b-6: with transform = \"logit\" msa_robustness() analyses the logits of responses in (0, 1)", {
  tol <- acc_m3b_arith()
  alpha <- as.numeric(acc_m3b_value("ANK-81", "method", "nominal_alpha"))
  for (seed in c(2L, 3L)) {
    d <- pb_design(7L, n_runs = 8L, seed = seed)
    X <- acc_m3b_coded(d)
    labels <- colnames(attr(d, "coded"))
    p <- acc_m3b_with_seed(seed, stats::runif(8L, 0.05, 0.95))
    r <- msa_robustness(d, p, alpha = alpha, transform = "logit")
    logit <- log(p / (1 - p))
    e <- acc_m3b_by_factor(r, labels, "effect")
    expect_lte(max(abs(e - acc_m3b_mean_differences(X, logit))), tol, label = sprintf("seed %d: effects on the logit scale", seed))
    ref <- acc_m3b_lenth_reference(acc_m3b_mean_differences(X, logit), alpha)
    for (k in c("pse", "me", "sme")) {
      expect_lte(abs(acc_m3b_attr(r, k) - ref[[k]]), tol, label = sprintf("seed %d: %s on the logit scale", seed, k))
    }
    untransformed <- msa_robustness(d, p, alpha = alpha)
    expect_false(isTRUE(all.equal(acc_m3b_by_factor(untransformed, labels, "effect"), e)),
                 label = sprintf("seed %d: the default analyses the untransformed proportions", seed))
  }
})

test_that("K-M3b-6: proportions of exactly 0 or 1 are an error before the logit transformation", {
  expect_true("transform" %in% names(formals(msa_robustness)))
  d <- pb_design(7L, n_runs = 8L, seed = 4L)
  p <- acc_m3b_with_seed(4L, stats::runif(8L, 0.05, 0.95))
  for (edge in c(0, 1)) {
    q <- p
    q[3] <- edge
    err <- tryCatch(msa_robustness(d, q, transform = "logit"), error = function(e) e)
    expect_s3_class(err, "error")
    if (inherits(err, "error")) {
      expect_true(acc_m3b_6_names_0_and_1(conditionMessage(err)),
                  label = sprintf("a proportion of exactly %g: the message names 0 and 1 (%s)", edge, conditionMessage(err)))
    }
    expect_no_error(msa_robustness(d, q))
  }
})

test_that("K-M3b-6: transform accepts only \"none\" and \"logit\"; any other value is an error (docs/01 §2 Nr. 4)", {
  expect_true("transform" %in% names(formals(msa_robustness)))
  d <- pb_design(7L, n_runs = 8L, seed = 4L)
  p <- acc_m3b_with_seed(4L, stats::runif(8L, 0.05, 0.95))
  expect_error(msa_robustness(d, p, transform = "probit"))
})
