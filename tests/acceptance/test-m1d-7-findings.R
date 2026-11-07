# K-M1d-7: findings of the class-B studies documented. vignettes/validation.Rmd
# reads all four results files and tabulates per scenario bias, relative bias,
# EmpSE, coverage and mean interval width with MCSE (no numeric literal from a
# results file in the Rmd text); every component of ordinal_recovery and
# binary_recovery whose relative bias exceeds ANK-TOL.bias_report, the bias of
# beta-hat^2/2 per scenario of two_level and every coverage of boot_coverage
# that deviates from the nominal level by more than ANK-TOL.mc_factor MCSE
# (report threshold) are named in the vignette as a finding (direction and
# scenario; no acceptance criterion, BL-04); the documentation of msa_fit() and
# msa_boot() names them qualitatively with a reference to the vignette; every
# scenario with a finding appears in the vignette and in the Rd file. The
# findings are computed by acc_m1d_findings() (setup-m1d.R) from the full
# results files; display rules ACC-10. The rule of docs/02 M1d that R/fit.R and
# R/grr.R change only in the roxygen documentation is checked here as well
# (ACC-12, ANK-34).

# Number tokens of every table row of the knitted validation.Rmd, once per
# test run.
acc_m1d_7_row_tokens <- function() {
  if (!is.null(acc_m1d$validation_rows)) return(acc_m1d$validation_rows)
  rows <- list()
  for (t in acc_m1a_tables(acc_m1a_knit_validation()$lines)) {
    for (i in seq_len(nrow(t))) {
      tok <- acc_m1a_numbers(unlist(t[i, ], use.names = FALSE))
      tok <- tok[!is.na(tok)]
      if (length(tok)) rows[[length(rows) + 1L]] <- tok
    }
  }
  acc_m1d$validation_rows <- rows
  rows
}

# TRUE if one table row shows all `values` (to the precision shown), or all of
# them times 100 (percent); as acc_m1c_row_shows().
acc_m1d_7_row_shows <- function(values) {
  for (tok in acc_m1d_7_row_tokens()) {
    for (scale in c(1, 100)) {
      if (all(vapply(values * scale, function(v) acc_m1b_shown(tok, v), logical(1)))) return(TRUE)
    }
  }
  FALSE
}

# Measures tabulated per scenario (ACC-10): bias, relative bias and EmpSE for
# every estimand; coverage and mean width for the interval estimands of
# boot_coverage.
acc_m1d_7_measures <- function(study, estimand) {
  base <- c("bias", "rel_bias", "empse")
  if (study == "boot_coverage" && estimand %in% acc_m1c_interval_estimands) c(base, "coverage", "width") else base
}

test_that("K-M1d-7: validation.Rmd knits in the repository without error", {
  k <- acc_m1a_knit_validation()
  expect_null(k$error)
  expect_false(any(grepl("^(##|#>)[[:space:]]*Error", k$lines)), label = "error output in the knitted vignette")
})

for (study in acc_m1d_studies) {
  test_that(sprintf("K-M1d-7: validation.Rmd tabulates per scenario of %s bias, relative bias, EmpSE (coverage, width) with MCSE from the full results file", study), {
    path <- acc_m1d_full_path(study, "results")
    expect_true(file.exists(path), label = basename(path))
    if (!file.exists(path)) return(invisible())
    res <- acc_m1b_read_csv(path)
    k <- acc_m1a_knit_validation()
    expect_null(k$error)
    text <- acc_m1d_norm(k$lines)
    acc_m1b_expect_n_sim_shown(k$lines, res, sprintf("%s (%s)", study, basename(path)))
    for (id in unique(res$scenario)) {
      expect_true(acc_m1d_has_id(text, id), label = sprintf("%s: the vignette names %s", study, id))
      for (e in unique(res$estimand[res$scenario == id & res$estimand != acc_m1c_share_estimand])) {
        for (m in acc_m1d_7_measures(study, e)) {
          row <- res[res$scenario == id & res$estimand == e & res$measure == m, , drop = FALSE]
          if (nrow(row) != 1L) {
            expect_identical(nrow(row), 1L, label = sprintf("%s: %s, %s, %s - row of the results file", study, id, e, m))
            next
          }
          v <- c(as.numeric(row$value), as.numeric(row$mcse))
          expect_true(acc_m1d_7_row_shows(v),
                      label = sprintf("%s: %s, %s, %s = %s with MCSE %s in one table row", study, id, e, m,
                                      format(v[1], digits = 15), format(v[2], digits = 15)))
        }
      }
    }
  })
}

test_that("K-M1d-7: no numeric literal of the four full results files is typed into validation.Rmd", {
  values <- numeric()
  for (study in acc_m1d_studies) {
    path <- acc_m1d_full_path(study, "results")
    expect_true(file.exists(path), label = basename(path))
    if (!file.exists(path)) next
    res <- acc_m1b_read_csv(path)
    values <- c(values, as.numeric(res$value), as.numeric(res$mcse))
  }
  typed <- acc_m1d_typed_literals(acc_m1a_vignette_path(), values, min_sig = 3L, min_int = Inf)
  expect_identical(typed, character(), label = "numeric literals in validation.Rmd that equal values of the full results files")
})

test_that("K-M1d-7: every finding is named in the vignette with scenario, estimand and direction (ankerRef: ANK-TOL.bias_report, ANK-TOL.mc_factor)", {
  for (study in acc_m1d_studies) expect_true(file.exists(acc_m1d_full_path(study, "results")), label = paste(study, "results file"))
  if (!all(file.exists(vapply(acc_m1d_studies, acc_m1d_full_path, "", kind = "results")))) return(invisible())
  f <- acc_m1d_findings()
  expect_true(all(c("two_level") %in% f$study), label = "two_level contributes its bias of beta-hat^2/2 in every scenario")
  k <- acc_m1a_knit_validation()
  expect_null(k$error)
  units <- acc_m1d_units(k$lines)
  for (i in seq_len(nrow(f))) {
    re <- acc_m1d_direction_re(f$kind[i], f$direction[i])
    hit <- vapply(units, function(u) {
      acc_m1d_has_id(u, f$scenario[i]) && acc_m1d_has_estimand(u, f$estimand[i]) && (is.null(re) || grepl(re, u, perl = TRUE))
    }, logical(1))
    expect_true(any(hit),
                label = sprintf("finding %s, %s, %s: %s %s (%s = %s, MCSE %s) named in one table row or sentence of the vignette",
                                f$study[i], f$scenario[i], f$estimand[i], f$kind[i], f$direction[i],
                                if (f$kind[i] == "coverage") "coverage" else if (f$study[i] == "two_level") "bias" else "relative bias",
                                format(f$value[i], digits = 4), format(f$mcse[i], digits = 4)))
  }
})

test_that("K-M1d-7: the help pages of msa_fit() and msa_boot() name every scenario with a finding, its direction and the vignette", {
  for (study in acc_m1d_studies) expect_true(file.exists(acc_m1d_full_path(study, "results")), label = paste(study, "results file"))
  if (!all(file.exists(vapply(acc_m1d_studies, acc_m1d_full_path, "", kind = "results")))) return(invisible())
  f <- acc_m1d_findings()
  for (rd in c("msa_fit", "msa_boot")) {
    txt <- acc_m1b_rd_text(rd)
    expect_true(grepl("vignette(\"validation\"", txt, fixed = TRUE) || grepl("validation.Rmd", txt, fixed = TRUE),
                label = sprintf("?%s refers to the vignette validation", rd))
    own <- f[vapply(f$study, acc_m1d_rd_of, "") == rd, , drop = FALSE]
    for (id in unique(own$scenario)) expect_true(acc_m1d_has_id(txt, id), label = sprintf("?%s names scenario %s with a finding", rd, id))
    for (i in which(!duplicated(own[c("kind", "direction")]))) {
      re <- acc_m1d_direction_re(own$kind[i], own$direction[i])
      if (is.null(re)) next
      expect_true(grepl(re, txt, perl = TRUE), label = sprintf("?%s names the direction %s of a %s finding", rd, own$direction[i], own$kind[i]))
    }
  }
})

# The rule of docs/02 M1d binds the state that completed M1d: R/fit.R and
# R/grr.R in the tag done/M1d against done/M1c, both read from the git objects
# with acc_m1c_baseline_text(), done/M1c checked against ANK-34. Later
# milestones change these files under their own rules (M3d: ADR-053 Nr. 14.3,
# checked in the code review at the diff since plan/M3d; ADR-053 Nr. 14.5).
test_that("K-M1d-7: R/fit.R and R/grr.R of done/M1d differ from done/M1c only in roxygen lines (docs/02 M1d; ankerRef: ANK-34)", {
  for (path in c("R/fit.R", "R/grr.R")) {
    old <- acc_m1d_baseline_file(path)
    on.exit(unlink(old), add = TRUE)
    done <- acc_m1c_baseline_text("done/M1d", path)
    on.exit(unlink(done), add = TRUE)
    a <- acc_m1d_code_lines(done)
    b <- acc_m1d_code_lines(old)
    expect_true(length(a) > 0L, label = sprintf("done/M1d:%s holds code lines", path))
    expect_identical(a, b, label = sprintf("done/M1d:%s without roxygen lines (%d vs %d lines)", path, length(a), length(b)),
                     expected.label = "done/M1c")
  }
})
