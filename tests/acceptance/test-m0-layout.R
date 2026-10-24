# K-M0-5: repository layout of the preset r-paket. Exit codes of
# git check-ignore: 0 = a path is ignored, 1 = no path is ignored, 128 = error.
# An error therefore never counts as "empty" output.

test_that("K-M0-5: git does not ignore docs/00-vision.md", {
  root <- acc_repo_root()
  literal <- acc_git(root, "check-ignore", "docs/00-vision.md")
  expect_identical(literal$status, 1L, info = paste(literal$stderr, collapse = "\n"))
  expect_identical(literal$stdout, character())
  # Without --no-index git check-ignore never reports a tracked file, and
  # docs/00-vision.md is tracked, so the literal form alone could not fail
  # (docs/01-fachspezifikation.md §2 no. 1). --no-index evaluates the ignore
  # rules themselves: docs/ must no longer be ignored (BL-19; CRITERIA.json,
  # open item ACC-2).
  rules <- acc_git(root, "check-ignore", "--no-index", "docs/00-vision.md")
  expect_identical(rules$status, 1L, info = paste(rules$stderr, collapse = "\n"))
  expect_identical(rules$stdout, character())
})

test_that("K-M0-5: git ignores reference/quellen/ and reference/privat/", {
  root <- acc_repo_root()
  for (probe in c("reference/quellen/probe.txt", "reference/privat/probe.txt")) {
    result <- acc_git(root, "check-ignore", probe)
    expect_identical(result$status, 0L, info = paste(c(probe, result$stderr), collapse = "\n"))
    expect_identical(result$stdout, probe, info = probe)
  }
})

test_that("K-M0-5: _pkgdown.yml builds the site into pkgdown-site", {
  lines <- readLines(file.path(acc_repo_root(), "_pkgdown.yml"), warn = FALSE)
  # a top-level key, neither indented nor commented out
  expect_true(any(grepl("^destination: pkgdown-site[[:space:]]*$", lines)))
})

test_that("K-M0-5: .Rbuildignore excludes the site, the specs and the harness folders", {
  # compared line by line without trimming: R CMD build uses each line as a
  # regular expression, surrounding blanks included
  lines <- readLines(file.path(acc_repo_root(), ".Rbuildignore"), warn = FALSE)
  for (entry in c("^pkgdown-site$", "^docs$", "^reference$", "^orchestrator$",
                  "^tests/acceptance$", "^tests/simulation$", "^tests/fixtures$")) {
    expect_true(entry %in% lines, info = entry)
  }
})
