# K-M3d-6: conventions in the report. The rendered report names the ndc
# constant 1.41, the verdict thresholds with their basis, the %Contribution
# thresholds as a convention, derived two-level components, the model without
# block and three-way interactions, the R_4s reading, all seeds (design,
# bootstrap, Plackett-Burman) and per model the model identifier, provider and
# quantization from meta (Formelsammlung Nr. 6, 7, 8, 10, 13, §11). Constants
# come from ANK-16, the recorded providers and routing from ANK-94, ANK-54 and
# ANK-55. What counts as naming each item: ACC-11, ACC-13 and ACC-14.

acc_m3d_6_lines <- function(key) {
  lines <- switch(key,
    main = acc_m3d_report_main(),
    contribution = acc_m3d_report("contribution", msa_grr(acc_m3d_numeric_study()$fit, basis = "contribution")),
    chart = acc_m3d_report_chart(),
    meta = acc_m3d_report("meta", acc_m3d_numeric_study()$grr, runs = acc_m3d_meta_runs()),
    derived_model = acc_m3d_report("derived_model", acc_m3d_derived_grr("model")),
    derived_block = acc_m3d_report("derived_block", acc_m3d_derived_grr("block")))
  if (!acc_m3d_report_ok(lines, key)) return(NULL)
  lines
}

# Normalized non-table lines of `lines`.
acc_m3d_6_text <- function(lines) acc_m3d_norm(lines[!grepl("^[[:space:]]*\\|", lines) & nzchar(trimws(lines))])

test_that("K-M3d-6: the precision section names the ndc constant 1.41 (ankerRef: ANK-16)", {
  lines <- acc_m3d_6_lines("main")
  if (is.null(lines)) return(invisible())
  sec <- acc_m3d_section_or_fail(lines, "Precision", "Precision")
  if (is.null(sec)) return(invisible())
  k <- acc_m3d_value("ANK-16", "ndc", "constant")
  n <- acc_m3d_norm(sec)
  hit <- grepl("(?i)\\bndc\\b|distinct categories", n, perl = TRUE) & acc_m3d_has_number(n, k)
  expect_true(any(hit), label = sprintf("a line of the precision section names ndc and the constant %s", format(k)))
})

test_that("K-M3d-6: the verdict line names basis and thresholds, and the %Contribution thresholds are named as a convention, for both bases (ankerRef: ANK-16)", {
  a <- acc_m3d_value("ANK-16", "contribution")
  for (key in c("main", "contribution")) {
    lines <- acc_m3d_6_lines(key)
    if (is.null(lines)) next
    sec <- acc_m3d_section_or_fail(lines, "Precision", paste("Precision of the", key, "report"))
    if (is.null(sec)) next
    grr <- if (key == "main") acc_m3d_numeric_study()$grr else msa_grr(acc_m3d_numeric_study()$fit, basis = "contribution")
    base <- if (key == "main") acc_m3d_value("ANK-16", "study_var") else a
    expect_identical(as.numeric(grr$threshold), as.numeric(c(base$acceptable_below, base$unacceptable_above)),
                     label = sprintf("fixture (%s): thresholds of the msa_grr object are those of ANK-16", key))
    n <- acc_m3d_norm(sec)
    basis <- if (grr$basis == "study_var") "% study variation" else "% contribution"
    verdict_line <- grepl(paste0("(?i)Classification: ", toupper(grr$verdict)), n, perl = TRUE) &
      grepl(basis, n, fixed = TRUE) & acc_m3d_has_number(n, grr$threshold[1]) & acc_m3d_has_number(n, grr$threshold[2])
    expect_true(any(verdict_line), label = sprintf("%s report: the classification line names the basis %s and the thresholds %s / %s",
                                                     key, basis, format(grr$threshold[1]), format(grr$threshold[2])))
    text <- acc_m3d_6_text(lines)
    convention <- grepl("(?i)contribution", text, perl = TRUE) & grepl("(?i)convention", text, perl = TRUE) &
      acc_m3d_has_number(text, a$acceptable_below) & acc_m3d_has_number(text, a$unacceptable_above)
    expect_true(any(convention), label = sprintf("%s report: a line names the %%Contribution thresholds %s and %s as a convention",
                                                   key, format(a$acceptable_below), format(a$unacceptable_above)))
  }
})

test_that("K-M3d-6: the precision section names each derived two-level component with the range method (K-M1b-4)", {
  for (factor in c("model", "block")) {
    grr <- acc_m3d_derived_grr(factor)
    expect_s3_class(grr, "msa_grr")
    if (!inherits(grr, "msa_grr")) next
    expect_identical(grr$derived, factor, label = paste("fixture: derived source of the two-level", factor, "fit"))
    lines <- acc_m3d_6_lines(paste0("derived_", factor))
    if (is.null(lines)) next
    sec <- acc_m3d_section_or_fail(lines, "Precision", paste("Precision of the two-level", factor, "report"))
    if (is.null(sec)) next
    n <- acc_m3d_norm(sec)
    named <- grepl(paste0("(?i)\\b", factor, "\\b"), n, perl = TRUE) & grepl("(?i)range method|two[- ]level|two fixed levels", n, perl = TRUE)
    expect_true(any(named), label = sprintf("a line of the precision section names %s as derived by the range method", factor))
  }
})

test_that("K-M3d-6: the report names the model without block and three-way interactions (Formelsammlung Nr. 10)", {
  lines <- acc_m3d_6_lines("main")
  if (is.null(lines)) return(invisible())
  text <- acc_m3d_6_text(lines)
  hit <- grepl("(?i)interaction", text, perl = TRUE) & grepl("(?i)\\bblock", text, perl = TRUE) &
    grepl("(?i)three[- ]way|3-way|three-factor|triple", text, perl = TRUE) &
    grepl("(?i)\\bno\\b|\\bnot\\b|without|pooled|exclud|omit", text, perl = TRUE)
  expect_true(any(hit), label = "a line states that the model has no block interactions and no three-way interactions")
})

test_that("K-M3d-6: the control-chart section names the R_4s reading (range of two consecutive values; Formelsammlung Nr. 6)", {
  lines <- acc_m3d_6_lines("chart")
  if (is.null(lines)) return(invisible())
  sec <- acc_m3d_section_or_fail(lines, ".*(Westgard|control chart|system suitability)", "on Westgard rules or the control chart")
  if (is.null(sec)) return(invisible())
  text <- acc_m3d_6_text(sec)
  hit <- grepl("(?i)\\bR[ _-]?4s\\b", text, perl = TRUE) & grepl("(?i)\\brange\\b", text, perl = TRUE) &
    grepl("(?i)consecutive|successive", text, perl = TRUE)
  expect_true(any(hit), label = "a line names R_4s, the range reading and consecutive values")
})

test_that("K-M3d-6: the report names the design, bootstrap and Plackett-Burman seeds", {
  lines <- acc_m3d_6_lines("main")
  if (is.null(lines)) return(invisible())
  n <- acc_m3d_norm(lines)
  expect_identical(attr(attr(acc_m3d_numeric_study()$runs, "design"), "seed"), acc_m3d_study_seeds[["design"]],
                   label = "fixture: design seed carried by the runs")
  labels <- c(design = "(?i)\\bdesign", bootstrap = "(?i)bootstrap", plackett_burman = "(?i)Plackett[- ]Burman")
  for (kind in names(labels)) {
    seed <- acc_m3d_study_seeds[[kind]]
    found <- vapply(n, function(line) {
      if (!grepl("(?i)seed", line, perl = TRUE)) return(FALSE)
      at <- regexpr(labels[[kind]], line, perl = TRUE)
      if (at < 0L) return(FALSE)
      after <- acc_m3d_integers(substring(line, at))
      length(after) > 0L && after[1] == seed
    }, NA)
    expect_true(any(found), label = sprintf("a line names the %s seed %d (first integer after the label, line mentions seed)", kind, seed))
  }
})

test_that("K-M3d-6: the report lists per model the model identifier, provider and quantization from meta (ankerRef: ANK-94, ANK-54, ANK-55)", {
  runs <- acc_m3d_meta_runs()
  files <- acc_anchor("ANK-94")$value$files
  expect_setequal(acc_m3d_meta_values(runs, "llama", "provider"), c(files$llama.json$response_provider, acc_m3d_second_provider))
  expect_identical(acc_m3d_meta_values(runs, "qwen", "quantizations"), acc_m3d_value("ANK-55", "quantization"))
  expect_identical(acc_m3d_meta_values(runs, "llama", "quantizations"), acc_m3d_value("ANK-54", "quantization"))
  lines <- acc_m3d_6_lines("meta")
  if (is.null(lines)) return(invisible())
  tab <- acc_m3d_table(lines, c("Model ID", "Model", "Provider", "Quantization"))
  expect_false(is.null(tab), label = "a table with the columns Model ID, Model, Provider, Quantization")
  if (is.null(tab)) return(invisible())
  for (id in c("sol", "llama", "qwen")) {
    rows <- acc_m3d_rows(tab, "Model ID", id)
    expect_length(rows, 1L)
    if (length(rows) != 1L) next
    for (col in c("Model", "Provider", "Quantization")) {
      field <- c(Model = "model_snapshot", Provider = "provider", Quantization = "quantizations")[[col]]
      want <- acc_m3d_meta_values(runs, id, field)
      cell <- acc_m3d_cell(tab, rows[[1]], col)
      if (length(want)) {
        for (w in want) expect_true(grepl(w, cell, fixed = TRUE), label = sprintf("%s, %s: cell %s names %s", id, col, encodeString(cell, quote = "\""), w))
      } else {
        expect_true(grepl("(?i)not reported", cell, perl = TRUE), label = sprintf("%s, %s: cell %s says not reported", id, col, encodeString(cell, quote = "\"")))
      }
    }
  }
  expect_identical(acc_m3d_meta_values(runs, "sol", "model_snapshot"), files$sol.json$response_model)
})
