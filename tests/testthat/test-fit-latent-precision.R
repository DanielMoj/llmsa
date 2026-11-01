# Synthetic designs test exact covariance relations, not fitted snapshots.
# Permuting rows changes numerical accumulation without changing those relations.
latent_precision_runs <- function(items, prompts = 1L, reps = 1L,
                                  type = "ordinal", seed = 20261111L) {
  d <- expand.grid(item_id = seq_len(items), prompt_id = seq_len(prompts), rep = seq_len(reps))
  d$model_id <- d$block <- 1L
  d$value <- if (type == "ordinal") ordered(rep(1:5, length.out = nrow(d))) else
    rep(0:1, length.out = nrow(d))
  set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  d[sample.int(nrow(d)), ]
}

latent_precision_error <- function(terms, residual = TRUE) {
  paste0("Latent variance components are not identifiable: random-effect terms ", terms,
    if (residual) " cannot be separated from the fixed latent residual variance" else "",
    " after accounting for fixed effects.")
}

latent_precision_expect <- function(expr, message) {
  result <- latent_test_capture(tryCatch(expr, error = identity))
  expect_s3_class(result$value, "error")
  if (inherits(result$value, "error")) {
    expect_identical(conditionMessage(result$value), message)
    expect_null(conditionCall(result$value))
  }
  expect_length(result$warnings, 0L)
}

test_that("large singleton relations and repeated controls survive row permutations (seeds 20261112-20261114)", {
  reached <- 0L
  engine <- function(...) {
    reached <<- reached + 1L
    stop("Identifiable design reached the engine.", call. = FALSE)
  }
  local_mocked_bindings(clmm = engine, .package = "ordinal")
  local_mocked_bindings(glmer = engine, .package = "lme4")
  sizes <- c(900L, 1500L, 2000L)
  for (case in seq_along(sizes)) {
    for (type in c("ordinal", "binary")) {
      single <- latent_precision_runs(sizes[case], type = type, seed = 20261111L + case)
      zero <- rbind(single, transform(single, rep = 2L))
      repeated <- latent_precision_runs(sizes[case], reps = 3L, type = type, seed = 20261111L + case)
      one_pair <- rbind(single, transform(single[1L, ], rep = 2L))
      for (link in c("probit", "logit")) {
        # Singleton item covariance is I, hence identical to the residual
        # after any fixed projection. Zero-weight duplicates add no pairs.
        latent_precision_expect(msa_fit(single, type = type, link = link), latent_precision_error("item"))
        latent_precision_expect(msa_fit(zero, type = type, link = link, weights = as.numeric(zero$rep == 1L)),
          latent_precision_error("item"))
        # Even one repeated item adds a covariance pair absent from I.
        latent_precision_expect(msa_fit(repeated, type = type, link = link),
          "Identifiable design reached the engine.")
        latent_precision_expect(msa_fit(one_pair, type = type, link = link),
          "Identifiable design reached the engine.")
      }
    }
  }
  expect_identical(reached, 24L)
})

test_that("large interaction and nested aliases stop before both engines (seeds 20261115-20261117)", {
  reached <- 0L
  engine <- function(...) {
    reached <<- reached + 1L
    stop("Identifiable design reached the engine.", call. = FALSE)
  }
  local_mocked_bindings(clmm = engine, .package = "ordinal")
  local_mocked_bindings(glmer = engine, .package = "lme4")
  for (type in c("ordinal", "binary")) {
    for (items in c(600L, 1000L)) {
      cells <- latent_precision_runs(items, prompts = 2L, type = type, seed = 20261115L)
      repeated <- latent_precision_runs(items, prompts = 2L, reps = 2L, type = type, seed = 20261116L)
      for (link in c("probit", "logit")) {
        # One row per item:prompt makes its covariance I. Prompt is fixed
        # for ordinal responses and random for binary responses.
        latent_precision_expect(msa_fit(cells, type = type, link = link, interactions = TRUE),
          latent_precision_error("item:prompt"))
        latent_precision_expect(msa_fit(repeated, type = type, link = link, interactions = TRUE),
          "Identifiable design reached the engine.")
      }
    }
    nested <- latent_precision_runs(1000L, prompts = 3L, reps = 2L, type = type, seed = 20261117L)
    nested$model_id <- (nested$item_id - 1L) %% 3L + 1L
    # Every item belongs to one model, so item:model and item are the same
    # partition even though there are repeated observations per cell.
    for (link in c("probit", "logit")) {
      latent_precision_expect(msa_fit(nested, type = type, link = link, interactions = TRUE),
        latent_precision_error("item, item:model", residual = FALSE))
    }
  }
  expect_identical(reached, 8L)
})

test_that("large one-factor information agrees with closed count formulas", {
  for (counts in list(rep(1, 5000L), rep(3, 2000L), c(rep(1, 1999L), 2), rep(1:3, 300L))) {
    dat <- data.frame(item = factor(rep(seq_along(counts), counts)))
    n <- sum(counts)
    # With an intercept, P = I - 11'/n and K marks equal items. Expanding
    # tr(P K P K) by item counts gives these scalar sums independently.
    g <- sum(counts^2) - 2 * sum(counts^3) / n + (sum(counts^2) / n)^2
    cross <- n - sum(counts^2) / n
    expected <- matrix(c(g, cross, cross, n - 1), 2L)
    observed <- llmsa:::msa_latent_information(dat, "item", matrix(1, n, 1L), residual = TRUE)
    expect_equal(observed, expected, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
    expect_lte(max(abs(observed - expected)), numeric_tolerance("arithmetic", "abs_tol"))
    if (all(counts == 1)) {
      ev <- eigen(observed, symmetric = TRUE, only.values = TRUE)$values
      expect_lte(min(ev), nrow(observed) * .Machine$double.eps * max(ev))
    }
  }
})

test_that("a smaller random partition spanned by fixed effects has exactly zero covariance information", {
  dat <- expand.grid(model = factor(1:2), block = factor(1:2), prompt = factor(1:2), rep = 1:2)
  dat <- dat[dat$model == "1" | dat$block == "1", ]
  dat$item <- interaction(dat$model, dat$block, drop = TRUE)
  X <- stats::model.matrix(~ prompt + model + block, dat)
  Z <- stats::model.matrix(~ 0 + item, dat)
  # The three item indicators are 1 - model2 - block2, model2 and block2.
  # They are fixed linear combinations, with prompt adding an independent
  # fourth column. Thus P Z is exactly zero for every frequency vector.
  model2 <- as.numeric(dat$model == "2")
  block2 <- as.numeric(dat$block == "2")
  expect_identical(as.vector(Z), as.vector(cbind(1 - model2 - block2, model2, block2)))
  expect_lt(ncol(Z), ncol(X))
  for (weights in list(rep(1, nrow(dat)), rep(1:3, length.out = nrow(dat)))) {
    expect_identical(llmsa:::msa_latent_information(dat, "item", X, weights = weights, residual = TRUE),
      diag(c(0, sum(weights) - ncol(X))))
    expect_identical(llmsa:::msa_latent_information(dat, "item", X, weights = weights), matrix(0, 1L, 1L))
  }
})

test_that("noninteger weights count positive rows once and retain the engine arguments (seed 20261118)", {
  seen <- list()
  engine <- function(data, weights, ...) {
    seen[[length(seen) + 1L]] <<- list(data = data, weights = weights)
    stop("Identifiable design reached the engine.", call. = FALSE)
  }
  local_mocked_bindings(clmm = engine, .package = "ordinal")
  local_mocked_bindings(glmer = engine, .package = "lme4")
  for (type in c("ordinal", "binary")) {
    single <- latent_precision_runs(54L, type = type, seed = 20261118L)
    regular <- latent_test_runs(type, items = 18L, prompts = 3L, models = 3L, seed = 20261118L)
    for (link in c("probit", "logit")) {
      for (weights in list(rep(1.25, nrow(single)), rep(1.5, nrow(single)),
        rep(c(1, 2, 1.5), length.out = nrow(single)))) {
        latent_precision_expect(msa_fit(single, type = type, link = link, weights = weights),
          latent_precision_error("item"))
      }
      zero <- rbind(single, transform(single, rep = 2L))
      weights <- c(rep(c(2, 0.5), length.out = nrow(single)), rep(0, nrow(single)))
      latent_precision_expect(msa_fit(zero, type = type, link = link, weights = weights),
        latent_precision_error("item"))
      for (multiple in c(0.1, 1 / nrow(regular))) {
        for (interactions in c(FALSE, TRUE)) {
          weights <- rep(multiple, nrow(regular))
          latent_precision_expect(msa_fit(regular, type = type, link = link,
            interactions = interactions, weights = weights), "Identifiable design reached the engine.")
          last <- seen[[length(seen)]]
          expect_identical(last$weights, weights)
          expect_identical(last$data$y, regular$value)
          expect_equal(nrow(last$data), nrow(regular))
        }
      }
      # Integer multiplicities still represent genuine repeated observations.
      weights <- rep(2, nrow(single))
      latent_precision_expect(msa_fit(single, type = type, link = link, weights = weights),
        "Identifiable design reached the engine.")
      expect_identical(seen[[length(seen)]]$weights, weights)
      # The policy is applied after row selection. The discarded fraction
      # must not turn the remaining integer frequencies into presence flags.
      weights[1L] <- 1.5
      latent_precision_expect(msa_fit(single, type = type, link = link,
        weights = weights, subset = seq_len(nrow(single))[-1L]), "Identifiable design reached the engine.")
      expect_identical(seen[[length(seen)]]$weights, weights[-1L])
    }
  }
  expect_length(seen, 24L)
})

test_that("noninteger weights use observed support for the ordinal fixed rank (seed 20261119)", {
  seen <- list()
  engine <- function(weights, ...) {
    seen[[length(seen) + 1L]] <<- weights
    stop("Identifiable design reached the engine.", call. = FALSE)
  }
  local_mocked_bindings(clmm = engine, .package = "ordinal")
  runs <- latent_test_runs(items = 12L, prompts = 2L, models = 2L, seed = 20261119L)
  same <- runs$prompt_id == sub("M", "P", runs$model_id, fixed = TRUE)
  weights <- ifelse(same, 0.1, 1e-30)
  for (link in c("probit", "logit")) {
    latent_precision_expect(msa_fit(runs, type = "ordinal", link = link, weights = weights),
      "Identifiable design reached the engine.")
    if (length(seen)) expect_identical(seen[[length(seen)]], weights)
    # Removing all off-diagonal cells instead gives identical prompt and
    # model columns. The fixed design must then be rejected, not fitted.
    latent_precision_expect(msa_fit(runs, type = "ordinal", link = link, weights = 0.1 * same),
      paste0("Ordinal two-level factors prompt, model are not identifiable: ",
        "the fixed-effect design is rank deficient."))
  }
  expect_length(seen, 2L)
})

test_that("fractional-weight fits retain direct clmm and glmer components (seed 20261120)", {
  for (type in c("ordinal", "binary")) {
    runs <- latent_test_runs(type, items = 12L, prompts = 3L, models = 2L, seed = 20261120L)
    dat <- data.frame(item = factor(runs$item_id), prompt = factor(runs$prompt_id),
      model = factor(runs$model_id), block = factor(runs$block), y = runs$value)
    weights <- rep(c(0, 0.5, 2, 0.75), length.out = nrow(dat))
    for (link in c("probit", "logit")) {
      direct <- latent_test_capture(if (type == "ordinal") {
        ordinal::clmm(y ~ 1 + model + (1 | item) + (1 | prompt), data = dat, weights = weights, link = link)
      } else {
        lme4::glmer(y ~ 1 + (1 | item) + (1 | prompt) + (1 | model),
          data = dat, weights = weights, family = stats::binomial(link))
      })$value
      fit <- latent_test_capture(msa_fit(runs, type = type, link = link, weights = weights))$value
      components <- if (type == "ordinal") ordinal::VarCorr(direct) else lme4::VarCorr(direct)
      reference <- c(vapply(components, function(x) as.numeric(x)[1L], numeric(1)),
        Residual = if (link == "probit") 1 else pi^2 / 3)
      if (type == "ordinal") reference["model"] <- stats::var(c(0, unname(direct$beta)))
      got <- stats::setNames(fit$vc$variance, fit$vc$source)
      expect_setequal(names(got), names(reference))
      expect_lte(max(abs(got[names(reference)] - reference)) / sum(reference),
        numeric_tolerance("engine_ordinal", "rel_tol"))
      expect_identical(fit$data$y, dat$y)
      expect_equal(stats::model.weights(stats::model.frame(fit$model)), weights, tolerance = 0)
      expect_equal(stats::nobs(fit$model), stats::nobs(direct), tolerance = 0)
    }
  }
})
