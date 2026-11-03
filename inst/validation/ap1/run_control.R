#!/usr/bin/env Rscript
# Language follow-up control (docs/decisions/ADR-AP1-DE-sprachvergleich.md): one pass of the
# English concise prompt over all items and models, in its own store, to look for drift
# between the English main plan and the German collection. No pilot, no evaluation.
args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[startsWith(args, "--file=")]
if (length(file_arg) != 1L) stop("AP1 run_control.R requires Rscript execution.", call. = FALSE)
script <- normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE)
root <- dirname(dirname(dirname(dirname(script))))
if (!file.exists(file.path(root, "DESCRIPTION"))) stop("AP1 source package root missing.", call. = FALSE)
if (!requireNamespace("pkgload", quietly = TRUE)) stop("AP1 needs the frozen pkgload dependency.", call. = FALSE)
pkgload::load_all(root, export_all = FALSE, helpers = FALSE, quiet = TRUE)
options(llmsa.ap1.root = root)

opts <- commandArgs(trailingOnly = TRUE)
value <- function(name) {
  at <- which(opts == name)
  if (length(at) != 1L || at == length(opts)) stop("AP1 control requires ", name, ".", call. = FALSE)
  opts[at + 1L]
}
mode <- value("--backend")
if (!mode %in% c("mock", "api")) stop("AP1 requires explicit --backend mock|api.", call. = FALSE)
store <- llmsa:::acmg_external_path(value("--store"), root)
if (!llmsa:::is_sqlite_path(store)) stop("AP1 --store requires .sqlite, .sqlite3 or .db.", call. = FALSE)

plan <- llmsa:::acmg_plan()
control <- plan$language_control
items <- llmsa:::acmg_items()
items$text <- items$hgvs
models <- vapply(llmsa:::acmg_models(plan), `[[`, "", "id")
design <- llmsa:::acmg_seeded(plan$design$seed, {
  d <- msa_design(items, stats::setNames(control$template, control$prompt_id), models,
                  reps = 1, blocks = 1, order = "fixed")
  d <- d[sample.int(nrow(d)), , drop = FALSE]
  d$position <- seq_len(nrow(d))
  rownames(d) <- NULL
  d
})
rows <- llmsa:::acmg_store_read(store, mode)
backends <- if (mode == "api") llmsa:::acmg_api_backends(plan) else NULL
backend <- if (mode == "mock") llmsa:::acmg_mock_backend(items, plan) else function(prompt, model, row) {
  backends[[row$model_id]](prompt, model, row)
}
watch <- llmsa:::acmg_watch(backend, plan, "control")
llmsa:::acmg_store_init(store, mode)
watch$start(1L, sum(!llmsa:::run_key(as.data.frame(design)) %in% llmsa:::run_key(rows)))
run <- tryCatch(msa_run(design, watch$backend, parse = llmsa:::acmg_parser(plan), block = 1L,
                        store = store, resume = TRUE, verbose = FALSE),
                acmg_network_abort = function(cnd) cnd)
if (inherits(run, "acmg_network_abort")) stop(conditionMessage(run), call. = FALSE)
rows <- llmsa:::acmg_store_read(store, mode)
cat(sprintf("AP1 control backend=%s; stored calls=%d; store=%s\n", mode, nrow(rows), store))
