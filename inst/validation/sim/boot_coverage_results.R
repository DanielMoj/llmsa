# Offline coverage tables: result schema and anchored run sizes only.
# The reader does not load a generator, fit models or read replicate/session files.
sys.source(system.file("validation", "latent", "reference_checks.R", package = "llmsa", mustWork = TRUE),
           envir = environment())

boot_interval_estimands <- c("grr_pct_study_var", "grr_pct_contribution", "ndc", "icc_items")

# These names are the estimands of docs/02 M1c, not numerical study findings.
boot_result_estimands <- function(binary) {
  components <- if (binary) c("item", "prompt", "model") else
    c("item", "prompt", "model", "block", "item:prompt", "item:model", "prompt:model", "Residual")
  c(components, boot_interval_estimands)
}

boot_read_results <- function(sim_dir = system.file("validation", "sim", package = "llmsa", mustWork = TRUE)) {
  full <- file.path(sim_dir, "boot_coverage_results.csv")
  path <- if (file.exists(full)) full else file.path(sim_dir, "boot_coverage_check_results.csv")
  if (!file.exists(path)) stop("Coverage study results are missing: ", path, call. = FALSE)
  d <- tryCatch(utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE),
    error = function(e) stop("Cannot read coverage study results: ", path, ": ", conditionMessage(e), call. = FALSE))
  required <- c("scenario", "estimand", "measure", "value", "mcse", "n_sim", "seed")
  if (anyDuplicated(names(d)) || !all(required %in% names(d)) || !nrow(d) || anyNA(d[required])) {
    stop("Invalid coverage results schema: ", path, call. = FALSE)
  }
  for (name in c("value", "mcse", "n_sim", "seed")) {
    if (!is.numeric(d[[name]]) || any(!is.finite(d[[name]]))) stop("Invalid coverage results column: ", name, call. = FALSE)
  }
  if (any(d$mcse < 0) || length(unique(d$n_sim)) != 1L || any(d$n_sim < 2 | d$n_sim != floor(d$n_sim)) ||
      anyDuplicated(d[c("scenario", "estimand", "measure")])) {
    stop("Invalid coverage results values or duplicate keys: ", path, call. = FALSE)
  }
  bounded <- d$measure %in% c("coverage", "singular_share", "failed_share")
  if (any(d$value[bounded] < 0 | d$value[bounded] > 1)) stop("Coverage proportions are outside [0, 1]: ", path, call. = FALSE)
  anchors <- latent_anchors(latent_context(repo_root = ""))
  parameters <- list(n_min = latent_get(anchors, "ANK-06", "value", "n_sim_min"),
    n_check = latent_tolerance(anchors, "n_check", "n_sim"))
  is_full <- identical(path, full)
  ids <- if (is_full) paste0("S-boot-", seq_len(7L)) else c("S-boot-1", "S-boot-7")
  if (!setequal(unique(d$scenario), ids)) stop("Incomplete coverage scenarios: ", path, call. = FALSE)
  if ((is_full && unique(d$n_sim) < parameters$n_min) || (!is_full && unique(d$n_sim) != parameters$n_check)) {
    stop("Coverage result n_sim does not meet the anchored run size: ", path, call. = FALSE)
  }
  for (id in ids) for (estimand in c(boot_result_estimands(id == "S-boot-7"), "bootstrap")) {
    measures <- if (estimand == "bootstrap") c("singular_share", "failed_share") else
      c("bias", "rel_bias", "empse", "rmse", if (estimand %in% boot_interval_estimands) c("coverage", "width"))
    rows <- d[d$scenario == id & d$estimand == estimand, , drop = FALSE]
    if (!all(measures %in% rows$measure)) stop("Incomplete coverage measures: ", id, "/", estimand, call. = FALSE)
  }
  # Display reads the results only. Replicate/session consistency is checked
  # by the study/reproduction workflow, not by knitting this table.
  list(data = d, path = path, mode = if (is_full) "full" else "check",
       n_sim = unique(d$n_sim), n_min = parameters$n_min)
}
