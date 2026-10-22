# Plan a crossed precision study for an LLM pipeline

Builds the run plan of a crossed measurement-system study: every item is
processed under every prompt variant and every model, `reps` times per
block. Items play the role of *parts*, prompt variants and models play
the role of *appraisers* and *instruments*, replicates measure
repeatability, and blocks separate replicates in time (different hours
or days), which is necessary because inference endpoints are not
deterministic at temperature 0 and their behaviour drifts with load.

## Usage

``` r
msa_design(
  items,
  prompts,
  models,
  reps = 3,
  blocks = 1,
  order = c("random", "fixed"),
  seed = NULL
)
```

## Arguments

- items:

  A character vector of item texts (optionally named by item id) or a
  data.frame with columns `item_id` and `text`. Additional columns (for
  example `reference`) are carried along and can be used as placeholders
  in prompts.

- prompts:

  A character vector of prompt templates. Placeholders in braces are
  replaced by the item fields: `{text}` is always available, `{item_id}`
  and any other column of `items` can be used as well. Names become
  prompt ids (default `P1`, `P2`, ...).

- models:

  A character vector of model identifiers passed to the backend. Names
  become model ids (default: the identifiers themselves).

- reps:

  Number of replicates per item, prompt, model and block.

- blocks:

  Number of blocks (sessions). Run each block at a different time to
  capture temporal drift of the endpoint.

- order:

  `"random"` randomises the run order within each block (recommended),
  `"fixed"` keeps the crossing order.

- seed:

  Optional seed for the randomisation.

## Value

A data.frame of class `msa_design` with one row per planned call:
`block`, `position` (run order within block), `item_id`, `prompt_id`,
`model_id`, `rep`, `prompt` (the rendered prompt) and `model` (the
backend model identifier). The design parameters are stored as
attributes.

## Examples

``` r
items <- c(v1 = "NM_000059.4:c.1813dupA", v2 = "NM_000059.4:c.7397T>C")
prompts <- c(
  short = "Classify the variant {text} according to ACMG/AMP. Answer with one class.",
  long  = "You are a clinical geneticist. Classify {text} (ACMG/AMP, 5 tiers)."
)
d <- msa_design(items, prompts, models = c("model-a", "model-b"), reps = 2, seed = 1)
head(d)
#> Crossed precision study for an LLM pipeline
#>   items (parts):      2
#>   prompt variants:    2  [short, long]
#>   models:             2  [model-a, model-b]
#>   replicates/block:   2
#>   blocks (sessions):  1
#>   planned calls:      6
#> 
#> First rows (prompt text truncated):
#>  block position item_id prompt_id model_id rep
#>      1        1      v2     short  model-a   1
#>      1        2      v1     short  model-b   2
#>      1        3      v1      long  model-b   1
#>      1        4      v1     short  model-a   1
#>      1        5      v1     short  model-a   2
#>      1        6      v2      long  model-a   2
#>                                       prompt   model
#>  Classify the variant NM_000059.4:c.7397T... model-a
#>  Classify the variant NM_000059.4:c.1813d... model-b
#>  You are a clinical geneticist. Classify ... model-b
#>  Classify the variant NM_000059.4:c.1813d... model-a
#>  Classify the variant NM_000059.4:c.1813d... model-a
#>  You are a clinical geneticist. Classify ... model-a
summary(d)
#> Crossed precision study for an LLM pipeline
#>   items (parts):      2
#>   prompt variants:    2  [short, long]
#>   models:             2  [model-a, model-b]
#>   replicates/block:   2
#>   blocks (sessions):  1
#>   planned calls:      16
```
