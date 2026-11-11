# Plan the size of a precision study by simulation

How many items, prompt variants, models and replicates does a study need
before the estimated percent gauge R&R can be trusted? With few prompt
or model levels the variance components of these factors are estimated
with large uncertainty, and the fit is often singular. This function
simulates studies of candidate sizes from assumed variance components,
refits each one and summarises the distribution of the estimated %GRR
(percent study variation) around its true value. A failed model fit
stops the planning run and reports its diagnostic; failed simulations
are not replaced or silently omitted.

## Usage

``` r
msa_plan(
  scenarios,
  vc = list(item = 1, prompt = 0.05, model = 0.05, residual = 0.1),
  nsim = 100,
  seed = NULL,
  verbose = TRUE
)
```

## Arguments

- scenarios:

  A data.frame with columns `n_items`, `n_prompts`, `n_models`, `n_reps`
  (and optionally `n_blocks`), one row per candidate design.

- vc:

  Assumed variance components, see
  [`msa_simulate()`](https://danielmoj.github.io/llmsa/reference/msa_simulate.md).

- nsim:

  Positive integer number of simulations per scenario.

- seed:

  Optional seed.

- verbose:

  Print progress.

## Value

A data.frame of class `msa_plan` with, per scenario, the true %GRR, the
mean and the 2.5 %, 50 % and 97.5 % quantiles of the estimates, the
root-mean-square error, the share of singular fits and the share of
simulations that misclassify the system relative to the 10 % / 30 %
thresholds (both exact thresholds are marginal). Additional columns are
`bias` (mean estimate minus truth), `empse` (sample standard deviation
of estimates), `mcse_bias` (EmpSE / sqrt(nsim)) and `mcse_empse`
(approximately EmpSE / sqrt(2 \* (nsim - 1))). With `nsim = 1`, EmpSE
and both MCSE columns are `NA_real_`.

The `replicates` attribute is a data.frame with `scenario` (input row
number), `sim` (repetition within the scenario), `estimate` (%GRR in
percent study variation), `singular` (logical) and `prompt` (the REML
prompt variance from that fit). With only one prompt variant there is no
estimated prompt component, so `prompt` is `NA_real_`, not a boundary
estimate of zero. For multiple prompt variants a missing or invalid
prompt estimate is an error. Singular fits, including estimates exactly
zero, remain in every summary. Non-finite %GRR estimates stop the run.

All summaries use these same replicates without rounding. Quantiles use
definition 7; true %GRR includes every non-item component, including the
block and pairwise interactions. Print rounds summaries to one decimal
place and returns the unchanged object invisibly. See the planning-rule
comparison in
[`vignette("validation", package = "llmsa")`](https://danielmoj.github.io/llmsa/articles/validation.md).

## Examples

``` r
# \donttest{
sc <- expand.grid(n_items = c(20, 40), n_prompts = c(3, 6), n_models = 3, n_reps = 3)
msa_plan(sc, vc = list(item = 1, prompt = 0.05, model = 0.05, residual = 0.1),
         nsim = 20, seed = 1)
#> scenario 1/4: 20 items, 3 prompts, 3 models, 3 reps, 1 block(s)
#> scenario 2/4: 40 items, 3 prompts, 3 models, 3 reps, 1 block(s)
#> scenario 3/4: 20 items, 6 prompts, 3 models, 3 reps, 1 block(s)
#> scenario 4/4: 40 items, 6 prompts, 3 models, 3 reps, 1 block(s)
#> Study-size planning by simulation (20 simulations per scenario)
#>   true %GRR (study variation) under the assumed variance components: 40.8 %
#>  n_items n_prompts n_models n_reps n_blocks mean q2.5 median q97.5 rmse
#>       20         3        3      3        1 41.0 29.2   39.9  58.3  8.7
#>       40         3        3      3        1 41.3 32.8   38.9  54.3  6.4
#>       20         6        3      3        1 41.1 28.8   40.2  54.5  6.8
#>       40         6        3      3        1 40.6 32.6   40.3  51.4  5.1
#>  pct_singular pct_misclassified bias empse mcse_bias mcse_empse
#>          90.0               5.0  0.2   8.9       2.0        1.5
#>          80.0               0.0  0.5   6.6       1.5        1.1
#>          85.0               5.0  0.3   7.0       1.6        1.1
#>         100.0               0.0 -0.2   5.3       1.2        0.9
# }
```
