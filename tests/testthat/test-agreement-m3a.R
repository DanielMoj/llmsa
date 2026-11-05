# Small synthetic studies; no protected observations or frozen oracle outputs.
m3a_attribute_runs <- function(value, item = rep(c("i1", "i2", "i3"), each = 2L)) {
  data.frame(item_id = item, prompt_id = "p", model_id = "m",
             rep = seq_along(value), value = value, stringsAsFactors = FALSE)
}

test_that("reference conflicts are rejected in every input form and row order", {
  d <- m3a_attribute_runs(c("a", "a", "b", "b", "a", "b"))
  d$reference <- c("a", "b", "b", "b", "a", "a")
  for (idx in list(seq_len(nrow(d)), rev(seq_len(nrow(d))))) {
    s <- d[idx, ]
    for (ref in list("reference", s[c("item_id", "reference")],
                     stats::setNames(s$reference, s$item_id))) {
      err <- tryCatch(msa_agreement(s, levels = c("a", "b"), reference = ref), error = identity)
      expect_s3_class(err, "error")
      expect_identical(conditionMessage(err), 'Conflicting reference values for item_id "i1": "a", "b".')
      expect_null(conditionCall(err))
    }
  }
})

test_that("a reference outside the scale cannot silently lose a pair", {
  d <- m3a_attribute_runs(c("a", "a", "b", "b", "a", "b"))
  ref <- c(i1 = "a", i2 = "c", i3 = "b")
  for (w in c("unweighted", "linear", "quadratic")) {
    for (lv in list(NULL, c("a", "b"))) {
      expect_error(msa_agreement(d, levels = lv, reference = ref, weights = w),
                   '`reference` contains values outside `levels`: "c".', fixed = TRUE)
    }
    lv <- c("a", "b", "c", "unused")
    a <- msa_agreement(d, levels = lv, reference = ref, weights = w)
    # Directly enumerate pair weights, independent of the product cross-table.
    x <- match(d$value, lv)
    y <- match(ref[d$item_id], lv)
    loss <- function(x, y) switch(w, unweighted = as.numeric(x != y),
                                 linear = abs(x - y) / (length(lv) - 1),
                                 quadratic = ((x - y) / (length(lv) - 1))^2)
    expected <- 1 - mean(loss(x, y)) / mean(outer(x, y, loss))
    expect_equal(a$kappa[["kappa_all_vs_reference"]], expected,
                 tolerance = numeric_tolerance("package_compare", "abs_tol"))
    modal <- match(a$modal$value, lv)
    truth <- match(a$modal$reference, lv)
    expect_equal(a$kappa[["kappa_modal_vs_reference"]],
                 1 - mean(loss(modal, truth)) / mean(outer(modal, truth, loss)),
                 tolerance = numeric_tolerance("package_compare", "abs_tol"))
  }
  d$value[d$item_id == "i2"] <- NA_character_
  expect_error(msa_agreement(d, reference = ref), 'outside `levels`: "c"', fixed = TRUE)
  one <- m3a_attribute_runs(c("a", "b", "c"), c("i1", "i2", "i3"))
  expect_error(msa_agreement(one, levels = c("a", "b"), reference = "value"),
               '`reference` contains values outside `levels`: "c".', fixed = TRUE)
})

test_that("missing reference entries do not hide a unique known item reference", {
  d <- m3a_attribute_runs(c("a", "a", "b", "b", NA, NA))
  d$reference <- factor(c(NA, "a", "b", NA, NA, NA))
  for (idx in list(seq_len(nrow(d)), rev(seq_len(nrow(d))))) {
    s <- d[idx, ]
    for (ref in list("reference", s[c("item_id", "reference")],
                     stats::setNames(s$reference, s$item_id))) {
      a <- msa_agreement(s, levels = c("a", "b"), reference = ref)
      expect_identical(a$accuracy_overall, 100)
      expect_identical(a$pct_items_all_correct, 100)
      expect_identical(unname(a$kappa), c(1, 1))
      expect_identical(a$alpha$n_units_excluded, rep(1, 4))
      expect_true(is.na(a$modal$value[a$modal$item_id == "i3"]))
    }
  }
})

test_that("Fleiss uses every observed item and only reports a point estimate", {
  d <- m3a_attribute_runs(c("a", "a", "a", "b", "b", "b"))
  a <- msa_agreement(d, fleiss = TRUE)
  # Of three within-item pairs, two agree. Marginals are one half each.
  expected <- (2 / 3 - 1 / 2) / (1 - 1 / 2)
  expect_identical(names(a$fleiss), "kappa")
  expect_identical(attributes(a$fleiss$kappa), NULL)
  expect_equal(a$fleiss$kappa, expected, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  expect_null(msa_agreement(d)$fleiss)
  for (which in list(1L, 1:2)) {
    missing <- d
    missing$value[which] <- NA_character_
    expect_message(b <- msa_agreement(missing, levels = c("a", "b"), fleiss = TRUE), "Krippendorff")
    expect_identical(b$fleiss$kappa, NA_real_)
  }
})

test_that("alpha matches explicit pair distances and counts empty units", {
  mat <- rbind(c(1, 1, 2), c(2, 3, NA), c(3, 1, 3), c(NA, NA, NA), c(2, NA, NA))
  d <- m3a_attribute_runs(as.character(t(mat)), rep(paste0("i", seq_len(nrow(mat))), each = ncol(mat)))
  lv <- c("1", "2", "3", "unused")
  units <- lapply(seq_len(nrow(mat)), function(i) mat[i, !is.na(mat[i, ])])
  units <- units[lengths(units) >= 2L]
  pooled <- unlist(units)
  n <- length(pooled)
  freq <- tabulate(pooled, nbins = length(lv))
  midrank <- cumsum(freq) - freq / 2
  for (w in c("unweighted", "linear", "quadratic")) {
    distance <- function(a, b) switch(w, unweighted = as.numeric(a != b),
                                     linear = (midrank[a] - midrank[b])^2,
                                     quadratic = (a - b)^2)
    observed <- sum(vapply(units, function(u) sum(outer(u, u, distance)) / (length(u) - 1), numeric(1))) / n
    expected <- sum(outer(pooled, pooled, distance)) / (n * (n - 1))
    a <- msa_agreement(d, levels = lv, weights = w)
    expect_equal(a$alpha$alpha, rep(1 - observed / expected, 4),
                 tolerance = numeric_tolerance("arithmetic", "abs_tol"))
    expect_identical(a$alpha$n_units_excluded, rep(2, 4))
    # Distances use positions, even when the category labels look numeric.
    labels <- c("1", "10", "100", "1000")
    renamed <- d
    renamed$value <- labels[match(d$value, lv)]
    b <- msa_agreement(renamed, levels = labels, weights = w)
    expect_identical(a$alpha, b$alpha)
    expect_identical(msa_agreement(d[rev(seq_len(nrow(d))), ], levels = lv, weights = w)$alpha, a$alpha)
  }
})

test_that("Fleiss and each alpha metric agree with live irr oracles", {
  skip_if_not_installed("irr")
  mat <- rbind(c(1, 1, 2), c(2, 3, 2), c(3, 1, 3), c(1, 2, 2), c(3, 3, 3))
  d <- m3a_attribute_runs(as.character(t(mat)), rep(paste0("i", seq_len(nrow(mat))), each = ncol(mat)))
  for (w in c("unweighted", "linear", "quadratic")) {
    a <- msa_agreement(d, levels = as.character(1:3), weights = w, fleiss = TRUE)
    metric <- c(unweighted = "nominal", linear = "ordinal", quadratic = "interval")[[w]]
    # irr 0.85 uses mc = 1 for a completely observed matrix, even with
    # more than two raters. An all-missing coder leaves every usable pair
    # unchanged and selects its correct m_u - 1 normalization branch.
    oracle_data <- rbind(t(mat), NA_real_)
    expect_equal(a$alpha$alpha, rep(irr::kripp.alpha(oracle_data, method = metric)$value, 4),
                 tolerance = numeric_tolerance("package_compare", "abs_tol"))
    expect_equal(a$fleiss$kappa, irr::kappam.fleiss(mat)$value,
                 tolerance = numeric_tolerance("package_compare", "abs_tol"))
  }
})

test_that("complete-data alpha agrees with independent pair enumeration", {
  mat <- rbind(c(1, 1, 2), c(2, 3, 2), c(3, 1, 3), c(1, 2, 2), c(3, 3, 3))
  d <- m3a_attribute_runs(as.character(t(mat)), rep(paste0("i", seq_len(nrow(mat))), each = ncol(mat)))
  for (w in c("unweighted", "linear", "quadratic")) {
    a <- msa_agreement(d, levels = as.character(1:3), weights = w)
    metric <- c(unweighted = "nominal", linear = "ordinal", quadratic = "interval")[[w]]
    # Independent complete-data check: enumerate within-item unordered
    # pairs and compare with all unordered pairs in the pooled ratings.
    freq <- tabulate(as.vector(mat), nbins = 3)
    scores <- cumsum(freq) - freq / 2
    distance <- function(v) {
      pairs <- utils::combn(v, 2)
      switch(metric, nominal = as.numeric(pairs[1, ] != pairs[2, ]),
             ordinal = (scores[pairs[1, ]] - scores[pairs[2, ]])^2,
             interval = (pairs[1, ] - pairs[2, ])^2)
    }
    observed <- mean(apply(mat, 1, function(v) mean(distance(v))))
    expected <- mean(distance(as.vector(mat)))
    expect_equal(a$alpha$alpha, rep(1 - observed / expected, 4),
                 tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  }
})

test_that("categorical summaries use valid pairs and the lowest tied category", {
  d <- m3a_attribute_runs(c("c", "b", "c", "b", "a", NA, "b", "c", NA, NA),
                         rep(c("tie", "correct", "empty"), c(5, 3, 2)))
  # tie: b and c twice each, a once; correct: b,c against c; empty: no pairs.
  ref <- c(tie = "b", correct = "c", empty = "a")
  a <- msa_agreement(d, levels = c("a", "b", "c"), reference = ref)
  expect_identical(a$modal$value[match(c("tie", "correct", "empty"), a$modal$item_id)], c("b", "b", NA_character_))
  expect_equal(a$accuracy_overall, 100 * 3 / 7, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  expect_identical(a$pct_items_all_correct, 0)
  expect_identical(a$n[["missing"]], 3L)
  d$value[d$item_id == "correct"] <- "c"
  b <- msa_agreement(d, levels = c("a", "b", "c"), reference = ref)
  expect_identical(b$pct_items_all_correct, 50)
  # An item with no known reference contributes no accuracy pair.
  b <- msa_agreement(d, levels = c("a", "b", "c"), reference = ref["correct"])
  expect_identical(b$pct_items_all_correct, 100)
  expect_identical(b$accuracy_overall, 100)
})

test_that("scope grouping is independent of separator characters and block labels", {
  d <- m3a_attribute_runs(c("a", "a", "b", "c", "c", "c"), rep(c("a|b", "a", "third"), each = 2))
  d$prompt_id <- rep(c("c", "b|c", "other"), each = 2)
  a <- msa_agreement(d, levels = c("a", "b", "c"))
  plain <- d
  plain$item_id <- rep(c("i1", "i2", "i3"), each = 2)
  plain$prompt_id <- rep(c("p1", "p2", "p3"), each = 2)
  plain$block <- seq_len(nrow(plain))
  b <- msa_agreement(plain, levels = c("a", "b", "c"))
  expect_identical(a$alpha, b$alpha)
  expect_identical(a$reproducibility, b$reproducibility)
  expect_identical(a$repeatability_overall, b$repeatability_overall)
})

test_that("agreement degeneracies return NA with informative messages", {
  d <- m3a_attribute_runs(rep("b", 6))
  for (lv in list("b", c("a", "b", "c"))) for (w in c("unweighted", "linear", "quadratic")) {
    expect_message(a <- msa_agreement(d, levels = lv, weights = w, reference = c(i1 = "b", i2 = "b", i3 = "b")), "kappa")
    expect_identical(unname(a$kappa), rep(NA_real_, 2))
    expect_identical(a$alpha$alpha, rep(NA_real_, 4))
  }
  expect_message(a <- msa_agreement(d, fleiss = TRUE), "same category")
  expect_identical(a$fleiss, list(kappa = NA_real_))
  d$value[] <- NA_character_
  expect_message(a <- msa_agreement(d, fleiss = TRUE), "fewer than two valid ratings")
  expect_identical(a$alpha$alpha, rep(NA_real_, 4))
  expect_identical(a$alpha$n_units_excluded, rep(3, 4))
  expect_true(all(is.na(a$reproducibility)))
  expect_identical(a$repeatability_overall, NA_real_)
  d <- d[c(1, 3, 5), ]
  d$value <- c("a", "b", "c")
  expect_message(a <- msa_agreement(d, fleiss = TRUE), "fewer than two valid ratings")
  expect_identical(a$fleiss, list(kappa = NA_real_))
  expect_message(k <- cohen_kappa(c("bad", NA), c("a", "b"), c("a", "b")), "no valid response-reference pairs")
  expect_identical(k, NA_real_)
  expect_identical(krippendorff_alpha(c(NA, NA), c("u", "v"), "a"), NA_real_)
  expect_identical(krippendorff_alpha(c("a", "b"), c("u", "v"), c("a", "b")), NA_real_)
})

test_that("agreement input errors name the invalid field without a call", {
  check <- function(expr, text) {
    err <- tryCatch(expr, error = identity)
    expect_s3_class(err, "error")
    expect_identical(conditionMessage(err), text)
    expect_null(conditionCall(err))
  }
  d <- m3a_attribute_runs(c("a", "b", "a", "b", "b", "b"))
  for (bad in list(NULL, logical(), c(TRUE, FALSE), NA, 1, "TRUE")) {
    check(msa_agreement(d, fleiss = bad), "`fleiss` must be a single nonmissing logical value.")
  }
  check(msa_agreement(d[setdiff(names(d), "rep")]), "runs is missing required column(s): rep")
  check(msa_agreement(d, reference = 1), "`reference` must be a named vector, a data.frame (item_id, reference) or a column name.")
  check(msa_agreement(d, reference = data.frame(item_id = "i1")), "reference is missing required column(s): reference")
  check(msa_agreement(d, reference = c(i1 = "")), '`reference` contains values outside `levels`: "".')
  choices_error <- function(choices) paste0("'arg' should be one of ", paste(dQuote(choices), collapse = ", "))
  check(msa_agreement(d, weights = "bad"), choices_error(c("unweighted", "linear", "quadratic")))
  check(krippendorff_alpha("a", "u", "a", "bad"), choices_error(c("nominal", "ordinal", "interval")))
  check(cohen_kappa("a", "a", "a", "bad"), choices_error(c("unweighted", "linear", "quadratic")))
  check(msa_agreement(d, weights = 1), "'arg' must be NULL or a character vector")
  check(msa_agreement(d, weights = c("linear", "quadratic")), "'arg' must be of length 1")
})
