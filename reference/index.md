# Package index

## Plan and run a study

- [`msa_design()`](https://danielmoj.github.io/llmsa/reference/msa_design.md)
  : Plan a crossed precision study for an LLM pipeline
- [`msa_run()`](https://danielmoj.github.io/llmsa/reference/msa_run.md)
  : Execute a design against a backend and keep an audit trail
- [`as_msa_runs()`](https://danielmoj.github.io/llmsa/reference/as_msa_runs.md)
  : Import results produced elsewhere
- [`msa_counts()`](https://danielmoj.github.io/llmsa/reference/msa_counts.md)
  : Realised cell counts of a study
- [`backend_mock()`](https://danielmoj.github.io/llmsa/reference/backends.md)
  [`backend_ellmer()`](https://danielmoj.github.io/llmsa/reference/backends.md)
  [`backend_openai_compatible()`](https://danielmoj.github.io/llmsa/reference/backends.md)
  : Backends: how a prompt becomes a response
- [`parse_identity()`](https://danielmoj.github.io/llmsa/reference/parsers.md)
  [`parse_number()`](https://danielmoj.github.io/llmsa/reference/parsers.md)
  [`parse_choice()`](https://danielmoj.github.io/llmsa/reference/parsers.md)
  [`parse_json_field()`](https://danielmoj.github.io/llmsa/reference/parsers.md)
  : Parsers for model responses

## Precision and accuracy

- [`msa_fit()`](https://danielmoj.github.io/llmsa/reference/msa_fit.md)
  : Estimate the variance components of an LLM measurement system
- [`msa_grr()`](https://danielmoj.github.io/llmsa/reference/msa_grr.md)
  : Gauge repeatability and reproducibility of an LLM pipeline
- [`msa_boot()`](https://danielmoj.github.io/llmsa/reference/msa_boot.md)
  : Bootstrap intervals for gauge R&R statistics
- [`msa_agreement()`](https://danielmoj.github.io/llmsa/reference/msa_agreement.md)
  : Attribute agreement of a categorical LLM pipeline
- [`msa_bias()`](https://danielmoj.github.io/llmsa/reference/msa_bias.md)
  : Bias and linearity of a numeric LLM pipeline against a reference

## Robustness, planning, control

- [`pb_design()`](https://danielmoj.github.io/llmsa/reference/pb_design.md)
  : Plackett-Burman screening design for robustness testing
- [`msa_robustness()`](https://danielmoj.github.io/llmsa/reference/msa_robustness.md)
  : Analyse a robustness screening experiment
- [`msa_simulate()`](https://danielmoj.github.io/llmsa/reference/msa_simulate.md)
  : Simulate a study with known variance components
- [`msa_plan()`](https://danielmoj.github.io/llmsa/reference/msa_plan.md)
  : Plan the size of a precision study by simulation
- [`msa_control_chart()`](https://danielmoj.github.io/llmsa/reference/msa_control_chart.md)
  : Control chart with Westgard rules for ongoing system suitability

## Report and data

- [`msa_report()`](https://danielmoj.github.io/llmsa/reference/msa_report.md)
  : Render a validation report
- [`acmg_demo`](https://danielmoj.github.io/llmsa/reference/acmg_demo.md)
  : Simulated ACMG/AMP variant classifications by an LLM pipeline
- [`ic50_demo`](https://danielmoj.github.io/llmsa/reference/ic50_demo.md)
  : Simulated numeric extraction (log10 IC50) by an LLM pipeline
- [`llmsa`](https://danielmoj.github.io/llmsa/reference/llmsa-package.md)
  [`llmsa-package`](https://danielmoj.github.io/llmsa/reference/llmsa-package.md)
  : llmsa: Measurement System Analysis for Pipelines Built on Large
  Language Models
