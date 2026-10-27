# K-M2-5: validation plan inst/validation/ap1/plan.yaml, acmg_plan(), call counts
# with msa_design() and the cost estimate. Values come from ANK-50, ANK-53 to
# ANK-59, ANK-61, ANK-62, ANK-65 to ANK-68; the field names inside models and
# design follow ACC-13, the other sections are checked by their values.

acc_m2_plan_yaml <- function() yaml::read_yaml(acc_m2_plan_file())

acc_m2_plan_models <- function(plan) {
  m <- plan$models
  keys <- vapply(m, function(e) as.character(e$key), "")
  stats::setNames(m, keys)
}

test_that("K-M2-5: plan.yaml has the fields cou, risk, acceptance, models, design, pilot, robustness, evaluation, budget, cutoff_date", {
  plan <- acc_m2_plan_yaml()
  need <- c("cou", "risk", "acceptance", "models", "design", "pilot", "robustness", "evaluation", "budget", "cutoff_date")
  expect_true(all(need %in% names(plan)), info = paste(setdiff(need, names(plan)), collapse = ", "))
  expect_true(is.character(plan$cou) && nzchar(paste(plan$cou, collapse = "")))
  expect_true(any(grepl("medium|mittel", acc_m2_leaves(plan$risk)$text, ignore.case = TRUE)))
  expect_identical(as.character(as.Date(as.character(plan$cutoff_date))), acc_anchor("ANK-50")$value)
})

test_that("K-M2-5: acmg_plan() reads plan.yaml, and acmg_plan(path) reads the given file", {
  plan_fun <- acc_m2_fn("acmg_plan")
  file_plan <- acc_m2_plan_yaml()
  got <- plan_fun()
  expect_true(is.list(got))
  expect_true(all(names(file_plan) %in% names(got)))
  expect_identical(as.numeric(got$design$seed), as.numeric(file_plan$design$seed))
  expect_identical(sort(vapply(got$models, function(e) as.character(e$key), "")), c("llama", "qwen", "sol"))
  copy <- tempfile(fileext = ".yaml")
  changed <- file_plan
  changed$design$seed <- 4242L
  yaml::write_yaml(changed, copy)
  other <- plan_fun(path = copy)
  expect_identical(as.numeric(other$design$seed), 4242)
  expect_identical(as.numeric(plan_fun()$design$seed), as.numeric(file_plan$design$seed))
})

test_that("K-M2-5: models: three entries sol, llama, qwen with id, endpoint, routing, reasoning, temperature, seed, knowledge cut-off and prices (ankerRef: ANK-50, ANK-53, ANK-54, ANK-55, ANK-61, ANK-65, ANK-66)", {
  plan <- acc_m2_plan_yaml()
  expect_length(plan$models, 3L)
  m <- acc_m2_plan_models(plan)
  expect_setequal(names(m), c("sol", "llama", "qwen"))
  fields <- c("id", "key", "endpoint", "provider_order", "quantizations", "reasoning", "temperature", "seed",
              "knowledge_cutoff", "price_in", "price_out")
  for (k in names(m)) expect_true(all(fields %in% names(m[[k]])), info = paste(k, paste(setdiff(fields, names(m[[k]])), collapse = ", ")))
  pol <- acc_anchor("ANK-61")$value
  files <- acc_anchor("ANK-94")$value$files
  a <- list(sol = acc_anchor("ANK-53")$value, llama = acc_anchor("ANK-54")$value, qwen = acc_anchor("ANK-55")$value)
  ids <- c(sol = a$sol$model_id, llama = a$llama$model_slug, qwen = a$qwen$model_slug)
  urls <- c(sol = files$sol.json$request_url, llama = files$llama.json$request_url, qwen = files$qwen.json$request_url)
  cut <- acc_m2_cutoffs()
  # price unit: US-Dollar per million tokens or per token (ACC-13), the same for all models
  per_token <- abs(as.numeric(m$sol$price_in) - a$sol$price_in_usd_per_mtok / 1e6) < 1e-12
  scale <- if (per_token) 1e6 else 1
  tol <- acc_anchor("ANK-53")$tolerance
  for (k in names(m)) {
    e <- m[[k]]
    expect_identical(as.character(e$id), unname(ids[k]), info = k)
    ep <- as.character(e$endpoint)
    expect_true(ep %in% c(urls[[k]], sub("/chat/completions$", "", urls[[k]])), info = paste(k, ep))
    expect_identical(as.numeric(e$seed), as.numeric(pol[[k]]$seed), info = k)
    expect_identical(as.character(as.Date(as.character(e$knowledge_cutoff))), format(cut[[k]], "%Y-%m-%d"), info = k)
    expect_lte(abs(as.numeric(e$price_in) * scale - a[[k]]$price_in_usd_per_mtok), tol)
    expect_lte(abs(as.numeric(e$price_out) * scale - a[[k]]$price_out_usd_per_mtok), tol)
    if (k == "sol") {
      expect_null(e$temperature)
      expect_identical(as.character(e$reasoning), a$sol$reasoning_plan)
      expect_length(unlist(e$provider_order), 0L)
      expect_length(unlist(e$quantizations), 0L)
    } else {
      expect_identical(as.numeric(e$temperature), as.numeric(pol[[k]]$temperature), info = k)
      expect_length(unlist(e$reasoning), 0L)
      expect_identical(as.character(unlist(e$provider_order)), a[[k]]$endpoint_tag, info = k)
      expect_identical(as.character(unlist(e$quantizations)), a[[k]]$quantization, info = k)
    }
  }
})

test_that("K-M2-5: design: 100 items, 3 prompts, 3 models, 3 replicates, 2 blocks, seed of ANK-59 (ankerRef: ANK-56, ANK-59)", {
  d <- acc_m2_plan_yaml()$design
  b <- acc_anchor("ANK-56")$value$main_breakdown
  expect_identical(as.numeric(d$items), as.numeric(b$items))
  expect_identical(as.numeric(d$prompts), as.numeric(b$prompts))
  expect_identical(as.numeric(d$models), as.numeric(length(acc_anchor("ANK-61")$value)))
  expect_identical(as.numeric(d$replicates), as.numeric(b$replicates))
  expect_identical(as.numeric(d$blocks), as.numeric(b$blocks))
  expect_identical(as.numeric(d$seed), as.numeric(acc_anchor("ANK-59")$value$seed))
  expect_true("order" %in% names(d))
})

test_that("K-M2-5: acceptance, pilot, evaluation and budget carry the values of ANK-57, ANK-58, ANK-67 and ANK-68", {
  plan <- acc_m2_plan_yaml()
  acc <- acc_m2_leaves(plan$acceptance)
  a58 <- acc_anchor("ANK-58")$value
  for (v in c(a58$grr_pct_study_var$acceptable_below, a58$grr_pct_study_var$marginal_below,
              a58$kappa_linear_modal$acceptable_min, a58$kappa_linear_modal$marginal_min,
              a58$dangerous_errors$marginal_max, a58$dangerous_errors$unacceptable_min)) {
    expect_true(acc_m2_has_number(acc, v), info = paste("acceptance", v))
  }
  expect_true(acc_m2_has_number(acc, a58$robustness$delta_p_limit) || acc_m2_has_number(acc, 100 * a58$robustness$delta_p_limit))
  expect_true(acc_m2_has_number(acc, a58$robustness$sme_alpha))
  pil <- acc_m2_leaves(plan$pilot)
  a67 <- acc_anchor("ANK-67")$value
  for (v in c(a67$pilot_items, a67$templates, a67$replicates, a67$calls_per_model, a67$parser_hits_min)) {
    expect_true(acc_m2_has_number(pil, v), info = paste("pilot", v))
  }
  expect_true(acc_m2_has_number(pil, a67$cost_quantile) || acc_m2_has_number(pil, 100 * a67$cost_quantile))
  expect_true(acc_m2_has_number(pil, a67$error_share_trigger) || acc_m2_has_number(pil, 100 * a67$error_share_trigger))
  ev <- acc_m2_leaves(plan$evaluation)
  a68 <- acc_anchor("ANK-68")$value
  expect_true(acc_m2_has_number(ev, a68$kappa_bootstrap$replicates))
  expect_true(acc_m2_has_number(ev, a68$kappa_bootstrap$level) || acc_m2_has_number(ev, 100 * a68$kappa_bootstrap$level))
  expect_true(acc_m2_has_number(ev, a68$kappa_bootstrap$seed))
  expect_true(acc_m2_has_number(ev, a68$modal_calls_per_item_and_model))
  for (sc in unlist(a68$fallback_fit$scores)) expect_true(acc_m2_has_number(ev, sc), info = paste("score", sc))
  expect_true(acc_m2_has_number(acc_m2_leaves(plan$budget), acc_anchor("ANK-57")$value$budget_eur))
})

test_that("K-M2-5: robustness: eight factors F1 to F8 with two levels, the building blocks of ANK-62, twelve runs, response measure of ANK-68", {
  r <- acc_m2_plan_yaml()$robustness
  lv <- acc_m2_leaves(r)
  text <- c(lv$text, acc_m2_names_deep(r))
  for (f in paste0("F", 1:8)) expect_true(any(grepl(paste0("(^|[^0-9A-Za-z])", f, "($|[^0-9])"), text)), info = f)
  blocks <- unlist(acc_anchor("ANK-62")$value$blocks)
  for (b in blocks) expect_true(b %in% trimws(lv$text), info = b)
  expect_true(acc_m2_has_number(lv, 12))
  expect_true(acc_m2_has_number(lv, acc_anchor("ANK-68")$value$robustness_response$correction))
})

test_that("K-M2-5: msa_design() with the plan values gives 5,400 main-plan rows (1,800 per model), 1,200 per model for Plackett-Burman and 30 per model in the pilot (ankerRef: ANK-56, ANK-67)", {
  plan <- acc_m2_plan_yaml()
  m <- acc_m2_plan_models(plan)
  models <- stats::setNames(vapply(m, function(e) as.character(e$id), ""), names(m))
  items <- acc_m2_fn("acmg_items")()
  items$text <- items$hgvs
  tpl <- acc_m2_main_templates()
  main <- llmsa::msa_design(items, tpl, models, reps = plan$design$replicates, blocks = plan$design$blocks,
                            seed = plan$design$seed)
  a56 <- acc_anchor("ANK-56")$value
  expect_identical(nrow(main), as.integer(3 * a56$calls_per_model_main))
  expect_identical(as.integer(table(main$model_id)[names(models)]), rep(as.integer(a56$calls_per_model_main), 3L))
  rob <- acc_m2_fn("acmg_prompts")(robustness = TRUE)
  pb_rows <- 0L
  for (i in seq_len(nrow(rob))) {
    d <- llmsa::msa_design(items, stats::setNames(as.character(rob$template[i]), as.character(rob$prompt_id[i])), models,
                           reps = 1, blocks = 1, seed = plan$design$seed)
    pb_rows <- pb_rows + nrow(d)
  }
  expect_identical(pb_rows, as.integer(3 * a56$calls_per_model_plackett_burman))
  pilot <- acc_m2_fn("acmg_items")(pilot = TRUE)
  pilot$text <- pilot$hgvs
  pd <- llmsa::msa_design(pilot, tpl, models, reps = 1, blocks = 1, seed = plan$design$seed)
  expect_identical(as.integer(table(pd$model_id)[names(models)]), rep(as.integer(acc_anchor("ANK-67")$value$calls_per_model), 3L))
  expect_identical(as.integer(a56$calls_per_model_main + a56$calls_per_model_plackett_burman), as.integer(a56$calls_per_model_total))
})

test_that("K-M2-5: the cost estimate from the price anchors and the token assumptions of ANK-56 stays below ANK-57", {
  plan <- acc_m2_plan_yaml()
  m <- acc_m2_plan_models(plan)
  a56 <- acc_anchor("ANK-56")$value
  a <- list(sol = acc_anchor("ANK-53")$value, llama = acc_anchor("ANK-54")$value, qwen = acc_anchor("ANK-55")$value)
  cost <- 0
  for (k in names(a)) {
    cost <- cost + a56$calls_per_model_total *
      (a56$tokens_in_per_call * a[[k]]$price_in_usd_per_mtok + a56$tokens_out_per_call_max * a[[k]]$price_out_usd_per_mtok) / 1e6
  }
  # ANK-57: limits and estimates in US-Dollar stay below the euro amount of the budget
  expect_lt(cost, acc_anchor("ANK-57")$value$budget_eur)
  # the same estimate from the prices written in plan.yaml
  per_token <- abs(as.numeric(m$sol$price_in) - a$sol$price_in_usd_per_mtok / 1e6) < 1e-12
  scale <- if (per_token) 1e6 else 1
  plan_cost <- sum(vapply(names(a), function(k) a56$calls_per_model_total *
    (a56$tokens_in_per_call * as.numeric(m[[k]]$price_in) * scale + a56$tokens_out_per_call_max * as.numeric(m[[k]]$price_out) * scale) / 1e6, 0))
  expect_lt(plan_cost, acc_anchor("ANK-57")$value$budget_eur)
  expect_lte(abs(plan_cost - cost), 3 * a56$calls_per_model_total * (a56$tokens_in_per_call + a56$tokens_out_per_call_max) *
               acc_anchor("ANK-53")$tolerance / 1e6)
})
