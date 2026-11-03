# Gauge repeatability and reproducibility of an LLM pipeline

Turns the variance components of an
[`msa_fit()`](https://danielmoj.github.io/llmsa/reference/msa_fit.md)
into the statistics that a measurement-system analysis reports. The
vocabulary follows the AIAG *Measurement Systems Analysis* manual:

## Usage

``` r
msa_grr(fit, threshold = NULL, basis = c("study_var", "contribution"))
```

## Arguments

- fit:

  An `msa_fit`.

- threshold:

  Length-two vector of thresholds (acceptable / marginal) on the chosen
  basis, in percent. Values must be numeric, finite, nonnegative and
  nondecreasing; `NULL` selects the defaults for `basis`.

- basis:

  `"study_var"` classifies by percent study variation (default,
  thresholds 10 and 30), `"contribution"` by percent contribution
  (typical thresholds 1 and 9).

## Value

An object of class `msa_grr` with elements `table` (one row per source),
`summary` (named vector: `grr_pct_study_var`, `grr_pct_contribution`,
`repeatability_pct_study_var`, `reproducibility_pct_study_var`, `ndc`,
`icc_items`), `verdict`, the thresholds, the outcome type and `derived`
(the sources named by `attr(fit$vc, "derived")`).

## Details

- **Repeatability**: the residual variance, i.e. variation between
  replicate calls under identical conditions (same item, prompt, model).

- **Reproducibility**: variation attributable to the measurement
  conditions, here prompt variant, model, block (time) and their
  interactions with each other and with the items.

- **Total gauge R&R**: repeatability + reproducibility, the variance the
  pipeline adds to a result.

- **Part-to-part**: the variance between items, the signal the pipeline
  is meant to resolve.

Two ratios are reported for every source: the *percent contribution*
(variance / total variance) and the *percent study variation* (standard
deviation / total standard deviation). The AIAG rule of thumb classifies
a system by the percent study variation of total gauge R&R: below 10 %
acceptable, 10-30 % marginal (may be acceptable depending on the
application, cost and risk), above 30 % unacceptable. The number of
distinct categories (ndc) is `max(1, floor(1.41 * sd_items / sd_grr))`;
a system should resolve at least 5. Thresholds should be set from the
model risk of the context of use, not taken as universal constants.

If total variance is zero, percentages, ICC and ndc are `NA` and the
verdict is `"undetermined"`. With positive item variance and zero gauge
variance, ndc is `Inf`. With zero item variance and positive gauge
variance, ndc is one. These conventions also apply to
[`msa_boot()`](https://danielmoj.github.io/llmsa/reference/msa_boot.md).
For latent outcomes these statistics use the link's fixed residual
variance. Sources derived from two fixed ordinal levels are retained in
`derived` and identified when printing; see
[`msa_fit()`](https://danielmoj.github.io/llmsa/reference/msa_fit.md)
for their positive bias and the `two_level` study in
[`vignette("validation")`](https://danielmoj.github.io/llmsa/articles/validation.md).
On the latent scale, Repeatability is the residual variance fixed by the
link, not a measurement of disagreement between replicates; see the
share of cells with identical replicates from
[`msa_agreement()`](https://danielmoj.github.io/llmsa/reference/msa_agreement.md).

## Examples

``` r
g <- msa_grr(msa_fit(ic50_demo, type = "numeric"))
g
#> Gauge R&R of an LLM measurement system
#>   outcome: numeric; 40 items x 3 prompts x 3 models x 2 block(s), 2152 observations
#>  Source               Variance SD     % Contribution % Study Var
#>  Total gauge R&R      0.0425   0.2061 4.2 %          20.5 %     
#>    Repeatability      0.0140   0.1184 1.4 %          11.8 %     
#>    Reproducibility    0.0285   0.1687 2.8 %          16.8 %     
#>      prompt           0.0049   0.0697 0.5 %          6.9 %      
#>      model            0.0171   0.1309 1.7 %          13.0 %     
#>      block (time)     0.0010   0.0319 0.1 %          3.2 %      
#>      prompt:model     0.0000   0.0046 0.0 %          0.5 %      
#>      item:prompt      0.0001   0.0092 0.0 %          0.9 %      
#>      item:model       0.0053   0.0731 0.5 %          7.3 %      
#>  Part-to-part (items) 0.9672   0.9835 95.8 %         97.9 %     
#>  Total variation      1.0097   1.0048 100.0 %        100.0 %    
#> 
#>   total gauge R&R: 20.5 % of study variation (4.2 % contribution)
#>   number of distinct categories (ndc): 6
#>   ICC (items): 0.958
#>   verdict: MARGINAL  [basis: % study variation, thresholds 10 / 30]
g$summary
#>             grr_pct_study_var          grr_pct_contribution 
#>                    20.5115983                     4.2072567 
#>   repeatability_pct_study_var reproducibility_pct_study_var 
#>                    11.7795154                    16.7919231 
#>                           ndc                     icc_items 
#>                     6.0000000                     0.9579274 
```
