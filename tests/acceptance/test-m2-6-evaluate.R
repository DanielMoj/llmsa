# K-M2-6: main-plan run with backend_mock() through inst/validation/ap1/run.R and
# its evaluation acmg_evaluate(runs, plan) per model. Expected values are computed
# from the stored answers by the mini-references of setup-m2.R with the rules of
# ANK-58 and ANK-68; fits are recomputed with msa_fit()/msa_grr() of the package
# (structure on the statistics core of v0.1.0, docs/03 introduction). The result
# structure follows ACC-12 (orchestrator/handoff/M2/CRITERIA.json).

acc_m2_keys <- function() c("sol", "llama", "qwen")

test_that("K-M2-6: without --store run.R writes to ../llmsa-runs/ap1_runs.sqlite, never into the working tree", {
  work <- tempfile("acc-m2-default-store-")
  pkg <- file.path(work, "llmsa")
  dir.create(pkg, recursive = TRUE)
  dir.create(file.path(work, "llmsa-runs"))
  for (part in c("DESCRIPTION", "NAMESPACE", "R", "inst", "data")) {
    from <- file.path(acc_pkg_root(), part)
    if (file.exists(from)) file.copy(from, pkg, recursive = TRUE)
  }
  before <- list.files(pkg, recursive = TRUE, all.files = TRUE)
  res <- acc_m2_run(c("--part", "pilot", "--backend", "mock"), wd = pkg,
                    script = file.path(pkg, "inst", "validation", "ap1", "run.R"))
  expect_identical(res$status, 0L, info = acc_m2_show(res))
  store <- file.path(work, "llmsa-runs", "ap1_runs.sqlite")
  expect_true(file.exists(store))
  expect_identical(acc_m2_count(store), as.integer(3 * acc_anchor("ANK-67")$value$calls_per_model))
  expect_identical(list.files(pkg, recursive = TRUE, all.files = TRUE), before)
  unlink(work, recursive = TRUE)
})

test_that("K-M2-6: the main plan in the store: 5,400 calls, 18 per item and model, model ids sol, llama, qwen (ankerRef: ANK-56)", {
  m <- acc_m2_mock_ok()
  rows <- acc_m2_store_rows(m$full_store)
  a <- acc_anchor("ANK-56")$value
  expect_identical(nrow(rows), as.integer(3 * a$calls_per_model_main))
  expect_setequal(unique(rows$model_id), acc_m2_keys())
  expect_setequal(unique(rows$prompt_id), acc_m2_main_prompts())
  expect_setequal(unique(rows$block), seq_len(a$main_breakdown$blocks))
  expect_setequal(unique(rows$rep), seq_len(a$main_breakdown$replicates))
  expect_setequal(unique(rows$item_id), acc_m2_items()$item_id)
  per <- table(paste(rows$item_id, rows$model_id))
  expect_true(all(per == acc_anchor("ANK-68")$value$modal_calls_per_item_and_model))
  expect_false(anyDuplicated(paste(rows$block, rows$item_id, rows$prompt_id, rows$model_id, rows$rep)) > 0L)
  expect_identical(m$new_files, character())
})

test_that("K-M2-6: in each block the replicate is the outer loop, the order within a replicate is random and reproducible (ankerRef: ANK-59)", {
  m <- acc_m2_mock_ok()
  full <- acc_m2_store_rows(m$full_store)
  for (b in unique(full$block)) {
    d <- full[full$block == b, , drop = FALSE]
    reps <- sort(unique(d$rep))
    for (r in reps[-length(reps)]) {
      expect_lt(max(d$position[d$rep == r]), min(d$position[d$rep == r + 1L]))
    }
    for (r in reps) {
      s <- d[d$rep == r, , drop = FALSE]
      s <- s[order(s$position), , drop = FALSE]
      same <- (s$item_id[-1] == s$item_id[-nrow(s)]) + (s$prompt_id[-1] == s$prompt_id[-nrow(s)]) +
        (s$model_id[-1] == s$model_id[-nrow(s)])
      # a crossed (systematic) order changes one factor per step; a random order rarely does
      expect_lt(mean(same == 2L), 0.5)
    }
  }
  blockwise <- acc_m2_store_rows(m$store)
  blockwise <- blockwise[blockwise$prompt_id %in% acc_m2_main_prompts() & blockwise$item_id %in% full$item_id, , drop = FALSE]
  key <- function(x) {
    x <- x[order(x$block, x$position), , drop = FALSE]
    paste(x$block, x$position, x$item_id, x$prompt_id, x$model_id, x$rep)
  }
  expect_identical(key(blockwise), key(full))
})

test_that("K-M2-3, K-M2-6: main-plan prompts contain gene, transcript and c. notation without p. notation", {
  m <- acc_m2_mock_ok()
  rows <- acc_m2_store_rows(m$full_store)
  items <- acc_m2_items()
  tpl <- acc_m2_templates()
  hash <- acc_m2_fn("hash_text")
  want <- vapply(seq_len(nrow(rows)), function(i) {
    it <- items[items$item_id == rows$item_id[i], , drop = FALSE]
    hash(acc_m2_fill(tpl[[rows$prompt_id[i]]], it$gene, it$hgvs))
  }, character(1))
  bad <- which(rows$prompt_hash != want)
  expect_identical(length(bad), 0L, info = paste(utils::head(paste(rows$item_id[bad], rows$prompt_id[bad]), 10), collapse = ", "))
})

test_that("K-M2-6: acmg_evaluate() per model: modal answer, hit rates, NA share, dangerous errors, kappa with bootstrap interval, agreement, fit, verdicts, report (ankerRef: ANK-58, ANK-68)", {
  e <- acc_m2_evaluation()
  items_csv <- acc_m2_normalise_items(acc_m2_items())
  for (key in acc_m2_keys()) acc_m2_check_model(e$main, key, e$main_rows, items_csv, e$plan, label = "main plan")
})

test_that("K-M2-6: the joint fit over the three models has a model component and no verdict", {
  e <- acc_m2_evaluation()
  j <- e$main$joint
  expect_s3_class(j, "msa_fit")
  expect_false(inherits(j, "msa_grr"))
  expect_true("model" %in% j$vc$source)
  expect_identical(as.integer(j$n$models), 3L)
  classes <- acc_m2_classes()
  ord <- acc_m2_with_conditions(llmsa::msa_fit(llmsa::as_msa_runs(e$main_rows), type = "ordinal", levels = classes, link = "probit"))
  if (!ord$failed) {
    expect_identical(j$type, "ordinal")
    expect_equal(j$vc, ord$value$vc, tolerance = acc_m2_tol("engine_ordinal")$rel_tol)
  } else {
    expect_identical(j$type, "numeric")
  }
})

test_that("K-M2-6: an error or a convergence warning of the ordinal fit switches to the numeric fit on the class scores 1 to 5 (ankerRef: ANK-68)", {
  e <- acc_m2_evaluation()
  classes <- acc_m2_classes()
  orig_fit <- llmsa::msa_fit
  for (mode in c("error", "warning")) {
    local({
      testthat::local_mocked_bindings(msa_fit = function(runs, type = c("numeric", "ordinal", "binary"), ...) {
        type <- match.arg(type)
        if (type == "ordinal" && mode == "error") stop("acceptance: forced failure of the ordinal fit")
        if (type == "ordinal") warning("acceptance: Model failed to converge (forced)")
        orig_fit(runs, type = type, ...)
      }, .package = "llmsa")
      ev <- acc_m2_evaluate(acc_m2_runs_with_items(e$main_rows, e$items), e$plan)
      for (key in acc_m2_keys()) {
        mo <- acc_m2_ev_model(ev, key)
        expect_true(isTRUE(mo$fallback), info = paste(mode, key))
        expect_identical(mo$grr$type, "numeric", info = paste(mode, key))
        r <- e$main_rows[e$main_rows$model_id == key, , drop = FALSE]
        r$value <- acc_m2_scores(r$value)
        want <- llmsa::msa_grr(orig_fit(llmsa::as_msa_runs(r), type = "numeric"))
        expect_equal(mo$grr$summary, want$summary, tolerance = acc_m2_tol("engine_ordinal")$rel_tol, info = paste(mode, key))
        expect_identical(unname(mo$verdicts[["grr"]]), acc_m2_band_grr(want$summary[["grr_pct_study_var"]]), info = paste(mode, key))
      }
    })
  }
})

test_that("K-M2-6: INSAID references only via acmg_items(insaid_path): NA without the TSV and no error, counted with the TSV (ankerRef: ANK-52)", {
  e <- acc_m2_evaluation()
  for (key in acc_m2_keys()) {
    g <- acc_m2_hit_row(acc_m2_ev_model(e$main, key)$hit_rate, "source", "insaid")
    expect_identical(as.integer(g$n), 0L, info = key)
    expect_true(is.na(g$rate), info = key)
  }
  items_tsv <- acc_m2_fn("acmg_items")(insaid_path = acc_m2_insaid_path())
  ev <- acc_m2_evaluate(acc_m2_runs_with_items(e$main_rows, items_tsv), e$plan)
  ins <- acc_m2_insaid()
  items_csv <- acc_m2_normalise_items(acc_m2_items())
  d <- items_csv$source == "insaid"
  cdna <- substr(items_csv$hgvs[d], nchar(items_csv$transcript[d]) + 2L, nchar(items_csv$hgvs[d]))
  items_csv$reference[d] <- ins$label[match(paste(items_csv$gene[d], cdna), paste(ins$gene, ins$cdna))]
  for (key in acc_m2_keys()) {
    exp <- acc_m2_expected_model(e$main_rows, items_csv, key)
    want <- exp$hit_rate[exp$hit_rate$by == "source" & exp$hit_rate$group == "insaid", , drop = FALSE]
    g <- acc_m2_hit_row(acc_m2_ev_model(ev, key)$hit_rate, "source", "insaid")
    expect_gt(as.integer(g$n), 0L)
    expect_identical(as.integer(g$n), want$n, info = key)
    expect_identical(as.integer(g$hits), want$hits, info = key)
    ki <- exp$kappa_items
    expect_lte(abs(as.numeric(acc_m2_ev_model(ev, key)$kappa[["estimate"]]) - acc_m2_kappa(ki$modal, ki$reference)),
               acc_m2_tol("arithmetic")$abs_tol)
  }
})

test_that("K-M2-6: constructed runs with NA as modal answer, ties and dangerous errors are evaluated by the rules of ANK-68 and ANK-58", {
  items_df <- acc_m2_fn("acmg_items")()
  items_csv <- acc_m2_normalise_items(acc_m2_items())
  plan <- acc_m2_fn("acmg_plan")()
  classes <- acc_m2_classes()
  keys <- acc_m2_keys()
  prompts <- acc_m2_main_prompts()
  b <- acc_anchor("ANK-56")$value$main_breakdown
  grid <- expand.grid(rep = seq_len(b$replicates), prompt_id = prompts, item_id = items_csv$item_id, model_id = keys,
                      block = seq_len(b$blocks), stringsAsFactors = FALSE)
  i <- match(grid$item_id, items_csv$item_id)
  m <- match(grid$model_id, keys)
  call <- (grid$block - 1L) * length(prompts) * b$replicates + (match(grid$prompt_id, prompts) - 1L) * b$replicates + grid$rep
  ref <- match(items_csv$reference, classes)
  ref[is.na(ref)] <- 3L
  base <- ref[i]
  idx <- base
  pattern <- (i + 3L * m) %% 10L
  # NA as modal answer: 10 of 18 calls unparsed
  na_call <- pattern == 1L & call <= 10L
  # tie: 9 calls the reference class, 9 calls its neighbour
  idx[pattern == 2L & call > 9L] <- ifelse(base[pattern == 2L & call > 9L] < 5L, base[pattern == 2L & call > 9L] + 1L, base[pattern == 2L & call > 9L] - 1L)
  # dangerous error: the opposite side of the scale in all calls
  danger <- pattern == 3L
  idx[danger] <- ifelse(base[danger] >= 4L, 1L, ifelse(base[danger] <= 2L, 5L, base[danger]))
  # one call per item and model on the neighbouring class (residual variation)
  noise <- call == 18L & pattern >= 4L
  idx[noise] <- ifelse(base[noise] < 5L, base[noise] + 1L, base[noise] - 1L)
  grid$value <- classes[idx]
  grid$value[na_call] <- NA_character_
  grid <- grid[order(grid$block, grid$model_id, grid$item_id, grid$prompt_id, grid$rep), , drop = FALSE]
  grid$position <- stats::ave(seq_len(nrow(grid)), grid$block, FUN = seq_along)
  rows <- grid[, c("block", "position", "item_id", "prompt_id", "model_id", "rep", "value")]
  ev <- acc_m2_evaluate(acc_m2_runs_with_items(rows, items_df), plan)
  for (key in keys) {
    exp <- acc_m2_check_model(ev, key, rows, items_csv, plan, label = "constructed")
    # the constructed patterns are present, so the rules are exercised
    expect_gt(sum(exp$modal$has_modal & is.na(exp$modal$modal)), 0L)
    expect_gt(exp$n_no_modal, 0L)
    expect_gt(exp$dangerous, 0L)
  }
})

test_that("K-M2-6: the mini-references of the evaluation detect wrong modal answers, NA handling and bands", {
  expect_identical(acc_m2_modal(c("A", "A", "B")), list(has_modal = TRUE, modal = "A"))
  expect_identical(acc_m2_modal(c("A", NA, NA)), list(has_modal = TRUE, modal = NA_character_))
  expect_identical(acc_m2_modal(c("A", "B", NA))$has_modal, FALSE)
  cl <- acc_m2_classes()
  perfect <- acc_m2_kappa(cl, cl, cl)
  expect_equal(perfect, 1)
  with_na <- acc_m2_kappa(c(cl[1:4], NA), cl, cl)
  expect_lt(with_na, perfect)
  # NA has weight 0 to every class, so it is worse than the neighbouring class
  expect_lt(with_na, acc_m2_kappa(c(cl[1:4], cl[4]), cl, cl))
  expect_identical(acc_m2_band_kappa(0.8), "acceptable")
  expect_identical(acc_m2_band_kappa(0.79), "marginal")
  expect_identical(acc_m2_band_kappa(0.59), "unacceptable")
  expect_identical(acc_m2_band_grr(10), "marginal")
  expect_identical(acc_m2_band_grr(30), "marginal")
  expect_identical(acc_m2_band_grr(9.99), "acceptable")
  expect_identical(acc_m2_band_dangerous(0), "acceptable")
  expect_identical(acc_m2_band_dangerous(1), "marginal")
  expect_identical(acc_m2_band_dangerous(2), "unacceptable")
  expect_identical(acc_m2_worst(c("acceptable", "marginal", "acceptable")), "marginal")
})
