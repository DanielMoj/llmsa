# Offline ADEMP calculation for docs/04 K-M3a-7 and ADR-052.
# Settings are specified scenarios, never empirical reference constants.
agreement_bias_settings <- function() {
  list(level = 0.95, rng = c("Mersenne-Twister", "Inversion", "Rejection"),
       scenarios = data.frame(scenario = c("S-bias-1", "S-bias-2"),
                              items = 20L, prompts = 3L, models = 3L, reps = 3L,
                              residual = c(0.1, 0.5), item = 1, bias = c(0.2, 0),
                              seed = c(20261106L, 20261107L), stringsAsFactors = FALSE))
}

agreement_bias_coverage <- function(anchors, n_sim = NULL) {
  # The caller supplies the existing hash-verified latent anchor objects.
  n_min <- anchors[["ANK-06"]][["value"]][["n_sim_min"]]
  factors <- anchors[["ANK-TOL"]][["value"]][["mc_factor"]]
  required <- list(n_min, factors[["pass"]], factors[["report"]])
  if (!all(vapply(required, function(x) is.numeric(x) && length(x) == 1L &&
                  is.finite(x) && x > 0, logical(1)))) {
    stop("Bias coverage requires valid ANK-06.n_sim_min and ANK-TOL.mc_factor anchors.", call. = FALSE)
  }
  if (is.null(n_sim)) n_sim <- n_min
  if (!is.numeric(n_sim) || length(n_sim) != 1L || !is.finite(n_sim) ||
      n_sim < 1 || n_sim != floor(n_sim)) {
    stop("Bias coverage `n_sim` must be a positive whole number.", call. = FALSE)
  }
  settings <- agreement_bias_settings()
  kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = globalenv(), inherits = FALSE)
  on.exit({
    RNGkind(kind[1], kind[2], kind[3])
    if (had_seed) assign(".Random.seed", old_seed, envir = globalenv()) else
      if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) rm(".Random.seed", envir = globalenv())
  }, add = TRUE)
  RNGkind(settings$rng[1], settings$rng[2], settings$rng[3])
  started <- proc.time()[["elapsed"]]
  summaries <- replicates <- vector("list", nrow(settings$scenarios))
  for (i in seq_len(nrow(settings$scenarios))) {
    sc <- settings$scenarios[i, ]
    set.seed(sc$seed)
    design <- expand.grid(rep = seq_len(sc$reps), model = seq_len(sc$models),
                          prompt = seq_len(sc$prompts), item = seq_len(sc$items))
    items <- sprintf("I%02d", seq_len(sc$items))
    frame <- data.frame(item_id = items[design$item], prompt_id = paste0("P", design$prompt),
                        model_id = paste0("M", design$model), rep = design$rep, stringsAsFactors = FALSE)
    bounds <- vapply(seq_len(n_sim), function(iteration) {
      tryCatch({
        truth <- stats::rnorm(sc$items, 0, sqrt(sc$item))
        frame$value <- truth[design$item] + sc$bias + stats::rnorm(nrow(design), 0, sqrt(sc$residual))
        reference <- data.frame(item_id = items, reference = truth, stringsAsFactors = FALSE)
        # Namespace dispatch deliberately uses the loaded (possibly mutated) package.
        result <- llmsa::msa_bias(llmsa::as_msa_runs(frame), reference = reference, level = settings$level)
        interval <- result$overall[c("lower", "upper")]
        if (!is.numeric(interval) || length(interval) != 2L || any(!is.finite(interval)) || interval[1] > interval[2]) {
          stop("invalid or non-finite bias interval", call. = FALSE)
        }
        unname(interval)
      }, error = function(e) {
        stop("Bias coverage ", sc$scenario, ", repetition ", iteration, ": ", conditionMessage(e), call. = FALSE)
      })
    }, numeric(2))
    covered <- bounds[1, ] <= sc$bias & sc$bias <= bounds[2, ]
    coverage <- mean(covered)
    mcse <- sqrt(coverage * (1 - coverage) / n_sim)
    distance <- coverage - settings$level
    distance_mcse <- if (mcse > 0) distance / mcse else if (distance == 0) 0 else sign(distance) * Inf
    finding <- if (abs(distance) <= factors$report * mcse) "within report threshold" else
      if (distance < 0) "undercoverage" else "overcoverage"
    summaries[[i]] <- data.frame(scenario = sc$scenario, coverage = coverage, MCSE = mcse,
                                 n_sim = n_sim, distance_mcse = distance_mcse, finding = finding,
                                 within_pass = abs(distance) <= factors$pass * mcse,
                                 stringsAsFactors = FALSE)
    replicates[[i]] <- data.frame(scenario = sc$scenario, repetition = seq_len(n_sim),
                                  lower = bounds[1, ], upper = bounds[2, ],
                                  true_bias = sc$bias, covered = covered, stringsAsFactors = FALSE)
  }
  list(summary = do.call(rbind, summaries), replicates = do.call(rbind, replicates),
       settings = settings, n_min = n_min, n_sim = n_sim, report_factor = factors$report,
       pass_factor = factors$pass, elapsed = proc.time()[["elapsed"]] - started,
       versions = c(R = as.character(getRversion()), llmsa = as.character(utils::packageVersion("llmsa"))))
}

agreement_coverage_table <- function(result) {
  tab <- result$summary[c("scenario", "coverage", "MCSE", "n_sim", "distance_mcse", "finding")]
  for (nm in c("coverage", "MCSE", "distance_mcse")) tab[[nm]] <- formatC(tab[[nm]], format = "f", digits = 6L)
  tab$n_sim <- format(tab$n_sim, scientific = FALSE, trim = TRUE)
  names(tab)[names(tab) == "distance_mcse"] <- "distance to level (MCSE)"
  tab
}
