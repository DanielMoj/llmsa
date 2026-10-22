# Simulate a study with known variance components

Generates numeric results of a crossed study from assumed variance
components, for teaching and for planning study size with
[`msa_plan()`](https://danielmoj.github.io/llmsa/reference/msa_plan.md).

## Usage

``` r
msa_simulate(
  n_items,
  n_prompts,
  n_models,
  n_reps,
  n_blocks = 1,
  vc = list(item = 1, prompt = 0.05, model = 0.05, residual = 0.1),
  mean = 0,
  seed = NULL
)
```

## Arguments

- n_items, n_prompts, n_models, n_reps, n_blocks:

  Design sizes.

- vc:

  Named list of variance components: `item`, `prompt`, `model`, `block`,
  `item_prompt`, `item_model`, `prompt_model`, `residual`. Missing
  components are zero.

- mean:

  Grand mean.

- seed:

  Optional seed.

## Value

An `msa_runs` data.frame with a `latent` column holding the item truth
and the `value` column holding the simulated measurement.

## Examples

``` r
r <- msa_simulate(20, 3, 2, 3, vc = list(item = 1, prompt = 0.05, residual = 0.1), seed = 1)
msa_grr(msa_fit(r, type = "numeric"))
#> boundary (singular) fit: see help('isSingular')
#> Gauge R&R of an LLM measurement system
#>   outcome: numeric; 20 items x 3 prompts x 2 models x 1 block(s), 360 observations
#>  Source               Variance SD     % Contribution % Study Var
#>  Total gauge R&R      0.1020   0.3193 11.0 %         33.2 %     
#>    Repeatability      0.0960   0.3099 10.4 %         32.2 %     
#>    Reproducibility    0.0059   0.0771 0.6 %          8.0 %      
#>      prompt           0.0059   0.0771 0.6 %          8.0 %      
#>      model            0.0000   0.0000 0.0 %          0.0 %      
#>      prompt:model     0.0000   0.0000 0.0 %          0.0 %      
#>      item:prompt      0.0000   0.0000 0.0 %          0.0 %      
#>      item:model       0.0000   0.0000 0.0 %          0.0 %      
#>  Part-to-part (items) 0.8236   0.9075 89.0 %         94.3 %     
#>  Total variation      0.9255   0.9621 100.0 %        100.0 %    
#> 
#>   total gauge R&R: 33.2 % of study variation (11.0 % contribution)
#>   number of distinct categories (ndc): 4
#>   ICC (items): 0.890
#>   verdict: UNACCEPTABLE  [basis: % study variation, thresholds 10 / 30]
#>   note: singular fit, see ?msa_fit
```
