# K-M1b-7: "der Code liest `<studie>_results.csv`, falls vorhanden, sonst
# `<studie>_check_results.csv`, und nennt `n_sim` aus der Datei". The full runs
# do not exist before the acceptance of M1b, so the choice is tested in a
# temporary copy of the package under test (ACC-11): for every study a TEST
# FIXTURE <study>_results.csv is written next to the short run, made from the
# short-run results with every value and mcse shifted and n_sim replaced by a
# marker (no simulation result, never written into the repository); shares
# stay valid shares (ADR-027 Nr. 5.2, ADR-029 Nr. 1); the
# replicates and session files of the short run are copied under the names of
# a full run. The vignette is knitted in a separate R process with the copy
# loaded by pkgload::load_all() and without REPO_ROOT, i.e. in the public
# context of R CMD check, where the files come from the package
# (system.file("validation", "sim", ...)). The section must show the fixture
# values and the marker n_sim.

acc_m1b_7f_studies <- c("ordinal_recovery", "binary_recovery", "two_level")
acc_m1b_7f_marker <- 1234L   # fixture marker for n_sim, not a reference value

# Every value moves by 0.5; a derived_share moves by 0.5 modulo 1, which keeps
# it in [0, 1] and has no fixed point, so no fixture value equals the short run.
acc_m1b_7f_fixture <- function(res) {
  res$n_sim <- acc_m1b_7f_marker
  value <- as.numeric(res$value)
  share <- res$measure == "derived_share"
  res$value <- ifelse(share, (value + 0.5) %% 1, value + 0.5)
  res$mcse <- as.numeric(res$mcse) + 0.25
  res
}

acc_m1b_7f_knit <- function() {
  if (!is.null(acc_m1b$full_knit)) return(acc_m1b$full_knit)
  root <- acc_pkg_root()
  copy <- file.path(tempfile("acc-m1b7-"), "llmsa")
  dir.create(file.path(copy, "vignettes"), recursive = TRUE)
  for (part in c("DESCRIPTION", "NAMESPACE", "LICENSE", "R", "inst", "data", "src")) {
    source <- file.path(root, part)
    if (file.exists(source) && !file.copy(source, copy, recursive = TRUE)) stop("acceptance: copy of ", part, " failed", call. = FALSE)
  }
  rmd <- file.path(copy, "vignettes", "validation.Rmd")
  if (!file.copy(acc_m1a_vignette_path(), rmd)) stop("acceptance: vignette missing: ", acc_m1a_vignette_path(), call. = FALSE)
  sim <- file.path(copy, "inst", "validation", "sim")
  fixtures <- list()
  for (study in acc_m1b_7f_studies) {
    check <- file.path(sim, paste0(study, "_check_", c("results.csv", "replicates.csv", "session.txt")))
    if (!all(file.exists(check))) stop("acceptance: short run of ", study, " missing under ", sim, call. = FALSE)
    fx <- acc_m1b_7f_fixture(acc_m1b_read_csv(check[1]))
    utils::write.csv(fx, file.path(sim, paste0(study, "_results.csv")), row.names = FALSE)
    file.copy(check[2], file.path(sim, paste0(study, "_replicates.csv")))
    file.copy(check[3], file.path(sim, paste0(study, "_session.txt")))
    fixtures[[study]] <- fx
  }
  out <- file.path(tempfile("acc-m1b7-knit-"), "validation.md")
  dir.create(dirname(out))
  lines <- tryCatch(
    callr::r(function(pkg, rmd, out) {
      Sys.unsetenv("REPO_ROOT")
      pkgload::load_all(pkg, export_all = FALSE, helpers = FALSE, quiet = TRUE)
      knitr::opts_knit$set(root.dir = dirname(rmd), base.dir = dirname(out))
      knitr::opts_chunk$set(error = FALSE, fig.path = "figure/")
      setwd(dirname(out))
      suppressMessages(suppressWarnings(knitr::knit(rmd, output = out, quiet = TRUE, envir = new.env(parent = globalenv()))))
      readLines(out, warn = FALSE)
    }, args = list(copy, rmd, out)),
    error = function(e) e)
  knit <- list(error = if (inherits(lines, "error")) conditionMessage(lines) else NULL,
               lines = if (inherits(lines, "error")) character() else lines, fixtures = fixtures)
  acc_m1b$full_knit <- knit
  knit
}

test_that("K-M1b-7: with <study>_results.csv present the vignette knits in the public context and shows the section", {
  k <- acc_m1b_7f_knit()
  expect_null(k$error)
  expect_false(is.null(acc_m1a_section(k$lines, acc_m1b_section_title)))
})

for (study in acc_m1b_7f_studies) {
  test_that(sprintf("K-M1b-7: with %s_results.csv present the section shows its values and its n_sim, not the short run", study), {
    k <- acc_m1b_7f_knit()
    sec <- acc_m1a_section(k$lines, acc_m1b_section_title)
    expect_false(is.null(sec))
    if (is.null(sec)) return(invisible())
    fx <- k$fixtures[[study]]
    acc_m1b_expect_results_shown(sec, fx, sprintf("%s (fixture %s_results.csv)", study, study))
    acc_m1b_expect_n_sim_shown(sec, fx, sprintf("%s (fixture)", study))
  })
}
