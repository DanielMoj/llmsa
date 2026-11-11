report_chart_error <- function(expr, message) {
  error <- tryCatch(force(expr), error = identity)
  expect_s3_class(error, "error")
  expect_identical(conditionMessage(error), message)
  expect_null(conditionCall(error))
}

test_that("reporting validates the chart and its reading before rendering", {
  grr <- structure(list(), class = "msa_grr")
  report_chart_error(msa_report(list()), "`grr` must come from msa_grr().")
  report_chart_error(msa_report(grr, control_chart = list()), "`control_chart` must come from msa_control_chart().")
  chart <- msa_control_chart(c(0, 2.5, -1.6), 0, 1)
  for (value in list(c("range", "westgard"), numeric(), 1, NA_character_, "unknown")) {
    attr(chart, "r4s") <- value
    report_chart_error(msa_report(grr, control_chart = chart),
                       "The control chart `r4s` attribute must be 'range' or 'westgard'.")
  }
})

test_that("assessment validation names each malformed field and preserves valid assessments", {
  valid <- list(criteria = data.frame(criterion = "synthetic", band = "marginal"),
                verdict = "marginal", sections = list(Note = list(text = "A synthetic note.")))
  message <- paste0("`assessment` requires criteria (criterion, band), a verdict string and named sections ",
                    "with text and optional data.frame table.")
  invalid <- list(NULL, "text", list(), valid[-1L], valid[-2L], valid[-3L])
  replace <- function(field, value) { x <- valid; x[field] <- list(value); x }
  invalid <- c(invalid, list(replace("criteria", list(criterion = "x", band = "x")),
    replace("criteria", data.frame(criterion = "x")), replace("criteria", data.frame(band = "x"))))
  for (value in list(1, character(), c("a", "b"), NA_character_, "")) {
    invalid <- c(invalid, list(replace("verdict", value)))
  }
  for (value in list("text", list(list(text = "unnamed")),
                    stats::setNames(list(list(text = "x")), NA_character_),
                    stats::setNames(list(list(text = "x")), ""),
                    list(A = list(text = "x"), A = list(text = "y")),
                    list(A = 1), list(A = list()), list(A = list(text = 1)),
                    list(A = list(text = NA_character_)), list(A = list(text = "x", table = matrix(1))))) {
    invalid <- c(invalid, list(replace("sections", value)))
  }
  for (x in invalid) report_chart_error(validate_assessment(x), message)
  for (x in list(valid, replace("sections", list()),
                 replace("sections", list(A = list(text = c("one", "two"), table = data.frame(value = 1)))))) {
    result <- withVisible(validate_assessment(x))
    expect_identical(result$value, x)
    expect_false(result$visible)
  }
})

test_that("missing rendering dependencies and templates have exact public diagnostics", {
  grr <- structure(list(), class = "msa_grr")
  for (missing in c("rmarkdown", "knitr")) {
    # Keep the product body; override only the dependency lookup in its parent.
    render <- msa_report
    environment(render) <- new.env(parent = environment(msa_report))
    environment(render)$requireNamespace <- function(package, ...) package != missing
    report_chart_error(render(grr), "Rendering needs packages `rmarkdown` and `knitr`.")
  }
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  local_mocked_bindings(pandoc_available = function(...) FALSE, .package = "rmarkdown")
  report_chart_error(msa_report(grr), "pandoc was not found; install pandoc or use RStudio/Positron.")
  local_mocked_bindings(pandoc_available = function(...) TRUE, .package = "rmarkdown")
  render <- msa_report
  environment(render) <- new.env(parent = environment(msa_report))
  environment(render)$system.file <- function(...) ""
  report_chart_error(render(grr), "Report template not found in the installed package.")
})

test_that("the render contract carries the reading separately from the unchanged violations table", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  recorded <- NULL
  local_mocked_bindings(pandoc_available = function(...) TRUE,
    render = function(input, output_format, output_file, output_dir, params, envir, quiet) {
      recorded <<- list(input = input, output_format = output_format, output_file = output_file,
                        output_dir = output_dir, params = params, envir = envir, quiet = quiet,
                        decimal = getOption("OutDec"))
      file.path(output_dir, output_file)
    }, .package = "rmarkdown")
  grr <- structure(list(), class = "msa_grr")
  chart <- msa_control_chart(c(0, 2.5, -1.6, 0, 2.1, -2.1), 0, 1, r4s = "westgard")
  expected <- msa_report_control_chart(chart)
  output <- tempfile(fileext = ".html")
  old_options <- options(OutDec = ",")
  on.exit(options(old_options), add = TRUE)
  returned <- withVisible(msa_report(grr, control_chart = chart, cou = "use", question = "question",
    risk = "high", acceptance = "criteria", title = "title", author = "author", output_file = output,
    output_format = "html_document", quiet = FALSE))
  expect_identical(recorded$params$control_chart_reading, "westgard")
  expect_identical(recorded$params$control_chart, expected)
  expect_identical(recorded$params[c("cou", "question", "risk", "acceptance", "title", "author")],
                   list(cou = "use", question = "question", risk = "high", acceptance = "criteria", title = "title", author = "author"))
  expect_identical(recorded$output_file, basename(output))
  expect_identical(recorded$output_dir, dirname(normalizePath(output, mustWork = FALSE)))
  expect_identical(recorded$output_format, "html_document")
  expect_true(is.environment(recorded$envir))
  expect_identical(parent.env(recorded$envir), globalenv())
  expect_false(recorded$quiet)
  expect_identical(recorded$decimal, ".")
  expect_identical(getOption("OutDec"), ",")
  # On Windows dirname() and rmarkdown::render() return forward slashes; compare normalized paths.
  expect_identical(normalizePath(returned$value, winslash = "/", mustWork = FALSE),
                   normalizePath(output, winslash = "/", mustWork = FALSE))
  expect_false(returned$visible)
  template <- system.file("templates", "validation_report.Rmd", package = "llmsa", mustWork = TRUE)
  expect_identical(readLines(recorded$input), readLines(template))
  attr(chart, "r4s") <- NULL
  msa_report(grr, control_chart = chart, output_file = output)
  expect_identical(recorded$params$control_chart_reading, "range")
  expect_identical(recorded$params$control_chart, expected)
  expect_true(recorded$quiet)
  msa_report(grr, output_file = output)
  expect_null(recorded$params$control_chart)
  expect_null(recorded$params$control_chart_reading)
  local_mocked_bindings(render = function(...) stop("Synthetic rendering failure.", call. = FALSE), .package = "rmarkdown")
  report_chart_error(msa_report(grr, output_file = output), "Synthetic rendering failure.")
  expect_identical(getOption("OutDec"), ",")
})

test_that("actual HTML reports distinguish both readings and support old cards", {
  for (package in c("rmarkdown", "knitr")) skip_if_not_installed(package)
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")
  grr <- msa_grr(msa_fit(ic50_demo, type = "numeric"))
  for (reading in c("range", "westgard", "legacy")) {
    chart <- msa_control_chart(c(0, 2.5, -1.6, 0, 2.1, -2.1), 0, 1,
                               r4s = if (reading == "westgard") "westgard" else "range")
    if (reading == "legacy") attr(chart, "r4s") <- NULL
    before <- chart
    path <- tempfile(fileext = ".html")
    result <- withVisible(msa_report(grr, control_chart = chart, output_file = path))
    expect_identical(normalizePath(result$value, winslash = "/"), normalizePath(path, winslash = "/"))
    expect_false(result$visible)
    text <- gsub("[[:space:]]+", " ", paste(readLines(path, warn = FALSE), collapse = " "))
    sentence <- if (reading == "westgard") paste0("R_4s uses the Westgard reading: one of two consecutive ",
      "standardized values is above 2 and the other below -2.") else
      "R_4s uses the range of two consecutive standardized values."
    expect_true(grepl(sentence, text, fixed = TRUE), info = sentence)
    expect_true(grepl("<th[^>]*>Rule</th>", text))
    expect_true(grepl("<th[^>]*>Positions</th>", text))
    expect_identical(chart, before)
  }
})
