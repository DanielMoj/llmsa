# Offline documentation calculations, using the currently loaded llmsa.
# Original anchors remain the authority; copies are complete and hash checked.

latent_anchor_ids <- c("ANK-06", "ANK-21", "ANK-25", "ANK-28", "ANK-TOL")
latent_studies <- c("ordinal_recovery", "binary_recovery", "two_level")

latent_get <- function(x, ...) {
  keys <- c(...)
  for (key in keys) {
    x <- x[[key]]
    if (is.null(x)) stop("Missing latent validation field: ", paste(keys, collapse = "$"), call. = FALSE)
  }
  x
}

latent_json <- function(path) {
  if (!file.exists(path)) stop("Latent validation input is missing: ", path, call. = FALSE)
  tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE),
    error = function(e) stop("Cannot read latent validation JSON: ", path, ": ", conditionMessage(e), call. = FALSE))
}

latent_hash <- function(path, expected) {
  if (!file.exists(path)) stop("Latent validation input is missing: ", path, call. = FALSE)
  got <- digest::digest(file = path, algo = "sha256", serialize = FALSE)
  if (!identical(got, expected)) stop("Latent validation SHA-256 mismatch: ", path, call. = FALSE)
  invisible(got)
}

latent_anchor <- function(path, id) {
  a <- latent_json(path)
  if (!identical(a[["id"]], id)) stop("Incorrect latent validation anchor ID: ", id, call. = FALSE)
  for (key in c("value", "unit", "tolerance", "source_url", "quote", "retrieved")) latent_get(a, key)
  a
}

latent_verify_resources <- function(resource_dir, repo_root = NULL) {
  manifest <- latent_json(file.path(resource_dir, "SOURCES.json"))
  if (!identical(manifest[["schema"]], 1L) ||
      !identical(manifest[["generator"]], "data-raw/make_validation_latent.R")) {
    stop("Invalid latent validation manifest schema or generator.", call. = FALSE)
  }
  entries <- latent_get(manifest, "anchors")
  if (anyDuplicated(names(entries)) || !setequal(names(entries), latent_anchor_ids)) {
    stop("Latent anchor manifest is incomplete or contains duplicate entries.", call. = FALSE)
  }
  files <- list.files(file.path(resource_dir, "anchors"), all.files = TRUE,
                      recursive = TRUE, include.dirs = TRUE, no.. = TRUE)
  if (!setequal(files, paste0(latent_anchor_ids, ".json"))) {
    stop("Latent anchor directory differs from the manifest.", call. = FALSE)
  }
  for (id in latent_anchor_ids) {
    e <- entries[[id]]
    original <- file.path("reference", "anchors", paste0(id, ".json"))
    copied <- file.path("inst", "validation", "latent", "anchors", paste0(id, ".json"))
    if (!identical(e[["original"]], original) || !identical(e[["copied"]], copied) ||
        !identical(e[["original_sha256"]], e[["copied_sha256"]])) {
      stop("Invalid latent anchor provenance: ", id, call. = FALSE)
    }
    path <- file.path(resource_dir, "anchors", paste0(id, ".json"))
    latent_hash(path, latent_get(e, "copied_sha256"))
    latent_anchor(path, id)
    if (!is.null(repo_root)) latent_hash(file.path(repo_root, original), e[["original_sha256"]])
  }
  manifest
}

latent_context <- function(repo_root = Sys.getenv("REPO_ROOT", ""),
                           resource_dir = system.file("validation", "latent", package = "llmsa", mustWork = TRUE)) {
  root <- NULL
  if (nzchar(repo_root)) {
    if (!file.exists(file.path(repo_root, "DESCRIPTION")) || !dir.exists(file.path(repo_root, "reference", "anchors"))) {
      stop("Invalid REPO_ROOT for latent validation: ", repo_root, call. = FALSE)
    }
    root <- normalizePath(repo_root, mustWork = TRUE)
  }
  manifest <- latent_verify_resources(resource_dir, root)
  list(mode = if (is.null(root)) "public" else "full", root = root, resource_dir = resource_dir,
       anchors = if (is.null(root)) file.path(resource_dir, "anchors") else file.path(root, "reference", "anchors"),
       manifest = manifest)
}

latent_anchors <- function(context = latent_context()) {
  stats::setNames(lapply(latent_anchor_ids, function(id) {
    latent_anchor(file.path(context$anchors, paste0(id, ".json")), id)
  }), latent_anchor_ids)
}

latent_tolerance <- function(anchors, entry, key) {
  x <- latent_get(anchors, "ANK-TOL", "value", entry, key)
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 0) {
    stop("Invalid latent validation tolerance: ", entry, "$", key, call. = FALSE)
  }
  x
}

latent_package_data <- function(name, package) {
  e <- new.env(parent = emptyenv())
  utils::data(list = name, package = package, envir = e)
  if (!exists(name, e, inherits = FALSE)) stop("Missing oracle dataset: ", package, "::", name, call. = FALSE)
  e[[name]]
}

latent_capture <- function(expr) {
  warnings <- messages <- character()
  value <- withCallingHandlers(expr,
    warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") },
    message = function(m) { messages <<- c(messages, conditionMessage(m)); invokeRestart("muffleMessage") })
  list(value = value, warnings = warnings, messages = messages)
}

latent_compare <- function(anchor, source, quantity, expected, observed, tolerance) {
  if (any(!is.finite(c(expected, observed, tolerance))) || tolerance < 0) {
    stop("Non-finite latent comparison: ", quantity, call. = FALSE)
  }
  data.frame(Anchor = anchor, Source = source, Quantity = quantity,
    Expected = expected, Observed = observed, Tolerance = tolerance,
    Result = if (abs(observed - expected) <= tolerance) "PASS" else "FAIL",
    stringsAsFactors = FALSE)
}

latent_reference_checks <- function(anchors = latent_anchors()) {
  diagnostics <- character()
  run <- function(expr, name) {
    result <- latent_capture(expr)
    conditions <- c(result$warnings, result$messages)
    if (length(conditions)) diagnostics <<- c(diagnostics, paste0(name, ": ", conditions))
    result$value
  }
  wine <- latent_package_data("wine", "ordinal")
  wine_runs <- llmsa::as_msa_runs(data.frame(item_id = as.character(wine$bottle),
    prompt_id = as.character(wine$judge), model_id = "M1", rep = 1L, value = as.character(wine$rating)))
  wine_rows <- list()
  for (link in c("logit", "probit")) {
    direct <- run(ordinal::clmm(rating ~ 1 + (1 | bottle) + (1 | judge), data = wine, link = link), paste("wine clmm", link))
    fitted <- run(llmsa::msa_fit(wine_runs, type = "ordinal", link = link, levels = levels(wine$rating)), paste("wine msa_fit", link))
    ref <- vapply(ordinal::VarCorr(direct), function(v) as.numeric(v)[1L], numeric(1))
    ref <- c(item = ref[["bottle"]], prompt = ref[["judge"]],
             Residual = latent_get(anchors, "ANK-28", "value", link))
    bound <- latent_tolerance(anchors, "engine_ordinal", "rel_tol") * sum(ref)
    for (name in names(ref)) {
      wine_rows[[length(wine_rows) + 1L]] <- latent_compare("ANK-TOL.engine_ordinal / ANK-28",
        "ordinal::clmm on wine; latent residual", paste(link, name), ref[[name]],
        fitted$vc$variance[match(name, fitted$vc$source)], bound)
    }
  }
  e <- new.env(parent = asNamespace("ordinal"))
  e$wine <- wine
  clmm2 <- list(
    laplace = run(eval(quote(clmm2(rating ~ temp + contact, random = judge, data = wine)), e), "clmm2 Laplace"),
    nagq10 = run(eval(quote(clmm2(rating ~ temp + contact, random = judge, data = wine, Hess = TRUE, nAGQ = 10)), e), "clmm2 quadrature"))
  installation_wine <- do.call(rbind, lapply(names(clmm2), function(key) {
    latent_compare("ANK-21", "Christensen, clmm2 tutorial, pp. 2-3", paste(key, "judge variance"),
      latent_get(anchors, "ANK-21", "value", key, "variance"), as.numeric(clmm2[[key]]$stDev)^2,
      latent_get(anchors, "ANK-21", "tolerance", key, "variance"))
  }))
  beetles <- latent_package_data("BeetlesMale", "rptR")
  beetle_runs <- llmsa::as_msa_runs(data.frame(item_id = as.character(beetles$Population),
    prompt_id = "P1", model_id = "M1", rep = as.integer(stats::ave(seq_len(nrow(beetles)), beetles$Population, FUN = seq_along)),
    value = beetles$Colour))
  fit <- run(llmsa::msa_fit(beetle_runs, type = "binary", link = "logit"), "BeetlesMale msa_fit")
  icc <- unname(llmsa::msa_grr(fit)$summary[["icc_items"]])
  direct <- run(lme4::glmer(Colour ~ (1 | Population), data = beetles, family = stats::binomial("logit")), "BeetlesMale glmer")
  rpt <- function(...) rptR::rptBinary(Colour ~ (1 | Population), grname = "Population", data = beetles,
                                       link = "logit", nboot = 0, npermut = 0, ...)
  liability <- run(rpt(expect = "liability"), "rptR liability")
  population <- as.numeric(lme4::VarCorr(direct)$Population)
  refs <- c(`rptBinary(expect = liability)` = liability$R["R_link", "Population"],
    `performance::icc (direct glmer)` = performance::icc(direct)$ICC_adjusted,
    `performance::icc (msa_fit model)` = performance::icc(fit$model)$ICC_adjusted,
    `Population / (Population + ANK-28 residual)` = population / (population + latent_get(anchors, "ANK-28", "value", "logit")))
  binary_rows <- do.call(rbind, lapply(names(refs), function(name) {
    latent_compare("ANK-28 / ANK-TOL.rptr.live_tol", name, "ICC_items (latent logit)", refs[[name]], icc,
                   latent_tolerance(anchors, "rptr", "live_tol"))
  }))
  default <- run(rpt(), "rptR default installation check")
  rpt_rows <- do.call(rbind, lapply(c(link_scale = "R_link", original_scale = "R_org"), function(scale) {
    key <- if (scale == "R_link") "link_scale" else "original_scale"
    latent_compare("ANK-25 / ANK-TOL.rptr.vignette_tol", "rptR vignette, rep10; default expect = meanobs", scale,
      latent_get(anchors, "ANK-25", "value", key), default$R[scale, "Population"],
      latent_tolerance(anchors, "rptr", "vignette_tol"))
  }))
  list(wine = do.call(rbind, wine_rows), ordinal_installation = installation_wine,
       binary = binary_rows, rptr_installation = rpt_rows, diagnostics = diagnostics[nzchar(diagnostics)])
}

latent_read_results <- function(study, sim_dir = system.file("validation", "sim", package = "llmsa", mustWork = TRUE)) {
  if (!study %in% latent_studies) stop("Unknown latent study: ", study, call. = FALSE)
  full <- file.path(sim_dir, paste0(study, "_results.csv"))
  path <- if (file.exists(full)) full else file.path(sim_dir, paste0(study, "_check_results.csv"))
  if (!file.exists(path)) stop("Latent study results are missing: ", path, call. = FALSE)
  d <- tryCatch(utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE),
    error = function(e) stop("Cannot read latent study results: ", path, ": ", conditionMessage(e), call. = FALSE))
  required <- c("scenario", "estimand", "measure", "value", "mcse", "n_sim", "seed")
  if (anyDuplicated(names(d)) || !all(required %in% names(d)) || !nrow(d) || anyNA(d[required])) {
    stop("Invalid latent study results schema: ", path, call. = FALSE)
  }
  for (col in c("value", "mcse", "n_sim", "seed")) {
    if (!is.numeric(d[[col]]) || any(!is.finite(d[[col]]))) stop("Invalid latent results column: ", col, call. = FALSE)
  }
  if (any(d$mcse < 0) || length(unique(d$n_sim)) != 1L || any(d$n_sim < 2 | d$n_sim != floor(d$n_sim)) ||
      anyDuplicated(d[c("scenario", "estimand", "measure")])) {
    stop("Invalid latent study results values or duplicate keys: ", path, call. = FALSE)
  }
  if (any(d$value[d$measure %in% c("empse", "rmse")] < 0) ||
      any(d$value[d$measure == "derived_share"] < 0 | d$value[d$measure == "derived_share"] > 1)) {
    stop("Invalid latent study result measure range: ", path, call. = FALSE)
  }
  if (any(d$seed != floor(d$seed) | d$seed < 1 | d$seed > .Machine$integer.max)) {
    stop("Invalid latent study result seed: ", path, call. = FALSE)
  }
  ids <- switch(study, ordinal_recovery = paste0("S-ord-", 1:4),
                binary_recovery = paste0("S-bin-", 1:2), two_level = paste0("S-two-", 1:2))
  if (!setequal(unique(d$scenario), ids)) stop("Incomplete latent study scenarios: ", path, call. = FALSE)
  for (id in ids) {
    estimands <- c("item", "prompt", "model", if (study == "ordinal_recovery") "item:model",
                   if (id == "S-ord-4") "block", "grr_pct_study_var", "icc_items")
    for (estimand in estimands) {
      measures <- c("bias", "rel_bias", "empse", "rmse", if (study == "two_level" && estimand == "model") "derived_share")
      rows <- d[d$scenario == id & d$estimand == estimand, , drop = FALSE]
      if (!all(measures %in% rows$measure)) stop("Incomplete latent study measures: ", id, "/", estimand, call. = FALSE)
    }
  }
  list(data = d, path = path, mode = if (identical(path, full)) "full" else "check", n_sim = unique(d$n_sim))
}

latent_display <- function(d) {
  # Format before kable: fixed decimal places erase small Bias and MCSE values.
  for (name in names(d)) if (is.numeric(d[[name]])) {
    d[[name]] <- vapply(d[[name]], format, character(1), digits = 6L, trim = TRUE)
  }
  d
}
