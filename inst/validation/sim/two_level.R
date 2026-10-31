#!/usr/bin/env Rscript
# ADEMP two-level range-method study, docs/02 M1b; installed package only.
library(llmsa)
helpers <- new.env(parent = globalenv())
sys.source(system.file("validation", "sim", "simulation_helpers.R", package = "llmsa", mustWork = TRUE), helpers)
helpers$sim_main("two_level", commandArgs(trailingOnly = TRUE))
