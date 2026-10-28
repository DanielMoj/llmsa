# ADR-014 E1: every AP1 model carries the required field timeout_s, and
# acmg_api_backends() passes it to backend_openai_compatible() as the client
# timeout; the request body stays unchanged. E2: meta$timeout_s records it.

test_that("a plan without a positive, finite, numeric timeout_s fails validation", {
  p <- ap1_test_plan()
  for (i in seq_along(p$models)) {
    key <- p$models[[i]]$key
    bad <- p; bad$models[[i]]$timeout_s <- NULL
    expect_error(acmg_validate_plan(bad), "Invalid AP1 plan field: models: required fields", fixed = TRUE, info = key)
    values <- list(null = NULL, zero = 0, negative = -1, negative_integer = -1800L, na = NA, na_real = NA_real_,
                   inf = Inf, minus_inf = -Inf, string = "1800", logical = TRUE, vector = c(1800, 1800), list = list(1800))
    for (name in names(values)) {
      bad <- p; bad$models[[i]]["timeout_s"] <- list(values[[name]])
      expect_true("timeout_s" %in% names(bad$models[[i]]), info = paste(key, name))
      expect_error(acmg_validate_plan(bad), "Invalid AP1 plan field: models.timeout_s", fixed = TRUE, info = paste(key, name))
    }
  }
  copy <- tempfile(fileext = ".yaml")
  on.exit(unlink(copy), add = TRUE)
  bad <- p; bad$models[[3]]$timeout_s <- NULL
  yaml::write_yaml(bad, copy)
  expect_error(acmg_plan(copy), "models: required fields", fixed = TRUE)
  good <- p; good$models[[1]]$timeout_s <- 0.5
  expect_identical(acmg_validate_plan(good), good)
})

test_that("acmg_api_backends() sends the plan timeout with every request and records it as meta$timeout_s", {
  skip_if_not_installed("httr2")
  p <- ap1_test_plan(); ap1_test_keys()
  on.exit(Sys.unsetenv(c("OPENAI_API_KEY", "OPENROUTER_API_KEY")), add = TRUE)
  expect_identical(vapply(p$models, function(m) as.numeric(m$timeout_s), 0), rep(1800, length(p$models)))
  # A different value shows that the request follows the plan, not a constant.
  other <- p
  for (i in seq_along(other$models)) other$models[[i]]$timeout_s <- 2.5 * i
  for (plan in list(p, other)) {
    backends <- acmg_api_backends(plan)
    for (key in names(backends)) {
      model <- acmg_models(plan)[[key]]
      seen <- list()
      httr2::local_mocked_responses(function(req) {
        seen[[length(seen) + 1L]] <<- list(timeout_ms = req$options$timeout_ms, body = ap1_test_request_body(req))
        ap1_test_response(list(id = "synthetic-id", model = model$id, choices = list(list(message = list(content = "Benign")))))
      })
      got <- backends[[key]]("Synthetic prompt", model$id, list(model_id = key))
      expect_length(seen, 1L)
      expect_equal(seen[[1]]$timeout_ms, model$timeout_s * 1000, info = key)
      expect_false(any(c("timeout", "timeout_s", "max_tokens") %in% names(seen[[1]]$body)), info = key)
      expect_equal(got$meta$timeout_s, model$timeout_s, info = key)
    }
  }
  # The default of backend_openai_compatible() is unchanged (ANK-02) and recorded as well.
  expect_identical(formals(backend_openai_compatible)$timeout, 120)
  seen <- NULL
  httr2::local_mocked_responses(function(req) {
    seen <<- req$options$timeout_ms
    ap1_test_response(list(id = "synthetic-id", model = "synthetic-model", choices = list(list(message = list(content = "Benign")))))
  })
  got <- backend_openai_compatible(api_key = "", temperature = NULL)("Synthetic prompt", "synthetic-model")
  expect_equal(seen, 120 * 1000)
  expect_equal(got$meta$timeout_s, 120)
})
