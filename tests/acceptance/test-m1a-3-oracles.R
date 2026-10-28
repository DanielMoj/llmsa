# K-M1a-3: cross-checks against established packages called at test time on the
# same data (oracles, no frozen values):
# (a) VCA::remlVCA on ic50_demo and on the AIAG data and VCA::anovaVCA on the
#     AIAG data give the components of msa_fit (ANK-TOL.oracle, component value
#     as a fraction of the oracle's total variance); VCA::anovaVCA on ic50_demo
#     is only reported, because the plan is unbalanced and ANOVA and REML
#     estimators differ there (Formelsammlung §2; ADR-016 E2);
# (b) SixSigma::ss.rr on ss.data.rr (part -> item, appraiser -> prompt,
#     run -> replicate, interaction in the model) gives the variance
#     components and % study variation (ANK-TOL.oracle) and the ndc of msa_grr;
# (c) msa_fit on Penicillin reproduces the REML estimates published by Bates
#     (2010, ch. 2, section 2.1.2) (ankerRef: ANK-13; tolerance
#     ANK-TOL.reml_anova times the sum of the printed variances, on the variance
#     scale; ADR-016 E1).
# Readings: ACC-3 (ss.rr), ACC-4 (models on the AIAG data), ACC-18 (Penicillin).

# Components and total variance of a VCA oracle for the model of msa_fit.
acc_m1a_3_oracle <- function(oracle, runs, interactions, label) {
  d <- acc_m1a_frame(runs)
  terms <- acc_m1a_terms(d, interactions)
  labels <- vapply(terms, acc_m1a_label, character(1))
  form <- stats::as.formula(paste("y ~", paste(labels, collapse = " + ")))
  res <- switch(oracle,
    remlVCA = VCA::remlVCA(form, Data = d, VarVC = FALSE, quiet = TRUE),
    anovaVCA = VCA::anovaVCA(form, Data = d, quiet = TRUE))
  tab <- res$aov.tab
  expect_true(all(c("total", labels, "error") %in% rownames(tab)), label = paste(label, ": VCA rows"))
  list(ref = c(stats::setNames(as.numeric(tab[labels, "VC"]), labels), Residual = as.numeric(tab["error", "VC"])),
       total = as.numeric(tab["total", "VC"]))
}

acc_m1a_3_vca <- function(oracle, runs, interactions, label) {
  o <- acc_m1a_3_oracle(oracle, runs, interactions, label)
  fit <- acc_m1a_quiet(msa_fit(runs, type = "numeric", interactions = interactions))
  acc_m1a_expect_components(acc_m1a_components(fit), o$ref,
                            acc_m1a_tol("oracle", "variance_component_tol_fraction_of_total_variance"),
                            o$total, paste0(label, " against VCA::", oracle))
}

test_that("K-M1a-3: VCA::remlVCA on ic50_demo gives the components of msa_fit (ankerRef: ANK-TOL.oracle)", {
  acc_m1a_3_vca("remlVCA", acc_m1a_dataset("ic50_demo"), interactions = TRUE, label = "ic50_demo")
})

test_that("K-M1a-3: VCA::anovaVCA on ic50_demo is reported, not judged, because the plan is unbalanced (ADR-016 E2)", {
  runs <- acc_m1a_dataset("ic50_demo")
  d <- acc_m1a_frame(runs)
  # Reason for reporting only (docs/02 K-M1a-3 (a), Formelsammlung §2): unequal
  # numbers of values per observed cell.
  counts <- table(interaction(d[c("block", "item", "prompt", "model")], drop = TRUE))
  expect_true(min(counts) < max(counts),
              label = sprintf("precondition: ic50_demo is unbalanced (%d to %d values per cell)", min(counts), max(counts)))
  o <- acc_m1a_3_oracle("anovaVCA", runs, interactions = TRUE, label = "ic50_demo")
  v <- acc_m1a_components(acc_m1a_quiet(msa_fit(runs, type = "numeric", interactions = TRUE)))
  expect_setequal(names(v), names(o$ref))
  expect_true(all(is.finite(o$ref)) && is.finite(o$total) && all(is.finite(v)))
  s <- intersect(names(o$ref), names(v))
  report <- data.frame(source = s, anovaVCA = unname(o$ref[s]), msa_fit = unname(v[s]),
                       deviation_sigma2_TV = unname((v[s] - o$ref[s]) / o$total))
  message("K-M1a-3 report, VCA::anovaVCA on ic50_demo (unbalanced; ANOVA type I and REML estimators differ, ",
          "Formelsammlung §2; no criterion, ADR-016 E2):\n",
          paste(utils::capture.output(print(report, row.names = FALSE, digits = 6)), collapse = "\n"))
})

test_that("K-M1a-3: VCA::remlVCA and VCA::anovaVCA on the AIAG data give the components of msa_fit (ankerRef: ANK-TOL.oracle, ANK-10)", {
  runs <- acc_m1a_aiag_runs()
  acc_m1a_3_vca("remlVCA", runs, interactions = FALSE, label = "AIAG, interaction pooled")
  acc_m1a_3_vca("anovaVCA", runs, interactions = FALSE, label = "AIAG, interaction pooled")
  acc_m1a_3_vca("remlVCA", runs, interactions = TRUE, label = "AIAG, with interaction")
})

test_that("K-M1a-3: SixSigma::ss.rr on ss.data.rr gives the variance components, % study variation and ndc of msa_grr (ankerRef: ANK-TOL.oracle; reading ACC-3)", {
  e <- new.env(parent = emptyenv())
  utils::data("ss.data.rr", package = "SixSigma", envir = e)
  x <- e$ss.data.rr
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  old <- options(show.signif.stars = getOption("show.signif.stars"))
  on.exit(options(old), add = TRUE)
  utils::capture.output(res <- SixSigma::ss.rr(var = "time1", part = "prototype", appr = "operator",
                                               data = x, print_plot = FALSE))
  vc <- res$varComp
  rownames(vc) <- trimws(rownames(vc))
  ref <- c(Residual = vc["Repeatability", "VarComp"], prompt = vc["operator", "VarComp"],
           "item:prompt" = if ("prototype:operator" %in% rownames(vc)) vc["prototype:operator", "VarComp"] else 0,
           item = vc["Part-To-Part", "VarComp"])
  total <- vc["Total Variation", "VarComp"]
  expect_true(all(is.finite(ref)) && is.finite(total))

  runs <- acc_m1a_runs(item = x$prototype, prompt = x$operator, model = "M1", rep = as.integer(x$run), value = x$time1)
  fit <- acc_m1a_quiet(msa_fit(runs, type = "numeric", interactions = TRUE))
  acc_m1a_expect_components(acc_m1a_components(fit), ref,
                            acc_m1a_tol("oracle", "variance_component_tol_fraction_of_total_variance"),
                            total, "ss.data.rr against SixSigma::ss.rr")

  # % study variation from the unrounded standard deviations of ss.rr (its
  # %StudyVar column is rounded to two decimals).
  sv <- res$studyVar
  rownames(sv) <- trimws(rownames(sv))
  pct <- 100 * sv[, "StdDev"] / sv["Total Variation", "StdDev"]
  g <- msa_grr(fit)
  rel <- acc_m1a_tol("oracle", "derived_rel_tol")
  pairs <- c(GRR = "Total Gage R&R", EV = "Repeatability", AV = "Reproducibility", prompt = "operator", PV = "Part-To-Part")
  for (k in names(pairs)) {
    acc_m1a_expect_relative(acc_m1a_cell(g, k, "pct_study_var"), pct[[pairs[[k]]]], rel,
                            paste("% study variation", k, "against ss.rr", pairs[[k]]))
  }
  ndc <- acc_m1a_summary(g, "ndc")
  expect_true(isTRUE(ndc == res$ncat), label = sprintf("ndc %s equals ss.rr ncat %s", format(ndc), format(res$ncat)))
})

test_that("K-M1a-3: msa_fit on Penicillin reproduces the REML estimates published by Bates (2010, ch. 2, section 2.1.2) (ankerRef: ANK-13)", {
  pub_var <- acc_m1a_value("ANK-13", "variance")
  pub_sd <- acc_m1a_value("ANK-13", "sd")
  design <- acc_m1a_value("ANK-13", "design")
  # published group -> source of msa_fit (item = sample, prompt = plate)
  map <- c(plate = "prompt", sample = "item", residual = "Residual")
  expect_setequal(names(pub_var), names(map))
  expect_setequal(names(pub_sd), names(map))
  # sigma2_TV = sum of the printed variances; the tolerance applies on the
  # variance scale, printed standard deviations squared (ADR-016 E1)
  total <- sum(vapply(names(map), function(k) as.numeric(pub_var[[k]]), numeric(1)))
  tol <- acc_m1a_tol("reml_anova", "component_tol_fraction_of_total_variance")

  p <- acc_m1a_penicillin()
  expect_identical(nrow(p), as.integer(design$observations))
  expect_identical(nlevels(p$plate), as.integer(design$plate))
  expect_identical(nlevels(p$sample), as.integer(design$sample))
  runs <- acc_m1a_penicillin_runs()

  # Second proof of the anchor (ADR-016 E1): the design is balanced, the ANOVA
  # estimators of the same data are nonnegative and agree with the printed
  # estimates within the same tolerance.
  d <- acc_m1a_frame(runs)
  anova <- acc_m1a_anova_estimates(d, acc_m1a_terms(d, interactions = FALSE))
  expect_true(all(anova >= 0), label = "precondition: all ANOVA estimators of Penicillin are nonnegative")
  for (k in names(map)) {
    expect_lte(abs(anova[[map[[k]]]] - as.numeric(pub_var[[k]])), tol * total,
               label = sprintf("precondition: ANOVA estimator %s %.8f against the printed variance %s", k,
                               anova[[map[[k]]]], format(pub_var[[k]])))
    expect_lte(abs(anova[[map[[k]]]] - as.numeric(pub_sd[[k]])^2), tol * total,
               label = sprintf("precondition: ANOVA estimator %s %.8f against the printed standard deviation %s squared",
                               k, anova[[map[[k]]]], format(pub_sd[[k]])))
  }

  v <- acc_m1a_components(acc_m1a_quiet(msa_fit(runs, type = "numeric", interactions = FALSE)))
  expect_setequal(names(v), unname(map))
  for (k in names(map)) {
    if (!map[[k]] %in% names(v)) next
    obs <- v[[map[[k]]]]
    dev_var <- abs(obs - as.numeric(pub_var[[k]]))
    expect_lte(dev_var, tol * total,
               label = sprintf("variance %s: observed %.8f, published %s, |deviation| = %.3g sigma2_TV", k, obs,
                               format(pub_var[[k]]), dev_var / total),
               expected.label = sprintf("%g sigma2_TV", tol))
    dev_sd <- abs(obs - as.numeric(pub_sd[[k]])^2)
    expect_lte(dev_sd, tol * total,
               label = sprintf("standard deviation %s on the variance scale: observed %.8f, published %s squared, |deviation| = %.3g sigma2_TV",
                               k, sqrt(obs), format(pub_sd[[k]]), dev_sd / total),
               expected.label = sprintf("%g sigma2_TV", tol))
  }
})
