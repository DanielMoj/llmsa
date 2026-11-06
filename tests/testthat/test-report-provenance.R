# Small synthetic byte examples and presentation checks, not numerical oracles.
report_provenance_runs <- function() {
  data.frame(block = c(2L, 1L), item_id = c("i2", "i1"), prompt_id = "p", model_id = "m",
              rep = 1L, value = c('a,"b"\nnext', NA_character_), flag = c(TRUE, NA),
              amount = c(0.5, -Inf), type = factor(c("z", "\u00e9")), stringsAsFactors = FALSE)
}

test_that("canonical run bytes match an independently written CSV document", {
  skip_if_not_installed("digest")
  runs <- report_provenance_runs()
  csv <- paste0('"block","item_id","prompt_id","model_id","rep","amount","flag","type","value"\n',
                 '1,"i1","p","m",1,-Inf,NA,"\u00e9",NA\n',
                 '2,"i2","p","m",1,0.5,TRUE,"z","a,""b""\nnext"\n')
  expected <- charToRaw(enc2utf8(csv))
  expect_identical(msa_report_canonical(runs), expected)
  expect_identical(msa_report_hash(runs), digest::digest(expected, algo = "sha256", serialize = FALSE))
  expect_identical(msa_report_canonical(runs[2:1, rev(seq_along(runs))]), expected)
  attr(runs, "irrelevant") <- "not run data"
  rownames(runs) <- c("ignored-a", "ignored-b")
  expect_identical(msa_report_canonical(runs), expected)
  empty <- runs[FALSE, ]
  expect_identical(msa_report_canonical(empty), charToRaw(strsplit(csv, "\n", fixed = TRUE)[[1L]][1L]) |> c(as.raw(10L)))
})

test_that("canonical values distinguish missingness, types, double bits and duplicate keys", {
  skip_if_not_installed("digest")
  expect_identical(msa_report_csv_column(c(NA_real_, NaN, Inf, -Inf, 0.5)),
                   c("NA", "NaN", "Inf", "-Inf", "0.5"))
  expect_identical(msa_report_csv_column(c(1L, NA_integer_)), c("1", "NA"))
  expect_identical(msa_report_csv_column(c(TRUE, FALSE, NA)), c("TRUE", "FALSE", "NA"))
  expect_identical(msa_report_csv_column(c("NA", NA_character_, "")), c('"NA"', "NA", '""'))
  expect_identical(msa_report_csv_column(1 + .Machine$double.eps), "1.0000000000000002")
  runs <- report_provenance_runs()
  runs[2L, c("block", "item_id")] <- runs[1L, c("block", "item_id")]
  runs <- rbind(runs, runs[1L, ])
  base <- msa_report_hash(runs)
  expect_identical(msa_report_hash(runs[3:1, ]), base)
  expect_false(identical(msa_report_hash(runs[-1L, ]), base))
  for (field in names(runs)) {
    changed <- runs
    if (is.factor(changed[[field]])) {
      changed[[field]] <- as.character(changed[[field]])
      changed[[field]][1L] <- "new level"
    } else if (is.logical(changed[[field]])) changed[[field]][1L] <- FALSE else
      if (is.numeric(changed[[field]])) changed[[field]][1L] <- changed[[field]][1L] + 1L else
        changed[[field]][1L] <- paste0(changed[[field]][1L], "!")
    expect_false(identical(msa_report_hash(changed), base), info = field)
  }
  changed <- runs
  changed$amount[1L] <- changed$amount[1L] * (1 + .Machine$double.eps)
  expect_false(identical(msa_report_hash(changed), base))
})

test_that("canonical byte ordering and decimal points ignore display and collation options", {
  runs <- report_provenance_runs()
  runs$block <- c(10L, 2L)
  runs$item_id <- c("Z", "a")
  runs[["\u00c4 column"]] <- c(1e-20, 0.25)
  before <- msa_report_canonical(runs)
  old <- options(OutDec = ",", digits = 3, scipen = 999)
  on.exit(options(old), add = TRUE)
  collate <- Sys.getlocale("LC_COLLATE")
  on.exit(Sys.setlocale("LC_COLLATE", collate), add = TRUE)
  Sys.setlocale("LC_COLLATE", "C")
  expect_identical(msa_report_canonical(runs), before)
  text <- rawToChar(before)
  expect_match(text, '\n2,"a"', fixed = TRUE)
  expect_lt(regexpr('\n2,"a"', text, fixed = TRUE)[1], regexpr('\n10,"Z"', text, fixed = TRUE)[1])
})

test_that("model provenance keeps all observed values and reports gaps without partial matching", {
  skip_if_not_installed("jsonlite")
  runs <- data.frame(model_id = c("m", "m", "m", "n", "z", "z", "missing"),
    meta = c('{"model_snapshot":"v1","provider":"HostA","quantizations":["fp8","fp16"]}',
             '{"model_snapshot":"v2","provider":"HostB","quantizations":"fp16"}',
             '{"provider_order":["RequestedHost"]}',
             '{"model_snapshot":"only-snapshot"}',
             'model_snapshot=legacy;provider=legacy', '{broken}', NA_character_))
  result <- msa_report_models(runs)
  m <- result$table[result$table[["Model ID"]] == "m", ]
  expect_identical(m$Model, "not reported; v1; v2")
  expect_identical(m$Provider, "HostA; HostB; not reported")
  expect_identical(m$Quantization, "fp16; fp8; not reported")
  expect_false(any(grepl("RequestedHost|legacy", unlist(result$table))))
  expect_identical(result$table$Provider[result$table[["Model ID"]] == "n"], "not reported")
  expect_match(result$notes, "Model ID z: unreadable metadata in 2 row(s)", fixed = TRUE)
  expect_identical(msa_report_models(runs[rev(seq_len(nrow(runs))), ])$table, result$table)
  runs$meta <- NULL
  expect_true(all(msa_report_models(runs)$table$Model == "not reported"))
  expect_length(msa_report_models(runs)$notes, 0L)
  expect_identical(nrow(msa_report_models(NULL)$table), 0L)
})

test_that("report seeds retain integer printing and old objects report absence", {
  for (seed in list(1e6, 17006L, 0L)) {
    x <- structure(list(), seed = seed)
    expect_identical(msa_report_seed(x), sprintf("%.0f", seed))
  }
  expect_identical(msa_report_seed(NULL), "not reported")
  expect_identical(msa_report_seed(structure(list(), seed = NA_integer_)), "not reported")
})

test_that("control chart reporting counts TRUE flags and sorts actual index positions", {
  # Explicit output fixture, independent of the rule implementation.
  chart <- structure(data.frame(index = c(40L, 20L, 30L, 10L),
                                 R_4s = c(TRUE, FALSE, NA, TRUE),
                                 quiet = c(FALSE, NA, FALSE, FALSE),
                                 reject = c(TRUE, TRUE, FALSE, TRUE)),
                      rules = c("R_4s", "quiet"), class = c("msa_control_chart", "data.frame"))
  actual <- msa_report_control_chart(chart)
  expected <- data.frame(Rule = c("R_4s", "quiet", "reject"), Violations = c(2L, 0L, 3L),
                          Positions = c("10, 40", "", "10, 20, 40"))
  expect_identical(actual, expected)
  expect_null(msa_report_control_chart(NULL))
  expect_error(msa_report(structure(list(), class = "msa_grr"), control_chart = data.frame()),
                "`control_chart` must come from msa_control_chart().", fixed = TRUE)
  expect_identical(tail(names(formals(msa_report)), 1L), "control_chart")
  expect_null(formals(msa_report)$control_chart)
})

test_that("rendered Markdown and HTML retain provenance, conventions and missing ndc", {
  for (pkg in c("rmarkdown", "knitr", "digest", "jsonlite")) skip_if_not_installed(pkg)
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")
  grr <- msa_grr(msa_fit(ic50_demo, type = "numeric"))
  runs <- ic50_demo
  runs$meta <- '{"model_snapshot":"synthetic-snapshot","provider":"SyntheticHost","quantizations":["fp8"]}'
  runs$meta[1L] <- "legacy=unreadable"
  attr(runs, "design") <- structure(list(), seed = 17007L)
  chart <- msa_control_chart(c(0, 3.5, -1, 0), center = 0, sd = 1)
  grr$summary[["ndc"]] <- NA_real_  # Presentation fixture, not a numerical result.
  constants <- numeric_anchor("ANK-16")
  old <- options(OutDec = ",")
  on.exit(options(old), add = TRUE)
  for (format in c("md", "html")) {
    out <- tempfile(fileext = paste0(".", format))
    rendered <- withVisible(msa_report(grr, runs = runs, control_chart = chart, output_file = out,
      output_format = if (format == "md") rmarkdown::md_document(variant = "gfm", pandoc_args = "--wrap=none") else
        rmarkdown::html_document()))
    expect_false(rendered$visible)
    expect_identical(normalizePath(rendered$value), normalizePath(out))
    text <- paste(readLines(out, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    text <- gsub("[[:space:]]+", " ", text)
    unlink(out)
    expect_match(text, "Number of distinct categories (ndc): NA; ICC(items)", fixed = TRUE)
    expect_match(text, "SHA-256 of the canonical run table", fixed = TRUE)
    expect_match(text, msa_report_hash(runs), fixed = TRUE)
    expect_match(text, "Design seed: 17007", fixed = TRUE)
    expect_match(text, "Bootstrap seed: not reported", fixed = TRUE)
    expect_match(text, "Plackett-Burman seed: not reported", fixed = TRUE)
    expect_match(text, "synthetic-snapshot", fixed = TRUE)
    expect_match(text, "SyntheticHost", fixed = TRUE)
    expect_match(text, "unreadable metadata in 1 row(s)", fixed = TRUE)
    expect_match(text, sprintf("constant %g", constants$ndc$constant), fixed = TRUE)
    expect_match(text, sprintf("thresholds %g %% and %g %% are a convention", constants$contribution$acceptable_below,
                               constants$contribution$unacceptable_above), fixed = TRUE)
    expect_match(text, "excludes block interactions and three-way interactions", fixed = TRUE)
    expect_match(text, "range of two consecutive", fixed = TRUE)
    expect_identical(getOption("OutDec"), ",")
  }
})

test_that("reports with old runs, missing metadata and omitted objects still render", {
  for (pkg in c("rmarkdown", "knitr", "digest")) skip_if_not_installed(pkg)
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")
  grr <- msa_grr(msa_fit(ic50_demo, type = "numeric"))
  grr$summary[["ndc"]] <- Inf
  for (runs in list(NULL, ic50_demo)) {
    out <- tempfile(fileext = ".md")
    msa_report(grr, runs = runs, output_file = out,
                output_format = rmarkdown::md_document(variant = "gfm", pandoc_args = "--wrap=none"))
    text <- paste(readLines(out, warn = FALSE), collapse = "\n")
    unlink(out)
    expect_match(text, "Number of distinct categories (ndc): Inf; ICC(items)", fixed = TRUE)
    expect_match(text, "Design seed: not reported", fixed = TRUE)
    expect_match(text, "Not assessed in this validation.", fixed = TRUE)
    expect_match(text, "not reported", fixed = TRUE)
    if (is.null(runs)) expect_match(text, "not available (runs not supplied)", fixed = TRUE) else
      expect_match(text, msa_report_hash(runs), fixed = TRUE)
  }
})
