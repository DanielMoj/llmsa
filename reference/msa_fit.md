# Estimate the variance components of an LLM measurement system

Fits a crossed random-effects model to the parsed values of a study.
Items, prompt variants, models and blocks enter as random effects; for
numeric outcomes the interactions item:prompt, item:model and
prompt:model are included by default. The residual variance is the
repeatability (replicate-to-replicate variation under identical
conditions).

## Usage

``` r
msa_fit(
  runs,
  type = c("numeric", "ordinal", "binary"),
  levels = NULL,
  interactions = NULL,
  link = c("probit", "logit"),
  ...
)
```

## Arguments

- runs:

  An `msa_runs` object (from
  [`msa_run()`](https://danielmoj.github.io/llmsa/reference/msa_run.md)
  or
  [`as_msa_runs()`](https://danielmoj.github.io/llmsa/reference/as_msa_runs.md)).

- type:

  Outcome type.

- levels:

  For ordinal outcomes: the labels in scale order. For binary outcomes
  given as labels: a length-two vector whose second element is the
  event.

- interactions:

  Include the two-way interactions as random effects? Default `TRUE` for
  numeric, `FALSE` otherwise.

- link:

  Link for ordinal and binary outcomes.

- ...:

  Passed on to the model-fitting function.

## Value

An object of class `msa_fit`: a list with the fitted `model`, the
variance-component table `vc` (source, variance), the model `formula`,
the analysed `data`, counts `n`, the outcome `type`, and a `singular`
flag (a variance estimated at zero, common with few prompt or model
levels; the point estimate is still valid but its uncertainty is large,
see
[`msa_boot()`](https://danielmoj.github.io/llmsa/reference/msa_boot.md)
and
[`msa_plan()`](https://danielmoj.github.io/llmsa/reference/msa_plan.md)).

## Details

- `type = "numeric"`: linear mixed model fitted by REML with
  [`lme4::lmer()`](https://rdrr.io/pkg/lme4/man/lmer.html).

- `type = "ordinal"`: cumulative link mixed model with
  [`ordinal::clmm()`](https://rdrr.io/pkg/ordinal/man/clmm.html).
  Variance components live on the latent scale, where the residual
  variance is fixed (1 for the probit link, pi^2/3 for the logit link).
  Interactions are off by default because they are costly in `clmm`.

- `type = "binary"`: generalised linear mixed model with
  [`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html) and the
  same latent-scale convention.

Factors with a single level (for example one model only) are dropped
from the model automatically. For ordinal outcomes
[`ordinal::clmm`](https://rdrr.io/pkg/ordinal/man/clmm.html) requires
more than two levels per random-effect factor; a factor with exactly two
levels (two models, two blocks) therefore enters as a fixed effect and
its variance component is derived from the estimated difference `beta`
by the range method (`beta^2 / 2`), which is how the AIAG X-bar/R
procedure treats two appraisers. Ordinal outcomes need at least three
items.

## See also

[`msa_grr()`](https://danielmoj.github.io/llmsa/reference/msa_grr.md) to
turn the variance components into gauge R&R statistics.

## Examples

``` r
fit <- msa_fit(ic50_demo, type = "numeric")
fit
#> Variance components of an LLM measurement system (numeric outcome)
#>   formula: y ~ 1 + (1 | item) + (1 | prompt) + (1 | model) + (1 | block) +     (1 | item:prompt) + (1 | item:model) + (1 | prompt:model)
#>   40 items x 3 prompts x 3 models x 2 block(s); 2152 observations; 2-3 valid replicates per cell
#>        source variance     sd    pct
#>    item:model   0.0054 0.0731  0.5 %
#>   item:prompt   0.0001 0.0092  0.0 %
#>          item   0.9672 0.9834 95.8 %
#>  prompt:model   0.0000 0.0046  0.0 %
#>         model   0.0171 0.1309  1.7 %
#>        prompt   0.0049 0.0697  0.5 %
#>         block   0.0010 0.0319  0.1 %
#>      Residual   0.0140 0.1184  1.4 %
# \donttest{
fit_ord <- msa_fit(acmg_demo, type = "ordinal",
                   levels = c("B", "LB", "VUS", "LP", "P"))
fit_ord$vc
#>     source   variance
#> 1     item 9.25608623
#> 2   prompt 0.03887272
#> 3    model 0.27811710
#> 4 Residual 1.00000000
# }
```
