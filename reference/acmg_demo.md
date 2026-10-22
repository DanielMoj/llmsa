# Simulated ACMG/AMP variant classifications by an LLM pipeline

A simulated crossed study: 60 variants classified into the five ACMG/AMP
tiers (`B` benign, `LB` likely benign, `VUS` uncertain significance,
`LP` likely pathogenic, `P` pathogenic) under 4 prompt variants and 3
models, 3 replicates each (2160 calls, 12 of them unparseable). The data
were generated from a latent-variable model with known variance
components (see `attr(acmg_demo, "simulation")` and
`data-raw/make_demo_data.R`); `reference` is the true tier. No real
variants or models are involved.

## Usage

``` r
acmg_demo
```

## Format

An `msa_runs` data.frame with columns `block`, `item_id`, `prompt_id`,
`model_id`, `rep`, `value`, `reference`.

## Examples

``` r
head(acmg_demo)
#> LLM runs: 6 calls, 1 items, 1 prompt variants, 2 models, 1 block(s)
#>   missing values: 0
#>  block item_id prompt_id model_id rep value
#>      1  VAR001   concise  model-a   1     B
#>      1  VAR001   concise  model-a   2     B
#>      1  VAR001   concise  model-a   3     B
#>      1  VAR001   concise  model-b   1     B
#>      1  VAR001   concise  model-b   2     B
#>      1  VAR001   concise  model-b   3     B
table(acmg_demo$value, useNA = "ifany")
#> 
#>    B   LB   LP    P  VUS <NA> 
#>  324  438  385  514  487   12 
```
