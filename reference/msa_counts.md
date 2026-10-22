# Realised cell counts of a study

Tabulates how many parsed values exist per item, prompt and model, which
documents the realised (possibly unbalanced) design in the report.

## Usage

``` r
msa_counts(runs)
```

## Arguments

- runs:

  An `msa_runs` object.

## Value

A data.frame with the number of planned and valid responses per
prompt-model combination, plus the number of items with fewer than two
valid replicates.
