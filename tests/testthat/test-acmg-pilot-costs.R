# ADR-011 no. 5 (E35): the pilot summary counts successful rows whose reported
# reasoning tokens exceed completion_tokens and, for the routed OpenRouter
# models, sums the billed usage.cost and the tokens at the plan prices (second
# evidence of the cost calculation). The pilot pass rules stay unchanged.

ap1_test_pilot_meta <- function(r, key, meta) {
  r$meta[r$model_id == key] <- meta_to_json(meta)
  r
}

test_that("recordings: reasoning above completion tokens is counted, billed and recomputed costs agree for OpenRouter", {
  skip_if_not_installed("httr2")
  p <- ap1_test_plan(); ap1_test_keys()
  on.exit(Sys.unsetenv(c("OPENAI_API_KEY", "OPENROUTER_API_KEY")), add = TRUE)
  httr2::local_mocked_responses(ap1_test_replay(p))
  backends <- acmg_api_backends(p)
  r <- ap1_test_pilot(p)
  for (key in names(backends)) {
    meta <- backends[[key]]("Synthetic replay prompt", acmg_models(p)[[key]]$id, list(model_id = key))$meta
    r <- ap1_test_pilot_meta(r, key, meta)
  }
  result <- acmg_pilot(r, p)
  tol <- ap1_test_tolerance(p, "arithmetic")
  for (key in names(backends)) {
    model <- acmg_models(p)[[key]]
    usage <- jsonlite::fromJSON(ap1_test_recording(key), simplifyVector = FALSE)$usage
    n <- sum(r$model_id == key)
    row <- result$summary[result$summary$model == key, , drop = FALSE]
    exceeds <- usage$completion_tokens_details$reasoning_tokens > usage$completion_tokens
    expect_identical(exceeds, key == "qwen", info = key) # 197 against 157 in qwen.json
    expect_identical(row$reasoning_exceeds_completion, if (exceeds) n else 0L, info = key)
    if (key == "sol") {
      expect_null(usage$cost)
      expect_true(is.na(row$usage_cost_usd))
      expect_true(is.na(row$recomputed_cost_usd))
    } else {
      expect_equal(row$usage_cost_usd, n * usage$cost, tolerance = tol, info = key)
      expect_equal(row$recomputed_cost_usd,
                   n * (usage$prompt_tokens * model$price_in + usage$completion_tokens * model$price_out) / 1e6,
                   tolerance = tol, info = key)
      expect_equal(row$usage_cost_usd, row$recomputed_cost_usd, tolerance = tol, info = key)
    }
  }
  # The billed cost is a diagnostic only: rules and projection do not use it.
  changed <- r
  for (key in c("llama", "qwen")) {
    meta <- jsonlite::fromJSON(r$meta[r$model_id == key][1L], simplifyVector = FALSE)
    meta$usage$cost <- 1000
    changed <- ap1_test_pilot_meta(changed, key, meta)
  }
  other <- acmg_pilot(changed, p)
  routed <- result$summary$model %in% c("llama", "qwen")
  expect_identical(other$rules, result$rules)
  expect_identical(other$projected_usd, result$projected_usd)
  expect_identical(other$summary$recomputed_cost_usd, result$summary$recomputed_cost_usd)
  expect_true(all(other$summary$usage_cost_usd[routed] > result$summary$usage_cost_usd[routed]))
})

test_that("the new pilot measurements use successful rows only and stay NA without complete fields", {
  p <- ap1_test_plan(); r <- ap1_test_pilot(p)
  tol <- ap1_test_tolerance(p, "arithmetic")
  meta <- function(key) {
    m <- list(id = paste0("synthetic-", key), model_snapshot = acmg_models(p)[[key]]$id,
              provider = acmg_models(p)[[key]]$provider_name,
              usage = list(prompt_tokens = 60, completion_tokens = 150, cost = 5e-5,
                           completion_tokens_details = list(reasoning_tokens = 200)))
    m[!vapply(m, is.null, logical(1))]
  }
  for (key in names(acmg_models(p))) r <- ap1_test_pilot_meta(r, key, meta(key))
  qwen <- which(r$model_id == "qwen")
  price <- acmg_models(p)$qwen
  at <- function(s, column) s[[column]][s$model == "qwen"]
  base <- acmg_pilot(r, p)$summary
  expect_identical(base$reasoning_exceeds_completion, rep(30L, 3))
  # Sol's direct endpoint is not routed; a cost field there is not summed.
  expect_true(is.na(base$usage_cost_usd[base$model == "sol"]) && is.na(base$recomputed_cost_usd[base$model == "sol"]))
  expect_equal(at(base, "usage_cost_usd"), 30 * 5e-5, tolerance = tol)
  expect_equal(at(base, "recomputed_cost_usd"), 30 * (60 * price$price_in + 150 * price$price_out) / 1e6, tolerance = tol)
  # A backend error removes the row from all three measurements.
  failed <- r; failed$error[qwen[1L]] <- "HTTP 503 Service Unavailable"
  s <- acmg_pilot(failed, p)$summary
  expect_identical(at(s, "reasoning_exceeds_completion"), 29L)
  expect_equal(at(s, "usage_cost_usd"), 29 * 5e-5, tolerance = tol)
  expect_equal(at(s, "recomputed_cost_usd"), 29 * (60 * price$price_in + 150 * price$price_out) / 1e6, tolerance = tol)
  # A missing billed cost or token count is not summed around.
  for (field in c("cost", "prompt_tokens", "completion_tokens")) {
    gap <- r; m <- meta("qwen"); m$usage[[field]] <- NULL
    gap$meta[qwen[1L]] <- meta_to_json(m)
    s <- acmg_pilot(gap, p)$summary
    expect_identical(is.na(at(s, "usage_cost_usd")), field == "cost", info = field)
    expect_identical(is.na(at(s, "recomputed_cost_usd")), field != "cost", info = field)
  }
  gap <- r; m <- meta("qwen"); m$usage$completion_tokens_details <- NULL
  gap$meta[qwen[1L]] <- meta_to_json(m)
  expect_identical(at(acmg_pilot(gap, p)$summary, "reasoning_exceeds_completion"), 29L)
})

test_that("the report states the cost basis and that reasoning token counts are shown as reported", {
  p <- ap1_test_plan()
  captured <- list()
  local_mocked_bindings(msa_fit = ap1_test_fit_stub, msa_report = function(grr, ..., output_file = "", assessment = NULL) {
    captured[[basename(output_file)]] <<- assessment
    output_file
  })
  acmg_evaluate(ap1_test_runs(p), p)
  for (key in names(acmg_models(p))) {
    section <- captured[[paste0("ap1-", key, ".html")]]$sections[["Pilot measurements"]]
    expect_identical(section$text, paste(
      "Latency and token summaries use available recorded values.",
      "Costs use usage.completion_tokens, which includes reasoning.",
      "Reasoning token counts are shown as reported by the API; for Qwen3-32B via DeepInfra they can exceed",
      "completion_tokens and are then not on the model's token scale."), info = key)
    expect_identical(section$table$model, key)
    expect_true(all(c("reasoning_exceeds_completion", "usage_cost_usd", "recomputed_cost_usd") %in% names(section$table)))
  }
})
