test_that("whole-word matching consumes phrases and rejects ambiguous or embedded labels", {
  p <- ap1_test_plan()
  parse <- acmg_parser(p)
  expect_identical(parse("Likely pathogenic, LP"), "Likely pathogenic")
  expect_identical(parse("Pathogenicity cannot be assessed"), NA_character_)
  expect_identical(parse("Benign or likely benign"), NA_character_)
  expect_identical(parse("(vous), UNCERTAIN significance"), "Uncertain significance")
  expect_identical(parse("B/LB"), NA_character_)
  expect_identical(parse("LB__likely-benign"), "Likely benign")
  for (empty in list(NULL, NA_character_, "", character())) expect_identical(parse(empty), NA_character_)
  expect_identical(parse_choice(c("Benign", "Likely benign"))("benignity"), "Benign")
  expect_error(parse_choice("x", whole_word = NA), "whole_word")
})

test_that("whole-word parsing is invariant to case and punctuation between words", {
  p <- ap1_test_plan(); parse <- acmg_parser(p)
  # A generated property over all anchored aliases, with noise that is not a label.
  for (label in names(p$aliases)) for (alias in unlist(p$aliases[[label]])) {
    for (sep in c(" ", "\n", "-", "_", ";")) {
      text <- paste0("[result] ", gsub(" ", sep, toupper(alias), fixed = TRUE), "!")
      expect_identical(parse(text), label, info = text)
    }
  }
})

test_that("prompt-specific parsers preserve raw responses and execution order", {
  d <- msa_design(c(x = "x", y = "y"), c(plain = "{text}", json = "{text}"), "m", reps = 1, order = "fixed")
  responses <- c('"B"', '{"classification":"LB"}', '"P"', 'No JSON: B')
  calls <- 0L
  bk <- function(prompt, model, row) { calls <<- calls + 1L; responses[calls] }
  p <- parse_choice(c("B", "LB", "P"), whole_word = TRUE)
  extract <- parse_json_field("classification")
  dispatch <- list(json = function(x) p(extract(x)), unused = identity)
  r <- msa_run(d, bk, parse = p, parse_by_prompt = dispatch, verbose = FALSE)
  expect_identical(r$response, responses)
  expect_identical(r$value, c("B", "LB", "P", NA_character_))
  expect_identical(r$position, d$position)
  calls <- 0L
  default <- msa_run(d, bk, parse = p, verbose = FALSE)
  calls <- 0L
  null <- msa_run(d, bk, parse = p, parse_by_prompt = NULL, verbose = FALSE)
  expect_identical(default$value, null$value)
  for (bad in list(list(identity), list(a = 1), stats::setNames(list(identity, identity), c("a", "a")), stats::setNames(list(identity), ""))) {
    calls <- 0L
    expect_error(msa_run(d, bk, parse_by_prompt = bad, verbose = FALSE), "parse_by_prompt")
    expect_identical(calls, 0L)
  }
  calls <- 0L
  r <- msa_run(d, bk, parse = p, parse_by_prompt = list(json = function(x) stop("synthetic parser failure")), verbose = FALSE)
  expect_true(all(is.na(r$value[r$prompt_id == "json"])))
})
