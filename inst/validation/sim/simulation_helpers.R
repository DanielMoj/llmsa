# Class-B studies: executable ADEMP contract in docs/02, ADR-023 and ADR-025.
# Scenario numbers are specification parameters, not empirical reference data.
sys.source(system.file("validation", "latent", "reference_checks.R", package = "llmsa", mustWork = TRUE),
           envir = environment())

sim_scenarios <- function(study) {
  ordinal <- c(item = 1, prompt = 0.0625, model = 0.09, `item:model` = 0.09, Residual = 1)
  binary <- c(item = 1, prompt = 0.1, model = 0.1, Residual = pi^2 / 3)
  two <- c(item = 1, prompt = 0.0625, model = 0.05, Residual = 1)
  one <- function(id, index, type, items, prompts, models, blocks, components, mu = 0) {
    list(id = id, index = index, type = type, link = if (type == "binary") "logit" else "probit",
      items = items, prompts = prompts, models = models, reps = 3L, blocks = blocks,
      components = components, mu = mu, cuts = c(-1.5, -0.5, 0.5, 1.5),
      interactions = startsWith(id, "S-ord-"))
  }
  all <- list(
    ordinal_recovery = list(
      one("S-ord-1", 1L, "ordinal", 60L, 3L, 3L, 1L, ordinal),
      one("S-ord-2", 2L, "ordinal", 60L, 5L, 3L, 1L, ordinal),
      one("S-ord-3", 3L, "ordinal", 60L, 3L, 3L, 1L, replace(ordinal, "item", 2.56)),
      one("S-ord-4", 4L, "ordinal", 100L, 3L, 3L, 2L, c(ordinal, block = 0.01))),
    binary_recovery = list(
      one("S-bin-1", 5L, "binary", 60L, 3L, 3L, 1L, binary),
      one("S-bin-2", 6L, "binary", 60L, 5L, 3L, 1L, binary, mu = 1.5)),
    two_level = list(
      one("S-two-1", 7L, "ordinal", 60L, 3L, 2L, 1L, two),
      one("S-two-2", 8L, "ordinal", 60L, 4L, 2L, 1L, replace(two, "model", 0.25))))
  if (length(study) != 1L || !study %in% names(all)) stop("Unknown simulation study: ", paste(study, collapse = ", "), call. = FALSE)
  sc <- all[[study]]
  stats::setNames(sc, vapply(sc, `[[`, character(1), "id"))
}

sim_seed <- function(scenario, rep) {
  # Permanent indices of all eight M1b scenarios; independent of task order.
  seed <- 20261031 + scenario$index + 8 * (as.double(rep) - 1)
  if (any(!is.finite(seed) | seed < 0 | seed > .Machine$integer.max | rep < 1 | rep != floor(rep))) {
    stop("Simulation repetition or seed is out of range.", call. = FALSE)
  }
  as.integer(seed)
}

sim_with_seed <- function(seed, expr) {
  kind <- RNGkind()
  had <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had) state <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    do.call(RNGkind, as.list(kind))
    if (had) assign(".Random.seed", state, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  force(expr)
}

sim_generate <- function(scenario, rep) {
  s <- scenario
  sim_with_seed(sim_seed(s, rep), {
    grid <- expand.grid(rep = seq_len(s$reps), block = seq_len(s$blocks),
      model = seq_len(s$models), prompt = seq_len(s$prompts), item = seq_len(s$items))
    eta <- rep(s$mu, nrow(grid))
    for (name in setdiff(names(s$components), "Residual")) {
      factors <- strsplit(name, ":", fixed = TRUE)[[1L]]
      groups <- interaction(grid[factors], drop = TRUE, lex.order = TRUE)
      effect <- stats::rnorm(nlevels(groups), sd = sqrt(s$components[[name]]))
      eta <- eta + effect[as.integer(groups)]
    }
    value <- if (s$type == "binary") {
      stats::rbinom(nrow(grid), size = 1L, prob = stats::plogis(eta))
    } else {
      latent <- eta + stats::rnorm(nrow(grid))
      paste0("c", findInterval(latent, s$cuts) + 1L)
    }
    llmsa::as_msa_runs(data.frame(item_id = sprintf("I%03d", grid$item),
      prompt_id = paste0("P", grid$prompt), model_id = paste0("M", grid$model),
      block = grid$block, rep = grid$rep, value = value))
  })
}

sim_truth <- function(s) {
  v <- s$components
  grr <- sum(v[names(v) != "item"])
  total <- grr + v[["item"]]
  c(v[names(v) != "Residual"], grr_pct_study_var = 100 * sqrt(grr / total), icc_items = v[["item"]] / total)
}

sim_replicate <- function(scenario, rep, fitter = llmsa::msa_fit) {
  s <- scenario
  warnings <- messages <- character()
  error <- ""
  fit <- NULL
  truth <- sim_truth(s)
  estimate <- stats::setNames(rep(NA_real_, length(truth)), names(truth))
  tryCatch(withCallingHandlers({
    runs <- sim_generate(s, rep)
    fit <- fitter(runs, type = s$type, link = s$link, interactions = s$interactions,
      levels = if (s$type == "ordinal") paste0("c", seq_len(length(s$cuts) + 1L)) else NULL)
    residual <- fit$vc$variance[fit$vc$source == "Residual"]
    if (length(residual) != 1L || !isTRUE(all.equal(residual, unname(s$components[["Residual"]]), tolerance = 0))) {
      stop("Fitted latent residual differs from the scenario link.", call. = FALSE)
    }
    components <- stats::setNames(fit$vc$variance, fit$vc$source)
    summary <- llmsa::msa_grr(fit)$summary
    estimate <- c(components[setdiff(names(truth), c("grr_pct_study_var", "icc_items"))],
                   summary[c("grr_pct_study_var", "icc_items")])[names(truth)]
    if (anyNA(estimate)) stop("A required fitted estimand is missing.", call. = FALSE)
  }, warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning")
  }, message = function(m) {
    messages <<- c(messages, conditionMessage(m)); invokeRestart("muffleMessage")
  }), error = function(e) {
    error <<- conditionMessage(e)
    estimate[] <<- NA_real_
  })
  count <- function(name) if (is.null(fit)) NA_integer_ else as.integer(fit$n[[name]])
  data.frame(scenario = s$id, rep = as.integer(rep), estimand = names(truth),
    estimate = unname(estimate), true = unname(truth), items = count("items"), prompts = count("prompts"),
    models = count("models"), blocks = count("blocks"), observations = count("observations"),
    rep_seed = sim_seed(s, rep), derived = !is.null(fit) && "model" %in% attr(fit$vc, "derived"),
    converged = if (is.null(fit)) FALSE else isTRUE(fit$converged),
    singular = if (is.null(fit)) NA else isTRUE(fit$singular),
    error = if (nzchar(error)) error else NA_character_,
    warnings = if (length(warnings)) paste(warnings, collapse = " | ") else NA_character_,
    messages = if (length(messages)) paste(messages, collapse = " | ") else NA_character_,
    stringsAsFactors = FALSE)
}

sim_performance <- function(x, truth) {
  x <- x[is.finite(x)]
  n <- length(x)
  if (n < 2L) stop("Fewer than two finite estimates (n = ", n, ").", call. = FALSE)
  if (length(truth) != 1L || !is.finite(truth) || truth == 0) stop("Performance measures require a finite nonzero truth.", call. = FALSE)
  bias <- mean(x) - truth
  empse <- stats::sd(x)
  mcse_bias <- empse / sqrt(n)
  errors <- (x - truth)^2
  rmse <- sqrt(mean(errors))
  data.frame(measure = c("bias", "rel_bias", "empse", "rmse"),
    value = c(bias, bias / truth, empse, rmse),
    mcse = c(mcse_bias, mcse_bias / abs(truth), empse / sqrt(2 * (n - 1)),
              if (rmse == 0) 0 else stats::sd(errors) / sqrt(n) / (2 * rmse)),
    stringsAsFactors = FALSE)
}

sim_summarize <- function(replicates, scenarios, n_sim, study) {
  result <- list()
  for (s in scenarios) for (estimand in names(sim_truth(s))) {
    d <- replicates[replicates$scenario == s$id & replicates$estimand == estimand, , drop = FALSE]
    n <- sum(is.finite(d$estimate))
    if (nrow(d) != n_sim || !setequal(d$rep, seq_len(n_sim)) || anyDuplicated(d$rep)) {
      stop("Incomplete or duplicate repetitions: ", s$id, "/", estimand, call. = FALSE)
    }
    if (n < 2L) stop("Cannot summarize ", s$id, "/", estimand, ": fewer than two finite estimates (", n, "/", n_sim,
                     "); inspect replicate errors and warnings.", call. = FALSE)
    measures <- sim_performance(d$estimate, sim_truth(s)[[estimand]])
    if (study == "two_level" && estimand == "model") {
      share <- mean(d$derived)
      measures <- rbind(measures, data.frame(measure = "derived_share", value = share,
                                             mcse = sqrt(share * (1 - share) / n_sim)))
    }
    result[[length(result) + 1L]] <- data.frame(scenario = s$id, estimand = estimand,
      measures, n_sim = n_sim, seed = sim_seed(s, 1L), n_finite = n, n_failed = n_sim - n,
      stringsAsFactors = FALSE)
  }
  d <- do.call(rbind, result)
  d[order(d$scenario, d$estimand, d$measure), , drop = FALSE]
}

sim_parse <- function(study, args) {
  if (!length(args) || length(args) %% 2L) stop("Use --n-sim <n> --out <directory> [--scenarios <ID,ID,...>].", call. = FALSE)
  keys <- args[seq.int(1L, length(args), 2L)]
  values <- args[seq.int(2L, length(args), 2L)]
  if (anyDuplicated(keys) || any(!keys %in% c("--n-sim", "--out", "--scenarios")) ||
      !all(c("--n-sim", "--out") %in% keys) || any(!nzchar(values))) {
    stop("Unknown, repeated or missing simulation option.", call. = FALSE)
  }
  opts <- stats::setNames(as.list(values), keys)
  n <- suppressWarnings(as.numeric(opts[["--n-sim"]]))
  if (!is.finite(n) || n < 2 || n != floor(n)) stop("--n-sim must be an integer of at least two.", call. = FALSE)
  scenarios <- sim_scenarios(study)
  if (!is.null(opts[["--scenarios"]])) {
    requested <- opts[["--scenarios"]]
    ids <- strsplit(requested, ",", fixed = TRUE)[[1L]]
    if (startsWith(requested, ",") || endsWith(requested, ",") || anyDuplicated(ids) || any(!ids %in% names(scenarios))) {
      stop("Unknown, empty or repeated scenario ID for ", study, ".", call. = FALSE)
    }
    scenarios <- scenarios[ids]
  }
  for (s in scenarios) sim_seed(s, n)
  list(n_sim = as.integer(n), out = opts[["--out"]], scenarios = scenarios)
}

sim_paths <- function(out, study) {
  stats::setNames(file.path(out, paste0(study, c("_results.csv", "_replicates.csv", "_session.txt"))),
                  c("results", "replicates", "session"))
}

sim_prepare_output <- function(out, study) {
  if (!dir.exists(out) && !dir.create(out, recursive = TRUE, showWarnings = FALSE)) {
    stop("Cannot create simulation output directory: ", out, call. = FALSE)
  }
  paths <- sim_paths(out, study)
  if (any(file.exists(paths))) stop("Study output already exists; use a fresh output directory: ", out, call. = FALSE)
  probe <- tempfile(".write-check-", tmpdir = out)
  tryCatch(writeLines("", probe), error = function(e) stop("Cannot write simulation output: ", out, ": ", conditionMessage(e), call. = FALSE))
  unlink(probe)
  paths
}

sim_implementation <- function() {
  # Hash the algorithms and scenario definitions, never the generated outputs.
  scope <- environment(sim_implementation)
  helpers <- sort(ls(scope, pattern = "^sim_"))
  helpers <- helpers[vapply(helpers, function(name) is.function(get(name, scope, inherits = FALSE)), logical(1))]
  code <- c(vapply(c("as_msa_runs", "msa_fit", "msa_grr", "msa_mer_converged", "msa_clmm_converged", "vc_from_model", "latent_residual", "grr_stats"),
    function(name) paste(deparse(get(name, asNamespace("llmsa")), width.cutoff = 500L), collapse = "\n"), character(1)),
    vapply(helpers, function(name) paste(deparse(get(name, scope), width.cutoff = 500L), collapse = "\n"), character(1)))
  digest::digest(paste(code, collapse = "\n"), algo = "sha256", serialize = FALSE)
}

sim_metadata <- function(study, scenarios, n_sim) {
  packages <- c("llmsa", "lme4", "ordinal", "Matrix", "parallel")
  c("format: llmsa-class-b-v1", paste0("study: ", study), paste0("n_sim: ", n_sim),
    paste0("implementation: ", sim_implementation()), paste0("R_version: ", getRversion()),
    paste0("package_", packages, ": ", vapply(packages, function(p) as.character(utils::packageVersion(p)), character(1))),
    "RNG: Mersenne-Twister; normal.kind=Inversion; sample.kind=Rejection",
    "seed_rule: 20261031 + j(scenario) + 8 * (rep - 1); permanent j=1..8 in specification order",
    paste0("scenarios: ", paste(names(scenarios), collapse = ",")),
    paste0("start_seeds: ", paste(vapply(scenarios, function(s) paste0(s$id, "=", sim_seed(s, 1L)), character(1)), collapse = ",")))
}

sim_write <- function(paths, replicates, scenarios, n_sim, study, session) {
  # Preserve all estimates and diagnoses even when aggregation must fail.
  utils::write.csv(replicates, paths[["replicates"]], row.names = FALSE)
  writeLines(session, paths[["session"]])
  result <- tryCatch(sim_summarize(replicates, scenarios, n_sim, study), error = function(e) {
    cat("\nAggregation failure: ", conditionMessage(e), "\n", file = paths[["session"]], append = TRUE, sep = "")
    stop(conditionMessage(e), call. = FALSE)
  })
  stage <- tempfile(".results-", tmpdir = dirname(paths[["results"]]))
  on.exit(unlink(stage), add = TRUE)
  utils::write.csv(result, stage, row.names = FALSE)
  if (!file.rename(stage, paths[["results"]])) stop("Cannot publish simulation result file: ", paths[["results"]], call. = FALSE)
  invisible(result)
}

sim_main <- function(study, args) {
  opts <- sim_parse(study, args)
  anchors <- latent_anchors(latent_context(repo_root = ""))
  cap <- latent_tolerance(anchors, "sim_runtime", "cores")
  workers <- suppressWarnings(as.numeric(Sys.getenv("LLMSA_SIM_WORKERS", as.character(cap))))
  if (length(workers) != 1L || !is.finite(workers) || workers < 1 || workers != floor(workers) || workers > cap) {
    stop("LLMSA_SIM_WORKERS must be an integer between one and the ANK-TOL.sim_runtime core limit.", call. = FALSE)
  }
  if (.Platform$OS.type == "windows") workers <- 1L
  paths <- sim_prepare_output(opts$out, study)
  # Load before fork so sessionInfo() records the engines used by workers.
  for (pkg in c("lme4", "ordinal", "parallel")) loadNamespace(pkg)
  tasks <- unlist(lapply(opts$scenarios, function(s) lapply(seq_len(opts$n_sim), function(r) list(s = s, rep = r))), recursive = FALSE)
  workers <- min(workers, length(tasks))
  task <- function(x) sim_replicate(x$s, x$rep)
  start <- proc.time()[["elapsed"]]
  computed <- if (workers == 1L) lapply(tasks, task) else {
    parallel::mclapply(tasks, task, mc.cores = as.integer(workers), mc.set.seed = FALSE)
  }
  if (any(!vapply(computed, is.data.frame, logical(1)))) stop("Simulation worker failed before returning its diagnoses.", call. = FALSE)
  reps <- do.call(rbind, computed)
  reps <- reps[order(reps$scenario, reps$rep, reps$estimand), , drop = FALSE]
  elapsed <- proc.time()[["elapsed"]] - start
  diagnoses <- unique(reps[c("scenario", "rep", "rep_seed", "error", "warnings", "messages")])
  diagnostic <- function(x) if (is.na(x)) "(none)" else x
  lines <- vapply(seq_len(nrow(diagnoses)), function(i) {
    d <- diagnoses[i, ]
    paste0(d$scenario, " rep=", d$rep, " seed=", d$rep_seed, " error=[", diagnostic(d$error),
           "] warnings=[", diagnostic(d$warnings), "] messages=[", diagnostic(d$messages), "]")
  }, character(1))
  session <- c(sim_metadata(study, opts$scenarios, opts$n_sim),
    paste0("command: Rscript ", study, ".R ", paste(vapply(args, shQuote, character(1)), collapse = " ")),
    paste0("workers: ", workers), sprintf("elapsed_seconds: %.6f", elapsed),
    "", "Per-repetition diagnostics (including every repetition seed):", lines,
    "", utils::capture.output(utils::sessionInfo()))
  result <- sim_write(paths, reps, opts$scenarios, opts$n_sim, study, session)
  cat(sprintf("%s: %d scenarios x %d repetitions; %d result rows; elapsed %.3f s; workers %d\n",
              study, length(opts$scenarios), opts$n_sim, nrow(result), elapsed, workers))
  invisible(paths)
}

sim_session_fields <- function(lines) {
  keys <- c("format", "study", "n_sim", "implementation", "R_version",
             paste0("package_", c("llmsa", "lme4", "ordinal", "Matrix", "parallel")),
             "RNG", "seed_rule", "scenarios", "start_seeds")
  stats::setNames(vapply(keys, function(key) {
    prefix <- paste0(key, ": ")
    hit <- lines[startsWith(lines, prefix)]
    if (length(hit) != 1L) stop("Missing or duplicate session field: ", key, call. = FALSE)
    substring(hit, nchar(prefix) + 1L)
  }, character(1)), keys)
}

sim_read_csv <- function(path) {
  # Type inference turns an entirely empty diagnostic column into logical NA.
  # Preserve the distinction between an empty diagnosis and a missing value.
  columns <- names(utils::read.csv(path, nrows = 0L, check.names = FALSE))
  text <- intersect(columns, c("scenario", "estimand", "measure", "error", "warnings", "messages"))
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
                 colClasses = stats::setNames(rep("character", length(text)), text))
}

sim_merge <- function(study, directories, out) {
  scenarios <- sim_scenarios(study)
  if (!length(directories) || anyDuplicated(normalizePath(directories, mustWork = TRUE))) {
    stop("Provide distinct directories of successful scenario runs.", call. = FALSE)
  }
  anchors <- latent_anchors(latent_context(repo_root = ""))
  tolerance <- latent_tolerance(anchors, "arithmetic", "abs_tol")
  parts <- lapply(directories, function(directory) {
    paths <- sim_paths(directory, study)
    if (!all(file.exists(paths))) stop("Incomplete simulation triplet: ", directory, call. = FALSE)
    session <- readLines(paths[["session"]], warn = FALSE)
    fields <- sim_session_fields(session)
    if (any(startsWith(session, "Aggregation failure:"))) stop("Cannot merge a failed run: ", directory, call. = FALSE)
    result <- sim_read_csv(paths[["results"]])
    reps <- sim_read_csv(paths[["replicates"]])
    required_result <- c("scenario", "estimand", "measure", "value", "mcse", "n_sim", "seed", "n_finite", "n_failed")
    required_rep <- c("scenario", "rep", "estimand", "estimate", "true", "items", "prompts", "models", "blocks",
                      "observations", "rep_seed", "derived", "converged", "singular", "error", "warnings", "messages")
    if (anyDuplicated(names(result)) || anyDuplicated(names(reps)) ||
        !setequal(names(result), required_result) || !setequal(names(reps), required_rep) || !nrow(reps) || !nrow(result)) {
      stop("Invalid simulation triplet schema: ", directory, call. = FALSE)
    }
    ids <- strsplit(fields[["scenarios"]], ",", fixed = TRUE)[[1L]]
    n <- suppressWarnings(as.numeric(fields[["n_sim"]]))
    if (fields[["study"]] != study || !is.finite(n) || n < 2 || n != floor(n) ||
        anyDuplicated(ids) || any(!ids %in% names(scenarios)) ||
        !setequal(unique(reps$scenario), ids) || !setequal(unique(result$scenario), ids) ||
        anyNA(result) || any(result$n_sim != n) || anyDuplicated(result[c("scenario", "estimand", "measure")])) {
      stop("Inconsistent simulation scenario, n_sim or keys: ", directory, call. = FALSE)
    }
    selected <- scenarios[ids]
    expected <- sim_session_fields(sim_metadata(study, selected, n))
    if (!identical(fields, expected)) stop("Simulation versions, implementation, seeds or RNG differ: ", directory, call. = FALSE)
    for (s in selected) {
      d <- reps[reps$scenario == s$id, , drop = FALSE]
      truth <- sim_truth(s)
      if (anyNA(d[c("rep", "rep_seed", "estimand", "true", "derived")]) ||
          !is.logical(d$derived) || !setequal(unique(d$estimand), names(truth)) ||
          any(d$rep_seed != sim_seed(s, d$rep)) ||
          any(abs(d$true - truth[d$estimand]) > tolerance)) {
        stop("Inconsistent simulation replicate seeds, flags or truths: ", s$id, call. = FALSE)
      }
    }
    reference <- sim_summarize(reps, selected, as.integer(n), study)
    result <- result[order(result$scenario, result$estimand, result$measure), , drop = FALSE]
    if (nrow(reference) != nrow(result)) stop("Incomplete simulation result rows: ", directory, call. = FALSE)
    for (name in names(reference)) {
      same <- if (is.numeric(reference[[name]])) {
        all(is.finite(result[[name]]) & abs(reference[[name]] - result[[name]]) <= tolerance)
      } else identical(as.character(reference[[name]]), as.character(result[[name]]))
      if (!same) stop("Simulation result differs from replicates: ", directory, "/", name, call. = FALSE)
    }
    list(result = result, reps = reps, fields = fields, session = session, paths = paths)
  })
  ids <- unlist(lapply(parts, function(p) unique(p$reps$scenario)), use.names = FALSE)
  if (anyDuplicated(ids) || !setequal(ids, names(scenarios))) {
    stop("Scenario runs must be disjoint and cover the entire study.", call. = FALSE)
  }
  ns <- vapply(parts, function(p) p$fields[["n_sim"]], character(1))
  if (length(unique(ns)) != 1L) stop("Scenario runs have different n_sim.", call. = FALSE)
  reps <- do.call(rbind, lapply(parts, `[[`, "reps"))
  reps <- reps[order(reps$scenario, reps$rep, reps$estimand), , drop = FALSE]
  result <- do.call(rbind, lapply(parts, `[[`, "result"))
  result <- result[order(result$scenario, result$estimand, result$measure), , drop = FALSE]
  paths <- sim_prepare_output(out, study)
  provenance <- unlist(lapply(seq_along(parts), function(i) {
    p <- parts[[i]]
    hashes <- vapply(p$paths, function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE), character(1))
    # Prefix originals so top-level metadata stays unambiguous in future reads.
    c(paste0("input: ", normalizePath(directories[i], mustWork = TRUE)),
      paste0("input_sha256: ", names(hashes), " ", hashes), paste0("original_session: ", p$session))
  }), use.names = FALSE)
  session <- c(sim_metadata(study, scenarios, as.integer(ns[1L])),
    "merge: complete disjoint scenarios; estimates and result cells retained",
    "runtime: see original_session entries; no combined run time is asserted", provenance,
    "", utils::capture.output(utils::sessionInfo()))
  # Do not recompute fits or replace the result rows with the verification above.
  utils::write.csv(reps, paths[["replicates"]], row.names = FALSE)
  written <- sim_read_csv(paths[["replicates"]])
  format_cells <- function(x) if (is.numeric(x)) vapply(x, format, character(1), digits = 15L) else as.character(x)
  for (name in names(reps)) {
    if (!identical(format_cells(written[[name]]), format_cells(reps[[name]]))) {
      stop("Merge changed a replicate cell: ", name, call. = FALSE)
    }
  }
  writeLines(session, paths[["session"]])
  utils::write.csv(result, paths[["results"]], row.names = FALSE)
  written_result <- sim_read_csv(paths[["results"]])
  for (name in names(result)) {
    if (!identical(format_cells(written_result[[name]]), format_cells(result[[name]]))) {
      stop("Merge changed a result cell: ", name, call. = FALSE)
    }
  }
  cat("Merged ", length(parts), " disjoint scenario triplets for ", study, "; no fits recomputed\n", sep = "")
  invisible(paths)
}
