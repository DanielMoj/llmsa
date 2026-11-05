# K-M3a-4: attribute statistics: hit rate overall and per prompt x model,
# share of fully correct items, modal answer per item with the tie rule
# "lowest category", attribute repeatability (cells with identical replicates;
# cells with fewer than two valid answers do not count) and attribute
# reproducibility (across prompts, across models, over all conditions) hit the
# values determined by hand on constructed data sets exactly; the AIAG
# attribute study (reference/quellen/data/aiag/attribute_study.csv)
# reproduces the kappa table of the manual (ankerRef: ANK-74).
# Exactly means up to ANK-TOL.arithmetic on the percent scale of the fields of
# v0.1.0. Missing answers stay missing: they count neither as right nor as
# wrong, and an item without a valid answer has no modal answer and does not
# enter the share of fully correct items (ACC-5). Reproducibility across
# prompts is the share of item x model units whose valid answers (all prompts
# and replicates) agree, across models the same for item x prompt units, each
# over the units with at least two valid answers (ACC-6). The hand values are
# checked a second time by the mini-reference (setup-m3a.R). The kappa table of
# the manual compares the appraisers in pairs on the same part and trial
# (AIAG 2010, p. 135) and each appraiser with the reference decision; both are
# computed with Cohen's kappa of msa_agreement() (ACC-7). Table III-C 5 is a
# second source for the attribute statistics on the same data.

# Constructed data set D1: 6 items, prompts P1 and P2, models M1 and M2, two
# replicates, categories a < b < c; i6 has no valid answer.
acc_m3a_4_d1 <- function() {
  cells <- c("P1|M1", "P1|M2", "P2|M1", "P2|M2")
  v <- list(i1 = c("a", "a",  "a", "a",  "a", "a",  "a", "a"),
            i2 = c("b", "b",  "b", "c",  "b", NA,   "c", "c"),
            i3 = c("c", "b",  "b", "c",  "a", "c",  "b", "a"),
            i4 = c("b", "b",  "b", "b",  NA,  NA,   "b", NA),
            i5 = c("c", "c",  "c", NA,   "c", "c",  NA,  NA),
            i6 = c(NA,  NA,   NA,  NA,   NA,  NA,   NA,  NA))
  ref <- c(i1 = "a", i2 = "b", i3 = "c", i4 = "a", i5 = "c", i6 = "b")
  pm <- strsplit(rep(rep(cells, each = 2), length(v)), "|", fixed = TRUE)
  runs <- acc_m3a_runs(item = rep(names(v), each = 8), prompt = vapply(pm, `[`, "", 1), model = vapply(pm, `[`, "", 2),
                       rep = rep(1:2, 4 * length(v)), value = unlist(v, use.names = FALSE))
  list(runs = runs, ref = ref, levels = c("a", "b", "c"))
}

# Values of D1 determined by hand (counts in the comments).
acc_m3a_4_d1_hand <- list(
  # valid answers 10 + 9 + 7 + 7 = 33, of them right 7 + 5 + 6 + 2 = 20
  accuracy_overall = 100 * 20 / 33,
  accuracy = list(c("P1", "M1", 100 * 7 / 10), c("P1", "M2", 100 * 5 / 9), c("P2", "M1", 100 * 6 / 7), c("P2", "M2", 100 * 2 / 7)),
  # items with a valid answer: i1 to i5; all valid answers right: i1, i5
  pct_items_all_correct = 100 * 2 / 5,
  # i3: a 2, b 3, c 3 -> tie of b and c -> b
  modal = c(i1 = "a", i2 = "b", i3 = "b", i4 = "b", i5 = "c", i6 = NA),
  # cells with two valid answers: 15, identical: 10
  repeatability_overall = 100 * 10 / 15,
  repeatability = list(c("P1", "M1", 100 * 4 / 5), c("P1", "M2", 100 * 2 / 4), c("P2", "M1", 100 * 2 / 3), c("P2", "M2", 100 * 2 / 3)),
  # item x model units with two valid answers: 9 (M1: i1-i5, M2: i1-i4), consistent: 6
  # item x prompt units: 9 (P1: i1-i5, P2: i1, i2, i3, i5), consistent: 5
  # items: i1-i5, consistent: i1, i4, i5
  reproducibility = c(across_prompts = 100 * 6 / 9, across_models = 100 * 5 / 9, overall = 100 * 3 / 5))

# Constructed data set D2: 5 items, prompts P1 to P3, one model, two
# replicates, binary categories "0" < "1".
acc_m3a_4_d2 <- function() {
  v <- list(i1 = c("1", "1",  "1", "1",  "1", "1"),
            i2 = c("0", "1",  "0", "0",  "1", "1"),
            i3 = c("1", NA,   "0", "0",  "1", "1"),
            i4 = c("0", "0",  "0", "0",  "0", NA),
            i5 = c(NA,  NA,   "1", "0",  NA,  "0"))
  ref <- c(i1 = "1", i2 = "0", i3 = "1", i4 = "0", i5 = "1")
  runs <- acc_m3a_runs(item = rep(names(v), each = 6), prompt = rep(rep(c("P1", "P2", "P3"), each = 2), length(v)),
                       model = "M1", rep = rep(1:2, 3 * length(v)), value = unlist(v, use.names = FALSE))
  list(runs = runs, ref = ref, levels = c("0", "1"))
}

acc_m3a_4_d2_hand <- list(
  # valid answers 7 + 10 + 8 = 25, right 6 + 7 + 5 = 18
  accuracy_overall = 100 * 18 / 25,
  accuracy = list(c("P1", "M1", 100 * 6 / 7), c("P2", "M1", 100 * 7 / 10), c("P3", "M1", 100 * 5 / 8)),
  # all valid answers right: i1, i4
  pct_items_all_correct = 100 * 2 / 5,
  # i2: 0 three times, 1 three times -> 0
  modal = c(i1 = "1", i2 = "0", i3 = "1", i4 = "0", i5 = "0"),
  # cells with two valid answers: 3 + 5 + 3 = 11, identical 2 + 4 + 3 = 9
  repeatability_overall = 100 * 9 / 11,
  repeatability = list(c("P1", "M1", 100 * 2 / 3), c("P2", "M1", 100 * 4 / 5), c("P3", "M1", 100 * 3 / 3)),
  # one model: item x model units are the items (i1, i4 consistent of 5);
  # item x prompt units are the cells pooled over replicates (9 of 11)
  reproducibility = c(across_prompts = 100 * 2 / 5, across_models = 100 * 9 / 11, overall = 100 * 2 / 5))

acc_m3a_4_repro_fields <- c(across_prompts = "pct_items_consistent_across_prompts",
                            across_models = "pct_items_consistent_across_models",
                            overall = "pct_items_consistent_overall")

acc_m3a_4_expect <- function(obs, hand, label, from_product = TRUE) {
  tol <- acc_m3a_arith()
  near <- function(a, b, what) {
    expect_true(is.numeric(a) && length(a) == 1L && !is.na(a) && abs(a - b) <= tol,
                label = sprintf("%s, %s: %s, by hand %.10f", label, what, format(a, digits = 12), b))
  }
  near(obs$accuracy_overall, hand$accuracy_overall, "hit rate overall")
  for (r in hand$accuracy) near(acc_m3a_cell(obs$accuracy, r[1], r[2], "pct_correct"), as.numeric(r[3]), paste("hit rate", r[1], r[2]))
  expect_identical(nrow(obs$accuracy), length(hand$accuracy), label = sprintf("%s: rows of the hit rate table", label))
  near(obs$pct_items_all_correct, hand$pct_items_all_correct, "share of fully correct items")
  modal <- if (from_product) acc_m3a_modal(obs) else obs$modal
  expect_identical(unname(modal[names(hand$modal)]), unname(hand$modal), label = sprintf("%s: modal answers", label))
  near(obs$repeatability_overall, hand$repeatability_overall, "repeatability overall")
  for (r in hand$repeatability) {
    near(acc_m3a_cell(obs$repeatability, r[1], r[2], "pct_items_consistent"), as.numeric(r[3]), paste("repeatability", r[1], r[2]))
  }
  for (k in names(hand$reproducibility)) {
    v <- if (from_product) obs$reproducibility[acc_m3a_4_repro_fields[[k]]] else obs$reproducibility[k]
    near(unname(v), hand$reproducibility[[k]], paste("reproducibility", k))
  }
}

test_that("K-M3a-4: on the constructed data set D1 (2 prompts x 2 models x 2 replicates, missing answers, a tie, an item without a valid answer), hit rates, fully correct items, modal answers, repeatability and reproducibility of msa_agreement() equal the values determined by hand", {
  d <- acc_m3a_4_d1()
  ag <- msa_agreement(d$runs, levels = d$levels, reference = d$ref)
  acc_m3a_4_expect(ag, acc_m3a_4_d1_hand, "D1")
  acc_m3a_4_expect(acc_m3a_attribute_ref(d$runs, d$ref, d$levels), acc_m3a_4_d1_hand, "D1, mini-reference", from_product = FALSE)
})

test_that("K-M3a-4: on the constructed binary data set D2 (3 prompts x 1 model x 2 replicates, a tie of 0 and 1), the attribute statistics of msa_agreement() equal the values determined by hand", {
  d <- acc_m3a_4_d2()
  ag <- msa_agreement(d$runs, levels = d$levels, reference = d$ref)
  acc_m3a_4_expect(ag, acc_m3a_4_d2_hand, "D2")
  acc_m3a_4_expect(acc_m3a_attribute_ref(d$runs, d$ref, d$levels), acc_m3a_4_d2_hand, "D2, mini-reference", from_product = FALSE)
})

test_that("K-M3a-4: the AIAG attribute study reproduces the kappa table of the manual: .86, .78, .79 between the appraisers (Table III-C 3) and .88, .92, .77 against the reference decision (ankerRef: ANK-74)", {
  d <- acc_m3a_aiag("ANK-74")
  lv <- as.character(unlist(acc_m3a_value("ANK-74", "design", "categories")))
  tol <- acc_m3a_printed_tol(acc_m3a_value("ANK-74", "kappa_decimals"))
  tabs <- acc_m3a_value("ANK-74", "crosstabs")
  expect_cross <- function(x, y, key) {
    t <- acc_m3a_crosstab(x, y, lv)
    got <- c(x0_y0 = t["0", "0"], x0_y1 = t["0", "1"], x1_y0 = t["1", "0"], x1_y1 = t["1", "1"])
    expect_identical(as.numeric(got), acc_m3a_num(tabs[[key]][names(got)]), label = sprintf("cross-tabulation %s of Table III-C 2/4", key))
  }
  between <- acc_m3a_value("ANK-74", "kappa_between")
  for (key in names(between)) {
    ab <- strsplit(key, "_", fixed = TRUE)[[1]]
    x <- acc_m3a_decisions(d, ab[1])
    y <- acc_m3a_decisions(d, ab[2])
    expect_identical(x$key, y$key)
    expect_cross(x$value, y$value, key)
    k <- acc_m3a_pair_kappa(x$value, y$value, lv)
    expect_lte(abs(k - between[[key]]), tol, label = sprintf("kappa %s: %.6f, printed %s", key, k, format(between[[key]])))
  }
  reference <- acc_m3a_value("ANK-74", "kappa_reference")
  ref <- acc_m3a_attribute_reference(d)
  for (ap in names(reference)) {
    x <- acc_m3a_decisions(d, ap)
    expect_cross(x$value, x$reference, paste0(ap, "_REF"))
    ag <- msa_agreement(acc_m3a_attribute_runs(d, ap), levels = lv, reference = ref)
    k <- acc_m3a_kappa(ag, "all")
    expect_lte(abs(k - reference[[ap]]), tol, label = sprintf("kappa %s against the reference: %.6f, printed %s", ap, k, format(reference[[ap]])))
  }
})

test_that("K-M3a-4: on the AIAG attribute study, repeatability per appraiser, fully correct parts per appraiser and the agreement of all appraisers of msa_agreement() equal Table III-C 5 (ankerRef: ANK-74)", {
  d <- acc_m3a_aiag("ANK-74")
  lv <- as.character(unlist(acc_m3a_value("ANK-74", "design", "categories")))
  ref <- acc_m3a_attribute_reference(d)
  eff <- acc_m3a_value("ANK-74", "effectiveness_table")
  total <- as.numeric(eff$total_inspected)
  tol <- acc_m3a_arith()
  ag <- msa_agreement(acc_m3a_attribute_runs(d), levels = lv, reference = ref)
  for (ap in c("A", "B", "C")) {
    r <- acc_m3a_cell(ag$repeatability, ap, "gage", "pct_items_consistent")
    expect_lte(abs(r - 100 * eff$appraiser_matched_all_trials[[ap]] / total), tol,
               label = sprintf("appraiser %s agrees with him/herself on all trials: %s %%", ap, format(r)))
    one <- msa_agreement(acc_m3a_attribute_runs(d, ap), levels = lv, reference = ref)
    expect_lte(abs(one$pct_items_all_correct - 100 * eff$score_vs_attribute_matched[[ap]] / total), tol,
               label = sprintf("appraiser %s agrees on all trials with the standard: %s %%", ap, format(one$pct_items_all_correct)))
  }
  expect_lte(abs(ag$reproducibility[["pct_items_consistent_overall"]] - 100 * eff$system_in_agreement / total), tol,
             label = "all appraisers agreed within and between themselves")
  expect_lte(abs(ag$pct_items_all_correct - 100 * eff$system_in_agreement_vs_reference / total), tol,
             label = "all appraisers agreed within and between themselves and with the reference")
})
