#!/usr/bin/env Rscript
# ADEMP binary variance-component recovery, docs/02 M1b; installed package only.
library(llmsa)
helpers <- new.env(parent = globalenv())
sys.source(system.file("validation", "sim", "simulation_helpers.R", package = "llmsa", mustWork = TRUE), helpers)
helpers$sim_main("binary_recovery", commandArgs(trailingOnly = TRUE))
