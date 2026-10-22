# Plan the size of a precision study by simulation

How many items, prompt variants, models and replicates does a study need
before the estimated percent gauge R&R can be trusted? With few prompt
or model levels the variance components of these factors are estimated
with large uncertainty, and the fit is often singular. This function
simulates studies of candidate sizes from assumed variance components,
refits each one and summarises the distribution of the estimated %GRR
(percent study variation) around its true value.

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

  Simulations per scenario.

- seed:

  Optional seed.

- verbose:

  Print progress.

## Value

A data.frame of class `msa_plan` with, per scenario, the true %GRR, the
mean and the 2.5 %, 50 % and 97.5 % quantiles of the estimates, the
root-mean-square error, the share of singular fits and the share of
simulations that misclassify the system relative to the 10 % / 30 %
thresholds.

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
#>  pct_singular pct_misclassified
#>          85.0               5.0
#>          80.0               0.0
#>          85.0               5.0
#>         100.0               0.0
# }
```
