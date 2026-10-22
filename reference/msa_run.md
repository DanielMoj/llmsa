# Execute a design against a backend and keep an audit trail

Runs every planned call of a design (or of one block of it), parses the
responses and records a full audit trail: timestamp, model identifier,
hash of the exact prompt, raw response, parsed value, latency and any
error. Rows are appended to `store` as they arrive, so that an
interrupted study can be resumed with `resume = TRUE` and no response is
ever lost.

## Usage

``` r
msa_run(
  design,
  backend,
  parse = parse_identity,
  block = NULL,
  store = NULL,
  resume = FALSE,
  delay = 0,
  verbose = TRUE
)
```

## Arguments

- design:

  An `msa_design` (see
  [`msa_design()`](https://danielmoj.github.io/llmsa/reference/msa_design.md)).

- backend:

  A backend function, see
  [backends](https://danielmoj.github.io/llmsa/reference/backends.md).

- parse:

  A parser function, see
  [parsers](https://danielmoj.github.io/llmsa/reference/parsers.md).
  Default keeps the raw text.

- block:

  Optional block number(s) to run now; default runs all blocks.

- store:

  Optional path. Ending in `.sqlite` or `.db` writes to an SQLite table
  `runs` (requires packages DBI and RSQLite); otherwise a CSV file is
  appended to.

- resume:

  If `TRUE` and `store` exists, calls already present in the store (same
  block, item, prompt, model and rep) are skipped.

- delay:

  Seconds to wait between calls (rate limits).

- verbose:

  Print progress.

## Value

A data.frame of class `msa_runs` with one row per call. Columns of
`items` other than `text` (for example `reference`) are carried along.

## Examples

``` r
truth <- c(v1 = 1.2, v2 = -0.4, v3 = 0.1)
lv <- c("Benign", "VUS", "Pathogenic")
d <- msa_design(c(v1 = "variant 1", v2 = "variant 2", v3 = "variant 3"),
                prompts = c(a = "Classify {text}.", b = "Tier for {text}?"),
                models = c("m1", "m2"), reps = 2, seed = 1)
bk <- backend_mock(truth, levels = lv, thresholds = c(-0.5, 0.5), seed = 2)
r <- msa_run(d, bk, parse = parse_choice(lv), verbose = FALSE)
head(r[, c("item_id", "prompt_id", "model_id", "rep", "value")])
#> LLM runs: 6 calls, 2 items, 2 prompt variants, 2 models, 0 block(s)
#>   missing values: 0
#>  item_id prompt_id model_id rep      value
#>       v1         a       m2   2 Pathogenic
#>       v1         b       m2   1 Pathogenic
#>       v1         a       m1   1 Pathogenic
#>       v1         a       m1   2 Pathogenic
#>       v2         a       m2   1        VUS
#>       v2         b       m1   2        VUS
```
