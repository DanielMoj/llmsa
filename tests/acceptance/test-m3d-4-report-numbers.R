# K-M3d-4: number fidelity of the report. Every metric rendered by msa_report()
# (variance components, % Contribution, % Study variation, ndc, ICC, verdict,
# kappa, alpha, accuracy, bias interval, Lenth values, Westgard violations)
# equals the value in the object passed, after rounding to the digits the
# template fixes (ANK-93: template at commit 332a2d5). The test renders the
# report as GitHub Markdown, parses lines and tables of the sections and
# compares; the printed number must carry exactly the anchored decimals and lie
# within half a unit of its last digit (docs/01 §2 Nr. 6) plus
# ANK-TOL.arithmetic. The bootstrap table holds intervals of the same gauge R&R
# statistics and is checked with the bootstrap digits of the template. Fleiss'
# kappa, added to the template in M3a, takes the kappa digits. Westgard
# violations are counts and positions, integers without rounding, in a section
# that a new last argument control_chart of msa_report() fills. Parse
# contract: ACC-10 and ACC-11.

acc_m3d_4_main <- function() {
  lines <- acc_m3d_report_main()
  if (!acc_m3d_report_ok(lines, "full")) return(NULL)
  lines
}

test_that("K-M3d-4: the variance-component table shows variance, SD, % Contribution and % Study variation of every source of the msa_grr object (ankerRef: ANK-93)", {
  lines <- acc_m3d_4_main()
  if (is.null(lines)) return(invisible())
  sec <- acc_m3d_section_or_fail(lines, "Precision", "Precision")
  if (is.null(sec)) return(invisible())
  cols <- c("Source", "Variance", "SD", "% Contribution", "% Study variation")
  tab <- acc_m3d_table(sec, cols)
  expect_false(is.null(tab), label = "a table with the columns Source, Variance, SD, % Contribution, % Study variation")
  if (is.null(tab)) return(invisible())
  g <- acc_m3d_numeric_study()$grr$table
  expect_identical(length(tab$rows), nrow(g), label = "rows of the variance-component table")
  fields <- c(Variance = "variance", SD = "sd", "% Contribution" = "pct_contribution", "% Study variation" = "pct_study_var")
  digits <- c(variance = "variance", sd = "sd", pct_contribution = "pct_contribution", pct_study_var = "pct_study_var")
  for (i in seq_len(nrow(g))) {
    rows <- acc_m3d_rows(tab, "Source", trimws(g$source[i]))
    expect_length(rows, 1L)
    if (length(rows) != 1L) next
    for (col in names(fields)) {
      acc_m3d_expect_rounded(acc_m3d_cell(tab, rows[[1]], col), g[[fields[[col]]]][i], acc_m3d_digits(digits[[fields[[col]]]]),
                             sprintf("%s, %s", trimws(g$source[i]), col))
    }
  }
})

test_that("K-M3d-4: the gauge R&R summary shows % study variation, % contribution, repeatability, reproducibility, ndc and ICC of the msa_grr object (ankerRef: ANK-93)", {
  lines <- acc_m3d_4_main()
  if (is.null(lines)) return(invisible())
  sec <- acc_m3d_section_or_fail(lines, "Precision", "Precision")
  if (is.null(sec)) return(invisible())
  s <- acc_m3d_numeric_study()$grr$summary
  num <- acc_m3d_num_re
  m <- acc_m3d_matches(sec, paste0("Total gauge R&R: ", num, " % of study variation \\(", num, " % contribution\\)"))
  expect_gte(length(m), 1L, label = "lines \"Total gauge R&R: x % of study variation (y % contribution)\"")
  for (x in m) {
    acc_m3d_expect_rounded(x[2], s[["grr_pct_study_var"]], acc_m3d_digits("grr_pct_study_var"), "GRR % study variation")
    acc_m3d_expect_rounded(x[3], s[["grr_pct_contribution"]], acc_m3d_digits("grr_pct_contribution"), "GRR % contribution")
  }
  m <- acc_m3d_matches(sec, paste0("Repeatability ", num, " %, reproducibility ", num, " % of study variation"))
  expect_gte(length(m), 1L, label = "lines \"Repeatability x %, reproducibility y % of study variation\"")
  for (x in m) {
    acc_m3d_expect_rounded(x[2], s[["repeatability_pct_study_var"]], acc_m3d_digits("repeatability_pct_study_var"), "repeatability % study variation")
    acc_m3d_expect_rounded(x[3], s[["reproducibility_pct_study_var"]], acc_m3d_digits("reproducibility_pct_study_var"), "reproducibility % study variation")
  }
  m <- acc_m3d_matches(sec, paste0("Number of distinct categories \\(ndc\\): (Inf|NA|[0-9]+); ICC\\(items\\) = ", num))
  expect_gte(length(m), 1L, label = "lines \"Number of distinct categories (ndc): n; ICC(items) = x\"")
  for (x in m) {
    ndc <- s[["ndc"]]
    expect_identical(x[2], if (is.na(ndc)) "NA" else if (is.infinite(ndc)) "Inf" else format(ndc), label = "printed ndc")
    acc_m3d_expect_rounded(x[3], s[["icc_items"]], acc_m3d_digits("icc_items"), "ICC(items)")
  }
})

test_that("K-M3d-4: the bootstrap table shows estimate and interval of every gauge R&R statistic of the msa_boot object (ankerRef: ANK-93)", {
  lines <- acc_m3d_4_main()
  if (is.null(lines)) return(invisible())
  sec <- acc_m3d_section_or_fail(lines, "Precision", "Precision")
  if (is.null(sec)) return(invisible())
  tab <- acc_m3d_table(sec, c("statistic", "estimate", "lower", "upper"))
  expect_false(is.null(tab), label = "a table with the columns statistic, estimate, lower, upper")
  if (is.null(tab)) return(invisible())
  b <- as.data.frame(acc_m3d_boot())
  expect_identical(length(tab$rows), nrow(b), label = "rows of the bootstrap table")
  for (i in seq_len(nrow(b))) {
    rows <- acc_m3d_rows(tab, "statistic", b$statistic[i])
    expect_length(rows, 1L)
    if (length(rows) != 1L) next
    for (field in c("estimate", "lower", "upper")) {
      acc_m3d_expect_rounded(acc_m3d_cell(tab, rows[[1]], field), b[[field]][i], acc_m3d_digits(paste0("boot_", field)),
                             sprintf("bootstrap %s, %s", b$statistic[i], field))
    }
  }
})

test_that("K-M3d-4: the verdict in the precision section and in the conclusion is the verdict of the msa_grr object (ankerRef: ANK-93)", {
  lines <- acc_m3d_4_main()
  if (is.null(lines)) return(invisible())
  verdict <- toupper(acc_m3d_numeric_study()$grr$verdict)
  sec <- acc_m3d_section_or_fail(lines, "Precision", "Precision")
  if (!is.null(sec)) {
    m <- acc_m3d_matches(sec, "Classification: ([A-Za-z]+)")
    expect_gte(length(m), 1L, label = "lines \"Classification: VERDICT\"")
    for (x in m) expect_identical(toupper(x[2]), verdict, label = "verdict in the precision section")
  }
  con <- acc_m3d_section_or_fail(lines, "Conclusion", "Conclusion")
  if (!is.null(con)) {
    m <- acc_m3d_matches(con, "classifies the pipeline as ([A-Za-z]+)")
    expect_gte(length(m), 1L, label = "lines \"... classifies the pipeline as VERDICT\"")
    for (x in m) expect_identical(toupper(x[2]), verdict, label = "verdict in the conclusion")
  }
})

test_that("K-M3d-4: Cohen's kappa, Fleiss' kappa and Krippendorff's alpha in the report equal the msa_agreement object (ankerRef: ANK-93)", {
  lines <- acc_m3d_4_main()
  if (is.null(lines)) return(invisible())
  sec <- acc_m3d_section_or_fail(lines, "Agreement", "Agreement")
  if (is.null(sec)) return(invisible())
  ag <- acc_m3d_agreement()
  num <- acc_m3d_num_re
  m <- acc_m3d_matches(sec, paste0("Cohen's kappa \\(modal response vs reference\\) ", num, ", \\(all responses vs reference\\) ", num))
  expect_gte(length(m), 1L, label = "lines \"Cohen's kappa (modal response vs reference) x, (all responses vs reference) y\"")
  for (x in m) {
    acc_m3d_expect_rounded(x[2], ag$kappa[["kappa_modal_vs_reference"]], acc_m3d_digits("kappa"), "kappa modal vs reference")
    acc_m3d_expect_rounded(x[3], ag$kappa[["kappa_all_vs_reference"]], acc_m3d_digits("kappa"), "kappa all vs reference")
  }
  expect_false(is.na(ag$fleiss$kappa), label = "fixture: Fleiss' kappa is defined")
  m <- acc_m3d_matches(sec, paste0("Fleiss' kappa: ", num))
  expect_gte(length(m), 1L, label = "lines \"Fleiss' kappa: x\"")
  for (x in m) acc_m3d_expect_rounded(x[2], ag$fleiss$kappa, acc_m3d_digits("kappa"), "Fleiss' kappa")
  tab <- acc_m3d_table(sec, c("scope", "alpha"))
  expect_false(is.null(tab), label = "a table with the columns scope and alpha")
  if (is.null(tab)) return(invisible())
  expect_identical(length(tab$rows), nrow(ag$alpha), label = "rows of the alpha table")
  for (i in seq_len(nrow(ag$alpha))) {
    rows <- acc_m3d_rows(tab, "scope", ag$alpha$scope[i])
    expect_length(rows, 1L)
    if (length(rows) == 1L) {
      acc_m3d_expect_rounded(acc_m3d_cell(tab, rows[[1]], "alpha"), ag$alpha$alpha[i], acc_m3d_digits("alpha"), paste("alpha,", ag$alpha$scope[i]))
    }
  }
})

test_that("K-M3d-4: accuracy overall, items correct in every call and accuracy per prompt and model equal the msa_agreement object (ankerRef: ANK-93)", {
  lines <- acc_m3d_4_main()
  if (is.null(lines)) return(invisible())
  sec <- acc_m3d_section_or_fail(lines, "Agreement", "Agreement")
  if (is.null(sec)) return(invisible())
  ag <- acc_m3d_agreement()
  num <- acc_m3d_num_re
  m <- acc_m3d_matches(sec, paste0("Accuracy: ", num, " % of responses correct; ", num, " % of items correct in every call"))
  expect_gte(length(m), 1L, label = "lines \"Accuracy: x % of responses correct; y % of items correct in every call\"")
  for (x in m) {
    acc_m3d_expect_rounded(x[2], ag$accuracy_overall, acc_m3d_digits("accuracy_overall"), "accuracy overall")
    acc_m3d_expect_rounded(x[3], ag$pct_items_all_correct, acc_m3d_digits("pct_items_all_correct"), "items correct in every call")
  }
  tab <- acc_m3d_table(sec, c("prompt_id", "model_id", "pct_correct"))
  expect_false(is.null(tab), label = "a table with the columns prompt_id, model_id, pct_correct")
  if (is.null(tab)) return(invisible())
  acc <- ag$accuracy
  expect_identical(length(tab$rows), nrow(acc), label = "rows of the accuracy table")
  for (i in seq_len(nrow(acc))) {
    rows <- Filter(function(r) identical(acc_m3d_cell(tab, r, "prompt_id"), acc$prompt_id[i]) &&
                     identical(acc_m3d_cell(tab, r, "model_id"), acc$model_id[i]), tab$rows)
    expect_length(rows, 1L)
    if (length(rows) == 1L) {
      acc_m3d_expect_rounded(acc_m3d_cell(tab, rows[[1]], "pct_correct"), acc$pct_correct[i], acc_m3d_digits("accuracy_pct_correct"),
                             sprintf("accuracy %s/%s", acc$prompt_id[i], acc$model_id[i]))
    }
  }
})

test_that("K-M3d-4: the bias interval overall and per prompt and model equals the msa_bias object (ankerRef: ANK-93)", {
  lines <- acc_m3d_4_main()
  if (is.null(lines)) return(invisible())
  sec <- acc_m3d_section_or_fail(lines, "Bias", "Bias and linearity")
  if (is.null(sec)) return(invisible())
  bi <- acc_m3d_bias()
  o <- bi$overall
  num <- acc_m3d_num_re
  m <- acc_m3d_matches(sec, paste0("Mean bias ", num, " \\(([0-9]+) % CI ", num, " to ", num, ";"))
  expect_gte(length(m), 1L, label = "lines \"Mean bias x (L % CI a to b; ...\"")
  for (x in m) {
    acc_m3d_expect_rounded(x[2], o[["bias"]], acc_m3d_digits("bias"), "mean bias")
    acc_m3d_expect_rounded(x[3], 100 * bi$level, acc_m3d_digits("bias_level_percent"), "confidence level in percent")
    acc_m3d_expect_rounded(x[4], o[["lower"]], acc_m3d_digits("bias_lower"), "lower limit")
    acc_m3d_expect_rounded(x[5], o[["upper"]], acc_m3d_digits("bias_upper"), "upper limit")
  }
  tab <- acc_m3d_table(sec, c("prompt_id", "model_id", "bias", "lower", "upper"))
  expect_false(is.null(tab), label = "a table with the columns prompt_id, model_id, bias, lower, upper")
  if (is.null(tab)) return(invisible())
  bc <- bi$by_condition
  expect_identical(length(tab$rows), nrow(bc), label = "rows of the bias table")
  for (i in seq_len(nrow(bc))) {
    rows <- Filter(function(r) identical(acc_m3d_cell(tab, r, "prompt_id"), bc$prompt_id[i]) &&
                     identical(acc_m3d_cell(tab, r, "model_id"), bc$model_id[i]), tab$rows)
    expect_length(rows, 1L)
    if (length(rows) != 1L) next
    for (field in c("bias", "lower", "upper")) {
      acc_m3d_expect_rounded(acc_m3d_cell(tab, rows[[1]], field), bc[[field]][i], acc_m3d_digits(paste0("by_condition_", field)),
                             sprintf("%s %s/%s", field, bc$prompt_id[i], bc$model_id[i]))
    }
  }
})

test_that("K-M3d-4: Lenth's PSE, ME, SME, the effects, t values and activity flags equal the msa_robustness object (ankerRef: ANK-93)", {
  lines <- acc_m3d_4_main()
  if (is.null(lines)) return(invisible())
  sec <- acc_m3d_section_or_fail(lines, "Robustness", "Robustness")
  if (is.null(sec)) return(invisible())
  ro <- acc_m3d_robustness()
  num <- acc_m3d_num_re
  m <- acc_m3d_matches(sec, paste0("Lenth PSE ", num, ", ME ", num, ", SME ", num))
  expect_gte(length(m), 1L, label = "lines \"Lenth PSE x, ME y, SME z\"")
  for (x in m) {
    acc_m3d_expect_rounded(x[2], attr(ro, "pse"), acc_m3d_digits("lenth_pse"), "PSE")
    acc_m3d_expect_rounded(x[3], attr(ro, "me"), acc_m3d_digits("lenth_me"), "ME")
    acc_m3d_expect_rounded(x[4], attr(ro, "sme"), acc_m3d_digits("lenth_sme"), "SME")
  }
  tab <- acc_m3d_table(sec, c("factor", "effect", "t_lenth", "active", "active_simultaneous"))
  expect_false(is.null(tab), label = "a table with the columns factor, effect, t_lenth, active, active_simultaneous")
  if (is.null(tab)) return(invisible())
  expect_identical(length(tab$rows), nrow(ro), label = "rows of the effects table")
  for (i in seq_len(nrow(ro))) {
    rows <- acc_m3d_rows(tab, "factor", ro$factor[i])
    expect_length(rows, 1L)
    if (length(rows) != 1L) next
    acc_m3d_expect_rounded(acc_m3d_cell(tab, rows[[1]], "effect"), ro$effect[i], acc_m3d_digits("effect"), paste("effect", ro$factor[i]))
    acc_m3d_expect_rounded(acc_m3d_cell(tab, rows[[1]], "t_lenth"), ro$t_lenth[i], acc_m3d_digits("t_lenth"), paste("t_lenth", ro$factor[i]))
    expect_identical(toupper(acc_m3d_cell(tab, rows[[1]], "active")), toupper(as.character(ro$active[i])), label = paste("active", ro$factor[i]))
    expect_identical(toupper(acc_m3d_cell(tab, rows[[1]], "active_simultaneous")), toupper(as.character(ro$active_simultaneous[i])),
                     label = paste("active_simultaneous", ro$factor[i]))
  }
})

test_that("K-M3d-4: msa_report(control_chart = ) lists the violations of every Westgard rule with count and positions as in the msa_control_chart object", {
  lines <- acc_m3d_report_chart()
  if (!acc_m3d_report_ok(lines, "control-chart")) return(invisible())
  sec <- acc_m3d_section_or_fail(lines, ".*(Westgard|control chart|system suitability)", "on Westgard rules or the control chart")
  if (is.null(sec)) return(invisible())
  tab <- acc_m3d_table(sec, c("Rule", "Violations", "Positions"))
  expect_false(is.null(tab), label = "a table with the columns Rule, Violations, Positions")
  if (is.null(tab)) return(invisible())
  cc <- acc_m3d_chart()
  rules <- c(attr(cc, "rules"), "reject")
  expect_identical(length(tab$rows), length(rules), label = "rows of the violations table (every rule and reject)")
  for (rule in rules) {
    fired <- cc$index[cc[[rule]] %in% TRUE]
    if (rule != "reject") expect_gt(length(fired), 0L, label = paste("fixture: rule", rule, "fires"))
    rows <- acc_m3d_rows(tab, "Rule", rule)
    expect_length(rows, 1L)
    if (length(rows) != 1L) next
    expect_identical(acc_m3d_integers(acc_m3d_cell(tab, rows[[1]], "Violations")), length(fired), label = paste("violations of", rule))
    expect_identical(acc_m3d_integers(acc_m3d_cell(tab, rows[[1]], "Positions")), as.integer(fired), label = paste("positions of", rule))
  }
})
