# Analyse a robustness screening experiment

Estimates the main effect of every factor in a Plackett-Burman (or any
two-level orthogonal) design on a response such as accuracy, agreement
with the reference, or the mean parsed value, and judges which effects
are active with Lenth's pseudo standard error, which needs no replicate
runs. Effects beyond the margin of error (ME) are flagged as active at
the 5 % level per effect; the simultaneous margin (SME) controls the
family-wise error.

## Usage

``` r
msa_robustness(design, response, factors = NULL, alpha = 0.05)
```

## Arguments

- design:

  A `pb_design` (or a data.frame with coded `-1`/`+1` columns named in
  `factors`).

- response:

  Numeric response, one value per run, in the row order of `design`.

- factors:

  Factor columns to analyse; default: all coded columns.

- alpha:

  Significance level for ME and SME.

## Value

An object of class `msa_robustness`: a data.frame of effects (`effect` =
mean at high level minus mean at low level, `t_lenth` = effect / PSE,
`active` flag) with attributes `pse`, `me`, `sme`, plus the response
summary.

## References

Lenth, R. V. (1989). Quick and easy analysis of unreplicated factorials.
*Technometrics* 31, 469-473.

## Examples

``` r
d <- pb_design(list(format = c("plain", "sci"), units = c("nM", "ng/mL"),
                    typos = c(0, 2), context = c("none", "extra"),
                    system = c("A", "B"), temp = c(0, 0.7)), seed = 1)
set.seed(7)
acc <- 0.9 - 0.08 * (d$typos > 0) - 0.05 * (d$temp > 0) + rnorm(nrow(d), 0, 0.01)
msa_robustness(d, acc)
#> Robustness screening: 8 runs, 6 factors; response mean 0.8334 (sd 0.0532)
#>   Lenth PSE 0.0100, ME 0.0432, SME 0.1081 (alpha = 0.05)
#>   factor  effect t_lenth active active_simultaneous
#>    typos -0.0770   -7.67   TRUE               FALSE
#>     temp -0.0602   -6.00   TRUE               FALSE
#>    units  0.0158    1.57  FALSE               FALSE
#>   format  0.0076    0.76  FALSE               FALSE
#>  context -0.0058   -0.58  FALSE               FALSE
#>   system  0.0034    0.34  FALSE               FALSE
#>   active factors (|effect| > ME): typos, temp
```
