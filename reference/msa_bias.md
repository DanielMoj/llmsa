# Bias and linearity of a numeric LLM pipeline against a reference

Compares parsed numeric values with reference values per item: mean bias
with a t-based confidence interval overall and per prompt-model
combination, and a linearity check (does the bias depend on the
magnitude of the reference?) by regressing the bias on the reference.

## Usage

``` r
msa_bias(runs, reference, level = 0.95)
```

## Arguments

- runs:

  An `msa_runs` object with numeric values.

- reference:

  A named numeric vector keyed by `item_id`, a data.frame with columns
  `item_id` and `reference`, or a column name in `runs`.

- level:

  Confidence level.

## Value

An object of class `msa_bias`: a list with `overall`, `by_condition` and
`linearity`.

## Examples

``` r
msa_bias(ic50_demo, reference = "reference")
#> Bias against reference (40 items, 2152 values)
#>   mean bias 0.0110  [95 % CI 0.0030, 0.0190]  sd 0.1885  p = 0.00682
#>  prompt_id model_id   n    bias     sd   lower   upper  p_value
#>     direct  model-a 239 -0.0061 0.1468 -0.0248  0.0126    0.519
#>   stepwise  model-a 240  0.0835 0.1530  0.0640  0.1029 2.87e-15
#>      table  model-a 240 -0.0502 0.1429 -0.0684 -0.0320 1.31e-07
#>     direct  model-b 239 -0.1267 0.1338 -0.1438 -0.1097 4.77e-35
#>   stepwise  model-b 239 -0.0505 0.1495 -0.0696 -0.0315 3.78e-07
#>      table  model-b 238 -0.1819 0.1404 -0.1998 -0.1639 9.61e-53
#>     direct  model-c 239  0.1432 0.1432  0.1250  0.1615  8.1e-38
#>   stepwise  model-c 239  0.2206 0.1411  0.2026  0.2386 5.02e-66
#>      table  model-c 239  0.0663 0.1453  0.0478  0.0848 1.87e-11
#>   linearity: bias = 0.0278 + -0.0092 * reference (slope p = 0.0268)
```
