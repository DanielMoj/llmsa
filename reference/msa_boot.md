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
  `parallel = "snow"` with a caller-supplied cluster `cl`.

## Value

A data.frame with the point estimate and interval for each statistic,
plus the bootstrap replicates as attribute `boot`, the confidence
`level`, and counts `n_failed` (replicates with at least one non-finite
statistic) and `n_singular` (singular replicates with all statistics
finite). An explicitly supplied `seed` is retained as the `seed`
attribute for reporting; with `seed = NULL` no seed provenance is
claimed.

## Details

Available for numeric and binary outcomes (lme4 models). For ordinal
outcomes fitted with
[`ordinal::clmm`](https://rdrr.io/pkg/ordinal/man/clmm.html) a
parametric bootstrap is not yet implemented; as a pragmatic alternative,
score the categories numerically and fit `type = "numeric"`, or treat
the top category as a binary outcome.

Numeric default fits use ordinary lme4 REML refits with `nloptwrap` and
its usual control settings; the analytical completion of the original
fit is not repeated for each bootstrap sample. An explicit fitting
control passed to
[`msa_fit()`](https://danielmoj.github.io/llmsa/reference/msa_fit.md)
remains the model's refit control.

Singular refits with finite statistics are retained in the percentile
intervals. Only non-finite values are removed, separately for each
statistic. A replicate with any non-finite statistic counts as failed;
it is not also counted as singular. The original fit is not a replicate.
Both counts are reported by the print method, including when zero.

The `boot_coverage` simulation study investigates interval coverage and
width by scenario; see its table in
[`vignette("validation", package = "llmsa")`](https://danielmoj.github.io/llmsa/articles/validation.md)
(`vignettes/validation.Rmd`). The full runs report overcoverage of the
integer-valued ndc intervals in S-boot-1, S-boot-2, S-boot-3, S-boot-4,
S-boot-5, S-boot-6 and S-boot-7 beyond the anchored MCSE report
threshold. No other interval estimand exceeds that report threshold in
these runs. These are reported findings, not a reason to change the
intervals. The vignette tabulates every scenario's coverage, width,
bias, empirical standard error and MCSE, with bootstrap diagnostics
shown separately.

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
#>  reproducibility_pct_study_var    16.79  8.89 28.95
#>                            ndc     6.00  4.00 10.00
#>                      icc_items     0.96  0.90  0.98
#>   0 failed or non-finite replicates (non-finite values dropped)
#>   30 singular replicates retained in the intervals
# }
```
