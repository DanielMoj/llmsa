# K-M1c-7: repeatability on the latent scale (ADR-040): for type = "ordinal"
# and type = "binary", print.msa_grr and inst/templates/validation_report.Rmd
# (below the line with Repeatability and Reproducibility) write the note quoted
# in docs/02 K-M1c-7; for type = "numeric" it is absent; ?msa_grr says the
# same. The note is read from docs/02 at test time; texts are compared after
# removing Markdown escapes, code and emphasis markers and quotes and
# collapsing whitespace (acc_m1c_norm_text()). The report is rendered by
# msa_report() as Markdown. The byte equality of msa_grr() and msa_boot() is
# tested in test-m1c-7-byte-equality.R. Test form: CRITERIA.json M1c, open
# ACC-13.

acc_m1c_7_latent_cases <- function() {
  list("ordinal (wine, probit)" = acc_m1b_wine_fit("probit"),
       "binary (BeetlesMale, logit)" = acc_m1b_beetles_fit())
}

acc_m1c_7_numeric_cases <- function() {
  list("numeric (ic50_demo)" = acc_m1c_grr_cases()[["numeric ic50_demo"]]$fit,
       "numeric (test design)" = acc_m1c_fit("numeric"))
}

test_that("K-M1c-7: docs/02 quotes the note, and its normalised form keeps msa_agreement()", {
  note <- acc_m1c_latent_note()
  expect_true(startsWith(note, "On the latent scale, Repeatability"), label = note)
  expect_true(grepl("msa_agreement()", acc_m1c_norm_text(note), fixed = TRUE), label = acc_m1c_norm_text(note))
})

for (case in c("ordinal (wine, probit)", "binary (BeetlesMale, logit)")) {
  test_that(sprintf("K-M1c-7: print.msa_grr writes the note for a %s fit", case), {
    fit <- acc_m1c_7_latent_cases()[[case]]
    lines <- acc_m1c_print_lines(msa_grr(fit))
    expect_true(acc_m1c_contains_note(lines),
                label = sprintf("print.msa_grr (%s) contains the note of K-M1c-7; output: %s", case, paste(lines, collapse = " | ")))
  })
}

test_that("K-M1c-7: print.msa_grr does not write the note for numeric fits", {
  for (case in names(acc_m1c_7_numeric_cases())) {
    lines <- acc_m1c_print_lines(msa_grr(acc_m1c_7_numeric_cases()[[case]]))
    expect_false(acc_m1c_contains_note(lines), label = sprintf("print.msa_grr (%s) contains the note", case))
  }
})

for (case in c("ordinal (wine, probit)", "binary (BeetlesMale, logit)")) {
  test_that(sprintf("K-M1c-7: the validation report writes the note directly below the line with Repeatability and Reproducibility for a %s fit", case), {
    report <- acc_m1c_report_lines(case, msa_grr(acc_m1c_7_latent_cases()[[case]]))
    expect_false(inherits(report, "error"),
                 label = sprintf("msa_report() renders (%s)", if (inherits(report, "error")) conditionMessage(report) else "ok"))
    if (inherits(report, "error")) return(invisible())
    section <- acc_m1c_report_precision(report)
    expect_false(is.null(section), label = "the report has section 3 (precision)")
    if (is.null(section)) return(invisible())
    block <- acc_m1c_block_below_rr(section)
    expect_false(is.null(block), label = "section 3 has exactly one line with Repeatability and Reproducibility")
    if (is.null(block)) return(invisible())
    expect_true(acc_m1c_contains_note(block),
                label = sprintf("the block below the line with Repeatability and Reproducibility (%s) is the note; block: %s",
                                case, paste(block, collapse = " | ")))
  })
}

test_that("K-M1c-7: the validation report does not write the note for a numeric fit", {
  case <- "numeric (ic50_demo)"
  report <- acc_m1c_report_lines(case, msa_grr(acc_m1c_7_numeric_cases()[[case]]))
  expect_false(inherits(report, "error"),
               label = sprintf("msa_report() renders (%s)", if (inherits(report, "error")) conditionMessage(report) else "ok"))
  if (inherits(report, "error")) return(invisible())
  expect_false(is.null(acc_m1c_report_precision(report)), label = "the report has section 3 (precision)")
  expect_false(acc_m1c_contains_note(report), label = "the numeric report contains the note")
})

test_that("K-M1c-7: ?msa_grr says the same (man/msa_grr.Rd contains the note)", {
  txt <- acc_m1b_rd_text("msa_grr")
  expect_true(acc_m1c_contains_note(txt), label = "man/msa_grr.Rd contains the note of K-M1c-7")
})
