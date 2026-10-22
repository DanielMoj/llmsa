# Changelog

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
