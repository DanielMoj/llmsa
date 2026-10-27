#!/usr/bin/env Rscript
# Load the source tree containing this script, including in temporary gate copies.
args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[startsWith(args, "--file=")]
if (length(file_arg) != 1L) stop("AP1 run.R requires Rscript execution.", call. = FALSE)
script <- normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE)
root <- dirname(dirname(dirname(dirname(script))))
if (!file.exists(file.path(root, "DESCRIPTION"))) stop("AP1 source package root missing.", call. = FALSE)
if (!requireNamespace("pkgload", quietly = TRUE)) stop("AP1 needs the frozen pkgload dependency.", call. = FALSE)
pkgload::load_all(root, export_all = FALSE, helpers = FALSE, quiet = TRUE)
options(llmsa.ap1.root = root)
llmsa:::acmg_run_cli(commandArgs(trailingOnly = TRUE))
