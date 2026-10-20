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
