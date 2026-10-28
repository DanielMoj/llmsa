# ADR-014 E3: the fifth pilot pass rule backend_errors mirrors the repeat-day
# trigger: per model, the share of stored pilot rows with a recorded error is at
# most error_share_trigger; unreadable answers do not count. A pilot that would
# trigger a repeat day in the main plan does not pass. E4: the pilot summary
# reports the maximum latency per model.

ap1_test_backend_failure <- function(r, rows) {
  # Failed calls are stored without a value or response metadata.
  r$error[rows] <- "Synthetic timeout: operation timed out"
  r$value[rows] <- NA_character_
  r$meta[rows] <- NA_character_
  r
}

ap1_test_errors_rule <- function(result, key) {
  result$rules[result$rules$model == key & result$rules$rule == "backend_errors", , drop = FALSE]
}

test_that("one backend error in 30 passes, two fail, and unreadable answers do not count", {
  p <- ap1_test_plan(); r <- ap1_test_pilot(p)
  trigger <- format(p$pilot$error_share_trigger)
  qwen <- which(r$model_id == "qwen")
  expect_length(qwen, 30L)
  base <- acmg_pilot(r, p)
  expect_identical(base$rules$rule[base$rules$model == "qwen"], c("4xx", "provider", "parser", "cost", "backend_errors"))
  for (key in names(acmg_models(p))) {
    rule <- ap1_test_errors_rule(base, key)
    expect_true(rule$passed, info = key)
    expect_identical(rule$reason, sprintf("0 of 30 backend errors (share 0 <= %s)", trigger), info = key)
  }
  one <- acmg_pilot(ap1_test_backend_failure(r, qwen[1]), p)
  expect_true(ap1_test_errors_rule(one, "qwen")$passed)
  expect_identical(ap1_test_errors_rule(one, "qwen")$reason, sprintf("1 of 30 backend errors (share %s <= %s)", format(1 / 30), trigger))
  expect_true(one$passed)
  two <- acmg_pilot(ap1_test_backend_failure(r, qwen[1:2]), p)
  expect_false(ap1_test_errors_rule(two, "qwen")$passed)
  expect_identical(ap1_test_errors_rule(two, "qwen")$reason, sprintf("2 of 30 backend errors (share %s > %s)", format(2 / 30), trigger))
  # Only backend_errors fails: two failed calls leave 28 recognized classes and the costs of the successful calls.
  failed <- two$rules[!two$rules$passed, ]
  expect_identical(paste(failed$model, failed$rule), "qwen backend_errors")
  expect_false(two$passed)
  three <- acmg_pilot(ap1_test_backend_failure(r, qwen[1:3]), p)
  expect_identical(ap1_test_errors_rule(three, "qwen")$reason, sprintf("3 of 30 backend errors (share 0.1 > %s)", trigger))
  output <- capture.output(acmg_print_pilot(three))
  expect_true(sprintf("qwen backend_errors failed: 3 of 30 backend errors (share 0.1 > %s)", trigger) %in% output)
  expect_true(sprintf("sol backend_errors passed: 0 of 30 backend errors (share 0 <= %s)", trigger) %in% output)
  expect_length(grep("^(sol|llama|qwen) backend_errors (passed|failed): ", output), length(p$models))
  # Unreadable answers are parser failures, not backend errors.
  unreadable <- r; unreadable$value[qwen[1:3]] <- NA_character_
  u <- acmg_pilot(unreadable, p)
  expect_true(ap1_test_errors_rule(u, "qwen")$passed)
  expect_identical(ap1_test_errors_rule(u, "qwen")$reason, sprintf("0 of 30 backend errors (share 0 <= %s)", trigger))
  expect_true(u$passed)
  # HTTP 4xx errors are backend errors as well.
  http <- ap1_test_backend_failure(r, qwen[1:2]); http$error[qwen[1:2]] <- "HTTP 400 Bad Request"
  h <- acmg_pilot(http, p)
  expect_identical(h$rules$passed[h$rules$model == "qwen" & h$rules$rule %in% c("4xx", "backend_errors")], c(FALSE, FALSE))
})

test_that("the backend error limit is inclusive and follows error_share_trigger and the stored rows", {
  p <- ap1_test_plan(); r <- ap1_test_pilot(p)
  qwen <- which(r$model_id == "qwen")
  failed <- ap1_test_backend_failure(r, qwen[1:2])
  p$pilot$error_share_trigger <- 2 / 30
  expect_true(ap1_test_errors_rule(acmg_pilot(failed, p), "qwen")$passed)
  p$pilot$error_share_trigger <- 2 / 30 - 1e-9
  expect_false(ap1_test_errors_rule(acmg_pilot(failed, p), "qwen")$passed)
  p <- ap1_test_plan()
  # The share is taken over the stored rows, as in acmg_repeat_day().
  partial <- acmg_pilot(ap1_test_backend_failure(r, qwen[1])[-qwen[2:11], ], p)
  expect_identical(ap1_test_errors_rule(partial, "qwen")$reason,
                   sprintf("1 of 20 backend errors (share 0.05 <= %s)", format(p$pilot$error_share_trigger)))
  expect_false(partial$passed)
  absent <- acmg_pilot(r[r$model_id != "qwen", ], p)
  expect_identical(ap1_test_errors_rule(absent, "qwen")$reason, "no stored pilot calls")
  expect_false(ap1_test_errors_rule(absent, "qwen")$passed)
  expect_true(all(absent$rules$passed[absent$rules$rule == "backend_errors" & absent$rules$model != "qwen"]))
})

test_that("the main plan and the robustness runs do not start when only backend_errors fails", {
  for (pkg in c("httr2", "DBI", "RSQLite")) skip_if_not_installed(pkg)
  p <- ap1_test_plan(); ap1_test_keys()
  on.exit(Sys.unsetenv(c("OPENAI_API_KEY", "OPENROUTER_API_KEY")), add = TRUE)
  r <- ap1_test_pilot(p)
  r <- ap1_test_backend_failure(r, which(r$model_id == "qwen")[1:2])
  failed <- acmg_pilot(r, p)$rules
  expect_identical(paste(failed$model, failed$rule)[!failed$passed], "qwen backend_errors")
  store <- tempfile(fileext = ".sqlite")
  on.exit(unlink(store), add = TRUE)
  acmg_store_init(store, "api")
  stored <- empty_runs()[rep(NA_integer_, nrow(r)), ]
  for (field in intersect(names(stored), names(r))) stored[[field]] <- r[[field]]
  append_store(store, stored)
  items <- acmg_items(); insaid <- items[items$source == "insaid", ]
  synthetic <- data.frame(gene = insaid$gene, cdna = sub("^[^:]+:", "", insaid$hgvs),
                          protein = "p.SyntheticProtected", classification = "Benign", status = "Validated")
  path <- tempfile(fileext = ".tsv")
  on.exit(unlink(path), add = TRUE)
  utils::write.table(synthetic, path, sep = "\t", quote = FALSE, row.names = FALSE)
  expected_hash <- acmg_hash(path)
  local_mocked_bindings(acmg_insaid_hash = function() expected_hash)
  calls <- 0L
  httr2::local_mocked_responses(function(req) { calls <<- calls + 1L; stop("Unexpected network request") })
  before <- acmg_hash(store)
  locked <- "^AP1 pilot has not passed: qwen backend_errors; no API calls made\\.$"
  expect_error(acmg_run_cli(c("--part", "main", "--backend", "api", "--store", store)), locked)
  expect_error(acmg_run_cli(c("--part", "main", "--block", "1", "--backend", "api", "--store", store)), locked)
  expect_error(acmg_run_cli(c("--part", "robustness", "--backend", "api", "--store", store, "--insaid-path", path)), locked)
  expect_identical(calls, 0L)
  expect_identical(acmg_hash(store), before)
})

test_that("the pilot summary reports the maximum latency per model, failed calls included", {
  p <- ap1_test_plan(); r <- ap1_test_pilot(p)
  for (key in names(acmg_models(p))) {
    at <- which(r$model_id == key)
    r$latency_s[at] <- seq_along(at) / 4 + match(key, names(acmg_models(p)))
  }
  qwen <- which(r$model_id == "qwen")
  r <- ap1_test_backend_failure(r, qwen[5])
  r$latency_s[qwen[5]] <- 1800.25
  s <- acmg_pilot(r, p)$summary
  expect_identical(match("latency_max", names(s)), match("latency_median", names(s)) + 1L)
  for (key in names(acmg_models(p))) {
    expect_identical(s$latency_max[s$model == key], max(r$latency_s[r$model_id == key]), info = key)
  }
  expect_identical(s$latency_max[s$model == "qwen"], 1800.25)
  r$latency_s[r$model_id == "sol"][2] <- NA_real_
  s <- acmg_pilot(r, p)$summary
  expect_identical(s$latency_max[s$model == "sol"], max(r$latency_s[r$model_id == "sol"], na.rm = TRUE))
  r$latency_s[r$model_id == "sol"] <- NA_real_
  expect_true(is.na(acmg_pilot(r, p)$summary$latency_max[1]))
  expect_true(is.na(acmg_pilot(r[r$model_id != "llama", ], p)$summary$latency_max[2]))
})

test_that("the report lists the backend error rule from plan.yaml, its result and the maximum latency", {
  p <- ap1_test_plan()
  captured <- list()
  local_mocked_bindings(msa_fit = ap1_test_fit_stub, msa_report = function(grr, ..., output_file = "", assessment = NULL) {
    captured[[basename(output_file)]] <<- assessment
    output_file
  })
  main <- ap1_test_runs(p)
  main$meta <- vapply(main$model_id, ap1_test_meta, "", plan = p)
  main$latency_s <- 0.5
  pilot <- ap1_test_pilot(p)
  pilot <- ap1_test_backend_failure(pilot, which(pilot$model_id == "qwen")[1:2])
  pilot$latency_s[pilot$model_id == "qwen"][1L] <- 1800.25
  pilot <- acmg_join_items(as.data.frame(pilot), acmg_items(pilot = TRUE))
  columns <- intersect(names(main), names(pilot))
  runs <- as_msa_runs(rbind(as.data.frame(main)[, columns], as.data.frame(pilot)[, columns]))
  p$reporting$output_dir <- tempfile("ap1-backend-errors-")
  on.exit(unlink(p$reporting$output_dir, recursive = TRUE), add = TRUE)
  acmg_evaluate(runs, p)
  expect_true(nzchar(p$pilot$pass_rules$backend_errors))
  for (key in names(acmg_models(p))) {
    sections <- captured[[paste0("ap1-", key, ".html")]]$sections
    expect_true(p$pilot$pass_rules$backend_errors %in% sections[["Pilot rules"]]$text, info = key)
    expect_identical(sections[["Pilot rules"]]$text[seq_along(p$pilot$pass_rules)], unname(unlist(p$pilot$pass_rules)), info = key)
    result <- sections[["Pilot result"]]$table
    expect_identical(result$passed[result$rule == "backend_errors"], key != "qwen", info = key)
    measurements <- sections[["Pilot measurements"]]$table
    expect_identical(measurements$latency_max, if (key == "qwen") 1800.25 else 0.25, info = key)
  }
})
