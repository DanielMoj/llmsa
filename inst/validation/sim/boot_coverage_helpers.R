# Class-B coverage study: docs/02 M1c and ADR-042. Scenario components are
# specification parameters; empirical conventions come from verified anchors.
sys.source(system.file("validation", "sim", "simulation_helpers.R", package = "llmsa", mustWork = TRUE),
           envir = environment())
sys.source(system.file("validation", "numeric", "reference_checks.R", package = "llmsa", mustWork = TRUE),
           envir = environment())

sys.source(system.file("validation", "sim", "boot_coverage_results.R", package = "llmsa", mustWork = TRUE),
           envir = environment())

boot_parameters <- function() {
  latent <- latent_anchors(latent_context(repo_root = ""))
  numeric <- validation_anchors(validation_context(repo_root = ""))
  list(ndc = validation_get(numeric, "ANK-16", "value", "ndc"),
    residual = latent_get(latent, "ANK-28", "value", "logit"),
    n_min = latent_get(latent, "ANK-06", "value", "n_sim_min"),
    n_check = latent_tolerance(latent, "n_check", "n_sim"),
    cores = latent_tolerance(latent, "sim_runtime", "cores"),
    arithmetic = latent_tolerance(latent, "arithmetic", "abs_tol"))
}

boot_scenarios <- function(parameters = boot_parameters()) {
  a <- c(item = 1, prompt = 0.05, model = 0.05, block = 0.01,
          `item:prompt` = 0.01, `item:model` = 0.05, `prompt:model` = 0.005, Residual = 0.1)
  b <- replace(a, c("prompt", "Residual"), c(0.3, 0.5))
  binary <- c(item = 1, prompt = 0.1, model = 0.1, Residual = parameters$residual)
  one <- function(index, items, prompts, components, type = "numeric", blocks = 2L) {
    list(id = paste0("S-boot-", index), index = index, type = type,
      link = if (type == "binary") "logit" else NULL,
      items = items, prompts = prompts, models = 3L, reps = 3L, blocks = blocks,
      components = components, mu = 0, ndc = parameters$ndc)
  }
  scenarios <- list(one(1L, 20L, 3L, a), one(2L, 20L, 5L, a),
    one(3L, 50L, 3L, a), one(4L, 50L, 5L, a),
    one(5L, 20L, 3L, b), one(6L, 20L, 5L, b),
    one(7L, 60L, 3L, binary, "binary", 1L))
  stats::setNames(scenarios, vapply(scenarios, `[[`, character(1), "id"))
}

boot_seeds <- function(scenario, rep) {
  # Permanent indices and paired streams, approved in ADR-042 section 18.1.
  data <- 20261102 + 2 * (scenario$index - 1) + 14 * (as.double(rep) - 1)
  if (any(!is.finite(data) | data < 0 | data + 1 > .Machine$integer.max |
          rep < 1 | rep != floor(rep))) {
    stop("Coverage repetition or seed is out of range.", call. = FALSE)
  }
  list(data = as.integer(data), boot = as.integer(data + 1))
}

boot_generate <- function(scenario, rep) {
  s <- scenario
  sim_with_seed(boot_seeds(s, rep)$data, {
    grid <- expand.grid(rep = seq_len(s$reps), block = seq_len(s$blocks),
      model = seq_len(s$models), prompt = seq_len(s$prompts), item = seq_len(s$items))
    eta <- rep(s$mu, nrow(grid))
    for (name in setdiff(names(s$components), "Residual")) {
      groups <- interaction(grid[strsplit(name, ":", fixed = TRUE)[[1L]]], drop = TRUE, lex.order = TRUE)
      eta <- eta + stats::rnorm(nlevels(groups), sd = sqrt(s$components[[name]]))[as.integer(groups)]
    }
    value <- if (s$type == "binary") {
      stats::rbinom(nrow(grid), size = 1L, prob = stats::plogis(eta))
    } else {
      eta + stats::rnorm(nrow(grid), sd = sqrt(s$components[["Residual"]]))
    }
    llmsa::as_msa_runs(data.frame(item_id = sprintf("I%03d", grid$item),
      prompt_id = paste0("P", grid$prompt), model_id = paste0("M", grid$model),
      block = grid$block, rep = grid$rep, value = value))
  })
}

boot_truth <- function(s) {
  v <- s$components
  gauge <- sum(v[names(v) != "item"])
  total <- gauge + v[["item"]]
  components <- if (s$type == "binary") v[names(v) != "Residual"] else v
  c(components, grr_pct_study_var = 100 * sqrt(gauge / total),
    grr_pct_contribution = 100 * gauge / total,
    ndc = max(s$ndc$minimum, floor(s$ndc$constant * sqrt(v[["item"]] / gauge))),
    icc_items = v[["item"]] / total)
}

boot_replicate <- function(scenario, rep, fitter = llmsa::msa_fit, bootstrapper = llmsa::msa_boot) {
  s <- scenario
  seeds <- boot_seeds(s, rep)
  truth <- boot_truth(s)
  estimate <- lower <- upper <- stats::setNames(rep(NA_real_, length(truth)), names(truth))
  settings <- stats::setNames(rep(NA_real_, 4L), c("boot_nsim", "boot_level", "n_singular", "n_failed"))
  warnings <- messages <- character()
  error <- error_stage <- NA_character_
  stage <- "fit"
  capture <- function(expr) withCallingHandlers(expr,
    warning = function(w) {
      warnings <<- c(warnings, paste0(stage, ": ", conditionMessage(w)))
      invokeRestart("muffleWarning")
    }, message = function(m) {
      messages <<- c(messages, paste0(stage, ": ", conditionMessage(m)))
      invokeRestart("muffleMessage")
    })
  failed <- function(e) {
    error <<- conditionMessage(e)
    error_stage <<- stage
    NULL
  }
  fitted <- tryCatch(capture({
    runs <- boot_generate(s, rep)
    f <- if (s$type == "numeric") fitter(runs, type = "numeric") else fitter(runs, type = "binary", link = s$link)
    components <- stats::setNames(f$vc$variance, f$vc$source)
    summary <- llmsa::msa_grr(f)$summary
    targets <- setdiff(names(truth), boot_interval_estimands)
    if (!all(targets %in% names(components)) || !all(boot_interval_estimands %in% names(summary))) {
      stop("A required coverage-study estimand is missing from the fit.", call. = FALSE)
    }
    list(fit = f, estimate = c(components[targets], summary[boot_interval_estimands])[names(truth)])
  }), error = failed)
  fit <- if (is.null(fitted)) NULL else fitted$fit
  if (!is.null(fit)) {
    estimate <- fitted$estimate
    stage <- "bootstrap"
    booted <- tryCatch(capture({
      # No nsim argument: every run uses the package default, including checks.
      b <- sim_with_seed(seeds$boot, bootstrapper(fit, level = 0.95, seed = seeds$boot))
      if (anyDuplicated(b$statistic) || !all(boot_interval_estimands %in% b$statistic) ||
          !is.matrix(attr(b, "boot"))) {
        stop("Incomplete coverage bootstrap statistics or replicates.", call. = FALSE)
      }
      counts <- c(boot_nsim = nrow(attr(b, "boot")), boot_level = attr(b, "level"),
                  n_singular = attr(b, "n_singular"), n_failed = attr(b, "n_failed"))
      if (length(counts) != 4L || any(!is.finite(counts)) || counts[["boot_nsim"]] < 1 ||
          any(counts[c("n_singular", "n_failed")] < 0) ||
          any(counts[c("n_singular", "n_failed")] != floor(counts[c("n_singular", "n_failed")])) ||
          sum(counts[c("n_singular", "n_failed")]) > counts[["boot_nsim"]]) {
        stop("Incomplete or invalid coverage bootstrap counts.", call. = FALSE)
      }
      rows <- match(boot_interval_estimands, b$statistic)
      list(lower = b$lower[rows], upper = b$upper[rows], settings = counts)
    }), error = failed)
    if (!is.null(booted)) {
      lower[boot_interval_estimands] <- booted$lower
      upper[boot_interval_estimands] <- booted$upper
      settings <- booted$settings
    }
  }
  count <- function(name) if (is.null(fit)) NA_integer_ else as.integer(fit$n[[name]])
  data.frame(scenario = s$id, rep = as.integer(rep), estimand = names(truth),
    estimate = unname(estimate), true = unname(truth), lower = unname(lower), upper = unname(upper),
    items = count("items"), prompts = count("prompts"), models = count("models"),
    blocks = count("blocks"), observations = count("observations"),
    boot_nsim = settings[["boot_nsim"]], boot_level = settings[["boot_level"]],
    n_singular = settings[["n_singular"]], n_failed = settings[["n_failed"]],
    data_seed = seeds$data, boot_seed = seeds$boot,
    converged = if (is.null(fit)) NA else isTRUE(fit$converged),
    singular = if (is.null(fit)) NA else isTRUE(fit$singular),
    error_stage = error_stage, error = error,
    warnings = if (length(warnings)) paste(warnings, collapse = " | ") else NA_character_,
    messages = if (length(messages)) paste(messages, collapse = " | ") else NA_character_,
    stringsAsFactors = FALSE)
}

boot_mean_mcse <- function(x, label) {
  x <- x[is.finite(x)]
  if (length(x) < 2L) stop("Cannot summarize ", label, ": fewer than two finite values.", call. = FALSE)
  c(value = mean(x), mcse = stats::sd(x) / sqrt(length(x)))
}

boot_summarize <- function(replicates, scenarios, n_sim) {
  result <- list()
  append <- function(s, estimand, measures, n) {
    if (any(!is.finite(measures$value)) || any(!is.finite(measures$mcse) | measures$mcse < 0)) {
      stop("Non-finite coverage performance measure: ", s$id, "/", estimand, call. = FALSE)
    }
    result[[length(result) + 1L]] <<- data.frame(scenario = s$id, estimand = estimand,
      measures, n_sim = n_sim, seed = boot_seeds(s, 1L)$data, n_finite = n, n_failed = n_sim - n)
  }
  for (s in scenarios) {
    truth <- boot_truth(s)
    scenario_rows <- replicates[replicates$scenario == s$id, , drop = FALSE]
    if (!setequal(unique(scenario_rows$estimand), names(truth))) {
      stop("Incomplete coverage estimands: ", s$id, call. = FALSE)
    }
    for (estimand in names(truth)) {
      d <- scenario_rows[scenario_rows$estimand == estimand, , drop = FALSE]
      label <- paste(s$id, estimand, sep = "/")
      if (nrow(d) != n_sim || anyNA(d$rep) || !setequal(d$rep, seq_len(n_sim)) || anyDuplicated(d$rep)) {
        stop("Incomplete or duplicate coverage repetitions: ", label, call. = FALSE)
      }
      n <- sum(is.finite(d$estimate))
      if (n < 2L) stop("Cannot summarize ", label, ": fewer than two finite estimates; inspect replicate diagnoses.", call. = FALSE)
      append(s, estimand, sim_performance(d$estimate, truth[[estimand]]), n)
      if (estimand %in% boot_interval_estimands) {
        ok <- is.finite(d$lower) & is.finite(d$upper)
        if (any(d$lower[ok] > d$upper[ok])) stop("Reversed coverage interval: ", label, call. = FALSE)
        widths <- boot_mean_mcse(d$upper[ok] - d$lower[ok], paste0(label, "/interval"))
        n <- sum(ok)
        p <- mean(d$lower[ok] <= d$true[ok] & d$true[ok] <= d$upper[ok])
        append(s, estimand, data.frame(measure = c("coverage", "width"),
          value = c(p, widths[["value"]]), mcse = c(sqrt(p * (1 - p) / n), widths[["mcse"]])), n)
      }
    }
    per_rep <- unique(scenario_rows[c("rep", "boot_nsim", "boot_level", "n_singular", "n_failed")])
    if (nrow(per_rep) != n_sim || anyDuplicated(per_rep$rep)) {
      stop("Inconsistent bootstrap settings across estimands: ", s$id, call. = FALSE)
    }
    ok <- is.finite(per_rep$boot_nsim)
    for (kind in c("singular", "failed")) {
      shares <- per_rep[[paste0("n_", kind)]][ok] / per_rep$boot_nsim[ok]
      if (any(!is.finite(shares) | shares < 0 | shares > 1)) {
        stop("Invalid bootstrap share: ", s$id, "/", kind, call. = FALSE)
      }
      measure <- paste0(kind, "_share")
      m <- boot_mean_mcse(shares, paste(s$id, measure, sep = "/"))
      append(s, "bootstrap", data.frame(measure = measure, value = m[["value"]], mcse = m[["mcse"]]), length(shares))
    }
  }
  result <- do.call(rbind, result)
  result[order(result$scenario, result$estimand, result$measure), , drop = FALSE]
}

boot_parse <- function(args, parameters = boot_parameters()) {
  if (!length(args) || length(args) %% 2L) stop("Use --n-sim <n> --out <directory> [--scenarios <ID,ID,...>].", call. = FALSE)
  keys <- args[seq.int(1L, length(args), 2L)]
  values <- args[seq.int(2L, length(args), 2L)]
  if (anyDuplicated(keys) || any(!keys %in% c("--n-sim", "--out", "--scenarios")) ||
      !all(c("--n-sim", "--out") %in% keys) || any(!nzchar(values))) {
    stop("Unknown, repeated or missing coverage option.", call. = FALSE)
  }
  opts <- stats::setNames(as.list(values), keys)
  n <- suppressWarnings(as.numeric(opts[["--n-sim"]]))
  if (!is.finite(n) || n < 2 || n != floor(n)) stop("--n-sim must be an integer of at least two.", call. = FALSE)
  scenarios <- boot_scenarios(parameters)
  if (!is.null(opts[["--scenarios"]])) {
    requested <- opts[["--scenarios"]]
    ids <- strsplit(requested, ",", fixed = TRUE)[[1L]]
    if (startsWith(requested, ",") || endsWith(requested, ",") || anyDuplicated(ids) || any(!ids %in% names(scenarios))) {
      stop("Unknown, empty or repeated coverage scenario ID.", call. = FALSE)
    }
    scenarios <- scenarios[ids]
  }
  for (s in scenarios) boot_seeds(s, n)
  list(n_sim = as.integer(n), out = opts[["--out"]], scenarios = scenarios)
}

boot_implementation <- function() {
  scope <- environment(boot_implementation)
  helpers <- sort(ls(scope, pattern = "^boot_"))
  helpers <- helpers[vapply(helpers, function(name) is.function(get(name, scope, inherits = FALSE)), logical(1))]
  numeric <- sort(ls(asNamespace("llmsa"), pattern = "^msa_numeric_"))
  code <- c(sim_implementation(),
    vapply(c("msa_boot", numeric), function(name) {
      paste(deparse(get(name, asNamespace("llmsa")), width.cutoff = 500L), collapse = "\n")
    }, character(1)),
    vapply(helpers, function(name) paste(deparse(get(name, scope), width.cutoff = 500L), collapse = "\n"), character(1)),
    paste(deparse(boot_interval_estimands), collapse = "\n"),
    paste(deparse(boot_parameters(), width.cutoff = 500L), collapse = "\n"))
  digest::digest(paste(code, collapse = "\n"), algo = "sha256", serialize = FALSE)
}

boot_metadata <- function(scenarios, n_sim) {
  packages <- c("llmsa", "lme4", "ordinal", "Matrix", "parallel")
  c("format: llmsa-class-b-v1", "study: boot_coverage", paste0("n_sim: ", n_sim),
    paste0("implementation: ", boot_implementation()), paste0("R_version: ", getRversion()),
    paste0("package_", packages, ": ", vapply(packages, function(p) as.character(utils::packageVersion(p)), character(1))),
    "RNG: Mersenne-Twister; normal.kind=Inversion; sample.kind=Rejection",
    "seed_rule: data_seed = 20261102 + 2 * (j - 1) + 14 * (rep - 1); boot_seed = data_seed + 1; permanent j in S-boot-j",
    paste0("scenarios: ", paste(names(scenarios), collapse = ",")),
    paste0("start_seeds: ", paste(vapply(scenarios, function(s) paste0(s$id, "=", boot_seeds(s, 1L)$data), character(1)), collapse = ",")),
    paste0("boot_start_seeds: ", paste(vapply(scenarios, function(s) paste0(s$id, "=", boot_seeds(s, 1L)$boot), character(1)), collapse = ",")))
}

boot_write <- function(paths, replicates, scenarios, n_sim, session) {
  # A failed aggregation must leave the genuine estimates and diagnoses.
  utils::write.csv(replicates, paths[["replicates"]], row.names = FALSE)
  writeLines(session, paths[["session"]])
  # Summarize the published precision, including closed interval endpoints.
  result <- tryCatch(boot_summarize(sim_read_csv(paths[["replicates"]]), scenarios, n_sim), error = function(e) {
    cat("\nAggregation failure: ", conditionMessage(e), "\n", file = paths[["session"]], append = TRUE, sep = "")
    stop(conditionMessage(e), call. = FALSE)
  })
  stage <- tempfile(".coverage-results-", tmpdir = dirname(paths[["results"]]))
  on.exit(unlink(stage), add = TRUE)
  utils::write.csv(result, stage, row.names = FALSE)
  if (!file.rename(stage, paths[["results"]])) stop("Cannot publish coverage results: ", paths[["results"]], call. = FALSE)
  invisible(result)
}

boot_workers <- function(cap, tasks) {
  workers <- suppressWarnings(as.numeric(Sys.getenv("LLMSA_SIM_WORKERS", as.character(cap))))
  if (length(workers) != 1L || !is.finite(workers) || workers < 1 || workers != floor(workers) || workers > cap) {
    stop("LLMSA_SIM_WORKERS must be an integer between one and the ANK-TOL.sim_runtime core limit.", call. = FALSE)
  }
  if (.Platform$OS.type == "windows") workers <- 1L
  as.integer(min(workers, tasks))
}

boot_main <- function(args) {
  parameters <- boot_parameters()
  opts <- boot_parse(args, parameters)
  workers <- boot_workers(parameters$cores, length(opts$scenarios) * opts$n_sim)
  paths <- sim_prepare_output(opts$out, "boot_coverage")
  # Load before fork: versions and one-time namespace messages are session-wide.
  for (package in c("lme4", "ordinal", "parallel")) loadNamespace(package)
  tasks <- unlist(lapply(opts$scenarios, function(s) lapply(seq_len(opts$n_sim), function(r) list(s = s, rep = r))), recursive = FALSE)
  task <- function(x) boot_replicate(x$s, x$rep)
  start <- proc.time()[["elapsed"]]
  computed <- if (workers == 1L) lapply(tasks, task) else {
    parallel::mclapply(tasks, task, mc.cores = workers, mc.set.seed = FALSE)
  }
  if (any(!vapply(computed, is.data.frame, logical(1)))) stop("Coverage worker failed before returning its diagnoses.", call. = FALSE)
  reps <- do.call(rbind, computed)
  reps <- reps[order(reps$scenario, reps$rep, reps$estimand), , drop = FALSE]
  elapsed <- proc.time()[["elapsed"]] - start
  diagnoses <- unique(reps[c("scenario", "rep", "data_seed", "boot_seed", "error_stage", "error", "warnings", "messages")])
  diagnostic <- function(x) if (is.na(x)) "(none)" else x
  lines <- vapply(seq_len(nrow(diagnoses)), function(i) {
    d <- diagnoses[i, ]
    paste0(d$scenario, " rep=", d$rep, " data_seed=", d$data_seed, " boot_seed=", d$boot_seed,
      " error_stage=[", diagnostic(d$error_stage), "] error=[", diagnostic(d$error),
      "] warnings=[", diagnostic(d$warnings), "] messages=[", diagnostic(d$messages), "]")
  }, character(1))
  session <- c(boot_metadata(opts$scenarios, opts$n_sim),
    paste0("command: Rscript boot_coverage.R ", paste(vapply(args, shQuote, character(1)), collapse = " ")),
    paste0("workers: ", workers), sprintf("elapsed_seconds: %.6f", elapsed),
    "", "Per-repetition diagnostics:", lines, "", utils::capture.output(utils::sessionInfo()))
  result <- boot_write(paths, reps, opts$scenarios, opts$n_sim, session)
  cat(sprintf("boot_coverage: %d scenarios x %d repetitions; %d result rows; elapsed %.3f s; workers %d\n",
    length(opts$scenarios), opts$n_sim, nrow(result), elapsed, workers))
  invisible(paths)
}

boot_merge <- function(directories, out) {
  if (!length(directories) || anyDuplicated(normalizePath(directories, mustWork = TRUE))) {
    stop("Provide distinct directories of successful coverage runs.", call. = FALSE)
  }
  parameters <- boot_parameters()
  scenarios <- boot_scenarios(parameters)
  parts <- lapply(directories, function(directory) {
    paths <- sim_paths(directory, "boot_coverage")
    if (!all(file.exists(paths))) stop("Incomplete coverage triplet: ", directory, call. = FALSE)
    session <- readLines(paths[["session"]], warn = FALSE)
    fields <- sim_session_fields(session)
    if (any(startsWith(session, "Aggregation failure:"))) stop("Cannot merge failed coverage run: ", directory, call. = FALSE)
    n <- suppressWarnings(as.numeric(fields[["n_sim"]]))
    ids <- strsplit(fields[["scenarios"]], ",", fixed = TRUE)[[1L]]
    if (!is.finite(n) || n < 2 || n != floor(n) || !length(ids) ||
        anyDuplicated(ids) || any(!ids %in% names(scenarios))) {
      stop("Invalid coverage scenario or repetition metadata: ", directory, call. = FALSE)
    }
    selected <- scenarios[ids]
    if (!identical(fields, sim_session_fields(boot_metadata(selected, n)))) {
      stop("Coverage implementation, versions, seeds or RNG differ: ", directory, call. = FALSE)
    }
    reps <- sim_read_csv(paths[["replicates"]])
    result <- sim_read_csv(paths[["results"]])
    required <- c("scenario", "rep", "estimand", "estimate", "true", "lower", "upper", "items", "prompts",
      "models", "blocks", "observations", "boot_nsim", "boot_level", "n_singular", "n_failed", "data_seed", "boot_seed",
      "converged", "singular", "error_stage", "error", "warnings", "messages")
    if (!setequal(names(reps), required) || anyDuplicated(names(reps)) || !nrow(reps) ||
        !setequal(unique(reps$scenario), ids) || anyNA(reps[c("scenario", "rep", "estimand", "true", "data_seed", "boot_seed")])) {
      stop("Invalid coverage replicate schema or scenarios: ", directory, call. = FALSE)
    }
    for (s in selected) {
      d <- reps[reps$scenario == s$id, , drop = FALSE]
      seeds <- boot_seeds(s, d$rep)
      truth <- boot_truth(s)[d$estimand]
      if (any(!is.finite(d$true)) || anyNA(truth) || any(abs(d$true - truth) > parameters$arithmetic) ||
          any(d$data_seed != seeds$data | d$boot_seed != seeds$boot)) {
        stop("Inconsistent coverage replicate truths or seeds: ", s$id, call. = FALSE)
      }
      counts <- c(items = s$items, prompts = s$prompts, models = s$models, blocks = s$blocks,
        observations = s$items * s$prompts * s$models * s$blocks * s$reps)
      for (name in names(counts)) {
        x <- d[[name]]
        if (any(!is.na(x) & (!is.finite(x) | x != counts[[name]])) || any(is.na(x) & !is.na(d$estimate))) {
          stop("Inconsistent coverage design count: ", s$id, "/", name, call. = FALSE)
        }
      }
    }
    expected <- boot_summarize(reps, selected, as.integer(n))
    if (!setequal(names(result), names(expected)) || anyDuplicated(names(result)) ||
        nrow(result) != nrow(expected) || anyNA(result)) stop("Invalid coverage result schema: ", directory, call. = FALSE)
    result <- result[order(result$scenario, result$estimand, result$measure), names(expected), drop = FALSE]
    for (name in names(expected)) {
      same <- if (is.numeric(expected[[name]])) {
        is.numeric(result[[name]]) && all(is.finite(result[[name]]) & abs(result[[name]] - expected[[name]]) <= parameters$arithmetic)
      } else identical(as.character(result[[name]]), as.character(expected[[name]]))
      if (!same) stop("Coverage result differs from replicates: ", directory, "/", name, call. = FALSE)
    }
    list(reps = reps, result = result, fields = fields, paths = paths, session = session)
  })
  ids <- unlist(lapply(parts, function(p) unique(p$reps$scenario)), use.names = FALSE)
  ns <- vapply(parts, function(p) p$fields[["n_sim"]], character(1))
  if (anyDuplicated(ids) || !setequal(ids, names(scenarios)) || length(unique(ns)) != 1L) {
    stop("Coverage runs must be disjoint, cover all scenarios and have the same n_sim.", call. = FALSE)
  }
  reps <- do.call(rbind, lapply(parts, `[[`, "reps"))
  result <- do.call(rbind, lapply(parts, `[[`, "result"))
  provenance <- unlist(lapply(seq_along(parts), function(i) {
    p <- parts[[i]]
    hashes <- vapply(p$paths, function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE), character(1))
    c(paste0("input: ", normalizePath(directories[i], mustWork = TRUE)),
      paste0("input_sha256: ", names(hashes), " ", hashes), paste0("original_session: ", p$session))
  }), use.names = FALSE)
  paths <- sim_prepare_output(out, "boot_coverage")
  utils::write.csv(reps[order(reps$scenario, reps$rep, reps$estimand), ], paths[["replicates"]], row.names = FALSE)
  writeLines(c(boot_metadata(scenarios, as.integer(ns[1L])),
    "merge: complete disjoint scenarios; estimates and result cells retained",
    "runtime: see original_session entries; no combined run time is asserted", provenance,
    "", utils::capture.output(utils::sessionInfo())), paths[["session"]])
  utils::write.csv(result[order(result$scenario, result$estimand, result$measure), ], paths[["results"]], row.names = FALSE)
  cat("Merged ", length(parts), " disjoint coverage triplets; no fits recomputed\n", sep = "")
  invisible(paths)
}
