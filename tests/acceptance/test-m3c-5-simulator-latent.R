# K-M3c-5 (deterministic part): the column latent that msa_simulate() carries
# is the item truth, the grand mean plus the item effect of the model equation
# (Formelsammlung §2 and §9, "die Itemwahrheit wird mitgeführt (latent)").
# The recovery of the given components over n_sim >= ANK-06 repetitions with
# msa_fit, and the distribution of latent, are the class A simulation
# tests/simulation/test-simulator-recovery.R. Components of S-boot-1 and the
# design of S-sim-1 are settings of the spec (docs/02 M1c, docs/04 M3c). ACC-6.

acc_m3c_5_vc <- list(item = 1, prompt = 0.05, model = 0.05, block = 0.01, item_prompt = 0.01,
                     item_model = 0.05, prompt_model = 0.005, residual = 0.1)

acc_m3c_5_sim <- function(...) acc_m3c_try(msa_simulate(...))

acc_m3c_5_ok <- function(r, what) {
  testthat::expect_false(inherits(r, "error"), label = sprintf("msa_simulate() for %s (%s)", what,
                                                              if (inherits(r, "error")) conditionMessage(r) else "ok"))
  !inherits(r, "error")
}

test_that("K-M3c-5: in the S-sim-1 design the column latent is constant within each item and differs between items, while value varies within items", {
  r <- acc_m3c_5_sim(40, 3, 3, 2, 2, vc = acc_m3c_5_vc, seed = 31085L)
  if (!acc_m3c_5_ok(r, "S-sim-1")) return(invisible())
  expect_true(all(c("item_id", "latent", "value") %in% names(r)), label = "columns item_id, latent, value")
  expect_identical(nrow(r), as.integer(40 * 3 * 3 * 2 * 2), label = "rows of the S-sim-1 design")
  per_item <- tapply(r$latent, r$item_id, function(v) length(unique(v)))
  expect_true(all(per_item == 1L), label = "one latent value per item")
  expect_identical(length(unique(r$latent)), 40L, label = "distinct latent values over 40 items")
  spread <- tapply(r$value, r$item_id, function(v) length(unique(v)))
  expect_true(all(spread > 1L), label = "value varies within every item")
})

test_that("K-M3c-5: with only an item component, value equals latent in every row; with a zero item component latent is the grand mean", {
  tol <- acc_m3c_arith()
  r <- acc_m3c_5_sim(6, 3, 2, 2, 2, vc = list(item = 1), mean = 5, seed = 31086L)
  if (acc_m3c_5_ok(r, "an item component only")) {
    expect_lte(max(abs(r$value - r$latent)), tol, label = "max |value - latent| with an item component only")
    expect_gt(stats::sd(unique(r$latent)), 0, label = "latent varies between items")
  }
  r0 <- acc_m3c_5_sim(6, 3, 2, 2, 2, vc = list(item = 0, prompt = 0.05, model = 0.05, residual = 0.1), mean = -2.5, seed = 31087L)
  if (acc_m3c_5_ok(r0, "a zero item component")) {
    expect_lte(max(abs(r0$latent - (-2.5))), tol, label = "max |latent - mean| with a zero item component")
    expect_gt(stats::sd(r0$value), 0, label = "value varies with the other components")
  }
})

test_that("K-M3c-5: shifting the grand mean shifts latent and value by the same amount (same seed)", {
  tol <- acc_m3c_arith()
  a <- acc_m3c_5_sim(10, 3, 3, 2, 2, vc = acc_m3c_5_vc, mean = 0, seed = 31088L)
  b <- acc_m3c_5_sim(10, 3, 3, 2, 2, vc = acc_m3c_5_vc, mean = 3.25, seed = 31088L)
  if (!acc_m3c_5_ok(a, "mean 0") || !acc_m3c_5_ok(b, "mean 3.25")) return(invisible())
  key <- function(d) paste(d$block, d$item_id, d$prompt_id, d$model_id, d$rep)
  b <- b[match(key(a), key(b)), , drop = FALSE]
  expect_lte(max(abs(b$latent - a$latent - 3.25)), tol, label = "max |latent shift - 3.25|")
  expect_lte(max(abs(b$value - a$value - 3.25)), tol, label = "max |value shift - 3.25|")
})
