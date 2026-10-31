# Synthetic fixtures (seed 20261031); direct engines and the latent variance
# formula are the numerical oracles. No fitted outputs are frozen here.
latent_rework_components <- function(model, type, link = "probit") {
  variances <- if (type == "ordinal") ordinal::VarCorr(model) else lme4::VarCorr(model)
  c(vapply(variances, function(x) as.numeric(x)[1L], numeric(1)),
    Residual = if (link == "probit") 1 else pi^2 / 3)
}

latent_rework_expect_components <- function(fit, reference) {
  observed <- stats::setNames(fit$vc$variance, fit$vc$source)
  expect_setequal(names(observed), names(reference))
  expect_lte(max(abs(observed[names(reference)] - reference)) / sum(reference),
             numeric_tolerance("engine_ordinal", "rel_tol"))
}

test_that("latent calls retain evaluated controls and binary refits match bootMer (seed 20261031)", {
  runs <- latent_test_runs("binary", models = 1L, prompts = 1L)
  control <- lme4::glmerControl(optimizer = "bobyqa")
  direct_scope <- latent_test_capture(msa_fit(runs, type = "binary", link = "logit", control = control))$value
  outer_scope <- (function(r) {
    local_control <- lme4::glmerControl(optimizer = "bobyqa")
    latent_test_capture(msa_fit(r, type = "binary", link = "logit", control = local_control))$value
  })(runs)
  oracle <- function(model) {
    parts <- vapply(lme4::VarCorr(model), function(x) as.numeric(x)[1L], numeric(1))
    parts[["item"]] / (sum(parts) + pi^2 / 3)
  }
  for (fit in list(direct_scope, outer_scope)) {
    expect_identical(fit$model@call$control, control)
    expect_identical(fit$model@call$data, fit$data)
    expect_identical(fit$model@call$family$link, "logit")
    refit <- latent_test_capture(lme4::refit(fit$model))$value
    expect_s4_class(refit, "glmerMod")
    got <- latent_test_capture(msa_boot(fit, nsim = 3L, seed = 20261031L))$value
    expected <- latent_test_capture(lme4::bootMer(fit$model, FUN = oracle,
      nsim = 3L, seed = 20261031L, type = "parametric"))$value
    expect_true(all(is.finite(expected$t)))
    expect_equal(unname(attr(got, "boot")[, "icc_items"]), unname(expected$t[, 1L]),
                 tolerance = numeric_tolerance("engine_boot", "tol"))
  }
  ordinal <- (function(r) {
    local_control <- ordinal::clmm.control(method = "ucminf")
    latent_test_capture(msa_fit(r, type = "ordinal", control = local_control))$value
  })(latent_test_runs(models = 1L, prompts = 1L))
  expect_identical(ordinal$model$call$control, ordinal::clmm.control(method = "ucminf"))
  expect_identical(ordinal$model$call$data, ordinal$data)
  again <- eval(ordinal$model$call, envir = new.env(parent = globalenv()))
  latent_rework_expect_components(ordinal, latent_rework_components(again, "ordinal"))
  no_offset <- latent_test_capture(msa_fit(latent_test_runs(models = 1L, prompts = 1L),
                                           type = "ordinal", offset = NULL))
  expect_length(no_offset$warnings, 0L)
  expect_null(no_offset$value$model$call$offset)
})

test_that("latent row expressions align weights and offsets before choosing effects (seed 20261031)", {
  for (type in c("ordinal", "binary")) {
    runs <- latent_test_runs(type, items = 12L)
    runs$value <- as.character(runs$value)
    runs$value[1L] <- NA_character_
    runs$value[2L] <- "outside"
    labels <- if (type == "ordinal") paste0("c", 1:5) else c("0", "1")
    cleaned <- runs[-c(1L, 2L), ]
    dat <- data.frame(item = factor(cleaned$item_id), prompt = factor(cleaned$prompt_id),
      model = factor(cleaned$model_id), block = factor(cleaned$block),
      y = if (type == "ordinal") ordered(cleaned$value, levels = labels) else as.integer(cleaned$value))
    weight_base <- 1
    offset_scale <- 1 / 100
    weights <- ifelse(dat$model == "M2", NA_real_, weight_base + as.integer(dat$item) %% 2L)
    offsets <- offset_scale * as.integer(dat$item)
    keep <- dat$item != "I001" & dat$prompt != "P3" & dat$model != "M3"
    fit <- latent_test_capture(msa_fit(runs, type = type, levels = labels,
      subset = item != "I001" & prompt != "P3" & model != "M3",
      weights = ifelse(model == "M2", NA_real_, weight_base + as.integer(item) %% 2L),
      offset = offset_scale * as.integer(item), na.action = stats::na.exclude))$value
    selected <- which(keep & !is.na(weights))
    reference <- droplevels(dat[selected, ])
    reference$known_offset <- offsets[selected]
    selected_weights <- weights[selected]
    expected_model <- if (type == "ordinal") {
      ordinal::clmm(y ~ 1 + prompt + offset(known_offset) + (1 | item),
        data = reference, weights = selected_weights, link = "probit")
    } else {
      latent_test_capture(lme4::glmer(y ~ 1 + (1 | item) + (1 | prompt),
        data = reference, weights = selected_weights, offset = reference$known_offset,
        family = stats::binomial("probit")))$value
    }
    components <- latent_rework_components(expected_model, type)
    if (type == "ordinal") components <- c(components, prompt = stats::var(c(0, expected_model$beta[[1L]])))
    latent_rework_expect_components(fit, components)
    expect_identical(fit$data$y, reference$y)
    for (name in c("item", "prompt", "model", "block")) expect_identical(fit$data[[name]], reference[[name]])
    expect_identical(fit$n[c("items", "prompts", "models", "blocks", "observations")],
                     list(items = 11L, prompts = 2L, models = 1L, blocks = 1L, observations = nrow(reference)))
    expect_equal(stats::nobs(fit$model), stats::nobs(expected_model))
    expect_equal(stats::nobs(fit$model), if (type == "ordinal") sum(selected_weights) else nrow(reference))
    expect_identical(fit$n$reps_per_cell, c(3L, 3L))
    expect_false("model" %in% all.vars(fit$formula))
    expect_identical(fit$derived, if (type == "ordinal") "prompt" else character())
    frame <- stats::model.frame(fit$model)
    expect_equal(stats::model.weights(frame), weights[selected], tolerance = 0)
    expect_equal(stats::model.offset(frame), offsets[selected], tolerance = 0)
  }
})

test_that("latent index subsets retain order and duplicates and reject empty designs (seed 20261031)", {
  for (type in c("ordinal", "binary")) {
    runs <- latent_test_runs(type, items = 12L, models = 1L, prompts = 1L)
    selected <- c(rev(seq.int(4L, nrow(runs))), 4L, 5L, 6L)
    weights <- rep(1:2, length.out = nrow(runs))
    offsets <- seq_len(nrow(runs)) / nrow(runs)
    fit <- latent_test_capture(msa_fit(runs, type = type, subset = selected,
                                      weights = weights, offset = offsets))$value
    dat <- data.frame(item = factor(runs$item_id[selected]), y = runs$value[selected],
                       known_offset = offsets[selected])
    selected_weights <- weights[selected]
    expected <- if (type == "ordinal") {
      ordinal::clmm(y ~ 1 + offset(known_offset) + (1 | item), data = dat,
        weights = selected_weights, link = "probit")
    } else {
      latent_test_capture(lme4::glmer(y ~ 1 + (1 | item), data = dat,
        weights = selected_weights, offset = offsets[selected], family = stats::binomial("probit")))$value
    }
    latent_rework_expect_components(fit, latent_rework_components(expected, type))
    expect_identical(fit$data$y, dat$y)
    expect_identical(fit$n$items, 11L)
    expect_identical(fit$n$observations, length(selected))
    expect_equal(stats::nobs(fit$model), stats::nobs(expected))
    expect_equal(stats::nobs(fit$model), if (type == "ordinal") sum(selected_weights) else length(selected))
    expect_identical(fit$n$reps_per_cell, c(3L, 6L))
    expect_error(msa_fit(runs, type = type, subset = integer()), "No valid response categories")
    expect_error(msa_fit(runs, type = type, subset = y == y[1L]), "Response is constant")
    varying <- tapply(runs$value, runs$item_id, function(x) length(unique(x)) > 1L)
    chosen_item <- names(varying)[which(varying)[1L]]
    expect_error(msa_fit(runs, type = type, subset = item == chosen_item), "items are needed")
    expect_error(msa_fit(runs, type = type, weights = rep(NA_real_, nrow(runs))), "No valid response categories")
    expect_error(msa_fit(runs, type = type, weights = rep(NA_real_, nrow(runs)), na.action = stats::na.fail), "missing")
  }
})

test_that("ordinal identifiability checks cover all two-level pairs and observed interactions (seed 20261031)", {
  runs <- latent_test_runs(items = 12L, prompts = 1L, models = 1L)
  fields <- c(prompt = "prompt_id", model = "model_id", block = "block")
  for (pair in utils::combn(names(fields), 2L, simplify = FALSE)) {
    bad <- runs
    for (group in pair) bad[[fields[[group]]]] <- rep(1:2, length.out = nrow(bad))
    design <- stats::model.matrix(~ first + second,
      data = data.frame(first = factor(bad[[fields[[pair[1L]]]]]), second = factor(bad[[fields[[pair[2L]]]]])))
    expect_lt(qr(design)$rank, ncol(design))
    error <- tryCatch(msa_fit(bad, type = "ordinal"), error = identity)
    expect_s3_class(error, "error")
    expect_match(conditionMessage(error), "not identifiable")
    for (group in pair) expect_match(conditionMessage(error), group, fixed = TRUE)
  }
  bad <- runs
  bad$prompt_id <- bad$model_id <- rep(c("one", "two"), length.out = nrow(bad))
  expect_equal(nlevels(interaction(bad$prompt_id, bad$model_id, drop = TRUE)), 2L)
  expect_error(msa_fit(bad, type = "ordinal", interactions = TRUE),
               "Ordinal random-effect term prompt:model requires at least three observed levels.", fixed = TRUE)
  # A supplied contrast can also make an otherwise crossed design unidentified.
  crossed <- latent_test_runs(items = 12L, models = 2L, prompts = 1L)
  expect_error(msa_fit(crossed, type = "ordinal", contrasts = list(model = matrix(c(0, 0), ncol = 1L))),
               "model are not identifiable")
})

test_that("a zero fixed contrast does not make interior ordinal random effects singular (seed 20261031)", {
  runs <- msa_simulate(20L, 4L, 1L, 3L, vc = list(item = 1, prompt = 1, residual = 1), seed = 20261031L)
  runs$value <- cut(runs$value, c(-Inf, -1.5, -0.5, 0.5, 1.5, Inf),
                    labels = paste0("c", 1:5), ordered_result = TRUE)
  runs <- rbind(transform(runs, block = 1L), transform(runs, block = 2L))
  dat <- data.frame(item = factor(runs$item_id), prompt = factor(runs$prompt_id),
                      block = factor(runs$block), y = runs$value)
  oracle <- ordinal::clmm(y ~ 1 + block + (1 | item) + (1 | prompt), data = dat, link = "probit")
  components <- latent_rework_components(oracle, "ordinal")
  # The existing ordinal boundary is 1e-6 (ADR-027 Nr. 2), not a fit tolerance.
  expect_true(all(components[c("item", "prompt")] > 1e-6))
  derived <- stats::var(c(0, oracle$beta[[1L]]))
  expect_lt(derived, 1e-6)
  fit <- latent_test_capture(msa_fit(runs, type = "ordinal"))$value
  latent_rework_expect_components(fit, c(components, block = derived))
  expect_identical(fit$derived, "block")
  expect_false(fit$singular)
})

test_that("levels are validated before data and explicit binary labels ignore storage mode (seed 20261031)", {
  for (type in c("ordinal", "binary")) {
    for (bad in list(character(), "one", c("one", "one"), c("one", NA), c("", "two"))) {
      expect_error(msa_fit(data.frame(), type = type, levels = bad), "levels")
    }
  }
  runs <- latent_test_runs("binary", models = 1L, prompts = 1L)
  event <- runs$value
  cases <- list(
    list(value = event + 1L, labels = c("1", "2")),
    list(value = as.character(event + 1L), labels = c("1", "2")),
    list(value = factor(event + 1L, levels = 2:1), labels = c("1", "2")),
    list(value = as.logical(event), labels = c("FALSE", "TRUE")),
    list(value = as.character(as.logical(event)), labels = c("FALSE", "TRUE")))
  for (case in cases) {
    runs$value <- case$value
    fit <- latent_test_capture(msa_fit(runs, type = "binary", levels = case$labels))$value
    expect_identical(fit$data$y, event)
    reversed <- latent_test_capture(msa_fit(runs, type = "binary", levels = rev(case$labels)))$value
    expect_identical(reversed$data$y, 1L - event)
  }
  runs$value <- event
  expect_error(suppressWarnings(msa_fit(runs, type = "binary", levels = c("no", "yes"))),
               "No valid response categories")
  runs$value <- event + 1L
  expect_error(msa_fit(runs, type = "binary"), "Binary values must be 0 or 1.", fixed = TRUE)
})
