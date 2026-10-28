# K-M1a-4: numerical accuracy on the NIST StRD ANOVA datasets (item = treatment,
# replicate = observation; certified values ankerRef: ANK-14). Lower
# difficulty (ANK-TOL.nist_digits$low_difficulty_datasets): REML residual
# variance against the certified within mean square and item component against
# the ANOVA estimator from the certified mean squares, relative tolerance of
# ANK-TOL.nist_digits. Average difficulty (medium_difficulty_datasets): LRE of
# msa_fit at most the margin of ANK-TOL.nist_digits below the LRE of stats::aov
# on the same data, for both quantities; vignettes/validation.Rmd reports both
# LRE per dataset, also for SmLs07-SmLs09 (no criterion). The data files are
# read from ../quellen/daten/nist-strd-anova_2026-10-22/ and must carry the
# SHA-256 of ANK-14 (ACC-9).

acc_m1a_4_fit <- function(name) {
  key <- paste0("nist_fit_", name)
  if (is.null(acc_m1a[[key]])) {
    acc_m1a[[key]] <- tryCatch(acc_m1a_quiet(msa_fit(acc_m1a_nist_runs(name), type = "numeric")),
                               error = function(e) e)
  }
  acc_m1a[[key]]
}

acc_m1a_4_high <- c("SmLs07", "SmLs08", "SmLs09")

test_that("K-M1a-4: the dataset lists of ANK-TOL.nist_digits match the difficulty classes of the criterion and the files of ANK-14", {
  low <- acc_m1a_nist_list("low_difficulty_datasets")
  medium <- acc_m1a_nist_list("medium_difficulty_datasets")
  expect_setequal(low, c("SiRstv", "SmLs01", "SmLs02", "SmLs03", "AtmWtAg"))
  expect_setequal(medium, c("SmLs04", "SmLs05", "SmLs06"))
  for (name in c(low, medium, acc_m1a_4_high)) {
    x <- acc_m1a_nist(name)
    expect_identical(length(unique(x$data$trt)), as.integer(x$meta$treatments), label = paste(name, "treatments"))
    expect_true(all(table(x$data$trt) == x$meta$replicates_per_cell), label = paste(name, "replicates per cell"))
  }
})

for (name in c("SiRstv", "SmLs01", "SmLs02", "SmLs03", "AtmWtAg")) {
  test_that(sprintf("K-M1a-4: %s (lower difficulty): REML residual variance and item component within the relative tolerance of ANK-TOL.nist_digits (ankerRef: ANK-14)", name), {
    expect_true(name %in% acc_m1a_nist_list("low_difficulty_datasets"))
    cert <- acc_m1a_nist_certified(name)
    fit <- acc_m1a_4_fit(name)
    expect_false(inherits(fit, "error"), label = paste(name, "fits without error:", if (inherits(fit, "error")) conditionMessage(fit) else ""))
    if (inherits(fit, "error")) return(invisible())
    v <- acc_m1a_components(fit)
    expect_setequal(names(v), c("item", "Residual"))
    tol <- acc_m1a_tol("nist_digits", "low_difficulty_rel_tol")
    for (k in names(cert)) {
      expect_true(k %in% names(v), label = paste(name, "has the component", k))
      if (k %in% names(v)) acc_m1a_expect_relative(v[[k]], cert[[k]], tol, paste(name, k, "against the certified value"))
    }
  })
}

for (name in c("SmLs04", "SmLs05", "SmLs06")) {
  test_that(sprintf("K-M1a-4: %s (average difficulty): LRE of msa_fit at most the margin of ANK-TOL.nist_digits below the LRE of stats::aov (ankerRef: ANK-14)", name), {
    expect_true(name %in% acc_m1a_nist_list("medium_difficulty_datasets"))
    cert <- acc_m1a_nist_certified(name)
    ref <- acc_m1a_nist_aov(name)
    margin <- acc_m1a_lre_margin()
    fit <- acc_m1a_4_fit(name)
    expect_false(inherits(fit, "error"), label = paste(name, "fits without error:", if (inherits(fit, "error")) conditionMessage(fit) else ""))
    if (inherits(fit, "error")) return(invisible())
    v <- acc_m1a_components(fit)
    for (k in names(cert)) {
      expect_true(k %in% names(v) && is.finite(v[[k]]), label = paste(name, k, "is a finite component"))
      if (!(k %in% names(v)) || !is.finite(v[[k]])) next
      lre_fit <- acc_m1a_lre(v[[k]], cert[[k]])
      lre_aov <- acc_m1a_lre(ref[[k]], cert[[k]])
      expect_false(is.na(lre_aov), label = paste(name, k, "LRE of stats::aov"))
      expect_gte(lre_fit, lre_aov - margin,
                 label = sprintf("%s %s: LRE msa_fit %.2f (aov %.2f)", name, k, lre_fit, lre_aov),
                 expected.label = sprintf("LRE aov - %g", margin))
    }
  })
}

test_that("K-M1a-4: SmLs07-SmLs09 (higher difficulty) are reported, not judged: certified values and data are readable (ankerRef: ANK-14)", {
  for (name in acc_m1a_4_high) {
    cert <- acc_m1a_nist_certified(name)
    ref <- acc_m1a_nist_aov(name)
    expect_true(all(is.finite(cert)) && all(is.finite(ref)), label = paste(name, "certified and aov values"))
    fit <- acc_m1a_4_fit(name)
    lre <- if (inherits(fit, "error")) c(Residual = NA_real_, item = NA_real_) else {
      v <- acc_m1a_components(fit)
      vapply(names(cert), function(k) if (k %in% names(v)) acc_m1a_lre(v[[k]], cert[[k]]) else NA_real_, numeric(1))
    }
    message(sprintf("K-M1a-4 report %s: LRE msa_fit residual %.2f, item %.2f; LRE aov residual %.2f, item %.2f%s",
                    name, lre[["Residual"]], lre[["item"]], acc_m1a_lre(ref[["Residual"]], cert[["Residual"]]),
                    acc_m1a_lre(ref[["item"]], cert[["item"]]),
                    if (inherits(fit, "error")) paste0(" (msa_fit error: ", conditionMessage(fit), ")") else ""))
  }
})

test_that("K-M1a-4: vignettes/validation.Rmd reports the LRE of msa_fit and of stats::aov for both quantities per dataset SmLs04-SmLs09", {
  k <- acc_m1a_knit_validation()
  expect_null(k$error)
  tabs <- acc_m1a_tables(acc_m1a_unfence(k$lines))
  # Tables with at least one column whose header names the LRE.
  lre_tabs <- Filter(function(t) any(grepl("LRE", names(t), fixed = TRUE)), tabs)
  expect_true(length(lre_tabs) >= 1L, label = "the knitted vignette holds a table with an LRE column")
  text <- paste(c(unlist(lapply(lre_tabs, names)), unlist(lre_tabs)), collapse = " ")
  expect_match(text, "msa_fit", fixed = TRUE)
  expect_match(text, "aov", fixed = TRUE)
  for (name in c(acc_m1a_nist_list("medium_difficulty_datasets"), acc_m1a_4_high)) {
    # LRE cells (number, Inf or NA) in the rows that name the dataset.
    entries <- unlist(lapply(lre_tabs, function(t) {
      hit <- apply(t, 1L, function(r) any(grepl(paste0("\\b", name, "\\b"), r)))
      cols <- grep("LRE", names(t), fixed = TRUE)
      cells <- unlist(t[hit, cols, drop = FALSE])
      cells[grepl("^[-+]?([0-9]+\\.?[0-9]*|\\.[0-9]+)([eE][-+]?[0-9]+)?$|^[-+]?Inf$|^NA$", trimws(cells))]
    }))
    expect_gte(length(entries), 4L,
               label = paste(name, ": LRE entries in LRE columns (msa_fit and aov, residual and item)"))
  }
})
