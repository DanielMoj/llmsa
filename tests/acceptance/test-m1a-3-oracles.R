# K-M1a-3: cross-checks against established packages called at test time on the
# same data (oracles, no frozen values):
# (a) VCA::remlVCA and VCA::anovaVCA on ic50_demo and on the AIAG data give the
#     components of msa_fit (ANK-TOL.oracle, component value as a fraction of
#     the oracle's total variance);
# (b) SixSigma::ss.rr on ss.data.rr (part -> item, appraiser -> prompt,
#     run -> replicate, interaction in the model) gives the variance
#     components and % study variation (ANK-TOL.oracle) and the ndc of msa_grr;
# (c) msa_fit on Penicillin reproduces the REML estimates published by Bates et
#     al. (2015) (ankerRef: ANK-13).
# Readings and open points: ACC-1 (ANK-13), ACC-2 (anovaVCA on ic50_demo),
# ACC-3 (ss.rr), ACC-4 (models on the AIAG data).

acc_m1a_3_vca <- function(oracle, runs, interactions, label) {
  d <- acc_m1a_frame(runs)
  terms <- acc_m1a_terms(d, interactions)
  labels <- vapply(terms, acc_m1a_label, character(1))
  form <- stats::as.formula(paste("y ~", paste(labels, collapse = " + ")))
  res <- switch(oracle,
    remlVCA = VCA::remlVCA(form, Data = d, VarVC = FALSE, quiet = TRUE),
    anovaVCA = VCA::anovaVCA(form, Data = d, quiet = TRUE))
  tab <- res$aov.tab
  expect_true(all(c("total", labels, "error") %in% rownames(tab)), label = paste(label, ": VCA rows"))
  ref <- c(stats::setNames(as.numeric(tab[labels, "VC"]), labels), Residual = as.numeric(tab["error", "VC"]))
  total <- as.numeric(tab["total", "VC"])
  fit <- acc_m1a_quiet(msa_fit(runs, type = "numeric", interactions = interactions))
  acc_m1a_expect_components(acc_m1a_components(fit), ref,
                            acc_m1a_tol("oracle", "variance_component_tol_fraction_of_total_variance"),
                            total, paste0(label, " against VCA::", oracle))
}

test_that("K-M1a-3: VCA::remlVCA on ic50_demo gives the components of msa_fit (ankerRef: ANK-TOL.oracle)", {
  acc_m1a_3_vca("remlVCA", acc_m1a_dataset("ic50_demo"), interactions = TRUE, label = "ic50_demo")
})

test_that("K-M1a-3: VCA::anovaVCA on ic50_demo gives the components of msa_fit (ankerRef: ANK-TOL.oracle; see ACC-2)", {
  acc_m1a_3_vca("anovaVCA", acc_m1a_dataset("ic50_demo"), interactions = TRUE, label = "ic50_demo")
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

test_that("K-M1a-3: msa_fit on Penicillin reproduces the REML estimates published by Bates et al. (2015) (ankerRef: ANK-13; open ACC-1)", {
  a <- acc_anchor("ANK-13")
  pub <- a$value$sd
  dec <- a$value$decimals$sd
  expect_true(!is.null(pub) && !is.null(dec), label = "ANK-13 holds value$sd and value$decimals$sd (ACC-1)")
  e <- new.env(parent = emptyenv())
  utils::data("Penicillin", package = "lme4", envir = e)
  p <- e$Penicillin
  runs <- acc_m1a_runs(item = p$sample, prompt = p$plate, model = "M1", rep = 1L, value = p$diameter)
  v <- acc_m1a_components(acc_m1a_quiet(msa_fit(runs, type = "numeric", interactions = FALSE)))
  map <- c(plate = "prompt", sample = "item", residual = "Residual")
  for (k in names(map)) {
    obs <- sqrt(v[[map[[k]]]])
    expect_lte(abs(obs - as.numeric(pub[[k]])), 0.5 * 10^(-as.numeric(dec[[k]])),
               label = sprintf("standard deviation %s: observed %.6f, published %s", k, obs, format(pub[[k]])))
  }
})
