# Render a validation report

Writes a self-contained validation report in the structure a reviewer or
auditor expects: context of use and model risk, realised study design,
precision (gauge R&R with intervals), agreement and accuracy against the
reference, bias and linearity, robustness screening, the verdict against
the acceptance criteria, and a traceability section with the data hash,
R and package versions and the session information.

## Usage

``` r
msa_report(
  grr,
  runs = NULL,
  boot = NULL,
  agreement = NULL,
  bias = NULL,
  robustness = NULL,
  cou = "",
  question = "",
  risk = c("medium", "low", "high"),
  acceptance = "",
  title = "Validation report: LLM pipeline as a measurement system",
  author = "",
  output_file = "validation_report.html",
  output_format = "html_document",
  quiet = TRUE,
  assessment = NULL
)
```

## Arguments

- grr:

  An `msa_grr` object (required).

- runs:

  The `msa_runs` the analysis is based on (for the realised design and
  the data hash).

- boot, agreement, bias, robustness:

  Optional results of
  [`msa_boot()`](https://danielmoj.github.io/llmsa/reference/msa_boot.md),
  [`msa_agreement()`](https://danielmoj.github.io/llmsa/reference/msa_agreement.md),
  [`msa_bias()`](https://danielmoj.github.io/llmsa/reference/msa_bias.md)
  and
  [`msa_robustness()`](https://danielmoj.github.io/llmsa/reference/msa_robustness.md).

- cou:

  Context of use: what the pipeline output is used for and what decision
  it supports.

- question:

  The question of interest the pipeline answers.

- risk:

  Model risk tier (influence of the output on the decision times
  consequence of a wrong decision).

- acceptance:

  Free-text acceptance criteria (e.g. "%GRR \< 20 % of study variation,
  ndc \>= 5, accuracy \>= 90 %").

- title, author:

  Report title and author.

- output_file:

  Path of the rendered file.

- output_format:

  Any rmarkdown output format, e.g. `"html_document"` (default) or
  `"pdf_document"` (needs LaTeX).

- quiet:

  Suppress rendering output.

- assessment:

  Optional list with `criteria` (a data.frame containing `criterion` and
  `band`, optionally `value` and `note`), `verdict` (one string), and
  `sections` (a named list of entries with character `text` and optional
  data.frame `table`). Validated before rendering. The supplied verdict
  is used in the conclusion; GRR remains in the precision section.
  `NULL` retains the original report. Application rules belong to the
  caller.

## Value

The path of the rendered report, invisibly.

## Details

The sections are filled from the objects supplied; omitted objects give
an explicit "not assessed" entry rather than silence. Rendering needs
the packages `rmarkdown` and `knitr` and a pandoc installation (RStudio
and Positron ship one).

## Examples

``` r
# \donttest{
if (requireNamespace("rmarkdown", quietly = TRUE) && rmarkdown::pandoc_available()) {
  fit <- msa_fit(ic50_demo, type = "numeric")
  out <- msa_report(msa_grr(fit), runs = ic50_demo,
                    bias = msa_bias(ic50_demo, "reference"),
                    cou = "Extraction of IC50 values from assay reports for a screening database",
                    question = "Is the extracted IC50 within assay precision?",
                    risk = "medium", acceptance = "%GRR < 30 %, ndc >= 5, |bias| < 0.1 log10 units",
                    output_file = tempfile(fileext = ".html"))
  out
}
#> [1] "/tmp/Rtmp2K5P9C/file19383e8b51a1.html"
# }
```
