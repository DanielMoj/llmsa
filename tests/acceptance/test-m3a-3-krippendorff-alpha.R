# K-M3a-3: Krippendorff's alpha for nominal, ordinal and interval data with
# missing values reproduces the example of Krippendorff (2011) (ankerRef:
# ANK-73), agrees with irr::kripp.alpha (ANK-TOL.package_compare), the mapping
# of the weights (unweighted -> nominal, linear -> ordinal, quadratic ->
# interval) is documented and tested; units with fewer than two valid answers
# do not enter and are counted. Two independent pieces of evidence: the
# printed values of the source and irr::kripp.alpha, both also against a
# mini-reference in the general form of the source (section E, without a
# coincidence matrix; setup-m3a.R). The count is the column n_units_excluded
# of the alpha table (ACC-10); the documentation is the help page of
# msa_agreement() (ACC-11).

acc_m3a_3_check_example <- function(ag, scopes, label) {
  printed <- acc_m3a_value("ANK-73", "alpha")
  tol <- acc_m3a_printed_tol(acc_m3a_value("ANK-73", "alpha_decimals"))
  for (sc in scopes) {
    a <- acc_m3a_alpha(ag, sc)
    expect_lte(abs(a - printed[[acc_m3a_metric_of[[ag$weights]]]]), tol,
               label = sprintf("%s, %s, scope \"%s\": alpha %.6f, printed %s", label, ag$weights, acc_m3a_scopes[[sc]], a,
                               format(printed[[acc_m3a_metric_of[[ag$weights]]]])))
  }
}

test_that("K-M3a-3: the mini-reference reproduces Krippendorff's (2011) example: n = 40 pairable values, alpha nominal .743, ordinal .815, interval .849 and ratio .797 (ankerRef: ANK-73)", {
  mat <- acc_m3a_kripp_example()
  expect_identical(sum(is.na(mat)), as.integer(acc_m3a_value("ANK-73", "missing")))
  expect_identical(as.numeric(colSums(!is.na(mat))), acc_m3a_num(acc_m3a_value("ANK-73", "values_per_unit")))
  scores <- as.vector(mat)
  units <- rep(seq_len(ncol(mat)), each = nrow(mat))
  printed <- acc_m3a_value("ANK-73", "alpha")
  tol <- acc_m3a_printed_tol(acc_m3a_value("ANK-73", "alpha_decimals"))
  for (metric in c("nominal", "ordinal", "interval", "ratio")) {
    r <- acc_m3a_kripp_ref(scores, units, 5L, metric)
    expect_lte(abs(r$alpha - printed[[metric]]), tol, label = sprintf("%s: %.6f, printed %s", metric, r$alpha, format(printed[[metric]])))
    expect_identical(as.integer(r$n), as.integer(acc_m3a_value("ANK-73", "pairable_values")))
    expect_identical(as.numeric(r$n_c), acc_m3a_num(acc_m3a_value("ANK-73", "pairable_by_value")))
    expect_identical(r$units, ncol(mat) - length(acc_m3a_value("ANK-73", "lone_value_units")))
  }
})

test_that("K-M3a-3: msa_agreement() reproduces Krippendorff's (2011) example with missing values: unweighted .743, linear .815, quadratic .849 (nominal, ordinal, interval; ankerRef: ANK-73)", {
  mat <- acc_m3a_kripp_example()
  lv <- as.character(acc_m3a_num(acc_m3a_value("ANK-73", "values")))
  for (type in acc_m3a_weight_types) {
    ag <- msa_agreement(acc_m3a_matrix_runs(mat, "prompts"), levels = lv, weights = type)
    acc_m3a_3_check_example(ag, c("prompts", "all"), "observers as prompts")
    ag <- msa_agreement(acc_m3a_matrix_runs(mat, "replicates"), levels = lv, weights = type)
    acc_m3a_3_check_example(ag, c("replicates", "prompts", "models", "all"), "observers as replicates")
  }
})

test_that("K-M3a-3: Krippendorff's alpha of msa_agreement() equals irr::kripp.alpha and the mini-reference (nominal, ordinal, interval) on the example and on seeded data with missing values (ANK-TOL.package_compare)", {
  data <- list(example = acc_m3a_kripp_example())
  for (cs in list(list(seed = 3301L, raters = 4L, units = 30L, K = 5L), list(seed = 3302L, raters = 6L, units = 20L, K = 4L))) {
    data[[sprintf("seed %d", cs$seed)]] <- acc_m3a_with_seed(cs$seed, {
      truth <- sample.int(cs$K, cs$units, replace = TRUE)
      m <- t(vapply(seq_len(cs$raters), function(r) {
        v <- ifelse(stats::runif(cs$units) < 0.6, truth, sample.int(cs$K, cs$units, replace = TRUE))
        v[stats::runif(cs$units) < 0.15] <- NA
        v
      }, numeric(cs$units)))
      m[, 1] <- c(truth[1], rep(NA, cs$raters - 1L))   # a lone value
      m[, 2] <- NA                                      # a unit without values
      m
    })
  }
  for (nm in names(data)) {
    mat <- data[[nm]]
    K <- max(mat, na.rm = TRUE)
    lv <- as.character(seq_len(K))
    expect_true(all(seq_len(K) %in% mat), label = paste(nm, ": every category occurs"))
    for (type in acc_m3a_weight_types) {
      metric <- acc_m3a_metric_of[[type]]
      ag <- msa_agreement(acc_m3a_matrix_runs(mat, "prompts"), levels = lv, weights = type)
      a <- acc_m3a_alpha(ag, "all")
      o <- irr::kripp.alpha(mat, method = metric)$value
      r <- acc_m3a_kripp_ref(as.vector(mat), rep(seq_len(ncol(mat)), each = nrow(mat)), K, metric)$alpha
      expect_lte(abs(a - o), acc_m3a_pkg(), label = sprintf("%s, %s (%s): msa_agreement() %.10f, irr::kripp.alpha %.10f", nm, type, metric, a, o))
      expect_lte(abs(a - r), acc_m3a_pkg(), label = sprintf("%s, %s (%s): msa_agreement() %.10f, mini-reference %.10f", nm, type, metric, a, r))
    }
  }
})

test_that("K-M3a-3: the weights map to the metrics unweighted -> nominal, linear -> ordinal, quadratic -> interval and to no other metric (tested on Krippendorff's example)", {
  mat <- acc_m3a_kripp_example()
  scores <- as.vector(mat)
  units <- rep(seq_len(ncol(mat)), each = nrow(mat))
  ref <- vapply(c("nominal", "ordinal", "interval"), function(m) acc_m3a_kripp_ref(scores, units, 5L, m)$alpha, numeric(1))
  for (type in acc_m3a_weight_types) {
    a <- acc_m3a_alpha(msa_agreement(acc_m3a_matrix_runs(mat, "prompts"), levels = as.character(1:5), weights = type), "all")
    for (metric in names(ref)) {
      if (identical(metric, acc_m3a_metric_of[[type]])) {
        expect_lte(abs(a - ref[[metric]]), acc_m3a_pkg(), label = sprintf("weights = \"%s\" gives the %s alpha", type, metric))
      } else {
        expect_gt(abs(a - ref[[metric]]), 1000 * acc_m3a_pkg(), label = sprintf("weights = \"%s\" does not give the %s alpha", type, metric))
      }
    }
  }
})

test_that("K-M3a-3: the help page of msa_agreement() documents the mapping unweighted (nominal), linear (ordinal), quadratic (interval) and no other pairing", {
  txt <- acc_m3a_norm(acc_m1b_rd_text("msa_agreement"))
  # A weight and its metric written as "w (m)", "w -> m", "w → m", "w: m" or
  # "w = m", or the other way round (ACC-11).
  pair <- function(a, b) sprintf("\\b%s\\b\\s*(?:\\(|->|→|:|=)\\s*%s\\b", a, b)
  documented <- function(w, m) grepl(pair(w, m), txt, ignore.case = TRUE, perl = TRUE) ||
    grepl(pair(m, w), txt, ignore.case = TRUE, perl = TRUE)
  for (type in acc_m3a_weight_types) {
    for (metric in unique(acc_m3a_metric_of)) {
      if (identical(metric, acc_m3a_metric_of[[type]])) {
        expect_true(documented(type, metric), label = sprintf("man/msa_agreement.Rd maps %s to %s", type, metric))
      } else {
        expect_false(documented(type, metric), label = sprintf("man/msa_agreement.Rd does not map %s to %s", type, metric))
      }
    }
  }
})

test_that("K-M3a-3: units with fewer than two valid answers do not enter alpha and are counted per scope (column n_units_excluded)", {
  mat <- acc_m3a_kripp_example()
  lv <- as.character(1:5)
  # Observers as prompts: replicate cells and item x prompt units hold one
  # value at most (48 units each); item x model units and items: unit 12.
  expected <- list(prompts = c(replicates = 48, prompts = 1, models = 48, all = 1),
                   replicates = c(replicates = 1, prompts = 1, models = 1, all = 1))
  for (layout in names(expected)) {
    ag <- msa_agreement(acc_m3a_matrix_runs(mat, layout), levels = lv)
    for (sc in names(expected[[layout]])) {
      n <- acc_m3a_alpha(ag, sc, "n_units_excluded")
      expect_true(is.numeric(n) && length(n) == 1L && isTRUE(n == expected[[layout]][[sc]]),
                  label = sprintf("observers as %s, scope \"%s\": %s units excluded, expected %d", layout, acc_m3a_scopes[[sc]],
                                  format(n), as.integer(expected[[layout]][[sc]])))
    }
  }
  # Three more units, two with one valid answer and one without, change no
  # alpha and add three to the count of the scope "all conditions".
  extra <- cbind(mat, c(2, NA, NA, NA), c(NA, NA, 5, NA), c(NA, NA, NA, NA))
  for (type in acc_m3a_weight_types) {
    a0 <- msa_agreement(acc_m3a_matrix_runs(mat, "prompts"), levels = lv, weights = type)
    a1 <- msa_agreement(acc_m3a_matrix_runs(extra, "prompts"), levels = lv, weights = type)
    expect_lte(abs(acc_m3a_alpha(a1, "all") - acc_m3a_alpha(a0, "all")), acc_m3a_arith(),
               label = sprintf("%s: alpha with three units without a pair", type))
    expect_lte(abs(acc_m3a_alpha(a1, "prompts") - acc_m3a_alpha(a0, "prompts")), acc_m3a_arith(),
               label = sprintf("%s: alpha across prompts with three units without a pair", type))
    expect_identical(as.numeric(acc_m3a_alpha(a1, "all", "n_units_excluded")), 4, label = sprintf("%s: units excluded", type))
  }
})
