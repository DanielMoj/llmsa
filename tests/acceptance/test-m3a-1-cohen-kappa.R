# K-M3a-1: Cohen's kappa unweighted, linear and quadratic weighted
# (Formelsammlung §5) reproduces the example of Cohen (1968) (ankerRef:
# ANK-70) and agrees on irr::vision, irr::diagnoses (pairwise) and constructed
# tables with irr::kappa2, psych::cohen.kappa and DescTools::CohenKappa
# (ANK-TOL.package_compare); a table with only one occupied category gives NA
# with a note, never NaN. Two independent pieces of evidence (docs/01 §2 Nr. 2):
# the printed values of the source and the oracles, both also checked against
# the mini-reference of Formelsammlung §5 (setup-m3a.R). The weighted kappa of
# Cohen's example uses the disagreement weights 0/1/3/6, which none of the
# three weightings of msa_agreement() represents; the example's kappa_w is
# reproduced by the mini-reference and the oracles with these weights, the
# product reproduces the unweighted kappa of the example and is compared on
# the same table for linear and quadratic weights (ACC-3). Kappa is read from
# the fields kappa_all_vs_reference and kappa_modal_vs_reference of v0.1.0.

test_that("K-M3a-1: the mini-reference of Formelsammlung §5 and the oracles reproduce Cohen (1968), Table 1: kappa .492, kappa_w .348 and .574 with the weights 6 and 1 interchanged (ankerRef: ANK-70)", {
  ex <- acc_m3a_cohen_pairs()
  v <- acc_m3a_matrix(acc_m3a_value("ANK-70", "disagreement_weights"))
  v_max <- as.numeric(acc_m3a_value("ANK-70", "v_max"))
  tol <- acc_m3a_printed_tol(acc_m3a_value("ANK-70", "kappa_decimals"))
  p <- acc_m3a_matrix(acc_m3a_value("ANK-70", "observed_proportions"))
  expect_lte(max(abs(rowSums(p) - acc_m3a_num(acc_m3a_value("ANK-70", "row_margins")))), acc_m3a_arith(),
             label = "row sums of the printed proportions minus the printed row margins")
  expect_lte(max(abs(colSums(p) - acc_m3a_num(acc_m3a_value("ANK-70", "column_margins")))), acc_m3a_arith(),
             label = "column sums of the printed proportions minus the printed column margins")
  expect_lte(max(abs(outer(rowSums(p), colSums(p)) - acc_m3a_matrix(acc_m3a_value("ANK-70", "chance_proportions")))),
             acc_m3a_printed_tol(acc_m3a_value("ANK-70", "proportions_decimals")),
             label = "chance-expected proportions = products of the margins")
  swapped <- v
  swapped[v == 6] <- 1
  swapped[v == 1] <- 6
  cases <- list(kappa = list(w = diag(3), printed = acc_m3a_value("ANK-70", "kappa")),
                kappa_w = list(w = 1 - v / v_max, printed = acc_m3a_value("ANK-70", "kappa_w")),
                kappa_w_interchanged = list(w = 1 - swapped / v_max, printed = acc_m3a_value("ANK-70", "kappa_w_interchanged")))
  for (nm in names(cases)) {
    k <- acc_m3a_kappa_table(ex$counts, cases[[nm]]$w)
    expect_lte(abs(k - cases[[nm]]$printed), tol,
               label = sprintf("%s of the mini-reference %.6f, printed %s", nm, k, format(cases[[nm]]$printed)))
  }
  tab <- acc_m3a_crosstab(ex$response, ex$reference, ex$levels)
  expect_lte(abs(suppressWarnings(psych::cohen.kappa(tab, w = v)$weighted.kappa) - acc_m3a_kappa_table(tab, 1 - v / v_max)),
             acc_m3a_pkg(), label = "psych::cohen.kappa with the disagreement weights of Table 1")
  expect_lte(abs(unname(DescTools::CohenKappa(tab, weights = 1 - v / v_max)) - acc_m3a_kappa_table(tab, 1 - v / v_max)),
             acc_m3a_pkg(), label = "DescTools::CohenKappa with the agreement weights 1 - v / v_max")
})

test_that("K-M3a-1: msa_agreement() reproduces kappa .492 of Cohen (1968), Table 1 (unweighted; ankerRef: ANK-70)", {
  ex <- acc_m3a_cohen_pairs()
  ids <- sprintf("u%03d", seq_along(ex$response))
  runs <- acc_m3a_runs(item = ids, prompt = "judgeB", model = "m", rep = 1L, value = ex$response)
  ag <- msa_agreement(runs, levels = ex$levels, reference = stats::setNames(ex$reference, ids), weights = "unweighted")
  printed <- acc_m3a_value("ANK-70", "kappa")
  tol <- acc_m3a_printed_tol(acc_m3a_value("ANK-70", "kappa_decimals"))
  for (which in c("all", "modal")) {
    k <- acc_m3a_kappa(ag, which)
    expect_lte(abs(k - printed), tol, label = sprintf("kappa_%s_vs_reference %.6f, printed %s", which, k, format(printed)))
    expect_lte(abs(k - acc_m3a_kappa_table(ex$counts, diag(3))), acc_m3a_pkg(),
               label = sprintf("kappa_%s_vs_reference equals the mini-reference", which))
  }
  # Default weighting of v0.1.0 is unweighted.
  ag0 <- msa_agreement(runs, levels = ex$levels, reference = stats::setNames(ex$reference, ids))
  expect_lte(abs(acc_m3a_kappa(ag0, "all") - printed), tol, label = "kappa with the default weights")
})

test_that("K-M3a-1: on Cohen's Table 1, linear and quadratic kappa of msa_agreement() equal the mini-reference, irr::kappa2, psych::cohen.kappa and DescTools::CohenKappa (ANK-TOL.package_compare)", {
  ex <- acc_m3a_cohen_pairs()
  for (type in acc_m3a_weight_types) {
    k <- acc_m3a_pair_kappa(ex$response, ex$reference, ex$levels, weights = type)
    ref <- acc_m3a_kappa_table(ex$counts, acc_m3a_weights(3, type))
    expect_lte(abs(k - ref), acc_m3a_pkg(), label = sprintf("%s: msa_agreement() %.10f, mini-reference %.10f", type, k, ref))
    o <- acc_m3a_oracle_kappa(ex$response, ex$reference, ex$levels, type)
    for (nm in names(o)) {
      expect_lte(abs(k - o[[nm]]), acc_m3a_pkg(), label = sprintf("%s: msa_agreement() %.10f, %s %.10f", type, k, nm, o[[nm]]))
    }
  }
})

test_that("K-M3a-1: on irr::vision (right eye as response, left eye as reference), Cohen's kappa of msa_agreement() equals irr::kappa2, psych::cohen.kappa and DescTools::CohenKappa for all three weightings (ANK-TOL.package_compare)", {
  vision <- NULL
  utils::data("vision", package = "irr", envir = environment())
  lv <- levels(vision$r.eye)
  expect_identical(levels(vision$l.eye), lv)
  x <- as.character(vision$r.eye)
  y <- as.character(vision$l.eye)
  for (type in acc_m3a_weight_types) {
    k <- acc_m3a_pair_kappa(x, y, lv, weights = type)
    ref <- acc_m3a_kappa_table(acc_m3a_crosstab(x, y, lv), acc_m3a_weights(length(lv), type))
    expect_lte(abs(k - ref), acc_m3a_pkg(), label = sprintf("vision, %s: msa_agreement() %.10f, mini-reference %.10f", type, k, ref))
    o <- acc_m3a_oracle_kappa(x, y, lv, type)
    for (nm in names(o)) {
      expect_lte(abs(k - o[[nm]]), acc_m3a_pkg(), label = sprintf("vision, %s: msa_agreement() %.10f, %s %.10f", type, k, nm, o[[nm]]))
    }
  }
})

test_that("K-M3a-1: on irr::diagnoses, pairwise for all 15 pairs of raters, Cohen's kappa of msa_agreement() equals irr::kappa2, psych::cohen.kappa and DescTools::CohenKappa (ANK-TOL.package_compare)", {
  diagnoses <- NULL
  utils::data("diagnoses", package = "irr", envir = environment())
  all_lv <- levels(diagnoses[[1]])
  pairs <- utils::combn(ncol(diagnoses), 2)
  n_checked <- 0L
  for (j in seq_len(ncol(pairs))) {
    x <- as.character(diagnoses[[pairs[1, j]]])
    y <- as.character(diagnoses[[pairs[2, j]]])
    # The scale of each pair is the set of categories it uses, in scale order,
    # as irr::kappa2 forms it (ACC-4).
    lv <- all_lv[all_lv %in% c(x, y)]
    for (type in acc_m3a_weight_types) {
      k <- acc_m3a_pair_kappa(x, y, lv, weights = type)
      o <- c(acc_m3a_oracle_kappa(x, y, lv, type),
             mini = acc_m3a_kappa_table(acc_m3a_crosstab(x, y, lv), acc_m3a_weights(length(lv), type)))
      for (nm in names(o)) {
        expect_lte(abs(k - o[[nm]]), acc_m3a_pkg(),
                   label = sprintf("raters %d and %d, %s: msa_agreement() %.10f, %s %.10f", pairs[1, j], pairs[2, j], type, k, nm, o[[nm]]))
      }
      n_checked <- n_checked + 1L
    }
  }
  expect_identical(n_checked, 45L)
})

test_that("K-M3a-1: on constructed tables (K = 2 to 5, seeded, with a category unused by the response and one unused by the reference), Cohen's kappa of msa_agreement() equals the mini-reference and the three oracles (ANK-TOL.package_compare)", {
  cases <- list()
  for (K in 2:5) {
    lv <- paste0("c", seq_len(K))
    cases[[paste("K =", K)]] <- acc_m3a_with_seed(310L + K, {
      ref <- sample(lv, 60, replace = TRUE)
      keep <- stats::runif(60) < 0.6
      resp <- ifelse(keep, ref, sample(lv, 60, replace = TRUE))
      list(x = resp, y = ref, lv = lv)
    })
  }
  # c4 only in the reference (empty row), c1 only in the response (empty column).
  lv <- paste0("c", 1:4)
  cases[["empty row and column"]] <- acc_m3a_with_seed(319L, {
    y <- sample(c("c2", "c3", "c4"), 50, replace = TRUE)
    x <- ifelse(stats::runif(50) < 0.7, y, sample(c("c1", "c2", "c3"), 50, replace = TRUE))
    x[y == "c4"] <- sample(c("c1", "c3"), sum(y == "c4"), replace = TRUE)
    list(x = x, y = y, lv = lv)
  })
  tab <- acc_m3a_crosstab(cases[["empty row and column"]]$x, cases[["empty row and column"]]$y, lv)
  expect_true(rowSums(tab)[["c4"]] == 0 && colSums(tab)[["c1"]] == 0, label = "the last case has an empty row and an empty column")
  for (nm in names(cases)) {
    cs <- cases[[nm]]
    expect_true(all(cs$lv %in% c(cs$x, cs$y)), label = paste(nm, ": every category occurs"))
    for (type in acc_m3a_weight_types) {
      k <- acc_m3a_pair_kappa(cs$x, cs$y, cs$lv, weights = type)
      o <- c(acc_m3a_oracle_kappa(cs$x, cs$y, cs$lv, type),
             mini = acc_m3a_kappa_table(acc_m3a_crosstab(cs$x, cs$y, cs$lv), acc_m3a_weights(length(cs$lv), type)))
      for (on in names(o)) {
        expect_lte(abs(k - o[[on]]), acc_m3a_pkg(), label = sprintf("%s, %s: msa_agreement() %.10f, %s %.10f", nm, type, k, on, o[[on]]))
      }
    }
  }
})

test_that("K-M3a-1: a table with only one occupied category gives NA with a note, never NaN, for all three weightings", {
  scales <- list("three categories, one used" = c("B", "LB", "VUS"), "a scale of one category" = "B")
  for (nm in names(scales)) {
    lv <- scales[[nm]]
    ids <- sprintf("i%02d", 1:6)
    runs <- acc_m3a_runs(item = rep(ids, each = 2), prompt = "p", model = "m", rep = rep(1:2, 6), value = "B")
    for (type in acc_m3a_weight_types) {
      res <- acc_m3a_conditions(msa_agreement(runs, levels = lv, reference = stats::setNames(rep("B", 6), ids), weights = type))
      expect_true(!inherits(res$value, "error"),
                   label = sprintf("%s, %s: msa_agreement() returns a result (%s)", nm, type,
                                   if (inherits(res$value, "error")) conditionMessage(res$value) else "ok"))
      if (inherits(res$value, "error")) next
      for (which in c("all", "modal")) {
        k <- acc_m3a_kappa(res$value, which)
        expect_true(is.numeric(k) && length(k) == 1L && is.na(k) && !is.nan(k),
                    label = sprintf("%s, %s: kappa_%s_vs_reference is NA and not NaN (got %s)", nm, type, which, format(k)))
      }
      expect_true(any(grepl("kappa", res$notes, ignore.case = TRUE)),
                  label = sprintf("%s, %s: a message or warning names kappa (got: %s)", nm, type,
                                  if (length(res$notes)) paste(shQuote(res$notes), collapse = "; ") else "none"))
    }
  }
})
