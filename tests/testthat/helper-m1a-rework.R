# Rework fixtures are synthetic. Every fit is made with the currently loaded
# namespace, including in mutation runs; no unmutated result is cached.
rework_capture <- function(expr) {
  warnings <- list()
  value <- tryCatch(withCallingHandlers(suppressMessages(expr), warning = function(w) {
    warnings[[length(warnings) + 1L]] <<- w
    invokeRestart("muffleWarning")
  }), error = identity)
  list(value = value, warnings = warnings)
}

rework_error <- function(expr, message) {
  result <- rework_capture(expr)
  expect_s3_class(result$value, "error")
  if (inherits(result$value, "error")) {
    # Own-output contract for diagnostic wording; there is no external oracle
    # for English messages. The failing input is asserted by each caller.
    expect_identical(conditionMessage(result$value), message)
    expect_null(conditionCall(result$value))
  }
  invisible(result)
}

rework_categorical_runs <- function() {
  r <- msa_simulate(8, 3, 2, 3, 2,
    vc = list(item = 1, prompt = 0.4, model = 0.2, block = 0.1, residual = 1), seed = 20261029L)
  r$value <- cut(r$value, breaks = c(-Inf, -1, 0, 1, Inf),
                 labels = c("A", "B", "C", "D"), ordered_result = TRUE)
  r
}

rework_display_fit <- function() {
  # Deliberately constructed reporting input, not an estimated study.
  structure(list(type = "numeric", link = "probit", formula = y ~ 1 + (1 | item),
    vc = data.frame(source = c("item", "Residual"), variance = c(4 / 3, 1 / 7)),
    n = list(items = 6L, prompts = 3L, models = 2L, blocks = 4L,
             observations = 37L, reps_per_cell = c(2L, 5L)),
    derived = character(), singular = FALSE), class = "msa_fit")
}
