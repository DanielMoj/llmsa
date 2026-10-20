#' Plan a crossed precision study for an LLM pipeline
#'
#' Builds the run plan of a crossed measurement-system study: every item is
#' processed under every prompt variant and every model, `reps` times per
#' block. Items play the role of *parts*, prompt variants and models play the
#' role of *appraisers* and *instruments*, replicates measure repeatability,
#' and blocks separate replicates in time (different hours or days), which is
#' necessary because inference endpoints are not deterministic at
#' temperature 0 and their behaviour drifts with load.
#'
#' @param items A character vector of item texts (optionally named by item id)
#'   or a data.frame with columns `item_id` and `text`. Additional columns
#'   (for example `reference`) are carried along and can be used as
#'   placeholders in prompts.
#' @param prompts A character vector of prompt templates. Placeholders in
#'   braces are replaced by the item fields: `{text}` is always available,
#'   `{item_id}` and any other column of `items` can be used as well. Names
#'   become prompt ids (default `P1`, `P2`, ...).
#' @param models A character vector of model identifiers passed to the
#'   backend. Names become model ids (default: the identifiers themselves).
#' @param reps Number of replicates per item, prompt, model and block.
#' @param blocks Number of blocks (sessions). Run each block at a different
#'   time to capture temporal drift of the endpoint.
#' @param order `"random"` randomises the run order within each block
#'   (recommended), `"fixed"` keeps the crossing order.
#' @param seed Optional seed for the randomisation.
#'
#' @return A data.frame of class `msa_design` with one row per planned call:
#'   `block`, `position` (run order within block), `item_id`, `prompt_id`,
#'   `model_id`, `rep`, `prompt` (the rendered prompt) and `model` (the
#'   backend model identifier). The design parameters are stored as
#'   attributes.
#' @examples
#' items <- c(v1 = "NM_000059.4:c.1813dupA", v2 = "NM_000059.4:c.7397T>C")
#' prompts <- c(
#'   short = "Classify the variant {text} according to ACMG/AMP. Answer with one class.",
#'   long  = "You are a clinical geneticist. Classify {text} (ACMG/AMP, 5 tiers)."
#' )
#' d <- msa_design(items, prompts, models = c("model-a", "model-b"), reps = 2, seed = 1)
#' head(d)
#' summary(d)
#' @export
msa_design <- function(items, prompts, models, reps = 3, blocks = 1,
                       order = c("random", "fixed"), seed = NULL) {
  order <- match.arg(order)
  items <- as_items(items)
  prompts <- as_named(prompts, "prompt")
  models <- as_named(models, "model", default = "value")
  if (!is.numeric(reps) || reps < 1) stop("`reps` must be >= 1.", call. = FALSE)
  if (!is.numeric(blocks) || blocks < 1) stop("`blocks` must be >= 1.", call. = FALSE)
  reps <- as.integer(reps); blocks <- as.integer(blocks)

  grid <- expand.grid(rep = seq_len(reps), model_id = names(models),
                      prompt_id = names(prompts), item_id = items$item_id,
                      block = seq_len(blocks),
                      stringsAsFactors = FALSE)
  grid <- grid[, c("block", "item_id", "prompt_id", "model_id", "rep")]

  if (!is.null(seed)) {
    old <- if (exists(".Random.seed", envir = globalenv())) get(".Random.seed", envir = globalenv()) else NULL
    on.exit(if (!is.null(old)) assign(".Random.seed", old, envir = globalenv()), add = TRUE)
    set.seed(seed)
  }
  grid <- do.call(rbind, lapply(split(grid, grid$block), function(b) {
    if (order == "random") b <- b[sample.int(nrow(b)), , drop = FALSE]
    b$position <- seq_len(nrow(b))
    b
  }))
  rownames(grid) <- NULL

  # render prompts
  idx <- match(grid$item_id, items$item_id)
  grid$prompt <- vapply(seq_len(nrow(grid)), function(i) {
    fields <- as.list(items[idx[i], , drop = FALSE])
    render_prompt(prompts[[grid$prompt_id[i]]], fields)
  }, character(1))
  grid$model <- unname(models[grid$model_id])
  grid <- grid[, c("block", "position", "item_id", "prompt_id", "model_id",
                   "rep", "prompt", "model")]

  structure(grid,
            class = c("msa_design", "data.frame"),
            items = items, prompts = prompts, models = models,
            reps = reps, blocks = blocks, order = order, seed = seed)
}

#' @export
summary.msa_design <- function(object, ...) {
  cat("Crossed precision study for an LLM pipeline\n")
  cat(sprintf("  items (parts):      %d\n", length(unique(object$item_id))))
  cat(sprintf("  prompt variants:    %d  [%s]\n", length(attr(object, "prompts")),
              paste(names(attr(object, "prompts")), collapse = ", ")))
  cat(sprintf("  models:             %d  [%s]\n", length(attr(object, "models")),
              paste(names(attr(object, "models")), collapse = ", ")))
  cat(sprintf("  replicates/block:   %d\n", attr(object, "reps")))
  cat(sprintf("  blocks (sessions):  %d\n", attr(object, "blocks")))
  cat(sprintf("  planned calls:      %d\n", nrow(object)))
  invisible(object)
}

#' @export
print.msa_design <- function(x, n = 6, ...) {
  summary(x)
  cat("\nFirst rows (prompt text truncated):\n")
  show <- utils::head(as.data.frame(x), n)
  show$prompt <- paste0(substr(show$prompt, 1, 40), ifelse(nchar(show$prompt) > 40, "...", ""))
  print(show, row.names = FALSE)
  invisible(x)
}
