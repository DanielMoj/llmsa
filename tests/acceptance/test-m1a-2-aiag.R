# K-M1a-2: the ANOVA example of the AIAG manual (data sheet 10 parts x 3
# appraisers x 3 trials, reference/quellen/data/aiag/anova_example.csv; item =
# part, prompt = appraiser, replicate = trial) is reproduced with
# msa_fit(..., interactions = FALSE) and msa_grr() to the published digits:
# EV, AV, GRR, PV, TV, % study variation and % contribution per source, ndc
# (ankerRef: ANK-10; tolerances as stated in ANK-10 from ANK-TOL.reml_anova and
# the printed digits, ACC-10). With interactions = TRUE the deviation from the
# manual (interaction pooled) is reported, not judged. A missing or altered
# data file fails the test.

acc_m1a_2_keys <- c("EV", "AV", "GRR", "PV")

test_that("K-M1a-2: the local data sheet is the AIAG example and reproduces Tab. III-B 7 (ankerRef: ANK-10)", {
  d <- acc_m1a_aiag()
  design <- acc_m1a_value("ANK-10", "design")
  expect_identical(length(unique(d$part)), as.integer(design$parts))
  expect_identical(length(unique(d$appraiser)), as.integer(design$appraisers))
  expect_identical(length(unique(d$trial)), as.integer(design$trials))
  expect_true(all(table(d$part, d$appraiser) == design$trials))

  a <- acc_m1a_value("ANK-10", "anova_table")
  x <- data.frame(part = factor(d$part), appraiser = factor(d$appraiser), value = d$value)
  tab <- summary(stats::aov(value ~ part * appraiser, data = x))[[1]]
  rownames(tab) <- trimws(rownames(tab))
  rows <- c(parts = "part", appraiser = "appraiser", appraiser_by_part = "part:appraiser", equipment = "Residuals")
  half_ss <- 0.5 * 10^(-as.numeric(a$decimals$ss))
  half_ms <- 0.5 * 10^(-as.numeric(a$decimals$ms))
  for (k in names(rows)) {
    expect_identical(as.integer(tab[rows[[k]], "Df"]), as.integer(a[[k]]$df), label = paste("df", k))
    expect_lte(abs(tab[rows[[k]], "Sum Sq"] - a[[k]]$ss), half_ss, label = paste("SS", k))
    expect_lte(abs(tab[rows[[k]], "Mean Sq"] - a[[k]]$ms), half_ms, label = paste("MS", k))
  }
  expect_lte(abs(sum(tab[["Sum Sq"]]) - a$total$ss), half_ss, label = "SS total")
  expect_identical(as.integer(sum(tab[["Df"]])), as.integer(a$total$df))
})

test_that("K-M1a-2: msa_fit(interactions = FALSE) and msa_grr() reproduce EV, AV, GRR, PV, TV, % study variation, % contribution and ndc of the AIAG example (ankerRef: ANK-10)", {
  pub <- acc_anchor("ANK-10")$value
  fit <- acc_m1a_quiet(msa_fit(acc_m1a_aiag_runs(), type = "numeric", interactions = FALSE))
  g <- msa_grr(fit)
  tol_c <- acc_m1a_tol("reml_anova", "component_tol_fraction_of_total_variance")
  rel <- acc_m1a_tol("reml_anova", "derived_rel_tol")
  total <- as.numeric(pub$variance$GRR) + as.numeric(pub$variance$PV)
  half <- function(group, key) 0.5 * 10^(-as.numeric(pub$decimals[[group]][[key]]))

  for (k in acc_m1a_2_keys) {
    v <- acc_m1a_cell(g, k, "variance")
    expect_lte(abs(v - pub$variance[[k]]), tol_c * total,
               label = sprintf("variance %s: observed %.8f, published %s", k, v, format(pub$variance[[k]])))
    s <- acc_m1a_cell(g, k, "sd")
    expect_lte(abs(s^2 - pub$sd[[k]]^2), tol_c * total,
               label = sprintf("sd %s (on the variance scale): observed %.8f, published %s", k, s, format(pub$sd[[k]])))
    for (col in c("pct_study_var", "pct_contribution")) {
      p <- acc_m1a_cell(g, k, col)
      expect_lte(abs(p - pub[[col]][[k]]), half(col, k) + rel * abs(pub[[col]][[k]]),
                 label = sprintf("%s %s: observed %.4f, published %s", col, k, p, format(pub[[col]][[k]])))
    }
  }
  tv <- acc_m1a_cell(g, "TV", "sd")
  expect_lte(abs(tv - pub$sd$TV), half("sd", "TV") + tol_c * total / (2 * pub$sd$TV),
             label = sprintf("TV: observed %.6f, published %s", tv, format(pub$sd$TV)))
  expect_lte(abs(acc_m1a_cell(g, "TV", "pct_study_var") - pub$pct_study_var$TV), half("pct_study_var", "TV"))
  ndc <- acc_m1a_summary(g, "ndc")
  expect_true(isTRUE(ndc == pub$ndc), label = sprintf("ndc %s equals the published %s", format(ndc), format(pub$ndc)))
})

test_that("K-M1a-2: with interactions = TRUE the deviation from the manual is reported, not judged (ankerRef: ANK-10)", {
  pub <- acc_anchor("ANK-10")$value
  fit <- acc_m1a_quiet(msa_fit(acc_m1a_aiag_runs(), type = "numeric", interactions = TRUE))
  g <- msa_grr(fit)
  v <- acc_m1a_components(fit)
  expect_true(all(is.finite(v)) && all(v >= 0))
  report <- data.frame(source = acc_m1a_2_keys,
                       published_sd = vapply(acc_m1a_2_keys, function(k) as.numeric(pub$sd[[k]]), numeric(1)),
                       observed_sd = vapply(acc_m1a_2_keys, function(k) acc_m1a_cell(g, k, "sd"), numeric(1)),
                       published_pct_study_var = vapply(acc_m1a_2_keys, function(k) as.numeric(pub$pct_study_var[[k]]), numeric(1)),
                       observed_pct_study_var = vapply(acc_m1a_2_keys, function(k) acc_m1a_cell(g, k, "pct_study_var"), numeric(1)))
  report$deviation_sd <- report$observed_sd - report$published_sd
  expect_true(all(is.finite(unlist(report[-1]))))
  expect_true(is.finite(acc_m1a_summary(g, "ndc")))
  message("K-M1a-2 report, AIAG example with interactions = TRUE (manual: interaction pooled; ndc ",
          format(acc_m1a_summary(g, "ndc")), " vs ", format(pub$ndc), "):\n",
          paste(utils::capture.output(print(report, row.names = FALSE, digits = 6)), collapse = "\n"))
})
