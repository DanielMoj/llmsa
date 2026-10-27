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
                       assessment = NULL) {
  if (!inherits(grr, "msa_grr")) stop("`grr` must come from msa_grr().", call. = FALSE)
  if (!is.null(assessment)) validate_assessment(assessment)
  risk <- match.arg(risk)
  if (!requireNamespace("rmarkdown", quietly = TRUE) || !requireNamespace("knitr", quietly = TRUE)) {
    stop("Rendering needs packages `rmarkdown` and `knitr`.", call. = FALSE)
  }
  if (!rmarkdown::pandoc_available()) stop("pandoc was not found; install pandoc or use RStudio/Positron.", call. = FALSE)
  template <- system.file("templates", "validation_report.Rmd", package = "llmsa")
  if (!nzchar(template)) stop("Report template not found in the installed package.", call. = FALSE)
  params <- list(
    grr = grr, runs = runs, boot = boot, agreement = agreement, bias = bias,
    robustness = robustness, cou = cou, question = question, risk = risk,
    acceptance = acceptance, title = title, author = author, assessment = assessment,
    data_hash = if (is.null(runs)) NA_character_ else hash_object(as.data.frame(runs)),
    package_version = as.character(utils::packageVersion("llmsa")),
    rendered_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))
  tmp <- file.path(tempdir(), "llmsa_report")
  dir.create(tmp, showWarnings = FALSE, recursive = TRUE)
  file.copy(template, file.path(tmp, "validation_report.Rmd"), overwrite = TRUE)
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
