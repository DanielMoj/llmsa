# K-M3a-6: linearity: msa_bias() reproduces with the handbook computation
# (regression of all g·m single values, gm - 2 degrees of freedom) the AIAG
# example Table III-B 4/5 (ankerRef: ANK-76; data under
# reference/quellen/data/aiag/linearity_study.csv): slope, intercept, R²,
# t values, t quantile; it also gives the regression on the item means (g - 2
# degrees of freedom) with R² and t values (ANK-76), computes the confidence
# band of the line and the criterion "bias = 0 lies within the band", carries
# the verdict with the handbook computation and names the difference of both
# computations in the object and in the report (Formelsammlung Nr. 2).
# Two independent pieces of evidence: the printed values of the manual (and of
# Formelsammlung §6 for the item means) and stats::lm, both also against the
# mini-reference of AIAG (2010), p. 96-98 (setup-m3a.R).
# Result fields (ACC-12, ACC-13): linearity (v0.1.0: intercept, slope,
# slope_p_value; new: r_squared as a proportion, t_intercept, t_slope, df,
# t_quantile), linearity_item_means (intercept, slope, r_squared, t_intercept,
# t_slope, df), linearity_band (data.frame reference, fit, lower, upper with a
# row for every reference value of the items), linearity_in_band (bias = 0
# within the band over the whole range of the reference values),
# linearity_verdict ("acceptable" or "unacceptable") and linearity_note.

acc_m3a_6_handbook_keys <- c("intercept", "slope", "slope_p_value", "r_squared", "t_intercept", "t_slope", "df", "t_quantile")
acc_m3a_6_means_keys <- c("intercept", "slope", "r_squared", "t_intercept", "t_slope", "df")

acc_m3a_6_lm <- function(x, y) {
  f <- stats::lm(y ~ x)
  s <- summary(f)
  c(intercept = unname(stats::coef(f)[1]), slope = unname(stats::coef(f)[2]), slope_p_value = s$coefficients[2, 4],
    r_squared = s$r.squared, t_intercept = s$coefficients[1, 3], t_slope = s$coefficients[2, 3], df = f$df.residual)
}

# Single valid deviations and item means of a data frame with item_id,
# reference and value.
acc_m3a_6_parts <- function(dat) {
  ok <- !is.na(dat$value)
  dev <- dat$value[ok] - dat$reference[ok]
  list(x = dat$reference[ok], dev = dev, means = acc_m3a_item_means(dat$item_id[ok], dat$reference[ok], dev))
}

acc_m3a_6_bias <- function(dat, level = 0.95) {
  runs <- acc_m3a_runs(dat$item_id, dat$prompt_id, dat$model_id, dat$rep, dat$value)
  msa_bias(runs, reference = unique(dat[, c("item_id", "reference")]), level = level)
}

# Five items at the reference values 2 to 10, m replicates, one prompt and one
# model; dev = item bias u + replicate pattern e.
acc_m3a_6_case <- function(x, m, dev) {
  data.frame(item_id = paste0("x", rep(seq_along(x), each = m)), prompt_id = "P1", model_id = "M1", rep = rep(seq_len(m), length(x)),
             reference = rep(x, each = m), value = rep(x, each = m) + dev, stringsAsFactors = FALSE)
}

test_that("K-M3a-6: the handbook computation of msa_bias() (all g·m single values, gm - 2 df) reproduces Table III-B 4/5 of the AIAG manual: slope, intercept, R², t values and t quantile (ankerRef: ANK-76)", {
  d <- acc_m3a_aiag("ANK-76")
  dev <- as.numeric(d$value) - as.numeric(d$reference)
  expect_lte(max(abs(as.numeric(tapply(dev, d$part, mean)) - acc_m3a_num(acc_m3a_value("ANK-76", "bias_averages")))),
             max(acc_m3a_printed_tol(acc_m3a_num(acc_m3a_value("ANK-76", "bias_averages_decimals")))),
             label = "bias averages of Table III-B 5")
  b <- msa_bias(acc_m3a_numeric_runs(d), reference = acc_m3a_numeric_reference(d), level = 1 - acc_m3a_value("ANK-76", "handbook", "alpha"))
  lin <- acc_m3a_bias_field(b, "linearity", acc_m3a_6_handbook_keys)
  hb <- acc_m3a_value("ANK-76", "handbook")
  printed <- c(slope = hb$slope, intercept = hb$intercept, r_squared = hb$r_squared, t_slope = hb$t_slope,
               t_intercept = hb$t_intercept, t_quantile = hb$t_quantile)
  decimals <- c(slope = hb$coefficient_decimals, intercept = hb$coefficient_decimals, r_squared = hb$r_squared_decimals,
                t_slope = hb$t_decimals, t_intercept = hb$t_decimals, t_quantile = hb$t_quantile_decimals)
  for (k in names(printed)) {
    expect_lte(abs(lin[[k]] - printed[[k]]), acc_m3a_printed_tol(decimals[[k]]),
               label = sprintf("handbook %s %.7f, printed %s", k, lin[[k]], format(printed[[k]])))
  }
  expect_identical(as.numeric(lin[["df"]]), as.numeric(hb$df))
  mini <- acc_m3a_lin_ref(as.numeric(d$reference), dev, 1 - hb$alpha)
  for (k in c("slope", "intercept", "r_squared", "t_slope", "t_intercept", "t_quantile")) {
    expect_lte(abs(lin[[k]] - mini[[k]]), acc_m3a_pkg(), label = sprintf("handbook %s equals the mini-reference", k))
  }
  o <- acc_m3a_6_lm(as.numeric(d$reference), dev)
  for (k in names(o)) expect_lte(abs(lin[[k]] - o[[k]]), acc_m3a_pkg(), label = sprintf("handbook %s equals stats::lm (%.10f)", k, o[[k]]))
})

test_that("K-M3a-6: msa_bias() also gives the regression on the item means (g - 2 df): R² 97.8 % and t_slope -11.52 of Formelsammlung §6 on the AIAG example (ankerRef: ANK-76), equal to stats::lm on the five bias averages", {
  d <- acc_m3a_aiag("ANK-76")
  dev <- as.numeric(d$value) - as.numeric(d$reference)
  b <- msa_bias(acc_m3a_numeric_runs(d), reference = acc_m3a_numeric_reference(d))
  im <- acc_m3a_bias_field(b, "linearity_item_means", acc_m3a_6_means_keys)
  pm <- acc_m3a_value("ANK-76", "item_means")
  printed <- c(slope = pm$slope, intercept = pm$intercept, r_squared = pm$r_squared, t_slope = pm$t_slope)
  decimals <- c(slope = pm$coefficient_decimals, intercept = pm$coefficient_decimals, r_squared = pm$r_squared_decimals,
                t_slope = pm$t_slope_decimals)
  for (k in names(printed)) {
    expect_lte(abs(im[[k]] - printed[[k]]), acc_m3a_printed_tol(decimals[[k]]),
               label = sprintf("item means %s %.7f, Formelsammlung §6 %s", k, im[[k]], format(printed[[k]])))
  }
  expect_identical(as.numeric(im[["df"]]), as.numeric(pm$df))
  means <- acc_m3a_item_means(d$part, as.numeric(d$reference), dev)
  o <- acc_m3a_6_lm(means$reference, means$bias)
  for (k in acc_m3a_6_means_keys) expect_lte(abs(im[[k]] - o[[k]]), acc_m3a_pkg(), label = sprintf("item means %s equals stats::lm (%.10f)", k, o[[k]]))
})

test_that("K-M3a-6: on seeded data (several prompts and models, missing values, unequal replicates) both regressions of msa_bias() equal stats::lm on the valid single values and on the item means (ANK-TOL.package_compare)", {
  dat <- acc_m3a_with_seed(3601L, {
    g <- expand.grid(rep = 1:3, model = c("M1", "M2"), prompt = c("P1", "P2"), item = 1:7, stringsAsFactors = FALSE)
    x <- c(1, 2.5, 3, 4.5, 6, 8, 9.5)
    u <- stats::rnorm(7, 0, 0.1)
    g$reference <- x[g$item]
    g$value <- g$reference + 0.2 - 0.03 * g$reference + u[g$item] + stats::rnorm(nrow(g), 0, 0.15)
    g$value[sample.int(nrow(g), 9)] <- NA
    data.frame(item_id = paste0("i", g$item), prompt_id = g$prompt, model_id = g$model, rep = g$rep,
               reference = g$reference, value = g$value, stringsAsFactors = FALSE)
  })
  p <- acc_m3a_6_parts(dat)
  b <- acc_m3a_6_bias(dat)
  lin <- acc_m3a_bias_field(b, "linearity", acc_m3a_6_handbook_keys)
  o <- acc_m3a_6_lm(p$x, p$dev)
  for (k in names(o)) expect_lte(abs(lin[[k]] - o[[k]]), acc_m3a_pkg(), label = sprintf("handbook %s: %.10f, stats::lm %.10f", k, lin[[k]], o[[k]]))
  expect_lte(abs(lin[["t_quantile"]] - stats::qt(0.975, length(p$dev) - 2)), acc_m3a_pkg(), label = "handbook t quantile with gm - 2 df")
  im <- acc_m3a_bias_field(b, "linearity_item_means", acc_m3a_6_means_keys)
  o <- acc_m3a_6_lm(p$means$reference, p$means$bias)
  for (k in names(o)[names(o) %in% acc_m3a_6_means_keys]) {
    expect_lte(abs(im[[k]] - o[[k]]), acc_m3a_pkg(), label = sprintf("item means %s: %.10f, stats::lm %.10f", k, im[[k]], o[[k]]))
  }
  expect_identical(as.numeric(im[["df"]]), 5)
})

test_that("K-M3a-6: the confidence band of the line and the criterion \"bias = 0 within the band\" follow AIAG (2010), p. 97-98; the verdict is carried by the handbook computation (ankerRef: ANK-76)", {
  check <- function(b, x, dev, level, label) {
    L <- acc_m3a_lin_ref(x, dev, level)
    band <- b$linearity_band
    expect_true(is.data.frame(band) && all(c("reference", "fit", "lower", "upper") %in% names(band)),
                label = sprintf("%s: linearity_band is a data.frame with reference, fit, lower, upper", label))
    if (!is.data.frame(band) || !all(c("reference", "fit", "lower", "upper") %in% names(band))) return(invisible())
    for (x0 in sort(unique(x))) {
      i <- which(abs(band$reference - x0) <= acc_m3a_arith())
      expect_true(length(i) >= 1L, label = sprintf("%s: the band has a row at the reference value %g", label, x0))
      if (!length(i)) next
      ref <- acc_m3a_band_ref(L, x0)
      for (k in c("fit", "lower", "upper")) {
        expect_lte(abs(band[[k]][i[1]] - ref[, k]), acc_m3a_pkg(), label = sprintf("%s: band %s at %g", label, k, x0))
      }
    }
    inside <- acc_m3a_in_band_ref(L, min(x), max(x))
    expect_identical(b$linearity_in_band, inside, label = sprintf("%s: bias = 0 within the band (mini-reference: %s)", label, inside))
    expect_identical(b$linearity_verdict, if (inside) "acceptable" else "unacceptable", label = sprintf("%s: verdict", label))
    inside
  }
  # AIAG example: the bias = 0 line intersects the bounds (p. 100).
  d <- acc_m3a_aiag("ANK-76")
  b <- msa_bias(acc_m3a_numeric_runs(d), reference = acc_m3a_numeric_reference(d))
  dev <- as.numeric(d$value) - as.numeric(d$reference)
  inside <- check(b, as.numeric(d$reference), dev, 0.95, "AIAG example")
  expect_identical(inside, acc_m3a_value("ANK-76", "handbook", "bias_zero_within_band"))
  expect_identical(b$linearity_verdict, acc_m3a_value("ANK-76", "handbook", "verdict"))
  x <- c(2, 4, 6, 8, 10)
  e6 <- c(0.02, -0.02, 0.01, -0.01, 0.015, -0.015)
  cases <- list(
    # small item biases, wider noise: bias = 0 inside the band
    acceptable = list(x = x, m = 6L, dev = rep(c(0.01, -0.02, 0.015, -0.01, 0.005), each = 6) + rep(c(0.05, -0.05, 0.03, -0.03, 0.04, -0.04), 5),
                      expect = TRUE, means = TRUE),
    # item biases without trend: the handbook band excludes 0, the item-mean band does not
    handbook_rejects = list(x = x, m = 6L, dev = rep(c(0.10, -0.08, 0.12, -0.05, 0.09), each = 6) + rep(e6, 5), expect = FALSE, means = TRUE),
    # 0 inside the band at every reference value, outside between them (near the mean 4.7)
    between_references = list(x = c(2, 2.1, 10), m = 4L, dev = 0.078 + rep(c(0.002, -0.002, 0.001), each = 4) + rep(c(0.1, -0.1), 6),
                              expect = FALSE, means = NA))
  for (nm in names(cases)) {
    cs <- cases[[nm]]
    dat <- acc_m3a_6_case(cs$x, cs$m, cs$dev)
    p <- acc_m3a_6_parts(dat)
    L <- acc_m3a_lin_ref(p$x, p$dev)
    expect_identical(acc_m3a_in_band_ref(L, min(p$x), max(p$x)), cs$expect, label = sprintf("%s: construction of the case", nm))
    if (!is.na(cs$means)) {
      M <- acc_m3a_lin_ref(p$means$reference, p$means$bias)
      expect_identical(acc_m3a_in_band_ref(M, min(p$x), max(p$x)), cs$means, label = sprintf("%s: band of the item means", nm))
    }
    if (nm == "between_references") {
      B <- acc_m3a_band_ref(L, unique(p$x))
      expect_true(all(B[, "lower"] <= 0 & B[, "upper"] >= 0), label = "between_references: 0 inside the band at every reference value")
    }
    res <- acc_m3a_conditions(acc_m3a_6_bias(dat))
    expect_true(!inherits(res$value, "error"), label = sprintf("%s: msa_bias() returns a result", nm))
    if (inherits(res$value, "error")) next
    check(res$value, p$x, p$dev, 0.95, nm)
  }
  # The level of the band is the argument level.
  dat <- acc_m3a_6_case(x, 6L, cases$handbook_rejects$dev)
  p <- acc_m3a_6_parts(dat)
  check(acc_m3a_6_bias(dat, level = 0.90), p$x, p$dev, 0.90, "level 0.90")
})

test_that("K-M3a-6: msa_bias() names the difference of the two computations (item means, degrees of freedom, correlated replicates) in the object and in the report (Formelsammlung Nr. 2)", {
  x <- c(2, 4, 6, 8, 10)
  dat <- acc_m3a_6_case(x, 4L, rep(c(0.10, -0.08, 0.12, -0.05, 0.09), each = 4) + rep(c(0.02, -0.02, 0.01, -0.01), 5))
  b <- acc_m3a_6_bias(dat)
  note <- b$linearity_note
  expect_true(is.character(note) && length(note) >= 1L && any(nzchar(note)), label = "msa_bias() has a character element linearity_note")
  if (!is.character(note)) note <- ""
  named <- acc_m3a_difference_named(note, 18L, 3L)
  for (k in names(named)) {
    expect_true(named[[k]], label = sprintf("linearity_note names %s (gm - 2 = 18, g - 2 = 3): %s", k, shQuote(paste(note, collapse = " "))))
  }
  if (is.null(acc_m3a$report_grr)) {
    acc_m3a$report_grr <- msa_grr(suppressMessages(msa_fit(acc_m1a_dataset("ic50_demo"), type = "numeric")))
  }
  out <- tempfile("acc-m3a-report-", fileext = ".md")
  on.exit(unlink(out), add = TRUE)
  res <- acc_m3a_conditions(msa_report(acc_m3a$report_grr, bias = b, output_file = out, quiet = TRUE,
                                       output_format = rmarkdown::md_document(variant = "gfm", pandoc_args = "--wrap=none")))
  expect_true(!inherits(res$value, "error"),
               label = sprintf("msa_report() renders (%s)", if (inherits(res$value, "error")) conditionMessage(res$value) else "ok"))
  if (inherits(res$value, "error")) return(invisible())
  lines <- readLines(out, warn = FALSE, encoding = "UTF-8")
  header <- grepl("^#{1,6}[[:space:]]", lines)
  start <- which(header & grepl("^#{1,6}[[:space:]]+5\\.[[:space:]]*Bias", lines))
  expect_length(start, 1L)
  if (length(start) != 1L) return(invisible())
  stop_at <- which(header & seq_along(lines) > start)
  section <- lines[seq(start, if (length(stop_at)) stop_at[1] - 1L else length(lines))]
  named <- acc_m3a_difference_named(section, 18L, 3L)
  for (k in names(named)) {
    expect_true(named[[k]], label = sprintf("section 5 of the report names %s: %s", k, shQuote(paste(section, collapse = " "))))
  }
})
