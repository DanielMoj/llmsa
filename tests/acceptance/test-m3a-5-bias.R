# K-M3a-5: bias: mean, t interval and p value from msa_bias() reproduce the
# AIAG example Table III-B 2 (ankerRef: ANK-75, data under
# reference/quellen/data/aiag/bias_study.csv) and agree with stats::t.test on
# the same deviations (ANK-TOL.package_compare); the same per prompt x model.
# Two independent pieces of evidence: the printed values of the manual and
# stats::t.test, both also against the mini-reference of AIAG (2010),
# p. 88-89 (setup-m3a.R). Table III-B 2 prints no p value; the printed t
# statistic (two decimals) and df bound it (ANK-75, p_value_note). Fields of
# v0.1.0: overall (n, bias, sd, lower, upper, p_value) and by_condition.

acc_m3a_5_fields <- c("n", "bias", "sd", "lower", "upper", "p_value")

# stats::t.test on deviations d as a vector in the order of acc_m3a_5_fields.
acc_m3a_5_ttest <- function(d, level) {
  t <- stats::t.test(d, conf.level = level)
  c(n = length(d), bias = unname(t$estimate), sd = stats::sd(d), lower = t$conf.int[1], upper = t$conf.int[2], p_value = t$p.value)
}

acc_m3a_5_row <- function(b, prompt, model) {
  bc <- b$by_condition
  if (!is.data.frame(bc) || !all(c("prompt_id", "model_id", acc_m3a_5_fields) %in% names(bc))) {
    stop("acceptance: by_condition of msa_bias() lacks prompt_id, model_id or ", paste(acc_m3a_5_fields, collapse = ", "), call. = FALSE)
  }
  i <- which(bc$prompt_id == prompt & bc$model_id == model)
  if (length(i) != 1L) stop("acceptance: by_condition has no single row for ", prompt, " x ", model, call. = FALSE)
  unlist(bc[i, acc_m3a_5_fields])
}

acc_m3a_5_expect_table <- function(obs, d, label) {
  p <- acc_m3a_value("ANK-75")
  printed <- c(bias = p$average_bias, sd = p$sigma_r, lower = p$ci95$lower, upper = p$ci95$upper)
  decimals <- c(bias = p$average_bias_decimals, sd = p$sigma_r_decimals, lower = p$ci_decimals, upper = p$ci_decimals)
  expect_identical(as.integer(obs[["n"]]), as.integer(p$n), label = sprintf("%s: n", label))
  for (k in names(printed)) {
    expect_lte(abs(obs[[k]] - printed[[k]]), acc_m3a_printed_tol(decimals[[k]]),
               label = sprintf("%s: %s %.6f, printed %s", label, k, obs[[k]], format(printed[[k]])))
  }
  se <- obs[["sd"]] / sqrt(obs[["n"]])
  expect_lte(abs(se - p$sigma_b), acc_m3a_printed_tol(p$sigma_b_decimals), label = sprintf("%s: sigma_b = sd / sqrt(n)", label))
  expect_lte(abs(obs[["bias"]] / se - p$t_statistic), acc_m3a_printed_tol(p$t_statistic_decimals), label = sprintf("%s: t", label))
  expect_lte(abs((obs[["upper"]] - obs[["bias"]]) / se - p$t_quantile), acc_m3a_printed_tol(p$t_quantile_decimals),
             label = sprintf("%s: t quantile of the interval (df = n - 1 = %d)", label, as.integer(p$df)))
  t_hi <- abs(p$t_statistic) + 0.5 * 10^(-p$t_statistic_decimals)
  t_lo <- abs(p$t_statistic) - 0.5 * 10^(-p$t_statistic_decimals)
  expect_true(obs[["p_value"]] >= 2 * stats::pt(-t_hi, p$df) && obs[["p_value"]] <= 2 * stats::pt(-t_lo, p$df),
              label = sprintf("%s: p value %.6f lies in [%.6f, %.6f], the range of the printed t = %s with df = %d", label, obs[["p_value"]],
                              2 * stats::pt(-t_hi, p$df), 2 * stats::pt(-t_lo, p$df), format(p$t_statistic), as.integer(p$df)))
  tt <- acc_m3a_5_ttest(d, 1 - p$alpha)
  for (k in acc_m3a_5_fields) {
    expect_lte(abs(obs[[k]] - tt[[k]]), acc_m3a_pkg(), label = sprintf("%s: %s equals stats::t.test (%.10f)", label, k, tt[[k]]))
  }
}

test_that("K-M3a-5: msa_bias() reproduces Table III-B 2 of the AIAG manual: mean bias, t interval and p value of the bias study, and agrees with stats::t.test on the same deviations (ankerRef: ANK-75)", {
  d <- acc_m3a_aiag("ANK-75")
  ref <- acc_m3a_numeric_reference(d)
  expect_identical(unique(as.numeric(d$reference)), as.numeric(acc_m3a_value("ANK-75", "reference_value")))
  b <- msa_bias(acc_m3a_numeric_runs(d), reference = ref, level = 1 - acc_m3a_value("ANK-75", "alpha"))
  dev <- as.numeric(d$value) - as.numeric(d$reference)
  acc_m3a_5_expect_table(b$overall[acc_m3a_5_fields], dev, "overall")
  acc_m3a_5_expect_table(acc_m3a_5_row(b, "operator", "gage"), dev, "by_condition")
  mini <- acc_m3a_t_ref(dev, 1 - acc_m3a_value("ANK-75", "alpha"))
  for (k in acc_m3a_5_fields) expect_lte(abs(b$overall[[k]] - mini[[k]]), acc_m3a_pkg(), label = sprintf("overall %s equals the mini-reference", k))
})

test_that("K-M3a-5: per prompt x model, msa_bias() reproduces Table III-B 2 in the condition that holds the AIAG data and equals stats::t.test in every condition (ankerRef: ANK-75)", {
  d <- acc_m3a_aiag("ANK-75")
  aiag <- data.frame(item_id = paste0("part", d$part), prompt_id = "P1", model_id = "M1", rep = d$trial,
                     value = as.numeric(d$value), reference = as.numeric(d$reference), stringsAsFactors = FALSE)
  other <- acc_m3a_with_seed(3501L, {
    g <- expand.grid(rep = 1:8, item = 1:3, prompt = c("P1", "P2"), model = c("M1", "M2"), stringsAsFactors = FALSE)
    g <- g[!(g$prompt == "P1" & g$model == "M1"), ]
    x <- c(2, 5, 9)
    data.frame(item_id = paste0("x", g$item), prompt_id = g$prompt, model_id = g$model, rep = g$rep,
               value = x[g$item] + ifelse(g$model == "M2", 0.3, -0.1) + stats::rnorm(nrow(g), 0, 0.2),
               reference = x[g$item], stringsAsFactors = FALSE)
  })
  all <- rbind(aiag, other)
  runs <- acc_m3a_runs(all$item_id, all$prompt_id, all$model_id, all$rep, all$value)
  ref <- unique(all[, c("item_id", "reference")])
  b <- msa_bias(runs, reference = ref)
  dev <- all$value - all$reference
  acc_m3a_5_expect_table(acc_m3a_5_row(b, "P1", "M1"), dev[all$prompt_id == "P1" & all$model_id == "M1"], "P1 x M1 (AIAG)")
  for (pm in list(c("P1", "M2"), c("P2", "M1"), c("P2", "M2"))) {
    obs <- acc_m3a_5_row(b, pm[1], pm[2])
    tt <- acc_m3a_5_ttest(dev[all$prompt_id == pm[1] & all$model_id == pm[2]], 0.95)
    for (k in acc_m3a_5_fields) {
      expect_lte(abs(obs[[k]] - tt[[k]]), acc_m3a_pkg(), label = sprintf("%s x %s: %s %.10f, stats::t.test %.10f", pm[1], pm[2], k, obs[[k]], tt[[k]]))
    }
  }
  expect_identical(nrow(b$by_condition), 4L)
})

test_that("K-M3a-5: on seeded data with missing values, mean, t interval and p value of msa_bias() equal stats::t.test on the valid deviations, overall and per prompt x model, at the levels 0.95 and 0.90 (ANK-TOL.package_compare)", {
  dat <- acc_m3a_with_seed(3502L, {
    g <- expand.grid(rep = 1:3, model = c("M1", "M2", "M3"), prompt = c("P1", "P2"), item = 1:12, stringsAsFactors = FALSE)
    x <- stats::rnorm(12, 10, 2)
    g$reference <- x[g$item]
    g$value <- g$reference + 0.15 + stats::rnorm(nrow(g), 0, 0.3)
    g$value[sample.int(nrow(g), 20)] <- NA
    g
  })
  runs <- acc_m3a_runs(paste0("i", dat$item), dat$prompt, dat$model, dat$rep, dat$value)
  ref <- unique(data.frame(item_id = paste0("i", dat$item), reference = dat$reference, stringsAsFactors = FALSE))
  ok <- !is.na(dat$value)
  dev <- dat$value - dat$reference
  for (level in c(0.95, 0.90)) {
    b <- msa_bias(runs, reference = ref, level = level)
    tt <- acc_m3a_5_ttest(dev[ok], level)
    for (k in acc_m3a_5_fields) {
      expect_lte(abs(b$overall[[k]] - tt[[k]]), acc_m3a_pkg(), label = sprintf("level %.2f, overall %s", level, k))
    }
    for (pr in c("P1", "P2")) for (mo in c("M1", "M2", "M3")) {
      s <- ok & dat$prompt == pr & dat$model == mo
      obs <- acc_m3a_5_row(b, pr, mo)
      tt <- acc_m3a_5_ttest(dev[s], level)
      for (k in acc_m3a_5_fields) {
        expect_lte(abs(obs[[k]] - tt[[k]]), acc_m3a_pkg(), label = sprintf("level %.2f, %s x %s: %s", level, pr, mo, k))
      }
    }
  }
})
