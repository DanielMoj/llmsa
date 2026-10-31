# K-M1b-7: vignettes/validation.Rmd holds the section "Ordinal and binary
# outcomes (latent scale)" with the checks of K-M1b-1 and K-M1b-5 and the read
# result files of the studies of K-M1b-2 and K-M1b-3 (tables per scenario with
# bias, EmpSE, MCSE; the code reads <study>_results.csv if present, else
# <study>_check_results.csv, and names n_sim from the file, no numeric literal
# from a results file in the Rmd text). Structure and reading are tested here
# on the vignette knitted in the repository (the knit is shared with K-M1a-7,
# acc_m1a_knit_validation()); the choice of a present <study>_results.csv is
# tested in test-m1b-7-vignette-full-results.R. Contract details: ACC-11.
# K-M1b-7: the build by R CMD check without ERROR and WARNING is decided by the
# lint gate (orchestrator/gates.d/20-lint.sh, orchestrator/lib/r-check.sh).

acc_m1b_7_studies <- c("ordinal_recovery", "binary_recovery", "two_level")

acc_m1b_7_section <- function() {
  k <- acc_m1a_knit_validation()
  acc_m1a_section(k$lines, acc_m1b_section_title)
}

acc_m1b_7_tokens <- function(section) acc_m1a_numbers(section)

test_that("K-M1b-7: vignettes/validation.Rmd holds the section \"Ordinal and binary outcomes (latent scale)\"", {
  rmd <- acc_m1a_vignette_path()
  expect_true(file.exists(rmd), label = rmd)
  if (!file.exists(rmd)) return(invisible())
  expect_false(is.null(acc_m1a_section(readLines(rmd, warn = FALSE), acc_m1b_section_title)))
})

test_that("K-M1b-7: the vignette knits in the repository without error and shows the section", {
  k <- acc_m1a_knit_validation()
  expect_null(k$error)
  sec <- acc_m1a_section(k$lines, acc_m1b_section_title)
  expect_false(is.null(sec))
  expect_false(any(grepl("^(##|#>)[[:space:]]*Error", k$lines)), label = "no error output in the knitted vignette")
})

test_that("K-M1b-7: the section shows the checks of K-M1b-1 with ANK-21 and ANK-TOL.engine_ordinal, expected and observed values", {
  sec <- acc_m1b_7_section()
  expect_false(is.null(sec))
  if (is.null(sec)) return(invisible())
  text <- paste(sec, collapse = "\n")
  for (id in c("ANK-21", "ANK-TOL.engine_ordinal")) expect_true(grepl(id, text, fixed = TRUE), label = paste("the section names", id))
  tokens <- acc_m1b_7_tokens(sec)
  for (key in c("laplace", "nagq10")) {
    v <- as.numeric(acc_m1a_value("ANK-21", key, "variance"))
    expect_true(acc_m1b_shown(tokens, v), label = sprintf("ANK-21 %s variance %s appears in the section", key, format(v)))
  }
  for (link in c("logit", "probit")) {
    v <- acc_m1a_components(acc_m1b_wine_fit(link))
    for (s in intersect(c("item", "prompt"), names(v))) {
      expect_true(acc_m1b_shown(tokens, v[[s]]),
                  label = sprintf("observed wine component %s (%s link) %s appears in the section", s, link, format(v[[s]], digits = 10)))
    }
  }
})

test_that("K-M1b-7: the section shows the checks of K-M1b-5 with ANK-25 and ANK-TOL.rptr, expected and observed values", {
  sec <- acc_m1b_7_section()
  expect_false(is.null(sec))
  if (is.null(sec)) return(invisible())
  text <- paste(sec, collapse = "\n")
  for (id in c("ANK-25", "ANK-TOL.rptr")) expect_true(grepl(id, text, fixed = TRUE), label = paste("the section names", id))
  tokens <- acc_m1b_7_tokens(sec)
  pub <- as.numeric(acc_m1a_value("ANK-25", "link_scale"))
  expect_true(acc_m1b_shown(tokens, pub), label = sprintf("ANK-25 link-scale value %s appears in the section", format(pub)))
  icc <- acc_m1b_beetles_icc()
  expect_true(acc_m1b_shown(tokens, icc), label = sprintf("observed ICC_items on BeetlesMale %s appears in the section", format(icc, digits = 10)))
})

for (study in acc_m1b_7_studies) {
  test_that(sprintf("K-M1b-7: the section tabulates bias and EmpSE with MCSE per scenario of %s from the results file and names n_sim from it", study), {
    path <- acc_m1b_expected_results_path(acc_m1b_sim_dir(), study)
    expect_true(file.exists(path), label = path)
    if (!file.exists(path)) return(invisible())
    res <- acc_m1b_read_csv(path)
    sec <- acc_m1b_7_section()
    expect_false(is.null(sec))
    if (is.null(sec)) return(invisible())
    cells <- tolower(unlist(lapply(acc_m1a_tables(sec), function(t) c(names(t), unlist(t, use.names = FALSE)))))
    for (w in c("bias", "empse", "mcse")) {
      expect_true(any(grepl(w, gsub("[[:space:]_-]", "", cells), fixed = TRUE)), label = sprintf("a table of the section shows %s", w))
    }
    acc_m1b_expect_results_shown(sec, res, sprintf("%s (%s)", study, basename(path)))
    acc_m1b_expect_n_sim_shown(sec, res, study)
  })
}

test_that("K-M1b-7: no numeric literal of a results file or of ANK-21 and ANK-25 is typed into validation.Rmd", {
  rmd <- acc_m1a_vignette_path()
  expect_true(file.exists(rmd))
  if (!file.exists(rmd)) return(invisible())
  lit <- acc_m1a_rmd_literals(readLines(rmd, warn = FALSE))
  values <- c(acc_m1a_leaves(acc_anchor("ANK-21")$value[c("laplace", "nagq10")]),
              acc_m1a_leaves(acc_anchor("ANK-25")$value[c("link_scale", "original_scale")]))
  for (study in acc_m1b_7_studies) {
    path <- acc_m1b_expected_results_path(acc_m1b_sim_dir(), study)
    expect_true(file.exists(path), label = path)
    if (!file.exists(path)) next
    res <- acc_m1b_read_csv(path)
    values <- c(values, as.numeric(res$value), as.numeric(res$mcse))
  }
  values <- unique(values[is.finite(values) & values != round(values)])
  typed <- character()
  for (i in seq_len(nrow(lit))) {
    x <- lit$value[i]
    if (lit$significant[i] >= 3L && any(x == values | x == signif(values, lit$significant[i]))) typed <- c(typed, lit$token[i])
  }
  expect_identical(unique(typed), character(), label = "numeric literals in validation.Rmd that equal result-file or anchor values")
})
