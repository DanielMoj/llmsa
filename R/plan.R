#' Simulate a study with known variance components
#'
#' Generates numeric results of a crossed study from assumed variance
#' components, for teaching and for planning study size with [msa_plan()].
#'
#' @param n_items,n_prompts,n_models,n_reps,n_blocks Design sizes.
#' @param vc Named list of variance components: `item`, `prompt`, `model`,
#'   `block`, `item_prompt`, `item_model`, `prompt_model`, `residual`.
#'   Missing components are zero.
#' @param mean Grand mean.
#' @param seed Optional seed.
#' @return An `msa_runs` data.frame with a `latent` column holding the
#'   item truth and the `value` column holding the simulated measurement.
#' @examples
#' r <- msa_simulate(20, 3, 2, 3, vc = list(item = 1, prompt = 0.05, residual = 0.1), seed = 1)
#' msa_grr(msa_fit(r, type = "numeric"))
#' @export
msa_simulate <- function(n_items, n_prompts, n_models, n_reps, n_blocks = 1,
                         vc = list(item = 1, prompt = 0.05, model = 0.05, residual = 0.1),
                         mean = 0, seed = NULL) {
  if (!is.null(seed)) { old <- .Random.seed_get(); on.exit(.Random.seed_set(old), add = TRUE); set.seed(seed) }
  g <- function(nm) vc[[nm]] %||% 0
  items <- sprintf("I%03d", seq_len(n_items)); prompts <- paste0("P", seq_len(n_prompts))
  models <- paste0("M", seq_len(n_models)); blocks <- seq_len(n_blocks)
  d <- expand.grid(rep = seq_len(n_reps), model_id = models, prompt_id = prompts,
                   item_id = items, block = blocks, stringsAsFactors = FALSE)
  eff <- function(keys, v) { e <- stats::rnorm(length(unique(keys)), 0, sqrt(v)); e[match(keys, unique(keys))] }
  d$latent <- mean + eff(d$item_id, g("item"))
  d$value <- d$latent + eff(d$prompt_id, g("prompt")) + eff(d$model_id, g("model")) +
    eff(d$block, g("block")) +
    eff(paste(d$item_id, d$prompt_id), g("item_prompt")) +
    eff(paste(d$item_id, d$model_id), g("item_model")) +
    eff(paste(d$prompt_id, d$model_id), g("prompt_model")) +
    stats::rnorm(nrow(d), 0, sqrt(g("residual")))
  as_msa_runs(d[, c("block", "item_id", "prompt_id", "model_id", "rep", "latent", "value")])
}

#' Plan the size of a precision study by simulation
#'
#' How many items, prompt variants, models and replicates does a study
#' need before the estimated percent gauge R&R can be trusted? With few
#' prompt or model levels the variance components of these factors are
#' estimated with large uncertainty, and the fit is often singular. This
#' function simulates studies of candidate sizes from assumed variance
#' components, refits each one and summarises the distribution of the
#' estimated %GRR (percent study variation) around its true value.
#'
#' @param scenarios A data.frame with columns `n_items`, `n_prompts`,
#'   `n_models`, `n_reps` (and optionally `n_blocks`), one row per candidate
#'   design.
#' @param vc Assumed variance components, see [msa_simulate()].
#' @param nsim Simulations per scenario.
#' @param seed Optional seed.
#' @param verbose Print progress.
#' @return A data.frame of class `msa_plan` with, per scenario, the true
#'   %GRR, the mean and the 2.5 %, 50 % and 97.5 % quantiles of the
#'   estimates, the root-mean-square error, the share of singular fits and
#'   the share of simulations that misclassify the system relative to the
#'   10 % / 30 % thresholds.
#' @examples
#' \donttest{
#' sc <- expand.grid(n_items = c(20, 40), n_prompts = c(3, 6), n_models = 3, n_reps = 3)
#' msa_plan(sc, vc = list(item = 1, prompt = 0.05, model = 0.05, residual = 0.1),
#'          nsim = 20, seed = 1)
#' }
#' @export
msa_plan <- function(scenarios, vc = list(item = 1, prompt = 0.05, model = 0.05, residual = 0.1),
                     nsim = 100, seed = NULL, verbose = TRUE) {
  stop_if_missing_cols(scenarios, c("n_items", "n_prompts", "n_models", "n_reps"), "scenarios")
  if (!"n_blocks" %in% names(scenarios)) scenarios$n_blocks <- 1
  if (!is.null(seed)) { old <- .Random.seed_get(); on.exit(.Random.seed_set(old), add = TRUE); set.seed(seed) }
  g <- function(nm) vc[[nm]] %||% 0
  grr_true <- g("residual") + g("prompt") + g("model") + g("block") + g("item_prompt") +
    g("item_model") + g("prompt_model")
  pct_true <- 100 * sqrt(grr_true / (grr_true + g("item")))
  classify <- function(p) ifelse(p < 10, "acceptable", ifelse(p <= 30, "marginal", "unacceptable"))
  res <- lapply(seq_len(nrow(scenarios)), function(i) {
    s <- scenarios[i, ]
    if (verbose) message(sprintf("scenario %d/%d: %d items, %d prompts, %d models, %d reps, %d block(s)",
                                 i, nrow(scenarios), s$n_items, s$n_prompts, s$n_models, s$n_reps, s$n_blocks))
    est <- numeric(nsim); sing <- logical(nsim)
    for (b in seq_len(nsim)) {
      r <- msa_simulate(s$n_items, s$n_prompts, s$n_models, s$n_reps, s$n_blocks, vc = vc)
      f <- suppressMessages(suppressWarnings(msa_fit(r, type = "numeric")))
      est[b] <- grr_stats(f$vc)$summary[["grr_pct_study_var"]]
      sing[b] <- isTRUE(f$singular)
    }
    q <- stats::quantile(est, c(0.025, 0.5, 0.975), na.rm = TRUE)
    data.frame(s, grr_true = pct_true, mean = mean(est, na.rm = TRUE),
               q2.5 = q[[1]], median = q[[2]], q97.5 = q[[3]],
               rmse = sqrt(mean((est - pct_true)^2, na.rm = TRUE)),
               pct_singular = 100 * mean(sing),
               pct_misclassified = 100 * mean(classify(est) != classify(pct_true), na.rm = TRUE))
  })
  out <- do.call(rbind, res)
  rownames(out) <- NULL
  structure(out, class = c("msa_plan", "data.frame"), nsim = nsim, vc = vc)
}

#' @export
print.msa_plan <- function(x, ...) {
  cat(sprintf("Study-size planning by simulation (%d simulations per scenario)\n", attr(x, "nsim")))
  cat(sprintf("  true %%GRR (study variation) under the assumed variance components: %.1f %%\n", x$grr_true[1]))
  d <- as.data.frame(x)
  for (nm in c("mean", "q2.5", "median", "q97.5", "rmse", "pct_singular", "pct_misclassified")) d[[nm]] <- fmt_num(d[[nm]], 1)
  d$grr_true <- NULL
  print(d, row.names = FALSE)
  invisible(x)
}
