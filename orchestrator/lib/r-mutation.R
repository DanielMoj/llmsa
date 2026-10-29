#!/usr/bin/env Rscript
# Mutationsadapter für orchestrator/gates.d/86-mutgate.sh (Preset r-paket, MUT_CMD).
# Mutiert mit dem CRAN-Paket muttest die geänderten R-Dateien aus MUT_FILES in einer schlanken
# Paketkopie außerhalb des Repos und schreibt den muttest-Bericht nach MUT_REPORT, unverändert bis
# auf den Status von Mutanten über dem Zeitlimit (RuntimeError -> Timeout, siehe unten).
# Der Bericht folgt dem Stryker-Schema (files -> mutants mit status, mutatorName, location);
# das Urteil (Score, Floor, Ratchet, Äquivalenz) fällt allein in 86-mutgate.
# Exit 0 = Lauf beendet und Bericht geschrieben, 2 = Infrastruktur (dann fehlt der Bericht und
# 86-mutgate meldet error). Liegt im Betreiber-Territorium.
#
# Umgebung: MUT_FILES (kommagetrennt, von 86-mutgate), MUT_REPORT, REPO_ROOT,
# MUT_TEST_DIRS (Vorgabe: die vier Testordner der Rollen), MUT_WORKERS (Vorgabe 1),
# MUT_R_MUTATORS (kommagetrennte muttest-Funktionen ohne Argumente),
# MUT_TEST_EXCLUDE (regulärer Ausdruck auf den Testnamen, also den Dateinamen ohne "test-" und
# ".R" wie bei testthat::test_dir(filter); passende Testdateien laufen nicht; leer = keine Ausnahme),
# MUT_TEST_TIMEOUT (Zeitlimit je Mutant in Sekunden; leer = ohne Grenze).

say <- function(...) cat("r-mutation: ", ..., "\n", sep = "")
infra <- function(...) {
  message("r-mutation: ", ...)
  quit(save = "no", status = 2)
}

for (pkg in c("muttest", "testthat", "pkgload", "R6", "jsonlite", "callr")) {
  if (!requireNamespace(pkg, quietly = TRUE)) infra("R-Paket fehlt: ", pkg)
}

env_list <- function(name, default, split) {
  value <- Sys.getenv(name, default)
  items <- trimws(strsplit(value, split)[[1]])
  items[nzchar(items)]
}
repo <- normalizePath(Sys.getenv("REPO_ROOT", getwd()), mustWork = TRUE)
if (!file.exists(file.path(repo, "DESCRIPTION"))) infra("DESCRIPTION fehlt in ", repo)
report <- Sys.getenv("MUT_REPORT", "reports/mutation/mutation.json")
if (!grepl("^/", report)) report <- file.path(repo, report)
test_dirs <- env_list("MUT_TEST_DIRS", "tests/testthat tests/acceptance tests/e2e tests/fuzz", "[[:space:]]+")
test_dirs <- test_dirs[dir.exists(file.path(repo, test_dirs))]
if (!length(test_dirs)) infra("kein Testordner vorhanden: ", Sys.getenv("MUT_TEST_DIRS"))
workers <- suppressWarnings(as.integer(Sys.getenv("MUT_WORKERS", "1")))
if (is.na(workers) || workers < 1L) infra("MUT_WORKERS muss eine positive Ganzzahl sein")
exclude <- Sys.getenv("MUT_TEST_EXCLUDE", "")
if (nzchar(exclude) && inherits(try(grepl(exclude, ""), silent = TRUE), "try-error")) {
  infra("MUT_TEST_EXCLUDE ist kein gültiger regulärer Ausdruck: ", exclude)
}
timeout <- if (nzchar(Sys.getenv("MUT_TEST_TIMEOUT"))) suppressWarnings(as.numeric(Sys.getenv("MUT_TEST_TIMEOUT"))) else Inf
if (is.na(timeout) || timeout <= 0) infra("MUT_TEST_TIMEOUT muss eine positive Zahl von Sekunden sein")
mutator_names <- env_list(
  "MUT_R_MUTATORS",
  paste(
    "arithmetic_operators", "comparison_operators", "logical_operators", "boolean_literals",
    "condition_mutations", "numeric_literals", "na_literals", "string_literals",
    "index_mutations", sep = ","
  ),
  ","
)

files <- env_list("MUT_FILES", "", ",")
files <- files[grepl("^R/[^/]+\\.[Rr]$", files) & file.exists(file.path(repo, files))]

# Schlanke Paketkopie: nur, was Laden und Testen brauchen; das Harness bleibt außen vor.
# tests/fixtures/ gehört dazu: Ohne die Aufzeichnungen brechen Tests mit Fehler ab, und muttest
# führt dann jeden Mutanten, den kein Test scheitern lässt, als RuntimeError statt Survived.
stage <- file.path(tempfile("harness-mutation-"), "pkg")
dir.create(stage, recursive = TRUE)
for (part in c("DESCRIPTION", "NAMESPACE", "R", "inst", "data", "src", "tests/fixtures", test_dirs)) {
  source <- file.path(repo, part)
  if (!file.exists(source)) next
  target <- file.path(stage, dirname(part))
  dir.create(target, recursive = TRUE, showWarnings = FALSE)
  if (!file.copy(source, target, recursive = TRUE)) infra("Kopie fehlgeschlagen: ", part)
}

mutators <- unlist(lapply(mutator_names, function(name) {
  factory <- get0(name, envir = asNamespace("muttest"), mode = "function")
  if (is.null(factory)) infra("unbekannter muttest-Mutator: ", name)
  made <- factory()
  if (inherits(made, "Mutator")) list(made) else made
}), recursive = FALSE)

old_wd <- setwd(stage)
plan <- if (length(files)) muttest::muttest_plan(mutators = mutators, source_files = files) else NULL
dir.create(dirname(report), recursive = TRUE, showWarnings = FALSE)
unlink(report)
if (is.null(plan) || nrow(plan) == 0) {
  # Ohne Mutanten gibt muttest keinen Bericht aus; der leere Bericht gibt diesen Befund wieder.
  empty <- lapply(files, function(path) {
    list(language = "r", source = paste(readLines(path), collapse = "\n"), mutants = list())
  })
  names(empty) <- files
  jsonlite::write_json(list(schemaVersion = "1.0", files = if (length(empty)) empty else structure(list(), names = character())),
    report, auto_unbox = TRUE, pretty = TRUE)
  say("keine Mutanten für: ", if (length(files)) paste(files, collapse = ", ") else "(keine R-Datei im Umfang)")
  quit(save = "no", status = 0)
}

# Ein Mutant gilt als entdeckt, sobald ein Test eines der Rollenordner ihn bemerkt. Die Tests eines
# Mutanten laufen in einem eigenen R-Prozess; nach `timeout` Sekunden wird er samt Kindprozessen
# beendet, und der Mutant zählt als Timeout (entdeckt). Testdateien, deren Testname auf `exclude`
# passt, laufen nicht; ein Ordner ohne verbleibende Testdatei wird übersprungen.
HarnessTestStrategy <- R6::R6Class("HarnessTestStrategy",
  inherit = muttest::TestStrategy,
  public = list(
    dirs = NULL,
    exclude = NULL,
    timeout = NULL,
    timeout_tag = "harness-timeout:",
    initialize = function(dirs, exclude, timeout) {
      self$dirs <- dirs
      self$exclude <- exclude
      self$timeout <- timeout
    },
    execute = function(path, plan, reporter) {
      run_tests <- function(dirs, exclude, reporter) {
        filter <- if (nzchar(exclude)) exclude
        results <- list()
        for (dir in dirs) {
          # full.names = FALSE wie in test_dir: Der Filter gilt dem Testnamen, nicht dem Pfad.
          if (!length(testthat::find_test_scripts(dir, filter = filter, invert = TRUE, full.names = FALSE))) next
          outcome <- testthat::test_dir(dir, filter = filter, invert = TRUE,
            reporter = reporter, stop_on_failure = FALSE, load_package = "source"
          )
          results[[length(results) + 1L]] <- as.data.frame(outcome)
        }
        if (!length(results)) return(list())
        do.call(rbind, results)
      }
      limit <- self$timeout
      tag <- self$timeout_tag
      tryCatch(
        callr::r(run_tests, args = list(self$dirs, self$exclude, reporter),
          timeout = limit, cleanup_tree = TRUE
        ),
        callr_timeout_error = function(e) {
          stop(structure(class = c("harness_timeout", "error", "condition"), list(
            message = paste0(tag, " Tests nach ", limit, " s abgebrochen (MUT_TEST_TIMEOUT)"),
            call = NULL
          )))
        }
      )
    }
  )
)

skipped <- if (nzchar(exclude)) unlist(lapply(test_dirs, function(dir) {
  file.path(dir, testthat::find_test_scripts(dir, filter = exclude, full.names = FALSE))
}))
say(nrow(plan), " Mutanten in ", paste(files, collapse = ", "), "; Tests: ", paste(test_dirs, collapse = ", "),
  if (length(skipped)) paste0("; ausgelassen nach MUT_TEST_EXCLUDE='", exclude, "': ", paste(skipped, collapse = ", ")))

if (is.finite(timeout)) {
  # Unmutierter Vorlauf mit demselben Testsatz in einer eigenen Kopie. Die Grenze ist mindestens das
  # Dreifache seiner Laufzeit: Ein gewachsener Testsatz soll nicht jeden Mutanten über die Grenze
  # treiben, denn ein Timeout zählt als entdeckt.
  base <- tempfile("harness-mutation-base-")
  dir.create(base)
  if (!file.copy(stage, base, recursive = TRUE)) infra("Kopie für den unmutierten Testlauf fehlgeschlagen")
  setwd(file.path(base, "pkg"))
  started <- proc.time()[["elapsed"]]
  unmutated <- tryCatch(
    HarnessTestStrategy$new(test_dirs, exclude, Inf)$execute(test_dirs[1], NULL, "silent"),
    error = function(e) infra("unmutierter Testlauf gescheitert: ", conditionMessage(e))
  )
  seconds <- proc.time()[["elapsed"]] - started
  setwd(stage)
  unlink(base, recursive = TRUE)
  failed <- if (length(unmutated)) sum(unmutated$failed > 0) else 0L
  errors <- if (length(unmutated)) sum(unmutated$error) else 0L
  say("unmutierter Testlauf: ", round(seconds, 1), " s; ", failed, " Tests fehlgeschlagen, ", errors, " mit Fehler")
  if (failed || errors) {
    say("WARNUNG: Schon unmutiert scheitern Tests; jeder Mutant zählt dann als entdeckt (Fehlschlag) ",
      "oder als RuntimeError (nur Fehler, im Score nicht gezählt)")
  }
  limit <- max(timeout, ceiling(3 * seconds))
  say("Zeitlimit je Mutant: ", limit, " s (MUT_TEST_TIMEOUT=", timeout, " s, dreifacher unmutierter Lauf ",
    ceiling(3 * seconds), " s)")
  timeout <- limit
} else {
  say("Zeitlimit je Mutant: keins")
}

muttest::muttest(
  plan,
  path = test_dirs[1],
  reporter = muttest::MultiReporter$new(
    muttest::ProgressMutationReporter$new(),
    muttest::JSONMutationReporter$new(path = report)
  ),
  test_strategy = HarnessTestStrategy$new(test_dirs, exclude, timeout),
  workers = workers,
  # Die eigene Grenze von muttest (mirai .timeout, Vorgabe 600 s) zählt ab dem Einreihen in die
  # Warteschlange und führt zu RuntimeError; das Zeitlimit je Mutant setzt HarnessTestStrategy.
  timeout = Inf
)
setwd(old_wd)
if (!file.exists(report)) infra("muttest hat keinen Bericht geschrieben: ", report)

# muttest führt den Abbruch nach dem Zeitlimit als RuntimeError; im Stryker-Schema heißt er Timeout
# und zählt in 86-mutgate und 88-mutfull als entdeckt.
doc <- jsonlite::read_json(report, simplifyVector = FALSE)
timed_out <- 0L
for (file in names(doc$files)) {
  for (i in seq_along(doc$files[[file]]$mutants)) {
    mutant <- doc$files[[file]]$mutants[[i]]
    reason <- if (is.character(mutant$statusReason)) mutant$statusReason else ""
    if (identical(mutant$status, "RuntimeError") && startsWith(reason, HarnessTestStrategy$public_fields$timeout_tag)) {
      doc$files[[file]]$mutants[[i]]$status <- "Timeout"
      timed_out <- timed_out + 1L
    }
  }
}
if (timed_out) {
  jsonlite::write_json(doc, report, auto_unbox = TRUE, null = "null", na = "null", pretty = TRUE, digits = NA)
  say(timed_out, " Mutanten über dem Zeitlimit, im Bericht als Timeout")
}
say("Bericht: ", report)
