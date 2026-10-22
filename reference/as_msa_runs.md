# Import results produced elsewhere

Turns a data.frame of results from any pipeline into an `msa_runs`
object, so that the analysis functions can be used without running the
backend through this package. The minimum is one row per call with the
item, prompt variant, model, replicate number and parsed value.

## Usage

``` r
as_msa_runs(
  x,
  item = "item_id",
  prompt = "prompt_id",
  model = "model_id",
  rep = "rep",
  value = "value",
  block = "block",
  design = NULL
)
```

## Arguments

- x:

  A data.frame.

- item, prompt, model, rep, value, block:

  Column names in `x`.

- design:

  Optional `msa_design` the results belong to.

## Value

An `msa_runs` data.frame.

## Examples

``` r
df <- expand.grid(item_id = paste0("I", 1:5), prompt_id = c("P1", "P2"),
                  model_id = c("m1", "m2"), rep = 1:2, stringsAsFactors = FALSE)
df$value <- rnorm(nrow(df))
r <- as_msa_runs(df)
class(r)
#> [1] "msa_runs"   "data.frame"
```
