# Bootstrap intervals for gauge R&R statistics

Parametric bootstrap of the fitted mixed model
([`lme4::bootMer()`](https://rdrr.io/pkg/lme4/man/bootMer.html)): the
model is simulated `nsim` times, refitted and the gauge R&R statistics
recomputed. Percentile intervals are returned. With few prompt or model
levels the intervals are wide and asymmetric, which is the honest
answer;
[`msa_plan()`](https://danielmoj.github.io/llmsa/reference/msa_plan.md)
shows how study size changes this.

## Usage

``` r
msa_boot(fit, nsim = 200, level = 0.95, seed = NULL, ...)
```

## Arguments

- fit:

  An `msa_fit` of type numeric or binary.

- nsim:

  Number of bootstrap samples.

- level:

  Confidence level.

- seed:

  Optional seed.

- ...:

  Passed to
  [`lme4::bootMer()`](https://rdrr.io/pkg/lme4/man/bootMer.html), e.g.
  `parallel = "multicore"`.

## Value

A data.frame with the point estimate and interval for each statistic,
plus the bootstrap replicates as attribute `boot`.

## Details

Available for numeric and binary outcomes (lme4 models). For ordinal
outcomes fitted with
[`ordinal::clmm`](https://rdrr.io/pkg/ordinal/man/clmm.html) a
parametric bootstrap is not yet implemented; as a pragmatic alternative,
score the categories numerically and fit `type = "numeric"`, or treat
the top category as a binary outcome.

## Examples

``` r
# \donttest{
fit <- msa_fit(ic50_demo, type = "numeric")
msa_boot(fit, nsim = 50, seed = 1)
#> Parametric bootstrap, 50 replicates, 95 % percentile intervals
#>                      statistic estimate lower upper
#>              grr_pct_study_var    20.51 13.82 32.02
#>           grr_pct_contribution     4.21  1.91 10.25
#>    repeatability_pct_study_var    11.78 10.17 15.78
#>  reproducibility_pct_study_var    16.79  8.89 28.96
#>                            ndc     6.00  4.00 10.00
#>                      icc_items     0.96  0.90  0.98
# }
```
