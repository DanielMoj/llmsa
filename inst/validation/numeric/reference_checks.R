# Executable documentation calculations. Product functions always come from
# the loaded llmsa namespace, including when that namespace is mutated.

validation_anchor_ids <- c("ANK-10", "ANK-13", "ANK-14", "ANK-16", "ANK-TOL")

validation_get <- function(x, ...) {
  keys <- c(...)
  for (key in keys) {
    x <- x[[key]]
    if (is.null(x)) stop("Missing validation field: ", paste(keys, collapse = "$"), call. = FALSE)
  }
  x
}

validation_json <- function(path) {
  if (!file.exists(path)) stop("Validation input is missing: ", path, call. = FALSE)
  tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE),
           error = function(e) stop("Cannot read validation JSON: ", path, ": ", conditionMessage(e), call. = FALSE))
}

validation_hash <- function(path, expected) {
  if (!file.exists(path)) stop("Validation input is missing: ", path, call. = FALSE)
  actual <- digest::digest(file = path, algo = "sha256", serialize = FALSE)
  if (!identical(actual, expected)) stop("Validation SHA-256 mismatch: ", path, call. = FALSE)
  invisible(actual)
}

validation_find_repo <- function(start = getwd(), repo_root = Sys.getenv("REPO_ROOT", "")) {
  if (nzchar(repo_root)) {
    if (!dir.exists(repo_root) || !file.exists(file.path(repo_root, "DESCRIPTION"))) {
      stop("Invalid REPO_ROOT for numeric validation: ", repo_root, call. = FALSE)
    }
    return(normalizePath(repo_root, mustWork = TRUE))
  }
  current <- normalizePath(start, mustWork = TRUE)
  repeat {
    if (file.exists(file.path(current, "DESCRIPTION")) &&
        (file.exists(file.path(current, "AGENTS.md")) || file.exists(file.path(current, "contracts", "PROTOCOLS.md")))) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) return(NULL)
    current <- parent
  }
}

validation_verify_resources <- function(resource_dir, repo_root = NULL,
                                       data_dir = system.file("extdata", "nist-strd-anova_2026-10-22",
                                                              package = "llmsa", mustWork = TRUE)) {
  manifest <- validation_json(file.path(resource_dir, "SOURCES.json"))
  entries <- validation_get(manifest, "anchors")
  if (anyDuplicated(names(entries)) || !setequal(names(entries), validation_anchor_ids)) {
    stop("Numeric anchor manifest is incomplete or contains duplicate entries.", call. = FALSE)
  }
  for (id in validation_anchor_ids) {
    entry <- entries[[id]]
    original <- file.path("reference", "anchors", paste0(id, ".json"))
    copied <- file.path("inst", "validation", "numeric", "anchors", paste0(id, ".json"))
    if (!identical(entry[["original"]], original) || !identical(entry[["copied"]], copied) ||
        !identical(entry[["original_sha256"]], entry[["copied_sha256"]])) {
      stop("Invalid numeric anchor provenance: ", id, call. = FALSE)
    }
    path <- file.path(resource_dir, "anchors", paste0(id, ".json"))
    validation_hash(path, validation_get(entry, "copied_sha256"))
    value <- validation_json(path)
    if (!identical(value[["id"]], id)) stop("Incorrect numeric anchor ID: ", id, call. = FALSE)
    for (key in c("value", "unit", "tolerance", "source_url", "quote", "retrieved")) validation_get(value, key)
    if (!is.null(repo_root)) validation_hash(file.path(repo_root, original), entry[["original_sha256"]])
  }
  anchor_files <- list.files(file.path(resource_dir, "anchors"), all.files = TRUE,
                            recursive = TRUE, include.dirs = TRUE, no.. = TRUE)
  if (!setequal(anchor_files, paste0(names(entries), ".json"))) {
    stop("Numeric anchor directory differs from the manifest.", call. = FALSE)
  }
  datasets <- validation_get(manifest, "datasets")
  nist <- validation_get(validation_json(file.path(resource_dir, "anchors", "ANK-14.json")), "value", "datasets")
  if (anyDuplicated(names(datasets)) || !setequal(names(datasets), names(nist))) {
    stop("Numeric dataset manifest differs from ANK-14.", call. = FALSE)
  }
  for (name in names(nist)) {
    entry <- datasets[[name]]
    copied <- validation_get(entry, "copied")
    allowed <- file.path("inst", "extdata", "nist-strd-anova_2026-10-22", paste0(name, c(".csv", ".csv.gz")))
    if (!is.character(copied) || length(copied) != 1L || !copied %in% allowed ||
        !identical(entry[["original_sha256"]], nist[[name]][["sha256"]])) {
      stop("Invalid numeric dataset provenance: ", name, call. = FALSE)
    }
    validation_hash(file.path(data_dir, basename(copied)), validation_get(entry, "copied_sha256"))
  }
  manifest
}

validation_context <- function(repo_root = Sys.getenv("REPO_ROOT", ""),
                               resource_dir = system.file("validation", "numeric", package = "llmsa", mustWork = TRUE),
                               data_dir = system.file("extdata", "nist-strd-anova_2026-10-22", package = "llmsa", mustWork = TRUE)) {
  if (nzchar(repo_root)) {
    root <- validation_find_repo(repo_root = repo_root)
    anchors <- file.path(root, "reference", "anchors")
    if (!dir.exists(anchors)) stop("Original anchor directory is missing: ", anchors, call. = FALSE)
    list(mode = "full", root = root, anchors = anchors,
         nist = file.path(dirname(root), "quellen", "daten", "nist-strd-anova_2026-10-22"),
         resource_dir = resource_dir)
  } else {
    manifest <- validation_verify_resources(resource_dir, data_dir = data_dir)
    list(mode = "public", root = NULL, anchors = file.path(resource_dir, "anchors"),
         nist = data_dir, resource_dir = resource_dir, manifest = manifest)
  }
}

validation_anchors <- function(context) {
  stats::setNames(lapply(validation_anchor_ids, function(id) {
    x <- validation_json(file.path(context$anchors, paste0(id, ".json")))
    if (!identical(x[["id"]], id)) stop("Incorrect validation anchor ID: ", id, call. = FALSE)
    for (key in c("value", "unit", "tolerance", "source_url", "quote", "retrieved")) validation_get(x, key)
    x
  }), validation_anchor_ids)
}

validation_tolerance <- function(anchors, entry, key) {
  value <- validation_get(anchors, "ANK-TOL", "value", entry, key)
  if (!is.numeric(value) || length(value) != 1L || !is.finite(value) || value < 0) {
    stop("Invalid validation tolerance: ", entry, "$", key, call. = FALSE)
  }
  value
}

validation_nist <- function(name, context, anchors) {
  meta <- validation_get(anchors, "ANK-14", "value", "datasets", name)
  if (identical(context$mode, "full")) {
    path <- file.path(context$nist, validation_get(meta, "file"))
    validation_hash(path, validation_get(meta, "sha256"))
    lines <- readLines(path, warn = FALSE)
    span <- as.integer(unlist(validation_get(meta, "data_lines")))
    if (length(span) != 2L || anyNA(span) || span[1] < 1 || span[2] > length(lines)) {
      stop("Invalid NIST data line range: ", name, call. = FALSE)
    }
    tokens <- strsplit(trimws(lines[seq.int(span[1], span[2])]), "[[:space:]]+")
    if (any(lengths(tokens) != 2L)) stop("Malformed NIST data row: ", name, call. = FALSE)
    trt <- vapply(tokens, `[[`, character(1), 1L)
    d <- data.frame(treatment = trt, rep = as.integer(stats::ave(seq_along(trt), trt, FUN = seq_along)),
                    value = as.numeric(vapply(tokens, `[[`, character(1), 2L)))
  } else {
    entry <- validation_get(context, "manifest", "datasets", name)
    if (!identical(entry[["original_sha256"]], meta[["sha256"]])) stop("NIST provenance differs from ANK-14: ", name)
    path <- file.path(context$nist, basename(validation_get(entry, "copied")))
    validation_hash(path, validation_get(entry, "copied_sha256"))
    d <- utils::read.csv(path, colClasses = c("character", "integer", "numeric"))
  }
  if (!identical(names(d), c("treatment", "rep", "value")) || anyNA(d) || any(!is.finite(d$value)) ||
      nrow(d) != validation_get(meta, "observations") ||
      length(unique(d$treatment)) != validation_get(meta, "treatments") ||
      any(table(d$treatment) != validation_get(meta, "replicates_per_cell")) ||
      !identical(d$rep, as.integer(stats::ave(seq_len(nrow(d)), d$treatment, FUN = seq_along)))) {
    stop("NIST table schema or design differs from ANK-14: ", name, call. = FALSE)
  }
  d
}

validation_aiag <- function(context, anchors) {
  if (!identical(context$mode, "full")) return(NULL)
  meta <- validation_get(anchors, "ANK-10", "value", "data_file")
  path <- file.path(context$root, validation_get(meta, "path"))
  validation_hash(path, validation_get(meta, "sha256"))
  d <- utils::read.csv(path, stringsAsFactors = FALSE)
  if (!identical(names(d), unlist(validation_get(meta, "columns"))) || nrow(d) != validation_get(meta, "rows") ||
      anyNA(d) || any(!is.finite(d$value))) stop("AIAG table schema differs from ANK-10.", call. = FALSE)
  d
}

validation_runs <- function(item, prompt = "P", model = "M", rep = 1L, value, block = 1L) {
  getExportedValue("llmsa", "as_msa_runs")(data.frame(item_id = as.character(item), prompt_id = as.character(prompt),
    model_id = as.character(model), rep = as.integer(rep), value = value, block = block))
}

validation_frame <- function(runs) {
  r <- runs[!is.na(runs$value), , drop = FALSE]
  data.frame(item = factor(r$item_id), prompt = factor(r$prompt_id), model = factor(r$model_id),
             block = factor(r$block), y = r$value)
}

validation_terms <- function(d, interactions) {
  main <- names(d)[vapply(d, is.factor, logical(1)) & vapply(d, function(x) length(unique(x)) > 1L, logical(1))]
  pairs <- if (interactions) c("item:prompt", "item:model", "prompt:model") else character()
  pairs <- pairs[vapply(strsplit(pairs, ":", fixed = TRUE), function(x) all(x %in% main), logical(1))]
  c(main, pairs)
}

# Independent fixed-effects ANOVA oracle for the balanced random model.
# Solve the EMS system using mean squares from stats, not product helpers.
validation_anova <- function(d, interactions) {
  labels <- validation_terms(d, interactions)
  terms <- strsplit(labels, ":", fixed = TRUE)
  sizes <- vapply(d[vapply(d, is.factor, logical(1))], nlevels, integer(1))
  counts <- table(d[names(sizes)[sizes > 1]])
  if (!length(counts) || any(counts != counts[1]) || counts[1] == 0) stop("ANOVA reference requires a balanced design.")
  aov <- stats::aov(stats::reformulate(labels, "y"), data = d)
  tab <- summary(aov)[[1]]
  ms <- stats::setNames(tab[["Mean Sq"]], trimws(rownames(tab)))
  coefficient <- outer(seq_along(terms), seq_along(terms), Vectorize(function(i, j) {
    if (all(terms[[i]] %in% terms[[j]])) nrow(d) / prod(sizes[terms[[j]]]) else 0
  }))
  estimates <- as.numeric(solve(coefficient, ms[labels] - ms[["Residuals"]]))
  c(stats::setNames(estimates, labels), Residual = ms[["Residuals"]])
}

validation_components <- function(fit) stats::setNames(fit$vc$variance, fit$vc$source)

validation_grr <- function(variance, anchors) {
  pv <- unname(variance[["item"]])
  ev <- unname(variance[["Residual"]])
  av <- sum(variance[!names(variance) %in% c("item", "Residual")])
  grr <- ev + av
  total <- pv + grr
  ndc <- validation_get(anchors, "ANK-16", "value", "ndc")
  c(grr_pct_study_var = 100 * sqrt(grr / total), grr_pct_contribution = 100 * grr / total,
    repeatability_pct_study_var = 100 * sqrt(ev / total), reproducibility_pct_study_var = 100 * sqrt(av / total),
    ndc = if (grr == 0) Inf else max(ndc[["minimum"]], floor(ndc[["constant"]] * sqrt(pv / grr))),
    icc_items = pv / total)
}

validation_format <- function(value) {
  if (is.numeric(value)) format(value, digits = 15, trim = TRUE) else as.character(value)
}

validation_row <- function(anchor, source, quantity, expected, observed, tolerance, passed = FALSE, result = NULL) {
  if (is.null(result)) result <- if (isTRUE(passed)) "PASS" else "FAIL"
  data.frame(Anchor = anchor, Source = source, Quantity = quantity, Expected = validation_format(expected),
              Observed = validation_format(observed), Tolerance = validation_format(tolerance), Result = result,
              stringsAsFactors = FALSE, check.names = FALSE)
}

validation_compare <- function(anchor, source, quantity, expected, observed, tolerance, squared = FALSE) {
  error <- if (squared) abs(observed^2 - expected^2) else abs(observed - expected)
  validation_row(anchor, source, quantity, expected, observed,
                  paste(validation_format(tolerance), if (squared) "on variance scale" else "absolute"),
                  is.finite(error) && error <= tolerance)
}

validation_lre <- function(observed, certified) {
  if (isTRUE(observed == certified)) Inf else -log10(abs(observed - certified) / abs(certified))
}

validation_lre_margin <- function(anchors) {
  entry <- validation_get(anchors, "ANK-TOL", "value", "nist_digits")
  rule <- regmatches(entry[["medium_difficulty_rule"]], regexec("LRE\\(stats::aov\\) - ([0-9]+)", entry[["medium_difficulty_rule"]]))[[1]]
  quote <- regmatches(entry[["quote"]], regexec("minus ([0-9]+)", entry[["quote"]]))[[1]]
  if (length(rule) != 2L || length(quote) != 2L || rule[2] != quote[2]) stop("Inconsistent NIST LRE margin in ANK-TOL.")
  as.numeric(rule[2])
}

# Only the aggregate GRR table is accepted here. Raw protected measurements
# never enter the presentation code, including in the full context.
validation_aiag_table <- function(anchors, grr = NULL) {
  pub <- validation_get(anchors, "ANK-10", "value")
  row_names <- c(EV = "Repeatability", AV = "Reproducibility", INT = "item:prompt", GRR = "Total gauge R&R",
                 PV = "Part-to-part (items)", TV = "Total variation")
  component_tol <- validation_tolerance(anchors, "reml_anova", "component_tol_fraction_of_total_variance")
  relative_tol <- validation_tolerance(anchors, "reml_anova", "derived_rel_tol")
  total <- pub[["variance"]][["GRR"]] + pub[["variance"]][["PV"]]
  rows <- list()
  for (kind in c("variance", "sd", "pct_study_var", "pct_contribution")) {
    for (key in intersect(names(row_names), names(pub[[kind]]))) {
      expected <- pub[[kind]][[key]]
      half <- 10^(-pub[["decimals"]][[kind]][[key]]) / 2
      squared <- kind == "sd" && key != "TV"
      bound <- if (kind == "variance" || squared) component_tol * total else
        if (kind == "sd") half + component_tol * total / (2 * expected) else
          if (key == "TV") half else half + relative_tol * abs(expected)
      quantity <- paste(key, kind)
      if (is.null(grr)) {
        row <- validation_row("ANK-10", "AIAG (2010), Tables III-B 8 and III-B 10", quantity, expected,
          "not rerun: protected data required", paste(validation_format(bound), if (squared) "on variance scale" else "absolute"),
          result = "NOT RERUN")
      } else {
        index <- match(row_names[[key]], trimws(grr$table$source))
        if (key == "INT" && is.na(index)) {
          row <- validation_row("ANK-10", "AIAG (2010), Tables III-B 8 and III-B 10", quantity, expected,
            "not estimated: pooled interaction", "not a separate component", result = "REPORT (pooled interaction)")
        } else {
          if (is.na(index)) stop("AIAG presentation is missing an aggregate component: ", key)
          value <- grr$table[[kind]][index]
          row <- validation_compare("ANK-10", "AIAG (2010), Tables III-B 8 and III-B 10", quantity, expected, value, bound, squared)
        }
      }
      rows[[length(rows) + 1L]] <- row
    }
  }
  rows[[length(rows) + 1L]] <- if (is.null(grr)) validation_row("ANK-10", "AIAG (2010)", "ndc", pub[["ndc"]],
    "not rerun: protected data required", "exact", result = "NOT RERUN") else
    validation_compare("ANK-10", "AIAG (2010)", "ndc", pub[["ndc"]], grr$summary[["ndc"]], 0)
  do.call(rbind, rows)
}

validation_capture <- function(expr) {
  warnings <- character()
  value <- withCallingHandlers(tryCatch(suppressMessages(expr), error = function(e) e),
    warning = function(w) {warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning")})
  list(value = value, warnings = warnings)
}

validation_run <- function(context = validation_context()) {
  anchors <- validation_anchors(context)
  fit_function <- getExportedValue("llmsa", "msa_fit")
  grr_function <- getExportedValue("llmsa", "msa_grr")
  simulate <- getExportedValue("llmsa", "msa_simulate")
  tables <- list()
  diagnostics <- list()
  fit <- function(runs, interactions = TRUE, label, ...) {
    captured <- validation_capture(fit_function(runs, type = "numeric", interactions = interactions, ...))
    if (inherits(captured$value, "error")) stop("Numeric validation fit failed (", label, "): ", conditionMessage(captured$value))
    if (length(captured$warnings)) {
      stop("Required numeric reference fit produced warnings (", label, "): ", paste(captured$warnings, collapse = "; "))
    }
    captured$value
  }
  add <- function(name, rows) tables[[name]] <<- do.call(rbind, rows)
  component_tol <- validation_tolerance(anchors, "reml_anova", "component_tol_fraction_of_total_variance")
  relative_tol <- validation_tolerance(anchors, "reml_anova", "derived_rel_tol")
  oracle_tol <- validation_tolerance(anchors, "oracle", "variance_component_tol_fraction_of_total_variance")
  oracle_relative <- validation_tolerance(anchors, "oracle", "derived_rel_tol")

  # K-M1a-1: synthetic designs prescribed by the specification, seed one.
  designs <- expand.grid(interactions = c(FALSE, TRUE), blocks = c(1, 3))
  rows <- list()
  optimizer_text <- validation_get(anchors, "ANK-TOL", "value", "reml_anova", "optimizer")
  optimizer <- regmatches(optimizer_text, regexec('^lmerControl\\(optimizer = "([A-Za-z_]+)"\\)$', optimizer_text))[[1]]
  if (length(optimizer) != 2L) stop("Unsupported reference optimizer declaration in ANK-TOL.")
  for (i in seq_len(nrow(designs))) {
    design <- designs[i, ]
    variance <- list(item = 1, prompt = 0.1, model = 0.08, residual = 0.1)
    if (design$blocks > 1) variance$block <- 0.05
    if (design$interactions) variance <- c(variance, list(item_prompt = 0.05, item_model = 0.04, prompt_model = 0.03))
    r <- simulate(20, 4, 3, 3, design$blocks, vc = variance, seed = 1)
    label <- paste("Synthetic design", i, "(seed 1)")
    reference <- validation_anova(validation_frame(r), design$interactions)
    if (any(reference < 0)) stop("Synthetic ANOVA reference has a negative component: ", label)
    f <- fit(r, design$interactions, label, control = lme4::lmerControl(optimizer = optimizer[2]))
    observed <- validation_components(f)
    for (key in names(reference)) rows[[length(rows) + 1L]] <- validation_compare(
      "ANK-TOL.reml_anova", "Independent stats::aov EMS solution", paste(label, key),
      reference[[key]], observed[[key]], component_tol * sum(reference))
    ref_grr <- validation_grr(reference, anchors)
    actual <- grr_function(f)$summary
    for (key in c("grr_pct_study_var", "grr_pct_contribution", "icc_items", "ndc")) {
      rows[[length(rows) + 1L]] <- validation_compare("ANK-TOL.reml_anova", "Independent GRR formulas", paste(label, key),
        ref_grr[[key]], actual[[key]], if (key == "ndc") 0 else relative_tol * abs(ref_grr[[key]]))
    }
  }
  add("Balanced designs against ANOVA", rows)

  # K-M1a-2: publish only AIAG statistics, in either context.
  aiag <- validation_aiag(context, anchors)
  pub <- validation_get(anchors, "ANK-10", "value")
  row_names <- c(EV = "Repeatability", AV = "Reproducibility", GRR = "Total gauge R&R",
                  PV = "Part-to-part (items)", TV = "Total variation")
  aiag_runs <- aiag_fit <- aiag_grr <- NULL
  if (!is.null(aiag)) {
    aiag_runs <- validation_runs(aiag$part, aiag$appraiser, rep = aiag$trial, value = aiag$value)
    aiag_fit <- fit(aiag_runs, FALSE, "AIAG, pooled interaction")
    aiag_grr <- grr_function(aiag_fit)
  }
  tables[["AIAG published statistics"]] <- validation_aiag_table(anchors, aiag_grr)
  if (!is.null(aiag_runs)) {
    interactive <- fit(aiag_runs, TRUE, "AIAG with interaction")
    g <- grr_function(interactive)
    rows <- lapply(c("EV", "AV", "GRR", "PV"), function(key) {
      observed <- g$table$sd[match(row_names[[key]], trimws(g$table$source))]
      validation_row("ANK-10", "AIAG pooled model versus model with interaction", paste(key, "SD"),
        pub[["sd"]][[key]], observed, "not a criterion", result = "REPORT")
    })
    add("AIAG interaction model (reported)", rows)
  }

  # K-M1a-3: live VCA and SixSigma oracles, never saved package output.
  ic50 <- getExportedValue("llmsa", "ic50_demo")
  ic50_fit <- fit(ic50, TRUE, "ic50_demo")
  cases <- list(list(label = "ic50_demo", runs = ic50, model = ic50_fit, interactions = TRUE, engine = "remlVCA", report = FALSE),
                list(label = "ic50_demo (unbalanced)", runs = ic50, model = ic50_fit, interactions = TRUE, engine = "anovaVCA", report = TRUE))
  if (!is.null(aiag_runs)) cases <- c(cases, list(
    list(label = "AIAG pooled", runs = aiag_runs, model = aiag_fit, interactions = FALSE, engine = "remlVCA", report = FALSE),
    list(label = "AIAG pooled", runs = aiag_runs, model = aiag_fit, interactions = FALSE, engine = "anovaVCA", report = FALSE),
    list(label = "AIAG with interaction", runs = aiag_runs, model = interactive, interactions = TRUE, engine = "remlVCA", report = FALSE)))
  for (case in cases) {
    d <- validation_frame(case$runs)
    terms <- validation_terms(d, case$interactions)
    formula <- stats::reformulate(terms, "y")
    oracle <- if (case$engine == "remlVCA") VCA::remlVCA(formula, Data = d, VarVC = FALSE, quiet = TRUE) else
      VCA::anovaVCA(formula, Data = d, quiet = TRUE)
    values <- oracle$aov.tab
    reference <- c(stats::setNames(values[terms, "VC"], terms), Residual = values["error", "VC"])
    observed <- validation_components(case$model)
    rows <- lapply(names(reference), function(key) {
      if (case$report) validation_row("ANK-TOL.oracle", paste0("VCA::", case$engine), paste(case$label, key),
        reference[[key]], observed[[key]], "not a criterion: unbalanced ANOVA", result = "REPORT") else
        validation_compare("ANK-TOL.oracle", paste0("VCA::", case$engine), paste(case$label, key),
          reference[[key]], observed[[key]], oracle_tol * values["total", "VC"])
    })
    add(paste(case$label, "against", case$engine), rows)
  }
  six_data <- new.env(parent = emptyenv())
  utils::data("ss.data.rr", package = "SixSigma", envir = six_data)
  d <- six_data$ss.data.rr
  old_stars <- options(show.signif.stars = getOption("show.signif.stars"))
  grDevices::pdf(NULL)
  tryCatch(utils::capture.output(six <- SixSigma::ss.rr(var = "time1", part = "prototype", appr = "operator",
                                                       data = d, print_plot = FALSE)),
           finally = {grDevices::dev.off(); options(old_stars)})
  table <- six$varComp
  rownames(table) <- trimws(rownames(table))
  reference <- c(Residual = table["Repeatability", "VarComp"], prompt = table["operator", "VarComp"],
    "item:prompt" = if ("prototype:operator" %in% rownames(table)) table["prototype:operator", "VarComp"] else 0,
    item = table["Part-To-Part", "VarComp"])
  f <- fit(validation_runs(d$prototype, d$operator, rep = as.integer(d$run), value = d$time1), TRUE, "SixSigma time1")
  observed <- validation_components(f)
  rows <- lapply(names(reference), function(key) validation_compare("ANK-TOL.oracle", "SixSigma::ss.rr, default pooling",
    key, reference[[key]], observed[[key]], oracle_tol * table["Total Variation", "VarComp"]))
  g <- grr_function(f)
  sd <- six$studyVar
  rownames(sd) <- trimws(rownames(sd))
  map <- c("Total gauge R&R" = "Total Gage R&R", Repeatability = "Repeatability", Reproducibility = "Reproducibility",
            prompt = "operator", "Part-to-part (items)" = "Part-To-Part")
  for (key in names(map)) {
    expected <- 100 * sd[map[[key]], "StdDev"] / sd["Total Variation", "StdDev"]
    value <- g$table$pct_study_var[match(key, trimws(g$table$source))]
    rows[[length(rows) + 1L]] <- validation_compare("ANK-TOL.oracle", "SixSigma::ss.rr, unrounded StdDev",
      paste(key, "% study variation"), expected, value, abs(expected) * oracle_relative)
  }
  rows[[length(rows) + 1L]] <- validation_compare("ANK-TOL.oracle", "SixSigma::ss.rr", "ndc", six$ncat, g$summary[["ndc"]], 0)
  add("SixSigma oracle", rows)

  pen_data <- new.env(parent = emptyenv())
  utils::data("Penicillin", package = "lme4", envir = pen_data)
  p <- pen_data$Penicillin
  pen <- validation_runs(p$sample, p$plate, value = p$diameter)
  f <- fit(pen, FALSE, "Penicillin")
  values <- validation_components(f)
  anova <- validation_anova(validation_frame(pen), FALSE)
  rows <- lapply(names(anova), function(key) validation_compare("ANK-TOL.reml_anova", "Penicillin: stats::aov EMS",
    key, anova[[key]], values[[key]], component_tol * sum(anova)))
  add("Penicillin against ANOVA", rows)
  pub <- validation_get(anchors, "ANK-13", "value")
  total <- sum(unlist(pub[["variance"]]))
  map <- c(plate = "prompt", sample = "item", residual = "Residual")
  rows <- list()
  for (kind in c("variance", "sd")) for (key in names(map)) {
    value <- values[[map[[key]]]]
    if (kind == "sd") value <- sqrt(value)
    rows[[length(rows) + 1L]] <- validation_compare("ANK-13", "Bates (2010), section 2.1.2",
      paste(key, kind), pub[[kind]][[key]], value, component_tol * total, squared = kind == "sd")
  }
  add("Penicillin published estimates", rows)

  # K-M1a-4: one-way certified quantities and live aov LRE, all datasets.
  meta <- validation_get(anchors, "ANK-14", "value", "datasets")
  low <- unlist(validation_get(anchors, "ANK-TOL", "value", "nist_digits", "low_difficulty_datasets"))
  medium <- unlist(validation_get(anchors, "ANK-TOL", "value", "nist_digits", "medium_difficulty_datasets"))
  margin <- validation_lre_margin(anchors)
  rows <- lre_rows <- list()
  for (name in names(meta)) {
    d <- validation_nist(name, context, anchors)
    certified <- c(Residual = meta[[name]][["within"]][["ms"]],
      item = (meta[[name]][["between"]][["ms"]] - meta[[name]][["within"]][["ms"]]) / meta[[name]][["replicates_per_cell"]])
    tab <- summary(stats::aov(value ~ factor(treatment), data = d))[[1]]
    aov <- c(Residual = tab[["Mean Sq"]][2], item = (tab[["Mean Sq"]][1] - tab[["Mean Sq"]][2]) / meta[[name]][["replicates_per_cell"]])
    captured <- validation_capture(fit_function(validation_runs(d$treatment, rep = d$rep, value = d$value), type = "numeric"))
    failed <- inherits(captured$value, "error")
    reason <- c(if (failed) conditionMessage(captured$value), captured$warnings)
    if (length(reason)) diagnostics[[length(diagnostics) + 1L]] <- data.frame(Context = paste("NIST", name), Diagnostic = reason)
    if (failed && name %in% c(low, medium)) stop("Required NIST fit failed: ", name, ": ", reason[1])
    observed <- if (failed) c(Residual = NA_real_, item = NA_real_) else validation_components(captured$value)
    lre_fit <- vapply(names(certified), function(key) validation_lre(observed[[key]], certified[[key]]), numeric(1))
    lre_aov <- vapply(names(certified), function(key) validation_lre(aov[[key]], certified[[key]]), numeric(1))
    for (key in names(certified)) {
      if (name %in% low) {
        bound <- validation_tolerance(anchors, "nist_digits", "low_difficulty_rel_tol") * abs(certified[[key]])
        row <- validation_compare("ANK-14; ANK-TOL.nist_digits", paste("NIST StRD", name), key,
          certified[[key]], observed[[key]], bound)
      } else {
        required <- name %in% medium
        row <- validation_row("ANK-14; ANK-TOL.nist_digits", paste("NIST StRD", name), key,
          certified[[key]], observed[[key]], if (required) paste("LRE >= aov LRE minus", margin) else "not a criterion",
          passed = lre_fit[[key]] >= lre_aov[[key]] - margin, result = if (!required) "REPORT (higher difficulty)" else NULL)
      }
      if (length(captured$warnings) && startsWith(row$Result, "PASS")) row$Result <- "WARNING: see diagnostics"
      rows[[length(rows) + 1L]] <- row
    }
    if (!name %in% low) lre_rows[[length(lre_rows) + 1L]] <- data.frame(Dataset = name,
      `LRE msa_fit residual` = lre_fit[["Residual"]], `LRE msa_fit item` = lre_fit[["item"]],
      `LRE aov residual` = lre_aov[["Residual"]], `LRE aov item` = lre_aov[["item"]], check.names = FALSE)
  }
  add("NIST certified quantities", rows)

  # K-M1a-5: replace components of a real small fit with explicit synthetic
  # components and check independent formulas, boundaries and undefined cases.
  base <- fit(simulate(8, 3, 3, 2, 2, seed = 1), TRUE, "constructed-component base")
  v <- c(item = 4, prompt = 1 / 8, model = 1 / 4, block = 1 / 16,
          "item:prompt" = 1 / 32, "item:model" = 1 / 64, "prompt:model" = 1 / 128, Residual = 1 / 2)
  base$vc$variance <- unname(v[base$vc$source])
  expected <- validation_grr(v, anchors)
  observed <- grr_function(base)$summary
  rows <- lapply(names(expected), function(key) validation_compare("ANK-16", "Independent GRR algebra; constructed components",
    key, expected[[key]], observed[[key]], validation_tolerance(anchors, "arithmetic", "abs_tol")))
  thresholds <- validation_get(anchors, "ANK-16", "value", "study_var")
  for (limit in c(thresholds[["acceptable_below"]], thresholds[["unacceptable_above"]])) {
    f <- base; f$vc$variance <- 0
    f$vc$variance[f$vc$source == "Residual"] <- limit^2 / 100
    f$vc$variance[f$vc$source == "item"] <- 100 - limit^2 / 100
    g <- grr_function(f)
    rows[[length(rows) + 1L]] <- validation_row("ANK-16", "AIAG study-variation boundaries", paste("verdict at", limit, "%"),
      "marginal", g$verdict, "exact", identical(g$verdict, "marginal"))
  }
  for (kind in c("zero total", "zero gauge", "zero item")) {
    f <- base; f$vc$variance <- 0
    if (kind == "zero gauge") f$vc$variance[f$vc$source == "item"] <- 1
    if (kind == "zero item") f$vc$variance[f$vc$source == "Residual"] <- 1
    g <- grr_function(f)
    expected <- switch(kind, "zero total" = NA_real_, "zero gauge" = Inf,
                       "zero item" = validation_get(anchors, "ANK-16", "value", "ndc", "minimum"))
    same <- if (is.na(expected)) is.na(g$summary[["ndc"]]) else isTRUE(g$summary[["ndc"]] == expected)
    rows[[length(rows) + 1L]] <- validation_row("ANK-16", "GRR boundary convention (ADR-017)", paste(kind, "ndc"),
      expected, g$summary[["ndc"]], "exact", same)
  }
  add("GRR formulas and boundary conventions", rows)
  list(context = context$mode, tables = tables, lre = do.call(rbind, lre_rows),
       diagnostics = if (length(diagnostics)) do.call(rbind, diagnostics) else data.frame(Context = character(), Diagnostic = character()))
}
