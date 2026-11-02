# K-M1c-5: the section reads boot_coverage_results.csv if present, otherwise
# boot_coverage_check_results.csv, and names n_sim from the file. The full run
# does not exist before the acceptance of M1c, so the choice is tested in a
# temporary copy of the package under test (ACC-11): a TEST FIXTURE
# boot_coverage_results.csv is written next to the short run (no simulation
# result, never written into the repository). It holds all seven scenarios like
# a full run: S-boot-2 to S-boot-6 take the rows of S-boot-1 (same estimands),
# S-boot-7 its own; every scenario is shifted by its own amount, shares and
# coverages stay in [0.1, 0.95] (inside [0, 1] and with at least two
# significant digits when shown with two decimals), n_sim is the marker 1234
# (at least ANK-06). The
# replicates and session file of the short run are copied under the names of
# a full run. The vignette is knitted in a separate R process with the copy
# loaded by pkgload::load_all() and without REPO_ROOT, i.e. in the public
# context of R CMD check. The section must show the fixture coverages with
# their MCSE and the marker n_sim.

acc_m1c_5f_marker <- 1234L   # fixture marker for n_sim, not a reference value
acc_m1c_5f_bounded <- c("coverage", acc_m1c_share_measures)

acc_m1c_5f_fixture <- function(check) {
  parts <- list()
  for (j in 1:7) {
    id <- paste0("S-boot-", j)
    source_id <- if (j == 7L) "S-boot-7" else "S-boot-1"
    rows <- check[check$scenario == source_id, , drop = FALSE]
    if (!nrow(rows)) stop("acceptance: short run without ", source_id, call. = FALSE)
    rows$scenario <- id
    value <- as.numeric(rows$value)
    bounded <- rows$measure %in% acc_m1c_5f_bounded
    rows$value <- ifelse(bounded, 0.1 + 0.85 * ((value + 0.5 + 0.13 * j) %% 1), value + 0.5 + j)
    rows$mcse <- as.numeric(rows$mcse) + 0.25 + 0.1 * j
    rows$n_sim <- acc_m1c_5f_marker
    parts[[j]] <- rows
  }
  do.call(rbind, parts)
}

acc_m1c_5f_knit <- function() {
  if (!is.null(acc_m1c$full_knit)) return(acc_m1c$full_knit)
  root <- acc_pkg_root()
  copy <- file.path(tempfile("acc-m1c5-"), "llmsa")
  dir.create(file.path(copy, "vignettes"), recursive = TRUE)
  for (part in c("DESCRIPTION", "NAMESPACE", "LICENSE", "R", "inst", "data", "src")) {
    source <- file.path(root, part)
    if (file.exists(source) && !file.copy(source, copy, recursive = TRUE)) stop("acceptance: copy of ", part, " failed", call. = FALSE)
  }
  rmd <- file.path(copy, "vignettes", "validation.Rmd")
  if (!file.copy(acc_m1a_vignette_path(), rmd)) stop("acceptance: vignette missing: ", acc_m1a_vignette_path(), call. = FALSE)
  sim <- file.path(copy, "inst", "validation", "sim")
  check <- file.path(sim, paste0(acc_m1c_study, "_check_", c("results.csv", "replicates.csv", "session.txt")))
  if (!all(file.exists(check))) stop("acceptance: short run of ", acc_m1c_study, " missing under ", sim, call. = FALSE)
  fixture <- acc_m1c_5f_fixture(acc_m1b_read_csv(check[1]))
  utils::write.csv(fixture, file.path(sim, paste0(acc_m1c_study, "_results.csv")), row.names = FALSE)
  file.copy(check[2], file.path(sim, paste0(acc_m1c_study, "_replicates.csv")))
  file.copy(check[3], file.path(sim, paste0(acc_m1c_study, "_session.txt")))
  out <- file.path(tempfile("acc-m1c5-knit-"), "validation.md")
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
               lines = if (inherits(lines, "error")) character() else lines, fixture = fixture)
  acc_m1c$full_knit <- knit
  knit
}

test_that("K-M1c-5: the fixture differs from the short run in every coverage and keeps coverages and shares in [0.1, 0.95]", {
  check <- acc_m1b_read_csv(acc_m1b_check_file(acc_m1c_study, "results"))
  fx <- acc_m1c_5f_fixture(check)
  expect_setequal(unique(fx$scenario), paste0("S-boot-", 1:7))
  bounded <- fx$measure %in% acc_m1c_5f_bounded
  expect_true(all(fx$value[bounded] >= 0.1 & fx$value[bounded] <= 0.95))
  original <- check[check$measure == "coverage", , drop = FALSE]
  shifted <- fx[fx$measure == "coverage" & fx$scenario %in% acc_m1c_check_scenarios, , drop = FALSE]
  key <- function(d) paste(d$scenario, d$estimand)
  same <- shifted$value == original$value[match(key(shifted), key(original))]
  expect_false(any(same), label = "a fixture coverage equals the short run")
})

test_that("K-M1c-5: with boot_coverage_results.csv present the vignette knits in the public context and shows the section", {
  k <- acc_m1c_5f_knit()
  expect_null(k$error)
  expect_false(is.null(acc_m1a_section(k$lines, acc_m1c_section_title)))
})

test_that("K-M1c-5: with boot_coverage_results.csv present the section shows its coverages with MCSE and its n_sim, not the short run", {
  k <- acc_m1c_5f_knit()
  sec <- acc_m1a_section(k$lines, acc_m1c_section_title)
  expect_false(is.null(sec))
  if (is.null(sec)) return(invisible())
  acc_m1c_expect_coverage_shown(sec, k$fixture, "boot_coverage (fixture boot_coverage_results.csv)")
  acc_m1b_expect_n_sim_shown(sec, k$fixture, "boot_coverage (fixture)")
})
