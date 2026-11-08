# Offline reader and arithmetic checks only: no simulation or model fitting.
# The generator is separately installed as validation/sim/planning_rule.R.

planning_anchor_locations <- c("ANK-89" = "planning", "ANK-06" = "latent",
                               "ANK-16" = "numeric", "ANK-TOL" = "numeric")
planning_replicate_columns <- c("plan", "scenario", "sim", "estimate", "singular", "prompt")
planning_summary_columns <- c("plan", "scenario", "n_items", "n_prompts", "n_models", "n_reps", "n_blocks",
  "seed", "n_sim", "grr_true", "mean", "q2.5", "median", "q97.5", "rmse", "pct_singular",
  "pct_misclassified", "bias", "empse", "mcse_bias", "mcse_empse", "nu", "cv_rule", "cv_empirical",
  "boundary_share", "mcse_boundary", "mcse_cv", "mcse_cv_method", "mcse_cv_note")
planning_cv_method <- "Delta method: first two empirical raw moments"

planning_get <- function(x, ...) {
  keys <- c(...)
  for (key in keys) {
    x <- x[[key]]
    if (is.null(x)) stop("Missing planning validation field: ", paste(keys, collapse = "$"), call. = FALSE)
  }
  x
}

planning_json <- function(path) {
  if (!file.exists(path)) stop("Planning validation input is missing: ", path, call. = FALSE)
  tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE),
    error = function(e) stop("Cannot read planning JSON: ", path, ": ", conditionMessage(e), call. = FALSE))
}

planning_hash <- function(path, expected) {
  if (!file.exists(path)) stop("Planning validation input is missing: ", path, call. = FALSE)
  if (!is.character(expected) || length(expected) != 1L || is.na(expected) ||
      !grepl("^[0-9a-f]{64}$", expected)) stop("Invalid planning SHA-256: ", path, call. = FALSE)
  actual <- digest::digest(file = path, algo = "sha256", serialize = FALSE)
  if (!identical(actual, expected)) stop("Planning SHA-256 mismatch: ", path, call. = FALSE)
  invisible(actual)
}

planning_inputs <- function(resource_dir = system.file("validation", "planning", package = "llmsa", mustWork = TRUE),
                            repo_root = Sys.getenv("REPO_ROOT", ""),
                            shared_dir = system.file("validation", package = "llmsa", mustWork = TRUE)) {
  manifest <- planning_json(file.path(resource_dir, "SOURCES.json"))
  if (!identical(manifest$schema, 1L) ||
      !identical(manifest$preparation, "data-raw/make_validation_planning.R")) {
    stop("Invalid planning manifest schema or preparation script.", call. = FALSE)
  }
  entries <- planning_get(manifest, "anchors")
  if (anyDuplicated(names(entries)) || !setequal(names(entries), names(planning_anchor_locations))) {
    stop("Planning anchor manifest is incomplete or duplicated.", call. = FALSE)
  }
  files <- list.files(file.path(resource_dir, "anchors"), recursive = TRUE, all.files = TRUE, no.. = TRUE)
  if (!identical(files, "ANK-89.json")) stop("Planning anchor directory differs from the manifest.", call. = FALSE)
  if (nzchar(repo_root) && (!file.exists(file.path(repo_root, "DESCRIPTION")) ||
      !dir.exists(file.path(repo_root, "reference", "anchors")))) {
    stop("Invalid REPO_ROOT for planning validation.", call. = FALSE)
  }
  anchors <- stats::setNames(lapply(names(planning_anchor_locations), function(id) {
    entry <- entries[[id]]
    name <- paste0(id, ".json")
    location <- planning_anchor_locations[[id]]
    original <- file.path("reference", "anchors", name)
    copied <- file.path("inst", "validation", location, "anchors", name)
    if (!identical(entry$original, original) || !identical(entry$copied, copied) ||
        !identical(entry$original_sha256, entry$copied_sha256)) {
      stop("Invalid planning anchor provenance: ", id, call. = FALSE)
    }
    directory <- if (location == "planning") resource_dir else file.path(shared_dir, location)
    path <- file.path(directory, "anchors", name)
    planning_hash(path, entry$copied_sha256)
    if (nzchar(repo_root)) planning_hash(file.path(repo_root, original), entry$original_sha256)
    a <- planning_json(path)
    if (!identical(a$id, id)) stop("Incorrect planning anchor ID: ", id, call. = FALSE)
    for (key in c("value", "unit", "tolerance", "source_url", "quote", "retrieved")) planning_get(a, key)
    a
  }), names(planning_anchor_locations))
  numeric_value <- function(id, ...) {
    x <- planning_get(anchors, id, "value", ...)
    if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 0) {
      stop("Invalid numeric planning anchor: ", id, call. = FALSE)
    }
    x
  }
  n_min <- numeric_value("ANK-06", "n_sim_min")
  numerator <- numeric_value("ANK-89", "numerator")
  offset <- numeric_value("ANK-89", "nu_offset")
  tolerance <- numeric_value("ANK-TOL", "arithmetic", "abs_tol")
  lower <- numeric_value("ANK-16", "study_var", "acceptable_below")
  upper <- numeric_value("ANK-16", "study_var", "unacceptable_above")
  if (n_min < 2 || n_min != floor(n_min) || numerator <= 0 || lower >= upper) {
    stop("Invalid planning anchor constraints.", call. = FALSE)
  }
  list(manifest = manifest, anchors = anchors, resource_dir = resource_dir,
       mode = if (nzchar(repo_root)) "full" else "public", n_min = n_min,
       numerator = numerator, offset = offset, tolerance = tolerance, thresholds = c(lower, upper))
}

planning_csv <- function(path, types = NA, columns = NULL) {
  if (!file.exists(path)) stop("Planning validation input is missing: ", path, call. = FALSE)
  tryCatch({
    if (!is.null(columns)) {
      header <- utils::read.csv(path, nrows = 0L, check.names = FALSE)
      if (!identical(names(header), columns)) stop("Invalid planning result schema.", call. = FALSE)
    }
    utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, colClasses = types)
  },
    error = function(e) stop("Cannot read planning CSV: ", path, ": ", conditionMessage(e), call. = FALSE))
}

# Delta method for sqrt(n/(n-1)) * sqrt(m2 - m1^2) / m1.
# This supplementary MCSE is an approximation, not an acceptance threshold.
planning_prompt_summary <- function(y) {
  if (!is.numeric(y) || length(y) < 2L || any(!is.finite(y)) || any(y < 0)) {
    stop("Planning prompt estimates must be finite, nonnegative and have at least two repetitions.", call. = FALSE)
  }
  n <- length(y)
  m1 <- mean(y)
  s <- stats::sd(y)
  if (m1 <= 0 || !is.finite(s / m1)) stop("The empirical prompt CV is undefined.", call. = FALSE)
  p <- mean(y == 0)
  mcse <- NA_real_
  note <- "undefined: positive mean, positive variance and finite moments are required"
  m2 <- mean(y^2)
  variance <- m2 - m1^2
  if (is.finite(variance) && variance > 0 && all(is.finite(y^2))) {
    correction <- sqrt(n / (n - 1))
    gradient <- correction * c(-m2 / (m1^2 * sqrt(variance)), 1 / (2 * m1 * sqrt(variance)))
    covariance <- stats::cov(cbind(y, y^2)) / n
    delta_variance <- as.numeric(crossprod(gradient, covariance %*% gradient))
    if (is.finite(delta_variance) && delta_variance >= 0) {
      mcse <- sqrt(delta_variance)
      note <- "approximate; all prompt estimates, including zeros, retained"
    }
  }
  list(cv_empirical = s / m1, boundary_share = p, mcse_boundary = sqrt(p * (1 - p) / n),
       mcse_cv = mcse, mcse_cv_method = planning_cv_method, mcse_cv_note = note)
}

planning_summarize <- function(replicates, designs, vc, inputs) {
  variance <- unlist(vc, use.names = TRUE)
  item <- if ("item" %in% names(variance)) variance[["item"]] else 0
  gauge <- sum(variance[names(variance) != "item"])
  truth <- 100 * sqrt(gauge / (gauge + item))
  classify <- function(x) ifelse(x < inputs$thresholds[1L], "acceptable",
                                ifelse(x > inputs$thresholds[2L], "unacceptable", "marginal"))
  result <- lapply(seq_len(nrow(designs)), function(i) {
    d <- designs[i, , drop = FALSE]
    r <- replicates[replicates$plan == d$plan, , drop = FALSE]
    n <- nrow(r)
    if (n < 2L) stop("Planning summary requires at least two repetitions: ", d$plan, call. = FALSE)
    x <- r$estimate
    average <- mean(x)
    empse <- stats::sd(x)
    # Definition 7 at the 2.5th, 50th and 97.5th percentiles.
    q <- stats::quantile(x, c(1, 20, 39) / 40, type = 7, names = FALSE)
    prompt <- planning_prompt_summary(r$prompt)
    nu <- d$n_prompts - inputs$offset
    data.frame(d, n_sim = n, grr_true = truth, mean = average, q2.5 = q[1L], median = q[2L], q97.5 = q[3L],
      rmse = sqrt(mean((x - truth)^2)), pct_singular = 100 * mean(r$singular),
      pct_misclassified = 100 * mean(classify(x) != classify(truth)), bias = average - truth, empse = empse,
      mcse_bias = empse / sqrt(n), mcse_empse = empse / sqrt(2 * (n - 1)),
      nu = nu, cv_rule = sqrt(inputs$numerator / nu), prompt, stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, result)
  rownames(out) <- NULL
  out[, planning_summary_columns]
}

planning_designs <- function(study, inputs) {
  rows <- planning_get(study, "designs")
  columns <- c("plan", "scenario", "n_items", "n_prompts", "n_models", "n_reps", "n_blocks", "seed")
  if (!is.list(rows) || !length(rows) ||
      any(!vapply(rows, function(r) is.list(r) && identical(names(r), columns) && all(lengths(r) == 1L), logical(1)))) {
    stop("Invalid planning design schema.", call. = FALSE)
  }
  designs <- do.call(rbind, lapply(rows, as.data.frame, stringsAsFactors = FALSE))
  if (!identical(as.character(designs$plan), paste0("S-plan-", seq_len(4L))) ||
      !identical(as.integer(designs$scenario), seq_len(nrow(designs)))) {
    stop("Planning design keys are incomplete or duplicated.", call. = FALSE)
  }
  counts <- designs[, setdiff(columns, "plan"), drop = FALSE]
  if (!all(vapply(counts, is.numeric, logical(1))) || anyNA(counts) ||
      any(!is.finite(as.matrix(counts))) || any(as.matrix(counts) != floor(as.matrix(counts))) ||
      any(as.matrix(counts) < 1) || any(designs$n_prompts <= inputs$offset)) {
    stop("Invalid planning design sizes or seeds.", call. = FALSE)
  }
  n <- planning_get(study, "n_sim")
  if (!is.numeric(n) || length(n) != 1L || !is.finite(n) || n < inputs$n_min || n != floor(n)) {
    stop("Planning repetition count is below ANK-06 or invalid.", call. = FALSE)
  }
  vc <- planning_get(study, "vc")
  names_vc <- c("item", "prompt", "model", "block", "item_prompt", "item_model", "prompt_model", "residual")
  if (!is.list(vc) || !setequal(names(vc), names_vc) || anyDuplicated(names(vc)) ||
      any(!vapply(vc, function(x) is.numeric(x) && length(x) == 1L && is.finite(x) && x >= 0, logical(1))) ||
      sum(unlist(vc)) <= 0) stop("Invalid planning variance components.", call. = FALSE)
  designs
}

planning_read_results <- function(resource_dir = system.file("validation", "planning", package = "llmsa", mustWork = TRUE),
                                  repo_root = Sys.getenv("REPO_ROOT", ""),
                                  shared_dir = system.file("validation", package = "llmsa", mustWork = TRUE)) {
  inputs <- planning_inputs(resource_dir, repo_root, shared_dir)
  manifest <- inputs$manifest
  if (!identical(manifest$generator, "inst/validation/sim/planning_rule.R")) {
    stop("Missing or invalid planning result generator.", call. = FALSE)
  }
  files <- planning_get(manifest, "results")
  expected_files <- c("summary.csv", "replicates.csv.gz", "session.txt")
  if (anyDuplicated(names(files)) || !setequal(names(files), expected_files)) {
    stop("Planning result manifest is incomplete or duplicated.", call. = FALSE)
  }
  for (name in expected_files) planning_hash(file.path(resource_dir, name), planning_get(files, name, "sha256"))
  study <- planning_get(manifest, "study")
  designs <- planning_designs(study, inputs)
  summary_types <- ifelse(planning_summary_columns %in% c("plan", "mcse_cv_method", "mcse_cv_note"),
                          "character", "numeric")
  summary <- planning_csv(file.path(resource_dir, "summary.csv"), summary_types, planning_summary_columns)
  reps <- planning_csv(file.path(resource_dir, "replicates.csv.gz"),
                        c("character", "integer", "integer", "numeric", "logical", "numeric"), planning_replicate_columns)
  if (!identical(names(summary), planning_summary_columns) ||
      !identical(names(reps), planning_replicate_columns)) stop("Invalid planning result schema.", call. = FALSE)
  if (!is.character(summary$plan) || anyNA(summary$plan) || anyDuplicated(summary$plan) ||
      !setequal(summary$plan, designs$plan) || !is.character(reps$plan) || anyNA(reps$plan) ||
      !setequal(reps$plan, designs$plan)) stop("Planning result keys are incomplete or duplicated.", call. = FALSE)
  numeric_columns <- setdiff(planning_summary_columns, c("plan", "mcse_cv_method", "mcse_cv_note"))
  if (!all(vapply(summary[numeric_columns], is.numeric, logical(1))) ||
      any(!is.finite(as.matrix(summary[setdiff(numeric_columns, "mcse_cv")])))) {
    stop("Planning summary contains non-finite or nonnumeric values.", call. = FALSE)
  }
  if (!all(vapply(reps[c("scenario", "sim", "estimate", "prompt")], is.numeric, logical(1))) ||
      any(!is.finite(as.matrix(reps[c("scenario", "sim", "estimate", "prompt")]))) ||
      !is.logical(reps$singular) || anyNA(reps$singular) || any(reps$prompt < 0) ||
      any(reps$estimate < 0 | reps$estimate > 100)) {
    stop("Planning replicates contain invalid estimates or flags.", call. = FALSE)
  }
  for (i in seq_len(nrow(designs))) {
    r <- reps[reps$plan == designs$plan[i], , drop = FALSE]
    if (nrow(r) != study$n_sim || !all(r$scenario == designs$scenario[i]) ||
        !identical(sort(r$sim), seq_len(study$n_sim))) {
      stop("Planning replicate keys are incomplete or duplicated: ", designs$plan[i], call. = FALSE)
    }
  }
  recalculated <- planning_summarize(reps, designs, study$vc, inputs)
  summary <- summary[match(designs$plan, summary$plan), , drop = FALSE]
  for (column in numeric_columns) {
    a <- summary[[column]]
    b <- recalculated[[column]]
    if (!identical(is.na(a), is.na(b)) || any(is.infinite(a)) ||
        any(abs(a[!is.na(a)] - b[!is.na(b)]) > inputs$tolerance)) {
      stop("Planning summary differs from its replicates: ", column, call. = FALSE)
    }
  }
  for (column in c("mcse_cv_method", "mcse_cv_note")) {
    if (!identical(summary[[column]], recalculated[[column]])) {
      stop("Planning CV MCSE method or explanation differs: ", column, call. = FALSE)
    }
  }
  table <- data.frame(plan = summary$plan, items = summary$n_items, prompts = summary$n_prompts,
    nu = summary$nu, cv_rule = summary$cv_rule, cv_empirical = summary$cv_empirical,
    boundary_share = summary$boundary_share, mcse_boundary = summary$mcse_boundary, n_sim = summary$n_sim)
  list(table = table, cv_mcse = summary[, c("plan", "cv_empirical", "mcse_cv", "mcse_cv_method", "mcse_cv_note")],
       summary = summary, replicates = reps, manifest = manifest, anchors = inputs$anchors,
       mode = inputs$mode, session = readLines(file.path(resource_dir, "session.txt"), warn = FALSE))
}

planning_display <- function(table, digits = 4L) {
  for (column in intersect(c("cv_rule", "cv_empirical", "boundary_share", "mcse_boundary", "mcse_cv"), names(table))) {
    table[[column]] <- ifelse(is.na(table[[column]]), "undefined",
                             formatC(table[[column]], format = "f", digits = digits, decimal.mark = "."))
  }
  table
}
