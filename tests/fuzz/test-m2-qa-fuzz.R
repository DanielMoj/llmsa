# QA / Red Team fuzz & boundary tests for M2 (fixed seed: 20261027)
testthat::set_max_fails(Inf)

qa_fuzz_fit_stub <- function(runs, type = c("numeric", "ordinal", "binary"), levels = NULL, link = "probit", ...) {
  type <- match.arg(type)
  structure(
    list(
      type = type,
      link = link,
      model = list(),
      vc = data.frame(
        source = c("item", "model", "Residual"),
        variance = c(10, 1, 1),
        stringsAsFactors = FALSE
      ),
      singular = FALSE,
      levels = levels,
      derived = character(),
      n = list(
        items = length(unique(runs$item_id)),
        prompts = length(unique(runs$prompt_id)),
        models = length(unique(runs$model_id)),
        blocks = length(unique(runs$block)),
        observations = nrow(runs),
        reps_per_cell = c(1L, 3L)
      )
    ),
    class = "msa_fit"
  )
}

test_that("QA-M2-005: acmg_evaluate and acmg_robustness reject unknown response classes and out-of-range rep/block in PB runs (seed = 20261027)", {
  for (pkg in c("yaml", "jsonlite", "digest")) skip_if_not_installed(pkg)
  set.seed(20261027L)
  plan <- llmsa:::acmg_plan()
  plan$reporting$output_dir <- tempfile("qa-m2-005-reports-")
  on.exit(unlink(plan$reporting$output_dir, recursive = TRUE), add = TRUE)

  items <- llmsa:::acmg_items()
  classes <- llmsa:::acmg_classes(plan)
  models <- names(llmsa:::acmg_models(plan))

  main <- expand.grid(
    rep = seq_len(plan$design$replicates),
    prompt_id = names(plan$templates),
    item_id = items$item_id,
    model_id = models,
    block = seq_len(plan$design$blocks),
    stringsAsFactors = FALSE
  )
  main$position <- as.integer(stats::ave(seq_len(nrow(main)), main$block, FUN = seq_along))
  main$value <- classes[sample.int(length(classes), nrow(main), replace = TRUE)]
  main$error <- NA_character_
  main$meta <- '{"mock":true}'
  main_runs <- llmsa:::acmg_join_items(main, items)

  pb <- llmsa:::acmg_design(items, plan, "robustness")
  pb$value <- classes[1L]
  pb$error <- NA_character_
  pb$meta <- '{"mock":true}'
  pb_runs <- llmsa:::acmg_join_items(pb, items)

  local_mocked_bindings(
    msa_fit = qa_fuzz_fit_stub,
    msa_report = function(..., output_file = "") output_file,
    .package = "llmsa"
  )

  fuzzed_labels <- c("VOUS", "Likely Pathogenic", "Uncertain Significance", "InvalidClass_99")
  chosen_label <- sample(fuzzed_labels, 1L)
  bad_pb <- pb_runs
  bad_pb$value[1L] <- chosen_label
  cols <- intersect(names(main_runs), names(bad_pb))
  combined_bad_class <- llmsa::as_msa_runs(rbind(main_runs[, cols], bad_pb[, cols]))

  expect_error(
    llmsa:::acmg_evaluate(combined_bad_class, plan),
    "unknown response or reference classes"
  )

  modal <- data.frame(
    item_id = items$item_id,
    modal = classes[1L],
    has_modal = TRUE,
    reference = items$reference,
    stringsAsFactors = FALSE
  )
  pb_sol <- pb_runs[pb_runs$model_id == "sol", , drop = FALSE]
  pb_bad_rep <- pb_sol
  pb_bad_rep$rep[1L] <- as.integer(plan$robustness$replicates + 1L)
  rob_rep <- llmsa:::acmg_robustness(pb_bad_rep, modal, items$item_id, plan)
  expect_false(isTRUE(rob_rep$complete))
  expect_identical(rob_rep$band, "not assessed")

  pb_bad_block <- pb_sol
  pb_bad_block$block[1L] <- 2L
  rob_block <- llmsa:::acmg_robustness(pb_bad_block, modal, items$item_id, plan)
  expect_false(isTRUE(rob_block$complete))
  expect_identical(rob_block$band, "not assessed")
})
