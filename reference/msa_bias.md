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
  `item_id` and `reference`, or a column name in `runs`. Each item has
  at most one distinct readable reference; conflicting references are
  errors. A known value beside missing entries supplies that item's
  reference. Factor labels are read as numbers.

- level:

  Finite numeric confidence level strictly between zero and one.

## Value

An object of class `msa_bias`, with:

- overall:

  Named numeric vector `n`, `bias`, `sd`, `lower`, `upper`, `p_value`,
  `n_excluded`.

- by_condition:

  The same quantities per observed prompt-model combination. With no
  valid pair all estimates are `NA`.

- linearity:

  Handbook `intercept`, `slope`, `slope_p_value`, `r_squared`
  (proportion), `t_intercept`, `t_slope`, `df`, `t_quantile`.

- linearity_item_means:

  Unweighted item-mean `intercept`, `slope`, `r_squared`, `t_intercept`,
  `t_slope`, `df`.

- linearity_band:

  Data frame `reference`, `fit`, `lower`, `upper`, at each distinct
  reference value; empty when the band is undefined.

- linearity_in_band:

  Logical scalar: zero lies in the entire handbook band, or `NA` when
  undefined.

- linearity_verdict:

  `"acceptable"` when the entire band contains zero, `"unacceptable"`
  otherwise, or `NA_character_` when undefined.

- linearity_note:

  Methods, both degrees of freedom, dependence limitation and any reason
  for undefined linearity.

- level, n_items:

  Confidence level and count of items with valid pairs.

## Details

Missing, NaN and unparseable responses or references are excluded and
counted once per row in `n_excluded`. Infinite inputs and overflow of
the response minus reference are errors. All observed prompt-model
conditions remain in the output, even with no valid pairs. If there are
no valid pairs overall, the call fails with an explanatory error.

The bias interval and p-value use the one-sample t calculation with
`n - 1` degrees of freedom. One valid pair gives its bias but no
inference. Numerically constant deviations give a point interval and an
undefined p-value, with a message; the measured SD is retained.
Constancy means a zero standard error, or a standard error smaller than
ten times machine precision times the absolute mean.

The handbook regression uses all valid single deviations (`N - 2`
degrees of freedom, or `gm - 2` in a balanced design). The additional
regression uses unweighted item means (`g - 2` degrees of freedom).
Items with the same reference value remain distinct. Unequal replicate
counts thus give different weighting in the two regressions. Replicates
of the same item may be correlated, so the handbook calculation can
overstate the information. The object and report describe this
limitation.

The handbook confidence band for the mean bias determines the linearity
verdict. Zero must lie in the band throughout the closed observed
reference range, including between displayed reference values; touching
the boundary counts as inclusion. This is not a prediction interval. A
single reference value leaves linearity undefined without preventing
bias estimation. Without residual degrees of freedom, coefficients are
retained but inference and the band are undefined. Numerically constant
targets have undefined R-squared. A residual norm no larger than ten
times machine precision times the centered target norm is treated as
zero: t and p are undefined and the band collapses onto the fitted line.
These cases produce messages and `NA`, never `NaN`.

## Examples

``` r
msa_bias(ic50_demo, reference = "reference")
#> Bias against reference (40 items, 2152 values)
#>   Excluded response-reference pairs: 8
#>   mean bias 0.0110  [95 % CI 0.0030, 0.0190]  sd 0.1885  p = 0.00682
#>  prompt_id model_id   n    bias     sd   lower   upper  p_value n_excluded
#>     direct  model-a 239 -0.0061 0.1468 -0.0248  0.0126    0.519          1
#>   stepwise  model-a 240  0.0835 0.1530  0.0640  0.1029 2.87e-15          0
#>      table  model-a 240 -0.0502 0.1429 -0.0684 -0.0320 1.31e-07          0
#>     direct  model-b 239 -0.1267 0.1338 -0.1438 -0.1097 4.77e-35          1
#>   stepwise  model-b 239 -0.0505 0.1495 -0.0696 -0.0315 3.78e-07          1
#>      table  model-b 238 -0.1819 0.1404 -0.1998 -0.1639 9.61e-53          2
#>     direct  model-c 239  0.1432 0.1432  0.1250  0.1615  8.1e-38          1
#>   stepwise  model-c 239  0.2206 0.1411  0.2026  0.2386 5.02e-66          1
#>      table  model-c 239  0.0663 0.1453  0.0478  0.0848 1.87e-11          1
#>   Handbook linearity: bias = 0.0278 + -0.0092 * reference (slope p = 0.0268)
#>     R-squared 0.0023; t intercept 3.234; t slope -2.215; df 2150; t quantile 1.9611
#>   Item means: bias = 0.0278 + -0.0092 * reference; R-squared 0.0274; t intercept 1.510; t slope -1.034; df 38
#>   Handbook linearity verdict: unacceptable
#> The handbook regression uses all valid single deviations (df = 2150; gm - 2 in a balanced design); the regression on unweighted item means uses df = 38 (g - 2). Replicates of the same item may be correlated and are not independent. The handbook confidence band determines the linearity verdict.
```
