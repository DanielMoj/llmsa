test_that("the OpenAI-compatible backend builds the request and reads the reply", {
  skip_if_not_installed("httr2", "1.0.0")
  bk <- backend_openai_compatible("http://localhost:11434/v1", api_key = "", temperature = 0,
                                  system = "Be terse.")
  res <- httr2::with_mocked_responses(function(req) {
    body <- req$body$data
    expect_equal(body$model, "qwen3:8b")
    expect_equal(body$temperature, 0)
    expect_equal(body$messages[[1]], list(role = "system", content = "Be terse."))
    expect_equal(body$messages[[2]], list(role = "user", content = "Classify X"))
    expect_true(grepl("/chat/completions$", req$url))
    httr2::response_json(body = list(
      model = "qwen3:8b-2026", usage = list(total_tokens = 12),
      choices = list(list(message = list(role = "assistant", content = "Likely pathogenic")))))
  }, bk("Classify X", "qwen3:8b", list(item_id = "v1")))
  expect_equal(res$text, "Likely pathogenic")
  expect_equal(res$meta$model_snapshot, "qwen3:8b-2026")
})

test_that("the mock backend is reproducible and honours p_fail", {
  truth <- c(v1 = 2, v2 = -2)
  bk1 <- backend_mock(truth, seed = 5)
  bk2 <- backend_mock(truth, seed = 5)
  row <- list(item_id = "v1", prompt_id = "P1", model_id = "m")
  expect_equal(bk1("p", "m", row)$text, bk2("p", "m", row)$text)
  expect_error(bk1("p", "m", list(item_id = "nope")), "unknown item_id")
  bkf <- backend_mock(truth, p_fail = 1, seed = 1)
  expect_true(is.na(parse_number()(bkf("p", "m", row)$text)))
})

test_that("backend_ellmer needs ellmer", {
  skip_if(requireNamespace("ellmer", quietly = TRUE))
  expect_error(backend_ellmer(list()), "ellmer")
})
