# Synthetic designs, except for the public ordinal::wine data. Integer
# frequency weights are checked by expanding observations and independently
# projecting their pairwise covariance matrices. No fitted output is frozen.
latent_weight_frame <- function(runs) {
  data.frame(item = factor(runs$item_id), prompt = factor(runs$prompt_id),
    model = factor(runs$model_id), block = factor(runs$block), y = runs$value)
}

latent_weight_pairs <- function(dat, groups, X, weights) {
  rows <- rep(seq_len(nrow(dat)), weights)
  expanded <- dat[rows, , drop = FALSE]
  X <- X[rows, , drop = FALSE]
  P <- diag(length(rows)) - X %*% solve(crossprod(X), t(X))
  columns <- lapply(groups, function(term) {
    parts <- strsplit(term, ":", fixed = TRUE)[[1L]]
    group <- do.call(paste, c(lapply(expanded[parts], as.character), sep = "/"))
    covariance <- outer(group, group, `==`) * 1
    as.vector(P %*% covariance %*% P)
  })
  # The residual is the identity before projection, hence P afterwards.
  cbind(do.call(cbind, columns), as.vector(P))
}

latent_weight_expect_error <- function(expr, message) {
  result <- latent_test_capture(tryCatch(expr, error = identity))
  expect_s3_class(result$value, "error")
  if (inherits(result$value, "error")) {
    expect_identical(conditionMessage(result$value), message)
    expect_null(conditionCall(result$value))
  }
  expect_length(result$warnings, 0L)
  invisible(result$value)
}

test_that("frequency information including the residual equals expanded observation pairs", {
  dat <- expand.grid(item = factor(1:4), prompt = factor(1:3),
    model = factor(1:2), block = factor(1:2))
  dat <- dat[-c(2L, 7L, 19L, 34L, 45L), ]
  groups <- c("item", "prompt", "item:prompt", "item:model", "prompt:model")
  for (weights in list(rep(1, nrow(dat)), rep(2, nrow(dat)), rep(0:3, length.out = nrow(dat)))) {
    for (contrasts in list(NULL, list(model = "contr.sum", block = "contr.sum"))) {
      X <- stats::model.matrix(~ model + block, dat, contrasts.arg = contrasts)
      pairs <- latent_weight_pairs(dat, groups, X, weights)
      expected <- crossprod(pairs)
      got <- llmsa:::msa_latent_information(dat, groups, X, weights = weights, residual = TRUE)
      expect_equal(got, expected, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
      expect_identical(got, t(got))
      expect_equal(got[6L, 6L], sum(weights) - ncol(X), tolerance = 0)
      expect_equal(llmsa:::msa_latent_information(dat, "item", X, weights = weights, residual = TRUE),
        expected[c(1L, 6L), c(1L, 6L)], tolerance = numeric_tolerance("arithmetic", "abs_tol"))
      # The original internal helper's random-only result remains available.
      expect_equal(llmsa:::msa_latent_information(dat, groups, X, weights = weights),
        expected[seq_along(groups), seq_along(groups)],
        tolerance = numeric_tolerance("arithmetic", "abs_tol"))
    }
  }
  # A one-column data frame is a complete design for one random term.
  dat <- data.frame(item = factor(rep(letters[1:4], c(1L, 2L, 3L, 4L))))
  weights <- rep(0:3, length.out = nrow(dat))
  X <- matrix(1, nrow(dat), 1L)
  expected <- crossprod(latent_weight_pairs(dat, "item", X, weights))
  expect_no_error(got <- llmsa:::msa_latent_information(dat, "item", X, weights = weights, residual = TRUE))
  expect_equal(got, expected, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
})

test_that("weighted fixed spans drop unobserved interaction levels exactly", {
  dat <- expand.grid(item = factor(1:4), prompt = factor(1:2), model = factor(1:2), rep = 1:2)
  weights <- ifelse(dat$prompt == "2" & dat$model == "2", 0, 1 + dat$rep)
  for (contrasts in list(NULL, list(prompt = "contr.sum", model = "contr.sum"))) {
    X <- stats::model.matrix(~ prompt + model, dat, contrasts.arg = contrasts)
    rows <- rep(seq_len(nrow(dat)), weights)
    Z <- stats::model.matrix(~ 0 + group,
      data.frame(group = interaction(dat$prompt[rows], dat$model[rows], drop = TRUE)))
    expect_equal(ncol(Z), ncol(X))
    expect_equal(qr(cbind(X[rows, ], Z))$rank, ncol(X))
    # This is an exact span, so numerical projection debris must be zero.
    got <- llmsa:::msa_latent_information(dat, "prompt:model", X, weights = weights, residual = TRUE)
    expect_identical(got, diag(c(0, sum(weights) - ncol(X))))
    expect_identical(llmsa:::msa_latent_information(dat, "prompt:model", X, weights = weights),
      matrix(0, 1L, 1L))
  }
})

test_that("single observations per latent random level fail before either engine (seed 20261102)", {
  called <- 0L
  forbidden <- function(...) { called <<- called + 1L; stop("Unexpected engine call.") }
  local_mocked_bindings(clmm = forbidden, .package = "ordinal")
  local_mocked_bindings(glmer = forbidden, .package = "lme4")
  wine <- new.env(parent = emptyenv())
  utils::data("wine", package = "ordinal", envir = wine)
  for (type in c("ordinal", "binary")) {
    single <- latent_test_runs(type, items = 18L, prompts = 1L, models = 1L, seed = 20261102L)
    single <- single[single$rep == 1L, ]
    cells <- latent_test_runs(type, items = 12L, models = 1L, seed = 20261102L)
    cells <- cells[cells$rep == 1L, ]
    public <- data.frame(item_id = wine$wine$bottle, prompt_id = wine$wine$judge,
      model_id = "M1", block = 1L, rep = 1L,
      value = if (type == "ordinal") wine$wine$rating else as.integer(wine$wine$rating) > 3L)
    for (link in c("probit", "logit")) {
      latent_weight_expect_error(msa_fit(single, type = type, link = link), paste0(
        "Latent variance components are not identifiable: random-effect terms item",
        " cannot be separated from the fixed latent residual variance after accounting for fixed effects."))
      for (runs in list(cells, public)) {
        latent_weight_expect_error(msa_fit(runs, type = type, link = link, interactions = TRUE), paste0(
          "Latent variance components are not identifiable: random-effect terms item:prompt",
          " cannot be separated from the fixed latent residual variance after accounting for fixed effects."))
      }
    }
  }
  expect_identical(called, 0L)
})

test_that("a linear combination of repeated latent groups can confound the residual", {
  grid <- expand.grid(a = 0:2, b = 0:2)
  runs <- data.frame(item_id = grid$a, prompt_id = grid$b,
    model_id = (grid$a + grid$b) %% 3L, block = (grid$a + 2L * grid$b) %% 3L, rep = 1L)
  dat <- latent_weight_frame(transform(runs, value = 0L))
  groups <- c("item", "prompt", "model", "block")
  pairs <- latent_weight_pairs(dat, groups, matrix(1, nrow(dat), 1L), rep(1, nrow(dat)))
  # Four distinct three-level partitions satisfy sum(P K_j P) = 3 P.
  for (group in groups) expect_true(all(table(dat[[group]]) == 3L))
  expect_equal(rowSums(pairs[, 1:4]) - 3 * pairs[, 5L], rep(0, nrow(pairs)),
    tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  called <- 0L
  forbidden <- function(...) { called <<- called + 1L; stop("Unexpected engine call.") }
  local_mocked_bindings(clmm = forbidden, .package = "ordinal")
  local_mocked_bindings(glmer = forbidden, .package = "lme4")
  for (type in c("ordinal", "binary")) {
    runs$value <- if (type == "ordinal") ordered(rep(1:3, 3L)) else rep(0:1, length.out = nrow(runs))
    for (link in c("probit", "logit")) {
      latent_weight_expect_error(msa_fit(runs, type = type, link = link), paste0(
        "Latent variance components are not identifiable: random-effect terms item, prompt, model, block",
        " cannot be separated from the fixed latent residual variance after accounting for fixed effects."))
    }
  }
  expect_identical(called, 0L)
})

test_that("a saturated fixed design has exactly zero residual information", {
  runs <- data.frame(item_id = 1:3, prompt_id = c(1, 1, 2), model_id = c(1, 2, 1),
    block = 1L, rep = 1L, value = ordered(1:3))
  dat <- latent_weight_frame(runs)
  X <- stats::model.matrix(~ prompt + model, dat)
  expect_equal(qr(X)$rank, nrow(X))
  expect_identical(llmsa:::msa_latent_information(dat, "item", X, residual = TRUE), matrix(0, 2L, 2L))
  called <- 0L
  forbidden <- function(...) { called <<- called + 1L; stop("Unexpected engine call.") }
  local_mocked_bindings(clmm = forbidden, .package = "ordinal")
  for (link in c("probit", "logit")) {
    latent_weight_expect_error(msa_fit(runs, type = "ordinal", link = link), paste0(
      "Latent variance components are not identifiable: random-effect terms item",
      " cannot be separated from the fixed latent residual variance after accounting for fixed effects."))
  }
  expect_identical(called, 0L)
})

test_that("zero frequency rows cannot hide equal partitions (seed 20261102)", {
  called <- 0L
  forbidden <- function(...) { called <<- called + 1L; stop("Unexpected engine call.") }
  local_mocked_bindings(clmm = forbidden, .package = "ordinal")
  local_mocked_bindings(glmer = forbidden, .package = "lme4")
  for (type in c("ordinal", "binary")) {
    runs <- latent_test_runs(type, items = 12L, seed = 20261102L)
    for (link in c("probit", "logit")) {
      message <- paste0("Latent variance components are not identifiable: random-effect terms prompt, model",
        " after accounting for fixed effects.")
      latent_weight_expect_error(msa_fit(runs, type = type, link = link,
        subset = as.integer(prompt) == as.integer(model)), message)
      for (multiple in c(1, 3)) {
        latent_weight_expect_error(msa_fit(runs, type = type, link = link,
          weights = multiple * (as.integer(prompt) == as.integer(model))), message)
      }
    }
  }
  # Zero weights can also remove the independent rows of the fixed design.
  runs <- latent_test_runs(items = 12L, prompts = 2L, models = 2L, seed = 20261102L)
  for (link in c("probit", "logit")) {
    latent_weight_expect_error(msa_fit(runs, type = "ordinal", link = link,
      weights = 1 * (as.integer(prompt) == as.integer(model))), paste0(
        "Ordinal two-level factors prompt, model are not identifiable: ",
        "the fixed-effect design is rank deficient."))
  }
  expect_identical(called, 0L)
})

test_that("latent diagnostics name all and only the confounded terms (seed 20261102)", {
  for (type in c("ordinal", "binary")) {
    runs <- latent_test_runs(type, items = 12L, seed = 20261102L)
    runs$model_id <- runs$prompt_id
    runs$block <- runs$prompt_id
    latent_weight_expect_error(msa_fit(runs, type = type), paste0(
      "Latent variance components are not identifiable: random-effect terms prompt, model, block",
      " after accounting for fixed effects."))
    nested <- latent_test_runs(type, items = 12L, seed = 20261102L)
    keep <- (as.integer(factor(nested$item_id)) - 1L) %/% 4L + 1L == as.integer(factor(nested$model_id))
    latent_weight_expect_error(msa_fit(nested[keep, ], type = type, interactions = TRUE), paste0(
      "Latent variance components are not identifiable: random-effect terms item, item:model",
      " after accounting for fixed effects."))
  }
  # The numeric path must retain its own contract, even for the same alias.
  runs <- msa_simulate(12L, 3L, 3L, 3L, seed = 20261102L)
  runs$model_id <- runs$prompt_id
  result <- latent_test_capture(tryCatch(msa_fit(runs, type = "numeric"), error = identity))$value
  expect_s3_class(result, "error")
  expect_identical(conditionMessage(result), "Numeric variance components are not identifiable.")
  expect_null(conditionCall(result))
})

test_that("latent frequency multiplicities affect residual identifiability (seed 20261102)", {
  reached <- 0L
  engine <- function(...) { reached <<- reached + 1L; stop("Identifiable design reached the engine.", call. = FALSE) }
  local_mocked_bindings(clmm = engine, .package = "ordinal")
  local_mocked_bindings(glmer = engine, .package = "lme4")
  for (type in c("ordinal", "binary")) {
    runs <- latent_test_runs(type, prompts = 1L, models = 1L, seed = 20261102L)
    runs <- runs[runs$rep == 1L, ]
    for (link in c("probit", "logit")) {
      expect_error(msa_fit(runs, type = type, link = link, weights = rep(2, nrow(runs))),
        "Identifiable design reached the engine.", fixed = TRUE)
    }
  }
  expect_identical(reached, 4L)
})

test_that("invalid latent frequencies fail with a named error before projection (seed 20261102)", {
  message <- "Ordinal and binary weights must be finite, non-negative numeric values with a finite positive sum."
  for (type in c("ordinal", "binary")) {
    runs <- latent_test_runs(type, items = 6L, prompts = 1L, models = 1L, seed = 20261102L)
    for (weights in list(rep(0, nrow(runs)), rep(-1, nrow(runs)),
      replace(rep(1, nrow(runs)), 1L, -0.5), rep(Inf, nrow(runs)),
      rep(.Machine$double.xmax, nrow(runs)), rep(TRUE, nrow(runs)))) {
      latent_weight_expect_error(msa_fit(runs, type = type, weights = weights), message)
    }
    weights <- rep(1, nrow(runs))
    weights[1L] <- NA_real_
    latent_weight_expect_error(msa_fit(runs, type = type, weights = weights, na.action = stats::na.pass), message)
  }
})

test_that("zero frequency rows supply neither response categories nor ordinal levels (seed 20261102)", {
  called <- 0L
  forbidden <- function(...) { called <<- called + 1L; stop("Unexpected engine call.") }
  local_mocked_bindings(clmm = forbidden, .package = "ordinal")
  local_mocked_bindings(glmer = forbidden, .package = "lme4")
  for (type in c("ordinal", "binary")) {
    runs <- latent_test_runs(type, items = 6L, prompts = 1L, models = 1L, seed = 20261102L)
    weights <- rep(1, nrow(runs))
    weights[1L] <- 0
    runs$value <- if (type == "ordinal") ordered(c(2L, rep(1L, nrow(runs) - 1L))) else
      c(1L, rep(0L, nrow(runs) - 1L))
    latent_weight_expect_error(msa_fit(runs, type = type, weights = weights),
      "Response is constant: at least two observed categories are needed.")
    # Positive total frequency one is valid, but supplies only one category.
    latent_weight_expect_error(msa_fit(runs, type = type, weights = c(1, rep(0, nrow(runs) - 1L))),
      "Response is constant: at least two observed categories are needed.")
  }
  runs <- latent_test_runs(items = 6L, prompts = 1L, models = 1L, seed = 20261102L)
  latent_weight_expect_error(msa_fit(runs, type = "ordinal", weights = 1 * (as.integer(item) <= 2L)),
    "Ordinal random-effect term item requires at least three observed levels.")
  expect_identical(called, 0L)
})

test_that("identifiable frequency-weighted fits retain direct engine components (seed 20261102)", {
  for (type in c("ordinal", "binary")) {
    runs <- latent_test_runs(type, items = 12L, models = 2L, seed = 20261102L)
    dat <- latent_weight_frame(runs)
    weights <- ifelse(runs$rep == 1L, 0, runs$rep)
    for (link in c("probit", "logit")) {
      for (contrasts in list(NULL, list(model = "contr.sum"))) {
        direct <- latent_test_capture(if (type == "ordinal") {
          ordinal::clmm(y ~ 1 + model + (1 | item) + (1 | prompt),
            data = dat, weights = weights, contrasts = contrasts, link = link)
        } else {
          lme4::glmer(y ~ 1 + (1 | item) + (1 | prompt) + (1 | model),
            data = dat, weights = weights, family = stats::binomial(link))
        })$value
        fit <- latent_test_capture(msa_fit(runs, type = type, link = link,
          weights = weights, contrasts = if (type == "ordinal") contrasts else NULL))$value
        vc <- if (type == "ordinal") ordinal::VarCorr(direct) else lme4::VarCorr(direct)
        reference <- c(vapply(vc, function(x) as.numeric(x)[1L], numeric(1)),
          Residual = if (link == "probit") 1 else pi^2 / 3)
        if (type == "ordinal") {
          # The sample variance of the two fitted level effects is the
          # range-method component under either contrast parameterization.
          levels <- if (is.null(contrasts)) c(0, 1) else c(1, -1)
          reference["model"] <- stats::var(levels * unname(direct$beta))
        }
        observed <- stats::setNames(fit$vc$variance, fit$vc$source)
        expect_setequal(names(observed), names(reference))
        expect_lte(max(abs(observed[names(reference)] - reference)) / sum(reference),
          numeric_tolerance("engine_ordinal", "rel_tol"))
        expect_identical(fit$data$y, dat$y)
        expect_equal(stats::nobs(fit$model), stats::nobs(direct))
        expect_equal(stats::model.weights(stats::model.frame(fit$model)),
          stats::model.weights(stats::model.frame(direct)), tolerance = 0)
      }
    }
  }
})
