# llmsa (development version)

* Ordinal and binary fits validate exact binary codes, explicit event labels,
  missing grouping values and constant categories. Dropped responses are
  counted in warnings and in the returned study size.
* `msa_fit()` now reports final-engine `converged` independently of `singular`.
  The actual clmm optimizer determines success, including its matrix fallback;
  stored ordinal and binary failure diagnoses produce warnings. Numeric fits
  retain their existing final-engine warning behavior.
* Two-level ordinal components always warn about the positive bias of the
  range method, `beta-hat^2 / 2`, which does not subtract the AIAG correction
  `EV^2 / (n * r)`. Both print methods identify every derived component;
  `msa_grr()` retains the component names in `derived`. The `two_level` study
  and the validation vignette document the method and its limitations.
* The validation vignette adds live ordinal and binary comparisons, separates
  latent ICC from rptR's default scale convention, and reads reproducible
  recovery-study results with MCSE. Offline anchor copies carry SHA-256
  provenance. Three simulation scripts retain fit failures and seeds, support
  separate scenario runs, and ship short reproducibility runs; full simulation
  findings require the operator's later runs.

* Default numeric `msa_fit()` preserves numeric input precision and completes
  REML using balanced-design formulas or an analytic constrained solution.
  The returned lme4 model stays on the original scale; `numerics` reports the
  method and diagnostics. Explicit fitting arguments retain the direct lme4
  path, and bootstrap refits use ordinary lme4 optimization.
* Numeric fits diagnose constant or non-finite responses, missing grouping
  values, degenerate residual variance and original-scale precision loss.
  The default path checks the residual model space before starting lme4,
  including unbalanced multi-factor studies with missing responses or cells.
  Failed initialization now gives a named error with the engine's cause and
  preserves start warnings, including for small positive residual variance.
  Arithmetic warnings and errors while constructing the original-scale model
  become named precision errors; final convergence warnings remain active.
  Numeric `NaN` and the string `"NaN"` are treated as missing responses.
  Explicit `subset`, `weights` and `offset` expressions use the fitting data;
  counts and row mappings describe the observations actually analysed.
  Stored fitting controls remain usable outside the original caller's scope.
  A failed fit stops `msa_plan()` with its diagnostic.
* `msa_grr()` applies the minimum ndc convention and reports undefined ratios
  as `NA` when total variance is zero, with verdict `undetermined`.
  Custom thresholds must be finite, numeric, nonnegative and nondecreasing.
* The numeric validation vignette computes literature, NIST and package-oracle
  comparisons offline. Public builds include verified free NIST inputs and
  complete anchor copies; protected AIAG data remain local and their public
  comparison is marked as not rerun.

* `backend_openai_compatible()` now omits `temperature` from the request when
  `temperature = NULL`. It supports a per-row system message and records response
  IDs, model snapshots, usage, fingerprints and requested/reported provider routing.
* `backend_openai_compatible()` records a non-empty `message.reasoning` of the
  reply as `meta$reasoning` (Qwen3-32B via OpenRouter returns its reasoning
  there). `reasoning_details` is not stored, and only `message.content` is parsed.
* `backend_openai_compatible()` records `finish_reason` and `native_finish_reason`
  of the first choice as `meta$finish_reason` and `meta$native_finish_reason` when
  they are non-empty strings, and the request timeout as `meta$timeout_s`. The
  default `timeout = 120` is unchanged.
* `parse_choice(whole_word = TRUE)` matches whole phrases, preferring longer
  phrases and rejecting ambiguous classifications. The default remains unchanged.
* `msa_run(parse_by_prompt = ...)` can select a parser for each prompt while
  retaining the raw response and the existing resumable store format.
  Numeric JSON metadata are now stored without rounding; small recorded API
  costs previously could be rounded to zero.
* `msa_report(assessment = ...)` accepts validated application criteria, an overall
  decision and additional report sections, including a robustness half-normal plot.
* The internal AP1 pipeline adds frozen study inputs, a YAML plan, an explicit
  mock/API runner, pilot checks and per-model assessment. Its functions are not
  exported. AP1 results are provisional until the M1 statistical validation.
* The AP1 plan requires a client timeout per model (`timeout_s`, 1800 s for all
  three models), which the runner passes to `backend_openai_compatible()`. The
  AP1 pilot has a fifth pass rule, `backend_errors`: a backend error share of at
  most `error_share_trigger` per model, unreadable answers not counted. The pilot
  summary reports the maximum latency.
* The internal AP1 runner repeats a call that failed before its request was sent
  (name resolution, connection, TLS handshake, or a timeout in these phases)
  after pauses of 30 s, doubling up to 600 s and at most 12 h per call (plan
  field `network`), instead of storing it as a backend error; then it stops
  without a row for that call. Such calls record `network_retries` and
  `network_wait_s`. The runner logs its progress with timestamps to stderr.

# llmsa 0.1.0

First public release.

* Crossed study design (`msa_design()`), execution with an audit trail and
  resumable store (`msa_run()`), import of external results
  (`as_msa_runs()`).
* Backends: `backend_mock()`, `backend_ellmer()`,
  `backend_openai_compatible()`; parsers for numbers, labels and JSON
  fields.
* Variance components for numeric, ordinal and binary outcomes
  (`msa_fit()`), gauge R&R statistics with AIAG classification
  (`msa_grr()`), parametric bootstrap intervals (`msa_boot()`).
* Attribute agreement with Krippendorff's alpha and Cohen's kappa
  (`msa_agreement()`), bias and linearity (`msa_bias()`).
* Plackett-Burman robustness screening with Lenth's method
  (`pb_design()`, `msa_robustness()`).
* Simulation-based study planning (`msa_simulate()`, `msa_plan()`).
* Westgard-rule control charts for system suitability
  (`msa_control_chart()`).
* Validation report template (`msa_report()`).
* Simulated demonstration data `acmg_demo` and `ic50_demo`.

Known limitations: no bootstrap for ordinal fits; batched multi-item
prompts (position and carry-over effects) and free-text outcomes judged by
a second model are planned for a later release.
