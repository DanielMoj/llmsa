# llmsa (development version)

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
