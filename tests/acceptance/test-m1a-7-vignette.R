# K-M1a-7: vignettes/validation.Rmd exists, holds the section "Variance
# components and gauge R&R (numeric)" with a table per reference check of
# K-M1a-1 to K-M1a-5 (anchor ID, source, expected value, observed value,
# tolerance, result); the values are computed in the vignette code and read
# from reference/anchors/, not typed in. Structure and reading are tested here
# on the vignette knitted in the repository (contract ACC-14).
# K-M1a-7: the build by R CMD check without ERROR and WARNING is decided by the
# lint gate (orchestrator/gates.d/20-lint.sh, orchestrator/lib/r-check.sh).

# Anchor IDs per criterion that the tables of the section must name.
acc_m1a_7_ids <- c("K-M1a-1" = "ANK-TOL.reml_anova", "K-M1a-2" = "ANK-10", "K-M1a-3" = "ANK-TOL.oracle",
                   "K-M1a-3" = "ANK-13", "K-M1a-4" = "ANK-14", "K-M1a-4" = "ANK-TOL.nist_digits",
                   "K-M1a-5" = "ANK-16")

acc_m1a_7_tables <- function() {
  k <- acc_m1a_knit_validation()
  sec <- acc_m1a_section(k$lines, acc_m1a_section_title)
  if (is.null(sec)) return(list())
  acc_m1a_reference_tables(acc_m1a_tables(sec))
}

# Expected-value cells of the rows whose anchor cell names `id`.
acc_m1a_7_expected <- function(tables, id) {
  unlist(lapply(tables, function(t) {
    ids <- lapply(acc_m1a_column(t, "anchor"), acc_m1a_anchor_ids)
    rows <- vapply(ids, function(x) id %in% x, logical(1))
    acc_m1a_column(t, "expected")[rows]
  }))
}

acc_m1a_7_expect_shown <- function(cells, value, label) {
  tokens <- acc_m1a_numbers(cells)
  expect_true(any(vapply(tokens, acc_m1a_shows, logical(1), value = value)),
              label = sprintf("%s (%s) appears in the expected column", label, format(value, digits = 15)))
}

test_that("K-M1a-7: vignettes/validation.Rmd exists and holds the section \"Variance components and gauge R&R (numeric)\"", {
  rmd <- acc_m1a_vignette_path()
  expect_true(file.exists(rmd), label = rmd)
  if (!file.exists(rmd)) return(invisible())
  expect_false(is.null(acc_m1a_section(readLines(rmd, warn = FALSE), acc_m1a_section_title)))
})

test_that("K-M1a-7: the vignette knits in the repository without error, shows the section and writes nothing into vignettes/", {
  k <- acc_m1a_knit_validation()
  expect_null(k$error)
  expect_true(length(k$lines) > 0L)
  expect_false(is.null(acc_m1a_section(k$lines, acc_m1a_section_title)))
  expect_identical(k$new_files, character())
  expect_false(any(grepl("^(##|#>)[[:space:]]*Error", k$lines)), label = "no error output in the knitted vignette")
})

test_that("K-M1a-7: the section holds a table per reference check of K-M1a-1 to K-M1a-5 with anchor, source, expected, observed, tolerance and result", {
  tabs <- acc_m1a_7_tables()
  expect_gte(length(tabs), 5L)
  named <- unique(unlist(lapply(tabs, function(t) acc_m1a_anchor_ids(acc_m1a_column(t, "anchor")))))
  for (i in seq_along(acc_m1a_7_ids)) {
    expect_true(acc_m1a_7_ids[[i]] %in% named,
                label = sprintf("%s: a table row names %s", names(acc_m1a_7_ids)[i], acc_m1a_7_ids[[i]]))
  }
  tol_entries <- names(acc_anchor("ANK-TOL")$value)
  for (id in named) {
    if (startsWith(id, "ANK-TOL.")) {
      expect_true(sub("^ANK-TOL\\.", "", id) %in% tol_entries, label = paste(id, "is an entry of ANK-TOL"))
    } else {
      expect_true(file.exists(file.path(acc_repo_root(), "reference", "anchors", paste0(id, ".json"))),
                  label = paste(id, "is a file under reference/anchors/"))
    }
  }
  for (t in tabs) {
    expect_gte(nrow(t), 1L)
    for (w in acc_m1a_required_columns) {
      cells <- acc_m1a_column(t, w)
      expect_true(all(!is.na(cells) & nzchar(trimws(cells))), label = sprintf("column %s has no empty cell", w))
    }
  }
})

test_that("K-M1a-7: the expected values of the AIAG example are the values of ANK-10 (ankerRef: ANK-10)", {
  cells <- acc_m1a_7_expected(acc_m1a_7_tables(), "ANK-10")
  expect_true(length(cells) > 0L)
  pub <- acc_anchor("ANK-10")$value
  for (k in c("EV", "AV", "GRR", "PV", "TV")) acc_m1a_7_expect_shown(cells, as.numeric(pub$sd[[k]]), paste("ANK-10 sd", k))
  for (k in c("EV", "AV", "GRR", "PV")) {
    acc_m1a_7_expect_shown(cells, as.numeric(pub$pct_study_var[[k]]), paste("ANK-10 % study variation", k))
    acc_m1a_7_expect_shown(cells, as.numeric(pub$pct_contribution[[k]]), paste("ANK-10 % contribution", k))
  }
  acc_m1a_7_expect_shown(cells, as.numeric(pub$ndc), "ANK-10 ndc")
})

test_that("K-M1a-7: the expected values of the NIST checks are the certified values of ANK-14 (ankerRef: ANK-14)", {
  cells <- acc_m1a_7_expected(acc_m1a_7_tables(), "ANK-14")
  expect_true(length(cells) > 0L)
  for (name in acc_m1a_nist_list("low_difficulty_datasets")) {
    acc_m1a_7_expect_shown(cells, as.numeric(acc_m1a_value("ANK-14", "datasets", name, "within", "ms")),
                           paste("ANK-14", name, "certified within mean square"))
  }
})

test_that("K-M1a-7: the expected values of the Penicillin check are the published estimates of ANK-13 (ankerRef: ANK-13; open ACC-1)", {
  pub <- acc_m1a_value("ANK-13", "sd")
  cells <- acc_m1a_7_expected(acc_m1a_7_tables(), "ANK-13")
  expect_true(length(cells) > 0L)
  for (k in names(pub)) acc_m1a_7_expect_shown(cells, as.numeric(pub[[k]]), paste("ANK-13 sd", k))
})

test_that("K-M1a-7: no value of the M1a anchors is typed into validation.Rmd (read from reference/anchors/)", {
  rmd <- acc_m1a_vignette_path()
  expect_true(file.exists(rmd))
  if (!file.exists(rmd)) return(invisible())
  src <- readLines(rmd, warn = FALSE)
  text <- paste(src, collapse = "\n")
  for (id in c("ANK-10", "ANK-13", "ANK-14", "ANK-16", "ANK-TOL")) {
    expect_match(text, id, fixed = TRUE, label = paste("validation.Rmd names", id))
  }
  lit <- acc_m1a_rmd_literals(src)
  ids <- c("ANK-10", "ANK-14", "ANK-16",
           if (file.exists(file.path(acc_repo_root(), "reference", "anchors", "ANK-13.json"))) "ANK-13")
  values <- unique(unlist(lapply(ids, function(id) acc_m1a_leaves(acc_anchor(id)$value))))
  values <- values[is.finite(values) & values != round(values)]
  tol <- acc_anchor("ANK-TOL")$value[c("reml_anova", "oracle", "nist_digits", "invariance")]
  tol_any <- unlist(lapply(tol, function(e) acc_m1a_leaves(e[grepl("tol", names(e))])))
  tol_sci <- unlist(lapply(tol, function(e) acc_m1a_leaves(e[!grepl("tol", names(e))])))
  typed <- character()
  for (i in seq_len(nrow(lit))) {
    x <- lit$value[i]
    hit_value <- lit$significant[i] >= 3L && any(x == values | x == signif(values, lit$significant[i]))
    hit_tol <- any(x == tol_any) || (lit$scientific[i] && any(x == tol_sci))
    if (hit_value || hit_tol) typed <- c(typed, lit$token[i])
  }
  expect_identical(unique(typed), character(), label = "numeric literals in validation.Rmd that equal anchor values")
})
