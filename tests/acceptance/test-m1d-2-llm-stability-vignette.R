# K-M1d-2: vignettes/llm-stability.Rmd computes per task and model the
# attribute repeatability (share of item x model cells with an identical
# answer across all runs), the hit rate and a binary fit with item and model as
# random effects (msa_fit(type = "binary"), msa_grr()), reads the data with
# system.file("extdata", …) and holds no typed result. Reading and calls are
# tested on the vignette knitted in the repository; expected values come from
# the mini-reference acc_m1d_llm_reference() and from the test's own calls of
# msa_fit() and msa_grr() on the frozen subset (ACC-5).
# K-M1d-2: the build by R CMD check without ERROR and WARNING is decided by the
# lint gate (orchestrator/gates.d/20-lint.sh, orchestrator/lib/r-check.sh).

acc_m1d_2_name <- "llm-stability"

acc_m1d_2_tokens <- function() {
  k <- acc_m1d_knit(acc_m1d_2_name)
  cells <- unlist(lapply(acc_m1a_tables(k$lines), function(t) c(names(t), unlist(t, use.names = FALSE))))
  acc_m1d_numbers(cells)
}

# Components item and model and %GRR of the binary fit of one task with the
# package defaults (interactions FALSE) and the given link (ACC-5).
acc_m1d_2_fit <- function(task, link) {
  key <- paste0("llm_fit_", task, "_", link)
  if (!is.null(acc_m1d[[key]])) return(acc_m1d[[key]])
  d <- acc_m1d_llm_items()
  fit <- acc_m1b_catch(msa_fit(acc_m1d_llm_runs(d[d$task == task, , drop = FALSE], "correct"), type = "binary", link = link))
  out <- if (inherits(fit$value, "error")) fit$value else {
    v <- acc_m1a_components(fit$value)
    g <- msa_grr(fit$value)
    c(item = v[["item"]], model = v[["model"]], grr_pct_study_var = as.numeric(acc_m1a_summary(g, "grr_pct_study_var")))
  }
  acc_m1d[[key]] <- out
  out
}

test_that("K-M1d-2: vignettes/llm-stability.Rmd exists and knits in the repository without error", {
  expect_true(file.exists(acc_m1d_vignette_path(acc_m1d_2_name)), label = acc_m1d_vignette_path(acc_m1d_2_name))
  k <- acc_m1d_knit(acc_m1d_2_name)
  expect_null(k$error)
  expect_false(any(grepl("^(##|#>)[[:space:]]*Error", k$lines)), label = "error output in the knitted vignette")
})

test_that("K-M1d-2: the vignette reads the frozen subset with system.file(\"extdata\", …), from no other path", {
  code <- paste(acc_m1d_rmd_code(acc_m1d_vignette_path(acc_m1d_2_name)), collapse = "\n")
  expect_true(grepl("system\\.file\\([[:space:]]*[\"']extdata[\"']", code), label = "system.file(\"extdata\", …) in the R code")
  expect_true(grepl(acc_m1d_llm_folder, code, fixed = TRUE), label = paste("the R code names", acc_m1d_llm_folder))
  expect_true(grepl("items.csv.gz", code, fixed = TRUE), label = "the R code names items.csv.gz")
  expect_false(grepl("quellen|inst/extdata|REPO_ROOT", code), label = "a path to ../quellen, inst/extdata or REPO_ROOT in the R code")
})

test_that("K-M1d-2: the vignette calls msa_fit(type = \"binary\") and msa_grr()", {
  code <- paste(acc_m1d_rmd_code(acc_m1d_vignette_path(acc_m1d_2_name)), collapse = "\n")
  expect_true(grepl("msa_fit\\(", code) && grepl("type[[:space:]]*=[[:space:]]*[\"']binary[\"']", code),
              label = "msa_fit(…, type = \"binary\") in the R code")
  expect_true(grepl("msa_grr\\(", code), label = "msa_grr() in the R code")
})

test_that("K-M1d-2: the vignette shows attribute repeatability and hit rate per task and model (ACC-5)", {
  k <- acc_m1d_knit(acc_m1d_2_name)
  expect_null(k$error)
  ref <- acc_m1d_llm_reference(acc_m1d_llm_items())
  tokens <- acc_m1d_2_tokens()
  text <- acc_m1d_norm(k$lines)
  for (t in unique(ref$task)) expect_true(grepl(t, text, fixed = TRUE), label = paste("the vignette names task", t))
  for (m in unique(ref$model)) expect_true(grepl(m, text, fixed = TRUE), label = paste("the vignette names model", m))
  for (i in seq_len(nrow(ref))) {
    for (what in c("repeatability", "hit_rate")) {
      v <- ref[[what]][i]
      expect_true(acc_m1d_shown(tokens, v, c(1, 100)),
                  label = sprintf("%s of %s, %s (%s) appears in a table of the vignette", what, ref$task[i], ref$model[i], format(v, digits = 6)))
    }
  }
})

test_that("K-M1d-2: the vignette shows per task the item and model components and %GRR of the binary fit (ACC-5)", {
  k <- acc_m1d_knit(acc_m1d_2_name)
  expect_null(k$error)
  tokens <- acc_m1d_2_tokens()
  for (t in unlist(acc_m1d_ank40()$tasks)) {
    shown <- FALSE
    fits <- character()
    for (link in c("probit", "logit")) {
      v <- acc_m1d_2_fit(t, link)
      if (inherits(v, "error")) { fits <- c(fits, paste(link, conditionMessage(v))); next }
      fits <- c(fits, paste(link, paste(names(v), format(v, digits = 6), collapse = ", ")))
      if (all(vapply(v, function(x) acc_m1d_shown(tokens, x, 1), logical(1)))) { shown <- TRUE; break }
    }
    expect_true(shown, label = sprintf("task %s: components item, model and %%GRR of msa_fit(type = \"binary\") appear in the tables (%s)",
                                       t, paste(fits, collapse = "; ")))
  }
})

test_that("K-M1d-2: no result is typed into llm-stability.Rmd", {
  ref <- acc_m1d_llm_reference(acc_m1d_llm_items())
  values <- c(ref$repeatability, ref$hit_rate, 100 * ref$repeatability, 100 * ref$hit_rate)
  for (t in unlist(acc_m1d_ank40()$tasks)) {
    v <- acc_m1d_2_fit(t, "probit")
    if (!inherits(v, "error")) values <- c(values, v)
  }
  typed <- acc_m1d_typed_literals(acc_m1d_vignette_path(acc_m1d_2_name), values, min_sig = 3L, min_int = Inf)
  expect_identical(typed, character(), label = "numeric literals in llm-stability.Rmd that equal computed results")
})
