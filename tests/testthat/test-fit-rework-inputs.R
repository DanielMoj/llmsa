test_that("explicit local controls survive serialization, update, refit and bootstrap", {
  r <- numeric_test_runs()
  f <- (function(r) {
    local_control <- lme4::lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 10000L))
    local_start <- list(theta = c(1, 1, 1))
    msa_fit(r, control = local_control, start = local_start)
  })(r)
  f <- unserialize(serialize(f, NULL))
  call <- stats::getCall(f$model)
  expect_identical(call[[1L]], quote(lme4::lmer))
  expect_identical(eval(call$control), lme4::lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 10000L)))
  expect_identical(eval(call$start), list(theta = c(1, 1, 1)))
  expect_false(any(grepl("\\.\\.[0-9]+", deparse(call))))
  reference <- lme4::lmer(f$formula, data = f$data, REML = TRUE,
                          control = lme4::lmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 10000L)),
                          start = list(theta = c(1, 1, 1)))
  updated <- stats::update(f$model)
  refitted <- lme4::refit(f$model)
  expect_identical(updated@optinfo$optimizer, "bobyqa")
  expect_identical(refitted@optinfo$optimizer, "bobyqa")
  expect_equal(lme4::getME(updated, "theta"), lme4::getME(reference, "theta"),
               tolerance = numeric_tolerance("engine_boot", "tol"))
  got <- msa_boot(f, nsim = 4, seed = 20261029L)
  direct <- lme4::bootMer(reference, function(m) grr_stats(vc_from_model(m, "numeric", "probit"))$summary,
                          nsim = 4, seed = 20261029L)
  expect_equal(unname(attr(got, "boot")), unname(direct$t), tolerance = numeric_tolerance("engine_boot", "tol"))
  forward <- function(r, ...) msa_fit(r, ...)
  forwarded <- (function() {
    hidden_control <- lme4::lmerControl(optimizer = "bobyqa")
    forward(r, control = hidden_control)
  })()
  expect_identical(eval(stats::getCall(forwarded$model)$control), lme4::lmerControl(optimizer = "bobyqa"))
})

test_that("numeric model-frame expressions and retained rows agree with direct lmer", {
  r <- numeric_test_runs()
  r$value[c(2, 8)] <- NA_real_
  valid <- which(!is.na(r$value))
  d <- numeric_test_frame(r[valid, ])
  # The data mask must win over this deliberately conflicting caller variable.
  item <- "caller value"
  form <- y ~ 1 + (1 | item) + (1 | prompt)
  offset_scale <- 1 / 10
  w <- rep(1, nrow(d))
  w[d$item == "I002"] <- NA_real_
  f <- suppressMessages(msa_fit(r, interactions = FALSE, subset = item != "I001",
                                 weights = ifelse(item == "I002", NA_real_, 1),
                                 offset = offset_scale * as.integer(prompt), na.action = stats::na.exclude))
  direct <- suppressMessages(lme4::lmer(form, data = d, REML = TRUE, subset = item != "I001",
                                        weights = w, offset = offset_scale * as.integer(prompt), na.action = stats::na.exclude))
  used <- which(d$item != "I001" & !is.na(w))
  expect_identical(f$numerics$input_rows, valid[used])
  expect_identical(f$data, droplevels(d[used, names(f$data)]))
  expect_equal(lme4::getME(f$model, "theta"), lme4::getME(direct, "theta"),
               tolerance = numeric_tolerance("engine_boot", "tol"))
  expect_identical(unname(stats::model.response(stats::model.frame(f$model))), r$value[valid[used]])
  expect_identical(f$n$observations, as.integer(stats::nobs(f$model)))
  for (group in c("item", "prompt", "model", "block")) {
    count <- length(unique(d[[group]][used]))
    expect_identical(f$n[[paste0(group, "s")]], as.integer(count))
  }
  expected_counts <- table(interaction(d[used, c("item", "prompt", "model", "block")], drop = TRUE))
  expect_identical(f$n$reps_per_cell, as.integer(range(expected_counts)))
  expect_identical(msa_grr(f)$n, f$n)
  expect_identical(item, "caller value")
})

test_that("index subsets retain order, duplicates and original numeric row mapping", {
  r <- numeric_test_runs()
  r$value[3] <- "unreadable"
  r$value[4] <- NA_character_
  valid <- setdiff(seq_len(nrow(r)), c(3L, 4L))
  selected <- c(5L, 5L, 1L, seq.int(6L, length(valid)))
  out <- rework_capture(msa_fit(r, interactions = FALSE, subset = selected))
  expect_identical(vapply(out$warnings, conditionMessage, ""),
                   "1 value(s) could not be interpreted as numbers and were dropped.")
  f <- out$value
  expect_s3_class(f, "msa_fit")
  expect_identical(f$numerics$input_rows, valid[selected])
  expect_identical(f$data$y, as.numeric(r$value[valid[selected]]))
  expect_identical(f$n$observations, length(selected))
  expect_identical(f$n$observations, as.integer(stats::nobs(f$model)))
})

test_that("NaN forms are missing and every numeric grouping column is validated on both paths", {
  r <- numeric_test_runs()
  numeric <- r
  numeric$value[c(1, 3)] <- c(NaN, NA_real_)
  text <- r
  text$value <- as.character(text$value)
  text$value[c(1, 3)] <- c("NaN", NA_character_)
  for (args in list(list(), list(control = lme4::lmerControl()))) {
    a <- rework_capture(do.call(msa_fit, c(list(runs = numeric), args)))
    b <- rework_capture(do.call(msa_fit, c(list(runs = text), args)))
    expect_length(a$warnings, 0L)
    expect_length(b$warnings, 0L)
    expect_identical(a$value$numerics$input_rows, b$value$numerics$input_rows)
    expect_identical(a$value$numerics$input_rows, setdiff(seq_len(nrow(r)), c(1L, 3L)))
    for (column in c("item_id", "prompt_id", "model_id", "block")) {
      bad <- r
      bad[[column]][1L] <- NA
      rework_error(do.call(msa_fit, c(list(runs = bad), args)),
                   "Numeric grouping factors must not contain missing values.")
    }
  }
})

test_that("input diagnostics report exact causes without exposing implementation calls", {
  r <- numeric_test_runs()
  rework_error(msa_fit(r[, names(r) != "rep"]), "runs is missing required column(s): rep")
  r$value <- NA_real_
  rework_error(msa_fit(r), "No valid (non-missing) values to analyse.")
  r$value <- "unreadable"
  out <- rework_error(msa_fit(r), "No valid numeric values to analyse.")
  expect_identical(conditionMessage(out$warnings[[1L]]),
                   paste(nrow(r), "value(s) could not be interpreted as numbers and were dropped."))
  r$value <- NA_real_
  r$value[1L] <- 2
  rework_error(msa_fit(r), "Numeric response has zero variation.")
  r$value[2L] <- Inf
  rework_error(msa_fit(r), "Numeric response must contain only finite values.")
  r <- numeric_test_runs()
  r$item_id <- "one"
  rework_error(msa_fit(r), "At least two items are needed.")
  r <- rework_categorical_runs()
  r$value <- as.character(r$value)
  rework_error(msa_fit(r, type = "ordinal"), "`levels` (labels in scale order) are required for ordinal outcomes.")
  r$item_id <- rep(c("one", "two"), length.out = nrow(r))
  rework_error(msa_fit(r, type = "ordinal", levels = c("A", "B", "C", "D")),
               "At least three items are needed for ordinal outcomes.")
})

test_that("binary parsing preserves the declared event and rejects invalid values", {
  r <- rework_categorical_runs()
  event <- r$value %in% c("C", "D")
  forms <- list(event, as.integer(event), as.character(as.integer(event)),
                factor(ifelse(event, "event", "other"), levels = c("event", "other")))
  reference <- NULL
  for (i in seq_along(forms)) {
    r$value <- forms[[i]]
    f <- suppressMessages(msa_fit(r, type = "binary", link = "logit",
                                  levels = if (i == 4L) c("other", "event") else NULL))
    expect_identical(f$data$y, as.integer(event))
    expect_null(f$numerics)
    expect_type(f$vc$source, "character")
    expect_identical(tail(f$vc$source, 1L), "Residual")
    expect_identical(sum(f$vc$source == "Residual"), 1L)
    expect_equal(tail(f$vc$variance, 1L), pi^2 / 3, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
    oracle <- as.data.frame(lme4::VarCorr(f$model))
    expect_identical(f$vc$source, c(as.character(oracle$grp), "Residual"))
    expect_equal(f$vc$variance, c(oracle$vcov, pi^2 / 3),
                 tolerance = numeric_tolerance("arithmetic", "abs_tol"))
    if (is.null(reference)) reference <- f$model
    expect_equal(lme4::getME(f$model, "theta"), lme4::getME(reference, "theta"),
                 tolerance = numeric_tolerance("engine_boot", "tol"))
  }
  r$value <- ifelse(event, "event", "other")
  r$value[1L] <- "unknown"
  f <- suppressMessages(msa_fit(r, type = "binary", levels = c("other", "event")))
  expect_identical(f$data$y, as.integer(event[-1L]))
  expect_identical(f$n$observations, nrow(r) - 1L)
  # Probit fixes the latent normal residual scale to unit variance.
  expect_identical(tail(f$vc$variance, 1L), 1)
  r$value <- "invalid"
  rework_error(msa_fit(r, type = "binary"), "Binary values must be 0/1, logical, or labels with `levels` given.")
  r$value <- 2L
  rework_error(msa_fit(r, type = "binary"), "Binary values must be 0 or 1.")
})

test_that("ordinal levels, derived components and logit residual follow their formulas", {
  r <- rework_categorical_runs()
  ordered <- msa_fit(r, type = "ordinal", link = "logit")
  expect_true(is.ordered(ordered$data$y))
  expect_identical(levels(ordered$data$y), levels(r$value))
  expect_null(ordered$numerics)
  expect_identical(ordered$derived, c("model", "block"))
  expect_identical(attr(ordered$vc, "derived"), c("model", "block"))
  expect_identical(ordered$vc$source, c("item", "prompt", "model", "block", "Residual"))
  expect_type(ordered$vc$source, "character")
  expect_equal(tail(ordered$vc$variance, 1L), pi^2 / 3, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  oracle <- ordinal::VarCorr(ordered$model)
  expected <- vapply(oracle, function(component) as.numeric(component), numeric(1))
  expect_equal(ordered$vc$variance[match(names(expected), ordered$vc$source)], unname(expected),
               tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  for (group in ordered$derived) {
    coefficient <- stats::coef(ordered$model)[[paste0(group, levels(ordered$data[[group]])[2L])]]
    expect_equal(ordered$vc$variance[ordered$vc$source == group], unname(coefficient)^2 / 2,
                 tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  }
  r$value <- as.character(r$value)
  r$value[1L] <- "unknown"
  out <- rework_capture(msa_fit(r, type = "ordinal", levels = c("A", "B", "C", "D")))
  expect_identical(vapply(out$warnings, conditionMessage, ""), "1 value(s) are not among `levels` and were dropped.")
  expect_true(is.ordered(out$value$data$y))
  expect_identical(out$value$n$observations, nrow(r) - 1L)
})

test_that("single-level factors exclude their interactions and unequal cells are counted independently", {
  r <- msa_simulate(6, 3, 1, 3, 2,
    vc = list(item = 1, prompt = 0.2, block = 0.1, item_prompt = 0.1, residual = 0.3), seed = 13L)
  r <- r[-c(1, 3, 8, 12, 15, 29), ]
  f <- suppressMessages(msa_fit(r, interactions = TRUE))
  expect_false(any(grepl("model", deparse(f$formula), fixed = TRUE)))
  expected <- table(paste(r$item_id, r$prompt_id, r$model_id, r$block, sep = "|"))
  expect_identical(f$n$reps_per_cell, as.integer(range(expected)))
  expect_identical(f$n[c("items", "prompts", "models", "blocks", "observations")],
                   list(items = 6L, prompts = 3L, models = 1L, blocks = 2L, observations = nrow(r)))
  r <- msa_simulate(6, 2, 2, 3, 2, seed = 20261029L)
  f <- suppressMessages(msa_fit(r, control = lme4::lmerControl()))
  expect_setequal(f$vc$source, c("item", "prompt", "model", "block", "item:prompt", "item:model", "prompt:model", "Residual"))
  r$prompt_id <- "one"
  f <- suppressMessages(msa_fit(r, control = lme4::lmerControl()))
  expect_false(any(grepl("prompt", deparse(f$formula), fixed = TRUE)))
  expect_true("item:model" %in% f$vc$source)
})

test_that("the ordinal singular flag retains its documented reporting distinction", {
  # Own-output characterization of the legacy clmm reporting policy: no
  # independent statistical reference defines this implementation threshold.
  r <- rework_categorical_runs()
  r$model_id <- "one"
  r$block <- 1L
  local_mocked_bindings(clmm = function(...) structure(list(), class = "clmm"), .package = "ordinal")
  for (case in list(list(v = 0, expected = TRUE), list(v = 1e-6, expected = FALSE), list(v = 1, expected = FALSE))) {
    local_mocked_bindings(vc_from_model = function(...) data.frame(source = c("item", "Residual"),
                                                                    variance = c(case$v, 0)))
    f <- msa_fit(r, type = "ordinal")
    expect_identical(f$singular, case$expected)
  }
})
