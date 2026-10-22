# Plackett-Burman screening design for robustness testing

Robustness in the ICH Q2(R2) sense asks whether small, deliberate
variations of the method leave the result unchanged. For an LLM pipeline
the natural perturbations are formatting and context variations: number
format, units, spelling errors, column order, irrelevant extra context,
a different system prompt, temperature, and so on. A Plackett-Burman
design screens up to `n_runs - 1` such factors at two levels each in
`n_runs` runs, with every pair of factors balanced and orthogonal, so
each main effect is estimated from all runs.

## Usage

``` r
pb_design(factors, n_runs = NULL, randomize = TRUE, seed = NULL)
```

## Arguments

- factors:

  A named list; each element is a length-two vector with the low (`-1`)
  and high (`+1`) level of one factor, for example
  `list(number_format = c("plain", "scientific"), typos = c("none", "two"))`.
  Alternatively a single integer giving the number of factors.

- n_runs:

  Number of runs: 8, 12, 16, 20 or 24. Default: the smallest design that
  accommodates the factors.

- randomize:

  Randomise the run order (recommended).

- seed:

  Optional seed.

## Value

A data.frame of class `pb_design` with one row per run, a column `run`,
one coded column per factor (`-1`/`+1`), and, when levels were given,
one labelled column per factor (suffix `_level`). The design matrix is
stored as attribute `coded`.

## References

Plackett, R. L. and Burman, J. P. (1946). The design of optimum
multifactorial experiments. *Biometrika* 33, 305-325.

## Examples

``` r
f <- list(number_format = c("plain", "scientific"),
          units = c("nM", "ng/mL"), typos = c("none", "two"),
          extra_context = c("none", "unrelated paragraph"),
          system_prompt = c("A", "B"), temperature = c(0, 0.7))
d <- pb_design(f, seed = 1)
d
#> Plackett-Burman design: 8 runs, 6 factors (8-run design screens up to 7)
#>  run number_format units typos extra_context system_prompt temperature
#>    1             1     1     1            -1             1          -1
#>    2             1    -1    -1             1             1           1
#>    3            -1    -1    -1            -1            -1          -1
#>    4            -1     1     1             1            -1           1
#>    5             1    -1     1            -1            -1           1
#>    6            -1    -1     1             1             1          -1
#>    7             1     1    -1             1            -1          -1
#>    8            -1     1    -1            -1             1           1
#>  number_format_level units_level typos_level extra_context_level
#>           scientific       ng/mL         two                none
#>           scientific          nM        none unrelated paragraph
#>                plain          nM        none                none
#>                plain       ng/mL         two unrelated paragraph
#>           scientific          nM         two                none
#>                plain          nM         two unrelated paragraph
#>           scientific       ng/mL        none unrelated paragraph
#>                plain       ng/mL        none                none
#>  system_prompt_level temperature_level
#>                    B                 0
#>                    B               0.7
#>                    A                 0
#>                    A               0.7
#>                    A               0.7
#>                    B                 0
#>                    A                 0
#>                    B               0.7
```
