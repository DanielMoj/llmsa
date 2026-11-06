# K-M3d-2: parsers (property test). parse_number() (decimal point and comma,
# sign, exponents, units in the text), parse_choice() (aliases, upper and lower
# case, surrounding text) and parse_json_field() (valid JSON, JSON in text,
# broken JSON) never raise an error on ANK-TOL.parser_cases random inputs per
# parser (generator seed from the same entry), return the expected value for
# valid forms and NA for invalid ones. The generators (setup-m3d.R) know the
# expected value of every input; the grammar of valid and invalid forms is
# ACC-4 to ACC-6. parse_choice() inputs are checked a second time with the
# mini-references of K-M2-3 (setup-m2.R), JSON inputs with jsonlite as the
# oracle of JSON validity, so that a generator error cannot pass as a parser
# defect.

# Checks parser results against the cases; `valid_ok(case, result)` decides a
# valid form. Reports the number of errors and wrong results with examples.
acc_m3d_2_check <- function(cases, results, valid_ok, what) {
  err <- vapply(results, inherits, NA, "error")
  ok <- mapply(function(cs, r) {
    if (inherits(r, "error") || length(r) != 1L) return(FALSE)
    if (cs$valid) isTRUE(valid_ok(cs, r)) else is.na(r)
  }, cases, results)
  show <- function(i) paste(vapply(utils::head(i, 5L), function(j) acc_m3d_show(cases[[j]], results[[j]]), ""), collapse = "; ")
  expect_identical(sum(err), 0L, label = sprintf("%s: inputs raising an error (examples: %s)", what, show(which(err))))
  expect_identical(sum(!ok), 0L, label = sprintf("%s: wrong results out of %d (examples: %s)", what, length(cases), show(which(!ok))))
}

test_that("K-M3d-2: parse_number() never fails on random inputs, returns the number for valid forms (decimal point and comma, sign, exponent, units in the text) and NA otherwise (ankerRef: ANK-TOL.parser_cases)", {
  n <- acc_m3d_parser_n()
  expect_identical(n, 10000L)
  cases <- acc_m3d_cases(acc_m3d_number_case, n, acc_m3d_parser_seed())
  # the generator covers both decimal marks, valid and invalid forms, signs and exponents
  dec <- vapply(cases, `[[`, "", "decimal")
  valid <- vapply(cases, `[[`, NA, "valid")
  texts <- vapply(cases, function(cs) if (is.na(cs$text)) "" else cs$text, "")
  expect_true(all(c(".", ",") %in% dec[valid]) && any(!valid))
  expect_true(any(valid & grepl("[0-9][eE][-+]?[0-9]", texts)) && any(valid & grepl("(^|[^0-9])[-+−][.,]?[0-9]", texts)))
  parsers <- list("." = parse_number(), "," = parse_number(decimal = ","))
  results <- lapply(cases, function(cs) acc_m3d_try(parsers[[cs$decimal]], cs$text))
  acc_m3d_2_check(cases, results, function(cs, r) is.numeric(r) && !is.na(r) && r == cs$expected, "parse_number()")
})

test_that("K-M3d-2: parse_choice() never fails on random inputs, returns the class for valid forms (aliases, upper and lower case, surrounding text) and NA otherwise (ankerRef: ANK-TOL.parser_cases, ANK-69)", {
  ctx <- acc_m3d_choice_context()
  cases <- acc_m3d_cases(acc_m3d_choice_case, acc_m3d_parser_n(), acc_m3d_parser_seed(), ctx)
  whole <- vapply(cases, `[[`, NA, "whole_word")
  forms <- vapply(cases, `[[`, "", "form")
  expect_true(all(c(TRUE, FALSE) %in% whole) && all(c("one class", "no class", "two classes") %in% forms))
  # second check of the generator: the mini-references of K-M2-3 give the same values
  ref <- vapply(cases, function(cs) {
    if (cs$whole_word) acc_m2_parse_ww(cs$text, ctx$classes, ctx$whole) else acc_m2_parse_v010(cs$text, ctx$classes, as.list(ctx$substring))
  }, "")
  expected <- vapply(cases, `[[`, "", "expected")
  expect_identical(ref, expected, label = "mini-references of K-M2-3 on the generated inputs")
  parsers <- list(substring = parse_choice(ctx$classes, aliases = as.list(ctx$substring)),
                  whole = parse_choice(ctx$classes, aliases = as.list(ctx$whole), whole_word = TRUE))
  results <- lapply(cases, function(cs) acc_m3d_try(parsers[[if (cs$whole_word) "whole" else "substring"]], cs$text))
  acc_m3d_2_check(cases, results, function(cs, r) is.character(r) && !is.na(r) && r == cs$expected, "parse_choice()")
})

test_that("K-M3d-2: parse_json_field() never fails on random inputs, returns the field for valid JSON, JSON in text or a code fence, and NA for broken JSON or a missing field (ankerRef: ANK-TOL.parser_cases)", {
  cases <- acc_m3d_cases(acc_m3d_json_case, acc_m3d_parser_n(), acc_m3d_parser_seed(), list(classes = acc_m2_classes()))
  forms <- vapply(cases, `[[`, "", "form")
  expect_true(all(c("valid", "no object", "truncated", "field missing", "field only in the second object") %in% forms) &&
                sum(startsWith(forms, "syntax error")) > 0L)
  # second check of the generator: jsonlite decides validity and the field value
  sane <- vapply(cases, function(cs) {
    if (cs$form == "valid") {
      if (!isTRUE(jsonlite::validate(cs$json))) return(FALSE)
      v <- jsonlite::fromJSON(cs$json, simplifyVector = FALSE)[[cs$field]]
      if (cs$expected_kind == "string") is.character(v) && identical(enc2utf8(v), enc2utf8(cs$expected)) else
        identical(as.character(v), cs$expected)
    } else if (cs$form %in% c("field missing", "field only in the second object")) {
      isTRUE(jsonlite::validate(cs$json)) && is.null(jsonlite::fromJSON(cs$json, simplifyVector = FALSE)[[cs$field]])
    } else if (cs$form == "no object") {
      is.na(cs$text) || !grepl("{", cs$text, fixed = TRUE)
    } else {
      !isTRUE(jsonlite::validate(cs$json))
    }
  }, NA)
  expect_identical(sum(!sane), 0L, label = "generated JSON inputs whose form jsonlite contradicts")
  parsers <- lapply(stats::setNames(acc_m3d_json_fields, acc_m3d_json_fields), parse_json_field)
  results <- lapply(cases, function(cs) acc_m3d_try(parsers[[cs$field]], cs$text))
  acc_m3d_2_check(cases, results, function(cs, r) is.character(r) && !is.na(r) && identical(enc2utf8(r), enc2utf8(cs$expected)),
                  "parse_json_field()")
})
