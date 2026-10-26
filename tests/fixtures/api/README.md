# API recordings

Unchanged JSON response bodies of the chat-completions API, one per model of
the AP1 plan, for the backend tests of K-M2-4 and K-M3d-3 (`ANK-94`). The
operator recorded them on 2026-10-26 with `record.R` in this folder: one call
per model with the production settings (docs/03 A.4), sent directly with
httr2 in the same form as `backend_openai_compatible()` (URL, headers, body
layout), without `req_retry()`. The message is a test question, not an AP1
item. Only response bodies are stored, no headers (OpenAI sends organisation
and project ids there), and no file contains an API key.

| File | Request | `model` in the request body |
| --- | --- | --- |
| `sol.json` | `POST https://api.openai.com/v1/chat/completions` | `gpt-6.1-sol` |
| `llama.json` | `POST https://openrouter.ai/api/v1/chat/completions` | `meta-llama/llama-3.3-70b-instruct` |
| `qwen.json` | `POST https://openrouter.ai/api/v1/chat/completions` | `qwen/qwen3-32b` |

Both OpenRouter responses carry a field `provider`, so no response of
`GET /api/v1/generation` was recorded. The OpenRouter bodies begin with
whitespace that OpenRouter sends while the request runs; it belongs to the
unchanged body.

## Replaying

Tests replay the files with `httr2::local_mocked_responses()`. The mock
function matches on the URL and the field `model` of the JSON body, so field
order and the other body fields do not change the match. When no recording
matches, it stops with an error instead of returning `NULL`, because httr2
would otherwise send the request. The constructed error case is a mock
response with HTTP 4xx. Example (httr2 1.3.0), with `fixture_dir` the path of
this folder as seen from the test:

```r
recordings <- c(
  "https://api.openai.com/v1/chat/completions gpt-6.1-sol" = "sol.json",
  "https://openrouter.ai/api/v1/chat/completions meta-llama/llama-3.3-70b-instruct" = "llama.json",
  "https://openrouter.ai/api/v1/chat/completions qwen/qwen3-32b" = "qwen.json"
)
mock <- function(req) {
  key <- paste(httr2::req_get_url(req), httr2::req_get_body(req)[["model"]])
  file <- recordings[key]
  if (is.na(file)) stop("no recording for ", key, call. = FALSE)
  path <- file.path(fixture_dir, file)
  httr2::response(status_code = 200, url = httr2::req_get_url(req), method = "POST",
                  headers = list("Content-Type" = "application/json"),
                  body = readBin(path, "raw", file.size(path)))
}
httr2::local_mocked_responses(mock)
```

## Recording again

From the repository root, one model per run:
`Rscript tests/fixtures/api/record.R sol` (likewise `llama` and `qwen`). The
script reads the keys with `readRenviron("~/.config/llmsa/openai.env")` and
`readRenviron("~/.config/llmsa/openrouter.env")`, sends the request once,
writes the body and prints the section for this file. Before committing,
check that no file in this folder contains a key or a 12-character piece of
one.

## Recordings of 2026-10-26

### `sol.json`

- Time (UTC): 2026-10-26T20:36:46Z
- Request: `POST https://api.openai.com/v1/chat/completions`
- Request body (the key travels only in the `Authorization` header):

  ```json
  {"model":"gpt-6.1-sol","messages":[{"role":"system","content":"You are a clinical variant scientist. Answer with exactly one of: Pathogenic, Likely pathogenic, Uncertain significance, Likely benign, Benign."},{"role":"user","content":"Which ACMG/AMP class applies to a variant with insufficient or conflicting evidence?"}],"reasoning_effort":"medium","seed":20261024}
  ```

- HTTP status: 200
- Model (response field `model`): `gpt-6.1-sol`
- `id`: `chatcmpl-EdLiy0e2r6NenmHTwGPPPq8v5LnCr`
- Provider: OpenAI (direct API; response field `provider`: absent)
- `system_fingerprint`: null
- `usage`: `{"prompt_tokens":57,"completion_tokens":6,"total_tokens":63,"prompt_tokens_details":{"cached_tokens":0,"cache_write_tokens":0,"audio_tokens":0},"completion_tokens_details":{"reasoning_tokens":0,"audio_tokens":0,"accepted_prediction_tokens":0,"rejected_prediction_tokens":0}}`

### `llama.json`

- Time (UTC): 2026-10-26T20:36:57Z
- Request: `POST https://openrouter.ai/api/v1/chat/completions`
- Request body (the key travels only in the `Authorization` header):

  ```json
  {"model":"meta-llama/llama-3.3-70b-instruct","messages":[{"role":"system","content":"You are a clinical variant scientist. Answer with exactly one of: Pathogenic, Likely pathogenic, Uncertain significance, Likely benign, Benign."},{"role":"user","content":"Which ACMG/AMP class applies to a variant with insufficient or conflicting evidence?"}],"temperature":0,"seed":20261024,"provider":{"order":["coreweave/fp16"],"allow_fallbacks":false,"quantizations":["fp16"]}}
  ```

- HTTP status: 200
- Model (response field `model`): `meta-llama/llama-3.3-70b-instruct`
- `id`: `gen-1793047017-4f5udMslyqHDKY4Dh5oI`
- Provider: `CoreWeave` (response field `provider`)
- `system_fingerprint`: null
- `usage`: `{"prompt_tokens":61,"completion_tokens":4,"total_tokens":65,"cost":4.615e-05,"is_byok":false,"prompt_tokens_details":{"cached_tokens":0,"cache_write_tokens":0,"audio_tokens":0,"video_tokens":0},"cost_details":{"upstream_inference_cost":4.615e-05,"upstream_inference_prompt_cost":4.331e-05,"upstream_inference_completions_cost":2.84e-06},"completion_tokens_details":{"reasoning_tokens":0,"image_tokens":0,"audio_tokens":0}}`

### `qwen.json`

- Time (UTC): 2026-10-26T20:37:10Z
- Request: `POST https://openrouter.ai/api/v1/chat/completions`
- Request body (the key travels only in the `Authorization` header):

  ```json
  {"model":"qwen/qwen3-32b","messages":[{"role":"system","content":"You are a clinical variant scientist. Answer with exactly one of: Pathogenic, Likely pathogenic, Uncertain significance, Likely benign, Benign."},{"role":"user","content":"Which ACMG/AMP class applies to a variant with insufficient or conflicting evidence?"}],"temperature":0,"seed":20261024,"provider":{"order":["deepinfra/fp8"],"allow_fallbacks":false,"quantizations":["fp8"]},"reasoning":{"enabled":false}}
  ```

- HTTP status: 200
- Model (response field `model`): `qwen/qwen3-32b`
- `id`: `gen-1793047030-WmkckdbKXsQmpJkpLtbG`
- Provider: `DeepInfra` (response field `provider`)
- `system_fingerprint`: null
- `usage`: `{"prompt_tokens":60,"completion_tokens":246,"total_tokens":306,"cost":7.368e-05,"is_byok":false,"prompt_tokens_details":{"cached_tokens":0,"cache_write_tokens":0,"audio_tokens":0,"video_tokens":0},"cost_details":{"upstream_inference_cost":7.368e-05,"upstream_inference_prompt_cost":4.8e-06,"upstream_inference_completions_cost":6.888e-05},"completion_tokens_details":{"reasoning_tokens":308,"image_tokens":0,"audio_tokens":0}}`
- Note: although the request sets `reasoning.enabled` to false, the response
  carries reasoning text in `message.reasoning` and `message.reasoning_details`
  and reports 308 reasoning tokens; `message.content` is the bare class.

The `usage` lines are printed by `record.R` after parsing, so numbers such as
`cost` appear in exponent notation; the JSON files keep the original text.
