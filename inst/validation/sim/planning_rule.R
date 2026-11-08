#!/usr/bin/env Rscript
# Class A documentation data for K-M3c-6, ADR-054 and ADR-055.
# This generator is never loaded by the vignette's result reader.
# Usage: Rscript planning_rule.R --out <directory> [--workers <n>] [--package <source-package>]

planning_rule_settings <- function() {
  # Specification settings: docs/02 S-boot-1; ADR-054 Nr. 7 (ACC-8).
  list(designs = data.frame(plan = paste0("S-plan-", seq_len(4L)), scenario = seq_len(4L),
    n_items = c(20L, 20L, 40L, 40L), n_prompts = c(3L, 5L, 3L, 5L), n_models = 3L,
    n_reps = 2L, n_blocks = 2L, seed = 20261108L + seq_len(4L), stringsAsFactors = FALSE),
    vc = list(item = 1, prompt = 0.05, model = 0.05, block = 0.01,
              item_prompt = 0.01, item_model = 0.05, prompt_model = 0.005, residual = 0.1),
    rng = c("Mersenne-Twister", "Inversion", "Rejection"))
}

planning_rule_csv <- function(data, path) {
  # Preserve all double bits, including tiny positive estimates next to zero.
  cells <- lapply(data, function(x) if (is.double(x)) sprintf("%.17g", x) else x)
  table <- as.data.frame(cells, stringsAsFactors = FALSE, check.names = FALSE)
  connection <- if (endsWith(path, ".gz")) gzfile(path, open = "wt", compression = 9, encoding = "UTF-8") else
    file(path, open = "wt", encoding = "UTF-8")
  on.exit(close(connection), add = TRUE)
  utils::write.table(table, connection, row.names = FALSE, col.names = TRUE, sep = ",", eol = "\n",
                     quote = which(vapply(data, is.character, logical(1))), qmethod = "double", na = "NA", dec = ".")
}

planning_rule_generate <- function(out, workers = 1L,
                                   repo_root = Sys.getenv("REPO_ROOT", ""),
                                   input_dir = system.file("validation", "planning", package = "llmsa", mustWork = TRUE)) {
  if (!is.numeric(workers) || length(workers) != 1L || !is.finite(workers) || workers < 1 || workers != floor(workers)) {
    stop("Planning workers must be a positive integer.", call. = FALSE)
  }
  if (.Platform$OS.type == "windows" && workers > 1L) {
    stop("Use --workers 1 for sequential planning generation on Windows.", call. = FALSE)
  }
  helpers <- new.env(parent = globalenv())
  sys.source(system.file("validation", "planning", "reference_checks.R", package = "llmsa", mustWork = TRUE), envir = helpers)
  inputs <- helpers$planning_inputs(input_dir, repo_root)
  settings <- planning_rule_settings()
  n_sim <- as.integer(inputs$n_min)
  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  old_seed <- if (had_seed) get(".Random.seed", envir = .GlobalEnv, inherits = FALSE) else NULL
  old_options <- options(OutDec = ".")
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv) else
      if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
    options(old_options)
  }, add = TRUE)
  do.call(RNGkind, as.list(settings$rng))
  started <- proc.time()[["elapsed"]]
  run_plan <- function(i) {
    d <- settings$designs[i, , drop = FALSE]
    t0 <- proc.time()[["elapsed"]]
    message(sprintf("Planning %s: starting %d repetitions with seed %d.", d$plan, n_sim, d$seed))
    fields <- c("n_items", "n_prompts", "n_models", "n_reps", "n_blocks")
    # Exactly one call per candidate; msa_plan() consumes its sequential stream.
    plan <- getExportedValue("llmsa", "msa_plan")(d[, fields], vc = settings$vc,
      nsim = n_sim, seed = d$seed, verbose = FALSE)
    reps <- attr(plan, "replicates", exact = TRUE)
    if (!is.data.frame(reps) || nrow(reps) != n_sim) stop("Incomplete planning result: ", d$plan, call. = FALSE)
    reps$plan <- d$plan
    reps$scenario <- d$scenario
    message(sprintf("Planning %s: completed %d repetitions in %.3f s.",
                    d$plan, nrow(reps), proc.time()[["elapsed"]] - t0))
    list(summary = as.data.frame(plan), replicates = reps[, helpers$planning_replicate_columns],
         elapsed = proc.time()[["elapsed"]] - t0)
  }
  indices <- seq_len(nrow(settings$designs))
  fits <- if (workers == 1L) lapply(indices, run_plan) else
    parallel::mclapply(indices, run_plan, mc.cores = min(workers, length(indices)), mc.set.seed = FALSE)
  errors <- vapply(fits, inherits, logical(1), "try-error")
  if (any(errors)) stop("Planning generation failed: ", paste(unlist(fits[errors]), collapse = "\n"), call. = FALSE)
  elapsed <- proc.time()[["elapsed"]] - started
  stage <- tempfile("planning-results-")
  dir.create(file.path(stage, "anchors"), recursive = TRUE)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  if (!file.copy(file.path(input_dir, "anchors", "ANK-89.json"), file.path(stage, "anchors", "ANK-89.json"))) {
    stop("Cannot stage the planning anchor.", call. = FALSE)
  }
  replicates <- do.call(rbind, lapply(fits, `[[`, "replicates"))
  rownames(replicates) <- NULL
  planning_rule_csv(replicates, file.path(stage, "replicates.csv.gz"))
  stored <- helpers$planning_csv(file.path(stage, "replicates.csv.gz"),
    c("character", "integer", "integer", "numeric", "logical", "numeric"), helpers$planning_replicate_columns)
  if (!identical(stored, replicates)) stop("Planning replicate serialization changed a value or type.", call. = FALSE)
  summary <- helpers$planning_summarize(stored, settings$designs, settings$vc, inputs)
  summary_fields <- c("grr_true", "mean", "q2.5", "median", "q97.5", "rmse", "pct_singular",
                      "pct_misclassified", "bias", "empse", "mcse_bias", "mcse_empse")
  for (i in indices) {
    for (column in summary_fields) {
      if (!isTRUE(abs(summary[[column]][i] - fits[[i]]$summary[[column]]) <= inputs$tolerance)) {
        stop("Stored replicates disagree with msa_plan(): ", settings$designs$plan[i], ", ", column, call. = FALSE)
      }
    }
  }
  planning_rule_csv(summary, file.path(stage, "summary.csv"))
  namespace <- asNamespace("llmsa")
  hash <- function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE)
  functions <- c("msa_plan", "msa_simulate", "msa_fit", "grr_stats", "as_msa_runs")
  function_hashes <- stats::setNames(lapply(functions, function(name) {
    f <- get(name, envir = namespace, inherits = FALSE)
    digest::digest(paste(deparse(f, width.cutoff = 500L), collapse = "\n"), algo = "sha256", serialize = FALSE)
  }), functions)
  source_root <- getNamespaceInfo(namespace, "path")
  source_files <- list.files(file.path(source_root, "R"), pattern = "\\.R$", full.names = TRUE)
  source_hashes <- stats::setNames(lapply(source_files, hash), paste0("R/", basename(source_files)))
  for (file in c("validation/sim/planning_rule.R", "validation/planning/reference_checks.R")) {
    source_hashes[[paste0("inst/", file)]] <- hash(system.file(file, package = "llmsa", mustWork = TRUE))
  }
  versions <- stats::setNames(lapply(c("llmsa", "lme4", "Matrix", "ordinal", "jsonlite", "digest"),
                                    function(p) as.character(utils::packageVersion(p))),
                              c("llmsa", "lme4", "Matrix", "ordinal", "jsonlite", "digest"))
  versions$R <- R.version.string
  session <- c("Planning rule comparison: class A documentation results (K-M3c-6).",
    "Source settings: docs/02 S-boot-1; ADR-054 Nr. 7 (ACC-8).",
    paste("n_sim:", n_sim), paste("RNG:", paste(settings$rng, collapse = "/")),
    paste("Method:", helpers$planning_cv_method),
    "All singular fits and exact zeros are retained; no fitted repetitions are dropped.",
    "Boundary: prompt == 0; CV: sample SD / mean; MCSE(boundary): sqrt(p * (1-p) / n_sim).",
    "CV MCSE: delta approximation using cov(cbind(prompt, prompt^2)) / n_sim; not a pass criterion.",
    sprintf("Workers: %d; elapsed seconds: %.3f", workers, elapsed),
    vapply(indices, function(i) sprintf("%s: seed %d; n_sim %d; elapsed seconds %.3f",
      settings$designs$plan[i], settings$designs$seed[i], n_sim, fits[[i]]$elapsed), ""),
    "Function SHA-256:", paste(names(function_hashes), unlist(function_hashes)),
    "Source SHA-256:", paste(names(source_hashes), unlist(source_hashes)),
    "Session:", utils::capture.output(utils::sessionInfo()))
  writeLines(session, file.path(stage, "session.txt"), useBytes = TRUE)
  manifest <- inputs$manifest[c("schema", "preparation", "anchors")]
  manifest$generator <- "inst/validation/sim/planning_rule.R"
  manifest$study <- list(specification = "docs/02 S-boot-1; ADR-054 Nr. 7 (ACC-8)", designs = settings$designs,
                         vc = settings$vc, n_sim = n_sim, rng = settings$rng)
  manifest$provenance <- list(versions = versions, function_sha256 = function_hashes, source_sha256 = source_hashes,
                             workers = workers, elapsed_seconds = elapsed, cv_mcse_method = helpers$planning_cv_method)
  manifest$results <- stats::setNames(lapply(c("summary.csv", "replicates.csv.gz", "session.txt"), function(name) {
    list(sha256 = hash(file.path(stage, name)))
  }), c("summary.csv", "replicates.csv.gz", "session.txt"))
  jsonlite::write_json(manifest, file.path(stage, "SOURCES.json"), pretty = TRUE, auto_unbox = TRUE, digits = NA)
  checked <- helpers$planning_read_results(stage, repo_root)
  dir.create(file.path(out, "anchors"), recursive = TRUE, showWarnings = FALSE)
  for (name in c("anchors/ANK-89.json", "summary.csv", "replicates.csv.gz", "session.txt", "SOURCES.json")) {
    if (!file.copy(file.path(stage, name), file.path(out, name), overwrite = TRUE)) {
      stop("Cannot publish planning result: ", name, call. = FALSE)
    }
  }
  print(helpers$planning_display(checked$table), row.names = FALSE)
  print(helpers$planning_display(checked$cv_mcse), row.names = FALSE)
  cat(sprintf("Planning generation: %d plans; %d replicates; n_sim %d per plan; %.3f s; RNG %s.\n",
              nrow(summary), nrow(stored), n_sim, elapsed, paste(settings$rng, collapse = "/")))
  invisible(checked)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) %% 2L || !length(args)) stop("Use --out <directory> [--workers <n>] [--package <source-package>].", call. = FALSE)
  keys <- args[seq.int(1L, length(args), by = 2L)]
  if (anyDuplicated(keys) || any(!keys %in% c("--out", "--workers", "--package")) || !"--out" %in% keys) {
    stop("Use --out <directory> [--workers <n>] [--package <source-package>].", call. = FALSE)
  }
  values <- stats::setNames(args[seq.int(2L, length(args), by = 2L)], keys)
  if ("--package" %in% keys) pkgload::load_all(values[["--package"]], quiet = TRUE, helpers = FALSE) else
    loadNamespace("llmsa")
  workers <- if ("--workers" %in% keys) suppressWarnings(as.numeric(values[["--workers"]])) else 1L
  planning_rule_generate(values[["--out"]], workers)
}
