# Helpers shared by the class A simulations (docs/01 §8; reviewer territory via
# REVIEWER_EXTRA_PATHS_REGEX). The tests gate runs this folder with
# testthat::test_dir(load_package = "source") from the repository root; the
# folder is not part of MUT_TEST_DIRS. A setup file, not a helper file, for the
# reason given in tests/acceptance/setup-acceptance.R.
#
# Reference values come from reference/anchors/ only (AGENTS.md, integrity
# rule 7); seeds, RNG, versions and runtime are reported in a message of each
# test (docs/01 §5 and §8).

sim_is_repo_root <- function(dir) {
  file.exists(file.path(dir, "DESCRIPTION")) && dir.exists(file.path(dir, "reference", "anchors"))
}

# Repository root: the nearest directory above the working directory that holds
# DESCRIPTION and reference/anchors/; otherwise REPO_ROOT (gate runner).
sim_repo_root <- function() {
  dir <- normalizePath(getwd(), mustWork = TRUE)
  repeat {
    if (sim_is_repo_root(dir)) return(dir)
    parent <- dirname(dir)
    if (identical(parent, dir)) break
    dir <- parent
  }
  env_root <- Sys.getenv("REPO_ROOT", "")
  if (nzchar(env_root) && sim_is_repo_root(env_root)) return(normalizePath(env_root, mustWork = TRUE))
  stop("simulation: no repository root with reference/anchors/ above ", getwd(),
       ", and REPO_ROOT does not point to one", call. = FALSE)
}

sim_anchor <- function(id) {
  path <- file.path(sim_repo_root(), "reference", "anchors", paste0(id, ".json"))
  if (!file.exists(path)) stop("simulation: anchor file missing: ", path, call. = FALSE)
  anchor <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  if (!identical(anchor$id, id)) stop("simulation: ", path, " carries the id ", format(anchor$id), call. = FALSE)
  anchor
}

# Nested value of an anchor; a missing value stops the test.
sim_value <- function(id, ...) {
  path <- c(...)
  v <- sim_anchor(id)$value
  for (k in path) {
    v <- v[[k]]
    if (is.null(v)) stop("simulation: ", id, " has no value ", paste(path, collapse = "$"), call. = FALSE)
  }
  v
}

sim_tol <- function(entry, key) sim_value("ANK-TOL", entry, key)

# RNG of docs/01 §5 (Mersenne-Twister, sample.kind = "Rejection").
sim_rng_kind <- c("Mersenne-Twister", "Inversion", "Rejection")

# Seeded block with sim_rng_kind; the caller's RNG state is restored.
sim_with_seed <- function(seed, expr) {
  kind <- RNGkind()
  had <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (had) old <- get(".Random.seed", envir = globalenv())
  on.exit({
    RNGkind(kind[1], kind[2], kind[3])
    if (had) assign(".Random.seed", old, envir = globalenv())
    else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) rm(".Random.seed", envir = globalenv())
  }, add = TRUE)
  RNGkind(sim_rng_kind[1], sim_rng_kind[2], sim_rng_kind[3])
  set.seed(seed)
  expr
}

# Monte Carlo standard errors (Formelsammlung §9, after Morris, White & Crowther
# 2019, Tab. 6): of a mean of per-replicate values (the formula of MCSE(Bias)),
# and of a proportion (the formula of MCSE(Coverage)).
sim_mcse_mean <- function(x) stats::sd(x) / sqrt(length(x))
sim_mcse_prop <- function(p, n_sim) sqrt(p * (1 - p) / n_sim)

sim_session_note <- function(seed) {
  paste0("seed ", seed, ", RNG ", paste(sim_rng_kind, collapse = "/"), ", ", R.version.string,
         ", llmsa ", as.character(utils::packageVersion("llmsa")))
}

# The acceptance helpers of M3c (mini-reference of the Westgard rules,
# candidate plans, vignette knit and table) in an environment of their own:
# tests/acceptance/setup-acceptance.R, setup-m1a.R, setup-m3a.R and setup-m3c.R
# (reviewer territory), read once per test run.
sim_m3c_env <- local({
  env <- NULL
  function() {
    if (is.null(env)) {
      e <- new.env(parent = globalenv())
      dir <- file.path(sim_repo_root(), "tests", "acceptance")
      for (f in c("setup-acceptance.R", "setup-m1a.R", "setup-m3a.R", "setup-m3c.R")) sys.source(file.path(dir, f), envir = e)
      env <<- e
    }
    env
  }
})

# Runs fun(i) for i in `index` with parallel::mclapply (allowed in
# tests/simulation, docs/01 §5); an error in a worker stops the test with its
# message instead of returning a try-error.
sim_parallel <- function(index, fun, cores = 14L) {
  out <- parallel::mclapply(index, function(i) tryCatch(fun(i), error = function(e) structure(conditionMessage(e), class = "sim_error")),
                            mc.cores = cores)
  failed <- vapply(out, function(x) inherits(x, "sim_error") || inherits(x, "try-error"), logical(1))
  if (any(failed)) stop("simulation: worker failed: ", as.character(out[[which(failed)[1]]]), call. = FALSE)
  out
}
