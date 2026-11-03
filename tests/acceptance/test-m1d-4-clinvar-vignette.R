# K-M1d-4: vignettes/clinvar-raters.Rmd computes for both subsets
# Krippendorff's alpha (nominal and ordinal) with msa_agreement(), the share of
# variants with fully agreeing submissions, the share of variants with a
# conflict, an ordinal fit with variant and submitter as random effects
# (msa_fit(type = "ordinal"), msa_grr()) and a sensitivity analysis with
# review_status "criteria provided" only; it sets the results against ANK-42 to
# ANK-46 (ANK-45 for the HRF subset) as a comparison, explicitly not as an
# acceptance criterion. Calls and anchor references are tested on the vignette
# knitted in the repository; expected values come from the frozen subsets, the
# mini-reference acc_m1d_kripp() (Krippendorff 2011) and the anchors (ACC-7).
# K-M1d-4: the build by R CMD check without ERROR and WARNING is decided by the
# lint gate (orchestrator/gates.d/20-lint.sh, orchestrator/lib/r-check.sh).

acc_m1d_4_name <- "clinvar-raters"

# Number tokens of the whole knitted document: text, tables and printed output
# (ACC-7: the vignette shows the values; where is free).
acc_m1d_4_tokens <- function() {
  key <- "clinvar_tokens"
  if (!is.null(acc_m1d[[key]])) return(acc_m1d[[key]])
  k <- acc_m1d_knit(acc_m1d_4_name)
  acc_m1d[[key]] <- acc_m1d_numbers(gsub("<[^>]+>", " ", k$lines))
  acc_m1d[[key]]
}

acc_m1d_4_alpha <- function(d, weights) {
  ag <- msa_agreement(acc_m1d_clinvar_runs(d), levels = acc_m1d_classes(), weights = weights)
  as.numeric(ag$alpha$alpha[ag$alpha$scope == "all conditions"])
}

# Components item and prompt and %GRR of the ordinal fit with the package
# defaults (interactions FALSE) and the given link (ACC-7).
acc_m1d_4_fit <- function(which, link) {
  key <- paste0("clinvar_fit_", which, "_", link)
  if (!is.null(acc_m1d[[key]])) return(acc_m1d[[key]])
  fit <- acc_m1b_catch(msa_fit(acc_m1d_clinvar_runs(acc_m1d_clinvar_subset(which)), type = "ordinal",
                               levels = acc_m1d_classes(), link = link))
  out <- if (inherits(fit$value, "error")) fit$value else {
    v <- acc_m1a_components(fit$value)
    c(item = v[["item"]], prompt = v[["prompt"]], grr_pct_study_var = as.numeric(acc_m1a_summary(msa_grr(fit$value), "grr_pct_study_var")))
  }
  acc_m1d[[key]] <- out
  out
}

test_that("K-M1d-4: vignettes/clinvar-raters.Rmd exists and knits in the repository without error", {
  expect_true(file.exists(acc_m1d_vignette_path(acc_m1d_4_name)), label = acc_m1d_vignette_path(acc_m1d_4_name))
  k <- acc_m1d_knit(acc_m1d_4_name)
  expect_null(k$error)
  expect_false(any(grepl("^(##|#>)[[:space:]]*Error", k$lines)), label = "error output in the knitted vignette")
})

test_that("K-M1d-4: the vignette reads both frozen subsets with system.file(\"extdata\", …) and calls msa_agreement(), msa_fit(type = \"ordinal\") and msa_grr()", {
  code <- paste(acc_m1d_rmd_code(acc_m1d_vignette_path(acc_m1d_4_name)), collapse = "\n")
  expect_true(grepl("system\\.file\\([[:space:]]*[\"']extdata[\"']", code), label = "system.file(\"extdata\", …) in the R code")
  expect_true(grepl(acc_m1d_clinvar_folder, code, fixed = TRUE), label = paste("the R code names", acc_m1d_clinvar_folder))
  for (f in acc_m1d_clinvar_files) expect_true(grepl(f, code, fixed = TRUE), label = paste("the R code names", f))
  expect_false(grepl("quellen|inst/extdata", code), label = "a path to ../quellen or inst/extdata in the R code")
  expect_true(grepl("msa_agreement\\(", code), label = "msa_agreement() in the R code")
  expect_true(grepl("msa_fit\\(", code) && grepl("type[[:space:]]*=[[:space:]]*[\"']ordinal[\"']", code), label = "msa_fit(…, type = \"ordinal\") in the R code")
  expect_true(grepl("msa_grr\\(", code), label = "msa_grr() in the R code")
})

test_that("K-M1d-4: Krippendorff's alpha of msa_agreement() equals the mini-reference for both subsets, nominal and ordinal (ankerRef: ANK-TOL.package_compare)", {
  tol <- as.numeric(acc_m1a_tol("package_compare", "abs_tol"))
  for (which in names(acc_m1d_clinvar_files)) {
    d <- acc_m1d_clinvar_subset(which)
    for (case in list(c("unweighted", "nominal"), c("linear", "ordinal"))) {
      got <- acc_m1d_4_alpha(d, case[1])
      want <- acc_m1d_kripp(as.character(d$variation_id), d$classification, acc_m1d_classes(), case[2])
      expect_true(length(got) == 1L && abs(got - want) <= tol,
                  label = sprintf("%s, %s alpha: msa_agreement() %s, reference %s", which, case[2],
                                  format(got, digits = 15), format(want, digits = 15)))
    }
  }
})

test_that("K-M1d-4: the vignette shows for both subsets alpha (nominal, ordinal), the share of fully agreeing variants and the share with a conflict (ACC-7)", {
  k <- acc_m1d_knit(acc_m1d_4_name)
  expect_null(k$error)
  tokens <- acc_m1d_4_tokens()
  for (which in names(acc_m1d_clinvar_files)) {
    d <- acc_m1d_clinvar_subset(which)
    values <- c(alpha_nominal = acc_m1d_kripp(as.character(d$variation_id), d$classification, acc_m1d_classes(), "nominal"),
                alpha_ordinal = acc_m1d_kripp(as.character(d$variation_id), d$classification, acc_m1d_classes(), "ordinal"))
    for (n in names(values)) {
      expect_true(acc_m1d_shown(tokens, values[[n]], 1), label = sprintf("%s: %s %s appears in the vignette", which, n, format(values[[n]], digits = 6)))
    }
    shares <- c(full_agreement = acc_m1d_full_agreement(d), conflict = acc_m1d_conflict(d))
    for (n in names(shares)) {
      expect_true(acc_m1d_shown(tokens, shares[[n]], c(1, 100)),
                  label = sprintf("%s: share %s %s appears in the vignette (share or percent)", which, n, format(shares[[n]], digits = 6)))
    }
  }
})

test_that("K-M1d-4: the vignette shows for both subsets the item and submitter components and %GRR of the ordinal fit (ACC-7)", {
  k <- acc_m1d_knit(acc_m1d_4_name)
  expect_null(k$error)
  tokens <- acc_m1d_4_tokens()
  for (which in names(acc_m1d_clinvar_files)) {
    shown <- FALSE
    fits <- character()
    for (link in c("probit", "logit")) {
      v <- acc_m1d_4_fit(which, link)
      if (inherits(v, "error")) { fits <- c(fits, paste(link, conditionMessage(v))); next }
      fits <- c(fits, paste(link, paste(names(v), format(v, digits = 6), collapse = ", ")))
      if (all(vapply(v, function(x) acc_m1d_shown(tokens, x, 1), logical(1)))) { shown <- TRUE; break }
    }
    expect_true(shown, label = sprintf("%s: components item, prompt (submitter) and %%GRR of msa_fit(type = \"ordinal\") appear in the vignette (%s)",
                                       which, paste(fits, collapse = "; ")))
  }
})

test_that("K-M1d-4: the sensitivity analysis with review_status \"criteria provided\" shows alpha (nominal, ordinal) for both subsets (ACC-7)", {
  k <- acc_m1d_knit(acc_m1d_4_name)
  expect_null(k$error)
  tokens <- acc_m1d_4_tokens()
  expect_true(grepl("criteria provided", acc_m1d_norm(k$lines), fixed = TRUE), label = "the vignette names the review status criteria provided")
  for (which in names(acc_m1d_clinvar_files)) {
    d <- acc_m1d_criteria_provided(acc_m1d_clinvar_subset(which))
    expect_true(nrow(d) > 0L, label = paste(which, "has rows with criteria provided"))
    if (!nrow(d)) next
    for (metric in c("nominal", "ordinal")) {
      v <- acc_m1d_kripp(as.character(d$variation_id), d$classification, acc_m1d_classes(), metric)
      expect_true(acc_m1d_shown(tokens, v, 1),
                  label = sprintf("%s, criteria provided: %s alpha %s appears in the vignette", which, metric, format(v, digits = 6)))
    }
  }
})

test_that("K-M1d-4: the vignette names ANK-42 to ANK-46 and shows every value of these anchors (ankerRef: ANK-42, ANK-43, ANK-44, ANK-45, ANK-46)", {
  k <- acc_m1d_knit(acc_m1d_4_name)
  expect_null(k$error)
  text <- acc_m1d_norm(k$lines)
  tokens <- acc_m1d_4_tokens()
  for (id in acc_m1d_literature) {
    expect_true(acc_m1d_has_id(text, id), label = paste("the vignette names", id))
    for (v in acc_m1a_leaves(acc_anchor(id)$value)) {
      expect_true(acc_m1d_shown(tokens, v, c(1, 0.01, 100)), label = sprintf("%s: value %s appears in the vignette", id, format(v, scientific = FALSE)))
    }
  }
  expect_true(grepl("not an acceptance criterion", text, ignore.case = TRUE),
              label = "the vignette states that the literature comparison is not an acceptance criterion")
})

test_that("K-M1d-4: the anchor values are read, not typed into clinvar-raters.Rmd; copies under inst/ equal reference/anchors/ (ankerRef: ANK-42 to ANK-46)", {
  values <- unlist(lapply(acc_m1d_literature, function(id) acc_m1a_leaves(acc_anchor(id)$value)))
  typed <- acc_m1d_typed_literals(acc_m1d_vignette_path(acc_m1d_4_name), values, min_sig = 3L, min_int = 100)
  expect_identical(typed, character(), label = "anchor values typed into clinvar-raters.Rmd")
  copies <- list.files(file.path(acc_pkg_root(), "inst"), pattern = "^ANK-4[2-6]\\.json$", recursive = TRUE, full.names = TRUE)
  for (f in copies) {
    expect_identical(acc_sha256(f), acc_sha256(file.path(acc_repo_root(), "reference", "anchors", basename(f))),
                     label = paste("copy", f, "equals reference/anchors"))
  }
})
