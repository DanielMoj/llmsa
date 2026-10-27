# Backends: how a prompt becomes a response

A backend is a function `function(prompt, model, row)` that sends
`prompt` to `model` and returns the raw text response (a length-one
character vector). `row` is the corresponding row of the design and can
be ignored. A backend may instead return a list with elements `text` and
`meta`; `meta` (a named list, e.g. token counts or the model snapshot id
reported by the API) is stored with the run. Any client library can be
wrapped this way; three backends are provided.

## Usage

``` r
backend_mock(
  truth,
  levels = NULL,
  thresholds = NULL,
  sd_prompt = 0.2,
  sd_model = 0.2,
  sd_rep = 0.3,
  p_fail = 0,
  template = "The result is: %s.",
  seed = NULL
)

backend_ellmer(chats)

backend_openai_compatible(
  base_url = "https://api.openai.com/v1",
  api_key = Sys.getenv("OPENAI_API_KEY"),
  temperature = 0,
  system = NULL,
  max_tokens = NULL,
  timeout = 120,
  ...
)
```

## Arguments

- truth:

  A named vector giving the latent true value of every `item_id`
  (numeric). For ordinal mocks this is the latent position; the label is
  obtained by cutting at `thresholds`.

- levels:

  Optional ordered labels. If given, the mock returns a label; otherwise
  it returns a number.

- thresholds:

  Cut points on the latent scale (length `length(levels) - 1`).

- sd_prompt, sd_model, sd_rep:

  Standard deviations of the prompt effect, the model effect and the
  replicate noise on the latent scale. Prompt and model effects are
  drawn once per prompt id / model id and kept fixed.

- p_fail:

  Probability that the mock returns an unparseable response, to exercise
  failure handling.

- template:

  A sprintf-style sentence with one `%s` for the value.

- seed:

  Seed for the mock's private random number stream.

- chats:

  For `backend_ellmer()`: an `ellmer` Chat object, or a named list of
  Chat objects keyed by model id.

- base_url, api_key, temperature, system, max_tokens, timeout, ...:

  For `backend_openai_compatible()`: server URL (without the trailing
  `/chat/completions`), API key (may be empty for local servers),
  sampling temperature, optional system message, token limit, request
  timeout in seconds, and further fields merged into the JSON body.
  `temperature = NULL` omits the temperature field. A non-empty, non-NA
  `row$system` overrides `system` and precedes the user message. The
  reply's `id`, `model` (as `model_snapshot`), `usage`,
  `system_fingerprint` (including null) and optional `provider` are
  recorded in `meta`. Requested routing is recorded as `provider_order`,
  `quantizations` and `allow_fallbacks`. Requested `seed`, `temperature`
  and `reasoning_effort`, when present, are retained as metadata for
  comparison with the study plan. Only `message.content` is parsed;
  credentials and headers are not stored.

## Value

A backend function.

## Details

- `backend_mock()` simulates an LLM for examples, tests and teaching.
  The default simulation draws a latent score from the item's `truth`
  plus prompt, model and replicate noise and writes a short sentence
  that contains the resulting label or number, so that the whole chain
  from prompt to parser can be exercised offline.

- `backend_ellmer()` wraps one or several `ellmer` chat objects (one per
  model id). Each call uses a fresh clone, so no conversation history
  leaks between calls.

- `backend_openai_compatible()` talks to any server that implements the
  OpenAI chat-completions API: OpenAI itself, Ollama
  (`base_url = "http://localhost:11434/v1"`), vLLM, LM Studio,
  Azure-style proxies.

## Examples

``` r
truth <- c(v1 = 1.2, v2 = -0.4)
bk <- backend_mock(truth, levels = c("Benign", "VUS", "Pathogenic"),
                   thresholds = c(-0.5, 0.5), seed = 1)
bk("Classify v1", "model-a", list(item_id = "v1", prompt_id = "P1", model_id = "model-a"))
#> $text
#> [1] "The result is: VUS."
#> 
#> $meta
#> $meta$mock
#> [1] TRUE
#> 
#> $meta$latent
#> [1] 0.3877586
#> 
#> 
```
