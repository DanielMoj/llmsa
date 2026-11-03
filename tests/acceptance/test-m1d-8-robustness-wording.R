# K-M1d-8: wording of the robustness result (ADR-045). Without a factor above
# ME, print.msa_robustness and inst/templates/validation_report.Rmd write the
# sentence quoted in docs/02 with the ME of the run in place of x, to four
# decimals as in the line with PSE, ME and SME; "robust to all screened
# perturbations" no longer occurs in R/ and inst/templates/. With factors above
# ME, both outputs name every such factor with "above ME only" or "also above
# SME" (column active_simultaneous). The object of msa_robustness() and the
# bands stay unchanged: compared with done/M1c (ANK-34) on the same inputs.
# Contract details: ACC-11.

acc_m1d_8_expected <- function(x) {
  me <- formatC(attr(x, "me"), format = "f", digits = 4)
  sub("(ME = x)", paste0("(ME = ", me, ")"), acc_m1d_robust_sentence(), fixed = TRUE)
}

test_that("K-M1d-8: the test cases hold one run without factor above ME and one with factors above ME only and above SME", {
  cases <- acc_m1d_robustness_cases()
  none <- msa_robustness(cases$none$design, cases$none$response)
  mixed <- msa_robustness(cases$mixed$design, cases$mixed$response)
  expect_false(any(none$active))
  expect_true(any(mixed$active & !mixed$active_simultaneous) && any(mixed$active_simultaneous))
})

test_that("K-M1d-8: without a factor above ME, print.msa_robustness writes the sentence of docs/02 with the ME of the run to four decimals", {
  cases <- acc_m1d_robustness_cases()
  x <- msa_robustness(cases$none$design, cases$none$response)
  out <- utils::capture.output(print(x))
  expect_true(grepl(acc_m1d_norm(acc_m1d_8_expected(x)), acc_m1d_norm(out), fixed = TRUE),
              label = sprintf("print output holds „%s“", acc_m1d_8_expected(x)))
  expect_identical(acc_m1d_me_in_pse_line(out), formatC(attr(x, "me"), format = "f", digits = 4),
                   label = "the ME of the line with PSE, ME and SME, four decimals")
  expect_false(grepl(acc_m1d_old_phrase, paste(out, collapse = " "), fixed = TRUE), label = "the old phrase in the print output")
  expect_false(grepl(acc_m1d_suffix_only, paste(out, collapse = " "), fixed = TRUE) ||
                 grepl(acc_m1d_suffix_sme, paste(out, collapse = " "), fixed = TRUE), label = "a factor suffix without an active factor")
})

test_that("K-M1d-8: with factors above ME, print.msa_robustness names each of them with \"above ME only\" or \"also above SME\"", {
  cases <- acc_m1d_robustness_cases()
  x <- msa_robustness(cases$mixed$design, cases$mixed$response)
  out <- utils::capture.output(print(x))
  expect_true(acc_m1d_suffixes_ok(out, x),
              label = sprintf("every active factor carries its suffix (%s); output: %s",
                              paste(x$factor[x$active], ifelse(x$active_simultaneous[x$active], acc_m1d_suffix_sme, acc_m1d_suffix_only), collapse = "; "),
                              paste(utils::tail(out, 4), collapse = " | ")))
  expect_false(grepl("No factor exceeded", paste(out, collapse = " "), fixed = TRUE), label = "the sentence for the case without active factor")
  expect_false(grepl(acc_m1d_old_phrase, paste(out, collapse = " "), fixed = TRUE), label = "the old phrase in the print output")
})

test_that("K-M1d-8: without a factor above ME, the report section 6 writes the sentence of docs/02 with the ME of the run to four decimals", {
  cases <- acc_m1d_robustness_cases()
  x <- msa_robustness(cases$none$design, cases$none$response)
  sec <- acc_m1d_report_robustness("none", x)
  expect_false(inherits(sec, "error"), label = if (inherits(sec, "error")) conditionMessage(sec) else "msa_report() renders")
  if (inherits(sec, "error")) return(invisible())
  expect_true(length(sec) > 0L, label = "the report has the section 6. Robustness")
  expect_true(grepl(acc_m1d_norm(acc_m1d_8_expected(x)), acc_m1d_norm(sec), fixed = TRUE),
              label = sprintf("report section 6 holds „%s“", acc_m1d_8_expected(x)))
  expect_identical(acc_m1d_me_in_pse_line(sec), formatC(attr(x, "me"), format = "f", digits = 4),
                   label = "the ME of the line with PSE, ME and SME in the report, four decimals")
  expect_false(grepl(acc_m1d_old_phrase, paste(sec, collapse = " "), fixed = TRUE), label = "the old phrase in the report")
})

test_that("K-M1d-8: with factors above ME, the report section 6 names each of them with \"above ME only\" or \"also above SME\"", {
  cases <- acc_m1d_robustness_cases()
  x <- msa_robustness(cases$mixed$design, cases$mixed$response)
  sec <- acc_m1d_report_robustness("mixed", x)
  expect_false(inherits(sec, "error"), label = if (inherits(sec, "error")) conditionMessage(sec) else "msa_report() renders")
  if (inherits(sec, "error")) return(invisible())
  expect_true(length(sec) > 0L, label = "the report has the section 6. Robustness")
  expect_true(acc_m1d_suffixes_ok(sec, x), label = "every active factor carries its suffix in the report")
  expect_false(grepl("No factor exceeded", paste(sec, collapse = " "), fixed = TRUE), label = "the sentence for the case without active factor")
})

test_that("K-M1d-8: \"robust to all screened perturbations\" occurs in no file under R/ and inst/templates/", {
  root <- acc_pkg_root()
  files <- c(list.files(file.path(root, "R"), full.names = TRUE, recursive = TRUE),
             list.files(file.path(root, "inst", "templates"), full.names = TRUE, recursive = TRUE))
  expect_true(length(files) > 0L)
  hits <- files[vapply(files, function(f) any(grepl(acc_m1d_old_phrase, readLines(f, warn = FALSE), fixed = TRUE)), logical(1))]
  expect_identical(hits, character(), label = "files with the old phrase")
})

test_that("K-M1d-8: the object of msa_robustness() is identical to done/M1c (ankerRef: ANK-34)", {
  old_fun <- get("msa_robustness", envir = acc_m1d_baseline(), inherits = FALSE)
  cases <- acc_m1d_robustness_cases()
  d <- cases$mixed$design
  plain <- as.data.frame(attr(d, "coded"))
  calls <- list(
    "no active factor" = list(design = cases$none$design, response = cases$none$response),
    "above ME and SME" = list(design = d, response = cases$mixed$response),
    "alpha 0.10" = list(design = d, response = cases$mixed$response, alpha = 0.10),
    "factor subset" = list(design = d, response = cases$mixed$response, factors = c("F1", "F2", "F5", "F7", "F9")),
    "plain data.frame" = list(design = plain, response = cases$mixed$response, factors = names(plain))
  )
  for (n in names(calls)) {
    expect_identical(do.call(msa_robustness, calls[[n]]), do.call(old_fun, calls[[n]]), label = paste("msa_robustness(),", n),
                     expected.label = "done/M1c")
  }
})

test_that("K-M1d-8: the robustness bands of acmg_robustness() are identical to done/M1c for acceptable, marginal and unacceptable (ankerRef: ANK-34, ANK-58)", {
  plan <- llmsa:::acmg_plan()
  old_fun <- get("acmg_robustness", envir = acc_m1d_baseline(), inherits = FALSE)
  k <- length(plan$robustness$factors)
  settings <- list(
    flat = rep(0, k),
    one_strong = c(1.2, rep(0, k - 1L)),
    spread = c(0.30, -0.28, 0.26, -0.24, 0.22, -0.20, 0.18, -0.16)[seq_len(k)],
    mixed = c(0.9, 0.25, -0.2, 0.15, rep(0, k - 4L)),
    small = c(0.05, -0.04, 0.03, rep(0, k - 3L))
  )
  bands <- character()
  for (n in names(settings)) {
    s <- acc_m1d_pb_runs(plan, settings[[n]])
    new <- llmsa:::acmg_robustness(s$runs, s$modal, s$item_ids, plan)
    old <- old_fun(s$runs, s$modal, s$item_ids, plan)
    expect_identical(new, old, label = paste("acmg_robustness(),", n), expected.label = "done/M1c")
    bands <- c(bands, new$band)
  }
  expect_setequal(intersect(bands, c("acceptable", "marginal", "unacceptable")), c("acceptable", "marginal", "unacceptable"))
})
