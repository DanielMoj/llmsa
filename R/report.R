#' Render a validation report
#'
#' Writes a self-contained validation report in the structure a reviewer
#' or auditor expects: context of use and model risk, realised study
#' design, precision (gauge R&R with intervals), agreement and accuracy
#' against the reference, bias and linearity, robustness screening, the
#' verdict against the acceptance criteria, and a traceability section with
#' the data hash, R and package versions and the session information.
#'
#' The sections are filled from the objects supplied; omitted objects give
#' an explicit "not assessed" entry rather than silence. Rendering needs
#' the packages `rmarkdown` and `knitr` and a pandoc installation (RStudio
#' and Positron ship one).
#' A supplied run table also requires `digest` for its SHA-256 hash. JSON
#' metadata are read with `jsonlite`; missing or unreadable metadata are
#' identified explicitly. Each model's table lists all observed snapshot and
#' provider values, and the requested quantizations recorded in `meta`.
#'
#' The data hash covers every column and row, without row names or object
#' attributes. Canonical CSV puts `block`, `item_id`, `prompt_id`, `model_id`,
#' `rep` first, followed by other column names in UTF-8 byte order. Rows sort
#' by those five keys (numeric keys by value, other keys by UTF-8 bytes, missing
#' keys last), with the full serialized row as the tie breaker. Duplicates
#' remain. The quoted header and every row end in LF. Text, including factor
#' labels, is UTF-8 and quoted with doubled internal quotes; embedded newlines
#' remain. Logical values are TRUE/FALSE, integers decimal, doubles use
#' `sprintf("%.17g")` with a decimal point. NA, NaN, Inf and -Inf retain their
#' distinct unquoted forms. Other columns are converted with `as.character()`.
#' The lowercase SHA-256 is computed over these bytes without R serialization.
#'
#' Seeds are read only from the design attached to `runs` and the `seed`
#' attributes of `boot` and `robustness`. Older objects or unrecorded seeds
#' are shown as "not reported"; the current RNG state is never used.
#'
#' @param grr An `msa_grr` object (required).
#' @param runs The `msa_runs` the analysis is based on (for the realised
#'   design and the data hash).
#' @param boot,agreement,bias,robustness Optional results of [msa_boot()],
#'   [msa_agreement()], [msa_bias()] and [msa_robustness()].
#' @param cou Context of use: what the pipeline output is used for and what
#'   decision it supports.
#' @param question The question of interest the pipeline answers.
#' @param risk Model risk tier (influence of the output on the decision
#'   times consequence of a wrong decision).
#' @param acceptance Free-text acceptance criteria (e.g. "%GRR < 20 % of
#'   study variation, ndc >= 5, accuracy >= 90 %").
#' @param title,author Report title and author.
#' @param output_file Path of the rendered file.
#' @param output_format Any rmarkdown output format, e.g. `"html_document"`
#'   (default) or `"pdf_document"` (needs LaTeX).
#' @param quiet Suppress rendering output.
#' @param assessment Optional list with `criteria` (a data.frame containing
#'   `criterion` and `band`, optionally `value` and `note`), `verdict` (one
#'   string), and `sections` (a named list of entries with character `text`
#'   and optional data.frame `table`). Validated before rendering. The supplied
#'   verdict is used in the conclusion; GRR remains in the precision section.
#'   `NULL` retains the original report. Application rules belong to the caller.
#' @param control_chart Optional result of [msa_control_chart()]. The report
#'   lists TRUE counts and sorted index positions for each rule and `reject`,
#'   and identifies the range interpretation of R_4s on consecutive values.
#' @return The path of the rendered report, invisibly.
#' @examples
#' \donttest{
#' if (requireNamespace("rmarkdown", quietly = TRUE) && rmarkdown::pandoc_available()) {
#'   fit <- msa_fit(ic50_demo, type = "numeric")
#'   out <- msa_report(msa_grr(fit), runs = ic50_demo,
#'                     bias = msa_bias(ic50_demo, "reference"),
#'                     cou = "Extraction of IC50 values from assay reports for a screening database",
#'                     question = "Is the extracted IC50 within assay precision?",
#'                     risk = "medium", acceptance = "%GRR < 30 %, ndc >= 5, |bias| < 0.1 log10 units",
#'                     output_file = tempfile(fileext = ".html"))
#'   out
#' }
#' }
#' @export
msa_report <- function(grr, runs = NULL, boot = NULL, agreement = NULL, bias = NULL,
                       robustness = NULL, cou = "", question = "",
                       risk = c("medium", "low", "high"), acceptance = "",
                       title = "Validation report: LLM pipeline as a measurement system",
                       author = "", output_file = "validation_report.html",
                       output_format = "html_document", quiet = TRUE,
                       assessment = NULL, control_chart = NULL) {
  if (!inherits(grr, "msa_grr")) stop("`grr` must come from msa_grr().", call. = FALSE)
  if (!is.null(assessment)) validate_assessment(assessment)
  if (!is.null(control_chart) && !inherits(control_chart, "msa_control_chart")) {
    stop("`control_chart` must come from msa_control_chart().", call. = FALSE)
  }
  risk <- match.arg(risk)
  if (!requireNamespace("rmarkdown", quietly = TRUE) || !requireNamespace("knitr", quietly = TRUE)) {
    stop("Rendering needs packages `rmarkdown` and `knitr`.", call. = FALSE)
  }
  if (!rmarkdown::pandoc_available()) stop("pandoc was not found; install pandoc or use RStudio/Positron.", call. = FALSE)
  template <- system.file("templates", "validation_report.Rmd", package = "llmsa")
  if (!nzchar(template)) stop("Report template not found in the installed package.", call. = FALSE)
  models <- msa_report_models(runs)
  params <- list(
    grr = grr, runs = runs, boot = boot, agreement = agreement, bias = bias,
    robustness = robustness, cou = cou, question = question, risk = risk,
    acceptance = acceptance, title = title, author = author, assessment = assessment,
    data_hash = msa_report_hash(runs),
    design_seed = msa_report_seed(attr(runs, "design", exact = TRUE)),
    bootstrap_seed = msa_report_seed(boot),
    plackett_burman_seed = msa_report_seed(robustness),
    model_metadata = models$table, metadata_notes = models$notes,
    control_chart = msa_report_control_chart(control_chart),
    # AIAG and contribution conventions: reference/anchors/ANK-16.json.
    ndc_constant = 1.41, contribution_thresholds = c(1, 9),
    package_version = as.character(utils::packageVersion("llmsa")),
    rendered_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))
  tmp <- file.path(tempdir(), "llmsa_report")
  dir.create(tmp, showWarnings = FALSE, recursive = TRUE)
  file.copy(template, file.path(tmp, "validation_report.Rmd"), overwrite = TRUE)
  old_options <- options(OutDec = ".")
  on.exit(options(old_options), add = TRUE)
  out <- rmarkdown::render(file.path(tmp, "validation_report.Rmd"), output_format = output_format,
                           output_file = basename(output_file), output_dir = dirname(normalizePath(output_file, mustWork = FALSE)),
                           params = params, envir = new.env(parent = globalenv()), quiet = quiet)
  invisible(out)
}

validate_assessment <- function(x) {
  fail <- function() stop("`assessment` requires criteria (criterion, band), a verdict string and named sections with text and optional data.frame table.", call. = FALSE)
  if (!is.list(x) || !all(c("criteria", "verdict", "sections") %in% names(x))) fail()
  if (!is.data.frame(x$criteria) || !all(c("criterion", "band") %in% names(x$criteria))) fail()
  if (!is.character(x$verdict) || length(x$verdict) != 1L || is.na(x$verdict) || !nzchar(x$verdict)) fail()
  if (!is.list(x$sections)) fail()
  if (length(x$sections) && (is.null(names(x$sections)) || anyNA(names(x$sections)) ||
                            any(!nzchar(names(x$sections))) || anyDuplicated(names(x$sections)))) fail()
  for (s in x$sections) {
    if (!is.list(s) || !is.character(s$text) || anyNA(s$text) ||
        (!is.null(s$table) && !is.data.frame(s$table))) fail()
  }
  invisible(x)
}
