# M1d offline resources

`prepare.R` supplies the data preparation scripts with strict label parsing,
ClinVar selection, deterministic UTF-8 CSV/gzip writing and staged publication.
It does not load llmsa. Run from the repository root:

```sh
Rscript data-raw/make_llm_stability.R
Rscript data-raw/make_clinvar_subsets.R
Rscript data-raw/make_validation_m1d.R
```

The first two commands require the original sibling `quellen/daten/` folders
and verify their anchored SHA-256 hashes before writing. They never download
data. Their complete selection and parsing rules, exclusions and missingness
counts are in the respective `extdata/` folder's `QUELLE.txt`; `SHA256SUMS`
covers every delivered file except itself. ADR-049 records the choices.

`anchors/` holds whole, byte-identical copies of ANK-06, ANK-40 through ANK-47,
ANK-63 and ANK-TOL. `reference/anchors/` remains the authority; `SOURCES.json`
records original and installed paths and SHA-256 hashes. The third command
reproduces the copies; `--out <package-root>` writes them elsewhere. The reader
checks the exact file set, hashes, provenance and required anchor fields.
Neither source documents nor protected per-variant annotations are included.

`findings.R` reads those resources and presents findings from the existing
result readers. It never loads a simulation generator, refits models or
changes result, replicate or session files. Reporting thresholds come from
ANK-TOL. Nominal coverage is the 95% interval level specified in docs/02 M1c.
Zero MCSE does not hide a deviation from that level. Each two-level scenario
reports bias and MCSE even when the report threshold resolves no direction.

The separate ordinal convergence sensitivity reads only its own replicate
file, retaining all finite estimates in the main group and selecting
`converged == TRUE` in the comparison group. Singular estimates stay in both
eligible groups. Each group reports its observed n, bias, relative bias,
EmpSE and MCSE using the ADEMP formulas in the project's formula collection
section 9. Fewer than two finite estimates produce an explicit unavailable
MCSE. Diagnostic fractions use actual outer repetitions as denominator and
show missing convergence/singularity flags separately. No comparison with
the independent results table is made. A missing replicate file makes only
this supplemental analysis unavailable; full-run acceptance still fails.

The installed vignettes use only packaged data and these resources. The
`llm-stability` and `clinvar-raters` articles perform their specified fits
at build time; `validation` reads the four studies without rerunning them.
