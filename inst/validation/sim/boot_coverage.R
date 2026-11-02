#!/usr/bin/env Rscript
# ADEMP percentile-interval coverage, docs/02 M1c; installed package only.
library(llmsa)
helpers <- new.env(parent = globalenv())
sys.source(system.file("validation", "sim", "boot_coverage_helpers.R", package = "llmsa", mustWork = TRUE), helpers)
helpers$boot_main(commandArgs(trailingOnly = TRUE))
