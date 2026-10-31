# Synthetic designs. The independent covariance-space calculation below uses
# observation pairs, not the grouping-level products in the implementation.
# Numerical comparison bounds come from ANK-TOL; no fitted output is frozen.
latent_ident_frame <- function(runs) {
  data.frame(item = factor(runs$item_id), prompt = factor(runs$prompt_id),
    model = factor(runs$model_id), block = factor(runs$block), y = runs$value)
}

latent_ident_covariance <- function(group) {
  outer(as.character(group), as.character(group), `==`) * 1
}

latent_ident_expect_error <- function(expr, terms) {
  result <- latent_test_capture(tryCatch(expr, error = identity))$value
  expect_s3_class(result, "error")
  if (inherits(result, "error")) {
    expect_match(conditionMessage(result), "not identifiable", fixed = TRUE)
    for (term in terms) {
      expect_match(conditionMessage(result), paste0("(^|[[:space:],])", term, "([[:space:],.]|$)"))
    }
  }
}

latent_ident_expect_engine <- function(fit, model, type, link, fixed = character()) {
  vc <- if (type == "ordinal") ordinal::VarCorr(model) else lme4::VarCorr(model)
  reference <- c(vapply(vc, function(x) as.numeric(x)[1L], numeric(1)),
    Residual = if (link == "probit") 1 else pi^2 / 3)
  for (group in fixed) {
    coefficient <- model$beta[startsWith(names(model$beta), group)]
    reference[group] <- stats::var(c(0, coefficient))
  }
  observed <- stats::setNames(fit$vc$variance, fit$vc$source)
  expect_setequal(names(observed), names(reference))
  expect_lte(max(abs(observed[names(reference)] - reference)) / sum(reference),
             numeric_tolerance("engine_ordinal", "rel_tol"))
}

test_that("latent information equals an independent covariance-pair calculation", {
  dat <- expand.grid(item = factor(1:4), prompt = factor(1:3),
    model = factor(1:2), block = factor(1:2))
  dat <- dat[-c(2L, 7L, 19L, 34L, 45L), ]
  groups <- c("item", "prompt", "item:prompt", "item:model", "prompt:model")
  for (contrasts in list(NULL, list(model = "contr.sum", block = "contr.sum"))) {
    X <- stats::model.matrix(~ model + block, dat, contrasts.arg = contrasts)
    P <- diag(nrow(dat)) - X %*% solve(crossprod(X), t(X))
    labels <- list(dat$item, dat$prompt, interaction(dat$item, dat$prompt),
      interaction(dat$item, dat$model), interaction(dat$prompt, dat$model))
    covariance <- lapply(labels, function(g) P %*% latent_ident_covariance(g) %*% P)
    expected <- outer(seq_along(groups), seq_along(groups), Vectorize(function(i, j) {
      sum(covariance[[i]] * covariance[[j]])
    }))
    expect_no_error(got <- llmsa:::msa_latent_information(dat, groups, X))
    expect_equal(got, expected, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
    expect_identical(got, t(got))
    # One grouping term must still return a 1 x 1 information matrix.
    expect_equal(llmsa:::msa_latent_information(dat, "item", X),
                 expected[1L, 1L, drop = FALSE], tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  }
})

test_that("latent fits reject equal partitions across all grouping pairs before engines (seed 20261031)", {
  called <- 0L
  forbidden <- function(...) { called <<- called + 1L; stop("Engine reached an unidentified design.") }
  local_mocked_bindings(clmm = forbidden, .package = "ordinal")
  local_mocked_bindings(glmer = forbidden, .package = "lme4")
  fields <- c(item = "item_id", prompt = "prompt_id", model = "model_id", block = "block")
  for (type in c("ordinal", "binary")) {
    runs <- latent_test_runs(type, items = 12L)
    for (pair in utils::combn(names(fields), 2L, simplify = FALSE)) {
      bad <- runs
      partition <- rep(1:3, length.out = nrow(bad))
      bad[[fields[[pair[1L]]]]] <- paste0("left", partition)
      bad[[fields[[pair[2L]]]]] <- paste0("right", 4L - partition)
      expect_identical(latent_ident_covariance(bad[[fields[[pair[1L]]]]]),
                       latent_ident_covariance(bad[[fields[[pair[2L]]]]]))
      for (link in c("probit", "logit")) {
        latent_ident_expect_error(msa_fit(bad, type = type, link = link), pair)
      }
    }
  }
  expect_identical(called, 0L)
})

test_that("nested items alias their model interaction after row selection (seed 20261031)", {
  called <- 0L
  forbidden <- function(...) { called <<- called + 1L; stop("Engine reached an unidentified design.") }
  local_mocked_bindings(clmm = forbidden, .package = "ordinal")
  local_mocked_bindings(glmer = forbidden, .package = "lme4")
  for (type in c("ordinal", "binary")) {
    runs <- latent_test_runs(type, items = 12L)
    keep <- (as.integer(factor(runs$item_id)) - 1L) %/% 4L + 1L == as.integer(factor(runs$model_id))
    nested <- runs[keep, ]
    expect_identical(latent_ident_covariance(nested$item_id),
                     latent_ident_covariance(interaction(nested$item_id, nested$model_id)))
    latent_ident_expect_error(msa_fit(nested, type = type, interactions = TRUE), c("item", "item:model"))
    latent_ident_expect_error(msa_fit(runs, type = type, interactions = TRUE,
      subset = (as.integer(item) - 1L) %/% 4L + 1L == as.integer(model)), c("item", "item:model"))
  }
  expect_identical(called, 0L)
})

test_that("two-level binary model and block variances cannot share a partition (seed 20261031)", {
  runs <- latent_test_runs("binary", items = 12L, models = 2L)
  runs$block <- 3L - as.integer(factor(runs$model_id))
  expect_identical(latent_ident_covariance(runs$model_id), latent_ident_covariance(runs$block))
  latent_ident_expect_error(msa_fit(runs, type = "binary"), c("model", "block"))
})

test_that("ordinal fixed effects can span a random term or the entire random design (seed 20261031)", {
  runs <- latent_test_runs(items = 12L, prompts = 1L, models = 2L, blocks = 2L)
  runs <- runs[runs$model_id == "M1" | runs$block == 1L, ]
  runs$prompt_id <- paste(runs$model_id, runs$block, sep = "-")
  for (only_item in c(FALSE, TRUE)) {
    bad <- runs
    term <- "prompt"
    if (only_item) {
      bad$item_id <- bad$prompt_id
      bad$prompt_id <- "P1"
      term <- "item"
    }
    dat <- latent_ident_frame(bad)
    for (contrasts in list(NULL, list(model = "contr.sum", block = "contr.sum"))) {
      X <- stats::model.matrix(~ model + block, dat, contrasts.arg = contrasts)
      Z <- stats::model.matrix(~ 0 + group, data.frame(group = dat[[term]]))
      # Independent rank proof: all indicator columns are already fixed.
      expect_equal(qr(X)$rank, ncol(X))
      expect_equal(qr(cbind(X, Z))$rank, ncol(X))
      expect_identical(llmsa:::msa_latent_information(dat, term, X), matrix(0, 1L, 1L))
      if (!only_item) {
        P <- diag(nrow(dat)) - X %*% solve(crossprod(X), t(X))
        item_covariance <- P %*% latent_ident_covariance(dat$item) %*% P
        expected <- diag(c(sum(item_covariance^2), 0))
        expect_equal(llmsa:::msa_latent_information(dat, c("item", "prompt"), X), expected,
                     tolerance = numeric_tolerance("arithmetic", "abs_tol"))
      }
      latent_ident_expect_error(msa_fit(bad, type = "ordinal", contrasts = contrasts), term)
    }
  }
  # Three item indicators can also lie in a strictly larger fixed space.
  bad <- runs
  bad$item_id <- bad$prompt_id
  bad$prompt_id <- rep(c("P1", "P2"), length.out = nrow(bad))
  dat <- latent_ident_frame(bad)
  X <- stats::model.matrix(~ prompt + model + block, dat)
  Z <- stats::model.matrix(~ 0 + item, dat)
  expect_lt(ncol(Z), ncol(X))
  expect_equal(qr(cbind(X, Z))$rank, ncol(X))
  expect_identical(llmsa:::msa_latent_information(dat, "item", X), matrix(0, 1L, 1L))
  latent_ident_expect_error(msa_fit(bad, type = "ordinal"), "item")
})

test_that("covariance components can be confounded without identical partitions", {
  grid <- data.frame(item_id = 1:4, prompt_id = c(1, 1, 2, 2),
    model_id = c(1, 2, 1, 2), block = c(1, 2, 2, 1))
  runs <- grid[rep(1:4, each = 3L), ]
  runs$rep <- rep(1:3, 4L)
  runs$value <- rep(c(0L, 1L, 0L), 4L)
  dat <- latent_ident_frame(runs)
  P <- diag(nrow(dat)) - 1 / nrow(dat)
  covariance <- lapply(dat[c("item", "prompt", "model", "block")], latent_ident_covariance)
  # For these four cells, 2 K_item = K_prompt + K_model + K_block on
  # the intercept-orthogonal space. All four partitions differ.
  relation <- 2 * covariance$item - covariance$prompt - covariance$model - covariance$block
  expect_equal(P %*% relation %*% P, matrix(0, nrow(dat), nrow(dat)),
               tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  for (pair in utils::combn(names(covariance), 2L, simplify = FALSE)) {
    expect_false(identical(covariance[[pair[1L]]], covariance[[pair[2L]]]))
  }
  latent_ident_expect_error(msa_fit(runs, type = "binary"), c("item", "prompt", "model", "block"))
})

test_that("identifiable nested and crossed latent designs retain direct engine fits (seed 20261031)", {
  for (type in c("ordinal", "binary")) {
    runs <- latent_test_runs(type, items = 12L, models = 1L)
    runs$model_id <- paste0("M", (as.integer(factor(runs$item_id)) - 1L) %/% 4L + 1L)
    dat <- latent_ident_frame(runs)
    for (link in c("probit", "logit")) {
      direct <- latent_test_capture(if (type == "ordinal") {
        ordinal::clmm(y ~ 1 + (1 | item) + (1 | prompt) + (1 | model), data = dat, link = link)
      } else {
        lme4::glmer(y ~ 1 + (1 | item) + (1 | prompt) + (1 | model), data = dat,
          family = stats::binomial(link))
      })$value
      expect_no_error(fit <- latent_test_capture(msa_fit(runs, type = type, link = link))$value)
      latent_ident_expect_engine(fit, direct, type, link)
    }
    runs <- latent_test_runs(type, items = 12L, models = 2L, blocks = 2L)
    dat <- latent_ident_frame(runs)
    direct <- latent_test_capture(if (type == "ordinal") {
      ordinal::clmm(y ~ 1 + model + block + (1 | item) + (1 | prompt), data = dat, link = "probit")
    } else {
      lme4::glmer(y ~ 1 + (1 | item) + (1 | prompt) + (1 | model) + (1 | block), data = dat,
        family = stats::binomial("probit"))
    })$value
    expect_no_error(fit <- latent_test_capture(msa_fit(runs, type = type))$value)
    latent_ident_expect_engine(fit, direct, type, "probit", if (type == "ordinal") c("model", "block") else character())
  }
})
