# llmsa: Measurement System Analysis for Pipelines Built on Large Language Models

<!-- badges: start -->
[![R-CMD-check](https://github.com/DanielMoj/llmsa/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/DanielMoj/llmsa/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.md)
<!-- badges: end -->

**Kurzfassung.** `llmsa` behandelt eine Auswertungspipeline, die auf einem
Sprachmodell aufsetzt, als das, was sie ist: ein Messverfahren mit
unbekannter Messunsicherheit. Das Paket validiert sie mit den Methoden, die
analytische und klinische Labore seit Jahrzehnten verwenden: gekreuzte
Präzisionsstudie mit Varianzkomponenten (Gage R&R), Attribut-Übereinstimmung
mit Kappa-Statistiken, Richtigkeit gegen eine Referenz,
Plackett-Burman-Screening der Robustheit, Fallzahlplanung per Simulation,
Regelkarten mit Westgard-Regeln für die laufende Systemeignung und ein
prüffähiger Validierungsbericht. Es ist unabhängig vom verwendeten Modell
und von der Pipeline selbst.

## Why

Benchmarks report how often a model is right. A laboratory needs to know
something else before it acts on a result: how much the result changes
when the same question is asked again (repeatability), when it is asked
differently or of another model (reproducibility), whether it is
systematically off (bias), whether a typo or a different number format
changes it (robustness), and whether it is still behaving the same way
next month (system suitability). None of this is new. Measurement system
analysis (AIAG MSA), CLSI EP05, ICH Q2(R2) and Westgard rules answer
exactly these questions for instruments. `llmsa` applies them to pipelines
built on large language models, whose endpoints are not deterministic even
at temperature 0 and whose models change silently.

The result is a validation report in the structure a reviewer or an
auditor expects, which is also what the FDA's 2025 draft guidance on AI
in regulatory decision-making asks for: a credibility assessment tied to
a stated context of use and model risk.

## What maps to what

| Measurement system analysis | LLM pipeline |
|---|---|
| Part | Item (variant, document, assay record) |
| Appraiser | Prompt variant (semantically equivalent wording) |
| Instrument | Model (provider, version, quantisation) |
| Trial / replicate | Repeated call under identical conditions |
| Day / session | Block (endpoints drift with load and time) |
| Repeatability | Variance between replicate calls |
| Reproducibility | Variance from prompt, model, block and their interactions |
| Part-to-part variation | Variance between items, the signal to resolve |
| Reference standard | Expert-curated answer |
| Robustness (ICH Q2) | Plackett-Burman screening of formatting and context perturbations |
| Control sample | Small set with known answers, run before each batch |

## Installation

```r
# install.packages("remotes")
remotes::install_github("DanielMoj/llmsa", build_vignettes = TRUE)
```

Dependencies are `lme4` and `ordinal`. Reports need `rmarkdown` and
pandoc; backends need `httr2` or `ellmer`.

## Quick start

```r
library(llmsa)

# 1. items (parts), prompt variants (appraisers), models (instruments)
items <- data.frame(item_id = c("v1", "v2", "v3"),
                    text = c("NM_000059.4:c.1813dupA", "NM_000059.4:c.7397T>C", "NM_000059.4:c.68-7T>A"),
                    reference = c("Pathogenic", "Benign", "VUS"))
tiers <- c("Benign", "Likely benign", "VUS", "Likely pathogenic", "Pathogenic")
prompts <- c(concise = "Classify {text} (ACMG/AMP five tiers). Answer with the tier only.",
             role    = "You are a clinical geneticist. Give the ACMG/AMP tier of {text}.")
design <- msa_design(items, prompts, models = c("gpt-4.1", "qwen3:8b"), reps = 3, blocks = 2, seed = 1)

# 2. run against any backend, with an audit trail
backend <- backend_openai_compatible("http://localhost:11434/v1", api_key = "")   # Ollama
runs <- msa_run(design, backend, parse = parse_choice(tiers), store = "runs.sqlite")

# 3. precision, agreement, robustness, report
fit <- msa_fit(runs, type = "ordinal", levels = tiers)
grr <- msa_grr(fit)                      # %GRR, ndc, verdict
ag  <- msa_agreement(runs, levels = tiers, reference = "reference", weights = "linear")
msa_report(grr, runs = runs, agreement = ag,
           cou = "Pre-classification of sequence variants for expert review",
           risk = "medium", acceptance = "%GRR < 30 %; kappa (modal) >= 0.8",
           output_file = "validation_report.html")
```

Results produced by another pipeline (Python, a workflow engine, a
spreadsheet) are analysed the same way after `as_msa_runs()`.

```r
g <- msa_grr(msa_fit(ic50_demo, type = "numeric"))
g
#> Gauge R&R of an LLM measurement system
#>   outcome: numeric; 40 items x 3 prompts x 3 models x 2 block(s), 2152 observations
#>  Source               Variance SD     % Contribution % Study Var
#>  Total gauge R&R      0.0425   0.2061 4.2 %          20.5 %
#>    Repeatability      0.0140   0.1184 1.4 %          11.8 %
#>    Reproducibility    0.0285   0.1687 2.8 %          16.8 %
#>      prompt           0.0049   0.0697 0.5 %          6.9 %
#>      model            0.0171   0.1309 1.7 %          13.0 %
#>      block (time)     0.0010   0.0319 0.1 %          3.2 %
#>      prompt:model     0.0000   0.0046 0.0 %          0.5 %
#>      item:prompt      0.0001   0.0092 0.0 %          0.9 %
#>      item:model       0.0054   0.0731 0.5 %          7.3 %
#>  Part-to-part (items) 0.9672   0.9834 95.8 %         97.9 %
#>  Total variation      1.0096   1.0048 100.0 %        100.0 %
#>
#>   total gauge R&R: 20.5 % of study variation (4.2 % contribution)
#>   number of distinct categories (ndc): 6
#>   ICC (items): 0.958
#>   verdict: MARGINAL  [basis: % study variation, thresholds 10 / 30]
```

## Functions

| Step | Function |
|---|---|
| Plan a crossed study | `msa_design()` |
| Run it with an audit trail, resume after interruption | `msa_run()`, `backend_mock()`, `backend_ellmer()`, `backend_openai_compatible()`, `parse_number()`, `parse_choice()`, `parse_json_field()` |
| Import results from elsewhere | `as_msa_runs()`, `msa_counts()` |
| Variance components, numeric / ordinal / binary | `msa_fit()` |
| Gauge R&R statistics and verdict | `msa_grr()`, `msa_boot()` |
| Attribute agreement, accuracy | `msa_agreement()` (Krippendorff's alpha, Cohen's kappa) |
| Bias and linearity | `msa_bias()` |
| Robustness screening | `pb_design()`, `msa_robustness()` (Lenth's PSE) |
| Study size by simulation | `msa_simulate()`, `msa_plan()` |
| Ongoing system suitability | `msa_control_chart()` (Westgard rules) |
| Validation report | `msa_report()` |

The vignette (`vignette("llmsa")`) runs a complete validation offline
with the mock backend.

## Design notes

* **Replicates must be spread in time.** Thinking Machines Lab showed in
  2025 that identical prompts at temperature 0 return different
  completions because batch composition on the server changes the
  arithmetic. Five calls within one second underestimate repeatability;
  use `blocks` and run them on different days.
* **Few levels, wide intervals.** Three models and four prompt variants are
  three and four levels of a random effect. Their variance components are
  estimated with large uncertainty and fits are often singular. Report
  bootstrap intervals (`msa_boot()`) and plan the study (`msa_plan()`);
  the number of prompt variants, not the number of items, drives the
  precision of the reproducibility estimate.
* **Memorisation confounds accuracy, not precision.** Reference answers
  that are public (ClinVar, textbooks) may be in the training data. Use
  items added after the model's cut-off for the accuracy question; the
  precision statistics are unaffected.
* **Acceptance criteria follow model risk.** The AIAG thresholds (10 % and
  30 % of study variation) are defaults, not laws. Set them from the
  consequence of a wrong decision in the stated context of use.
* **Free-text outcomes** judged by a second model are a second measurement
  system that needs its own validation (a nested MSA). This release covers
  numeric, ordinal and binary outcomes.

## Roadmap

* Batched multi-item prompts: position and carry-over effects analysed as
  in a crossover study (Williams designs).
* Nested validation of LLM-as-judge scoring for free-text outcomes.
* Bootstrap intervals for ordinal fits; modified-large-sample intervals for
  variance components.
* Detection-limit style experiments: how much evidence must a document
  contain before a finding is extracted reliably.

## Citation

```
Moj, D. A. (2026). llmsa: Measurement System Analysis for Pipelines Built on
Large Language Models. R package version 0.1.0.
https://github.com/DanielMoj/llmsa
```

A `CITATION.cff` is included; a Zenodo DOI will be added with the first
release.

## References

* AIAG (2010). *Measurement Systems Analysis*, 4th ed. Automotive Industry
  Action Group.
* Burdick, R. K., Borror, C. M., Montgomery, D. C. (2003). A review of
  methods for measurement systems capability analysis. *Journal of Quality
  Technology* 35, 342-354.
* CLSI (2014). *EP05-A3: Evaluation of Precision of Quantitative Measurement
  Procedures*.
* ICH (2023). *Q2(R2): Validation of Analytical Procedures*.
* Krippendorff, K. (2011). *Computing Krippendorff's Alpha-Reliability*.
  University of Pennsylvania.
* Lenth, R. V. (1989). Quick and easy analysis of unreplicated factorials.
  *Technometrics* 31, 469-473.
* Plackett, R. L., Burman, J. P. (1946). The design of optimum
  multifactorial experiments. *Biometrika* 33, 305-325.
* Westgard, J. O., Barry, P. L., Hunt, M. R., Groth, T. (1981). A
  multi-rule Shewhart chart for quality control in clinical chemistry.
  *Clinical Chemistry* 27, 493-501.
* U.S. Food and Drug Administration (2025). *Considerations for the Use of
  Artificial Intelligence to Support Regulatory Decision-Making for Drug and
  Biological Products*. Draft guidance.
* He, H., Thinking Machines Lab (2025). *Defeating Nondeterminism in LLM
  Inference*.

## License

MIT, see `LICENSE.md`.
