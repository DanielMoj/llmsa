# Latent-scale validation resources

`reference_checks.R` compares the currently loaded llmsa with live `ordinal`,
`lme4`, `rptR` and `performance` oracles. `utils::data()` loads wine and
BeetlesMale from those installed packages. No oracle output is frozen here.

`anchors/` contains whole, byte-identical copies of ANK-06, ANK-21, ANK-25,
ANK-28 and ANK-TOL. The authority remains `reference/anchors/` in the
repository. `SOURCES.json` records both paths and SHA-256 digests. Regenerate
offline with `Rscript data-raw/make_validation_latent.R`; `--out <package-root>`
writes the same resources to another directory. No source document or
protected dataset is distributed.

A nonempty `REPO_ROOT` selects original anchors and verifies their hashes
against the copies. Missing originals are errors. Without it the installed
copies supply the public package build. Schema, exact file set, provenance
and hashes are checked in both contexts. Product functions in `R/` do not
read these documentation resources.

The wine engine comparison uses the same random-effects formula as llmsa;
ANK-21 separately checks the published `clmm2` model with temp and contact.
The binary ICC comparison uses liability-scale rptR, performance and the
formula with the residual from ANK-28. ANK-25 belongs only to the separate
rptR default-call installation check; its values are not ICC_items references.

For each study, the vignette reads an existing `<study>_results.csv` from the
loaded package, otherwise `<study>_check_results.csv`. Invalid existing files
fail explicitly. It reports `n_sim` and every measure with its MCSE; it never
runs a simulation during knitting. Full-run completeness and reproduction
are separate milestone checks; the short runs are reproduction evidence.
