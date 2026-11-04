# Offline readers and presentation for M1d. No simulation or fitting code.
# ADEMP formulas: the project's formula collection, section 9.

m1d_resource_ids <- c("ANK-06", sprintf("ANK-%02d", 40:47), "ANK-63", "ANK-TOL")

m1d_resources <- function(directory = system.file("validation", "m1d", package = "llmsa", mustWork = TRUE)) {
  read_json <- function(path) {
    if (!file.exists(path)) stop("M1d validation input is missing: ", path, call. = FALSE)
    tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE),
      error = function(e) stop("Cannot read M1d validation JSON: ", path, ": ", conditionMessage(e), call. = FALSE))
  }
  manifest <- read_json(file.path(directory, "SOURCES.json"))
  if (!identical(manifest$schema, 1L) ||
      !identical(manifest$generator, "data-raw/make_validation_m1d.R") ||
      !setequal(names(manifest$anchors), m1d_resource_ids)) {
    stop("M1d validation manifest is incomplete.", call. = FALSE)
  }
  if (!setequal(list.files(file.path(directory, "anchors"), all.files = TRUE, no.. = TRUE),
                paste0(m1d_resource_ids, ".json"))) stop("M1d anchor directory differs from the manifest.", call. = FALSE)
  out <- stats::setNames(vector("list", length(m1d_resource_ids)), m1d_resource_ids)
  for (id in m1d_resource_ids) {
    name <- paste0(id, ".json")
    path <- file.path(directory, "anchors", name)
    meta <- manifest$anchors[[id]]
    hash <- digest::digest(file = path, algo = "sha256", serialize = FALSE)
    if (!identical(meta$original, paste0("reference/anchors/", name)) ||
        !identical(meta$copied, paste0("inst/validation/m1d/anchors/", name)) ||
        !identical(hash, meta$original_sha256) || !identical(hash, meta$copied_sha256)) {
      stop("M1d anchor SHA-256/provenance mismatch: ", id, call. = FALSE)
    }
    a <- read_json(path)
    required <- c("id", "value", "unit", "tolerance", "source_url", "quote", "retrieved")
    if (!identical(a$id, id) || !all(required %in% names(a))) stop("Invalid M1d anchor: ", id, call. = FALSE)
    out[[id]] <- a
  }
  out
}

m1d_display <- function(d, digits = 4L) {
  for (name in names(d)) if (is.numeric(d[[name]])) {
    d[[name]] <- vapply(d[[name]], format, "", digits = digits, trim = TRUE)
  }
  d
}

m1d_numeric_leaves <- function(x, prefix = "") {
  if (is.numeric(x)) return(data.frame(quantity = prefix, value = x, stringsAsFactors = FALSE))
  if (!is.list(x)) return(data.frame(quantity = character(), value = numeric()))
  do.call(rbind, lapply(names(x), function(name) {
    m1d_numeric_leaves(x[[name]], if (nzchar(prefix)) paste(prefix, name, sep = ".") else name)
  }))
}

m1d_literature_table <- function(anchor) {
  rows <- m1d_numeric_leaves(anchor$value)
  rows$unit <- ifelse(grepl("pct", rows$quantity), "percent", "count")
  rows$unit[grepl("(^|\\.)(k_)?alpha($|_)", rows$quantity)] <- "dimensionless alpha"
  rows$unit[grepl("pct_above$", rows$quantity)] <- "percent, strictly above this bound"
  rows$unit[grepl("min_pct$", rows$quantity)] <- "percent, minimum rule"
  rows$quantity <- gsub("_", " ", rows$quantity, fixed = TRUE)
  rows
}

# Nominal coverage is the study contract (docs/02 M1c: 95% intervals), not an
# estimate from the full results or a data-dependent acceptance threshold.
m1d_findings <- function(study, results, anchors, nominal = 95 / 100) {
  fields <- c("scenario", "estimand", "measure", "value", "mcse")
  if (!all(fields %in% names(results)) || anyNA(results[fields]) ||
      any(!is.finite(results$value)) || any(!is.finite(results$mcse)) || any(results$mcse < 0) ||
      anyDuplicated(results[c("scenario", "estimand", "measure")])) {
    stop("Invalid M1d findings input.", call. = FALSE)
  }
  tolerance <- anchors[["ANK-TOL"]]$value
  if (study %in% c("ordinal_recovery", "binary_recovery")) {
    rows <- results[results$measure == "rel_bias" &
      !results$estimand %in% c("Residual", "residual", "grr_pct_study_var", "icc_items"), fields, drop = FALSE]
    rows <- rows[abs(rows$value) > pmax(tolerance$bias_report$rel_bias,
      tolerance$bias_report$mcse_multiple * rows$mcse), , drop = FALSE]
    direction <- ifelse(rows$value > 0, "overestimation", "underestimation")
  } else if (study == "two_level") {
    rows <- results[results$measure == "bias" & results$estimand == "model", fields, drop = FALSE]
    if (!setequal(rows$scenario, unique(results$scenario))) stop("Missing two-level model bias.", call. = FALSE)
    direction <- ifelse(abs(rows$value) > tolerance$mc_factor$report * rows$mcse,
      ifelse(rows$value > 0, "overestimation", "underestimation"), "no direction resolved at the report threshold")
  } else if (study == "boot_coverage") {
    if (length(nominal) != 1L || !is.finite(nominal) || nominal <= 0 || nominal >= 1) {
      stop("Invalid nominal coverage.", call. = FALSE)
    }
    intervals <- c("grr_pct_study_var", "grr_pct_contribution", "ndc", "icc_items")
    rows <- results[results$measure == "coverage" & results$estimand %in% intervals, fields, drop = FALSE]
    rows <- rows[abs(rows$value - nominal) > tolerance$mc_factor$report * rows$mcse, , drop = FALSE]
    direction <- ifelse(rows$value > nominal, "overcoverage", "undercoverage")
  } else stop("Unknown M1d study: ", study, call. = FALSE)
  rows$direction <- direction
  rownames(rows) <- NULL
  rows
}

m1d_performance <- function(x, truth) {
  if (length(truth) != 1L || !is.finite(truth) || truth == 0) {
    stop("M1d sensitivity requires one finite nonzero truth.", call. = FALSE)
  }
  x <- x[is.finite(x)]
  n <- length(x)
  bias <- if (n) mean(x) - truth else NA_real_
  empse <- if (n > 1L) stats::sd(x) else NA_real_
  mcse <- if (n > 1L) empse / sqrt(n) else NA_real_
  data.frame(n = n, bias = bias, bias_mcse = mcse, rel_bias = bias / truth,
    rel_bias_mcse = mcse / abs(truth), empse = empse,
    empse_mcse = if (n > 1L) empse / sqrt(2 * (n - 1L)) else NA_real_,
    status = if (n > 1L) "available" else "fewer than two finite estimates", stringsAsFactors = FALSE)
}

m1d_convergence_sensitivity <- function(path = system.file("validation", "sim", "ordinal_recovery_replicates.csv",
                                                          package = "llmsa")) {
  if (!nzchar(path) || !file.exists(path)) {
    return(list(available = FALSE, reason = "not available: ordinal_recovery_replicates.csv is missing"))
  }
  d <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  required <- c("scenario", "rep", "estimand", "estimate", "true", "converged", "singular")
  if (!all(required %in% names(d)) || !nrow(d) || anyNA(d[c("scenario", "rep", "estimand", "true")]) ||
      !is.numeric(d$estimate) || !is.numeric(d$true) || !is.logical(d$converged) || !is.logical(d$singular) ||
      anyDuplicated(d[c("scenario", "rep", "estimand")])) {
    stop("Invalid ordinal convergence-sensitivity replicates.", call. = FALSE)
  }
  groups <- split(d, list(d$scenario, d$estimand), drop = TRUE)
  tables <- lapply(groups, function(g) {
    truth <- unique(g$true)
    # Each denominator is computed from these replicate rows, never from a
    # separately read results table. Singularity is not an exclusion rule.
    all <- m1d_performance(g$estimate, truth)
    converged <- m1d_performance(g$estimate[g$converged %in% TRUE], truth)
    data.frame(scenario = g$scenario[1L], estimand = g$estimand[1L],
      selection = c("all finite estimates", "converged finite estimates"), rbind(all, converged))
  })
  flags <- unique(d[c("scenario", "rep", "converged", "singular")])
  if (anyDuplicated(flags[c("scenario", "rep")])) stop("Conflicting replicate diagnostics.", call. = FALSE)
  diagnostics <- lapply(split(flags, flags$scenario), function(g) {
    n <- nrow(g)
    nonconverged <- mean(g$converged %in% FALSE)
    singular <- mean(g$singular %in% TRUE)
    data.frame(scenario = g$scenario[1L], n = n, nonconverged = sum(g$converged %in% FALSE),
      convergence_unknown = sum(is.na(g$converged)), nonconverged_share = nonconverged,
      nonconverged_mcse = sqrt(nonconverged * (1 - nonconverged) / n),
      singular = sum(g$singular %in% TRUE), singular_unknown = sum(is.na(g$singular)),
      singular_share = singular, singular_mcse = sqrt(singular * (1 - singular) / n))
  })
  list(available = TRUE, tables = do.call(rbind, tables), diagnostics = do.call(rbind, diagnostics))
}
