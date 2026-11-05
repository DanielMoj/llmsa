# Bias interval coverage

`bias_coverage.R` calculates the table in the validation vignette using the
currently loaded `llmsa` namespace. It makes no network request, writes no
result files, and does not load a second package copy. Its inputs are the
whole, hash-verified ANK-06 and ANK-TOL objects from the existing
`validation/latent/reference_checks.R` infrastructure. The original anchors
under `reference/anchors/` remain the authority; no new copies are made here.

ADEMP (docs/04 K-M3a-7, Formelsammlung section 9, ADR-052):

- Aim and estimand: coverage of the t interval for the true mean bias.
- Data: twenty items, three prompts, three models and three replicates.
  Item truths are independent standard normal draws, supplied as references.
  Each response is its item truth plus the scenario bias plus an independent
  normal residual. There are no additional prompt, model or block effects.
  S-bias-1 has residual variance 0.1 and bias 0.2; S-bias-2 has residual
  variance 0.5 and bias zero. These are specification settings, not measured
  constants. The design varies replicate, model, prompt, then item; each
  repetition draws all item truths before all residuals.
- Method: `msa_bias(level = 0.95)` and its `overall` interval. The product
  performs both linearity regressions too; the study evaluates the bias
  interval alone.
- Performance: coverage is the proportion of closed intervals containing
  the truth, with MCSE `sqrt(coverage * (1 - coverage) / n_sim)`. Every
  repetition counts. A calculation failure or invalid interval aborts with
  its scenario and repetition. It never changes the denominator.
- Reproducibility: seeds 20261106 and 20261107, with
  Mersenne-Twister / Inversion / Rejection. RNG kind and the previous seed
  (including its absence) are restored after success and after failure.
  Metadata records settings, sample size, elapsed seconds and R/llmsa versions.
- Production size: ANK-06 `n_sim_min` per scenario. A smaller explicit
  `n_sim` is for fast unit fixtures only and provides no coverage evidence.
  The vignette uses the full default. The signed distance from nominal is
  reported in MCSE; a zero MCSE with a nonzero distance gives signed infinity.
  Findings beyond ANK-TOL.mc_factor.report are named as undercoverage or
  overcoverage and do not abort rendering. The independent acceptance study
  checks ANK-TOL.mc_factor.pass and every interval against its own formula.

Run from an installed package (public context, without protected sources):

```r
latent <- new.env()
sys.source(system.file("validation", "latent", "reference_checks.R",
                       package = "llmsa", mustWork = TRUE), envir = latent)
anchors <- latent$latent_anchors(latent$latent_context(repo_root = ""))
agreement <- new.env()
sys.source(system.file("validation", "agreement", "bias_coverage.R",
                       package = "llmsa", mustWork = TRUE), envir = agreement)
result <- agreement$agreement_bias_coverage(anchors)
agreement$agreement_coverage_table(result)
```

For repository validation, set `REPO_ROOT` to the repository and call
`latent_context()` without the empty override. It verifies the original
anchors as well as the installed copies. The rest of the calculation is
identical. `tests/simulation/test-bias-coverage.R` belongs to the reviewer
and computes independent class A evidence; this helper does not source it.
