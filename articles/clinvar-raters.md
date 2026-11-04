# ClinVar submitters as a rater study

These two public-domain subsets use ClinVar state **2026-10-19**. The
HRF subset includes variants in MEFV, MVK, NLRP3 and TNFRSF1A with at
least two distinct submitters after the exact five-class filter. The
genome-wide sample draws **1000 variants** with at least **3 distinct
remaining submitters**, using seed **20261024** from a numerically
sorted list. Filtering precedes both counting and sampling. Each
selected variant retains all qualifying submissions, including multiple
SCVs from the same submitter.

The ordered scale is Benign \< Likely benign \< Uncertain significance
\< Likely pathogenic \< Pathogenic. Other terms are excluded, with
counts in the packaged provenance. Gene lists come unchanged from
`variant_summary`; the submitter identifier is the original submitter
text. `data-raw/make_clinvar_subsets.R` checks the anchored source
hashes and reproduces the stored files. Their `SHA256SUMS` includes
`QUELLE.txt`. This article reads only installed data and makes no model
calls.

## Agreement and ordinal components

Variant maps to item and submitter to prompt, with a single model and
block, and replicate one. Krippendorff’s alpha uses all submissions
without modal reduction: `weights = "unweighted"` gives nominal alpha
and `weights = "linear"` selects the ordinal metric. The reported row is
`all conditions`, whose unit is the variant. Only variants with at least
two submissions contribute pairable ratings.

Complete agreement means the same one of the five classes for every
submission. Conflict means at least two of the three groups B/LB, VUS
and P/LP, following ANK-46. Both proportions use variants with at least
two submissions as denominator. Conflict is therefore not the complement
of complete agreement: a B/LB or P/LP difference fails exact agreement
without crossing a conflict boundary.

``` r

alpha_values <- function(d) {
  runs <- as_rater_runs(d)
  nominal <- msa_agreement(runs, levels = classes, weights = "unweighted")
  ordinal <- msa_agreement(runs, levels = classes, weights = "linear")
  c(alpha_nominal = nominal$alpha$alpha[nominal$alpha$scope == "all conditions"],
    alpha_ordinal = ordinal$alpha$alpha[ordinal$alpha$scope == "all conditions"])
}
pairable_counts <- function(d) {
  sizes <- table(d$variation_id)
  c(variants = length(sizes), submissions = nrow(d), pairable_variants = sum(sizes >= 2L),
    pairable_submissions = sum(sizes[sizes >= 2L]))
}
groups <- setNames(c("B/LB", "B/LB", "VUS", "P/LP", "P/LP"), classes)
analyses <- lapply(names(datasets), function(name) {
  d <- datasets[[name]]
  ratings <- split(d$classification, d$variation_id)
  ratings <- ratings[lengths(ratings) >= 2L]
  agreement <- mean(vapply(ratings, function(x) length(unique(x)) == 1L, logical(1)))
  conflict <- mean(vapply(ratings, function(x) length(unique(groups[x])) >= 2L, logical(1)))
  diagnostics <- character()
  fit <- withCallingHandlers(msa_fit(as_rater_runs(d), type = "ordinal", levels = classes,
                                    interactions = FALSE, link = "probit"),
    warning = function(w) {
      diagnostics <<- c(diagnostics, conditionMessage(w)); invokeRestart("muffleWarning")
    }, message = function(m) {
      diagnostics <<- c(diagnostics, conditionMessage(m)); invokeRestart("muffleMessage")
    })
  grr <- msa_grr(fit)
  components <- setNames(fit$vc$variance, fit$vc$source)
  list(agreement = data.frame(subset = name, as.list(pairable_counts(d)), as.list(alpha_values(d)),
                              full_agreement = agreement, conflict = conflict),
       fit = data.frame(subset = name, item = components[["item"]], prompt = components[["prompt"]],
         grr_pct_study_var = grr$summary[["grr_pct_study_var"]], converged = fit$converged, singular = fit$singular),
       diagnostics = data.frame(subset = name, diagnostic = if (length(diagnostics)) paste(unique(diagnostics), collapse = " | ") else "none"))
})
```

| subset | variants | submissions | pairable_variants | pairable_submissions | alpha_nominal | alpha_ordinal | full_agreement | conflict |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| hrf | 1383 | 6647 | 1383 | 6647 | 0.528 | 0.7529 | 0.5264 | 0.3565 |
| sample | 1000 | 5010 | 1000 | 5010 | 0.6037 | 0.8508 | 0.486 | 0.296 |

| subset | item  | prompt | grr_pct_study_var | converged | singular |
|:-------|:------|:-------|:------------------|:----------|:---------|
| hrf    | 4.959 | 1.382  | 56.97             | TRUE      | FALSE    |
| sample | 11.59 | 2.296  | 47.06             | TRUE      | FALSE    |

| subset | diagnostic |
|:-------|:-----------|
| hrf    | none       |
| sample | none       |

The fits use the default probit link without interactions. `item` is
variant variance; `prompt` is submitter variance. Percent GRR uses study
variation. The residual variance is fixed by the link, not an empirical
estimate of repeatability between submissions. Unbalanced participation,
correlated submissions from the same laboratory and differences in the
assessed evidence limit an interpretation as independent random raters.
This is an agreement study, not a clinical validation of individual
classifications.

## Sensitivity to review status

The specified sensitivity keeps only statuses beginning literally with
**“criteria provided”**. It does not match “no assertion criteria
provided”. It also excludes the higher status “reviewed by expert panel”
and excludes “flagged submission”. The following counts show which
statuses are present and retained. The initial submitter thresholds are
not applied again; variants with one remaining submission cannot
contribute to alpha.

``` r

status_counts <- do.call(rbind, lapply(names(datasets), function(name) {
  counts <- as.data.frame(table(review_status = datasets[[name]]$review_status),
                          responseName = "submissions", stringsAsFactors = FALSE)
  data.frame(subset = name, counts, retained = startsWith(counts$review_status, "criteria provided"))
}))
sensitivity <- do.call(rbind, lapply(names(datasets), function(name) {
  d <- datasets[[name]]
  d <- d[!is.na(d$review_status) & startsWith(d$review_status, "criteria provided"), , drop = FALSE]
  data.frame(subset = name, as.list(pairable_counts(d)), as.list(alpha_values(d)))
}))
```

| subset | review_status                       | submissions | retained |
|:-------|:------------------------------------|------------:|:---------|
| hrf    | criteria provided, single submitter |        5958 | TRUE     |
| hrf    | flagged submission                  |          14 | FALSE    |
| hrf    | no assertion criteria provided      |         675 | FALSE    |
| sample | criteria provided, single submitter |        4479 | TRUE     |
| sample | flagged submission                  |           6 | FALSE    |
| sample | no assertion criteria provided      |         488 | FALSE    |
| sample | reviewed by expert panel            |          37 | FALSE    |

Criteria-provided sensitivity: actual retained and pairable
denominators. {.table}

| subset | variants | submissions | pairable_variants | pairable_submissions | alpha_nominal | alpha_ordinal |
|:---|:---|:---|:---|:---|:---|:---|
| hrf | 1381 | 5958 | 1329 | 5906 | 0.5201 | 0.7474 |
| sample | 1000 | 4479 | 993 | 4472 | 0.5983 | 0.8484 |

## Literature comparison

This comparison is **not an acceptance criterion**. All values below are
read from whole, hash-verified copies of ANK-42 through ANK-46. Counts,
percentages, alpha and reported bounds retain their units. The labelled
quantity paths identify each population and denominator; they should not
be pooled into one agreement rate.

Yang et al. (ANK-42) combine classes into three pathogenicity groups or
two actionability groups. Their clinical-testing subset from the later
submission period uses actionability, not exact five-class concordance.
Their complete agreement and majority-consensus rates answer different
questions from each other and from the stricter complete agreement
computed here.

Amendola et al. (ANK-43) compare laboratory criteria and ACMG-AMP
criteria, then reassess agreement after consensus discussion. Their
alpha population differs from the population of the initial and
post-discussion counts, and the publication does not explicitly identify
the alpha metric as nominal or ordinal. Harrison et al. (ANK-44)
distinguish exact agreement, differences within B/LB or P/LP, and
conflicts across those groups. Their reassessment changes the evidence
and cannot be treated as a replicate of this snapshot.

Lazareva et al. (ANK-46) study whether a variant was tagged with a
conflict at least once over the period **2018-04 to 2024-04**, across
genes with disease associations. That cumulative proportion is not a
cross-sectional conflict fraction among multiply submitted variants.

Van Gijn et al. (ANK-45) provide the HRF comparison through a staged
expert consensus workflow. The first-round no-consensus percentage is a
lower bound, and the validation percentage is a voting rule. The
abstract reports 804 consensus variants out of 858, while the Results
counts sum to 803 from the validated and provisional groups. ANK-45
records this discrepancy; the table preserves the reported abstract
value. No INSAID classification for an individual variant is distributed
or used here.

### ANK-42: Yang et al.

Source: [Yang et al.](https://doi.org/10.1038/gim.2017.60).

| quantity | value | unit |
|:---|:---|:---|
| dataset.variants | 27224 | count |
| dataset.genes | 1713 | count |
| dataset.classifications | 74065 | count |
| dataset.submitters | 429 | count |
| pathogenicity three groups.complete agreement pct | 81 | percent |
| pathogenicity three groups.majority consensus pct | 89.3 | percent |
| actionability two groups.complete agreement pct | 94.1 | percent |
| actionability two groups.majority consensus pct | 96.7 | percent |
| clinical testing 2014 or later actionability.variants | 11535 | count |
| clinical testing 2014 or later actionability.complete agreement pct | 97.2 | percent |
| clinical testing 2014 or later actionability.majority consensus pct | 98.4 | percent |

### ANK-43: Amendola et al.

Source: [Amendola et al.](https://doi.org/10.1016/j.ajhg.2016.03.024).

| quantity                                       | value | unit                |
|:-----------------------------------------------|:------|:--------------------|
| laboratories                                   | 9     | count               |
| variants                                       | 99    | count               |
| variants in alpha                              | 97    | count               |
| k alpha interlab acmg amp                      | 0.72  | dimensionless alpha |
| k alpha interlab lab criteria                  | 0.76  | dimensionless alpha |
| identical across labs initial.variants         | 33    | count               |
| identical across labs initial.of               | 99    | count               |
| identical across labs initial.pct              | 34    | percent             |
| consensus after discussion.variants            | 70    | count               |
| consensus after discussion.of                  | 99    | count               |
| consensus after discussion.pct                 | 71    | percent             |
| medically relevant differences.classifications | 43    | count               |
| medically relevant differences.of              | 194   | count               |
| medically relevant differences.pct             | 22    | percent             |

### ANK-44: Harrison et al.

Source: [Harrison et al.](https://doi.org/10.1038/gim.2017.14).

| quantity                                   | value | unit    |
|:-------------------------------------------|:------|:--------|
| laboratories                               | 4     | count   |
| shared variants                            | 6169  | count   |
| genes                                      | 308   | count   |
| concordant initial pct                     | 88.3  | percent |
| exact agreement.variants                   | 3845  | count   |
| exact agreement.pct                        | 62.3  | percent |
| confidence differences.variants            | 1600  | count   |
| confidence differences.pct                 | 26    | percent |
| discordant.variants                        | 724   | count   |
| discordant.pct                             | 11.7  | percent |
| medically significant differences.variants | 216   | count   |
| medically significant differences.pct      | 3.5   | percent |
| plp vs lbb variants                        | 12    | count   |
| vus vs lbb.variants                        | 508   | count   |
| vus vs lbb.pct                             | 8.2   | percent |
| concordant after reassessment pct          | 91.7  | percent |

### ANK-45: Van Gijn et al. (HRF)

Source: [Van Gijn et
al. (HRF)](https://doi.org/10.1136/jmedgenet-2017-105216).

| quantity                       | value | unit                               |
|:-------------------------------|:------|:-----------------------------------|
| variants                       | 858   | count                              |
| experts round 1                | 4     | count                              |
| no consensus round 1 pct above | 80    | percent, strictly above this bound |
| consensus final.variants       | 804   | count                              |
| consensus final.of             | 858   | count                              |
| consensus final.pct            | 94    | percent                            |
| validated rule min pct         | 75    | percent, minimum rule              |
| validated.variants             | 632   | count                              |
| validated.pct                  | 74    | percent                            |
| provisional.variants           | 171   | count                              |
| provisional.pct                | 20    | percent                            |

### ANK-46: Lazareva et al.

Source: [Lazareva et al.](https://doi.org/10.3390/jpm14080864).

| quantity           | value   | unit    |
|:-------------------|:--------|:--------|
| variants           | 2296245 | count   |
| genes              | 4731    | count   |
| coi variants       | 131092  | count   |
| coi genes          | 3703    | count   |
| coi variants pct   | 5.7     | percent |
| genes with coi pct | 78      | percent |

Agreement with other submitters is not a correctness label for a
variant. The different populations, grouping rules and reassessment
procedures explain why these literature results are contextual
comparisons rather than target values for either frozen subset. See
[`vignette("validation")`](https://danielmoj.github.io/llmsa/articles/validation.md)
for the statistical engine checks and the ordinal simulation findings.
