# QA / Red Team fuzz & boundary tests for M3d (fixed seed: 20261106)

test_that("QA-M3d-FUZZ-1: parse_number, parse_choice and parse_json_field withstand adversarial inputs, nested keys, escapes and path lookalikes (seed = 20261106)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  skip_if_not_installed("jsonlite")
  set.seed(20261106L)

  # 1. parse_number() edge cases across decimal marks, Unicode minus, exponents, glued identifiers
  p_dot <- parse_number(".")
  p_comma <- parse_number(",")
  u_minus <- intToUtf8(0x2212L)
  ws_only <- paste0("   ", intToUtf8(c(0x09L, 0x0aL, 0x0dL)), " ")
  for (bad in list(NULL, character(0L), NA_character_, "", ws_only, "-", "+", u_minus, ".", ",", "e", "E", "-.e+", "N/A (not determined)")) {
    expect_identical(expect_no_warning(p_dot(bad)), NA_real_)
    expect_identical(expect_no_warning(p_comma(bad)), NA_real_)
  }
  expect_identical(p_dot(paste0("CYP3A4 H2O pIC50 = ", u_minus, "0.0025e+2 mg/m3 (est.)")), -0.25)
  expect_identical(p_comma(paste0("CYP3A4 H2O pIC50 = ", u_minus, "0,0025E+2 mg/m3 (est.)")), -0.25)
  expect_identical(p_dot("EC50: (.125nM)"), 0.125)
  expect_identical(p_comma(paste0("EC50: (", u_minus, ",125nM)")), -0.125)
  expect_identical(p_dot("IC50 = 4.5 nM (replicate 2: 9.9 nM)"), 4.5)

  # 2. parse_choice() boundary cases in substring and whole-word modes
  classes <- c("Benign", "Likely benign", "Uncertain significance", "Likely pathogenic", "Pathogenic")
  aliases <- list(
    B = "Benign",
    LB = "Likely benign",
    VUS = "Uncertain significance",
    VOUS = "Uncertain significance",
    uncertain = "Uncertain significance",
    LP = "Likely pathogenic",
    P = "Pathogenic"
  )
  pc_sub <- parse_choice(classes, aliases = aliases[c("VUS", "VOUS", "uncertain")], whole_word = FALSE)
  pc_ww <- parse_choice(classes, aliases = aliases, whole_word = TRUE)

  for (bad_ww in list(NA, c(TRUE, FALSE), logical(0L), "TRUE", 1L, NULL)) {
    err <- tryCatch(parse_choice(classes, whole_word = bad_ww), error = identity)
    expect_s3_class(err, "error")
    expect_null(conditionCall(err))
    expect_match(conditionMessage(err), "`whole_word` must be TRUE or FALSE.", fixed = TRUE)
  }

  expect_identical(pc_sub("Classification: lIkElY pAtHoGeNiC (PS1, PM2)"), "Likely pathogenic")
  expect_identical(pc_ww("Criteria PS1, PM2, PVS1 met -> LP (Likely Pathogenic)"), "Likely pathogenic")
  expect_identical(pc_ww("Either VUS or VOUS (uncertain significance)"), "Uncertain significance")
  expect_identical(pc_ww("Conflicting: LP vs Benign"), NA_character_)
  expect_identical(pc_ww(c("Benign", "Pathogenic")), NA_character_)
  expect_identical(pc_ww(NULL), NA_character_)
  expect_identical(pc_ww(character(0L)), NA_character_)

  # 3. parse_json_field() adversarial braces, quotes before '{', escapes, nested keys and non-scalars
  pj <- parse_json_field("class")
  bs <- intToUtf8(0x5cL)
  nl <- intToUtf8(0x0aL)
  tb <- intToUtf8(0x09L)
  cr <- intToUtf8(0x0dL)
  ae <- intToUtf8(0x00e4L)
  obj1 <- list(
    nested = list(class = "Benign"),
    quote_brace = paste0('} { " ', bs),
    class = "Likely pathogenic",
    arr = list(1L, list(class = "VUS"))
  )
  json1 <- as.character(jsonlite::toJSON(obj1, auto_unbox = TRUE))
  txt1 <- paste0('Note: do not pick "wrong" before brace! ', json1, ' trailing {"class":"Benign"}')
  expect_identical(expect_no_warning(pj(txt1)), "Likely pathogenic")

  val2 <- paste0("line1", nl, "line2", tb, ae, "/", bs, '"}')
  obj2 <- list(meta = list(class = "Benign"), class = val2)
  json2 <- as.character(jsonlite::toJSON(obj2, auto_unbox = TRUE))
  txt2 <- paste("```json", json2, "```", sep = paste0(cr, nl))
  expect_identical(expect_no_warning(pj(txt2)), val2)

  txt3 <- 'Prefix with unmatched quote " and apostrophe then {"class": -42.5, "other": true}'
  expect_identical(expect_no_warning(pj(txt3)), "-42.5")

  adversarial_invalid <- list(
    NULL, character(0L), NA_character_, c('{"class":"VUS"}', '{"class":"Benign"}'),
    "", "plain text without braces", "https://example.com/data.json", "{nonexistent_file.json}",
    '{"nested":{"class":"VUS"}}',
    '{"other":"ok"} {"class":"VUS"}',
    '{"class":null}', '{"class":true}', '{"class":false}',
    '{"class":["VUS"]}', '{"class":{"nested":"VUS"}}',
    '{"class":"VUS",}', '{"class":"VUS" "other":1}', '{"class":"unterminated}'
  )
  for (bad in adversarial_invalid) {
    expect_identical(expect_no_warning(pj(bad)), NA_character_)
  }
})

test_that("QA-M3d-FUZZ-2: canonical run-table SHA-256 and report provenance helpers satisfy permutation invariance and 1-ULP sensitivity (seed = 20261106)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  for (pkg in c("digest", "jsonlite")) skip_if_not_installed(pkg)
  set.seed(20261106L)

  base_runs <- data.frame(
    block = c(2L, 1L, 1L, NA_integer_),
    item_id = c("I10", "I2", "I2", "I1"),
    prompt_id = c("P2", "P1", "P1", "P1"),
    model_id = c("m2", "m1", "m1", NA_character_),
    rep = c(1L, 2L, 1L, 1L),
    value = c("NA", NA_character_, "", 'quote "and"
newline'),
    score = c(1.0, 1.0 + .Machine$double.eps, NaN, -Inf),
    flag = c(TRUE, FALSE, NA, TRUE),
    grade = factor(c("b", "a", NA, "b"), levels = c("a", "b")),
    stringsAsFactors = FALSE
  )

  raw_base <- llmsa:::msa_report_canonical(base_runs)
  hash_base <- llmsa:::msa_report_hash(base_runs)
  expect_match(hash_base, "^[0-9a-f]{64}$")

  # 1. Permutation invariance across 25 random row + column permutations and hostile options
  for (i in seq_len(25L)) {
    perm_r <- sample.int(nrow(base_runs))
    perm_c <- sample.int(ncol(base_runs))
    shuffled <- base_runs[perm_r, perm_c, drop = FALSE]
    rownames(shuffled) <- paste0("row_", seq_len(nrow(shuffled)))
    attr(shuffled, "custom_attr") <- list(seed = i, note = "ignored")
    expect_identical(llmsa:::msa_report_canonical(shuffled), raw_base)
    expect_identical(llmsa:::msa_report_hash(shuffled), hash_base)
  }

  old_env_opts <- options(OutDec = ",", scipen = 999, digits = 2)
  on.exit(options(old_env_opts), add = TRUE)
  expect_identical(llmsa:::msa_report_canonical(base_runs), raw_base)
  options(old_env_opts)

  # 2. Strict sensitivity to 1-ULP double changes, special values, and string vs NA distinctions
  mutations <- list(
    ulp = { m <- base_runs; m$score[1L] <- 1.0 - .Machine$double.neg.eps; m },
    nan_to_na = { m <- base_runs; m$score[3L] <- NA_real_; m },
    neginf_to_posinf = { m <- base_runs; m$score[4L] <- Inf; m },
    na_str_to_na = { m <- base_runs; m$value[1L] <- NA_character_; m },
    empty_to_na = { m <- base_runs; m$value[3L] <- NA_character_; m },
    dup_row = rbind(base_runs, base_runs[2L, , drop = FALSE])
  )
  for (nm in names(mutations)) {
    expect_false(identical(llmsa:::msa_report_hash(mutations[[nm]]), hash_base), info = nm)
  }

  # 3. Provenance helper edge cases: msa_report_seed, msa_report_models, msa_report_control_chart
  expect_identical(llmsa:::msa_report_seed(structure(list(), seed = 0L)), "0")
  expect_identical(llmsa:::msa_report_seed(structure(list(), seed = 1e6)), "1000000")
  expect_identical(llmsa:::msa_report_seed(structure(list(), seed = c(1L, 2L))), "not reported")
  expect_identical(llmsa:::msa_report_seed(structure(list(), seed = NA_real_)), "not reported")

  mod_res <- llmsa:::msa_report_models(base_runs)
  expect_identical(mod_res$table[["Model ID"]], c("m1", "m2", "not reported"))
  expect_true(all(mod_res$table$Model == "not reported"))
  expect_length(mod_res$notes, 0L)

  chart_zero <- msa_control_chart(c(0.1, -0.1, 0.2, -0.2), center = 0, sd = 1)
  tab_zero <- llmsa:::msa_report_control_chart(chart_zero)
  expect_true(all(tab_zero$Violations == 0L))
  expect_true(all(tab_zero$Positions == ""))
})
