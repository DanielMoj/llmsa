# Changelog

## llmsa (development version)

- [`msa_robustness()`](https://danielmoj.github.io/llmsa/reference/msa_robustness.md)
  accepts `transform = "logit"` for finite proportions strictly between
  zero and one. Effects and response summaries then use the logit scale;
  the default `transform = "none"` preserves existing results.

- The robustness half-normal plot names Daniel’s plotting convention.
  The help page explains that Lenth’s ME and SME are conservative and
  `alpha` is a nominal significance level.

- New offline `llm-stability` and `clinvar-raters` vignettes recompute
  agreement and latent variance components from reproducible, licensed
  frozen subsets. Data preparation records parsing failures, exclusions,
  selection rules and SHA-256 provenance. Missing answers stay missing;
  the stability article explains the source’s two non-label answer keys.

- The validation vignette reports all four full simulation studies with
  MCSE, dynamically identified component-bias and interval-coverage
  findings, and a separate ordinal convergence sensitivity. Help pages
  describe the observed underestimation of some prompt/model components
  and overcoverage of integer-valued ndc intervals. Core calculations
  and the operator’s simulation files are unchanged.

- Robustness printing and reports now state that no factor exceeding ME
  does not establish pipeline robustness. Every active factor is
  labelled `above ME only` or `also above SME`; results and AP1 bands
  are unchanged.

- [`msa_boot()`](https://danielmoj.github.io/llmsa/reference/msa_boot.md)
  records failed and singular replicates separately as `n_failed` and
  `n_singular`. Percentile intervals retain finite singular refits and
  omit only non-finite values. Printing always reports both counts;
  older objects identify singular counts as not recorded.

- Latent gauge R&R summaries, reports and
  [`?msa_grr`](https://danielmoj.github.io/llmsa/reference/msa_grr.md)
  explain that Repeatability is the residual variance fixed by the link.
  Observed agreement between replicates is available from
  [`msa_agreement()`](https://danielmoj.github.io/llmsa/reference/msa_agreement.md).

- Ordinal fits default to `iter.max = 2000` and `eval.max = 4000`.
  Explicit `control` replaces these limits; direct optimizer options in
  `...` follow
  [`ordinal::clmm()`](https://rdrr.io/pkg/ordinal/man/clmm.html)
  precedence. See
  [`?msa_fit`](https://danielmoj.github.io/llmsa/reference/msa_fit.md).

- The `boot_coverage` study and validation vignette report percentile
  interval coverage, width and bootstrap diagnostics with MCSE. The
  shipped short runs check reproducibility; full-run findings follow
  separately. All three latent recovery short runs are regenerated with
  the updated ordinal fitting limits.

- Ordinal and binary fits reject confounded random-effect variances
  before calling the engine, including interactions and terms spanned by
  fixed effects. The check includes the fixed latent residual variance
  and frequency weights: zero-weight rows contribute no information, and
  a random term with one observation per level cannot be separated from
  the residual. Errors name only the affected terms and explain residual
  confounding when present. Sparse cross-products preserve this check
  for designs with thousands of factor levels without dense projection
  blocks. Integer weights count as frequencies; if any retained weight
  is noninteger, each positive-weight row counts once in the check.
  Engine weights are unchanged. The help page documents the limitations
  of term selection with zero-weight rows. Identifiable designs retain
  their existing engine fits; ordinal singularity concerns random
  effects only.

- Latent fits apply `subset`, `weights`, `offset` and `na.action` before
  selecting model terms, so data and study counts describe the analysed
  rows. Ordinal offsets are kept in `data$.msa_offset`; with frequency
  weights, `n$observations` counts rows and `nobs(model)` reports the
  weight sum. Stored engine calls retain evaluated arguments and can be
  evaluated again outside the original caller, including for binary
  refits and bootstraps.

- Explicit ordinal and binary `levels` must contain distinct,
  non-missing, non-empty labels. They determine the coding independently
  of the response storage type and take precedence over an ordered
  factor’s levels.

- Ordinal and binary fits validate exact binary codes, explicit event
  labels, missing grouping values and constant categories. Dropped
  responses are counted in warnings and in the returned study size.

- [`msa_fit()`](https://danielmoj.github.io/llmsa/reference/msa_fit.md)
  now reports final-engine `converged` independently of `singular`. The
  actual clmm optimizer determines success, including its matrix
  fallback; stored ordinal and binary failure diagnoses produce
  warnings. Numeric fits retain their existing final-engine warning
  behavior.

- Two-level ordinal components always warn about the positive bias of
  the range method, `beta-hat^2 / 2`, which does not subtract the AIAG
  correction `EV^2 / (n * r)`. Both print methods identify every derived
  component;
  [`msa_grr()`](https://danielmoj.github.io/llmsa/reference/msa_grr.md)
  retains the component names in `derived`. The `two_level` study and
  the validation vignette document the method and its limitations.

- The validation vignette adds live ordinal and binary comparisons,
  separates latent ICC from rptR’s default scale convention, and reads
  reproducible recovery-study results with MCSE. Offline anchor copies
  carry SHA-256 provenance. Three simulation scripts retain fit failures
  and seeds, support separate scenario runs, and ship short
  reproducibility runs; full simulation findings require the operator’s
  later runs.

- Default numeric
  [`msa_fit()`](https://danielmoj.github.io/llmsa/reference/msa_fit.md)
  preserves numeric input precision and completes REML using
  balanced-design formulas or an analytic constrained solution. The
  returned lme4 model stays on the original scale; `numerics` reports
  the method and diagnostics. Explicit fitting arguments retain the
  direct lme4 path, and bootstrap refits use ordinary lme4 optimization.

- Numeric fits diagnose constant or non-finite responses, missing
  grouping values, degenerate residual variance and original-scale
  precision loss. The default path checks the residual model space
  before starting lme4, including unbalanced multi-factor studies with
  missing responses or cells. Failed initialization now gives a named
  error with the engine’s cause and preserves start warnings, including
  for small positive residual variance. Arithmetic warnings and errors
  while constructing the original-scale model become named precision
  errors; final convergence warnings remain active. Numeric `NaN` and
  the string `"NaN"` are treated as missing responses. Explicit
  `subset`, `weights` and `offset` expressions use the fitting data;
  counts and row mappings describe the observations actually analysed.
  Stored fitting controls remain usable outside the original caller’s
  scope. A failed fit stops
  [`msa_plan()`](https://danielmoj.github.io/llmsa/reference/msa_plan.md)
  with its diagnostic.

- [`msa_grr()`](https://danielmoj.github.io/llmsa/reference/msa_grr.md)
  applies the minimum ndc convention and reports undefined ratios as
  `NA` when total variance is zero, with verdict `undetermined`. Custom
  thresholds must be finite, numeric, nonnegative and nondecreasing.

- The numeric validation vignette computes literature, NIST and
  package-oracle comparisons offline. Public builds include verified
  free NIST inputs and complete anchor copies; protected AIAG data
  remain local and their public comparison is marked as not rerun.

- [`backend_openai_compatible()`](https://danielmoj.github.io/llmsa/reference/backends.md)
  now omits `temperature` from the request when `temperature = NULL`. It
  supports a per-row system message and records response IDs, model
  snapshots, usage, fingerprints and requested/reported provider
  routing.

- [`backend_openai_compatible()`](https://danielmoj.github.io/llmsa/reference/backends.md)
  records a non-empty `message.reasoning` of the reply as
  `meta$reasoning` (Qwen3-32B via OpenRouter returns its reasoning
  there). `reasoning_details` is not stored, and only `message.content`
  is parsed.

- [`backend_openai_compatible()`](https://danielmoj.github.io/llmsa/reference/backends.md)
  records `finish_reason` and `native_finish_reason` of the first choice
  as `meta$finish_reason` and `meta$native_finish_reason` when they are
  non-empty strings, and the request timeout as `meta$timeout_s`. The
  default `timeout = 120` is unchanged.

- `parse_choice(whole_word = TRUE)` matches whole phrases, preferring
  longer phrases and rejecting ambiguous classifications. The default
  remains unchanged.

- `msa_run(parse_by_prompt = ...)` can select a parser for each prompt
  while retaining the raw response and the existing resumable store
  format. Numeric JSON metadata are now stored without rounding; small
  recorded API costs previously could be rounded to zero.

- `msa_report(assessment = ...)` accepts validated application criteria,
  an overall decision and additional report sections, including a
  robustness half-normal plot.

- The internal AP1 pipeline adds frozen study inputs, a YAML plan, an
  explicit mock/API runner, pilot checks and per-model assessment. Its
  functions are not exported. AP1 results are provisional until the M1
  statistical validation.

- The AP1 plan requires a client timeout per model (`timeout_s`, 1800 s
  for all three models), which the runner passes to
  [`backend_openai_compatible()`](https://danielmoj.github.io/llmsa/reference/backends.md).
  The AP1 pilot has a fifth pass rule, `backend_errors`: a backend error
  share of at most `error_share_trigger` per model, unreadable answers
  not counted. The pilot summary reports the maximum latency.

- The internal AP1 runner repeats a call that failed before its request
  was sent (name resolution, connection, TLS handshake, or a timeout in
  these phases) after pauses of 30 s, doubling up to 600 s and at most
  12 h per call (plan field `network`), instead of storing it as a
  backend error; then it stops without a row for that call. Such calls
  record `network_retries` and `network_wait_s`. The runner logs its
  progress with timestamps to stderr.

## llmsa 0.1.0

First public release.

- Crossed study design
  ([`msa_design()`](https://danielmoj.github.io/llmsa/reference/msa_design.md)),
  execution with an audit trail and resumable store
  ([`msa_run()`](https://danielmoj.github.io/llmsa/reference/msa_run.md)),
  import of external results
  ([`as_msa_runs()`](https://danielmoj.github.io/llmsa/reference/as_msa_runs.md)).
- Backends:
  [`backend_mock()`](https://danielmoj.github.io/llmsa/reference/backends.md),
  [`backend_ellmer()`](https://danielmoj.github.io/llmsa/reference/backends.md),
  [`backend_openai_compatible()`](https://danielmoj.github.io/llmsa/reference/backends.md);
  parsers for numbers, labels and JSON fields.
- Variance components for numeric, ordinal and binary outcomes
  ([`msa_fit()`](https://danielmoj.github.io/llmsa/reference/msa_fit.md)),
  gauge R&R statistics with AIAG classification
  ([`msa_grr()`](https://danielmoj.github.io/llmsa/reference/msa_grr.md)),
  parametric bootstrap intervals
  ([`msa_boot()`](https://danielmoj.github.io/llmsa/reference/msa_boot.md)).
- Attribute agreement with Krippendorff’s alpha and Cohen’s kappa
  ([`msa_agreement()`](https://danielmoj.github.io/llmsa/reference/msa_agreement.md)),
  bias and linearity
  ([`msa_bias()`](https://danielmoj.github.io/llmsa/reference/msa_bias.md)).
- Plackett-Burman robustness screening with Lenth’s method
  ([`pb_design()`](https://danielmoj.github.io/llmsa/reference/pb_design.md),
  [`msa_robustness()`](https://danielmoj.github.io/llmsa/reference/msa_robustness.md)).
- Simulation-based study planning
  ([`msa_simulate()`](https://danielmoj.github.io/llmsa/reference/msa_simulate.md),
  [`msa_plan()`](https://danielmoj.github.io/llmsa/reference/msa_plan.md)).
- Westgard-rule control charts for system suitability
  ([`msa_control_chart()`](https://danielmoj.github.io/llmsa/reference/msa_control_chart.md)).
- Validation report template
  ([`msa_report()`](https://danielmoj.github.io/llmsa/reference/msa_report.md)).
- Simulated demonstration data `acmg_demo` and `ic50_demo`.

Known limitations: no bootstrap for ordinal fits; batched multi-item
prompts (position and carry-over effects) and free-text outcomes judged
by a second model are planned for a later release.
