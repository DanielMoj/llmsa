test_that("Plackett-Burman matrices are orthogonal and balanced", {
  for (n in c(8, 12, 16, 20, 24)) {
    X <- llmsa:::pb_matrix(n)
    expect_equal(dim(X), c(n, n - 1))
    expect_true(all(X %in% c(-1, 1)))
    expect_equal(colSums(X), rep(0, n - 1))
    G <- t(X) %*% X
    expect_equal(G, diag(n, n - 1))
  }
})

test_that("pb_design chooses the size, labels levels and analyses effects", {
  f <- list(format = c("plain", "sci"), units = c("nM", "ng/mL"), typos = c(0, 2),
            context = c("none", "extra"), system = c("A", "B"), temp = c(0, 0.7))
  d <- pb_design(f, seed = 1)
  expect_equal(nrow(d), 8)
  expect_equal(attr(d, "n_runs"), 8)
  expect_true(all(d$format_level %in% c("plain", "sci")))
  expect_equal(nrow(pb_design(9)), 12)
  expect_error(pb_design(f, n_runs = 10))
  set.seed(7)
  acc <- 0.9 - 0.08 * (d$typos > 0) - 0.05 * (d$temp > 0) + rnorm(nrow(d), 0, 0.005)
  ro <- msa_robustness(d, acc)
  expect_s3_class(ro, "msa_robustness")
  expect_setequal(ro$factor[ro$active], c("typos", "temp"))
  expect_equal(ro$effect[ro$factor == "typos"], -0.08, tolerance = 0.02)
  expect_error(msa_robustness(d, acc[-1]))
})

test_that("Lenth's pseudo standard error is computed as defined", {
  # Build a design whose column means reproduce chosen effects exactly:
  # effect_j = mean(y | x_j = +1) - mean(y | x_j = -1) with an orthogonal X
  X <- llmsa:::pb_matrix(8)[, 1:7]
  eff <- c(10, 1, -1, 2, -2, 0.5, -0.5)
  y <- as.vector(X %*% (eff / 2))
  d <- data.frame(X); names(d) <- paste0("F", 1:7)
  ro <- msa_robustness(d, y, factors = names(d))
  expect_equal(ro$effect[match(names(d), ro$factor)], eff, tolerance = 1e-10)
  # s0 = 1.5 * median|eff| = 1.5; keep |eff| < 3.75 -> median = 1 -> PSE = 1.5
  expect_equal(attr(ro, "pse"), 1.5)
  expect_equal(attr(ro, "me"), qt(0.975, 7 / 3) * 1.5)
  expect_equal(ro$factor[ro$active], "F1")
  # pure noise: nothing active
  set.seed(2)
  ro0 <- msa_robustness(d, rnorm(8), factors = names(d))
  expect_false(any(ro0$active_simultaneous))
})

test_that("msa_plan returns one row per scenario with sensible quantities", {
  sc <- data.frame(n_items = c(10, 20), n_prompts = 2, n_models = 2, n_reps = 2)
  p <- msa_plan(sc, nsim = 3, seed = 1, verbose = FALSE)
  expect_s3_class(p, "msa_plan")
  expect_equal(nrow(p), 2)
  expect_true(all(p$q2.5 <= p$median & p$median <= p$q97.5))
  expect_true(all(p$pct_singular >= 0 & p$pct_singular <= 100))
})

test_that("Westgard rules fire as specified", {
  z <- c(0, 0, 3.5, 0, 2.2, 2.3, 0, 0, 1.2, 1.3, 1.1, 1.4, 0, -2.5, 2.0)
  cc <- msa_control_chart(z, center = 0, sd = 1)
  expect_true(cc$`1_3s`[3])
  expect_true(cc$`2_2s`[6]); expect_false(cc$`2_2s`[5])
  expect_true(cc$`4_1s`[12])
  expect_true(cc$`R_4s`[15])
  expect_false(any(cc$`10_x`))
  expect_true(all(cc$reject[c(3, 6, 12, 15)]))
  cc10 <- msa_control_chart(rep(0.5, 10), center = 0, sd = 1)
  expect_true(cc10$`10_x`[10])
  expect_error(msa_control_chart(1:5, center = 0, sd = 0))
})

test_that("msa_simulate honours its sizes", {
  r <- msa_simulate(5, 2, 3, 4, n_blocks = 2, seed = 1)
  expect_equal(nrow(r), 5 * 2 * 3 * 4 * 2)
  expect_s3_class(r, "msa_runs")
})
