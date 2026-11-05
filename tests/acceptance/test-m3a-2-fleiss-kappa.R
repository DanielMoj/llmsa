# K-M3a-2: msa_agreement() gets the argument fleiss = FALSE (default,
# Schnittstellenregel) and with fleiss = TRUE computes kappa_F after
# Formelsammlung §5 for units with the same number of raters; on
# irr::diagnoses the value equals Fleiss (1971), Table 1 (ankerRef: ANK-72),
# and irr::kappam.fleiss (ANK-TOL.package_compare); with unequal numbers of
# raters it gives NA with a message that points to Krippendorff's alpha; a
# standard error is given only if it is computed after Fleiss, Nee & Landis
# (1979). Two independent pieces of evidence: the printed values of the source
# and irr::kappam.fleiss, both also against the mini-reference (setup-m3a.R).
# The ratings of an item are all its valid answers over prompts, models,
# blocks and replicates (Formelsammlung §5: m ratings per item); the result
# carries kappa_F as fleiss$kappa (ACC-8); a standard error, if given, is an
# element of fleiss whose name marks it as such (ACC-9).

acc_m3a_2_diagnoses <- function() {
  diagnoses <- NULL
  utils::data("diagnoses", package = "irr", envir = environment())
  diagnoses
}

# irr::diagnoses as runs: patient = item; the six ratings as prompts, as
# 3 prompts x 2 replicates, or as 2 models x 3 prompts.
acc_m3a_2_runs <- function(dg, layout = c("prompts", "prompts_reps", "models_prompts")) {
  layout <- match.arg(layout)
  N <- nrow(dg)
  item <- rep(sprintf("p%02d", seq_len(N)), each = ncol(dg))
  r <- rep(seq_len(ncol(dg)), times = N)
  value <- as.character(t(as.matrix(data.frame(lapply(dg, as.character), stringsAsFactors = FALSE))))
  switch(layout,
         prompts = acc_m3a_runs(item = item, prompt = paste0("r", r), model = "m", rep = 1L, value = value),
         prompts_reps = acc_m3a_runs(item = item, prompt = paste0("p", (r + 1L) %/% 2L), model = "m", rep = 2L - r %% 2L, value = value),
         models_prompts = acc_m3a_runs(item = item, prompt = paste0("p", (r - 1L) %% 3L + 1L), model = paste0("m", (r - 1L) %/% 3L + 1L),
                                       rep = 1L, value = value))
}

test_that("K-M3a-2: msa_agreement() has the argument fleiss with the default FALSE behind the arguments of v0.1.0, and the default adds no Fleiss part (Schnittstellenregel)", {
  f <- formals(msa_agreement)
  expect_true("fleiss" %in% names(f), label = "msa_agreement() has an argument fleiss")
  if (!"fleiss" %in% names(f)) return(invisible())
  expect_identical(f$fleiss, FALSE)
  expect_gt(match("fleiss", names(f)), match("weights", names(f)))
  dg <- acc_m3a_2_diagnoses()
  ag <- msa_agreement(acc_m3a_2_runs(dg), levels = levels(dg[[1]]))
  expect_null(ag$fleiss)
})

test_that("K-M3a-2: irr::diagnoses is Table 1 of Fleiss (1971), and the mini-reference reproduces P-bar .5556, P-bar_e .2201 and kappa .430 (ankerRef: ANK-72) and equals irr::kappam.fleiss (ANK-TOL.package_compare)", {
  dg <- acc_m3a_2_diagnoses()
  lv <- levels(dg[[1]])
  runs <- as.data.frame(acc_m3a_2_runs(dg))
  counts <- acc_m3a_counts(runs$item_id, runs$value, lv)
  expect_identical(as.numeric(colSums(counts)), acc_m3a_num(acc_m3a_value("ANK-72", "category_totals")))
  expect_identical(nrow(counts), as.integer(acc_m3a_value("ANK-72", "subjects")))
  ref <- acc_m3a_fleiss_ref(counts)
  expect_identical(as.integer(ref$m), as.integer(acc_m3a_value("ANK-72", "ratings_per_subject")))
  p_printed <- acc_m3a_num(acc_m3a_value("ANK-72", "p_j"))
  expect_lte(max(abs(ref$p - p_printed)), acc_m3a_printed_tol(acc_m3a_value("ANK-72", "p_j_decimals")), label = "p_j")
  pb <- acc_m3a_value("ANK-72", "P_bar")
  expect_lte(abs(ref$P_bar - pb), acc_m3a_printed_tol(acc_m3a_value("ANK-72", "P_bar_decimals")),
             label = sprintf("P-bar %.6f, printed %s", ref$P_bar, format(pb)))
  pe <- acc_m3a_value("ANK-72", "P_e")
  # Gl. (6) of the source sums the squares of the printed p_j (ANK-72, P_e_rule).
  expect_lte(abs(sum(p_printed^2) - pe), acc_m3a_printed_tol(acc_m3a_value("ANK-72", "P_e_decimals")),
             label = sprintf("P-bar_e from the printed p_j %.6f, printed %s", sum(p_printed^2), format(pe)))
  # |sum p^2 - sum p'^2| <= sum (2 p' + h) h for |p - p'| <= h, h half a unit
  # of the printed p_j (ANK-72, tolerance P_e).
  h <- 0.5 * 10^(-as.numeric(acc_m3a_value("ANK-72", "p_j_decimals")))
  expect_lte(abs(ref$P_e - pe), sum((2 * p_printed + h) * h) + acc_m3a_printed_tol(acc_m3a_value("ANK-72", "P_e_decimals")),
             label = sprintf("exact P-bar_e %.6f within the rounding of the p_j of %s", ref$P_e, format(pe)))
  k <- acc_m3a_value("ANK-72", "kappa")
  expect_lte(abs(ref$kappa - k), acc_m3a_printed_tol(acc_m3a_value("ANK-72", "kappa_decimals")),
             label = sprintf("kappa %.6f, printed %s", ref$kappa, format(k)))
  o <- irr::kappam.fleiss(dg)
  expect_lte(abs(o$value - ref$kappa), acc_m3a_pkg(), label = "irr::kappam.fleiss value")
  expect_lte(abs(o$value / o$statistic - ref$se), acc_m3a_pkg(),
             label = "irr::kappam.fleiss value / statistic equals the standard error of Fleiss, Nee & Landis (1979), Gl. (12)")
})

test_that("K-M3a-2: with fleiss = TRUE, kappa_F of msa_agreement() on irr::diagnoses equals Fleiss (1971), Table 1 (.430, ankerRef: ANK-72) and irr::kappam.fleiss (ANK-TOL.package_compare), whatever factors carry the six ratings", {
  dg <- acc_m3a_2_diagnoses()
  lv <- levels(dg[[1]])
  printed <- acc_m3a_value("ANK-72", "kappa")
  tol <- acc_m3a_printed_tol(acc_m3a_value("ANK-72", "kappa_decimals"))
  o <- irr::kappam.fleiss(dg)$value
  for (layout in c("prompts", "prompts_reps", "models_prompts")) {
    ag <- msa_agreement(acc_m3a_2_runs(dg, layout), levels = lv, fleiss = TRUE)
    k <- acc_m3a_fleiss(ag)$kappa
    expect_lte(abs(k - printed), tol, label = sprintf("%s: kappa_F %.6f, printed %s", layout, k, format(printed)))
    expect_lte(abs(k - o), acc_m3a_pkg(), label = sprintf("%s: kappa_F %.10f, irr::kappam.fleiss %.10f", layout, k, o))
  }
})

test_that("K-M3a-2: kappa_F of msa_agreement() equals the mini-reference and irr::kappam.fleiss on seeded data with equal numbers of valid ratings, also when every item misses one answer (ANK-TOL.package_compare)", {
  cases <- list(
    list(seed = 3201L, N = 25L, prompts = 2L, reps = 2L, K = 4L, drop_one = FALSE),
    list(seed = 3202L, N = 40L, prompts = 3L, reps = 1L, K = 3L, drop_one = FALSE),
    list(seed = 3203L, N = 30L, prompts = 5L, reps = 1L, K = 5L, drop_one = TRUE))
  for (cs in cases) {
    lv <- paste0("k", seq_len(cs$K))
    m <- cs$prompts * cs$reps
    d <- acc_m3a_with_seed(cs$seed, {
      truth <- sample(lv, cs$N, replace = TRUE)
      g <- expand.grid(rep = seq_len(cs$reps), prompt = seq_len(cs$prompts), item = seq_len(cs$N))
      g$value <- ifelse(stats::runif(nrow(g)) < 0.55, truth[g$item], sample(lv, nrow(g), replace = TRUE))
      # expand.grid varies rep fastest, then prompt, then item: rows (i - 1) m + 1..m.
      if (cs$drop_one) g$value[(seq_len(cs$N) - 1L) * m + sample.int(m, cs$N, replace = TRUE)] <- NA_character_
      g
    })
    runs <- acc_m3a_runs(item = sprintf("i%02d", d$item), prompt = paste0("p", d$prompt), model = "m", rep = d$rep, value = d$value)
    ag <- msa_agreement(runs, levels = lv, fleiss = TRUE)
    k <- acc_m3a_fleiss(ag)$kappa
    rd <- as.data.frame(runs)
    ref <- acc_m3a_fleiss_ref(acc_m3a_counts(rd$item_id, rd$value, lv))
    o <- irr::kappam.fleiss(acc_m3a_rating_matrix(rd$item_id, rd$value))$value
    label <- sprintf("seed %d (N = %d, %d ratings%s, K = %d)", cs$seed, cs$N, m, if (cs$drop_one) " with one missing" else "", cs$K)
    expect_lte(abs(k - ref$kappa), acc_m3a_pkg(), label = sprintf("%s: kappa_F %.10f, mini-reference %.10f", label, k, ref$kappa))
    expect_lte(abs(k - o), acc_m3a_pkg(), label = sprintf("%s: kappa_F %.10f, irr::kappam.fleiss %.10f", label, k, o))
  }
})

test_that("K-M3a-2: with unequal numbers of raters, kappa_F is NA (not NaN) with a message that points to Krippendorff's alpha", {
  dg <- acc_m3a_2_diagnoses()
  lv <- levels(dg[[1]])
  missing_one <- as.data.frame(acc_m3a_2_runs(dg))
  missing_one$value[3] <- NA_character_
  extra <- as.data.frame(acc_m3a_2_runs(dg))
  extra <- rbind(extra, transform(extra[1, ], rep = 2L))
  for (nm in c("one answer missing", "one item with a seventh answer")) {
    d <- if (nm == "one answer missing") missing_one else extra
    res <- acc_m3a_conditions(msa_agreement(acc_m3a_runs(d$item_id, d$prompt_id, d$model_id, d$rep, d$value),
                                            levels = lv, fleiss = TRUE))
    expect_true(!inherits(res$value, "error"),
                 label = sprintf("%s: msa_agreement() returns a result (%s)", nm,
                                 if (inherits(res$value, "error")) conditionMessage(res$value) else "ok"))
    if (inherits(res$value, "error")) next
    k <- acc_m3a_fleiss(res$value)$kappa
    expect_true(is.na(k) && !is.nan(k), label = sprintf("%s: kappa_F is NA and not NaN (got %s)", nm, format(k)))
    expect_true(any(grepl("Krippendorff", res$notes, ignore.case = TRUE)),
                label = sprintf("%s: a message or warning points to Krippendorff's alpha (got: %s)", nm,
                                if (length(res$notes)) paste(shQuote(res$notes), collapse = "; ") else "none"))
  }
})

test_that("K-M3a-2: a standard error of kappa_F, if msa_agreement() gives one, follows Fleiss, Nee & Landis (1979), Gl. (12) (ankerRef: ANK-72), in the result and in the printout", {
  dg <- acc_m3a_2_diagnoses()
  lv <- levels(dg[[1]])
  runs <- acc_m3a_2_runs(dg)
  rd <- as.data.frame(runs)
  ref <- acc_m3a_fleiss_ref(acc_m3a_counts(rd$item_id, rd$value, lv))
  ag <- msa_agreement(runs, levels = lv, fleiss = TRUE)
  se <- acc_m3a_se_fields(acc_m3a_fleiss(ag))
  ok <- vapply(se, function(v) is.numeric(v) && length(v) == 1L && is.finite(v) && abs(v - ref$se) <= acc_m3a_pkg(), logical(1))
  expect_true(all(ok),
              label = sprintf("standard errors in fleiss (%s) equal Gl. (12) of Fleiss, Nee & Landis (1979), %.8f (Fleiss 1971 would give 0.0275)",
                              if (length(se)) paste(sprintf("%s = %s", names(se), vapply(se, function(v) format(v, digits = 8), "")), collapse = ", ") else "none given",
                              ref$se))
  out <- utils::capture.output(print(ag))
  lines <- out[grepl("(?i)fleiss", out, perl = TRUE) & grepl("(?i)\\bSE\\b|standard error|std\\.? ?err", out, perl = TRUE)]
  shown <- vapply(lines, function(l) any(vapply(acc_m1a_numbers(l), acc_m1a_shows, logical(1), value = ref$se)), logical(1))
  expect_true(all(shown),
              label = sprintf("printed lines that give a standard error of Fleiss' kappa show %.6f (lines: %s)", ref$se,
                              if (length(lines)) paste(shQuote(lines), collapse = "; ") else "none"))
})

test_that("K-M3a-2: identical answers on every item give kappa_F NA, not NaN, and leave the other statistics of msa_agreement() (docs/01 §2 Nr. 4; ACC-8)", {
  lv <- c("k1", "k2", "k3")
  runs <- acc_m3a_runs(item = rep(sprintf("i%02d", 1:10), each = 4), prompt = rep(paste0("p", 1:4), 10), model = "m",
                       rep = 1L, value = "k2")
  res <- acc_m3a_conditions(msa_agreement(runs, levels = lv, fleiss = TRUE))
  expect_true(!inherits(res$value, "error"),
               label = sprintf("msa_agreement(fleiss = TRUE) returns a result (%s)",
                               if (inherits(res$value, "error")) conditionMessage(res$value) else "ok"))
  if (inherits(res$value, "error")) return(invisible())
  k <- acc_m3a_fleiss(res$value)$kappa
  expect_true(is.na(k) && !is.nan(k), label = sprintf("kappa_F is NA and not NaN (got %s)", format(k)))
  expect_identical(res$value$reproducibility[["pct_items_consistent_overall"]], 100)
})
