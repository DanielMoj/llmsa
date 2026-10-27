test_that("pilot parser success requires all keys and counts recognized classes, not correctness", {
  p <- ap1_test_plan(); r <- ap1_test_pilot(p)
  rule <- function(data, name, model = "sol") {
    x <- acmg_pilot(data, p)$rules
    x$passed[x$model == model & x$rule == name]
  }
  expect_true(rule(r, "parser"))
  sol <- which(r$model_id == "sol")
  r$value[tail(sol, p$pilot$parser_hits_of - p$pilot$parser_hits_min)] <- NA
  expect_true(rule(r, "parser"))
  r$value[sol[1]] <- NA
  expect_false(rule(r, "parser"))
  r <- ap1_test_pilot(p)
  expect_false(rule(r[-sol[1], ], "parser"))
  duplicate <- r; duplicate[sol[2], ] <- duplicate[sol[1], ]
  expect_false(rule(duplicate, "parser"))
  r$error[sol[1:4]] <- "synthetic backend failure"
  expect_false(rule(r, "parser"))
})

test_that("pilot HTTP and provider rules distinguish observed facts from missing metadata", {
  p <- ap1_test_plan(); r <- ap1_test_pilot(p)
  rule <- function(data, name, model = "sol") {
    x <- acmg_pilot(data, p)$rules
    x$passed[x$model == model & x$rule == name]
  }
  for (text in c("HTTP 400 Bad Request.", "HTTP/1.1 499 Client error", "HTTP status code: 429")) {
    bad <- r; bad$error[1] <- text
    expect_false(rule(bad, "4xx"), info = text)
  }
  for (text in c("HTTP 500 Internal error", "read 400 tokens", "error 499", "HTTP 200 OK")) {
    bad <- r; bad$error[1] <- text
    expect_true(rule(bad, "4xx"), info = text)
  }
  expect_true(rule(r, "provider"))
  r$meta[1] <- '{}'
  expect_false(rule(r, "provider"))
  r <- ap1_test_pilot(p); i <- which(r$model_id == "llama")[1]
  m <- jsonlite::fromJSON(r$meta[i], simplifyVector = FALSE)
  m$provider <- NULL; r$meta[i] <- meta_to_json(m)
  expect_false(rule(r, "provider", "llama"))
  expect_true(any(grepl("/api/v1/generation", acmg_pilot(r, p)$rules$reason, fixed = TRUE)))
  m$provider <- "wrong-provider"; r$meta[i] <- meta_to_json(m)
  expect_false(rule(r, "provider", "llama"))
  r <- ap1_test_pilot(p); r$meta <- '{"mock":true}'
  expect_true(rule(r, "4xx"))
  expect_false(rule(r, "provider"))
  expect_false(rule(r, "cost"))
})

test_that("pilot cost uses a global strict budget and never double-counts reasoning", {
  p <- ap1_test_plan(); r <- ap1_test_pilot(p)
  expect_true(acmg_pilot(r, p)$passed)
  n <- p$design$items * (p$design$prompts * p$design$replicates * p$design$blocks + p$robustness$runs)
  expected <- sum(vapply(p$models, function(m) n * (p$tokens$input * m$price_in + 100 * m$price_out) / 1e6, 0))
  expect_equal(acmg_pilot(r, p)$projected_usd, expected, tolerance = p$validation_tolerances$arithmetic)
  varied <- r
  for (key in names(acmg_models(p))) {
    index <- which(varied$model_id == key)
    varied$meta[index] <- vapply(seq_along(index), function(tokens) ap1_test_meta(key, p, completion = tokens, reasoning = 0), "")
  }
  # With tokens 1:n, the type-7 interpolated quantile equals 1 + (n - 1) * q.
  q90 <- 1 + (p$pilot$calls_per_model - 1) * p$pilot$cost_quantile
  projected <- sum(vapply(p$models, function(m) n * (p$tokens$input * m$price_in + q90 * m$price_out) / 1e6, 0))
  expect_equal(acmg_pilot(varied, p)$projected_usd, projected, tolerance = p$validation_tolerances$arithmetic)
  r$meta <- vapply(r$model_id, ap1_test_meta, "", plan = p, reasoning = 100000)
  expect_equal(acmg_pilot(r, p)$projected_usd, expected, tolerance = p$validation_tolerances$arithmetic)
  p$budget$budget_eur <- expected
  expect_false(any(acmg_pilot(r, p)$rules$passed[acmg_pilot(r, p)$rules$rule == "cost"]))
  p$budget$budget_eur <- expected + 1
  expect_true(acmg_pilot(r, p)$passed)
  p$budget$budget_eur <- expected - 1
  expect_false(acmg_pilot(r, p)$passed)
  p <- ap1_test_plan()
  for (field in c("usage", "completion_tokens")) {
    bad <- r; meta <- jsonlite::fromJSON(bad$meta[1], simplifyVector = FALSE)
    if (field == "usage") meta$usage <- NULL else meta$usage$completion_tokens <- NULL
    bad$meta[1] <- meta_to_json(meta)
    expect_false(acmg_pilot(bad, p)$passed)
    expect_true(is.na(acmg_pilot(bad, p)$projected_usd))
  }
  bad <- r; bad$error[bad$model_id == "qwen"] <- "HTTP 500"
  expect_false(acmg_pilot(bad, p)$passed)
})

test_that("stores retain provenance, including failures, and mismatches do not change bytes", {
  skip_if_not_installed("DBI"); skip_if_not_installed("RSQLite")
  p <- ap1_test_plan()
  store <- tempfile(fileext = ".sqlite")
  acmg_store_init(store, "api")
  rec <- empty_runs()[NA_integer_, ]; rec$error <- "HTTP 400 synthetic"; rec$meta <- NA_character_
  append_store(store, rec)
  before <- acmg_hash(store)
  expect_error(acmg_store_read(store, "mock"), "provenance")
  expect_identical(acmg_hash(store), before)
  expect_identical(attr(acmg_store_read(store, "api"), "ap1_mode"), "api")
  mock_store <- tempfile(fileext = ".db")
  acmg_store_init(mock_store, "mock")
  expect_error(acmg_store_read(mock_store, "api"), "provenance")
  rec$meta <- ap1_test_meta("sol", p)
  append_store(mock_store, rec)
  before <- acmg_hash(mock_store)
  expect_error(acmg_store_read(mock_store, "mock"), "mixed")
  expect_identical(acmg_hash(mock_store), before)
  mixed <- ap1_test_pilot(p); mixed$meta[1] <- '{"mock":true}'
  expect_error(acmg_provenance(mixed), "mixed")
  no_meta <- mixed; no_meta$meta <- NULL
  expect_identical(acmg_provenance(no_meta), "unverified")
  no_meta$meta <- '{"mock":true}'
  expect_identical(acmg_provenance(no_meta), "synthetic")
  partial <- ap1_test_pilot(p); partial$meta[1] <- NA_character_
  expect_identical(acmg_provenance(partial), "unverified")
})

test_that("API robustness still requires a passing pilot after a valid synthetic TSV preflight", {
  for (pkg in c("httr2", "DBI", "RSQLite")) skip_if_not_installed(pkg)
  p <- ap1_test_plan(); items <- acmg_items(); insaid <- items[items$source == "insaid", ]
  synthetic <- data.frame(gene = insaid$gene, cdna = sub("^[^:]+:", "", insaid$hgvs),
                           protein = "p.SyntheticProtected", classification = "Benign", status = "Validated")
  path <- tempfile(fileext = ".tsv")
  utils::write.table(synthetic, path, sep = "\t", quote = FALSE, row.names = FALSE)
  expected_hash <- acmg_hash(path)
  local_mocked_bindings(acmg_insaid_hash = function() expected_hash)
  store <- tempfile(fileext = ".sqlite"); acmg_store_init(store, "api"); before <- acmg_hash(store)
  calls <- 0L
  httr2::local_mocked_responses(function(req) { calls <<- calls + 1L; stop("Unexpected request") })
  expect_error(acmg_run_cli(c("--part", "robustness", "--backend", "api", "--store", store, "--insaid-path", path)), "pilot")
  expect_identical(acmg_hash(store), before)
  expect_identical(calls, 0L)
  joined <- acmg_items(path)
  d <- acmg_design(joined, p, "robustness")
  prompt <- acmg_prompt_table(p)
  rows <- d$item_id %in% insaid$item_id
  f2 <- prompt$F2[match(d$prompt_id[rows], prompt$prompt_id)]
  expect_identical(grepl("p.SyntheticProtected", d$prompt[rows], fixed = TRUE), f2 > 0)
  expect_false(any(grepl("p.SyntheticProtected", acmg_design(joined, p, "main")$prompt, fixed = TRUE)))
  expect_true(all(acmg_items()$protein[items$source == "insaid"] == ""))
})

test_that("evaluate-only uses store provenance and never constructs an API backend", {
  for (pkg in c("DBI", "RSQLite")) skip_if_not_installed(pkg)
  p <- ap1_test_plan(); store <- tempfile(fileext = ".sqlite")
  acmg_store_init(store, "api")
  item <- acmg_items(); item <- item[item$source == "insaid", ][1, ]
  row <- empty_runs()[NA_integer_, ]
  row$item_id <- item$item_id; row$model_id <- "sol"; row$prompt_id <- "concise"
  row$rep <- 1L; row$block <- 1L; row$value <- acmg_classes(p)[1]
  row$error <- NA_character_; row$meta <- ap1_test_meta("sol", p)
  append_store(store, row)
  before <- acmg_hash(store); evaluated <- FALSE
  local_mocked_bindings(acmg_api_backends = function(...) stop("API constructor must not run in evaluation"),
                        acmg_evaluate = function(runs, plan) {
                          evaluated <<- TRUE
                          expect_identical(attr(runs, "ap1_mode"), "api")
                          expect_true(is.na(runs$reference))
                          runs
                        })
  expect_message(acmg_run_cli(c("--evaluate-only", "--backend", "api", "--store", store)), "INSAID references not loaded")
  expect_true(evaluated)
  expect_identical(acmg_hash(store), before)
})

test_that("CLI rejects missing mode, non-SQLite paths and failed pilots before requests or writes", {
  for (pkg in c("httr2", "DBI", "RSQLite")) skip_if_not_installed(pkg)
  p <- ap1_test_plan(); store <- tempfile(fileext = ".sqlite")
  calls <- 0L
  httr2::local_mocked_responses(function(req) { calls <<- calls + 1L; stop("Unexpected request") })
  expect_error(acmg_run_cli(c("--part", "pilot", "--store", store)), "explicit --backend")
  expect_false(file.exists(store))
  expect_error(acmg_run_cli(c("--part", "pilot", "--backend", "mock", "--store", paste0(store, ".csv"))), "SQLite|sqlite")
  expect_false(file.exists(paste0(store, ".csv")))
  expect_error(acmg_run_cli(c("--part", "main", "--backend", "api", "--store", store)), "pilot")
  expect_false(file.exists(store))
  expect_error(acmg_run_cli(c("--part", "robustness", "--backend", "api", "--store", store)), "insaid-path")
  fake <- tempfile(fileext = ".tsv"); writeLines("synthetic invalid TSV", fake)
  expect_error(acmg_run_cli(c("--part", "robustness", "--backend", "api", "--store", store, "--insaid-path", fake)), "SHA-256")
  acmg_store_init(store, "api"); before <- acmg_hash(store)
  expect_error(acmg_run_cli(c("--part", "main", "--backend", "api", "--store", store)), "pilot")
  expect_identical(acmg_hash(store), before)
  expect_error(acmg_run_cli(c("--part", "pilot", "--backend", "mock", "--store", store)), "provenance")
  expect_identical(acmg_hash(store), before)
  expect_identical(calls, 0L)
})

test_that("external paths reject descendants and symlinks while permitting sibling stores", {
  root <- tempfile("synthetic-root-"); dir.create(root)
  expect_error(acmg_external_path(file.path(root, "runs", "ap1.sqlite"), root), "outside")
  expect_error(acmg_external_path(file.path(root, "missing", "..", "inside.sqlite"), root), "outside")
  sibling <- paste0(root, "-runs")
  # Paths are compared normalized (ADR-012): the existing parent is normalized
  # independently of acmg_resolve_path() and the rest is appended.
  parent <- normalizePath(dirname(sibling), winslash = "/", mustWork = TRUE)
  expect_identical(acmg_external_path(file.path(sibling, "ap1.sqlite"), root),
                   file.path(parent, basename(sibling), "ap1.sqlite"))
  # Windows links the directory with a junction: unlink() removes junctions, but
  # warns on directory symlinks, and symlinks may need a privilege (ADR-012).
  link <- tempfile("synthetic-link-")
  linked <- if (.Platform$OS.type == "windows") Sys.junction(root, link) else file.symlink(root, link)
  if (isTRUE(linked)) {
    expect_error(acmg_external_path(file.path(link, "runs", "ap1.sqlite"), root), "outside")
    unlink(link)
  }
})

test_that("repeat-day triggers count backend errors and strictly exceed the threshold", {
  p <- ap1_test_plan(); r <- ap1_test_pilot(p)
  r <- r[r$model_id == "sol", ][rep(seq_len(p$pilot$calls_per_model), length.out = 100), ]
  r$error <- NA_character_; r$value <- NA_character_
  r$error[1:5] <- "HTTP 500"
  get <- function(x) acmg_repeat_day(x, p)[1, ]
  expect_false(get(r)$error_trigger)
  r$error[6] <- "HTTP 500"
  expect_true(get(r)$error_trigger)
  m <- jsonlite::fromJSON(r$meta[10], simplifyVector = FALSE); m$model_snapshot <- "synthetic-change"
  r$meta[10] <- meta_to_json(m)
  expect_true(get(r)$model_change)
  r <- ap1_test_pilot(p); r <- r[r$model_id == "llama", ]
  m <- jsonlite::fromJSON(r$meta[1], simplifyVector = FALSE); m$provider <- "synthetic-change"
  r$meta[1] <- meta_to_json(m)
  diagnostics <- acmg_repeat_day(r, p)
  expect_true(diagnostics$provider_change[diagnostics$model == "llama"])
})
