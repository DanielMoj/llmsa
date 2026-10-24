# Helpers shared by the acceptance tests (reviewer territory, see AGENTS.md).
#
# The file is named setup-*.R, not helper-*.R: with load_package = "source"
# testthat 3.3 leaves helper files to pkgload::load_all(), which reads them from
# tests/testthat/ only, while setup files of the test folder are sourced in every
# loading mode.
#
# The acceptance tests run in two settings:
# - the tests gate (orchestrator/lib/r-tests.R): working directory
#   tests/acceptance inside the repository, package loaded from source;
# - the mutation gates (orchestrator/lib/r-mutation.R): a temporary package
#   copy that holds only DESCRIPTION, NAMESPACE, R/, inst/, data/ and the test
#   folders; the mutated package is loaded from that copy.
# The package under test is therefore always the loaded namespace, while
# repository files outside the copy (reference/anchors/, docs/, orchestrator/,
# .git) are always read from the repository root. Looked up in the copy, they
# would be missing, every acceptance test would fail for every mutant, and the
# mutation score would count mutants as killed that no test detected.

acc_pkg <- "llmsa"

acc_is_repo_root <- function(dir) {
  file.exists(file.path(dir, "DESCRIPTION")) &&
    dir.exists(file.path(dir, "reference", "anchors"))
}

# Repository root: the nearest directory above the working directory that holds
# DESCRIPTION and reference/anchors/; otherwise REPO_ROOT, which the gate runner
# orchestrator/verifier.sh exports to every gate.
acc_repo_root <- function() {
  dir <- normalizePath(getwd(), mustWork = TRUE)
  repeat {
    if (acc_is_repo_root(dir)) return(dir)
    parent <- dirname(dir)
    if (identical(parent, dir)) break
    dir <- parent
  }
  env_root <- Sys.getenv("REPO_ROOT", "")
  if (nzchar(env_root) && acc_is_repo_root(env_root)) {
    return(normalizePath(env_root, mustWork = TRUE))
  }
  stop("acceptance: no repository root with reference/anchors/ above ", getwd(),
       ", and REPO_ROOT does not point to one", call. = FALSE)
}

# Directory the loaded package under test comes from (the source directory
# after pkgload::load_all(), the installation directory otherwise).
acc_pkg_root <- function() {
  if (!isNamespaceLoaded(acc_pkg)) {
    stop("acceptance: package ", acc_pkg, " is not loaded; run the tests with ",
         "testthat::test_dir(load_package = \"source\")", call. = FALSE)
  }
  normalizePath(getNamespaceInfo(asNamespace(acc_pkg), "path"), mustWork = TRUE)
}

# Fields every anchor carries (reference/anchors/README.md).
acc_anchor_fields <- c("id", "value", "unit", "tolerance", "source_url", "quote", "retrieved")

# Reads reference/anchors/<id>.json; reference values come only from there
# (AGENTS.md, integrity rule 7).
acc_anchor <- function(id) {
  path <- file.path(acc_repo_root(), "reference", "anchors", paste0(id, ".json"))
  if (!file.exists(path)) stop("acceptance: anchor file missing: ", path, call. = FALSE)
  anchor <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  absent <- setdiff(acc_anchor_fields, names(anchor))
  if (length(absent)) {
    stop("acceptance: anchor ", id, " lacks ", paste(absent, collapse = ", "), call. = FALSE)
  }
  if (!identical(anchor$id, id)) {
    stop("acceptance: ", path, " carries the id ", format(anchor$id), call. = FALSE)
  }
  anchor
}

# Runs a command and returns its exit status with stdout and stderr as lines.
# `args` and the values in `env` ("NAME=value") must be quoted by the caller.
# With `stdout_file`, stdout goes byte for byte to that file instead.
acc_run <- function(command, args = character(), env = character(), stdout_file = NULL) {
  out <- if (is.null(stdout_file)) tempfile("acc-stdout-") else stdout_file
  err <- tempfile("acc-stderr-")
  on.exit(unlink(c(err, if (is.null(stdout_file)) out)), add = TRUE)
  status <- suppressWarnings(system2(command, args, stdout = out, stderr = err, env = env))
  list(
    status = as.integer(status),
    stdout = if (is.null(stdout_file)) readLines(out, warn = FALSE) else character(),
    stderr = readLines(err, warn = FALSE)
  )
}

# git with the repository root as working directory.
acc_git <- function(root, ..., stdout_file = NULL) {
  acc_run("git", shQuote(c("-C", root, ...)), stdout_file = stdout_file)
}

acc_sha256 <- function(paths) {
  if (!exists("sha256sum", envir = asNamespace("tools"), inherits = FALSE)) {
    stop("acceptance: tools::sha256sum() is missing in R ", getRversion(), call. = FALSE)
  }
  unname(tools::sha256sum(paths))
}

# TRUE once the orchestrator has completed milestone `ms`: it writes
# orchestrator/state/<ms>/8-done.done and commits it before the tag done/<ms>.
acc_milestone_done <- function(ms) {
  file.exists(file.path(acc_repo_root(), "orchestrator", "state", ms, "8-done.done"))
}
