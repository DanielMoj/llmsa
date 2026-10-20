test_that("kappa and alpha equal 1 under perfect agreement and drop with noise", {
  lv <- c("a", "b", "c")
  df <- expand.grid(item_id = paste0("I", 1:30), prompt_id = c("P1", "P2"), model_id = c("m1", "m2"),
                    rep = 1:2, stringsAsFactors = FALSE)
  set.seed(1)
  truth <- setNames(sample(lv, 30, TRUE), paste0("I", 1:30))
  df$value <- unname(truth[df$item_id])
  ag <- msa_agreement(as_msa_runs(df), levels = lv, reference = truth)
  expect_equal(ag$repeatability_overall, 100)
  expect_equal(unname(ag$reproducibility), c(100, 100, 100))
  expect_equal(ag$alpha$alpha, rep(1, 4))
  expect_equal(unname(ag$kappa), c(1, 1))
  expect_equal(ag$accuracy_overall, 100)
  noisy <- df; noisy$value[sample.int(nrow(noisy), 60)] <- sample(lv, 60, TRUE)
  ag2 <- msa_agreement(as_msa_runs(noisy), levels = lv, reference = truth)
  expect_true(ag2$repeatability_overall < 100)
  expect_true(all(ag2$alpha$alpha < 1))
  expect_true(ag2$kappa[[2]] < 1)
})

test_that("Cohen's kappa matches a textbook example", {
  # Classic 2x2 example: 20 agree-yes, 5 yes/no, 10 no/yes, 15 agree-no
  x <- c(rep("yes", 25), rep("no", 25))
  y <- c(rep("yes", 20), rep("no", 5), rep("yes", 10), rep("no", 15))
  k <- llmsa:::cohen_kappa(x, y, c("no", "yes"))
  po <- 35 / 50; pe <- (25 / 50) * (30 / 50) + (25 / 50) * (20 / 50)
  expect_equal(k, (po - pe) / (1 - pe))
  # quadratic weights on an ordinal scale with one-step disagreements
  k_q <- llmsa:::cohen_kappa(c("a", "b", "c", "a"), c("b", "b", "c", "a"), c("a", "b", "c"), "quadratic")
  k_u <- llmsa:::cohen_kappa(c("a", "b", "c", "a"), c("b", "b", "c", "a"), c("a", "b", "c"), "unweighted")
  expect_true(k_q > k_u)
})

test_that("Krippendorff's alpha reproduces the worked example from Krippendorff (2011)", {
  # Four observers, twelve units (Krippendorff, "Computing Krippendorff's
  # alpha-reliability", 2011): nominal 0.743, interval 0.849, ordinal 0.815
  dat <- rbind(A = c(1, 2, 3, 3, 2, 1, 4, 1, 2, NA, NA, NA),
               B = c(1, 2, 3, 3, 2, 2, 4, 1, 2, 5, NA, 3),
               C = c(NA, 3, 3, 3, 2, 3, 4, 2, 2, 5, 1, NA),
               D = c(1, 2, 3, 3, 2, 4, 4, 1, 2, 5, 1, NA))
  values <- as.character(as.vector(dat))
  units <- rep(seq_len(ncol(dat)), each = nrow(dat))
  alpha_nom <- llmsa:::krippendorff_alpha(values, units, as.character(1:5), "nominal")
  expect_equal(alpha_nom, 0.743, tolerance = 0.002)
  alpha_int <- llmsa:::krippendorff_alpha(values, units, as.character(1:5), "interval")
  expect_equal(alpha_int, 0.849, tolerance = 0.002)
  alpha_ord <- llmsa:::krippendorff_alpha(values, units, as.character(1:5), "ordinal")
  expect_equal(alpha_ord, 0.815, tolerance = 0.002)
})
