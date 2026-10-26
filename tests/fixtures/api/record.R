# Records one chat-completions response per model of the AP1 plan as an
# unchanged JSON body (operator script; see README.md in this folder).
#
# Usage, from the repository root, one model per run:
#   Rscript tests/fixtures/api/record.R sol
#   Rscript tests/fixtures/api/record.R llama
#   Rscript tests/fixtures/api/record.R qwen
#
# The request mirrors backend_openai_compatible(): same URL, headers and body
# layout (model, messages, then the extra fields). It is sent exactly once,
# without req_retry(); a failed call is reported and not repeated. Only the
# response body is written, never response headers (OpenAI sends
# organisation and project ids there). If an OpenRouter response has no field
# `provider`, the script waits a few seconds and records GET /generation for
# its id as well. API keys are read with readRenviron() and never printed or
# written. The output is the README.md section for the recording.

key <- commandArgs(trailingOnly = TRUE)
if (length(key) != 1L || !key %in% c("sol", "llama", "qwen")) {
  stop("usage: Rscript tests/fixtures/api/record.R sol|llama|qwen", call. = FALSE)
}
out_dir <- file.path("tests", "fixtures", "api")
if (!dir.exists(out_dir)) stop("run this script from the repository root", call. = FALSE)

seed <- 20261024
system_prompt <- "You are a clinical variant scientist. Answer with exactly one of: Pathogenic, Likely pathogenic, Uncertain significance, Likely benign, Benign."
user_prompt <- "Which ACMG/AMP class applies to a variant with insufficient or conflicting evidence?"

openai <- list(base_url = "https://api.openai.com/v1",
               env_file = "~/.config/llmsa/openai.env", env_var = "OPENAI_API_KEY")
openrouter <- list(base_url = "https://openrouter.ai/api/v1",
                   env_file = "~/.config/llmsa/openrouter.env", env_var = "OPENROUTER_API_KEY")

# Production settings (docs/03 A.4; ANK-53 to ANK-55, ANK-61). Sol sends no
# temperature and no max_tokens; arrays are lists so that they stay JSON arrays.
plans <- list(
  sol = c(openai, list(
    model = "gpt-6.1-sol",
    extra = list(reasoning_effort = "medium", seed = seed))),
  llama = c(openrouter, list(
    model = "meta-llama/llama-3.3-70b-instruct",
    extra = list(temperature = 0, seed = seed,
                 provider = list(order = list("coreweave/fp16"), allow_fallbacks = FALSE,
                                 quantizations = list("fp16"))))),
  qwen = c(openrouter, list(
    model = "qwen/qwen3-32b",
    extra = list(temperature = 0, seed = seed,
                 provider = list(order = list("deepinfra/fp8"), allow_fallbacks = FALSE,
                                 quantizations = list("fp8")),
                 reasoning = list(enabled = FALSE))))
)
p <- plans[[key]]

readRenviron(p$env_file)
api_key <- Sys.getenv(p$env_var)
if (!nzchar(api_key)) stop(p$env_var, " is empty after readRenviron()", call. = FALSE)

# Removes the key, and anything shaped like a key, before text is printed.
redact <- function(x) {
  x <- gsub(api_key, "<key>", x, fixed = TRUE)
  gsub("sk-[[:alnum:]_*-]+", "<key>", x)
}

# Sends `req` once. Returns the response, or NULL after reporting the failure.
perform_once <- function(req, what) {
  req <- httr2::req_error(req, is_error = function(resp) FALSE)
  resp <- tryCatch(httr2::req_perform(req), error = function(e) e)
  if (inherits(resp, "error")) {
    cat(sprintf("FAILED %s: %s\n", what, redact(conditionMessage(resp))))
    return(NULL)
  }
  status <- httr2::resp_status(resp)
  if (status >= 400) {
    text <- tryCatch(httr2::resp_body_string(resp), error = function(e) "")
    cat(sprintf("FAILED %s: HTTP %d\n%s\n", what, status, redact(substr(text, 1, 2000))))
    return(NULL)
  }
  resp
}

# Formats a response field, telling an absent field from a JSON null.
show_field <- function(x, name) {
  if (!name %in% names(x)) "absent" else if (is.null(x[[name]])) "null" else
    paste0("`", x[[name]], "`")
}

messages <- list(list(role = "system", content = system_prompt),
                 list(role = "user", content = user_prompt))
body <- c(list(model = p$model, messages = messages), p$extra)
url <- paste0(p$base_url, "/chat/completions")
req <- httr2::request(url)
req <- httr2::req_headers(req, "Content-Type" = "application/json")
req <- httr2::req_headers(req, Authorization = paste("Bearer", api_key))
req <- httr2::req_body_json(req, body)
req <- httr2::req_timeout(req, 120)
# Same serialisation as the req_body_json() defaults, for the record.
body_json <- jsonlite::toJSON(body, auto_unbox = TRUE, digits = 22, null = "null")

sent_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
resp <- perform_once(req, paste("POST", url))
if (is.null(resp)) quit(save = "no", status = 1)
raw <- httr2::resp_body_raw(resp)
js <- jsonlite::parse_json(rawToChar(raw))
# `[[` matches field names exactly; `$` would also accept a partial match.
if (!is.null(js[["error"]]) || length(js[["choices"]]) == 0L) {
  cat(sprintf("FAILED POST %s: HTTP %d without choices\n%s\n", url, httr2::resp_status(resp),
              redact(substr(rawToChar(raw), 1, 2000))))
  quit(save = "no", status = 1)
}
file <- file.path(out_dir, paste0(key, ".json"))
writeBin(raw, file)

provider <- if (identical(p$base_url, openai$base_url)) {
  sprintf("OpenAI (direct API; response field `provider`: %s)", show_field(js, "provider"))
} else if (!is.null(js[["provider"]])) {
  sprintf("%s (response field `provider`)", show_field(js, "provider"))
} else {
  Sys.sleep(10)
  greq <- httr2::request(paste0(p$base_url, "/generation"))
  greq <- httr2::req_url_query(greq, id = js[["id"]])
  greq <- httr2::req_headers(greq, Authorization = paste("Bearer", api_key))
  greq <- httr2::req_timeout(greq, 120)
  gurl <- httr2::req_get_url(greq)
  gresp <- perform_once(greq, paste("GET", gurl))
  if (is.null(gresp)) {
    "not recorded (the response has no field `provider`; GET /generation failed)"
  } else {
    graw <- httr2::resp_body_raw(gresp)
    gfile <- file.path(out_dir, paste0(key, "-generation.json"))
    writeBin(graw, gfile)
    gdata <- jsonlite::parse_json(rawToChar(graw))[["data"]]
    sprintf("%s (field `provider_name` of `GET %s`, HTTP %d, recorded as `%s`; the response has no field `provider`)",
            show_field(gdata, "provider_name"), gurl, httr2::resp_status(gresp), basename(gfile))
  }
}

cat(sprintf("### `%s`\n\n", basename(file)))
cat(sprintf("- Time (UTC): %s\n", sent_at))
cat(sprintf("- Request: `POST %s`\n", url))
cat("- Request body (the key travels only in the `Authorization` header):\n\n")
cat(sprintf("  ```json\n  %s\n  ```\n\n", body_json))
cat(sprintf("- HTTP status: %d\n", httr2::resp_status(resp)))
cat(sprintf("- Model (response field `model`): %s\n", show_field(js, "model")))
cat(sprintf("- `id`: %s\n", show_field(js, "id")))
cat(sprintf("- Provider: %s\n", provider))
cat(sprintf("- `system_fingerprint`: %s\n", show_field(js, "system_fingerprint")))
cat(sprintf("- `usage`: `%s`\n", jsonlite::toJSON(js[["usage"]], auto_unbox = TRUE, digits = NA,
                                                  null = "null")))
