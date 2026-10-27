# K-M2-7: robustness runs from pb_design(8, n_runs = 12) with the seed of ANK-59,
# composed from the building blocks of ANK-62; run.R --part pilot|main|robustness
# with resume; the system prompt through the design column `system`; evaluation of
# the robustness runs (ANK-58, ANK-68). Expected texts come from the mini-reference
# acc_m2_compose() and acc_m2_variant_text() of setup-m2.R.

acc_m2_rob_table <- function() {
  r <- as.data.frame(acc_m2_fn("acmg_prompts")(robustness = TRUE), stringsAsFactors = FALSE)
  need <- c("prompt_id", paste0("F", 1:8), "template", "system")
  if (!all(need %in% names(r))) stop("acceptance: acmg_prompts(robustness = TRUE) lacks ", paste(setdiff(need, names(r)), collapse = ", "), call. = FALSE)
  r
}

acc_m2_sample_item <- function() {
  items <- acc_m2_items()
  er <- items[items$source == "erepo" & nzchar(items$protein), , drop = FALSE]
  if (!nrow(er)) stop("acceptance: no erepo item with p. notation in items.csv", call. = FALSE)
  as.list(er[1, , drop = FALSE])
}

test_that("K-M2-7: pb_design(8, n_runs = 12) with the seed of ANK-59 is an orthogonal two-level design", {
  pb <- acc_m2_pb()
  expect_identical(dim(pb), c(12L, 8L))
  expect_identical(colnames(pb), paste0("F", 1:8))
  expect_true(all(pb %in% c(-1, 1)))
  expect_equal(unname(crossprod(pb)), diag(12, 8))
  expect_true(any(apply(pb, 1, function(r) all(r < 0))))
})

test_that("K-M2-7: acmg_prompts(robustness = TRUE) gives the twelve runs pb01 to pb12 in design order with factors F1 to F8 (ankerRef: ANK-59, ANK-62)", {
  r <- acc_m2_rob_table()
  pb <- acc_m2_pb()
  expect_identical(nrow(r), 12L)
  expect_identical(as.character(r$prompt_id), unlist(acc_anchor("ANK-62")$value$pb_design$prompt_ids))
  lev <- as.matrix(r[, paste0("F", 1:8)])
  storage.mode(lev) <- "double"
  dimnames(lev) <- NULL
  expect_identical(lev, unname(pb))
})

test_that("K-M2-7: each run carries the user message composed from the building blocks and the system prompt of F6 (ankerRef: ANK-62)", {
  r <- acc_m2_rob_table()
  for (i in seq_len(nrow(r))) {
    lev <- unlist(r[i, paste0("F", 1:8)])
    want <- acc_m2_compose(lev)
    expect_identical(as.character(r$template[i]), want$template, info = r$prompt_id[i])
    sys <- as.character(r$system[i])
    if (is.na(sys)) sys <- ""
    expect_identical(sys, want$system, info = r$prompt_id[i])
  }
  minus <- which(apply(as.matrix(r[, paste0("F", 1:8)]), 1, function(x) all(x < 0)))
  expect_length(minus, 1L)
  expect_identical(as.character(r$template[minus]), unname(acc_m2_templates()[["concise"]]))
})

test_that("K-M2-7: every level of the eight factors is visible in the generated text of every run", {
  r <- acc_m2_rob_table()
  b <- acc_anchor("ANK-62")$value$blocks
  item <- acc_m2_sample_item()
  for (i in seq_len(nrow(r))) {
    lev <- unlist(r[i, paste0("F", 1:8)])
    id <- r$prompt_id[i]
    txt <- acc_m2_fill(as.character(r$template[i]), item$gene, acc_m2_variant_text(item, lev[["F1"]], lev[["F2"]]))
    lang <- if (lev[["F8"]] > 0) "de" else "en"
    # F1 transcript, F2 p. notation
    expect_identical(grepl(paste0(item$transcript, ":"), txt, fixed = TRUE), lev[["F1"]] < 0, info = paste(id, "F1"))
    expect_identical(grepl(paste0("(", item$protein, ")"), txt, fixed = TRUE), lev[["F2"]] > 0, info = paste(id, "F2"))
    # F3 transposed letters in the task sentence
    expect_identical(grepl("accoridng|entsprechned", txt), lev[["F3"]] > 0, info = paste(id, "F3"))
    # F4 order of task and format sentence
    task_at <- regexpr(if (lev[["F8"]] > 0) "Klassifiziere" else "Classify", txt, fixed = TRUE)
    fmt_at <- regexpr(if (lev[["F8"]] > 0) "Antworte" else "Answer", txt, fixed = TRUE)
    expect_identical(task_at < fmt_at, lev[["F4"]] < 0, info = paste(id, "F4"))
    # F5 context paragraph with a blank line
    expect_identical(startsWith(txt, paste0(b$context[[lang]], "\n\n")), lev[["F5"]] > 0, info = paste(id, "F5"))
    # F6 system prompt
    sys <- as.character(r$system[i]); if (is.na(sys)) sys <- ""
    expect_identical(sys == b$system$en, lev[["F6"]] > 0, info = paste(id, "F6"))
    expect_identical(nzchar(sys), lev[["F6"]] > 0, info = paste(id, "F6"))
    # F7 abbreviated answer format
    expect_identical(grepl("B, LB, VUS, LP, P.", txt, fixed = TRUE), lev[["F7"]] > 0, info = paste(id, "F7"))
    # F8 language
    expect_identical(grepl("Keimbahnvariante", txt, fixed = TRUE), lev[["F8"]] > 0, info = paste(id, "F8"))
    # class names stay English in every language
    expect_true(grepl(if (lev[["F7"]] > 0) "B, LB, VUS, LP, P." else "Benign, Likely benign, Uncertain significance, Likely pathogenic, Pathogenic.", txt, fixed = TRUE))
  }
})

test_that("K-M2-7: run.R --part main|robustness|pilot fill one store; resume = TRUE skips no call of another part (ankerRef: ANK-56, ANK-67)", {
  m <- acc_m2_mock()
  for (nm in names(m$res)) expect_identical(m$res[[nm]]$status, 0L, info = acc_m2_show(m$res[[nm]]))
  a56 <- acc_anchor("ANK-56")$value
  a67 <- acc_anchor("ANK-67")$value
  per_block <- as.integer(3 * a56$calls_per_model_main / a56$main_breakdown$blocks)
  rob <- as.integer(3 * a56$calls_per_model_plackett_burman)
  pil <- as.integer(3 * a67$calls_per_model)
  expect_identical(unname(m$counts), c(per_block, 2L * per_block, 2L * per_block + rob, 2L * per_block + rob + pil,
                                       2L * per_block + rob + pil))
  rows <- acc_m2_store_rows(m$store)
  main <- rows[rows$prompt_id %in% acc_m2_main_prompts() & rows$item_id %in% acc_m2_items()$item_id, , drop = FALSE]
  expect_identical(as.integer(table(main$block)), rep(per_block, 2L))
  pilot <- rows[rows$item_id %in% acc_m2_pilot()$item_id, , drop = FALSE]
  expect_identical(nrow(pilot), pil)
  expect_setequal(unique(pilot$item_id), acc_m2_pilot()$item_id)
  expect_setequal(unique(pilot$prompt_id), acc_m2_main_prompts())
  expect_true(all(pilot$rep == a67$replicates))
  expect_identical(as.integer(table(pilot$model_id)[c("sol", "llama", "qwen")]), rep(as.integer(a67$calls_per_model), 3L))
  rb <- rows[grepl("^pb[0-9]{2}$", rows$prompt_id), , drop = FALSE]
  expect_identical(nrow(rb), rob)
  expect_setequal(unique(rb$prompt_id), unlist(acc_anchor("ANK-62")$value$pb_design$prompt_ids))
  expect_setequal(unique(rb$item_id), acc_m2_items()$item_id)
  expect_false(anyDuplicated(paste(rb$item_id, rb$prompt_id, rb$model_id)) > 0L)
  expect_identical(m$new_files, character())
})

test_that("K-M2-7: robustness prompts in the store are the composed texts with the variant text of F1 and F2", {
  m <- acc_m2_mock_ok()
  rows <- acc_m2_store_rows(m$store)
  rb <- rows[grepl("^pb[0-9]{2}$", rows$prompt_id), , drop = FALSE]
  pb <- acc_m2_pb()
  items <- acc_m2_items()
  hash <- acc_m2_fn("hash_text")
  expected_text <- function(item, lev) acc_m2_fill(acc_m2_compose(lev)$template, item$gene, acc_m2_variant_text(item, lev[["F1"]], lev[["F2"]]))
  bad <- character()
  for (i in seq_len(nrow(rb))) {
    item <- as.list(items[items$item_id == rb$item_id[i], , drop = FALSE])
    lev <- pb[rb$prompt_id[i], ]
    if (identical(hash(expected_text(item, lev)), rb$prompt_hash[i])) next
    flipped <- character()
    for (f in names(lev)) {
      alt <- lev
      alt[[f]] <- -alt[[f]]
      if (identical(hash(expected_text(item, alt)), rb$prompt_hash[i])) flipped <- c(flipped, f)
    }
    bad <- c(bad, sprintf("%s %s %s: text differs%s", rb$item_id[i], rb$prompt_id[i], rb$model_id[i],
                          if (length(flipped)) paste0(" (matches with ", paste(flipped, collapse = ", "), " flipped)") else ""))
    if (length(bad) >= 20L) break
  }
  expect_identical(bad, character())
})

test_that("K-M2-7: --part pilot reports every pass rule of ANK-67 per model as passed or failed", {
  m <- acc_m2_mock_ok()
  out <- tolower(c(m$res$pilot$stdout, m$res$pilot$stderr))
  verdict <- "(passed|failed|nicht bestanden|bestanden)"
  rules <- c(parameters = "4xx", provider = "provider", parser = "parser", cost = "cost")
  for (key in c("sol", "llama", "qwen")) {
    for (rule in names(rules)) {
      hit <- grepl(key, out, fixed = TRUE) & grepl(rules[[rule]], out, fixed = TRUE) & grepl(verdict, out)
      expect_true(any(hit), info = paste(key, rule))
    }
    para <- grepl(key, out, fixed = TRUE) & grepl(rules[["parameters"]], out, fixed = TRUE)
    expect_true(any(para & grepl("(passed|[^t] bestanden|^bestanden)", out)), info = paste(key, "no 4xx answer from the mock backend"))
  }
})

test_that("K-M2-7: backend_openai_compatible() sends a non-empty design column system as system message before the user message, otherwise the argument system", {
  s <- acc_m2_model_settings()$llama
  sys_block <- acc_anchor("ANK-62")$value$blocks$system$en
  cases <- list(
    list(row = list(item_id = "x", system = sys_block), arg = NULL, want = sys_block),
    list(row = list(item_id = "x", system = sys_block), arg = "Argument system.", want = sys_block),
    list(row = list(item_id = "x", system = ""), arg = NULL, want = NULL),
    list(row = list(item_id = "x", system = ""), arg = "Argument system.", want = "Argument system."),
    list(row = list(item_id = "x", system = NA_character_), arg = "Argument system.", want = "Argument system."),
    list(row = list(item_id = "x"), arg = NULL, want = NULL),
    list(row = list(item_id = "x"), arg = "Argument system.", want = "Argument system."),
    list(row = NULL, arg = "Argument system.", want = "Argument system.")
  )
  for (k in seq_along(cases)) {
    cs <- cases[[k]]
    case <- paste("case", k)
    sink <- new.env()
    httr2::local_mocked_responses(acc_m2_replay(sink))
    acc_m2_backend(s, system = cs$arg)("User message.", s$model, cs$row)
    msgs <- sink$requests[[1]]$body$messages
    roles <- vapply(msgs, `[[`, "", "role")
    if (is.null(cs$want)) {
      expect_identical(roles, "user", info = case)
    } else {
      expect_identical(roles, c("system", "user"), info = case)
      expect_identical(msgs[[1]]$content, cs$want, info = case)
    }
    expect_identical(msgs[[length(msgs)]]$content, "User message.", info = case)
  }
})

acc_m2_expected_robustness <- function(main_rows, rob_rows, items_csv, key) {
  exp <- acc_m2_expected_model(main_rows, items_csv, key)
  md <- exp$modal
  pb_obj <- llmsa::pb_design(8, n_runs = 12, seed = acc_anchor("ANK-59")$value$seed)
  pb <- acc_m2_pb()
  r <- rob_rows[rob_rows$model_id == key, , drop = FALSE]
  resp <- data.frame(prompt_id = rownames(pb), x = NA_integer_, n = NA_integer_, stringsAsFactors = FALSE)
  for (j in seq_len(nrow(resp))) {
    rr <- r[r$prompt_id == resp$prompt_id[j], , drop = FALSE]
    mm <- md[match(rr$item_id, md$item_id), , drop = FALSE]
    agree <- !is.na(rr$value) & mm$has_modal & !is.na(mm$modal) & rr$value == mm$modal
    resp$x[j] <- sum(agree %in% TRUE)
    resp$n[j] <- nrow(rr)
  }
  resp$y <- acc_m2_empirical_logit(resp$x, resp$n)
  eff <- vapply(colnames(pb), function(f) mean(resp$y[pb[, f] > 0]) - mean(resp$y[pb[, f] < 0]), numeric(1))
  rob <- llmsa::msa_robustness(pb_obj, resp$y)
  m0 <- mean(resp$y)
  dp <- stats::plogis(m0 + eff / 2) - stats::plogis(m0 - eff / 2)
  list(response = resp, effects = eff, robustness = rob, delta_p = dp,
       band = acc_m2_band_robustness(dp, eff, attr(rob, "sme")))
}

test_that("K-M2-7: acmg_evaluate() evaluates the robustness runs per model: empirical logit, effects with msa_robustness(), delta p at the intercept, band and overall verdict (ankerRef: ANK-58, ANK-68)", {
  e <- acc_m2_evaluation()
  items_csv <- acc_m2_normalise_items(acc_m2_items())
  tol <- acc_m2_tol("arithmetic")$abs_tol
  for (key in c("sol", "llama", "qwen")) {
    want <- acc_m2_expected_robustness(e$main_rows, e$rob_rows, items_csv, key)
    mo <- acc_m2_ev_model(e$all, key)
    rb <- mo$robustness
    expect_true(is.list(rb), info = key)
    got <- as.data.frame(rb$response, stringsAsFactors = FALSE)
    got <- got[match(want$response$prompt_id, got$prompt_id), , drop = FALSE]
    expect_identical(as.integer(got$x), as.integer(want$response$x), info = key)
    expect_identical(as.integer(got$n), as.integer(want$response$n), info = key)
    expect_lte(max(abs(as.numeric(got$y) - want$response$y)), tol)
    expect_s3_class(rb$effects, "msa_robustness")
    ge <- stats::setNames(rb$effects$effect, rb$effects$factor)
    expect_lte(max(abs(ge[names(want$effects)] - want$effects)), tol)
    expect_lte(abs(attr(rb$effects, "sme") - attr(want$robustness, "sme")), tol)
    dp <- unlist(rb$delta_p)
    expect_lte(max(abs(dp[names(want$delta_p)] - want$delta_p)), tol)
    expect_identical(rb$band, want$band, info = key)
    acc_m2_check_model(e$all, key, e$main_rows, items_csv, e$plan, robustness_expected = want$band, label = "with robustness")
  }
})
