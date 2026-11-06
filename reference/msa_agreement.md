# Attribute agreement of a categorical LLM pipeline

The categorical counterpart of
[`msa_grr()`](https://danielmoj.github.io/llmsa/reference/msa_grr.md),
following the attribute agreement analysis of the AIAG MSA manual: how
often does the pipeline give the same answer when asked again
(repeatability), the same answer under a different prompt or model
(reproducibility), and the correct answer (accuracy against a
reference)? Agreement is summarised as percentages of consistent cells
and items, as Krippendorff's alpha (which tolerates missing responses
and ordinal scales) and, against a reference, as Cohen's kappa with
optional ordinal weights.

## Usage

``` r
msa_agreement(
  runs,
  levels = NULL,
  reference = NULL,
  weights = c("unweighted", "linear", "quadratic"),
  fleiss = FALSE
)
```

## Arguments

- runs:

  An `msa_runs` object with categorical values.

- levels:

  The labels in scale order (needed for ordinal weights and for a clean
  category list). Default: sorted unique values.

- reference:

  Optional reference classification: a named vector keyed by `item_id`,
  a data.frame with columns `item_id` and `reference`, or the name of a
  column in `runs`.

- weights:

  Weighting of disagreements for the ordinal statistics: `unweighted`
  (nominal), `linear` (ordinal), `quadratic` (interval). Interval
  distances use category positions, not numeric label values.

- fleiss:

  Also compute Fleiss' kappa over all valid ratings of each item. Every
  observed item must have the same number of valid ratings, at least
  two. Unequal counts give `NA` with a message pointing to
  Krippendorff's alpha. Only the point estimate is returned; no standard
  error is computed.

## Value

An object of class `msa_agreement`, a list with `repeatability` (per
prompt-model cell: share of items whose replicates all agree),
`reproducibility` (share of items consistent across prompts, across
models and overall), `alpha` (Krippendorff's alpha within replicates,
across prompts, across models, and overall), and, if a reference is
given, `accuracy` (per prompt-model and overall) and `kappa` (Cohen's
kappa of the modal response and of all responses against the reference).
With `fleiss = TRUE`, `fleiss` is a list with the single numeric element
`kappa`.

## Details

Missing responses and responses outside `levels` are excluded. Accuracy
uses valid response-reference pairs. An item without a valid pair does
not enter the proportion of fully correct items. Repeatability and
reproducibility require at least two valid responses per unit; blocks do
not split these units. Alpha counts excluded observed units in
`n_units_excluded`, including units without any valid response.

Each item must have at most one distinct nonmissing reference. Repeated
identical references are allowed; a known reference beside missing
entries is used for that item. Conflicting references are errors.
Nonmissing references must belong to `levels`, including when the scale
is derived from responses. Supply the complete scale explicitly when
some categories occur only in the reference. Undefined Cohen's kappa
gives `NA` with a message, including single-category scales.

The modal response ignores missing answers; ties select the lowest of
the tied categories in scale order. An item without a valid answer has a
missing mode. These are general agreement diagnostics. The AP1
application uses its own decision metric: `acmg_modal()` treats missing
answers as a category and excludes tied modes from decisions. Cohen's
kappa over all responses has no standard error because responses of the
same item can be dependent.

## Examples

``` r
lv <- c("B", "LB", "VUS", "LP", "P")
ag <- msa_agreement(acmg_demo, levels = lv, reference = "reference", weights = "linear")
ag
#> Attribute agreement of an LLM measurement system
#>   60 items, 2160 responses (12 missing/unparseable); categories: B < LB < VUS < LP < P; weights: linear
#> 
#> Repeatability: 43.4 % of item-prompt-model cells have identical replicates
#>  prompt_id model_id pct_items_consistent
#>    concise  model-a               40.0 %
#>   criteria  model-a               38.3 %
#>       json  model-a               41.7 %
#>       role  model-a               43.3 %
#>    concise  model-b               45.0 %
#>   criteria  model-b               40.0 %
#>       json  model-b               35.6 %
#>       role  model-b               45.0 %
#>    concise  model-c               48.3 %
#>   criteria  model-c               51.7 %
#>       json  model-c               45.0 %
#>       role  model-c               46.7 %
#> 
#> Reproducibility: items consistent across prompts 16.7 %, across models 15.8 %, overall 8.3 %
#> 
#> Krippendorff's alpha:
#>                               scope alpha n_units_excluded
#>  replicates (within prompt & model) 0.876                1
#>       across prompts (within model) 0.874                0
#>       across models (within prompt) 0.839                0
#>                      all conditions 0.839                0
#> 
#> Accuracy vs reference: 60.8 % of responses correct; 8.3 % of items correct in every call
#>  prompt_id model_id pct_correct
#>    concise  model-a      59.0 %
#>   criteria  model-a      58.2 %
#>       json  model-a      63.3 %
#>       role  model-a      62.0 %
#>    concise  model-b      66.7 %
#>   criteria  model-b      66.1 %
#>       json  model-b      67.4 %
#>       role  model-b      60.5 %
#>    concise  model-c      50.0 %
#>   criteria  model-c      53.3 %
#>       json  model-c      58.9 %
#>       role  model-c      64.8 %
#>   Cohen's kappa (linear): modal response vs reference 0.863; all responses vs reference 0.737
```
