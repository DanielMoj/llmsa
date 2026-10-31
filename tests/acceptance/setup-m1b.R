# Helpers for the M1b acceptance tests (docs/02-statistikkern.md, K-M1b-1 to
# K-M1b-7); a setup file for the reason given in setup-acceptance.R.
#
# Reference values come from reference/anchors/ (ANK-21, ANK-25, ANK-28,
# ANK-TOL) or from the oracles the criteria name (ordinal::clmm,
# ordinal::clmm2, rptR::rptBinary, performance::icc, lme4::glmer), called at
# test time on the same data; no package output is frozen. The simulation
# scenarios are read at test time from the table in docs/02-statistikkern.md:
# docs/01 §8 makes them specification, not anchors.
# The mini-references below are written independently of the package code
# from Formelsammlung §3 (gauge R&R statistics, via acc_m1a_grr_reference()),
# §4 (latent scale, range method for two levels) and §9 (performance measures
# of a simulation study). Interpretations of points on which the spec is
# silent are listed in orchestrator/handoff/M1b/CRITERIA.json under "open"
# (ACC-n); the contract of the class-B scripts is ACC-2 to ACC-8.

acc_m1b <- new.env(parent = emptyenv())   # cache for one test run

# Anchors ---------------------------------------------------------------------------

# Residual variance of the latent scale for a link (ANK-28). The decimal value
# must agree with the exact expression of the anchor.
acc_m1b_latent_residual <- function(link) {
  value <- as.numeric(acc_m1a_value("ANK-28", link))
  exact <- eval(parse(text = acc_m1a_value("ANK-28", "expression", link)), envir = baseenv())
  if (abs(value - exact) > acc_m1a_tol("arithmetic", "abs_tol")) {
    stop("acceptance: ANK-28 value for ", link, " does not equal its expression", call. = FALSE)
  }
  value
}

acc_m1b_engine_tol <- function() as.numeric(acc_m1a_tol("engine_ordinal", "rel_tol"))
acc_m1b_arith_tol <- function() as.numeric(acc_m1a_tol("arithmetic", "abs_tol"))
acc_m1b_n_check <- function() as.integer(acc_m1a_tol("n_check", "n_sim"))

# Data ------------------------------------------------------------------------------

acc_m1b_package_data <- function(name, package) {
  e <- new.env(parent = emptyenv())
  utils::data(list = name, package = package, envir = e)
  if (!exists(name, envir = e, inherits = FALSE)) {
    stop("acceptance: dataset ", name, " missing in package ", package, call. = FALSE)
  }
  e[[name]]
}

# ordinal::wine with item = bottle, prompt = judge, one model, one replicate
# (docs/02 K-M1b-1).
acc_m1b_wine <- function() acc_m1b_package_data("wine", "ordinal")
acc_m1b_wine_levels <- function() levels(acc_m1b_wine()$rating)
acc_m1b_wine_runs <- function() {
  w <- acc_m1b_wine()
  acc_m1a_runs(item = w$bottle, prompt = w$judge, model = "M1", rep = 1L, value = as.character(w$rating))
}

# rptR::BeetlesMale with item = Population, one prompt, one model; the
# individuals of a population are its replicates (docs/02 K-M1b-5).
acc_m1b_beetles <- function() acc_m1b_package_data("BeetlesMale", "rptR")
acc_m1b_beetles_runs <- function() {
  b <- acc_m1b_beetles()
  rep <- stats::ave(seq_len(nrow(b)), b$Population, FUN = seq_along)
  acc_m1a_runs(item = b$Population, prompt = "P1", model = "M1", rep = rep, value = as.integer(b$Colour))
}

# Fits of the package under test on wine (K-M1b-1, K-M1b-7) and BeetlesMale
# (K-M1b-5, K-M1b-7), once per test run.
acc_m1b_wine_fit <- function(link) {
  key <- paste0("wine_fit_", link)
  if (is.null(acc_m1b[[key]])) {
    acc_m1b[[key]] <- acc_m1a_quiet(msa_fit(acc_m1b_wine_runs(), type = "ordinal",
                                            levels = acc_m1b_wine_levels(), link = link))
  }
  acc_m1b[[key]]
}

acc_m1b_beetles_fit <- function() {
  if (is.null(acc_m1b$beetles_fit)) {
    acc_m1b$beetles_fit <- acc_m1a_quiet(msa_fit(acc_m1b_beetles_runs(), type = "binary", link = "logit"))
  }
  acc_m1b$beetles_fit
}

acc_m1b_beetles_icc <- function() as.numeric(acc_m1a_summary(msa_grr(acc_m1b_beetles_fit()), "icc_items"))

acc_m1b_ordinal_levels <- function(k = 5L) paste0("c", seq_len(k))

# Constructed study data from the latent model of Formelsammlung §4: random
# effects for item, prompt, model and block, latent residual N(0, 1) (probit)
# or logistic (logit); ordinal values cut at `cuts` into classes c1 < c2 < ...,
# binary values 1 when the latent value exceeds -mu. Seeded with the RNG of
# docs/01 §5; test parameters, no reference values.
acc_m1b_latent_design <- function(seed, items, prompts, models, reps, blocks, vc, link) {
  acc_m1a_with_seed(seed, {
    g <- expand.grid(rep = seq_len(reps), block = seq_len(blocks), model = seq_len(models),
                     prompt = seq_len(prompts), item = seq_len(items))
    eff <- function(n, v) stats::rnorm(n, 0, sqrt(if (is.null(v)) 0 else v))
    eta <- eff(items, vc$item)[g$item] + eff(prompts, vc$prompt)[g$prompt] +
      eff(models, vc$model)[g$model] + eff(blocks, vc$block)[g$block]
    noise <- if (link == "probit") stats::rnorm(nrow(g)) else stats::rlogis(nrow(g))
    list(g = g, latent = eta + noise)
  })
}

acc_m1b_ordinal_runs <- function(seed, items = 12L, prompts = 3L, models = 3L, reps = 2L, blocks = 1L,
                                 vc = list(item = 1, prompt = 0.3, model = 0.3, block = 0.3),
                                 cuts = c(-1.5, -0.5, 0.5, 1.5), link = "probit") {
  s <- acc_m1b_latent_design(seed, items, prompts, models, reps, blocks, vc, link)
  y <- findInterval(s$latent, cuts) + 1L
  acc_m1a_runs(item = sprintf("I%02d", s$g$item), prompt = paste0("P", s$g$prompt),
               model = paste0("M", s$g$model), rep = s$g$rep, value = paste0("c", y), block = s$g$block)
}

acc_m1b_binary_runs <- function(seed, items = 30L, prompts = 3L, models = 3L, reps = 2L, blocks = 1L,
                                vc = list(item = 1, prompt = 0.5, model = 0.5), mu = 0) {
  s <- acc_m1b_latent_design(seed, items, prompts, models, reps, blocks, vc, "logit")
  acc_m1a_runs(item = sprintf("I%02d", s$g$item), prompt = paste0("P", s$g$prompt),
               model = paste0("M", s$g$model), rep = s$g$rep, value = as.integer(s$latent + mu > 0),
               block = s$g$block)
}

# Model frame for a direct engine call, built from the runs the way the
# criteria describe the roles (factors item, prompt, model, block; rows with
# a missing response removed).
acc_m1b_frame <- function(runs, type, levels = NULL) {
  d <- as.data.frame(runs, stringsAsFactors = FALSE)
  out <- data.frame(item = factor(d$item_id), prompt = factor(d$prompt_id), model = factor(d$model_id),
                    block = factor(d$block))
  out$y <- if (type == "ordinal") {
    factor(as.character(d$value), levels = levels, ordered = TRUE)
  } else {
    as.integer(d$value)
  }
  droplevels(out[!is.na(out$y), , drop = FALSE])
}

# Variance components of a direct ordinal::clmm fit by grouping factor.
acc_m1b_clmm_components <- function(m) {
  v <- ordinal::VarCorr(m)
  stats::setNames(vapply(v, function(x) as.numeric(x)[1], numeric(1)), names(v))
}

acc_m1b_glmer_components <- function(m) {
  v <- as.data.frame(lme4::VarCorr(m))
  stats::setNames(v$vcov, v$grp)
}

# Mini-reference, Formelsammlung §4: a factor with exactly two levels enters
# as a fixed effect; its component is the sample variance of the two level
# effects {0, beta}, i.e. beta^2 / 2.
acc_m1b_range_component <- function(beta) stats::var(c(0, beta))

# Calls ------------------------------------------------------------------------------

# Value of `expr` with every warning collected (and muffled) and messages
# suppressed; an error is returned as the value.
acc_m1b_catch <- function(expr) {
  found <- character()
  value <- withCallingHandlers(
    tryCatch(suppressMessages(expr), error = function(e) e),
    warning = function(w) {
      found <<- c(found, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  list(value = value, warnings = found)
}

acc_m1b_norm <- function(x) trimws(gsub("[[:space:]]+", " ", x))

# Plain text of a help page of the documentation (man/<name>.Rd). The Rd files
# are read from the repository root: the package copy of the mutation gates
# holds no man/ directory (setup-acceptance.R).
acc_m1b_rd_text <- function(name) {
  key <- paste0("rd_", name)
  if (!is.null(acc_m1b[[key]])) return(acc_m1b[[key]])
  path <- file.path(acc_repo_root(), "man", paste0(name, ".Rd"))
  if (!file.exists(path)) stop("acceptance: help page missing: ", path, call. = FALSE)
  out <- tempfile("acc-m1b-rd-", fileext = ".txt")
  on.exit(unlink(out), add = TRUE)
  old <- options(useFancyQuotes = FALSE)
  on.exit(options(old), add = TRUE)
  tools::Rd2txt(tools::parse_Rd(path), out = out, options = list(underline_titles = FALSE))
  txt <- acc_m1b_norm(paste(readLines(out, warn = FALSE), collapse = " "))
  acc_m1b[[key]] <- txt
  txt
}

# Simulation scenarios (docs/02-statistikkern.md, M1b) ----------------------------------

acc_m1b_studies <- c(ordinal_recovery = "S-ord-", binary_recovery = "S-bin-", two_level = "S-two-")

acc_m1b_component_names <- c("Item×Modell" = "item:model", "Item" = "item", "Prompt" = "prompt",
                             "Modell" = "model", "Block" = "block", "Rest" = "Residual")

acc_m1b_number <- function(s) {
  s <- trimws(s)
  if (identical(s, "π²/3")) return(pi^2 / 3)
  x <- suppressWarnings(as.numeric(sub(",", ".", s, fixed = TRUE)))
  if (is.na(x)) stop("acceptance: unreadable number in the scenario table of docs/02: ", s, call. = FALSE)
  x
}

acc_m1b_parse_components <- function(cell, known) {
  parts <- trimws(strsplit(cell, "(;|,)[[:space:]]+")[[1]])
  base <- list()
  own <- list()
  for (p in parts) {
    ref <- regmatches(p, regexec("^(sonst )?wie (S-[a-z]+-[0-9]+)$", p))[[1]]
    if (length(ref)) {
      if (is.null(known[[ref[3]]])) stop("acceptance: scenario ", ref[3], " referenced before it is defined", call. = FALSE)
      base <- known[[ref[3]]]$components
      next
    }
    m <- regmatches(p, regexec("^(\\S+) (.+)$", p))[[1]]
    if (length(m) != 3L || !m[2] %in% names(acc_m1b_component_names)) {
      stop("acceptance: unreadable component in the scenario table of docs/02: ", p, call. = FALSE)
    }
    own[[acc_m1b_component_names[[m[2]]]]] <- acc_m1b_number(m[3])
  }
  for (k in names(own)) base[[k]] <- own[[k]]
  base
}

# The scenario table of M1b as a list by scenario ID: study, outcome type,
# link, design sizes and the true latent components (including Residual).
acc_m1b_scenarios <- function() {
  if (!is.null(acc_m1b$scenarios)) return(acc_m1b$scenarios)
  path <- file.path(acc_repo_root(), "docs", "02-statistikkern.md")
  if (!file.exists(path)) stop("acceptance: specification missing: ", path, call. = FALSE)
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  start <- grep("^## M1b", lines)
  end <- grep("^## M1c", lines)
  if (length(start) != 1L || length(end) != 1L || end <= start) {
    stop("acceptance: section M1b not found in ", path, call. = FALSE)
  }
  block <- lines[start:end]
  rows <- block[grepl("^\\|[[:space:]]*S-(ord|bin|two)-[0-9]+[[:space:]]*\\|", block)]
  out <- list()
  for (row in rows) {
    cells <- acc_m1a_split_pipe(row)
    if (length(cells) != 8L) stop("acceptance: scenario row with ", length(cells), " cells: ", row, call. = FALSE)
    id <- cells[1]
    target <- cells[2]
    ref <- regmatches(target, regexec("^wie (S-[a-z]+-[0-9]+)$", target))[[1]]
    if (length(ref)) {
      type <- out[[ref[2]]]$type
      link <- out[[ref[2]]]$link
    } else {
      type <- if (grepl("^ordinal", target)) "ordinal" else if (grepl("^bin", target)) "binary" else NA_character_
      link <- if (grepl("Probit", target)) "probit" else if (grepl("Logit", target)) "logit" else NA_character_
    }
    if (is.na(type) || is.na(link)) stop("acceptance: outcome type or link unreadable: ", target, call. = FALSE)
    sizes <- suppressWarnings(as.integer(cells[3:7]))
    if (anyNA(sizes)) stop("acceptance: design sizes unreadable: ", row, call. = FALSE)
    study <- names(acc_m1b_studies)[startsWith(id, acc_m1b_studies)]
    out[[id]] <- list(id = id, study = study, type = type, link = link,
                      items = sizes[1], prompts = sizes[2], models = sizes[3], reps = sizes[4], blocks = sizes[5],
                      components = acc_m1b_parse_components(cells[8], out))
  }
  acc_m1b$scenarios <- out
  out
}

acc_m1b_study_scenarios <- function(study) {
  Filter(function(s) identical(s$study, study), acc_m1b_scenarios())
}

# True values of the estimands of a scenario on the latent scale: every true
# component except the residual (fixed by the link, ANK-28), and %GRR (study
# variation) and ICC_items by Formelsammlung §3 with GRR = every component
# except the item component (residual included), TV = GRR + item.
acc_m1b_truth <- function(sc) {
  v <- unlist(sc$components)
  if (!all(c("item", "Residual") %in% names(v))) stop("acceptance: scenario ", sc$id, " lacks item or residual", call. = FALSE)
  grr <- sum(v[names(v) != "item"])
  total <- grr + v[["item"]]
  c(v[names(v) != "Residual"], grr_pct_study_var = 100 * sqrt(grr / total), icc_items = v[["item"]] / total)
}

# Required performance measures (docs/02, "Schätzziele"): bias, relative bias,
# empirical SE and RMSE for every estimand; for S-two additionally the share
# of replications with a derived component, reported at the two-level factor
# (ACC-3).
acc_m1b_measures <- c("bias", "rel_bias", "empse", "rmse")
acc_m1b_two_level_factor <- "model"

# Mini-reference, Formelsammlung §9 (Morris, White & Crowther 2019, Tab. 6):
# bias and EmpSE with their MCSE, MSE with its MCSE, RMSE = sqrt(MSE); relative
# bias = bias / theta with MCSE(bias) / |theta|; MCSE(RMSE) by the delta method
# MCSE(MSE) / (2 RMSE) (ACC-5). Only finite estimates enter.
acc_m1b_performance <- function(estimate, true) {
  x <- estimate[is.finite(estimate)]
  n <- length(x)
  if (n < 2L) stop("acceptance: fewer than two finite estimates", call. = FALSE)
  m <- mean(x)
  ss <- sum((x - m)^2)
  bias <- m - true
  mcse_bias <- sqrt(ss / (n * (n - 1)))
  empse <- sqrt(ss / (n - 1))
  mse <- mean((x - true)^2)
  mcse_mse <- sqrt(sum(((x - true)^2 - mse)^2) / (n * (n - 1)))
  rmse <- sqrt(mse)
  list(bias = c(value = bias, mcse = mcse_bias),
       rel_bias = c(value = bias / true, mcse = mcse_bias / abs(true)),
       empse = c(value = empse, mcse = empse / sqrt(2 * (n - 1))),
       rmse = c(value = rmse, mcse = mcse_mse / (2 * rmse)))
}

# Share of replications with a derived component; MCSE as for a coverage
# (Formelsammlung §9).
acc_m1b_share <- function(flag) {
  p <- mean(flag)
  c(value = p, mcse = sqrt(p * (1 - p) / length(flag)))
}

# Class-B scripts (docs/01 §8; contract ACC-2) -----------------------------------------------

acc_m1b_sim_dir <- function() file.path(acc_pkg_root(), "inst", "validation", "sim")
acc_m1b_script <- function(study) file.path(acc_m1b_sim_dir(), paste0(study, ".R"))
acc_m1b_check_file <- function(study, kind) {
  file.path(acc_m1b_sim_dir(), paste0(study, "_check_", kind, if (kind == "session") ".txt" else ".csv"))
}
acc_m1b_out_file <- function(dir, study, kind) {
  file.path(dir, paste0(study, "_", kind, if (kind == "session") ".txt" else ".csv"))
}

acc_m1b_read_csv <- function(path) {
  if (!file.exists(path)) stop("acceptance: file missing: ", path, call. = FALSE)
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

# The package under test installed into a temporary library, once per test
# run: a copy of DESCRIPTION, NAMESPACE, R/, inst/, data/ (and src/, LICENSE
# if present) of the loaded package is installed with R CMD INSTALL, so that
# the scripts load exactly the package under test with library(llmsa) (ACC-2).
acc_m1b_library <- function() {
  if (!is.null(acc_m1b$library)) return(acc_m1b$library)
  root <- acc_pkg_root()
  copy <- file.path(tempfile("acc-m1b-pkg-"), "llmsa")
  dir.create(copy, recursive = TRUE)
  for (part in c("DESCRIPTION", "NAMESPACE", "LICENSE", "R", "inst", "data", "src")) {
    source <- file.path(root, part)
    if (file.exists(source) && !file.copy(source, copy, recursive = TRUE)) {
      stop("acceptance: copy of ", part, " failed", call. = FALSE)
    }
  }
  lib <- tempfile("acc-m1b-lib-")
  dir.create(lib)
  res <- acc_run(file.path(R.home("bin"), "R"),
                 c("CMD", "INSTALL", "--no-docs", "--no-multiarch", paste0("--library=", shQuote(lib)), shQuote(copy)))
  if (res$status != 0L) {
    stop("acceptance: R CMD INSTALL of the package under test failed:\n",
         paste(utils::tail(c(res$stdout, res$stderr), 40), collapse = "\n"), call. = FALSE)
  }
  acc_m1b$library <- lib
  lib
}

# Runs `Rscript inst/validation/sim/<study>.R --n-sim <n> --scenarios <ids>
# --out <dir>` with the installed package under test, from a temporary working
# directory; returns status, output, elapsed seconds and the output files.
acc_m1b_run_script <- function(study, n_sim, scenarios) {
  script <- acc_m1b_script(study)
  if (!file.exists(script)) stop("acceptance: script missing: ", script, call. = FALSE)
  lib <- acc_m1b_library()
  out <- tempfile(paste0("acc-m1b-", study, "-out-"))
  dir.create(out)
  work <- tempfile("acc-m1b-wd-")
  dir.create(work)
  old <- setwd(work)
  on.exit(setwd(old), add = TRUE)
  libs <- paste(c(lib, .libPaths()), collapse = .Platform$path.sep)
  args <- c(shQuote(script), "--n-sim", as.character(n_sim), "--scenarios", paste(scenarios, collapse = ","),
            "--out", shQuote(out))
  start <- proc.time()[["elapsed"]]
  res <- acc_run(file.path(R.home("bin"), "Rscript"), args, env = paste0("R_LIBS=", shQuote(libs)))
  elapsed <- proc.time()[["elapsed"]] - start
  c(res, list(elapsed = elapsed, out = out, call = paste("Rscript", paste(args, collapse = " "))))
}

# Short run of a study rerun with n_sim = ANK-TOL.n_check and all scenarios of
# the study, once per test run.
acc_m1b_rerun <- function(study) {
  key <- paste0("rerun_", study)
  if (!is.null(acc_m1b[[key]])) return(acc_m1b[[key]])
  ids <- names(acc_m1b_study_scenarios(study))
  run <- acc_m1b_run_script(study, acc_m1b_n_check(), ids)
  acc_m1b[[key]] <- run
  run
}

acc_m1b_expect_run_ok <- function(run, study) {
  expect_identical(run$status, 0L,
                   label = sprintf("%s: exit status of `%s` (stderr: %s)", study, run$call,
                                   paste(utils::tail(run$stderr, 15), collapse = " | ")))
  for (kind in c("results", "replicates", "session")) {
    f <- acc_m1b_out_file(run$out, study, kind)
    expect_true(file.exists(f), label = sprintf("%s: the run writes %s", study, basename(f)))
  }
}

# Every column compared cell by cell; numbers after format(x, digits = 15),
# element by element (docs/02 K-M1b-2), rows ordered by scenario, rep and
# estimand.
acc_m1b_format_cells <- function(x) {
  if (is.numeric(x)) vapply(x, format, character(1), digits = 15) else as.character(x)
}

acc_m1b_order_replicates <- function(d) {
  keys <- intersect(c("scenario", "rep", "estimand"), names(d))
  if (!length(keys)) return(d)
  d[do.call(order, unname(as.list(d[keys]))), , drop = FALSE]
}

acc_m1b_expect_same_replicates <- function(new, old, label) {
  expect_setequal(names(new), names(old))
  expect_identical(nrow(new), nrow(old), label = sprintf("%s: number of rows", label))
  if (!setequal(names(new), names(old)) || nrow(new) != nrow(old)) return(invisible())
  new <- acc_m1b_order_replicates(new)
  old <- acc_m1b_order_replicates(old)
  for (col in names(old)) {
    a <- acc_m1b_format_cells(new[[col]])
    b <- acc_m1b_format_cells(old[[col]])
    diff <- which(a != b | is.na(a) != is.na(b))
    expect_true(length(diff) == 0L,
                label = sprintf("%s, column %s: %d cell(s) differ after format(x, digits = 15)%s", label, col, length(diff),
                                if (length(diff)) paste0(", first: ", a[diff[1]], " vs ", b[diff[1]]) else ""))
  }
}

acc_m1b_result_columns <- c("scenario", "estimand", "measure", "value", "mcse", "n_sim", "seed")
acc_m1b_replicate_columns <- c("scenario", "rep", "estimand", "estimate", "true",
                               "items", "prompts", "models", "blocks", "observations")

# Schema of a results file (docs/01 §8, ACC-3): the seven columns, a row with
# finite value and finite nonnegative mcse for every scenario, estimand and
# measure, n_sim as given, a finite seed.
acc_m1b_expect_results_schema <- function(res, study, scenarios, n_sim, label) {
  absent <- setdiff(acc_m1b_result_columns, names(res))
  expect_identical(absent, character(), label = sprintf("%s: columns missing from the results file", label))
  if (length(absent)) return(invisible())
  expect_setequal(unique(res$scenario), scenarios)
  expect_true(all(is.finite(suppressWarnings(as.numeric(res$seed)))), label = sprintf("%s: every row has a finite seed", label))
  for (id in scenarios) {
    sc <- acc_m1b_scenarios()[[id]]
    measures <- function(e) c(acc_m1b_measures, if (study == "two_level" && e == acc_m1b_two_level_factor) "derived_share")
    for (e in names(acc_m1b_truth(sc))) {
      for (m in measures(e)) {
        row <- res[res$scenario == id & res$estimand == e & res$measure == m, , drop = FALSE]
        what <- sprintf("%s: %s, estimand %s, measure %s", label, id, e, m)
        expect_identical(nrow(row), 1L, label = paste(what, "- number of rows"))
        if (nrow(row) != 1L) next
        expect_true(is.finite(row$value), label = paste(what, "- finite value"))
        expect_true(is.finite(row$mcse) && row$mcse >= 0, label = paste(what, "- finite nonnegative mcse"))
        expect_equal(as.numeric(row$n_sim), as.numeric(n_sim), label = paste(what, "- n_sim"))
      }
    }
  }
}

# Replicates against the scenario table (ACC-4): columns, one row per
# replication and estimand, the true values of the table, the design sizes of
# the table taken from the fitted model.
acc_m1b_expect_replicates_design <- function(rep, study, scenarios, n_sim, label) {
  cols <- c(acc_m1b_replicate_columns, if (study == "two_level") "derived")
  absent <- setdiff(cols, names(rep))
  expect_identical(absent, character(), label = sprintf("%s: columns missing from the replicates file", label))
  if (length(absent)) return(invisible())
  tol <- acc_m1b_arith_tol()
  for (id in scenarios) {
    sc <- acc_m1b_scenarios()[[id]]
    truth <- acc_m1b_truth(sc)
    for (e in names(truth)) {
      rows <- rep[rep$scenario == id & rep$estimand == e, , drop = FALSE]
      what <- sprintf("%s: %s, estimand %s", label, id, e)
      expect_setequal(as.integer(rows$rep), seq_len(n_sim))
      expect_identical(nrow(rows), as.integer(n_sim), label = paste(what, "- one row per replication"))
      expect_true(nrow(rows) > 0L && all(abs(as.numeric(rows$true) - truth[[e]]) <= tol),
                  label = sprintf("%s - column true equals the table value %.12g", what, truth[[e]]))
    }
    fitted <- rep[rep$scenario == id & !is.na(rep$items), , drop = FALSE]
    expect_true(nrow(fitted) > 0L, label = sprintf("%s: %s has fitted replications", label, id))
    for (k in c("items", "prompts", "models", "blocks")) {
      expect_true(nrow(fitted) > 0L && all(as.integer(fitted[[k]]) == sc[[k]]),
                  label = sprintf("%s: %s, column %s equals the table value %d", label, id, k, sc[[k]]))
    }
    n_obs <- sc$items * sc$prompts * sc$models * sc$reps * sc$blocks
    expect_true(nrow(fitted) > 0L && all(as.integer(fitted$observations) == n_obs),
                label = sprintf("%s: %s, column observations equals items x prompts x models x replicates x blocks = %d",
                                label, id, n_obs))
  }
}

# Results recomputed from the replicates with the mini-reference (ACC-5),
# tolerance ANK-TOL.arithmetic; the true values come from the scenario table.
acc_m1b_expect_results_recomputed <- function(res, rep, study, scenarios, label) {
  tol <- acc_m1b_arith_tol()
  for (id in scenarios) {
    truth <- acc_m1b_truth(acc_m1b_scenarios()[[id]])
    for (e in names(truth)) {
      rows <- rep[rep$scenario == id & rep$estimand == e, , drop = FALSE]
      if (nrow(rows) < 2L) {
        expect_gte(nrow(rows), 2L, label = sprintf("%s: %s, estimand %s - replications", label, id, e))
        next
      }
      ref <- acc_m1b_performance(as.numeric(rows$estimate), truth[[e]])
      if (study == "two_level" && e == acc_m1b_two_level_factor) {
        ref$derived_share <- acc_m1b_share(as.logical(rows$derived))
      }
      for (m in names(ref)) {
        row <- res[res$scenario == id & res$estimand == e & res$measure == m, , drop = FALSE]
        if (nrow(row) != 1L) {
          expect_identical(nrow(row), 1L, label = sprintf("%s: %s, %s, %s - row", label, id, e, m))
          next
        }
        for (k in c("value", "mcse")) {
          dev <- abs(as.numeric(row[[k]]) - ref[[m]][[k]])
          expect_true(is.finite(dev) && dev <= tol,
                      label = sprintf("%s: %s, estimand %s, measure %s, %s = %.15g, recomputed %.15g (|deviation| %.3g)",
                                      label, id, e, m, k, as.numeric(row[[k]]), ref[[m]][[k]], dev))
        }
      }
    }
  }
}

# Session file (docs/01 §5, §8; ACC-7): sessionInfo() with R and package
# versions, the seed(s) of the results, RNG kind and sample kind, runtime.
acc_m1b_expect_session <- function(path, res, study, label) {
  expect_true(file.exists(path), label = sprintf("%s: %s exists", label, basename(path)))
  if (!file.exists(path)) return(invisible())
  txt <- readLines(path, warn = FALSE)
  all <- paste(txt, collapse = "\n")
  expect_true(any(grepl("^R version [0-9]", trimws(txt))), label = sprintf("%s: names the R version (sessionInfo())", label))
  pkgs <- c("llmsa", "lme4", if (study != "binary_recovery") "ordinal")
  for (p in pkgs) {
    expect_true(grepl(paste0("(^|[^A-Za-z0-9.])", p, "_[0-9]"), all, perl = TRUE),
                label = sprintf("%s: names the version of %s", label, p))
  }
  expect_true(grepl("Mersenne-Twister", all, fixed = TRUE), label = sprintf("%s: names the RNG Mersenne-Twister", label))
  expect_true(grepl("Rejection", all, fixed = TRUE), label = sprintf("%s: names sample.kind Rejection", label))
  for (s in unique(suppressWarnings(as.numeric(res$seed)))) {
    if (!is.finite(s)) next
    token <- format(s, scientific = FALSE, trim = TRUE)
    expect_true(grepl(paste0("(^|[^0-9])", token, "([^0-9]|$)"), all), label = sprintf("%s: names the seed %s", label, token))
  }
  expect_true(grepl("runtime|elapsed", all, ignore.case = TRUE), label = sprintf("%s: names the runtime", label))
}

# Vignette (K-M1b-7) --------------------------------------------------------------------------

acc_m1b_section_title <- "Ordinal and binary outcomes (latent scale)"

# The results file the vignette has to read for a study (docs/02 K-M1b-7):
# <study>_results.csv of the package if present, else the short run.
acc_m1b_expected_results_path <- function(sim_dir, study) {
  full <- file.path(sim_dir, paste0(study, "_results.csv"))
  if (file.exists(full)) full else file.path(sim_dir, paste0(study, "_check_results.csv"))
}

# Number tokens of all table cells of a section.
acc_m1b_table_tokens <- function(section) {
  cells <- unlist(lapply(acc_m1a_tables(section), function(t) c(names(t), unlist(t, use.names = FALSE))))
  acc_m1a_numbers(cells[!is.na(cells)])
}

# TRUE if the written number `tok` shows `value` to the precision shown: equal,
# or at least two significant digits written and within one unit of the last
# written digit. One unit, not half a unit, because tables may round twice
# (knitr::kable rounds to `digits`, format() then rounds the column again);
# two digits so that a bare "0" or "1" never counts as showing a value.
acc_m1b_shows <- function(tok, value) {
  x <- suppressWarnings(as.numeric(tok))
  if (is.na(x) || !is.finite(value)) return(isTRUE(x == value))
  if (x == value) return(TRUE)
  mant <- sub("[eE].*$", "", sub("^[-+]", "", tok))
  significant <- nchar(sub("^0+", "", gsub("[^0-9]", "", mant)))
  if (significant < 2L) return(FALSE)
  expo <- if (grepl("[eE]", tok)) as.numeric(sub("^.*[eE]", "", tok)) else 0
  dec <- if (grepl("\\.", mant)) nchar(sub("^[^.]*\\.", "", mant)) else 0
  abs(x - value) <= 10^(expo - dec) * (1 + 1e-9) + 1e-15 * abs(value)
}

acc_m1b_shown <- function(tokens, value) any(vapply(tokens, acc_m1b_shows, logical(1), value = value))

# Bias and EmpSE with their MCSE of every scenario and estimand of a results
# file appear in the tables of the section (to the precision shown).
acc_m1b_expect_results_shown <- function(section, res, label) {
  tokens <- acc_m1b_table_tokens(section)
  text <- paste(section, collapse = "\n")
  for (id in unique(res$scenario)) {
    expect_true(grepl(id, text, fixed = TRUE), label = sprintf("%s: the section names scenario %s", label, id))
    rows <- res[res$scenario == id & res$measure %in% c("bias", "empse"), , drop = FALSE]
    expect_true(nrow(rows) > 0L, label = sprintf("%s: %s has bias and EmpSE rows in the results file", label, id))
    for (i in seq_len(nrow(rows))) {
      for (k in c("value", "mcse")) {
        v <- as.numeric(rows[[k]][i])
        expect_true(acc_m1b_shown(tokens, v),
                    label = sprintf("%s: %s, %s, %s %s (%s) appears in a table of the section", label, id,
                                    rows$estimand[i], rows$measure[i], k, format(v, digits = 15)))
      }
    }
  }
}

acc_m1b_expect_n_sim_shown <- function(section, res, label) {
  text <- paste(section, collapse = "\n")
  for (n in unique(as.integer(res$n_sim))) {
    digits <- as.character(n)
    sep <- if (nchar(digits) > 3L) {
      paste0(substr(digits, 1, nchar(digits) - 3L), "[ ,.'  ]?", substr(digits, nchar(digits) - 2L, nchar(digits)))
    } else digits
    expect_true(grepl(paste0("(^|[^0-9.])", sep, "([^0-9]|$)"), text, perl = TRUE),
                label = sprintf("%s: the section names n_sim = %d from the file", label, n))
  }
}
