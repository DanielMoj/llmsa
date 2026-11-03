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

  For ordinal outcomes: at least two distinct, non-missing, non-empty
  labels in scale order. For binary outcomes: two such labels, whose
  second element is the event. When supplied, these labels determine the
  coding regardless of the response's storage type. Labels require this
  explicit argument; their order of occurrence or factor levels do not
  determine the event.

- interactions:

  Include the two-way interactions as random effects? Default `TRUE` for
  numeric, `FALSE` otherwise.

- link:

  Link for ordinal and binary outcomes.

- ...:

  Passed on to the model-fitting function. For numeric outcomes,
  supplying any argument here selects a direct
  [`lme4::lmer()`](https://rdrr.io/pkg/lme4/man/lmer.html) call on the
  original response, including when an argument is explicitly `NULL`.
  Expressions in `subset`, `weights` and `offset` can use the internal
  columns `item`, `prompt`, `model`, `block` and `y`. Row-based
  arguments refer to the rows remaining after missing or unreadable
  responses are removed. Other symbols in these expressions are looked
  up in the immediate caller of `msa_fit()`, as in a direct `lmer()`
  call; a wrapper forwarding `...` must make them available in that
  frame. Other arguments retain their original argument environments
  when forwarded.

## Value

An object of class `msa_fit`: a list with the fitted `model`, the
variance-component table `vc` (source, variance), the model `formula`,
the analysed `data`, counts `n`, the outcome `type`, and a `singular`
flag (a variance estimated at zero, common with few prompt or model
levels; the point estimate is still valid but its uncertainty is large,
see
[`msa_boot()`](https://danielmoj.github.io/llmsa/reference/msa_boot.md)
and
[`msa_plan()`](https://danielmoj.github.io/llmsa/reference/msa_plan.md)),
plus numeric fitting diagnostics `numerics` (`NULL` for other outcome
types), logical `converged`, and `derived` (sources estimated from two
fixed levels, also in `attr(vc, "derived")`).

## Details

- `type = "numeric"`: linear mixed model fitted by REML, returned as an
  [`lme4::lmer()`](https://rdrr.io/pkg/lme4/man/lmer.html) model. See
  the numeric fitting details below.

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
by the range method (`beta^2 / 2`). This substitute does not subtract
the AIAG handbook correction `EV^2 / (n * r)`. It has positive bias:
`E[beta-hat^2 / 2] = sigma^2 + Var(beta-hat) / 2`. Every such fit warns
and both print methods identify the derived sources. The `two_level`
simulation study and its table in
[`vignette("validation")`](https://danielmoj.github.io/llmsa/articles/validation.md)
(`vignettes/validation.Rmd`) investigate that bias. Short runs establish
reproducibility; quantitative findings require the full simulation runs.
With fewer than three ordinal items the error is "At least three items
are needed for ordinal outcomes."

With no arguments in `...`, the numeric fit preserves the input doubles
and conditions their differences before solving for variance ratios.
Eligible balanced designs use a closed expected-mean-square solution.
Unbalanced designs and multi-factor variance boundaries use an analytic
profiled REML score and Hessian, initialized by `lmer`, with nonnegative
variance constraints. A boundary solution re-estimates the remaining
components. The resulting lme4 model retains the original response
scale, row order and factor labels; `vc` is extracted from its
`VarCorr()`.

The `numerics` field records the method (`"closed_form"`,
`"analytic_reml"` or `"lmer"`) and, for the default path, conditioning,
initialization diagnostics, active zero constraints and convergence
norms. Its `input_rows` maps the rows actually analysed by the model to
the input, including exclusions by `subset` or `na.action`. The returned
`data` and all counts in `n` describe those same rows. Initialization
warnings are retained in `numerics$start$warnings` after successful
analytic completion, and emitted if completion fails. Final-model
convergence checks remain active. Explicit lme4 arguments retain lme4
warnings and errors. Initialization failures on the default path
identify the fitting stage and retain the underlying engine's message.
Numerical warnings or errors during original-scale model construction
produce a named representability error. Final `checkConv` warnings can
precede that error when the model is not representable at working
precision.

Default numeric models store ordinary `nloptwrap` refit control with no
extra optimizer options.
[`msa_boot()`](https://danielmoj.github.io/llmsa/reference/msa_boot.md)
and [`lme4::refit()`](https://rdrr.io/pkg/lme4/man/refit.html) therefore
use normal lme4 optimization; they do not repeat the initial analytic
completion. The actual initial method is also recorded in the model's
`optinfo$completion`. Both numeric paths store the fitting data and
evaluated arguments in the model call so it remains usable outside the
original caller's scope. Printing or deparsing that embedded lme4 call
can therefore be lengthy; printing the `msa_fit` object gives the
compact study summary.

Constant numeric responses, non-finite values, non-identifiable
components and a degenerate residual variance produce named errors.
There is no absolute variance cutoff for small representable variation
or tied scores. A positive residual variance does not guarantee a fit:
with high repeatability, initialization, analytic completion or
construction of the original-scale model can fail at working precision.
Final convergence checks use the standard-deviation-ratio scale: a
numerically singular Hessian warning can occur even for an identifiable
balanced model with a closed-form solution. Numeric `NaN` and the string
`"NaN"` are treated as missing responses, without a parsing warning.
Missing numeric grouping values are rejected on both fitting paths. The
default path rejects variances whose original-scale representation or
model arithmetic loses working precision; conditioning cannot recover
digits lost in the inputs.

Ordinal and binary fits discard missing responses, and labels outside
`levels`, with a warning giving the count. All returned data and study
counts describe the retained observations. Missing grouping values are
rejected. No remaining response, or a constant response category,
produces a named error. Binary numeric values (including numeric strings
without `levels`) must be finite and exactly zero or one; they are never
rounded. Row selection, including missing weights or offsets handled by
`na.action`, precedes the choice of random and two-level fixed effects.
Ordinal offsets are retained in `data$.msa_offset` and included in the
model formula. Counts in `n` describe data rows; with ordinal frequency
weights, `stats::nobs(model)` follows `clmm` and reports the sum of
those weights. Non-identifiable two-level fixed effects and ordinal
random-effect terms with fewer than three observed levels produce named
errors. Before either latent engine is called, random-effect variances
must be separately identifiable after accounting for the fixed effects.
Confounded grouping factors, including interactions, produce an error
naming the affected terms. This check includes the fixed latent residual
variance: a random term with one observation per level, or a confounded
linear combination of terms, cannot be separated from that residual. If
all retained weights are integers, they count as multiplicities,
including binomial prior weights for zero/one responses. Otherwise each
positive-weight row counts once in this check, including the
fixed-effect rank check. Zero-weight rows contribute no information. The
original weights are passed to the engine unchanged. Weights must be
finite, non-negative numeric values with a finite positive sum. Sparse
covariance cross-products avoid dense level-by-level projection blocks
when checking large designs. Ordinal singularity describes random
effects only, not the derived components. Ordinal and binary estimates
are invariant to row order and factor labels only up to the optimization
tolerance of the underlying engines.

Without `control` in `...`, ordinal fits use
`ordinal::clmm.control(iter.max = 2000, eval.max = 4000)`. An explicit
`control` passed in `...` replaces both limits, including when it is an
empty or partial list. Optimizer options given directly in `...`, such
as `iter.max`, take precedence over the corresponding default limit, as
in [`ordinal::clmm()`](https://rdrr.io/pkg/ordinal/man/clmm.html).

`converged` records the final engine diagnosis, independently of
`singular`. For `clmm`, success means code zero for `nlminb`, or code
one or two for `ucminf`; the matrix fitting path uses `nlminb` even if
`ucminf` was requested. For lme4 models, success requires optimizer code
zero and no convergence message other than the singular-boundary note.
Missing or unreadable codes do not confirm convergence. On both numeric
paths the final model decides: initialization diagnostics do not, and a
final Hessian or gradient diagnostic means `converged = FALSE` even
after analytic completion. Numeric warning behavior remains that of lme4
and its final convergence check. Ordinal and binary non-convergence is
warned, including a diagnosis stored by the engine without an emitted
warning. A range-method warning alone does not indicate non-convergence.

## Known limitations

Zero-weight rows still contribute levels when selecting random versus
two-level fixed effects. An ordinal fit can therefore reject a random
factor with fewer than three levels among its positive-weight rows. Use
`subset` to exclude those rows when that is the intended design. Numeric
fits with explicit arguments in `...` use lme4's diagnostics; the
default numeric path's identifiability check does not apply to them.

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
#>    item:model   0.0053 0.0731  0.5 %
#>   item:prompt   0.0001 0.0092  0.0 %
#>          item   0.9672 0.9835 95.8 %
#>  prompt:model   0.0000 0.0046  0.0 %
#>         model   0.0171 0.1309  1.7 %
#>        prompt   0.0049 0.0697  0.5 %
#>         block   0.0010 0.0319  0.1 %
#>      Residual   0.0140 0.1184  1.4 %
# \donttest{
fit_ord <- msa_fit(acmg_demo, type = "ordinal",
                   levels = c("B", "LB", "VUS", "LP", "P"))
#> Warning: 12 missing response(s) were dropped.
fit_ord$vc
#>     source   variance
#> 1     item 9.25609132
#> 2   prompt 0.03887219
#> 3    model 0.27811382
#> 4 Residual 1.00000000
# }
```
