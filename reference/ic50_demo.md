# Simulated numeric extraction (log10 IC50) by an LLM pipeline

A simulated crossed study with a numeric outcome: 40 compounds, 3 prompt
variants, 3 models, 3 replicates in each of 2 blocks (days), 2160 calls
with 8 missing values. Generated with known effects of prompt, model,
block and item:model interaction (see `attr(ic50_demo, "simulation")`);
`reference` is the true value.

## Usage

``` r
ic50_demo
```

## Format

An `msa_runs` data.frame with columns `block`, `item_id`, `prompt_id`,
`model_id`, `rep`, `value`, `reference`.

## Examples

``` r
head(ic50_demo)
#> LLM runs: 6 calls, 1 items, 1 prompt variants, 2 models, 1 block(s)
#>   missing values: 0
#>  block item_id prompt_id model_id rep value
#>      1  CPD001    direct  model-a   1 1.585
#>      1  CPD001    direct  model-a   2 1.467
#>      1  CPD001    direct  model-a   3 1.791
#>      1  CPD001    direct  model-b   1 1.323
#>      1  CPD001    direct  model-b   2 1.473
#>      1  CPD001    direct  model-b   3 1.291
msa_grr(msa_fit(ic50_demo, type = "numeric"))
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
#>      item:model       0.0054   0.0731 0.5 %          7.3 %      
#>  Part-to-part (items) 0.9672   0.9834 95.8 %         97.9 %     
#>  Total variation      1.0096   1.0048 100.0 %        100.0 %    
#> 
#>   total gauge R&R: 20.5 % of study variation (4.2 % contribution)
#>   number of distinct categories (ndc): 6
#>   ICC (items): 0.958
#>   verdict: MARGINAL  [basis: % study variation, thresholds 10 / 30]
```
