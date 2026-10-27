# ADR-011 no. 2 (E28): reporting.policies lists DeepInfra, CoreWeave and
# OpenRouter separately (snapshots of 2026-10-27); the report shows each of them
# with snapshot date, quote and URL.

test_that("plan.yaml lists DeepInfra, CoreWeave and OpenRouter separately in the policy schema", {
  p <- ap1_test_plan()
  policies <- p$reporting$policies
  for (policy in policies) {
    expect_identical(names(policy), c("provider", "summary", "quote", "snapshot_date", "url", "location"))
    expect_true(all(vapply(policy, function(x) is.character(x) && length(x) == 1L && nzchar(x), logical(1))))
    expect_match(policy$url, "^https://")
  }
  providers <- vapply(policies, `[[`, "", "provider")
  expect_identical(sub(" .*", "", providers), c("DeepInfra", "CoreWeave", "OpenRouter", "OpenAI"))
  routed <- policies[1:3]
  expect_true(all(vapply(routed, `[[`, "", "snapshot_date") == "2026-10-27"))
  for (policy in routed[1:2]) {
    expect_match(policy$summary, "No retention period is claimed.", fixed = TRUE)
    expect_match(policy$summary, "ZDR was enforced in the OpenRouter account settings during AP1.$")
  }
  # Each routed model of the plan has exactly one provider entry naming model, endpoint and provider.
  for (key in c("llama", "qwen")) {
    m <- acmg_models(p)[[key]]
    hit <- vapply(routed[1:2], function(x) all(vapply(c(m$id, unlist(m$provider_order), m$provider_name), grepl,
                                                       logical(1), x = x$provider, fixed = TRUE)), logical(1))
    expect_identical(sum(hit), 1L, info = key)
    expect_true(grepl(m$id, routed[[3]]$provider, fixed = TRUE), info = key)
  }
})

test_that("the rendered report shows DeepInfra, CoreWeave and OpenRouter with snapshot date, quote and URL", {
  for (pkg in c("rmarkdown", "knitr")) skip_if_not_installed(pkg)
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")
  p <- ap1_test_plan()
  p$reporting$output_dir <- tempfile("ap1-policy-reports-")
  on.exit(unlink(p$reporting$output_dir, recursive = TRUE), add = TRUE)
  render <- msa_report
  captured <- list()
  # Render one report; every model's report carries the same policy sections.
  local_mocked_bindings(msa_fit = ap1_test_fit_stub, msa_report = function(grr, ..., output_file = "", assessment = NULL) {
    captured[[basename(output_file)]] <<- assessment
    if (basename(output_file) == "ap1-sol.html") render(grr, ..., output_file = output_file, assessment = assessment) else output_file
  })
  ev <- acmg_evaluate(ap1_test_runs(p), p)
  html <- gsub("[[:space:]]+", " ", paste(readLines(ev$models$sol$report, warn = FALSE), collapse = " "))
  for (policy in p$reporting$policies[1:3]) {
    for (key in names(captured)) {
      section <- captured[[key]]$sections[[paste("Data policy:", policy$provider)]]
      expect_false(is.null(section), info = paste(key, policy$provider))
      for (text in c(policy$snapshot_date, policy$quote, policy$url)) expect_match(section$text, text, fixed = TRUE)
    }
    for (text in c(policy$provider, policy$snapshot_date, policy$quote, policy$url)) {
      expect_true(grepl(gsub("[[:space:]]+", " ", text), html, fixed = TRUE), info = text)
    }
  }
})
