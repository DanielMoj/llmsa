# Helpers for the M1c acceptance tests (docs/02-statistikkern.md, K-M1c-1 to
# K-M1c-8); a setup file for the reason given in setup-acceptance.R.
#
# Reference values come from reference/anchors/ (ANK-16, ANK-28, ANK-32,
# ANK-33, ANK-TOL) or from the oracles the criteria name: lme4::bootMer with an
# independently written FUN, called at test time on the same fit, and the
# direct ordinal::clmm call of K-M1b-1 (K-M1c-8); no package output is frozen.
# The scenarios of the coverage study and the iteration limits of K-M1c-8 are
# read at test time from docs/02-statistikkern.md (docs/01 §8 and ADR-041:
# specification, not anchors). The mini-references below are written
# independently of the package code from Formelsammlung §3 (gauge R&R
# statistics), §4 (latent residual) and §9 (percentile interval, performance
# measures of a simulation study).
# Interpretations of points on which the spec is silent are listed in
# orchestrator/handoff/M1c/CRITERIA.json under "open" (ACC-n). Test designs,
# seeds and the injected refit failures below are test parameters, not
# reference values.

acc_m1c <- new.env(parent = emptyenv())   # cache for one test run

# Anchors ----------------------------------------------------------------------------

acc_m1c_boot_tol <- function() as.numeric(acc_m1a_tol("engine_boot", "tol"))

# Random numbers ----------------------------------------------------------------------

# `expr` evaluated with the RNG of docs/01 §5 (Mersenne-Twister, Inversion,
# Rejection); the caller's RNG kind and state are restored. Seeds are passed to
# msa_boot() and lme4::bootMer() themselves.
acc_m1c_with_rng <- function(expr) {
  kind <- RNGkind()
  had <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (had) old <- get(".Random.seed", envir = globalenv())
  on.exit({
    RNGkind(kind[1], kind[2], kind[3])
    if (had) assign(".Random.seed", old, envir = globalenv())
    else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) rm(".Random.seed", envir = globalenv())
  }, add = TRUE)
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  expr
}

# Test designs (K-M1c-1, K-M1c-2, K-M1c-7) ---------------------------------------------

# Numeric study data from the model of Formelsammlung §2: a normal random
# effect for every named component (main effects and two-way interactions) and
# a normal residual; balanced crossed design.
acc_m1c_numeric_runs <- function(seed, items, prompts, models, reps, blocks, vc, mu = 10) {
  acc_m1a_with_seed(seed, {
    g <- expand.grid(rep = seq_len(reps), block = seq_len(blocks), model = seq_len(models),
                     prompt = seq_len(prompts), item = seq_len(items))
    y <- rep(mu, nrow(g))
    for (name in setdiff(names(vc), "Residual")) {
      factors <- strsplit(name, ":", fixed = TRUE)[[1]]
      groups <- interaction(g[factors], drop = TRUE, lex.order = TRUE)
      y <- y + stats::rnorm(nlevels(groups), 0, sqrt(vc[[name]]))[as.integer(groups)]
    }
    y <- y + stats::rnorm(nrow(g), 0, sqrt(vc[["Residual"]]))
    acc_m1a_runs(item = sprintf("I%02d", g$item), prompt = paste0("P", g$prompt), model = paste0("M", g$model),
                 rep = g$rep, value = y, block = g$block)
  })
}

acc_m1c_designs <- list(
  # K-M1c-1, K-M1c-2 (failures), K-M1c-7: all seven components, two blocks.
  numeric = list(type = "numeric", seed = 20261102L, items = 10L, prompts = 3L, models = 3L, reps = 2L, blocks = 2L,
                 vc = c(item = 1, prompt = 0.2, model = 0.2, block = 0.05, "item:prompt" = 0.05,
                        "item:model" = 0.05, "prompt:model" = 0.02, Residual = 0.1),
                 interactions = NULL),
  # K-M1c-1, K-M1c-7: logit model with item, prompt and model.
  binary = list(type = "binary", seed = 20261103L, items = 30L, prompts = 4L, models = 4L, reps = 2L, blocks = 1L,
                vc = list(item = 1, prompt = 0.5, model = 0.5), interactions = NULL),
  # K-M1c-2 (no failed and no singular replicate), K-M1c-7.
  zero = list(type = "numeric", seed = 20261105L, items = 12L, prompts = 5L, models = 5L, reps = 2L, blocks = 1L,
              vc = c(item = 1, prompt = 0.5, model = 0.5, Residual = 0.2), interactions = FALSE)
)

# Bootstrap runs of the tests: design, nsim, seed, level; for "failed" the
# refits that fail (K-M1c-2).
acc_m1c_boot_runs <- list(
  numeric = list(design = "numeric", nsim = 20L, seed = 101L),
  binary = list(design = "binary", nsim = 20L, seed = 202L),
  failed = list(design = "numeric", nsim = 20L, seed = 303L, level = 0.90, fail_at = c(2L, 7L, 15L)),
  zero = list(design = "zero", nsim = 20L, seed = 404L, level = 0.95)
)

acc_m1c_levels <- c(0.90, 0.95)   # docs/02 K-M1c-1: "für `level` 0,90 und 0,95"

acc_m1c_runs <- function(name) {
  d <- acc_m1c_designs[[name]]
  if (d$type == "binary") {
    acc_m1b_binary_runs(d$seed, items = d$items, prompts = d$prompts, models = d$models, reps = d$reps,
                        blocks = d$blocks, vc = d$vc)
  } else {
    acc_m1c_numeric_runs(d$seed, d$items, d$prompts, d$models, d$reps, d$blocks, d$vc)
  }
}

# Fit of the package under test on a test design, once per test run.
acc_m1c_fit <- function(name) {
  key <- paste0("fit_", name)
  if (is.null(acc_m1c[[key]])) {
    d <- acc_m1c_designs[[name]]
    runs <- acc_m1c_runs(name)
    fit <- acc_m1a_quiet(if (d$type == "binary") {
      msa_fit(runs, type = "binary", link = "logit", interactions = d$interactions)
    } else {
      msa_fit(runs, type = "numeric", interactions = d$interactions)
    })
    acc_m1c[[key]] <- fit
  }
  acc_m1c[[key]]
}

# Mini-reference: FUN for lme4::bootMer (K-M1c-1) --------------------------------------------
#
# Formelsammlung §3 with the components of lme4::VarCorr: EV = residual
# variance (numeric: the residual of VarCorr; binary: the latent residual of
# the link, Formelsammlung §4 and ANK-28), AV = prompt + model + block +
# item:prompt + item:model + prompt:model, GRR = EV + AV, PV = item,
# TV = GRR + PV; ndc with the constant and the lower bound of ANK-16. The names
# of the six statistics are those of msa_grr()$summary (?msa_grr). Two further
# elements serve the tests only: the unrounded ndc and the singular flag of the
# refit (lme4::isSingular() with its default tolerance, as msa_fit() records
# `singular` for lme4 models; ACC-2).

acc_m1c_av_terms <- c("prompt", "model", "block", "item:prompt", "item:model", "prompt:model")
acc_m1c_statistics <- c("grr_pct_study_var", "grr_pct_contribution", "repeatability_pct_study_var",
                        "reproducibility_pct_study_var", "ndc", "icc_items")

acc_m1c_reference_fun <- function(type, link) {
  k <- acc_m1a_ndc_constant()
  lower <- acc_m1a_ndc_minimum()
  latent <- if (type == "binary") acc_m1b_latent_residual(link) else NA_real_
  function(m) {
    v <- as.data.frame(lme4::VarCorr(m))
    comp <- stats::setNames(v$vcov, v$grp)
    ev <- if (type == "binary") latent else comp[["Residual"]]
    comp <- comp[names(comp) != "Residual"]
    unknown <- setdiff(names(comp), c("item", acc_m1c_av_terms))
    if (length(unknown)) stop("acceptance: unexpected variance component(s) ", paste(unknown, collapse = ", "), call. = FALSE)
    pv <- comp[["item"]]
    av <- sum(comp[names(comp) %in% acc_m1c_av_terms])
    grr <- ev + av
    tv <- grr + pv
    c(grr_pct_study_var = 100 * sqrt(grr / tv),
      grr_pct_contribution = 100 * grr / tv,
      repeatability_pct_study_var = 100 * sqrt(ev / tv),
      reproducibility_pct_study_var = 100 * sqrt(av / tv),
      ndc = max(lower, floor(k * sqrt(pv / grr))),
      icc_items = pv / tv,
      ndc_raw = k * sqrt(pv / grr),
      singular = as.numeric(lme4::isSingular(m)))
  }
}

# Percentile interval of Formelsammlung §9 from the finite replicates, with
# the quantile definition of stats::quantile() (type 7, the definition of the
# code status of §9; ACC-1).
acc_m1c_percentile <- function(x, level) {
  x <- x[is.finite(x)]
  a <- (1 - level) / 2
  stats::quantile(x, probs = c(a, 1 - a), type = 7, names = FALSE)
}

# Refit failures (K-M1c-2) ---------------------------------------------------------------------
#
# lme4::bootMer() refits the model once per replicate and turns an error of the
# refit into a replicate of NA values. The binding `refit` in the namespace of
# lme4 is replaced for the duration of `expr` by a wrapper that throws an error
# on the calls listed in `fail_at` and otherwise calls the original (ACC-2).
acc_m1c_with_failed_refits <- function(fail_at, expr) {
  original <- get("refit", envir = asNamespace("lme4"))
  calls <- 0L
  failing <- function(object, newresp = NULL, ...) {
    calls <<- calls + 1L
    if (calls %in% fail_at) stop("acceptance: injected refit failure (K-M1c-2)", call. = FALSE)
    original(object, newresp, ...)
  }
  testthat::local_mocked_bindings(refit = failing, .package = "lme4")
  expr
}

# Bootstrap runs ---------------------------------------------------------------------------------

# lme4::bootMer() with the mini-reference FUN on the model of `fit`, once per
# test run and run key; list(t0, t, warnings).
acc_m1c_reference_boot <- function(run) {
  key <- paste0("ref_", run)
  if (!is.null(acc_m1c[[key]])) return(acc_m1c[[key]])
  r <- acc_m1c_boot_runs[[run]]
  fit <- acc_m1c_fit(r$design)
  fun <- acc_m1c_reference_fun(fit$type, fit$link)
  call <- function() lme4::bootMer(fit$model, FUN = fun, nsim = r$nsim, seed = r$seed, type = "parametric")
  res <- acc_m1c_with_rng(acc_m1b_catch(if (is.null(r$fail_at)) call() else acc_m1c_with_failed_refits(r$fail_at, call())))
  if (inherits(res$value, "error")) {
    stop("acceptance: lme4::bootMer with the reference FUN failed (", run, "): ", conditionMessage(res$value), call. = FALSE)
  }
  out <- list(t0 = res$value$t0, t = res$value$t, warnings = res$warnings)
  acc_m1c[[key]] <- out
  out
}

# msa_boot() of the package under test, once per test run, run key and level;
# list(value, warnings) as from acc_m1b_catch(), value possibly an error.
acc_m1c_msa_boot <- function(run, level) {
  key <- sprintf("boot_%s_%s", run, format(level))
  if (!is.null(acc_m1c[[key]])) return(acc_m1c[[key]])
  r <- acc_m1c_boot_runs[[run]]
  fit <- acc_m1c_fit(r$design)
  call <- function() msa_boot(fit, nsim = r$nsim, level = level, seed = r$seed)
  res <- acc_m1c_with_rng(acc_m1b_catch(if (is.null(r$fail_at)) call() else acc_m1c_with_failed_refits(r$fail_at, call())))
  acc_m1c[[key]] <- res
  res
}

acc_m1c_boot_row <- function(b, statistic) {
  rows <- which(as.character(b$statistic) == statistic)
  if (length(rows) != 1L) return(NULL)
  list(estimate = as.numeric(b$estimate[rows]), lower = as.numeric(b$lower[rows]), upper = as.numeric(b$upper[rows]))
}

# The unrounded ndc of every replicate and of the original fit keeps a distance
# to the next integer, so that the floor of ndc cannot differ between two
# correct implementations by rounding of the last bit (docs/01 §2 Nr. 6: ndc
# equal; test data away from rounding limits).
acc_m1c_expect_ndc_away_from_integers <- function(ref, label) {
  raw <- c(ref$t0[["ndc_raw"]], ref$t[, "ndc_raw"])
  raw <- raw[is.finite(raw)]
  distance <- abs(raw - round(raw))
  expect_true(length(raw) > 0L && all(distance > 1e-9 * pmax(1, raw)),
              label = sprintf("%s: unrounded ndc of the test data away from integers (smallest distance %.3g)",
                              label, if (length(distance)) min(distance) else NA_real_))
}

# Quantiles and point estimates of msa_boot() equal the percentile interval of
# the reference replicates and t0 of the same lme4::bootMer() call: relative
# tolerance ANK-TOL.engine_boot for every statistic, the point estimate of ndc
# equal (docs/01 §2 Nr. 6).
acc_m1c_expect_quantiles <- function(b, ref, level, label) {
  tol <- acc_m1c_boot_tol()
  expect_setequal(as.character(b$statistic), acc_m1c_statistics)
  for (s in acc_m1c_statistics) {
    row <- acc_m1c_boot_row(b, s)
    expect_false(is.null(row), label = sprintf("%s: msa_boot() has exactly one row for %s", label, s))
    if (is.null(row)) next
    q <- acc_m1c_percentile(ref$t[, s], level)
    for (k in 1:2) {
      observed <- c(row$lower, row$upper)[k]
      expected <- q[k]
      dev <- abs(observed - expected)
      expect_true(is.finite(observed) && dev <= tol * abs(expected),
                  label = sprintf("%s, %s, %s quantile (level %s): msa_boot %.15g, bootMer %.15g (|deviation| %.3g)",
                                  label, s, c("lower", "upper")[k], format(level), observed, expected, dev))
    }
    expected <- ref$t0[[s]]
    if (s == "ndc") {
      expect_identical(row$estimate, as.numeric(expected), label = sprintf("%s: point estimate of ndc", label))
    } else {
      dev <- abs(row$estimate - expected)
      expect_true(is.finite(row$estimate) && dev <= tol * abs(expected),
                  label = sprintf("%s, %s: point estimate %.15g, t0 of bootMer %.15g (|deviation| %.3g)",
                                  label, s, row$estimate, expected, dev))
    }
  }
}

# Print wording (K-M1c-2, ACC-2) ----------------------------------------------------------------

acc_m1c_word_fail <- "fail|non-finite|nonfinite|not finite"
acc_m1c_word_drop <- "drop|discard|exclud|remov|omit"
acc_m1c_word_keep <- "retain|kept|keep|includ|remain"

# The count n as a number of its own: not part of a longer number or a
# decimal, a full stop at the end of a sentence allowed.
acc_m1c_has_count <- function(line, n) {
  grepl(paste0("(^|[^0-9.])", n, "(?:$|[^0-9.]|\\.(?:$|[^0-9]))"), line, perl = TRUE)
}

# Lines of the print output: one names the failed (non-finite) replicates with
# their number as dropped, one names the singular replicates with their number
# as retained, and no line calls singular replicates dropped.
acc_m1c_expect_counts_printed <- function(lines, n_failed, n_singular, label) {
  low <- tolower(lines)
  failed_line <- vapply(low, function(l) acc_m1c_has_count(l, n_failed) && grepl(acc_m1c_word_fail, l) &&
                          grepl(acc_m1c_word_drop, l) && !grepl("singular", l, fixed = TRUE), logical(1))
  singular_line <- vapply(low, function(l) acc_m1c_has_count(l, n_singular) && grepl("singular", l, fixed = TRUE) &&
                            grepl(acc_m1c_word_keep, l) && !grepl(acc_m1c_word_drop, l), logical(1))
  wrong <- vapply(low, function(l) grepl("singular", l, fixed = TRUE) && grepl(acc_m1c_word_drop, l), logical(1))
  out <- paste(lines, collapse = " | ")
  expect_true(any(failed_line),
              label = sprintf("%s: a line names %d failed (non-finite) replicates as dropped; output: %s", label, n_failed, out))
  expect_true(any(singular_line),
              label = sprintf("%s: a line names %d singular replicates as retained; output: %s", label, n_singular, out))
  expect_false(any(wrong), label = sprintf("%s: no line calls singular replicates dropped; output: %s", label, out))
}

# Coverage study (K-M1c-3, K-M1c-4; contract ACC-3 to ACC-9) ------------------------------------

acc_m1c_study <- "boot_coverage"
acc_m1c_check_scenarios <- c("S-boot-1", "S-boot-7")   # docs/02 K-M1c-3 and K-M1c-4
acc_m1c_nominal_level <- 0.95                           # docs/02 M1c: "95-%-Perzentilintervalle"
acc_m1c_interval_estimands <- c("grr_pct_study_var", "grr_pct_contribution", "ndc", "icc_items")
acc_m1c_point_measures <- c("bias", "rel_bias", "empse", "rmse")
acc_m1c_interval_measures <- c("coverage", "width")
acc_m1c_share_estimand <- "bootstrap"
acc_m1c_share_measures <- c("singular_share", "failed_share")
acc_m1c_replicate_columns <- c("scenario", "rep", "estimand", "estimate", "true", "lower", "upper",
                               "items", "prompts", "models", "blocks", "observations",
                               "boot_nsim", "boot_level", "n_singular", "n_failed")

acc_m1c_component_names <- c("Item×Prompt" = "item:prompt", "Item×Modell" = "item:model",
                             "Prompt×Modell" = "prompt:model", "Item" = "item", "Prompt" = "prompt",
                             "Modell" = "model", "Block" = "block", "Rest" = "Residual")

# One cell of the column "wahre Komponenten": parts separated by ";", either a
# reference ("wie S-boot-n", "sonst wie S-boot-n"), the outcome ("binär, Logit,
# μ = 0") or a component with its true value.
acc_m1c_parse_cell <- function(cell, known) {
  base <- list(type = "numeric", link = NA_character_, mu = 0, components = list())
  own <- list()
  for (p in trimws(strsplit(cell, ";", fixed = TRUE)[[1]])) {
    ref <- regmatches(p, regexec("^(sonst )?wie (S-boot-[0-9]+)$", p))[[1]]
    if (length(ref)) {
      if (is.null(known[[ref[3]]])) stop("acceptance: scenario ", ref[3], " referenced before it is defined", call. = FALSE)
      base <- known[[ref[3]]][c("type", "link", "mu", "components")]
      next
    }
    if (grepl("^binär", p)) {
      base$type <- "binary"
      base$link <- if (grepl("Logit", p, fixed = TRUE)) "logit" else if (grepl("Probit", p, fixed = TRUE)) "probit" else NA_character_
      mu <- regmatches(p, regexec("μ = (-?[0-9]+(,[0-9]+)?)", p))[[1]]
      base$mu <- if (length(mu)) acc_m1b_number(mu[2]) else NA_real_
      next
    }
    m <- regmatches(p, regexec("^(\\S+) (\\S+)$", p))[[1]]
    if (length(m) != 3L || !m[2] %in% names(acc_m1c_component_names)) {
      stop("acceptance: unreadable part in the scenario table of docs/02 (M1c): ", p, call. = FALSE)
    }
    own[[acc_m1c_component_names[[m[2]]]]] <- acc_m1b_number(m[3])
  }
  for (k in names(own)) base$components[[k]] <- own[[k]]
  base
}

# The scenario table of M1c as a list by scenario ID: outcome type, link, mu,
# design sizes and the true components. A binary scenario gets the latent
# residual of its link (ANK-28) as its residual; it is no estimand (ACC-5).
acc_m1c_scenarios <- function() {
  if (!is.null(acc_m1c$scenarios)) return(acc_m1c$scenarios)
  path <- file.path(acc_repo_root(), "docs", "02-statistikkern.md")
  if (!file.exists(path)) stop("acceptance: specification missing: ", path, call. = FALSE)
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  start <- grep("^## M1c", lines)
  end <- grep("^## M1d", lines)
  if (length(start) != 1L || length(end) != 1L || end <= start) stop("acceptance: section M1c not found in ", path, call. = FALSE)
  block <- lines[start:end]
  rows <- block[grepl("^\\|[[:space:]]*S-boot-[0-9]+[[:space:]]*\\|", block)]
  out <- list()
  for (row in rows) {
    cells <- acc_m1a_split_pipe(row)
    if (length(cells) != 7L) stop("acceptance: scenario row with ", length(cells), " cells: ", row, call. = FALSE)
    sizes <- suppressWarnings(as.integer(cells[2:6]))
    if (anyNA(sizes)) stop("acceptance: design sizes unreadable: ", row, call. = FALSE)
    parsed <- acc_m1c_parse_cell(cells[7], out)
    if (parsed$type == "binary") {
      if (is.na(parsed$link) || is.na(parsed$mu)) stop("acceptance: link or mu unreadable: ", row, call. = FALSE)
      parsed$components$Residual <- acc_m1b_latent_residual(parsed$link)
    }
    out[[cells[1]]] <- c(list(id = cells[1], items = sizes[1], prompts = sizes[2], models = sizes[3],
                              reps = sizes[4], blocks = sizes[5]), parsed)
  }
  acc_m1c$scenarios <- out
  out
}

# True values of the estimands of a scenario: every true component (for a
# binary scenario without the latent residual), and %GRR, % contribution GRR,
# ndc and ICC_items by Formelsammlung §3 with GRR = every component except the
# item component (residual included), TV = GRR + item; ndc with ANK-16.
acc_m1c_truth <- function(sc) {
  v <- unlist(sc$components)
  if (!all(c("item", "Residual") %in% names(v))) stop("acceptance: scenario ", sc$id, " lacks item or residual", call. = FALSE)
  pv <- v[["item"]]
  grr <- sum(v[names(v) != "item"])
  tv <- grr + pv
  components <- if (sc$type == "binary") v[names(v) != "Residual"] else v
  c(components,
    grr_pct_study_var = 100 * sqrt(grr / tv),
    grr_pct_contribution = 100 * grr / tv,
    ndc = max(acc_m1a_ndc_minimum(), floor(acc_m1a_ndc_constant() * sqrt(pv / grr))),
    icc_items = pv / tv)
}

# Required rows of a results file for one scenario: estimand, measure.
acc_m1c_required_rows <- function(sc) {
  rows <- list()
  for (e in names(acc_m1c_truth(sc))) {
    m <- c(acc_m1c_point_measures, if (e %in% acc_m1c_interval_estimands) acc_m1c_interval_measures)
    rows[[length(rows) + 1L]] <- data.frame(estimand = e, measure = m, stringsAsFactors = FALSE)
  }
  rows[[length(rows) + 1L]] <- data.frame(estimand = acc_m1c_share_estimand, measure = acc_m1c_share_measures,
                                          stringsAsFactors = FALSE)
  do.call(rbind, rows)
}

# Default number of bootstrap replicates of msa_boot() in the package under
# test (docs/02 M1c: "Bootstrap-Wiederholungen je Fit nach Paketvorgabe").
acc_m1c_default_nsim <- function() {
  f <- formals(get("msa_boot", envir = asNamespace(acc_pkg)))
  as.numeric(eval(f$nsim, envir = baseenv()))
}

# Schema of a results file (docs/01 §8, ACC-5): the seven columns, one row with
# finite value and finite nonnegative mcse for every scenario, estimand and
# measure, n_sim as given, a finite seed.
acc_m1c_expect_results_schema <- function(res, scenarios, n_sim, label) {
  absent <- setdiff(acc_m1b_result_columns, names(res))
  expect_identical(absent, character(), label = sprintf("%s: columns missing from the results file", label))
  if (length(absent)) return(invisible())
  expect_setequal(unique(res$scenario), scenarios)
  expect_true(all(is.finite(suppressWarnings(as.numeric(res$seed)))), label = sprintf("%s: every row has a finite seed", label))
  for (id in scenarios) {
    req <- acc_m1c_required_rows(acc_m1c_scenarios()[[id]])
    for (i in seq_len(nrow(req))) {
      row <- res[res$scenario == id & res$estimand == req$estimand[i] & res$measure == req$measure[i], , drop = FALSE]
      what <- sprintf("%s: %s, estimand %s, measure %s", label, id, req$estimand[i], req$measure[i])
      expect_identical(nrow(row), 1L, label = paste(what, "- number of rows"))
      if (nrow(row) != 1L) next
      expect_true(is.finite(as.numeric(row$value)), label = paste(what, "- finite value"))
      expect_true(is.finite(as.numeric(row$mcse)) && as.numeric(row$mcse) >= 0, label = paste(what, "- finite nonnegative mcse"))
      expect_equal(as.numeric(row$n_sim), as.numeric(n_sim), label = paste(what, "- n_sim"))
    }
  }
}

# Replicates against the scenario table (ACC-6): columns, one row per
# replication and estimand, the true values of the table, the design sizes of
# the table from the fitted model, the bootstrap settings and counts.
acc_m1c_expect_replicates_design <- function(rep, scenarios, n_sim, label) {
  absent <- setdiff(acc_m1c_replicate_columns, names(rep))
  expect_identical(absent, character(), label = sprintf("%s: columns missing from the replicates file", label))
  if (length(absent)) return(invisible())
  tol <- acc_m1b_arith_tol()
  b_default <- acc_m1c_default_nsim()
  for (id in scenarios) {
    sc <- acc_m1c_scenarios()[[id]]
    truth <- acc_m1c_truth(sc)
    expect_setequal(unique(rep$estimand[rep$scenario == id]), names(truth))
    for (e in names(truth)) {
      rows <- rep[rep$scenario == id & rep$estimand == e, , drop = FALSE]
      what <- sprintf("%s: %s, estimand %s", label, id, e)
      expect_setequal(as.integer(rows$rep), seq_len(n_sim))
      expect_identical(nrow(rows), as.integer(n_sim), label = paste(what, "- one row per replication"))
      expect_true(nrow(rows) > 0L && all(abs(as.numeric(rows$true) - truth[[e]]) <= tol),
                  label = sprintf("%s - column true equals the table value %.12g", what, truth[[e]]))
    }
    d <- rep[rep$scenario == id, , drop = FALSE]
    fitted <- d[!is.na(d$items), , drop = FALSE]
    expect_true(nrow(fitted) > 0L, label = sprintf("%s: %s has fitted replications", label, id))
    for (k in c("items", "prompts", "models", "blocks")) {
      expect_true(nrow(fitted) > 0L && all(as.integer(fitted[[k]]) == sc[[k]]),
                  label = sprintf("%s: %s, column %s equals the table value %d", label, id, k, sc[[k]]))
    }
    n_obs <- sc$items * sc$prompts * sc$models * sc$reps * sc$blocks
    expect_true(nrow(fitted) > 0L && all(as.integer(fitted$observations) == n_obs),
                label = sprintf("%s: %s, column observations equals items x prompts x models x replicates x blocks = %d",
                                label, id, n_obs))
    booted <- d[!is.na(d$boot_nsim), , drop = FALSE]
    expect_true(nrow(booted) > 0L, label = sprintf("%s: %s has bootstrapped replications", label, id))
    expect_true(nrow(booted) > 0L && all(as.numeric(booted$boot_nsim) == b_default),
                label = sprintf("%s: %s, boot_nsim equals the default nsim of msa_boot() (%s)", label, id, format(b_default)))
    expect_true(nrow(booted) > 0L && all(abs(as.numeric(booted$boot_level) - acc_m1c_nominal_level) <= tol),
                label = sprintf("%s: %s, boot_level equals %s", label, id, format(acc_m1c_nominal_level)))
    counts <- c(as.numeric(booted$n_singular), as.numeric(booted$n_failed))
    expect_true(nrow(booted) > 0L && all(is.finite(counts) & counts >= 0 & counts == round(counts)) &&
                  all(as.numeric(booted$n_singular) + as.numeric(booted$n_failed) <= as.numeric(booted$boot_nsim)),
                label = sprintf("%s: %s, n_singular and n_failed are counts within boot_nsim", label, id))
    per_rep <- unique(booted[c("rep", "boot_nsim", "boot_level", "n_singular", "n_failed")])
    expect_false(anyDuplicated(per_rep$rep) > 0L,
                 label = sprintf("%s: %s, bootstrap settings and counts agree across the rows of a replication", label, id))
    iv <- booted[booted$estimand %in% acc_m1c_interval_estimands & as.numeric(booted$n_failed) < as.numeric(booted$boot_nsim), , drop = FALSE]
    expect_true(nrow(iv) > 0L && all(is.finite(as.numeric(iv$lower)) & is.finite(as.numeric(iv$upper)) &
                                       as.numeric(iv$lower) <= as.numeric(iv$upper)),
                label = sprintf("%s: %s, interval estimands of bootstrapped replications have finite bounds, lower <= upper",
                                label, id))
  }
}

# Performance measures of the point estimates (ACC-5): the mini-reference of
# M1b (acc_m1b_performance(), Formelsammlung §9 and ADR-023 Nr. 5). An
# integer estimand such as ndc can equal its true value in every replication;
# then RMSE = 0, MCSE(MSE) = 0 and the delta formula MCSE(MSE) / (2 RMSE) is
# 0/0, so MCSE(RMSE) is 0 by convention.
acc_m1c_performance <- function(estimate, true) {
  p <- acc_m1b_performance(estimate, true)
  if (p$rmse[["value"]] == 0) p$rmse[["mcse"]] <- 0
  p
}

# Mean of per-replication values with the MCSE of a mean (Formelsammlung §9,
# MCSE(Bias) applied to the values; ACC-5).
acc_m1c_mean_mcse <- function(x) {
  x <- x[is.finite(x)]
  n <- length(x)
  if (n < 2L) stop("acceptance: fewer than two finite values", call. = FALSE)
  c(value = mean(x), mcse = sqrt(sum((x - mean(x))^2) / (n * (n - 1))))
}

# Coverage of the closed interval [lower, upper] over the replications with
# finite bounds; MCSE as in Formelsammlung §9 (ACC-5).
acc_m1c_coverage <- function(lower, upper, true) {
  ok <- is.finite(lower) & is.finite(upper)
  hit <- lower[ok] <= true[ok] & true[ok] <= upper[ok]
  n <- length(hit)
  if (n < 1L) stop("acceptance: no finite interval", call. = FALSE)
  p <- mean(hit)
  c(value = p, mcse = sqrt(p * (1 - p) / n))
}

# Every measure of a results file recomputed from its replicates with the
# mini-references (ACC-5), tolerance ANK-TOL.arithmetic; true values from the
# scenario table.
acc_m1c_expect_results_recomputed <- function(res, rep, scenarios, label) {
  tol <- acc_m1b_arith_tol()
  check <- function(id, e, m, ref) {
    row <- res[res$scenario == id & res$estimand == e & res$measure == m, , drop = FALSE]
    if (nrow(row) != 1L) {
      expect_identical(nrow(row), 1L, label = sprintf("%s: %s, %s, %s - row", label, id, e, m))
      return(invisible())
    }
    for (k in c("value", "mcse")) {
      dev <- abs(as.numeric(row[[k]]) - ref[[k]])
      expect_true(is.finite(dev) && dev <= tol,
                  label = sprintf("%s: %s, estimand %s, measure %s, %s = %.15g, recomputed %.15g (|deviation| %.3g)",
                                  label, id, e, m, k, as.numeric(row[[k]]), ref[[k]], dev))
    }
  }
  for (id in scenarios) {
    truth <- acc_m1c_truth(acc_m1c_scenarios()[[id]])
    for (e in names(truth)) {
      rows <- rep[rep$scenario == id & rep$estimand == e, , drop = FALSE]
      if (sum(is.finite(as.numeric(rows$estimate))) < 2L) {
        expect_gte(sum(is.finite(as.numeric(rows$estimate))), 2L,
                   label = sprintf("%s: %s, estimand %s - finite estimates", label, id, e))
        next
      }
      perf <- acc_m1c_performance(as.numeric(rows$estimate), truth[[e]])
      for (m in acc_m1c_point_measures) check(id, e, m, perf[[m]])
      if (e %in% acc_m1c_interval_estimands) {
        lower <- as.numeric(rows$lower)
        upper <- as.numeric(rows$upper)
        check(id, e, "coverage", acc_m1c_coverage(lower, upper, as.numeric(rows$true)))
        ok <- is.finite(lower) & is.finite(upper)
        check(id, e, "width", acc_m1c_mean_mcse(upper[ok] - lower[ok]))
      }
    }
    d <- rep[rep$scenario == id & !is.na(rep$boot_nsim), , drop = FALSE]
    per_rep <- d[!duplicated(d$rep), , drop = FALSE]
    b <- as.numeric(per_rep$boot_nsim)
    check(id, acc_m1c_share_estimand, "singular_share", acc_m1c_mean_mcse(as.numeric(per_rep$n_singular) / b))
    check(id, acc_m1c_share_estimand, "failed_share", acc_m1c_mean_mcse(as.numeric(per_rep$n_failed) / b))
  }
}

# Session file (docs/01 §5, §8; K-M1c-4; ACC-8): sessionInfo() with R and
# package versions, the seed(s) of the results, RNG kind and sample kind,
# runtime.
acc_m1c_expect_session <- function(path, res, label) {
  expect_true(file.exists(path), label = sprintf("%s: %s exists", label, basename(path)))
  if (!file.exists(path)) return(invisible())
  txt <- readLines(path, warn = FALSE)
  all <- paste(txt, collapse = "\n")
  expect_true(any(grepl("^R version [0-9]", trimws(txt))), label = sprintf("%s: names the R version (sessionInfo())", label))
  for (p in c("llmsa", "lme4")) {
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

# Script runs, once per test run (ACC-3): the short run rerun, the prefix run
# and the run over the scenarios outside the short run.
acc_m1c_script_run <- function(key, n_sim, scenarios) {
  cache <- paste0("run_", key)
  if (is.null(acc_m1c[[cache]])) acc_m1c[[cache]] <- acc_m1b_run_script(acc_m1c_study, n_sim, scenarios)
  acc_m1c[[cache]]
}

acc_m1c_rerun <- function() acc_m1c_script_run("rerun", acc_m1b_n_check(), acc_m1c_check_scenarios)

# Vignette (K-M1c-5; ACC-11) ---------------------------------------------------------------------

acc_m1c_section_title <- "Bootstrap intervals: coverage by scenario"

# TRUE if one row of one table shows all `values` (to the precision shown), or
# all of them times 100 (percent).
acc_m1c_row_shows <- function(tables, values) {
  for (t in tables) {
    for (i in seq_len(nrow(t))) {
      tokens <- acc_m1a_numbers(unlist(t[i, ], use.names = FALSE))
      tokens <- tokens[!is.na(tokens)]
      if (!length(tokens)) next
      for (scale in c(1, 100)) {
        if (all(vapply(values * scale, function(v) acc_m1b_shown(tokens, v), logical(1)))) return(TRUE)
      }
    }
  }
  FALSE
}

# Coverage with its MCSE of every scenario and interval estimand of a results
# file shown in one table row of the section; every scenario named.
acc_m1c_expect_coverage_shown <- function(section, res, label) {
  tables <- acc_m1a_tables(section)
  text <- paste(section, collapse = "\n")
  for (id in unique(res$scenario)) {
    expect_true(grepl(id, text, fixed = TRUE), label = sprintf("%s: the section names scenario %s", label, id))
    rows <- res[res$scenario == id & res$measure == "coverage", , drop = FALSE]
    expect_true(nrow(rows) > 0L, label = sprintf("%s: %s has coverage rows in the results file", label, id))
    for (i in seq_len(nrow(rows))) {
      v <- c(as.numeric(rows$value[i]), as.numeric(rows$mcse[i]))
      expect_true(acc_m1c_row_shows(tables, v),
                  label = sprintf("%s: %s, %s, coverage %s with MCSE %s appears in one table row of the section",
                                  label, id, rows$estimand[i], format(v[1], digits = 15), format(v[2], digits = 15)))
    }
  }
}

# K-M1c-7: note on the latent scale ------------------------------------------------------------

# The note quoted in docs/02 K-M1c-7 between „ and “.
acc_m1c_latent_note <- function() {
  if (!is.null(acc_m1c$note)) return(acc_m1c$note)
  path <- file.path(acc_repo_root(), "docs", "02-statistikkern.md")
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  line <- lines[startsWith(lines, "- **K-M1c-7:**")]
  if (length(line) != 1L) stop("acceptance: criterion K-M1c-7 not found in ", path, call. = FALSE)
  m <- regmatches(line, regexec("„([^“]+)“", line))[[1]]
  if (length(m) != 2L) stop("acceptance: the note of K-M1c-7 is not quoted in ", path, call. = FALSE)
  acc_m1c$note <- m[2]
  m[2]
}

# Text for comparison: Markdown escapes, code and emphasis markers and quotes
# removed, whitespace collapsed; an underscore inside a word (msa_agreement)
# stays.
acc_m1c_norm_text <- function(x) {
  x <- paste(x, collapse = " ")
  x <- gsub(" ", " ", x, fixed = TRUE)
  x <- gsub("\\\\([[:punct:]])", "\\1", x)
  for (ch in c("`", "*", "‘", "’", "“", "”", "„", "\"", "'")) x <- gsub(ch, "", x, fixed = TRUE)
  x <- gsub("(?<![[:alnum:]])_|_(?![[:alnum:]])", "", x, perl = TRUE)
  trimws(gsub("[[:space:]]+", " ", x))
}

acc_m1c_contains_note <- function(text) grepl(acc_m1c_norm_text(acc_m1c_latent_note()), acc_m1c_norm_text(text), fixed = TRUE)

acc_m1c_print_lines <- function(x) utils::capture.output(print(x))

# The report rendered by msa_report() as GitHub Markdown without line wrapping;
# once per test run and case.
acc_m1c_report_lines <- function(key, grr) {
  cache <- paste0("report_", key)
  if (!is.null(acc_m1c[[cache]])) return(acc_m1c[[cache]])
  out <- tempfile("acc-m1c-report-", fileext = ".md")
  res <- acc_m1b_catch(msa_report(grr, output_file = out, quiet = TRUE,
                                  output_format = rmarkdown::md_document(variant = "gfm", pandoc_args = "--wrap=none")))
  value <- if (inherits(res$value, "error")) res$value else readLines(out, warn = FALSE, encoding = "UTF-8")
  acc_m1c[[cache]] <- value
  value
}

# Lines of section 3 ("Precision") of a rendered report.
acc_m1c_report_precision <- function(lines) {
  header <- grepl("^#{1,6}[[:space:]]", lines)
  start <- which(header & grepl("^#{1,6}[[:space:]]+3\\.", lines))
  if (length(start) != 1L) return(NULL)
  stop_at <- which(header & seq_along(lines) > start)
  end <- if (length(stop_at)) stop_at[1] - 1L else length(lines)
  lines[seq(start, end)]
}

# The block directly below the line with Repeatability and Reproducibility
# (not the section header, which names both): the next nonblank line and its
# continuation lines (up to a blank line, a header or the next list item).
acc_m1c_block_below_rr <- function(section) {
  hit <- which(!grepl("^#", section) & grepl("repeatability", section, ignore.case = TRUE) &
                 grepl("reproducibility", section, ignore.case = TRUE))
  if (length(hit) != 1L) return(NULL)
  i <- hit + 1L
  while (i <= length(section) && !nzchar(trimws(section[i]))) i <- i + 1L
  if (i > length(section)) return(character())
  block <- section[i]
  j <- i + 1L
  item <- "^[[:space:]]*([-*+]|[0-9]+\\.)[[:space:]]"
  while (j <= length(section) && nzchar(trimws(section[j])) && !grepl("^#", section[j]) && !grepl(item, section[j])) {
    block <- c(block, section[j])
    j <- j + 1L
  }
  block
}

# Byte equality with done/M1b (K-M1c-7; ACC-13) ------------------------------------------------
#
# R/fit.R and R/grr.R of the revision named in ANK-33 (the tag done/M1b, the
# state before M1c; ADR-038, ADR-039), read with git cat-file into a temporary
# file, never into the working tree, checked against the SHA-256 of ANK-33 and
# sourced into one environment whose parent is the namespace under test (for
# helpers outside these two files, which the compared calculations do not use).

acc_m1c_baseline_text <- function(ref, path) {
  blob <- tempfile("acc-m1c-baseline-", fileext = ".R")
  read <- acc_git(acc_repo_root(), "cat-file", "blob", paste0(ref, ":", path), stdout_file = blob)
  if (read$status != 0L) {
    stop("acceptance: git cat-file ", ref, ":", path, " failed: ", paste(read$stderr, collapse = " "), call. = FALSE)
  }
  blob
}

acc_m1c_baseline <- function() {
  if (!is.null(acc_m1c$baseline)) return(acc_m1c$baseline)
  value <- acc_anchor("ANK-33")$value
  env <- new.env(parent = asNamespace(acc_pkg))
  for (path in names(value$files)) {
    file <- acc_m1c_baseline_text(value$ref, path)
    if (!identical(acc_sha256(file), value$files[[path]]$sha256)) {
      stop("acceptance: ", value$ref, ":", path, " does not carry the SHA-256 of ANK-33", call. = FALSE)
    }
    sys.source(file, envir = env, keep.source = FALSE)
    unlink(file)
  }
  acc_m1c$baseline <- env
  env
}

acc_m1c_grr_parts <- c("table", "summary", "verdict")

# The parts of an msa_boot() result that K-M1c-7 keeps byte-identical: the
# data.frame (names, columns, row names, class) and the attributes boot and
# level; n_failed and n_singular belong to K-M1c-2 (ACC-13).
acc_m1c_boot_core <- function(b) {
  list(names = names(b), class = class(b), row_names = attr(b, "row.names"),
       columns = lapply(stats::setNames(names(b), names(b)), function(n) b[[n]]),
       boot = attr(b, "boot"), level = attr(b, "level"))
}

# Fits for the comparison of msa_grr(), with arguments, once per test run.
acc_m1c_grr_cases <- function() {
  if (!is.null(acc_m1c$grr_cases)) return(acc_m1c$grr_cases)
  ic50 <- acc_m1a_quiet(msa_fit(acc_m1a_dataset("ic50_demo"), type = "numeric"))
  two <- suppressWarnings(acc_m1a_quiet(msa_fit(acc_m1b_ordinal_runs(20261108L, items = 12L, models = 2L),
                                                type = "ordinal", levels = acc_m1b_ordinal_levels(), link = "probit")))
  cases <- list(
    "numeric ic50_demo" = list(fit = ic50, args = list()),
    "numeric ic50_demo, basis contribution" = list(fit = ic50, args = list(basis = "contribution")),
    "numeric test design" = list(fit = acc_m1c_fit("numeric"), args = list()),
    "numeric test design without interactions" = list(fit = acc_m1c_fit("zero"), args = list()),
    "ordinal wine, probit" = list(fit = acc_m1b_wine_fit("probit"), args = list()),
    "ordinal wine, logit" = list(fit = acc_m1b_wine_fit("logit"), args = list()),
    "ordinal with two models (derived)" = list(fit = two, args = list()),
    "binary BeetlesMale" = list(fit = acc_m1b_beetles_fit(), args = list()),
    "binary test design, thresholds 5 and 50" = list(fit = acc_m1c_fit("binary"), args = list(threshold = c(5, 50)))
  )
  acc_m1c$grr_cases <- cases
  cases
}

# Gate configuration (K-M1c-6; ACC-12) ------------------------------------------------------------

# Value of a shell assignment KEY=value in orchestrator/config.env; the last
# assignment wins, quotes and trailing comments removed; NULL if absent.
acc_m1c_config_value <- function(key) {
  path <- file.path(acc_repo_root(), "orchestrator", "config.env")
  if (!file.exists(path)) stop("acceptance: missing ", path, call. = FALSE)
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  hit <- grep(paste0("^[[:space:]]*(export[[:space:]]+)?", key, "="), lines, value = TRUE)
  if (!length(hit)) return(NULL)
  v <- sub(paste0("^[[:space:]]*(export[[:space:]]+)?", key, "="), "", hit[length(hit)])
  if (startsWith(v, "'")) return(sub("^'([^']*)'.*$", "\\1", v))
  if (startsWith(v, "\"")) return(sub("^\"([^\"]*)\".*$", "\\1", v))
  sub("[[:space:]].*$", "", v)
}

# K-M1c-8: iteration limit of the ordinal default path (ADR-041; ACC-18 to ACC-20) ---------------
#
# The limits are read at test time from the criterion in docs/02 (values of
# the specification and of ADR-041 Nr. 1, not empirical anchors; like the note
# of K-M1c-7). The oracle is ordinal::clmm itself: the control a fit stores
# in `$control` (after clmm has processed its `control` and `...`) is compared
# with the control stored by a direct clmm call with the argument the
# criterion requires.

# The line of a criterion in docs/02.
acc_m1c_criterion_line <- function(id) {
  path <- file.path(acc_repo_root(), "docs", "02-statistikkern.md")
  if (!file.exists(path)) stop("acceptance: specification missing: ", path, call. = FALSE)
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  line <- lines[startsWith(lines, paste0("- **", id, ":**"))]
  if (length(line) != 1L) stop("acceptance: criterion ", id, " not found in ", path, call. = FALSE)
  line
}

# iter.max and eval.max of the code span `control = ordinal::clmm.control(
# iter.max = <n>, eval.max = <m>)` in K-M1c-8; any other form stops the test.
acc_m1c_8_limits <- function() {
  if (!is.null(acc_m1c$limits)) return(acc_m1c$limits)
  line <- acc_m1c_criterion_line("K-M1c-8")
  spans <- gsub("`", "", regmatches(line, gregexpr("`[^`]+`", line))[[1]], fixed = TRUE)
  form <- "^control = ordinal::clmm\\.control\\(iter\\.max = ([0-9]+), eval\\.max = ([0-9]+)\\)$"
  hits <- Filter(length, regmatches(spans, regexec(form, spans)))
  if (length(hits) != 1L) {
    stop("acceptance: K-M1c-8 in docs/02 does not name exactly one ",
         "`control = ordinal::clmm.control(iter.max = <n>, eval.max = <m>)`", call. = FALSE)
  }
  out <- c(iter.max = as.numeric(hits[[1]][2]), eval.max = as.numeric(hits[[1]][3]))
  acc_m1c$limits <- out
  out
}

# Mini-reference of the rule of K-M1c-8: the control argument ordinal::clmm
# must receive. Without `control` among the arguments of msa_fit(), the
# limits of docs/02; with `control`, exactly the value of the call.
acc_m1c_8_required_control <- function(args) {
  if ("control" %in% names(args)) return(args[["control"]])
  l <- acc_m1c_8_limits()
  ordinal::clmm.control(iter.max = l[["iter.max"]], eval.max = l[["eval.max"]])
}

# The control a clmm fit stores, with list elements and optimizer options
# (optCtrl) ordered by name; expect_equal(tolerance = 0) then compares the
# values regardless of option order and of integer or double storage.
acc_m1c_8_control_form <- function(control) {
  if (!is.list(control) || is.null(names(control))) return(control)
  if (is.list(control$optCtrl) && length(control$optCtrl)) {
    control$optCtrl <- control$optCtrl[order(names(control$optCtrl))]
  }
  control[order(names(control))]
}

# The direct call of K-M1b-1 on ordinal::wine, with a control argument if one
# is given; used as the oracle.
acc_m1c_8_direct_wine <- function(link, control = NULL) {
  args <- list(rating ~ 1 + (1 | bottle) + (1 | judge), data = acc_m1b_wine(), link = link)
  if (!is.null(control)) args["control"] <- list(control)
  do.call(ordinal::clmm, args)
}

# Components of a direct wine fit in the roles of llmsa (item = bottle,
# prompt = judge) with the latent residual of ANK-28.
acc_m1c_8_wine_reference <- function(direct, link) {
  v <- acc_m1b_clmm_components(direct)
  c(item = v[["bottle"]], prompt = v[["judge"]], Residual = acc_m1b_latent_residual(link))
}

# `expr` evaluated while every call of ordinal::clmm is recorded: the binding
# in the namespace of ordinal is replaced for the duration of this function by
# a wrapper that evaluates the same call in the same calling frame with the
# original function and records the control stored by each fit (ACC-18).
# Returns list(value, warnings, controls).
acc_m1c_8_record_clmm <- function(expr) {
  original <- get("clmm", envir = asNamespace("ordinal"))
  controls <- list()
  recorder <- function(...) {
    call <- sys.call()
    call[[1L]] <- original
    model <- eval(call, parent.frame())
    controls[length(controls) + 1L] <<- list(model$control)
    model
  }
  testthat::local_mocked_bindings(clmm = recorder, .package = "ordinal")
  res <- acc_m1b_catch(expr)
  c(res, list(controls = controls))
}

# msa_fit() on wine (item = bottle, prompt = judge, one replicate; K-M1b-1)
# with the further arguments `args`, every call of ordinal::clmm recorded.
acc_m1c_8_wine_fit <- function(link, args = list()) {
  acc_m1c_8_record_clmm(do.call(msa_fit, c(list(acc_m1b_wine_runs(), type = "ordinal",
                                                 levels = acc_m1b_wine_levels(), link = link), args)))
}

# Every recorded clmm call and the model of the returned fit store the
# control `expected` (a stored control in the form of acc_m1c_8_control_form()).
acc_m1c_8_expect_controls <- function(rec, expected, label) {
  expect_false(inherits(rec$value, "error"),
               label = sprintf("%s: msa_fit() runs (%s)", label,
                               if (inherits(rec$value, "error")) conditionMessage(rec$value) else "ok"))
  expect_gte(length(rec$controls), 1L, label = sprintf("%s: number of recorded calls of ordinal::clmm", label))
  for (i in seq_along(rec$controls)) {
    expect_equal(acc_m1c_8_control_form(rec$controls[[i]]), expected, tolerance = 0,
                 label = sprintf("%s: control stored by call %d of ordinal::clmm", label, i),
                 expected.label = "the control of the direct call with the required argument")
  }
  if (inherits(rec$value, "msa_fit")) {
    expect_equal(acc_m1c_8_control_form(rec$value$model$control), expected, tolerance = 0,
                 label = sprintf("%s: fit$model$control", label),
                 expected.label = "the control of the direct call with the required argument")
  }
}

# Plain text of a help page for the K-M1c-8 checks: acc_m1b_rd_text() without
# quote characters, so that \code{iter.max = 2000} reads iter.max = 2000.
acc_m1c_8_rd_plain <- function(name) {
  x <- acc_m1b_rd_text(name)
  for (ch in c("'", "\"", "`", "‘", "’", "“", "”")) x <- gsub(ch, "", x, fixed = TRUE)
  x
}

# A limit named as `<name> = <value>` (spaces free; ":" or "of" also accepted).
acc_m1c_8_limit_pattern <- function(name, value) {
  paste0("(?<![[:alnum:]_.])", gsub(".", "\\.", name, fixed = TRUE), "\\s*(?:=|:|\\bof\\b)?\\s*",
         format(value, scientific = FALSE), "(?![0-9])")
}

acc_m1c_8_word_replace <- "replac|overrid|supersed|instead|precedence"

# Sentences of a plain text: split after ".", "!" or "?" before an upper-case
# letter or an opening bracket.
acc_m1c_8_sentences <- function(text) strsplit(text, "(?<=[.!?])\\s+(?=[[:upper:](])", perl = TRUE)[[1]]

# The value of a field "key: value" of a session file of the class-B studies
# (format llmsa-class-b-v1); NA unless exactly one line carries the key.
acc_m1c_8_session_field <- function(path, key) {
  lines <- readLines(path, warn = FALSE)
  hit <- lines[startsWith(lines, paste0(key, ": "))]
  if (length(hit) != 1L) return(NA_character_)
  substring(hit, nchar(key) + 3L)
}
