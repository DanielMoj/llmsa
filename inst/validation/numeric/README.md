# Numeric statistical validation

`reference_checks.R` is the executable calculation used by
`vignette("validation", package = "llmsa")`. It uses the currently loaded
package namespace and live `stats`, `lme4`, `VCA` and `SixSigma` oracles.
All expected published values and tolerances come from the original anchors
or their verified whole-file copies. The script writes no results and makes
no network requests.

For complete local validation, set `REPO_ROOT` to the repository root before
knitting or building the package. Required inputs are:

- `reference/anchors/ANK-10.json`, `ANK-13.json`, `ANK-14.json`, `ANK-16.json`
  and `ANK-TOL.json`;
- the protected AIAG sheet at `reference/quellen/data/aiag/anova_example.csv`;
- the frozen NIST originals in the sibling directory
  `../quellen/daten/nist-strd-anova_2026-10-22/`.

Missing or modified inputs stop this mode. It never switches silently to the
public context. Neither context prints AIAG measurements, only statistics.

With `REPO_ROOT` unset or empty, the public context computes all free
comparisons using installed data. AIAG comparisons show the expected
statistics and `not rerun: protected data required`, with result `NOT RERUN`.
This context needs no protected files and is exercised by package build/check.

From a repository with the local originals, reproduce all public inputs with:

```sh
Rscript data-raw/make_validation_numeric.R
Rscript data-raw/make_validation_numeric.R --out /tmp/llmsa-validation-inputs
```

The output directory is a package root: it receives `inst/extdata/` and
`inst/validation/numeric/anchors/` plus `SOURCES.json`. The generator verifies
all original hashes and schemas before publication. Numeric tokens and row
order are preserved. Large CSVs use timestamp-free gzip headers. No oracle
outputs are frozen. Regenerate after an authorized change to an original
anchor; never edit a copy by hand.

`SOURCES.json` identifies each original and stored file by path and SHA-256.
The unit suite verifies copy integrity and drift against any reachable
repository. Only comparison to the original files is skipped when no
repository is reachable; installed resources are always checked. The full
vignette, large VCA calculation and independent acceptance suite are separate
from the small unit tests.
