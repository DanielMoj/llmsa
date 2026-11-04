# K-M3b-3: main effects are differences of the level means and twice the
# regression coefficient with +-1 coding; Lenth's PSE, ME and SME with the
# constants 1.5 and 2.5 and d = m/3 reproduce examples II and IV of Lenth (1989)
# (ankerRef: ANK-81); the PSE agrees with unrepx::PSE, and PSE, ME and SME
# agree with DoE.base::ME.Lenth(simulated = FALSE) (ANK-TOL.frf2_unrepx); a
# factor is active when |E| > ME, simultaneously active when |E| > SME. Two
# independent pieces of evidence (docs/01 §2 Nr. 2): the printed values of the
# source and a mini-reference of Gl. (1)-(5) (setup-m3b.R); unrepx and DoE.base
# run as oracles at test time. Lenth's examples enter msa_robustness() as plain
# data.frame designs with all 15 contrast columns, because the PSE of the
# source is taken over all m = 15 contrasts (ACC-6). unrepx::ME() derives ME
# from a simulated reference distribution, not from t quantiles with d = m/3;
# ADR-050 Nr. 2 replaced it as oracle by DoE.base::ME.Lenth(simulated = FALSE)
# (ACC-7).

acc_m3b_3_alpha <- function() as.numeric(acc_m3b_value("ANK-81", "method", "nominal_alpha"))

# A pb_design with k factors in 12 runs and a seeded response with a few large
# effects.
acc_m3b_3_pb_case <- function(k, seed) {
  d <- pb_design(k, n_runs = 12L, seed = seed)
  X <- acc_m3b_coded(d)
  beta <- c(2, -1.5, 0.8, rep(0, k - 3L))
  y <- acc_m3b_with_seed(seed, as.numeric(10 + X %*% beta / 2 + stats::rnorm(12L, 0, 0.3)))
  list(d = d, X = X, y = y, labels = colnames(attr(d, "coded")))
}

test_that("K-M3b-3: main effects are differences of the level means and twice the regression coefficient with +-1 coding", {
  tol <- acc_m3b_arith()
  for (k in c(11L, 8L)) {
    case <- acc_m3b_3_pb_case(k, seed = 7L)
    r <- msa_robustness(case$d, case$y)
    e <- acc_m3b_by_factor(r, case$labels, "effect")
    expect_lte(max(abs(e - acc_m3b_mean_differences(case$X, case$y))), tol,
               label = sprintf("k = %d: |effect - difference of level means|", k))
    b <- stats::coef(stats::lm(case$y ~ case$X))[-1]
    expect_lte(max(abs(e - 2 * unname(b))), tol, label = sprintf("k = %d: |effect - 2 b|", k))
  }
  for (ex in c("II", "IV")) {
    L <- acc_m3b_lenth_example(ex)
    r <- msa_robustness(L$design, L$y, factors = L$labels, alpha = acc_m3b_3_alpha())
    e <- acc_m3b_by_factor(r, L$labels, "effect")
    expect_lte(max(abs(e - acc_m3b_mean_differences(L$X, L$y))), tol, label = paste("example", ex, ": level means"))
    b <- stats::coef(stats::lm(L$y ~ L$X))[-1]
    expect_lte(max(abs(e - 2 * unname(b))), tol, label = paste("example", ex, ": 2 b"))
  }
})

test_that("K-M3b-3: msa_robustness() reproduces the contrasts of Tab. 3 and PSE, ME and SME of Lenth's examples II and IV (ankerRef: ANK-81)", {
  alpha <- acc_m3b_3_alpha()
  for (ex in c("II", "IV")) {
    L <- acc_m3b_lenth_example(ex)
    pub <- L$meta
    r <- msa_robustness(L$design, L$y, factors = L$labels, alpha = alpha)
    e <- acc_m3b_by_factor(r, L$labels, "effect")
    tol_e <- acc_m3b_printed_tol(pub$estimates_decimals)
    for (i in seq_along(L$labels)) {
      expect_lte(abs(e[i] - L$printed[i]), tol_e,
                 label = sprintf("example %s, contrast %s: observed %.5f, printed %s", ex, L$labels[i], e[i], format(L$printed[i])))
    }
    obs <- vapply(c("response_mean", "pse", "me", "sme"), function(k) acc_m3b_attr(r, k), numeric(1))
    expect_lte(abs(obs[["response_mean"]] - pub$mean), acc_m3b_printed_tol(pub$mean_decimals),
               label = sprintf("example %s: mean %.5f, printed %s", ex, obs[["response_mean"]], format(pub$mean)))
    expect_lte(abs(obs[["pse"]] - pub$pse), acc_m3b_printed_tol(pub$pse_decimals),
               label = sprintf("example %s: PSE %.6f, printed %s", ex, obs[["pse"]], format(pub$pse)))
    expect_lte(abs(obs[["me"]] - pub$me), acc_m3b_printed_tol(pub$me_sme_decimals),
               label = sprintf("example %s: ME %.6f, printed %s", ex, obs[["me"]], format(pub$me)))
    expect_lte(abs(obs[["sme"]] - pub$sme), acc_m3b_printed_tol(pub$me_sme_decimals),
               label = sprintf("example %s: SME %.6f, printed %s", ex, obs[["sme"]], format(pub$sme)))
    ref <- acc_m3b_lenth_reference(acc_m3b_mean_differences(L$X, L$y), alpha)
    expect_lte(abs(ref$s0 - pub$s0), acc_m3b_printed_tol(pub$pse_decimals), label = paste("example", ex, ": s0 of the mini-reference"))
    for (k in c("pse", "me", "sme")) {
      expect_lte(abs(obs[[k]] - ref[[k]]), acc_m3b_arith(),
                 label = sprintf("example %s: %s equals the mini-reference (%.10f)", ex, k, ref[[k]]))
    }
  }
})

test_that("K-M3b-3: the constants 1.5 and 2.5, d = m/3 and gamma give the t quantiles of Tab. 1 of Lenth (1989) for m = 7 to 255 (ankerRef: ANK-81)", {
  t1 <- acc_m3b_value("ANK-81", "table1")
  tol <- acc_m3b_printed_tol(t1$decimals)
  alpha <- acc_m3b_3_alpha()
  ms <- as.integer(unlist(t1$m))
  for (i in seq_along(ms)) {
    k <- as.integer(round(log2(ms[i] + 1)))
    X <- acc_m3b_full_contrasts(k)
    expect_identical(ncol(X), ms[i])
    y <- acc_m3b_with_seed(100L + i, stats::rnorm(nrow(X)))
    r <- msa_robustness(as.data.frame(X), y, factors = colnames(X), alpha = alpha)
    expect_identical(nrow(as.data.frame(r)), ms[i])
    ratio_me <- acc_m3b_attr(r, "me") / acc_m3b_attr(r, "pse")
    ratio_sme <- acc_m3b_attr(r, "sme") / acc_m3b_attr(r, "pse")
    expect_lte(abs(ratio_me - t1$t_975[[i]]), tol,
               label = sprintf("m = %d: ME/PSE %.4f, Tab. 1 %s", ms[i], ratio_me, format(t1$t_975[[i]])))
    expect_lte(abs(ratio_sme - t1$t_gamma[[i]]), tol,
               label = sprintf("m = %d: SME/PSE %.4f, Tab. 1 %s", ms[i], ratio_sme, format(t1$t_gamma[[i]])))
  }
})

test_that("K-M3b-3: the PSE takes the median over the contrasts strictly below 2.5 s0 (Lenth 1989, Gl. (2), ankerRef: ANK-81)", {
  # Effects 1, 1, 2, 2, 7.5, 30, 40 in binary-exact arithmetic: median 2, s0 = 3,
  # 2.5 s0 = 7.5. The contrast 7.5 lies on the bound and stays out, so the PSE
  # is 1.5 x median(1, 1, 2, 2) = 2.25; with it the PSE would be 3. The
  # expected PSE is the mini-reference applied to the effects the product
  # reports, so that a last-bit difference in a correct effect computation
  # cannot decide the test.
  alpha <- acc_m3b_3_alpha()
  d <- pb_design(7L, n_runs = 8L, randomize = FALSE)
  X <- acc_m3b_coded(d)
  target <- c(2, 40, 1, 7.5, 2, 30, 1)
  y <- as.numeric(X %*% target) / 2
  expect_identical(unname(acc_m3b_mean_differences(X, y)), target)
  expect_identical(acc_m3b_lenth_reference(target, alpha)$pse, 2.25)
  r <- msa_robustness(d, y, alpha = alpha)
  e <- acc_m3b_by_factor(r, colnames(attr(d, "coded")), "effect")
  expect_lte(max(abs(e - target)), acc_m3b_arith())
  expected <- acc_m3b_lenth_reference(e, alpha)$pse
  expect_lte(abs(acc_m3b_attr(r, "pse") - expected), acc_m3b_arith(),
             label = sprintf("PSE %.10f with a contrast on the trimming bound (expected %.10f)", acc_m3b_attr(r, "pse"), expected))
})

test_that("K-M3b-3: a factor is active when |E| > ME and simultaneously active when |E| > SME (ankerRef: ANK-81)", {
  alpha <- acc_m3b_3_alpha()
  for (ex in c("II", "IV")) {
    L <- acc_m3b_lenth_example(ex)
    r <- msa_robustness(L$design, L$y, factors = L$labels, alpha = alpha)
    expect_setequal(r$factor[r$active], as.character(unlist(L$meta$active)))
    expect_setequal(r$factor[r$active_simultaneous], as.character(unlist(L$meta$active_simultaneous)))
  }
  # Ten small effects and one effect halfway between ME and SME: active, not
  # simultaneously active.
  d <- pb_design(11L, n_runs = 12L, randomize = FALSE)
  X <- acc_m3b_coded(d)
  small <- c(0.11, -0.23, 0.05, 0.31, -0.17, 0.08, -0.29, 0.14, 0.21, -0.02)
  ref_small <- acc_m3b_lenth_reference(c(small, 100), alpha)
  big <- (ref_small$me + ref_small$sme) / 2
  target <- c(small, big)
  ref <- acc_m3b_lenth_reference(target, alpha)
  expect_identical(ref$active, c(rep(FALSE, 10), TRUE))
  expect_identical(ref$active_simultaneous, rep(FALSE, 11))
  y <- 5 + as.numeric(X %*% target) / 2
  r <- msa_robustness(d, y, alpha = alpha)
  labels <- colnames(attr(d, "coded"))
  expect_identical(acc_m3b_by_factor(r, labels, "active"), ref$active)
  expect_identical(acc_m3b_by_factor(r, labels, "active_simultaneous"), ref$active_simultaneous)
  # The flags follow the returned margins on seeded designs.
  for (seed in 1:3) {
    case <- acc_m3b_3_pb_case(11L, seed = seed)
    r <- msa_robustness(case$d, case$y, alpha = alpha)
    expect_identical(r$active, abs(r$effect) > acc_m3b_attr(r, "me"))
    expect_identical(r$active_simultaneous, abs(r$effect) > acc_m3b_attr(r, "sme"))
    ref <- acc_m3b_lenth_reference(acc_m3b_by_factor(r, case$labels, "effect"), alpha)
    expect_identical(acc_m3b_by_factor(r, case$labels, "active"), ref$active)
    expect_identical(acc_m3b_by_factor(r, case$labels, "active_simultaneous"), ref$active_simultaneous)
  }
})

test_that("K-M3b-3: the PSE agrees with unrepx::PSE(method = \"Lenth\") (ANK-TOL.frf2_unrepx)", {
  tol <- as.numeric(acc_m3b_tol("frf2_unrepx", "pse_me_tol"))
  alpha <- acc_m3b_3_alpha()
  cases <- lapply(c("II", "IV"), function(ex) {
    L <- acc_m3b_lenth_example(ex)
    list(label = paste("example", ex), design = L$design, y = L$y, factors = L$labels, X = L$X)
  })
  for (seed in 1:3) {
    case <- acc_m3b_3_pb_case(11L, seed = seed)
    cases[[length(cases) + 1L]] <- list(label = paste("pb_design(11), seed", seed), design = case$d, y = case$y,
                                        factors = case$labels, X = case$X)
  }
  for (cs in cases) {
    r <- msa_robustness(cs$design, cs$y, factors = cs$factors, alpha = alpha)
    oracle <- unname(unrepx::PSE(acc_m3b_mean_differences(cs$X, cs$y), method = "Lenth"))
    expect_lte(abs(acc_m3b_attr(r, "pse") - oracle), tol,
               label = sprintf("%s: PSE %.10f, unrepx %.10f", cs$label, acc_m3b_attr(r, "pse"), oracle))
  }
})

test_that("K-M3b-3: PSE, ME and SME agree with DoE.base::ME.Lenth(simulated = FALSE) (ANK-TOL.frf2_unrepx)", {
  # pse_me_tol holds for SME as well (ADR-050 Nr. 2). The oracle gets the
  # effects computed here from the data, except in the case with a contrast on
  # the trimming bound, where it gets the effects the product reports, for the
  # reason given in the test of Gl. (2) above.
  tol <- as.numeric(acc_m3b_tol("frf2_unrepx", "pse_me_tol"))
  alpha <- acc_m3b_3_alpha()
  cases <- lapply(c("II", "IV"), function(ex) {
    L <- acc_m3b_lenth_example(ex)
    list(label = paste("example", ex), design = L$design, y = L$y, factors = L$labels,
         effects = acc_m3b_mean_differences(L$X, L$y))
  })
  for (k in c(11L, 8L)) {
    for (seed in 1:3) {
      case <- acc_m3b_3_pb_case(k, seed = seed)
      cases[[length(cases) + 1L]] <- list(label = sprintf("pb_design(%d) in 12 runs, seed %d", k, seed), design = case$d,
                                          y = case$y, factors = case$labels,
                                          effects = acc_m3b_mean_differences(case$X, case$y))
    }
  }
  for (k in 3:6) {
    X <- acc_m3b_full_contrasts(k)
    y <- acc_m3b_with_seed(200L + k, stats::rnorm(nrow(X)))
    cases[[length(cases) + 1L]] <- list(label = sprintf("m = %d contrasts of the 2^%d factorial", ncol(X), k),
                                        design = as.data.frame(X), y = y, factors = colnames(X),
                                        effects = acc_m3b_mean_differences(X, y))
  }
  for (cs in cases) {
    r <- msa_robustness(cs$design, cs$y, factors = cs$factors, alpha = alpha)
    oracle <- acc_m3b_doe_lenth(cs$effects, alpha)
    ref <- acc_m3b_lenth_reference(cs$effects, alpha)
    for (key in names(oracle)) {
      expect_lte(abs(acc_m3b_attr(r, key) - oracle[[key]]), tol,
                 label = sprintf("%s: %s %.10f, DoE.base::ME.Lenth %.10f", cs$label, toupper(key), acc_m3b_attr(r, key), oracle[[key]]))
      expect_lte(abs(oracle[[key]] - ref[[key]]), acc_m3b_arith(),
                 label = sprintf("%s: %s of DoE.base::ME.Lenth %.10f equals the mini-reference %.10f", cs$label, toupper(key),
                                 oracle[[key]], ref[[key]]))
    }
  }
  # Effects 1, 1, 2, 2, 7.5, 30, 40: DoE.base trims strictly as Gl. (2) does,
  # so the contrast on 2.5 s0 stays out of the PSE there as well.
  target <- c(2, 40, 1, 7.5, 2, 30, 1)
  expect_identical(acc_m3b_doe_lenth(target, alpha)[["pse"]], acc_m3b_lenth_reference(target, alpha)$pse)
  d <- pb_design(7L, n_runs = 8L, randomize = FALSE)
  X <- acc_m3b_coded(d)
  y <- as.numeric(X %*% target) / 2
  r <- msa_robustness(d, y, alpha = alpha)
  oracle <- acc_m3b_doe_lenth(acc_m3b_by_factor(r, colnames(attr(d, "coded")), "effect"), alpha)
  for (key in names(oracle)) {
    expect_lte(abs(acc_m3b_attr(r, key) - oracle[[key]]), tol,
               label = sprintf("contrast on the trimming bound: %s %.10f, DoE.base::ME.Lenth %.10f", toupper(key),
                               acc_m3b_attr(r, key), oracle[[key]]))
  }
})
