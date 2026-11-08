# Small synthetic designs; full recovery studies belong to the acceptance suite.
plan_test_scenarios <- function() {
  data.frame(n_items = c(6L, 8L), n_prompts = c(3L, 2L), n_models = 2L,
             n_reps = 2L, n_blocks = c(1L, 2L), label = c("small", "blocked"),
             row.names = c("arbitrary", "row names"))
}

plan_expect_error <- function(expr, message) {
  error <- tryCatch(force(expr), error = identity)
  expect_s3_class(error, "error")
  expect_identical(conditionMessage(error), message)
  expect_null(conditionCall(error))
}

# Independent interpolation and sums; do not use a product summary helper.
plan_test_summary <- function(x, singular, truth) {
  n <- length(x)
  sorted <- sort(x)
  quantile <- function(p) {
    position <- 1 + (n - 1) * p
    lower <- floor(position)
    sorted[lower] + (position - lower) * (sorted[min(lower + 1, n)] - sorted[lower])
  }
  average <- sum(x) / n
  squares <- sum((x - average)^2)
  limits <- numeric_anchor("ANK-16")$study_var
  classify <- function(values) {
    result <- rep("marginal", length(values))
    result[values < limits$acceptable_below] <- "acceptable"
    result[values > limits$unacceptable_above] <- "unacceptable"
    result
  }
  c(mean = average, q2.5 = quantile(0.025), median = quantile(0.5), q97.5 = quantile(0.975),
    rmse = sqrt(sum((x - truth)^2) / n), pct_singular = 100 * sum(singular) / n,
    pct_misclassified = 100 * sum(classify(x) != classify(truth)) / n,
    bias = average - truth, empse = sqrt(squares / (n - 1)),
    mcse_bias = sqrt(squares / (n * (n - 1))), mcse_empse = sqrt(squares / (2 * (n - 1)^2)))
}

test_that("planning replicates retain the actual fits in RNG order and all summaries recompute", {
  scenarios <- plan_test_scenarios()
  vc <- list(item = 1, prompt = 0.1, model = 0.2, block = 0.01,
             item_prompt = 0.04, item_model = 0.08, prompt_model = 0.03, residual = 0.2)
  set.seed(20261110)
  before <- .Random.seed
  p <- msa_plan(scenarios, vc, nsim = 4L, seed = 142L, verbose = FALSE)
  expect_identical(.Random.seed, before)
  expect_identical(attr(p, "vc"), vc)
  expect_identical(attr(p, "nsim"), 4L)
  expect_identical(p$label, scenarios$label)
  expect_identical(rownames(p), c("1", "2"))
  actual <- attr(p, "replicates", exact = TRUE)
  expect_identical(actual$scenario, rep(1:2, each = 4L))
  expect_identical(actual$sim, rep(1:4, 2L))
  expected <- list()
  set.seed(142L)
  for (i in seq_len(nrow(scenarios))) {
    s <- scenarios[i, ]
    for (b in seq_len(4L)) {
      runs <- msa_simulate(s$n_items, s$n_prompts, s$n_models, s$n_reps, s$n_blocks, vc)
      fit <- suppressWarnings(suppressMessages(msa_fit(runs, type = "numeric")))
      item <- fit$vc$variance[fit$vc$source == "item"]
      other <- sum(fit$vc$variance[fit$vc$source != "item"])
      expected[[length(expected) + 1L]] <- data.frame(scenario = i, sim = b,
        estimate = 100 * sqrt(other / (other + item)), singular = isTRUE(fit$singular),
        prompt = fit$vc$variance[fit$vc$source == "prompt"])
    }
  }
  tolerance <- numeric_tolerance("arithmetic", "abs_tol")
  expect_equal(actual, do.call(rbind, expected), tolerance = tolerance)
  truth <- 100 * sqrt(sum(unlist(vc[names(vc) != "item"])) / sum(unlist(vc)))
  for (i in seq_len(nrow(p))) {
    reps <- actual[actual$scenario == i, ]
    expect_equal(p$grr_true[i], truth, tolerance = tolerance)
    reference <- plan_test_summary(reps$estimate, reps$singular, truth)
    expect_equal(unlist(p[i, names(reference)], use.names = TRUE), reference, tolerance = tolerance)
  }
  expect_identical(msa_plan(scenarios, vc, nsim = 4L, seed = 142L, verbose = FALSE), p)
})

test_that("a single prompt has no estimated prompt component and a single repetition has no EmpSE", {
  scenario <- plan_test_scenarios()[1L, ]
  scenario$n_prompts <- 1L
  scenario$n_blocks <- NULL
  p <- msa_plan(scenario, nsim = 1, seed = 143L, verbose = FALSE)
  r <- attr(p, "replicates")
  expect_identical(r$prompt, NA_real_)
  expect_identical(p$n_blocks, 1)
  for (nm in c("empse", "mcse_bias", "mcse_empse")) {
    expect_identical(p[[nm]], NA_real_, info = nm)
  }
  expect_identical(p$mean, r$estimate)
  expect_identical(p$q2.5, r$estimate)
  expect_identical(p$median, r$estimate)
  expect_identical(p$q97.5, r$estimate)
  expect_identical(p$bias, r$estimate - p$grr_true)
  expect_identical(p$rmse, abs(p$bias))
  expect_identical(p$pct_singular, 100 * r$singular)
  expect_type(r$singular, "logical")
  expect_false(anyNA(r$singular))
})

test_that("nsim validation and missing design columns fail before simulation with named errors", {
  calls <- 0L
  local_mocked_bindings(msa_simulate = function(...) { calls <<- calls + 1L; stop("must not simulate") })
  scenario <- plan_test_scenarios()[1L, ]
  for (bad in list(NULL, numeric(), c(1, 2), NA_real_, NaN, Inf, -Inf, 0, -1, 2.5, "3", TRUE, 1 + 1i)) {
    plan_expect_error(msa_plan(scenario, nsim = bad), "`nsim` must be a positive integer.")
  }
  for (column in c("n_items", "n_prompts", "n_models", "n_reps")) {
    missing <- scenario
    missing[[column]] <- NULL
    plan_expect_error(msa_plan(missing, nsim = 1), paste0("scenarios is missing required column(s): ", column))
  }
  expect_identical(calls, 0L)
})

test_that("planning rejects missing or invalid prompt estimates instead of inventing a boundary", {
  vc <- data.frame(source = "prompt", variance = 0)
  local_mocked_bindings(msa_fit = function(...) list(vc = vc, singular = TRUE),
                       grr_stats = function(...) list(summary = c(grr_pct_study_var = 20)))
  scenario <- plan_test_scenarios()[1L, ]
  valid <- msa_plan(scenario, nsim = 2L, seed = 145L, verbose = FALSE)
  expect_identical(attr(valid, "replicates")$prompt, c(0, 0))
  expect_identical(attr(valid, "replicates")$singular, c(TRUE, TRUE))
  expect_identical(valid$pct_singular, 100)
  expect_identical(valid$empse, 0)
  for (bad in list(data.frame(source = "Residual", variance = 1),
                  data.frame(source = character(), variance = numeric()),
                  data.frame(source = c("prompt", "prompt"), variance = c(1, 2)),
                  data.frame(source = "prompt", variance = "0.1"),
                  data.frame(source = "prompt", variance = TRUE),
                  data.frame(source = "prompt", variance = NA_real_),
                  data.frame(source = "prompt", variance = Inf),
                  data.frame(source = "prompt", variance = -1))) {
    vc <- bad
    plan_expect_error(msa_plan(scenario, nsim = 2L, seed = 145L, verbose = FALSE),
                      "Planning scenario 1, simulation 1: missing or invalid prompt variance.")
  }
})

test_that("planning rejects invalid GRR estimates without dropping repetitions", {
  estimate <- 20
  local_mocked_bindings(msa_fit = function(...) list(vc = data.frame(source = "prompt", variance = 0.1), singular = FALSE),
                       grr_stats = function(...) list(summary = list(grr_pct_study_var = estimate)))
  scenario <- plan_test_scenarios()[1L, ]
  for (bad in list(NULL, numeric(), c(10, 20), "20", TRUE, NA_real_, NaN, Inf, -1, 101)) {
    estimate <- bad
    plan_expect_error(msa_plan(scenario, nsim = 2L, seed = 146L, verbose = FALSE),
                      "Planning scenario 1, simulation 1: invalid %GRR estimate.")
  }
})

test_that("planning classification keeps exact anchored thresholds marginal", {
  limits <- numeric_anchor("ANK-16")$study_var
  lo <- limits$acceptable_below
  hi <- limits$unacceptable_above
  eps <- 2^-20
  estimates <- c(lo - eps, lo, lo + eps, hi - eps, hi, hi + eps)
  next_estimate <- 0L
  local_mocked_bindings(msa_fit = function(...) list(vc = data.frame(source = "prompt", variance = 0), singular = FALSE),
    grr_stats = function(...) {
      next_estimate <<- next_estimate + 1L
      list(summary = c(grr_pct_study_var = estimates[next_estimate]))
    })
  for (truth in c(lo / 2, lo, hi, hi * 2)) {
    next_estimate <- 0L
    p <- msa_plan(plan_test_scenarios()[1L, ], vc = list(item = 100^2 - truth^2, residual = truth^2),
                  nsim = length(estimates), seed = 147L, verbose = FALSE)
    expected <- if (truth %in% c(lo, hi)) 2 / 6 else 5 / 6
    expect_equal(p$pct_misclassified, 100 * expected, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
    expect_identical(attr(p, "replicates")$estimate, estimates)
  }
})

test_that("failed fits retain the original diagnostic, stop immediately and restore the RNG", {
  calls <- 0L
  local_mocked_bindings(msa_fit = function(...) {
    calls <<- calls + 1L
    stop("Synthetic fit failure: no component estimate.", call. = FALSE)
  })
  set.seed(20261111)
  before <- .Random.seed
  plan_expect_error(msa_plan(plan_test_scenarios(), nsim = 3L, seed = 148L, verbose = FALSE),
                    "Synthetic fit failure: no component estimate.")
  expect_identical(calls, 1L)
  expect_identical(.Random.seed, before)
  rm(".Random.seed", envir = .GlobalEnv)
  on.exit(assign(".Random.seed", before, envir = .GlobalEnv), add = TRUE)
  plan_expect_error(msa_plan(plan_test_scenarios(), nsim = 3L, seed = 148L, verbose = FALSE),
                    "Synthetic fit failure: no component estimate.")
  expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
})

test_that("planning reports the actual scenario sizes and seedless planning advances the RNG", {
  scenario <- plan_test_scenarios()[1L, ]
  scenario$n_blocks <- NULL
  set.seed(149L)
  before <- .Random.seed
  expect_message(p <- msa_plan(scenario, nsim = 1, verbose = TRUE),
                 "scenario 1/1: 6 items, 3 prompts, 2 models, 2 reps, 1 block(s)", fixed = TRUE)
  expect_false(identical(.Random.seed, before))
  expect_identical(p$n_blocks, 1)
})

test_that("plan printing shows every rounded summary and returns the unchanged result invisibly", {
  old_options <- options(width = 220, OutDec = ".")
  on.exit(options(old_options), add = TRUE)
  # Presentation expectation, not an independent numerical validation.
  for (n in c(1L, 3L)) {
    p <- msa_plan(plan_test_scenarios(), nsim = n, seed = 150L, verbose = FALSE)
    tab <- as.data.frame(p)
    fields <- c("mean", "q2.5", "median", "q97.5", "rmse", "pct_singular", "pct_misclassified",
                "bias", "empse", "mcse_bias", "mcse_empse")
    for (nm in fields) tab[[nm]] <- vapply(tab[[nm]], function(x) if (is.na(x)) "NA" else sprintf("%.1f", x), "")
    tab$grr_true <- NULL
    expected <- c(sprintf("Study-size planning by simulation (%d simulations per scenario)", n),
      sprintf("  true %%GRR (study variation) under the assumed variance components: %.1f %%", p$grr_true[1L]),
      utils::capture.output(print(tab, row.names = FALSE)))
    printed <- NULL
    output <- utils::capture.output(printed <- withVisible(print(p)))
    expect_identical(output, expected)
    expect_identical(printed$value, p)
    expect_false(printed$visible)
    legacy <- p
    for (column in c("bias", "empse", "mcse_bias", "mcse_empse")) legacy[[column]] <- NULL
    legacy_table <- tab[, setdiff(names(tab), c("bias", "empse", "mcse_bias", "mcse_empse"))]
    expect_identical(utils::capture.output(print(legacy)),
                     c(expected[1:2], utils::capture.output(print(legacy_table, row.names = FALSE))))
  }
})

test_that("the simulator follows the independent crossed-effects equation and seeded draw order", {
  vc <- list(item = 1, prompt = 2, model = 3, block = 4, item_prompt = 0.5,
             item_model = 1.5, prompt_model = 2.5, residual = 0.25)
  set.seed(151L)
  indices <- expand.grid(rep = 1:2, model = 1:2, prompt = 1:3, item = 1:4, block = 1:2)
  item <- stats::rnorm(4, sd = sqrt(vc$item))
  prompt <- stats::rnorm(3, sd = sqrt(vc$prompt))
  model <- stats::rnorm(2, sd = sqrt(vc$model))
  block <- stats::rnorm(2, sd = sqrt(vc$block))
  item_prompt <- stats::rnorm(4 * 3, sd = sqrt(vc$item_prompt))
  item_model <- stats::rnorm(4 * 2, sd = sqrt(vc$item_model))
  prompt_model <- stats::rnorm(3 * 2, sd = sqrt(vc$prompt_model))
  residual <- stats::rnorm(nrow(indices), sd = sqrt(vc$residual))
  truth <- 7 + item[indices$item]
  response <- truth + prompt[indices$prompt] + model[indices$model] + block[indices$block] +
    item_prompt[(indices$item - 1) * 3 + indices$prompt] +
    item_model[(indices$item - 1) * 2 + indices$model] +
    prompt_model[(indices$prompt - 1) * 2 + indices$model] + residual
  before <- .Random.seed
  runs <- msa_simulate(4, 3, 2, 2, 2, vc, mean = 7, seed = 151L)
  expect_identical(.Random.seed, before)
  expect_identical(runs$item_id, sprintf("I%03d", indices$item))
  expect_identical(runs$prompt_id, paste0("P", indices$prompt))
  expect_identical(runs$model_id, paste0("M", indices$model))
  expect_identical(runs$block, indices$block)
  expect_identical(runs$rep, indices$rep)
  expect_equal(runs$latent, truth, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
  expect_equal(runs$value, response, tolerance = numeric_tolerance("arithmetic", "abs_tol"))
})
