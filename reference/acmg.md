# Internal AP1 application pipeline

Frozen configuration, local item import, prompt construction and
evaluation for the operator-approved AP1 study. These functions are
internal: they do not extend the domain-independent public API.

## Usage

``` r
acmg_plan(path = NULL)

acmg_items(insaid_path = NULL, pilot = FALSE)

acmg_prompts(robustness = FALSE)

acmg_evaluate(runs, plan)
```

## Arguments

- path:

  Optional YAML file; the default is the shipped AP1 plan.

- insaid_path:

  Optional local INSAID TSV. Its reference classes and protein notation
  are joined in memory, never saved by this importer.

- pilot:

  Read the disjoint pilot items instead of the main items.

- robustness:

  Return the twelve PB templates and their coded factors.

- runs:

  Main and optional PB responses as an `msa_runs`, with item columns
  `reference`, `source` and `prior_differs_sol/llama/qwen`.

- plan:

  A list read by `acmg_plan()`.

## Value

`acmg_plan()` returns a validated list. `acmg_items()` returns a
data.frame. `acmg_prompts()` returns named templates, or a PB
data.frame. `acmg_evaluate()` returns `models` keyed by model and a
joint `msa_fit`. Each model includes GRR, fit diagnostics, modal
responses, item-bootstrap kappa, agreement, stratified rates, robustness
with backend errors per PB run, completeness, provenance, criteria bands
and an external rendered report. Incomplete results are not assessed.
