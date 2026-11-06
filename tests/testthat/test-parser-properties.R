test_that("Unicode minus preserves number meaning with both decimal marks", {
  for (decimal in c(".", ",")) {
    parser <- parse_number(decimal)
    for (number in c("-12.5", "-.25", "-4E+2", "1e-3", "+0.75")) {
      text <- gsub(".", decimal, number, fixed = TRUE)
      unicode <- gsub("-", "\u2212", text, fixed = TRUE)
      expect_identical(parser(paste("IC50 =", unicode, "mg/m3")), as.numeric(number))
      expect_identical(parser(paste("IC50 =", text, "mg/m3")), as.numeric(number))
    }
  }
})

test_that("JSON extraction decodes strings and reads only the first object's top level", {
  skip_if_not_installed("jsonlite")
  extract <- parse_json_field("value")
  cases <- c(
    '{"nested":{"value":"wrong"},"value":"right"}' = "right",
    '{"note":"} { \\\"","value":"line\\nnext\\t\\u00e9\\/\\\\"}' = "line\nnext\t\u00e9/\\",
    '{"value":-1.25e2,"array":[{},null,true]}' = "-125",
    '{"value":"first"} {"value":"second"}' = "first",
    '{"value":""}' = "")
  for (json in names(cases)) {
    for (wrapped in c(json, paste("Answer:", json, "End."), paste0("```json\r\n", json, "\r\n```"))) {
      expect_identical(expect_no_warning(extract(wrapped)), unname(cases[[json]]))
    }
  }
  expect_identical(parse_json_field("a.b")('{"axb":"wrong","a.b":"right"}'), "right")
  expect_identical(parse_json_field("a\"b")('{"a\\\"b":"escaped key"}'), "escaped key")
})

test_that("malformed or non-scalar JSON cannot yield an apparent field value", {
  skip_if_not_installed("jsonlite")
  extract <- parse_json_field("value")
  bad <- list(NULL, character(), NA_character_, "", "no object",
              '{"value":"x",}', '{"value":"x" "other":1}', '{"value" "x"}',
              '{"value":"x","other":"\\x"}', '{"value":"x","other":}',
              "{'value':'x'}", '{value:"x"}', '{"value":"unfinished}',
              '{"nested":{"value":"x"}}', '{} {"value":"second"}',
              '{"value":"unfinished" {"value":"second"}',
              '{"value":null}', '{"value":[]}', '{"value":["x"]}',
              '{"value":{"label":"x"}}', '{"value":true}', '{"value":false}')
  for (text in bad) expect_identical(expect_no_warning(extract(text)), NA_character_)
})

test_that("malformed JSON text is never interpreted as a file path", {
  skip_if_not_installed("jsonlite")
  # jsonlite::fromJSON("{x}") would read this file; parse_json must reject it.
  dir <- tempfile("synthetic-json-path-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  previous <- setwd(dir)
  on.exit(setwd(previous), add = TRUE)
  writeLines('{"value":"must not be read"}', "{x}")
  expect_identical(expect_no_warning(parse_json_field("value")("{x}")), NA_character_)
})

test_that("JSON parser construction gives the documented missing-package error", {
  # Keep the factory body intact while making its optional dependency absent.
  factory <- parse_json_field
  dependencies <- new.env(parent = environment(factory))
  dependencies$requireNamespace <- function(package, quietly = FALSE) FALSE
  environment(factory) <- dependencies
  err <- tryCatch(factory("value"), error = identity)
  expect_s3_class(err, "error")
  expect_identical(conditionMessage(err),
                   "Package `jsonlite` is required for parse_json_field(); install it to use this parser.")
  expect_null(conditionCall(err))
})
