# llmsa: Measurement System Analysis for Pipelines Built on Large Language Models

`llmsa` treats a pipeline built on a large language model (LLM) as what
it is: a measurement procedure with unknown measurement uncertainty. It
validates the pipeline with the methods that analytical and clinical
laboratories have used for decades: a crossed precision study with
variance components (gauge R&R), attribute agreement, bias against a
reference, Plackett-Burman screening of robustness, simulation-based
planning of the study size, Westgard-rule control charts for ongoing
system suitability, and a validation report in the structure a reviewer
or an auditor expects. It produces the evidence that a quality unit, an
inspector, a notified body or a model-risk function asks for before the
output of an LLM step may count.

The object of the validation is always a concrete pipeline (model,
prompt, settings) for a stated task and risk, never “the LLM” in
general. Any pipeline qualifies whose output is a number, an ordered
class or a yes/no answer; results produced outside R can be imported.

## Why

Benchmarks report how often a model is right. A laboratory needs to know
something else before it acts on a result: how much the result changes
when the same question is asked again (repeatability), when it is asked
in other words or of another model (reproducibility), whether it is
systematically off (bias), whether a typo or a different number format
changes it (robustness), and whether it still behaves the same way next
month (system suitability). None of this is new. Measurement system
analysis (AIAG MSA), CLSI EP05 for quantitative and CLSI EP12 for binary
qualitative results, ICH Q2(R2) and the Westgard rules answer exactly
these questions for instruments and laboratory tests. `llmsa` applies
them to pipelines built on LLMs, whose answers vary even at temperature
0 and whose models can change without notice.

The validation report ties the evidence to a stated context of use, a
model risk and acceptance criteria fixed in advance. This is the
structure of the credibility assessment in the FDA’s 2025 draft guidance
on AI in regulatory decision-making.

## Who needs this

Classic computer system validation assumes that the same input gives the
same output. A step built on a language model breaks that assumption.
Its answer can change with the wording of the prompt, with the day, and
with model updates the provider makes without notice, so a single test
run proves little. Wherever such a step sorts, extracts or calculates
inside a regulated process, the organisation running it is expected to
show three things: what the step gets wrong, how often, and whether that
still holds after the next update. A benchmark score or a vendor
certificate describes a model on someone else’s data, not this pipeline
on this task.

`llmsa` produces that evidence. Laboratories, quality units and notified
bodies know its methods from instruments. Insurers and banks ask the
same questions in the terms of model risk management: stability on
re-run, sensitivity analysis, ongoing monitoring, revalidation after a
change.

The following constructed examples show the kind of error a study is
designed to catch:

- *“Admitted to hospital for syncope, discharged after two days, fully
  recovered.”* The pipeline reads “fully recovered” and classifies the
  adverse event report as non-serious. The hospital admission makes it
  serious, and the 15-day reporting clock is running.
- *“The meter showed 95 mg/dl, shortly afterwards my mother was
  unconscious; the paramedics measured 32 mg/dl.”* The complaint is
  filed as a usage question instead of a reportable incident.
- *“eGFR 28 in March, now 41”*, against an exclusion criterion of eGFR
  below 30. The pipeline takes the old value and excludes the patient
  from a trial, and nobody sees a false exclusion again.
- An article reports a clearance of 4.2 mL/min/kg. The extraction
  returns 4.2 L/h, and the value enters a pharmacokinetic model.

The examples are invented to show plausible failure modes, not
documented incidents.

### Where it applies

| Field | Pipeline output | Why evidence is required | Key figure |
|----|----|----|----|
| Clinical genetics, laboratory diagnostics | ACMG/AMP tier of a variant, pre-classified for expert review | The tier enters a clinical report under ISO 15189 accreditation; CLSI EP12 covers binary qualitative results. | Agreement with expert classifications; precision across prompts, models and days |
| Pharmacovigilance | Seriousness of an adverse event report; adverse reaction mentioned in a publication | GVP Module VI: serious reports within 15 days, non-serious within 90; literature screened at least weekly | Missed serious cases, missed reports |
| Clinical trials | Eligibility in pre-screening | ICH E6(R3): computerised systems fit for purpose through risk-based validation; the sponsor keeps the ultimate responsibility when a service provider runs them | False exclusions |
| Model-informed drug development | PK parameters extracted from publications | ICH M15: model evaluation commensurate with model risk; extracted values become model inputs. | %GRR, bias and linearity; unit errors |
| Medical devices | Reportability of a complaint; results of calculation functions in medical software | MDR Annex I 17: repeatability and reliability of software; MDR Art. 87 reporting deadlines; ISO 13485 §4.1.6: validation of QMS software before use and after changes | Missed incidents with injury or death; results outside tolerance |
| Insurance | Status of each diagnosis in medical reports for underwriting | AI Act Annex III 5(c), high-risk from 2 December 2027; Art. 15: accuracy and robustness maintained over the lifecycle | Both error directions; underwriters and model in the same gauge study |
| Banking | Disposable income from bank statements; risk class and costs from product documents | AI Act Annex III 5(b), high-risk from 2 December 2027; MiFID II suitability; DORA third-party ICT risk | Deviation in euros; stability after each vendor model update |

Apart from the ACMG/AMP study under way, none of these applications has
been measured with llmsa yet. Several of them need two measures that are
still on the roadmap: a sensitivity per class with a lower confidence
bound for the critical error direction, and the comparison of model
versions.

### What a validation with llmsa produces

1.  The intended use, the worst plausible error and the regulatory
    context, written down first.
2.  Reference, statistics and acceptance criteria, fixed before the
    first call.
3.  A measurement on the actual pipeline, in its own environment or API
    account.
4.  A report in the structure of a credibility assessment, including
    what was not tested.
5.  A control set and Westgard rules for every later change of model or
    prompt.

## When to use it

- **Before deployment.** A crossed study (items × prompt variants ×
  models × replicates × blocks) shows where the variation comes from and
  whether the pipeline separates the items it has to separate.
- **After a change.** A new model version, a reworded prompt, another
  provider or quantisation: repeat the study with the changed component
  and compare the result with the validated state.
- **In routine use.** A small control set with known answers runs before
  each batch, and
  [`msa_control_chart()`](https://danielmoj.github.io/llmsa/reference/msa_control_chart.md)
  applies the Westgard rules to catch drift, for example after a silent
  model update.

## What maps to what

| Measurement system analysis | LLM pipeline |
|----|----|
| Measurand | What the pipeline reports: a number (IC50), an ordered class (ACMG/AMP tier), a yes/no finding |
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

## How llmsa itself is validated

A statistics package for validation has to be validated itself. In
`llmsa`, a passing test is not enough for a statistic to count as
verified. Each one needs two independent pieces of evidence: a published
value, a recalculation by a different route, or a live comparison with
an established package. Where no closed-form answer exists, a simulation
study decides; it is planned with the ADEMP scheme (Morris, White and
Crowther, 2019) and reported with Monte Carlo standard errors (MCSE).
Reference values are stored in `reference/anchors/` with source, page,
value and tolerance and are never estimated. Edge cases and invariances
are tested explicitly.

| Component | Status | Evidence |
|----|----|----|
| Variance components, %GRR, % contribution, ndc and verdict (numeric) | verified | equal to the ANOVA estimators on balanced designs; AIAG worked example; published REML estimates for lme4’s `Penicillin` data; NIST StRD ANOVA datasets with certified values; live comparison with VCA, SixSigma and lme4 |
| Ordinal and binary outcomes (latent scale) | verified | equal to direct fits with [`ordinal::clmm()`](https://rdrr.io/pkg/ordinal/man/clmm.html) and [`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html); latent ICC against rptR and performance; recovery of simulated components with MCSE |
| Bootstrap intervals ([`msa_boot()`](https://danielmoj.github.io/llmsa/reference/msa_boot.md)) | verified | quantiles equal to [`lme4::bootMer()`](https://rdrr.io/pkg/lme4/man/bootMer.html); coverage measured in seven scenarios with MCSE |
| Robustness screening (Plackett-Burman, Lenth) | implemented; validation in progress | planned: generator rows of Plackett and Burman (1946), comparison with FrF2, the worked examples of Lenth (1989), false-alarm rate at the nominal level |
| Agreement (Cohen, Krippendorff), bias and linearity | implemented; not yet validated | planned: published values for every weighting and scale level, established packages, AIAG examples, simulated coverage |
| Westgard rules, simulator, study planning | implemented; not yet validated | planned: each rule exactly at its limit, false-alarm rates against Westgard et al. (1981), recovery of simulated components |
| Execution, parsers, backends, report | implemented; not yet validated | planned: an interrupted and resumed run gives the same store, parsers on random input, recorded real API responses, every number in the report equal to the object value |

The test suite of the statistical core detects 92.8 % of 1,478
deliberately injected faults (mutation testing of `R/fit.R` and
`R/grr.R`, threshold 80 %).

The article
[`vignette("validation", package = "llmsa")`](https://danielmoj.github.io/llmsa/articles/validation.md)
reruns the reference comparisons when it is built and reads the
simulation results from the stored runs. It needs no network, and no
number in it is typed in by hand. The AIAG handbook data are protected
and not distributed: the public build marks those rows as *not rerun*,
and the complete comparison runs locally.

The simulation studies also produced findings that matter in practice.
For ordinal and binary outcomes, the latent prompt and model components
were underestimated in several scenarios. Percentile intervals for the
integer-valued ndc cover more often than their nominal level. The
validation article reports every scenario with its MCSE, and the help
pages of
[`msa_fit()`](https://danielmoj.github.io/llmsa/reference/msa_fit.md)
and
[`msa_boot()`](https://danielmoj.github.io/llmsa/reference/msa_boot.md)
name the affected scenarios.

## Installation

``` r

# install.packages("remotes")
remotes::install_github("DanielMoj/llmsa", dependencies = TRUE, build_vignettes = TRUE)
```

`llmsa` needs R 4.1 or later. The fitting engines are `lme4` (Bates et
al., 2015) and `ordinal` (Christensen, 2026). Optional packages add
features: `httr2` (API backend), `ellmer` (chat objects), `DBI` and
`RSQLite` (SQLite store), `jsonlite` (response metadata), `rmarkdown`
with pandoc (report). The validation article uses VCA, SixSigma, rptR
and performance as live comparisons, so building the vignettes needs
`dependencies = TRUE`. Continuous integration runs `R CMD check` on
Linux, macOS and Windows.

## Quick start

### Analyse a study

`ic50_demo` is a simulated numeric extraction with known variance
components: 40 compounds, 3 prompt variants, 3 models, 3 replicates in
each of 2 blocks.

``` r

library(llmsa)

fit <- msa_fit(ic50_demo, type = "numeric")
msa_grr(fit)
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
#>      item:model       0.0053   0.0731 0.5 %          7.3 %
#>  Part-to-part (items) 0.9672   0.9835 95.8 %         97.9 %
#>  Total variation      1.0097   1.0048 100.0 %        100.0 %
#>
#>   total gauge R&R: 20.5 % of study variation (4.2 % contribution)
#>   number of distinct categories (ndc): 6
#>   ICC (items): 0.958
#>   verdict: MARGINAL  [basis: % study variation, thresholds 10 / 30]
```

The measurement system takes up 20.5 % of the study variation, between
the AIAG thresholds of 10 % and 30 %, hence *marginal*. The model is the
largest single source of reproducibility variance, and the pipeline
still resolves six distinct categories of compounds.

### Plan and run a study

``` r

tiers <- c("Benign", "Likely benign", "VUS", "Likely pathogenic", "Pathogenic")

# items are the parts, prompt variants the appraisers, models the instruments
items <- data.frame(item_id = sprintf("v%02d", 1:30),
                    text    = sprintf("variant %02d", 1:30))
prompts <- c(concise = "Classify {text} into the five ACMG/AMP tiers. Answer with the tier only.",
             role    = "You are a clinical variant scientist. Give the ACMG/AMP tier of {text}.",
             terse   = "ACMG/AMP tier of {text}?")
design <- msa_design(items, prompts, models = c("model-a", "model-b", "model-c"),
                     reps = 3, blocks = 2, seed = 1)

# offline: a mock backend with known variance components
truth   <- setNames(seq(-2.5, 2.5, length.out = 30), items$item_id)
backend <- backend_mock(truth, levels = tiers, thresholds = c(-1.5, -0.5, 0.5, 1.5), seed = 2)
runs <- msa_run(design, backend, parse = parse_choice(tiers, whole_word = TRUE),
                store = "runs.sqlite")

fit <- msa_fit(runs, type = "ordinal", levels = tiers)  # warns: two blocks, see Design notes
grr <- msa_grr(fit)
ag  <- msa_agreement(runs, levels = tiers, weights = "linear")
msa_report(grr, runs = runs, agreement = ag,
           cou = "Pre-classification of sequence variants for expert review",
           risk = "medium", acceptance = "%GRR < 30 %; Krippendorff's alpha >= 0.8",
           output_file = "validation_report.html")
```

`parse_choice(whole_word = TRUE)` matches whole phrases, prefers “Likely
benign” over “Benign” and returns `NA` for an answer that names two
classes. It does not read negations (“not pathogenic” parses as
“Pathogenic”), so prompts should ask for the label alone. The store
keeps every call as it arrives; `resume = TRUE` continues an interrupted
study without repeating a call.

### Run against real models

[`backend_openai_compatible()`](https://danielmoj.github.io/llmsa/reference/backends.md)
talks to any server with the OpenAI chat-completions API. Behind a
router such as OpenRouter, the same model name can be served by
different providers and quantisations, which would change the instrument
between calls. Pin both and disallow fallbacks:

``` r

pinned <- function(endpoint, quantisation) {
  backend_openai_compatible("https://openrouter.ai/api/v1",
                            api_key = Sys.getenv("OPENROUTER_API_KEY"),
                            temperature = 0, seed = 20261024,
                            provider = list(order = list(endpoint),
                                            allow_fallbacks = FALSE,
                                            quantizations = list(quantisation)))
}
backends <- list(llama = pinned("coreweave/fp16", "fp16"),
                 qwen  = pinned("deepinfra/fp8", "fp8"),
                 sol   = backend_openai_compatible(temperature = NULL,  # model rejects temperature
                                                   reasoning_effort = "medium", seed = 20261024))
backend <- function(prompt, model, row) backends[[row$model_id]](prompt, model, row)

design <- msa_design(items, prompts,
                     models = c(llama = "meta-llama/llama-3.3-70b-instruct",
                                qwen  = "qwen/qwen3-32b", sol = "gpt-6.1-sol"),
                     reps = 3, blocks = 2, seed = 1)
msa_run(design, backend, parse = parse_choice(tiers, whole_word = TRUE),
        block = 1, store = "study.sqlite")                     # day 1
runs <- msa_run(design, backend, parse = parse_choice(tiers, whole_word = TRUE),
                store = "study.sqlite", resume = TRUE)         # day 2: runs block 2, returns all
```

Each call is stored with its timestamp, block and run position, the
model identifier, a hash of the rendered prompt, the raw response, the
parsed value, latency and any error. From the API response the store
keeps the response ID, the reported model snapshot, token usage, the
system fingerprint, the finish reason and, where the endpoint returns
them, the serving provider and the reasoning text; from the request, the
provider order, quantisations, the fallback setting, seed, temperature,
reasoning effort and timeout. Credentials and headers are never stored.
`msa_run(parse_by_prompt = ...)` sets a parser per prompt variant, for
example
[`parse_json_field()`](https://danielmoj.github.io/llmsa/reference/parsers.md)
for a prompt that asks for JSON.

### Results from another pipeline

Results from Python, a workflow engine or a spreadsheet are analysed the
same way once they have one row per call:

``` r

runs <- as_msa_runs(results, item = "doc_id", prompt = "prompt", model = "model",
                    rep = "replicate", value = "answer")
```

The ClinVar article takes this route, with ClinVar submitters as
appraisers.

## Functions

| Step | Functions |
|----|----|
| Plan a crossed study | [`msa_design()`](https://danielmoj.github.io/llmsa/reference/msa_design.md) |
| Plan the study size by simulation | [`msa_simulate()`](https://danielmoj.github.io/llmsa/reference/msa_simulate.md), [`msa_plan()`](https://danielmoj.github.io/llmsa/reference/msa_plan.md) |
| Run it with an audit trail, resume after interruption | [`msa_run()`](https://danielmoj.github.io/llmsa/reference/msa_run.md) |
| Backends | [`backend_openai_compatible()`](https://danielmoj.github.io/llmsa/reference/backends.md), [`backend_ellmer()`](https://danielmoj.github.io/llmsa/reference/backends.md), [`backend_mock()`](https://danielmoj.github.io/llmsa/reference/backends.md) |
| Parsers | [`parse_choice()`](https://danielmoj.github.io/llmsa/reference/parsers.md), [`parse_number()`](https://danielmoj.github.io/llmsa/reference/parsers.md), [`parse_json_field()`](https://danielmoj.github.io/llmsa/reference/parsers.md), [`parse_identity()`](https://danielmoj.github.io/llmsa/reference/parsers.md) |
| Import results from elsewhere | [`as_msa_runs()`](https://danielmoj.github.io/llmsa/reference/as_msa_runs.md) |
| Realised cell counts of a study | [`msa_counts()`](https://danielmoj.github.io/llmsa/reference/msa_counts.md) |
| Variance components, numeric / ordinal / binary | [`msa_fit()`](https://danielmoj.github.io/llmsa/reference/msa_fit.md) |
| Gauge R&R statistics, verdict, bootstrap intervals | [`msa_grr()`](https://danielmoj.github.io/llmsa/reference/msa_grr.md), [`msa_boot()`](https://danielmoj.github.io/llmsa/reference/msa_boot.md) |
| Attribute agreement and accuracy (Krippendorff, 2011; Cohen, 1960, 1968) | [`msa_agreement()`](https://danielmoj.github.io/llmsa/reference/msa_agreement.md) |
| Bias and linearity | [`msa_bias()`](https://danielmoj.github.io/llmsa/reference/msa_bias.md) |
| Robustness screening (Lenth’s method) | [`pb_design()`](https://danielmoj.github.io/llmsa/reference/pb_design.md), [`msa_robustness()`](https://danielmoj.github.io/llmsa/reference/msa_robustness.md) |
| Ongoing system suitability (Westgard rules) | [`msa_control_chart()`](https://danielmoj.github.io/llmsa/reference/msa_control_chart.md) |
| Validation report | [`msa_report()`](https://danielmoj.github.io/llmsa/reference/msa_report.md) |

## Articles

- [`vignette("llmsa")`](https://danielmoj.github.io/llmsa/articles/llmsa.md),
  *Validating an LLM pipeline as a measurement system*: a complete
  validation, offline with the mock backend.
- [`vignette("validation")`](https://danielmoj.github.io/llmsa/articles/validation.md),
  *Statistical validation of llmsa*: every comparison with published
  values, NIST certified values, package oracles and the simulation
  studies.
- [`vignette("llm-stability")`](https://danielmoj.github.io/llmsa/articles/llm-stability.md),
  *Answer stability at temperature zero*: 82,850 recorded calls of five
  models on eight tasks in ten runs, from the public llm-stability data
  of Atıl et al. (2025, Apache-2.0); attribute repeatability, hit rate
  and the share of missing answers per task and model.
- [`vignette("clinvar-raters")`](https://danielmoj.github.io/llmsa/articles/clinvar-raters.md),
  *ClinVar submitters as a rater study*: submitters as appraisers, with
  Krippendorff’s alpha and ordinal variance components for 1,383
  variants in four genes of hereditary recurrent fevers (MEFV, MVK,
  NLRP3, TNFRSF1A) and a genome-wide sample of 1,000 variants, from
  public-domain ClinVar data (Landrum et al., 2025).

None of the articles calls a model. The real-data subsets they read are
frozen under `inst/extdata/` with SHA-256 checksums and their
provenance; the scripts in `data-raw/` rebuild them from the original
sources. The simulated datasets `ic50_demo` and `acmg_demo` carry their
true variance components as an attribute.

## Design notes

- **Replicates must be spread in time.** Identical requests at
  temperature 0 can return different completions because the load on the
  server, and with it the batch size, changes the order of
  floating-point operations (He and Thinking Machines Lab, 2025). Five
  calls within one second underestimate repeatability; use `blocks` and
  run them on different days.
- **Pin the instrument.** Fix provider, quantisation and model snapshot,
  and record what the endpoint reports. A model name alone does not
  identify an instrument.
- **Few levels, wide intervals.** Three models and four prompt variants
  are three and four levels of a random effect. Their variance
  components are estimated with large uncertainty, fits are often
  singular, and for ordinal and binary outcomes the simulation studies
  found these components underestimated in several scenarios. Report
  bootstrap intervals
  ([`msa_boot()`](https://danielmoj.github.io/llmsa/reference/msa_boot.md))
  and plan the study
  ([`msa_plan()`](https://danielmoj.github.io/llmsa/reference/msa_plan.md));
  the number of prompt variants, not the number of items, drives the
  precision of the reproducibility estimate.
- **Two levels are not enough for a variance.** In an ordinal fit, a
  prompt, model or block factor with exactly two levels enters as a
  fixed effect, and its component is estimated by the range method
  `beta-hat^2 / 2`, which is biased upwards.
  [`msa_fit()`](https://danielmoj.github.io/llmsa/reference/msa_fit.md)
  warns and marks the component.
- **On the latent scale, repeatability is fixed, not measured.** For
  ordinal and binary outcomes the residual variance is set by the link
  (1 for probit, pi^2/3 for logit; Nakagawa, Johnson and Schielzeth,
  2017). The observed agreement between replicates comes from
  [`msa_agreement()`](https://danielmoj.github.io/llmsa/reference/msa_agreement.md).
- **Memorisation confounds accuracy, not precision.** Reference answers
  that are public (ClinVar, textbooks) may be in the training data. Use
  items added after the model’s knowledge cut-off for the accuracy
  question; the precision statistics are unaffected.
- **Acceptance criteria follow model risk.** The AIAG thresholds (10 %
  and 30 % of study variation) are defaults, not laws. Set them from the
  consequence of a wrong decision in the stated context of use.
- **Deterministic classifiers.** The same design applies to fine-tuned
  encoder models and other classifiers. Their repeated calls agree, so
  the replicate has to be a factor that really varies, such as hardware,
  numeric precision or inference runtime; with identical replicates a
  numeric
  [`msa_fit()`](https://danielmoj.github.io/llmsa/reference/msa_fit.md)
  stops with a named error. The variation then moves to input
  preprocessing and training seeds. The score (logit or probability) is
  analysed as a numeric outcome, and the decision threshold sets the
  critical error direction. In its July 2025 draft, EU GMP Annex 22
  covers only static models with deterministic output and keeps
  generative AI and LLMs out of critical GMP applications; the final
  text is still pending. A study of this kind documents how reproducible
  a model’s output actually is.
- **Free-text outcomes** judged by a second model are a second
  measurement system that needs its own validation (a nested MSA). This
  release covers numeric, ordinal and binary outcomes.

## Application study

The first application under way is the five-tier ACMG/AMP classification
of sequence variants (Richards et al., 2015) against expert
classifications: 100 variants, 3 prompt variants, 3 models via APIs (one
proprietary, two open-weight with pinned provider and quantisation), 3
replicates in each of 2 blocks, 5,400 calls in the main study, plus a
pilot and a robustness screen. The plan, the frozen item set and the
runner are in `inst/validation/ap1/`. The plan was approved before the
first call, and every later change is documented in a decision record.
Results will be reported when the analysis is complete.

## How llmsa is developed

Changes are built in milestones from written specifications. One model
implements, a second reviews and owns the acceptance tests and reference
values, a third writes adversarial end-to-end and fuzz tests, and only
deterministic gates (`R CMD check`, the test suites, mutation testing)
decide whether a milestone passes. The maintainer approves the
specifications and every decision record. Specifications and decision
records are in `docs/` (in German); `AGENTS.md`, `BACKLOG.md`,
`PROGRESS.md`, `orchestrator/` and the other process files are excluded
from the package build. The 22 exported functions of version 0.1.0 keep
their interfaces; a change requires a decision record and a deprecation
period.

## Roadmap

- Validation of the remaining components (agreement, bias and linearity,
  robustness, control charts, planning, execution and report) to the
  standard above.
- Comparison of model versions as fixed levels, for revalidation after a
  change.
- Measures for binary results after CLSI EP12: sensitivity and
  specificity, or positive and negative percent agreement, with
  confidence bounds for the critical error direction; the imprecision of
  a classifier score near its threshold, estimated as C5 and C95.
- Bootstrap intervals for ordinal fits; modified-large-sample intervals
  for variance components (Burdick, Borror and Montgomery, 2003).
- Batched multi-item prompts: position and carry-over effects analysed
  as in a crossover study (Williams designs).
- Nested validation of LLM-as-judge scoring for free-text outcomes.
- Detection-limit style experiments: how much evidence a document must
  contain before a finding is extracted reliably.
- First release with a Zenodo DOI, then CRAN.

## Citation

    Moj, D. A. (2026). llmsa: Measurement System Analysis for Pipelines Built on
    Large Language Models. R package version 0.1.0.
    https://github.com/DanielMoj/llmsa

`citation("llmsa")` returns the same entry; a `CITATION.cff` is
included. A Zenodo DOI will be added with the first release.

## References

- Atıl, B., Aykent, S., Chittams, A., et al. (2025). Non-determinism of
  “deterministic” LLM system settings in hosted environments. In
  *Proceedings of the 5th Workshop on Evaluation and Comparison of NLP
  Systems (Eval4NLP)*, 135–148. Association for Computational
  Linguistics. <https://doi.org/10.18653/v1/2025.eval4nlp-1.12>
- Automotive Industry Action Group (2010). *Measurement Systems Analysis
  (MSA): Reference Manual*, 4th ed. Southfield, MI: AIAG. ISBN
  978-1-60534-211-5.
- Bates, D., Mächler, M., Bolker, B., Walker, S. (2015). Fitting linear
  mixed-effects models using lme4. *Journal of Statistical Software*
  67(1), 1–48. <https://doi.org/10.18637/jss.v067.i01>
- Burdick, R. K., Borror, C. M., Montgomery, D. C. (2003). A review of
  methods for measurement systems capability analysis. *Journal of
  Quality Technology* 35(4), 342–354.
  <https://doi.org/10.1080/00224065.2003.11980232>
- Christensen, R. H. B. (2026). *ordinal: Regression Models for Ordinal
  Data*. R package version 2026.7-26.
  <https://doi.org/10.32614/CRAN.package.ordinal>
- Clinical and Laboratory Standards Institute (2025). *CLSI EP05:
  Evaluation of Precision of Quantitative Measurement Procedures*, 4th
  ed. ISBN 978-1-68440-304-2 (PDF). Supersedes EP05-A3 (2014).
- Clinical and Laboratory Standards Institute (2023). *CLSI EP12:
  Evaluation of Qualitative, Binary Output Examination Performance*, 3rd
  ed. ISBN 978-1-68440-177-2 (PDF). Supersedes EP12-A2 (2008).
  <https://clsi.org/shop/standards/ep12/>
- Cohen, J. (1960). A coefficient of agreement for nominal scales.
  *Educational and Psychological Measurement* 20(1), 37–46.
  <https://doi.org/10.1177/001316446002000104>
- Cohen, J. (1968). Weighted kappa: nominal scale agreement with
  provision for scaled disagreement or partial credit. *Psychological
  Bulletin* 70(4), 213–220. <https://doi.org/10.1037/h0026256>
- European Commission, PIC/S (2025). *EudraLex Volume 4, Good
  Manufacturing Practice Guidelines, Annex 22: Artificial Intelligence*.
  Draft for stakeholder consultation, 7 July to 7 October 2025.
  <https://health.ec.europa.eu/consultations/stakeholders-consultation-eudralex-volume-4-good-manufacturing-practice-guidelines-chapter-4-annex_en>
- European Medicines Agency (2017). *Guideline on good pharmacovigilance
  practices (GVP), Module VI: Collection, management and submission of
  reports of suspected adverse reactions to medicinal products (Rev 2)*.
  EMA/873138/2011 Rev 2, in effect since 22 November 2017.
  <https://www.ema.europa.eu/en/documents/regulatory-procedural-guideline/guideline-good-pharmacovigilance-practices-gvp-module-vi-collection-management-submission-reports_en.pdf>
- European Parliament, Council of the European Union (2014). Directive
  2014/65/EU of 15 May 2014 on markets in financial instruments (MiFID
  II). OJ L 173, 12.6.2014, p. 349.
  <http://data.europa.eu/eli/dir/2014/65/oj>
- European Parliament, Council of the European Union (2017). Regulation
  (EU) 2017/745 of 5 April 2017 on medical devices (MDR). OJ L 117,
  5.5.2017, p. 1. <http://data.europa.eu/eli/reg/2017/745/oj>
- European Parliament, Council of the European Union (2022). Regulation
  (EU) 2022/2554 of 14 December 2022 on digital operational resilience
  for the financial sector (DORA). OJ L 333, 27.12.2022, p. 1.
  <http://data.europa.eu/eli/reg/2022/2554/oj>
- European Parliament, Council of the European Union (2024). Regulation
  (EU) 2024/1689 of 13 June 2024 laying down harmonised rules on
  artificial intelligence (Artificial Intelligence Act). OJ L,
  2024/1689, 12.7.2024. <http://data.europa.eu/eli/reg/2024/1689/oj>
- European Parliament, Council of the European Union (2026). Regulation
  (EU) 2026/1744 of 8 July 2026 amending Regulations (EU) 2024/1689,
  (EU) 2018/1139 and (EU) 2023/1230 (Digital Omnibus on AI). OJ L,
  2026/1744, 24.7.2026. <http://data.europa.eu/eli/reg/2026/1744/oj>
- He, H., Thinking Machines Lab (2025). Defeating nondeterminism in LLM
  inference. *Thinking Machines Lab: Connectionism*, 10 September 2025.
  <https://doi.org/10.64434/tml.20250910>
- International Council for Harmonisation (2023). *ICH Harmonised
  Guideline Q2(R2): Validation of Analytical Procedures*. Adopted 1
  November 2023.
  <https://database.ich.org/sites/default/files/ICH_Q2(R2)_Guideline_2023_1130.pdf>
- International Council for Harmonisation (2025). *ICH Harmonised
  Guideline: Guideline for Good Clinical Practice E6(R3)*. Step 4,
  adopted 6 January 2025; in effect in the EU since 23 July 2025.
  <https://database.ich.org/sites/default/files/ICH_E6(R3)_Step4_FinalGuideline_2025_0106.pdf>
- International Council for Harmonisation (2026). *ICH Harmonised
  Guideline: General Principles for Model-Informed Drug Development
  M15*. Step 4, adopted 29 January 2026; EU Step 5
  EMA/CHMP/ICH/496426/2024, in effect since 23 July 2026.
  <https://www.ema.europa.eu/en/documents/scientific-guideline/ich-m15-guideline-general-principles-model-informed-drug-development-step-5_en.pdf>
- International Organization for Standardization (2016). *ISO 13485:2016
  Medical devices — Quality management systems — Requirements for
  regulatory purposes*, 3rd
  ed. <https://www.iso.org/standard/59752.html>
- International Organization for Standardization (2022). *ISO 15189:2022
  Medical laboratories — Requirements for quality and competence*, 4th
  ed. <https://www.iso.org/standard/76677.html>
- Krippendorff, K. (2011). *Computing Krippendorff’s Alpha-Reliability*.
  Departmental Papers (ASC), Annenberg School for Communication,
  University of Pennsylvania.
  <https://repository.upenn.edu/asc_papers/43>
- Landrum, M. J., Chitipiralla, S., Kaur, K., et al. (2025). ClinVar:
  updates to support classifications of both germline and somatic
  variants. *Nucleic Acids Research* 53(D1), D1313–D1321.
  <https://doi.org/10.1093/nar/gkae1090>
- Lenth, R. V. (1989). Quick and easy analysis of unreplicated
  factorials. *Technometrics* 31(4), 469–473.
  <https://doi.org/10.1080/00401706.1989.10488595>
- Morris, T. P., White, I. R., Crowther, M. J. (2019). Using simulation
  studies to evaluate statistical methods. *Statistics in Medicine*
  38(11), 2074–2102. <https://doi.org/10.1002/sim.8086>
- Nakagawa, S., Johnson, P. C. D., Schielzeth, H. (2017). The
  coefficient of determination R² and intra-class correlation
  coefficient from generalized linear mixed-effects models revisited and
  expanded. *Journal of the Royal Society Interface* 14(134), 20170213.
  <https://doi.org/10.1098/rsif.2017.0213>
- National Institute of Standards and Technology, Statistical
  Engineering Division. *Statistical Reference Datasets (StRD): Analysis
  of Variance*. <https://itl.nist.gov/div898/strd/anova/anova.html>
  (retrieved 22 October 2026).
- Plackett, R. L., Burman, J. P. (1946). The design of optimum
  multifactorial experiments. *Biometrika* 33(4), 305–325.
  <https://doi.org/10.1093/biomet/33.4.305>
- Richards, S., Aziz, N., Bale, S., et al. (2015). Standards and
  guidelines for the interpretation of sequence variants: a joint
  consensus recommendation of the American College of Medical Genetics
  and Genomics and the Association for Molecular Pathology. *Genetics in
  Medicine* 17(5), 405–424. <https://doi.org/10.1038/gim.2015.30>
- U.S. Food and Drug Administration (2025). *Considerations for the Use
  of Artificial Intelligence to Support Regulatory Decision-Making for
  Drug and Biological Products: Guidance for Industry and Other
  Interested Parties*. Draft guidance, January 2025, docket
  FDA-2024-D-4689. <https://www.fda.gov/media/184830/download>
- Westgard, J. O., Barry, P. L., Hunt, M. R., Groth, T. (1981). A
  multi-rule Shewhart chart for quality control in clinical chemistry.
  *Clinical Chemistry* 27(3), 493–501.
  <https://doi.org/10.1093/clinchem/27.3.493>

## License

MIT, see `LICENSE.md`.
