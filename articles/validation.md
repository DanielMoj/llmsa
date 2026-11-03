# Statistical validation of llmsa

## Variance components and gauge R&R (numeric)

These calculations compare the numeric random-effects model with
independent ANOVA calculations, published estimates, certified NIST
quantities and live package oracles. Every observed value is recomputed
by the currently loaded `llmsa` namespace. No fitted estimates or oracle
results are stored as inputs. The reference calculations are implemented
in the installed `validation/numeric/reference_checks.R` script.

The reference authority is `reference/anchors/`: ANK-10 contains the
AIAG example, ANK-13 the published Penicillin estimates, ANK-14 the NIST
certified quantities, ANK-16 the GRR conventions, and ANK-TOL the
comparison tolerances. Variance-component tolerances are fractions of
the reference **total** variance; derived ratios use relative
tolerances. Printed standard deviations are compared on the variance
scale where the anchor requires it. The tables show the resulting
absolute bounds.

This run uses the **public** context. A nonempty `REPO_ROOT` selects
complete local validation: original anchors, the protected AIAG sheet
and the frozen NIST originals. Missing inputs or mismatching SHA-256
hashes stop the calculation. Without `REPO_ROOT`, the public package
build uses whole, byte-identical anchor copies and free NIST tables.
Their provenance is recorded in `validation/numeric/SOURCES.json`. In
that context, AIAG rows explicitly say
`not rerun: protected data required` and never claim a successful rerun.
Neither context displays the protected AIAG measurements.

The balanced synthetic studies use the specification’s four crossed
designs with seed one, with and without block effects and pairwise
interactions. The independent ANOVA calculation solves the
expected-mean-square equations; negative moment estimates are outside
that comparison. At a variance boundary, the numeric default fit
re-estimates the remaining components by restricted REML. The AIAG
comparison pools the interaction as in the handbook; that row is marked
as not separately estimated. The model with interaction is reported
separately. On the unbalanced `ic50_demo` data,
[`VCA::remlVCA`](https://rdrr.io/pkg/VCA/man/remlVCA.html) is a
criterion, while
[`VCA::anovaVCA`](https://rdrr.io/pkg/VCA/man/anovaVCA.html) is a
reported comparison.
[`SixSigma::ss.rr`](http://emilopezcano.github.io/SixSigma/reference/ss.rr.md)
uses its default interaction pooling; study variation comes from its
unrounded standard deviations.

### Balanced designs against ANOVA

| Anchor | Source | Quantity | Expected | Observed | Tolerance | Result |
|:---|:---|:---|:---|:---|:---|:---|
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 1 (seed 1) item | 0.835101910404327 | 0.835102313122942 | 0.000112176345654644 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 1 (seed 1) prompt | 0.168794312318087 | 0.168794416682278 | 0.000112176345654644 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 1 (seed 1) model | 0.0123698579800859 | 0.0123698382273596 | 0.000112176345654644 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 1 (seed 1) Residual | 0.105497375843937 | 0.10549737464579 | 0.000112176345654644 absolute | PASS |
| ANK-TOL.reml_anova | Independent GRR formulas | Synthetic design 1 (seed 1) grr_pct_study_var | 50.5515033377568 | 50.5514997389425 | 0.00505515033377568 absolute | PASS |
| ANK-TOL.reml_anova | Independent GRR formulas | Synthetic design 1 (seed 1) grr_pct_contribution | 25.5545448970724 | 25.5545412585631 | 0.00255545448970724 absolute | PASS |
| ANK-TOL.reml_anova | Independent GRR formulas | Synthetic design 1 (seed 1) icc_items | 0.744454551029276 | 0.744454587414369 | 7.44454551029276e-05 absolute | PASS |
| ANK-TOL.reml_anova | Independent GRR formulas | Synthetic design 1 (seed 1) ndc | 2 | 2 | 0 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 2 (seed 1) item | 0.896356056977856 | 0.896355885245044 | 0.000119652855913307 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 2 (seed 1) prompt | 0.099234985232256 | 0.0992349351431396 | 0.000119652855913307 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 2 (seed 1) model | 0.00163326075749219 | 0.00163326845691075 | 0.000119652855913307 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 2 (seed 1) item:prompt | 0.0332467620444283 | 0.0332467584284754 | 0.000119652855913307 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 2 (seed 1) item:model | 0.0292096365532243 | 0.0292096391073928 | 0.000119652855913307 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 2 (seed 1) prompt:model | 0.0207364731002638 | 0.0207364810060388 | 0.000119652855913307 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 2 (seed 1) Residual | 0.116111384467547 | 0.116111384938424 | 0.000119652855913307 absolute | PASS |
| ANK-TOL.reml_anova | Independent GRR formulas | Synthetic design 2 (seed 1) grr_pct_study_var | 50.086872925452 | 50.086874327654 | 0.0050086872925452 absolute | PASS |
| ANK-TOL.reml_anova | Independent GRR formulas | Synthetic design 2 (seed 1) grr_pct_contribution | 25.0869483945038 | 25.0869497991421 | 0.00250869483945038 absolute | PASS |
| ANK-TOL.reml_anova | Independent GRR formulas | Synthetic design 2 (seed 1) icc_items | 0.749130516054963 | 0.749130502008579 | 7.49130516054962e-05 absolute | PASS |
| ANK-TOL.reml_anova | Independent GRR formulas | Synthetic design 2 (seed 1) ndc | 2 | 2 | 0 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 3 (seed 1) item | 0.831776303543049 | 0.831777146976174 | 0.000116858157865115 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 3 (seed 1) prompt | 0.170651542751799 | 0.170652334747135 | 0.000116858157865115 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 3 (seed 1) model | 0.014079640005018 | 0.0140796343569236 | 0.000116858157865115 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 3 (seed 1) block | 0.0429564226349355 | 0.0429565506072487 | 0.000116858157865115 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 3 (seed 1) Residual | 0.109117669716351 | 0.109117667757456 | 0.000116858157865115 absolute | PASS |
| ANK-TOL.reml_anova | Independent GRR formulas | Synthetic design 3 (seed 1) grr_pct_study_var | 53.6858612349231 | 53.6858936172884 | 0.00536858612349231 absolute | PASS |
| ANK-TOL.reml_anova | Independent GRR formulas | Synthetic design 3 (seed 1) grr_pct_contribution | 28.8217169653542 | 28.8217517348681 | 0.00288217169653542 absolute | PASS |
| ANK-TOL.reml_anova | Independent GRR formulas | Synthetic design 3 (seed 1) icc_items | 0.711782830346458 | 0.711782482651319 | 7.11782830346458e-05 absolute | PASS |
| ANK-TOL.reml_anova | Independent GRR formulas | Synthetic design 3 (seed 1) ndc | 2 | 2 | 0 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 4 (seed 1) item | 0.812907930868241 | 0.812903011877827 | 0.000127510045272807 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 4 (seed 1) prompt | 0.19014246243158 | 0.190140990142518 | 0.000127510045272807 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 4 (seed 1) model | 0.00493987696115859 | 0.00493990642879696 | 0.000127510045272807 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 4 (seed 1) block | 0.0447175071996804 | 0.0447173774568431 | 0.000127510045272807 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 4 (seed 1) item:prompt | 0.0445888629217295 | 0.0445888568476236 | 0.000127510045272807 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 4 (seed 1) item:model | 0.0365928277418786 | 0.0365928295480705 | 0.000127510045272807 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 4 (seed 1) prompt:model | 0.0312833167960641 | 0.031283375422539 | 0.000127510045272807 absolute | PASS |
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 4 (seed 1) Residual | 0.109927667807743 | 0.109927674665773 | 0.000127510045272807 absolute | PASS |
| ANK-TOL.reml_anova | Independent GRR formulas | Synthetic design 4 (seed 1) grr_pct_study_var | 60.2059283263633 | 60.2059817007425 | 0.00602059283263633 absolute | PASS |
| ANK-TOL.reml_anova | Independent GRR formulas | Synthetic design 4 (seed 1) grr_pct_contribution | 36.2475380563919 | 36.2476023255014 | 0.00362475380563919 absolute | PASS |
| ANK-TOL.reml_anova | Independent GRR formulas | Synthetic design 4 (seed 1) icc_items | 0.637524619436081 | 0.637523976744986 | 6.37524619436081e-05 absolute | PASS |
| ANK-TOL.reml_anova | Independent GRR formulas | Synthetic design 4 (seed 1) ndc | 1 | 1 | 0 absolute | PASS |

### AIAG published statistics

| Anchor | Source | Quantity | Expected | Observed | Tolerance | Result |
|:---|:---|:---|:---|:---|:---|:---|
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | EV variance | 0.039973 | not rerun: protected data required | 0.0001177876 absolute | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | AV variance | 0.051455 | not rerun: protected data required | 0.0001177876 absolute | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | INT variance | 0 | not rerun: protected data required | 0.0001177876 absolute | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | GRR variance | 0.09143 | not rerun: protected data required | 0.0001177876 absolute | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | PV variance | 1.086446 | not rerun: protected data required | 0.0001177876 absolute | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | EV sd | 0.199933 | not rerun: protected data required | 0.0001177876 on variance scale | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | AV sd | 0.226838 | not rerun: protected data required | 0.0001177876 on variance scale | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | INT sd | 0 | not rerun: protected data required | 0.0001177876 on variance scale | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | GRR sd | 0.302373 | not rerun: protected data required | 0.0001177876 on variance scale | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | PV sd | 1.042327 | not rerun: protected data required | 0.0001177876 on variance scale | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | TV sd | 1.085 | not rerun: protected data required | 0.00055428 absolute | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | EV pct_study_var | 18.4 | not rerun: protected data required | 0.05184 absolute | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | AV pct_study_var | 20.9 | not rerun: protected data required | 0.05209 absolute | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | INT pct_study_var | 0 | not rerun: protected data required | 0.5 absolute | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | GRR pct_study_var | 27.9 | not rerun: protected data required | 0.05279 absolute | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | PV pct_study_var | 96 | not rerun: protected data required | 0.0596 absolute | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | TV pct_study_var | 100 | not rerun: protected data required | 0.05 absolute | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | EV pct_contribution | 3.4 | not rerun: protected data required | 0.05034 absolute | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | AV pct_contribution | 4.4 | not rerun: protected data required | 0.05044 absolute | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | INT pct_contribution | 0 | not rerun: protected data required | 0.5 absolute | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | GRR pct_contribution | 7.8 | not rerun: protected data required | 0.05078 absolute | NOT RERUN |
| ANK-10 | AIAG (2010), Tables III-B 8 and III-B 10 | PV pct_contribution | 92.2 | not rerun: protected data required | 0.05922 absolute | NOT RERUN |
| ANK-10 | AIAG (2010) | ndc | 4 | not rerun: protected data required | exact | NOT RERUN |

### ic50_demo against remlVCA

| Anchor | Source | Quantity | Expected | Observed | Tolerance | Result |
|:---|:---|:---|:---|:---|:---|:---|
| ANK-TOL.oracle | VCA::remlVCA | ic50_demo item | 0.967220789818754 | 0.967220226546123 | 0.000100970171854842 absolute | PASS |
| ANK-TOL.oracle | VCA::remlVCA | ic50_demo prompt | 0.00486225044085849 | 0.00486224064145486 | 0.000100970171854842 absolute | PASS |
| ANK-TOL.oracle | VCA::remlVCA | ic50_demo model | 0.0171356297778552 | 0.0171354046279492 | 0.000100970171854842 absolute | PASS |
| ANK-TOL.oracle | VCA::remlVCA | ic50_demo block | 0.00101738231623373 | 0.00101739985692395 | 0.000100970171854842 absolute | PASS |
| ANK-TOL.oracle | VCA::remlVCA | ic50_demo item:prompt | 8.42405662587328e-05 | 8.42408728729267e-05 | 0.000100970171854842 absolute | PASS |
| ANK-TOL.oracle | VCA::remlVCA | ic50_demo item:model | 0.00534983906040427 | 0.00534983731012706 | 0.000100970171854842 absolute | PASS |
| ANK-TOL.oracle | VCA::remlVCA | ic50_demo prompt:model | 2.12812383544617e-05 | 2.12809485421782e-05 | 0.000100970171854842 absolute | PASS |
| ANK-TOL.oracle | VCA::remlVCA | ic50_demo Residual | 0.0140103053297033 | 0.0140103056395663 | 0.000100970171854842 absolute | PASS |

### ic50_demo (unbalanced) against anovaVCA

| Anchor | Source | Quantity | Expected | Observed | Tolerance | Result |
|:---|:---|:---|:---|:---|:---|:---|
| ANK-TOL.oracle | VCA::anovaVCA | ic50_demo (unbalanced) item | 0.969968365297755 | 0.967220226546123 | not a criterion: unbalanced ANOVA | REPORT |
| ANK-TOL.oracle | VCA::anovaVCA | ic50_demo (unbalanced) prompt | 0.00488367383776392 | 0.00486224064145486 | not a criterion: unbalanced ANOVA | REPORT |
| ANK-TOL.oracle | VCA::anovaVCA | ic50_demo (unbalanced) model | 0.0171099342884023 | 0.0171354046279492 | not a criterion: unbalanced ANOVA | REPORT |
| ANK-TOL.oracle | VCA::anovaVCA | ic50_demo (unbalanced) block | 0.00100892168736979 | 0.00101739985692395 | not a criterion: unbalanced ANOVA | REPORT |
| ANK-TOL.oracle | VCA::anovaVCA | ic50_demo (unbalanced) item:prompt | 9.42738421534943e-05 | 8.42408728729267e-05 | not a criterion: unbalanced ANOVA | REPORT |
| ANK-TOL.oracle | VCA::anovaVCA | ic50_demo (unbalanced) item:model | 0.00534173250038118 | 0.00534983731012706 | not a criterion: unbalanced ANOVA | REPORT |
| ANK-TOL.oracle | VCA::anovaVCA | ic50_demo (unbalanced) prompt:model | 2.15882253347061e-05 | 2.12809485421782e-05 | not a criterion: unbalanced ANOVA | REPORT |
| ANK-TOL.oracle | VCA::anovaVCA | ic50_demo (unbalanced) Residual | 0.0140107037401431 | 0.0140103056395663 | not a criterion: unbalanced ANOVA | REPORT |

### SixSigma oracle

| Anchor | Source | Quantity | Expected | Observed | Tolerance | Result |
|:---|:---|:---|:---|:---|:---|:---|
| ANK-TOL.oracle | SixSigma::ss.rr, default pooling | Residual | 0.0213087542087542 | 0.0213087542223815 | 8.62212121212121e-06 absolute | PASS |
| ANK-TOL.oracle | SixSigma::ss.rr, default pooling | prompt | 0.000573512906846233 | 0.000573512905820389 | 8.62212121212121e-06 absolute | PASS |
| ANK-TOL.oracle | SixSigma::ss.rr, default pooling | item:prompt | 0 | 0 | 8.62212121212121e-06 absolute | PASS |
| ANK-TOL.oracle | SixSigma::ss.rr, default pooling | item | 0.0643389450056117 | 0.0643389445237618 | 8.62212121212121e-06 absolute | PASS |
| ANK-TOL.oracle | SixSigma::ss.rr, unrounded StdDev | Total gauge R&R % study variation | 50.3777881275185 | 50.3777882791117 | 0.00503777881275185 absolute | PASS |
| ANK-TOL.oracle | SixSigma::ss.rr, unrounded StdDev | Repeatability % study variation | 49.7132284728041 | 49.7132286239795 | 0.00497132284728041 absolute | PASS |
| ANK-TOL.oracle | SixSigma::ss.rr, unrounded StdDev | Reproducibility % study variation | 8.15576185478249 | 8.15576186968176 | 0.000815576185478249 absolute | PASS |
| ANK-TOL.oracle | SixSigma::ss.rr, unrounded StdDev | prompt % study variation | 8.15576185478249 | 8.15576186968176 | 0.000815576185478249 absolute | PASS |
| ANK-TOL.oracle | SixSigma::ss.rr, unrounded StdDev | Part-to-part (items) % study variation | 86.3833228313131 | 86.3833227429056 | 0.00863833228313131 absolute | PASS |
| ANK-TOL.oracle | SixSigma::ss.rr | ndc | 2 | 2 | 0 absolute | PASS |

### Penicillin against ANOVA

| Anchor | Source | Quantity | Expected | Observed | Tolerance | Result |
|:---|:---|:---|:---|:---|:---|:---|
| ANK-TOL.reml_anova | Penicillin: stats::aov EMS | item | 3.73091787439613 | 3.73091787439614 | 0.000475024154589372 absolute | PASS |
| ANK-TOL.reml_anova | Penicillin: stats::aov EMS | prompt | 0.716908212560386 | 0.716908212560387 | 0.000475024154589372 absolute | PASS |
| ANK-TOL.reml_anova | Penicillin: stats::aov EMS | Residual | 0.302415458937197 | 0.302415458937198 | 0.000475024154589372 absolute | PASS |

### Penicillin published estimates

| Anchor | Source | Quantity | Expected | Observed | Tolerance | Result |
|:---|:---|:---|:---|:---|:---|:---|
| ANK-13 | Bates (2010), section 2.1.2 | plate variance | 0.71691 | 0.716908212560387 | 0.000475029 absolute | PASS |
| ANK-13 | Bates (2010), section 2.1.2 | sample variance | 3.73097 | 3.73091787439614 | 0.000475029 absolute | PASS |
| ANK-13 | Bates (2010), section 2.1.2 | residual variance | 0.30241 | 0.302415458937198 | 0.000475029 absolute | PASS |
| ANK-13 | Bates (2010), section 2.1.2 | plate sd | 0.84671 | 0.8467043241654 | 0.000475029 on variance scale | PASS |
| ANK-13 | Bates (2010), section 2.1.2 | sample sd | 1.93157 | 1.93155840563938 | 0.000475029 on variance scale | PASS |
| ANK-13 | Bates (2010), section 2.1.2 | residual sd | 0.54992 | 0.549923139117821 | 0.000475029 on variance scale | PASS |

### NIST certified quantities

| Anchor | Source | Quantity | Expected | Observed | Tolerance | Result |
|:---|:---|:---|:---|:---|:---|:---|
| ANK-14; ANK-TOL.nist_digits | NIST StRD SiRstv | Residual | 0.010831828 | 0.0108318280000011 | 1.0831828e-10 absolute | PASS |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SiRstv | item | 0.00039094748 | 0.000390947479999821 | 3.9094748e-12 absolute | PASS |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs01 | Residual | 0.01 | 0.01 | 1e-10 absolute | PASS |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs01 | item | 0.00952380952380952 | 0.00952380952380954 | 9.52380952380952e-11 absolute | PASS |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs02 | Residual | 0.01 | 0.01 | 1e-10 absolute | PASS |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs02 | item | 0.0099502487562189 | 0.00995024875621895 | 9.9502487562189e-11 absolute | PASS |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs03 | Residual | 0.01 | 0.00999999999999871 | 1e-10 absolute | PASS |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs03 | item | 0.00999500249875063 | 0.00999500249874934 | 9.99500249875063e-11 absolute | PASS |
| ANK-14; ANK-TOL.nist_digits | NIST StRD AtmWtAg | Residual | 2.28155932971014e-10 | 2.28155932976711e-10 | 2.28155932971014e-18 absolute | PASS |
| ANK-14; ANK-TOL.nist_digits | NIST StRD AtmWtAg | item | 1.42091080917874e-10 | 1.42091080910812e-10 | 1.42091080917874e-18 absolute | PASS |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs04 | Residual | 0.01 | 0.0100000000001543 | LRE \>= aov LRE minus 1 | PASS |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs04 | item | 0.00952380952380952 | 0.00952380952432609 | LRE \>= aov LRE minus 1 | PASS |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs05 | Residual | 0.01 | 0.0100000000005709 | LRE \>= aov LRE minus 1 | PASS |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs05 | item | 0.0099502487562189 | 0.00995024875740476 | LRE \>= aov LRE minus 1 | PASS |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs06 | Residual | 0.01 | 0.0100000000005127 | LRE \>= aov LRE minus 1 | PASS |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs06 | item | 0.00999500249875063 | 0.00999500249990696 | LRE \>= aov LRE minus 1 | PASS |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs07 | Residual | 0.01 | NA | not a criterion | REPORT (higher difficulty) |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs07 | item | 0.00952380952380952 | NA | not a criterion | REPORT (higher difficulty) |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs08 | Residual | 0.01 | NA | not a criterion | REPORT (higher difficulty) |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs08 | item | 0.0099502487562189 | NA | not a criterion | REPORT (higher difficulty) |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs09 | Residual | 0.01 | NA | not a criterion | REPORT (higher difficulty) |
| ANK-14; ANK-TOL.nist_digits | NIST StRD SmLs09 | item | 0.00999500249875063 | NA | not a criterion | REPORT (higher difficulty) |

### GRR formulas and boundary conventions

| Anchor | Source | Quantity | Expected | Observed | Tolerance | Result |
|:---|:---|:---|:---|:---|:---|:---|
| ANK-16 | Independent GRR algebra; constructed components | grr_pct_study_var | 44.5811668553512 | 44.5811668553512 | 1e-10 absolute | PASS |
| ANK-16 | Independent GRR algebra; constructed components | grr_pct_contribution | 19.8748043818466 | 19.8748043818466 | 1e-10 absolute | PASS |
| ANK-16 | Independent GRR algebra; constructed components | repeatability_pct_study_var | 31.6475108851694 | 31.6475108851694 | 1e-10 absolute | PASS |
| ANK-16 | Independent GRR algebra; constructed components | reproducibility_pct_study_var | 31.399291281138 | 31.399291281138 | 1e-10 absolute | PASS |
| ANK-16 | Independent GRR algebra; constructed components | ndc | 2 | 2 | 1e-10 absolute | PASS |
| ANK-16 | Independent GRR algebra; constructed components | icc_items | 0.801251956181534 | 0.801251956181534 | 1e-10 absolute | PASS |
| ANK-16 | AIAG study-variation boundaries | verdict at 10 % | marginal | marginal | exact | PASS |
| ANK-16 | AIAG study-variation boundaries | verdict at 30 % | marginal | marginal | exact | PASS |
| ANK-16 | GRR boundary convention (ADR-017) | zero total ndc | NA | NA | exact | PASS |
| ANK-16 | GRR boundary convention (ADR-017) | zero gauge ndc | Inf | Inf | exact | PASS |
| ANK-16 | GRR boundary convention (ADR-017) | zero item ndc | 1 | 1 | exact | PASS |

### NIST precision report

Item denotes the treatment and replicate denotes the observation within
the treatment. The certified within mean square is the residual
variance; the item reference is the between-minus-within mean-square
difference divided by the number of replicates. NIST labels `AtmWtAg` as
**Average** difficulty; the project nevertheless applies the stricter
relative tolerance 10^{-8} to it, as to the lower-difficulty datasets.

Log relative error (LRE) is the negative base-ten logarithm of the
absolute relative error. Exact agreement gives `Inf`. For `SmLs04`
through `SmLs06`, the required LRE is at least the corresponding
[`stats::aov`](https://rdrr.io/r/stats/aov.html) LRE minus 1. The
higher-difficulty `SmLs07` through `SmLs09` are reports, with no pass
threshold. Low LRE values expose precision loss, including loss in the
original-scale lme4 model despite conditioning the variance-ratio
calculation. `NA` denotes a failed fit whose reason is reported below;
rounded input values are never repaired.

| Dataset | LRE msa_fit residual | LRE msa_fit item | LRE aov residual | LRE aov item |
|:--------|---------------------:|-----------------:|-----------------:|-------------:|
| SmLs04  |             10.81152 |        10.265686 |        10.265517 |     9.895248 |
| SmLs05  |             10.24344 |         9.923803 |        10.286648 |     9.943994 |
| SmLs06  |             10.29010 |         9.936698 |        10.286163 |     9.934862 |
| SmLs07  |                   NA |               NA |         4.284250 |     4.464968 |
| SmLs08  |                   NA |               NA |         3.670185 |     3.921781 |
| SmLs09  |                   NA |               NA |         3.224904 |     3.918561 |

Fit diagnostics:

| Context | Diagnostic |
|:---|:---|
| NIST SmLs07 | Numeric model variance is not representable on the original scale at working precision. |
| NIST SmLs08 | Numeric model variance is not representable on the original scale at working precision. |
| NIST SmLs09 | Numeric model variance is not representable on the original scale at working precision. |

### Reproduction and interpretation

Run `Rscript data-raw/make_validation_numeric.R` from the repository to
reproduce the public inputs offline. The script checks original hashes
before writing; `--out <package-root>` reproduces the files in a
separate directory. The local NIST collection belongs in the sibling
`quellen/daten/` directory, and the protected AIAG sheet at the path
recorded in ANK-10. The installed `validation/numeric/README.md`
explains both build contexts and their checks.

The default numeric fit uses a closed EMS solution for eligible balanced
designs and an analytic REML completion otherwise. Supplying any lme4
argument through `...` selects the direct lme4 path; the ANOVA reference
check uses the optimizer declared by ANK-TOL. The final model retains
the original response scale, observation order and factor labels. Its
components come from `VarCorr()`. Bootstrap refits use ordinary lme4
optimization with the stored refit control; the initial analytic
completion is not repeated per replicate.

Zero total variance makes percentages, ICC and ndc undefined (`NA`),
with verdict `undetermined`. Zero gauge variance with positive item
variance gives infinite ndc; zero item variance with positive gauge
variance gives the lower bound from ANK-16. Constant numeric responses
and a degenerate residual variance produce named errors. These finite
reference checks establish neither bootstrap coverage nor the later
ordinal and binary simulation results.

## Ordinal and binary outcomes (latent scale)

Ordinal
[`msa_fit()`](https://danielmoj.github.io/llmsa/reference/msa_fit.md)
uses cumulative link mixed models and binary
[`msa_fit()`](https://danielmoj.github.io/llmsa/reference/msa_fit.md)
uses binomial mixed models. Variance components, gauge R&R and
`ICC_items` refer to the latent scale. ANK-28 fixes the residual
variance to one for the probit link and to `pi^2 / 3` for the logit
link. In both cases, `ICC_items` is the item variance divided by the sum
of all variance components, including that residual. Gauge R&R includes
every component except the item variance.

All reference values below are read from ANK-21, ANK-25 and ANK-28, with
tolerances from ANK-TOL. The **public** context verifies whole anchor
copies and their SHA-256 manifest under `validation/latent/`. When
`REPO_ROOT` is set, original anchors are also checked and used; an
invalid root or missing input is an error. There is no network access.

### Wine: ordinal components and a separate installation check

The wine comparison maps bottle to item, judge to prompt, with one model
and one replicate. Each link is fitted again with
[`ordinal::clmm`](https://rdrr.io/pkg/ordinal/man/clmm.html) and
[`msa_fit()`](https://danielmoj.github.io/llmsa/reference/msa_fit.md).
The absolute comparison bound is `ANK-TOL.engine_ordinal` times the
direct fit’s total latent variance. The tutorial’s `clmm2` model
includes temperature and contact fixed effects, so its ANK-21 estimates
form a separate installation check, using both Laplace approximation and
quadrature.

| Anchor | Source | Quantity | Expected | Observed | Tolerance | Result |
|:---|:---|:---|:---|:---|:---|:---|
| ANK-TOL.engine_ordinal / ANK-28 | ordinal::clmm on wine; latent residual | logit item | 2.74961 | 2.74961 | 7.24961e-08 | PASS |
| ANK-TOL.engine_ordinal / ANK-28 | ordinal::clmm on wine; latent residual | logit prompt | 1.21013 | 1.21013 | 7.24961e-08 | PASS |
| ANK-TOL.engine_ordinal / ANK-28 | ordinal::clmm on wine; latent residual | logit Residual | 3.28987 | 3.28987 | 7.24961e-08 | PASS |
| ANK-TOL.engine_ordinal / ANK-28 | ordinal::clmm on wine; latent residual | probit item | 0.911033 | 0.911033 | 2.33276e-08 | PASS |
| ANK-TOL.engine_ordinal / ANK-28 | ordinal::clmm on wine; latent residual | probit prompt | 0.421725 | 0.421725 | 2.33276e-08 | PASS |
| ANK-TOL.engine_ordinal / ANK-28 | ordinal::clmm on wine; latent residual | probit Residual | 1 | 1 | 2.33276e-08 | PASS |

| Anchor | Source | Quantity | Expected | Observed | Tolerance | Result |
|:---|:---|:---|:---|:---|:---|:---|
| ANK-21 | Christensen, clmm2 tutorial, pp. 2-3 | laplace judge variance | 1.27946 | 1.27946 | 5e-07 | PASS |
| ANK-21 | Christensen, clmm2 tutorial, pp. 2-3 | nagq10 judge variance | 1.28774 | 1.28774 | 5e-07 | PASS |

### BeetlesMale: binary repeatability and a separate installation check

Population is the item, with one prompt, one model and replicates
numbered within Population. The latent logit `ICC_items` is compared
with live `rptR::rptBinary(expect = "liability")`,
[`performance::icc()`](https://easystats.github.io/performance/reference/icc.html)
on both the direct `glmer` model and the returned model, and the
independent calculation
`variance(Population) / (variance(Population) + pi^2 / 3)` using ANK-28.
These comparisons use `ANK-TOL.rptr.live_tol`.

The published ANK-25 values use rptR’s default `expect = "meanobs"` and
a different scale convention. Both the link and original scale values
are reproduced separately with `ANK-TOL.rptr.vignette_tol`. They are
installation checks, not reference values for `ICC_items`.

| Anchor | Source | Quantity | Expected | Observed | Tolerance | Result |
|:---|:---|:---|:---|:---|:---|:---|
| ANK-28 / ANK-TOL.rptr.live_tol | rptBinary(expect = liability) | ICC_items (latent logit) | 0.223305 | 0.223305 | 1e-06 | PASS |
| ANK-28 / ANK-TOL.rptr.live_tol | performance::icc (direct glmer) | ICC_items (latent logit) | 0.223305 | 0.223305 | 1e-06 | PASS |
| ANK-28 / ANK-TOL.rptr.live_tol | performance::icc (msa_fit model) | ICC_items (latent logit) | 0.223305 | 0.223305 | 1e-06 | PASS |
| ANK-28 / ANK-TOL.rptr.live_tol | Population / (Population + ANK-28 residual) | ICC_items (latent logit) | 0.223305 | 0.223305 | 1e-06 | PASS |

| Anchor | Source | Quantity | Expected | Observed | Tolerance | Result |
|:---|:---|:---|:---|:---|:---|:---|
| ANK-25 / ANK-TOL.rptr.vignette_tol | rptR vignette, rep10; default expect = meanobs | R_link | 0.188 | 0.187939 | 5e-04 | PASS |
| ANK-25 / ANK-TOL.rptr.vignette_tol | rptR vignette, rep10; default expect = meanobs | R_org | 0.185 | 0.185407 | 5e-04 | PASS |

### Simulation recovery and two-level factors

The following tables read the installed studies’ `<study>_results.csv`
if it exists, otherwise `<study>_check_results.csv`. An invalid existing
full result file stops the build. The displayed `n_sim` comes from each
file. Knitting does not run simulations. Bias, relative bias, empirical
standard error (EmpSE) and root mean squared error (RMSE) each have a
Monte Carlo standard error (MCSE); the tables retain significant digits
for small estimates. `n_finite` and `n_failed` count the usable and
missing estimates separately. Finite estimates with non-convergence or
singularity are retained, with the diagnoses recorded in the replicate
and session files.

Short runs check reproducibility and file structure. They do not
establish quantitative recovery or bias findings. Full runs require at
least 1000 repetitions per scenario, according to ANK-06, and are
performed separately by the operator after acceptance. The installed
`validation/sim/README.md` gives executable full-run and
scenario-merging instructions, the ADEMP design, MCSE formulas and
failure handling. The random stream for each scenario and repetition is
independent of the requested run length and worker count.

For ordinal fits, a prompt, model or block with exactly two levels
enters as a fixed effect. Its component is the squared fitted difference
divided by two, `beta-hat^2 / 2`, marked in `attr(fit$vc, "derived")`
and in
[`msa_grr()`](https://danielmoj.github.io/llmsa/reference/msa_grr.md).
This range method does not subtract the AIAG correction
`EV^2 / (n * r)`. Its bias is positive:
`E[beta-hat^2 / 2] = sigma^2 + Var(beta-hat) / 2`. Every such fit warns,
and printing names each derived component with
`range method, see ?msa_fit`. The `two_level` study redraws both model
effects in every repetition and reports `derived_share`, the fraction of
repetitions with a derived model component. It measures this bias;
quantitative conclusions await the full runs. Fewer than three ordinal
items are rejected.

### ordinal_recovery

Read `ordinal_recovery_check_results.csv` (check); n_sim = 20 per
scenario.

S-ord-1

| scenario | estimand | measure | value | mcse | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-ord-1 | grr_pct_study_var | bias | -1.60014 | 0.711695 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | grr_pct_study_var | empse | 3.1828 | 0.516318 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | grr_pct_study_var | rel_bias | -0.0214969 | 0.00956119 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | grr_pct_study_var | rmse | 3.49058 | 0.356059 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | icc_items | bias | 0.0226031 | 0.0105137 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | icc_items | empse | 0.0470188 | 0.00762745 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | icc_items | rel_bias | 0.0506875 | 0.023577 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | icc_items | rmse | 0.0510992 | 0.00504297 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | item | bias | 0.0754422 | 0.0393165 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | item | empse | 0.175829 | 0.0285232 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | item | rel_bias | 0.0754422 | 0.0393165 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | item | rmse | 0.187247 | 0.0186655 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | item:model | bias | -0.00174148 | 0.00664729 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | item:model | empse | 0.0297276 | 0.00482245 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | item:model | rel_bias | -0.0193498 | 0.0738588 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | item:model | rmse | 0.0290272 | 0.00409706 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | model | bias | -0.0296065 | 0.010379 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | model | empse | 0.0464164 | 0.00752973 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | model | rel_bias | -0.328962 | 0.115322 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | model | rmse | 0.0540676 | 0.00589925 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | prompt | bias | -0.0123624 | 0.0120677 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | prompt | empse | 0.0539686 | 0.00875486 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | prompt | rel_bias | -0.197799 | 0.193084 | 20 | 20261032 | 20 | 0 |
| S-ord-1 | prompt | rmse | 0.0540353 | 0.00930249 | 20 | 20261032 | 20 | 0 |

S-ord-2

| scenario | estimand | measure | value | mcse | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-ord-2 | grr_pct_study_var | bias | -0.0944099 | 0.685094 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | grr_pct_study_var | empse | 3.06384 | 0.49702 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | grr_pct_study_var | rel_bias | -0.00126834 | 0.00920383 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | grr_pct_study_var | rmse | 2.98775 | 0.382961 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | icc_items | bias | 0.000512831 | 0.0102256 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | icc_items | empse | 0.0457301 | 0.00741841 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | icc_items | rel_bias | 0.00115002 | 0.0229308 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | icc_items | rmse | 0.0445752 | 0.00585203 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | item | bias | 0.0140555 | 0.0380336 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | item | empse | 0.170092 | 0.0275925 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | item | rel_bias | 0.0140555 | 0.0380336 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | item | rmse | 0.166379 | 0.0250801 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | item:model | bias | 0.00939742 | 0.00562271 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | item:model | empse | 0.0251455 | 0.00407914 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | item:model | rel_bias | 0.104416 | 0.0624746 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | item:model | rmse | 0.0262487 | 0.00349605 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | model | bias | -0.0148265 | 0.0158959 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | model | empse | 0.0710886 | 0.0115321 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | model | rel_bias | -0.164738 | 0.176621 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | model | rmse | 0.0708571 | 0.0176252 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | prompt | bias | 0.00162025 | 0.00814046 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | prompt | empse | 0.0364052 | 0.00590571 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | prompt | rel_bias | 0.0259241 | 0.130247 | 20 | 20261033 | 20 | 0 |
| S-ord-2 | prompt | rmse | 0.0355204 | 0.00518874 | 20 | 20261033 | 20 | 0 |

S-ord-3

| scenario | estimand | measure | value | mcse | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-ord-3 | grr_pct_study_var | bias | -1.02627 | 1.0359 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | grr_pct_study_var | empse | 4.63269 | 0.751521 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | grr_pct_study_var | rel_bias | -0.0179535 | 0.0181219 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | grr_pct_study_var | rmse | 4.63055 | 0.790158 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | icc_items | bias | 0.00958872 | 0.0116915 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | icc_items | empse | 0.0522861 | 0.00848192 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | icc_items | rel_bias | 0.0142426 | 0.017366 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | icc_items | rmse | 0.0518564 | 0.00842987 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | item | bias | 0.151376 | 0.13008 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | item | empse | 0.581734 | 0.0943696 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | item | rel_bias | 0.0591312 | 0.0508123 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | item | rmse | 0.586863 | 0.129229 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | item:model | bias | 0.00923075 | 0.00716217 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | item:model | empse | 0.0320302 | 0.00519598 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | item:model | rel_bias | 0.102564 | 0.0795796 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | item:model | rmse | 0.0325552 | 0.00710468 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | model | bias | -0.0246332 | 0.0107356 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | model | empse | 0.0480112 | 0.00778845 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | model | rel_bias | -0.273702 | 0.119285 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | model | rmse | 0.0528831 | 0.00580126 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | prompt | bias | -0.010234 | 0.0178925 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | prompt | empse | 0.0800177 | 0.0129806 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | prompt | rel_bias | -0.163743 | 0.28628 | 20 | 20261034 | 20 | 0 |
| S-ord-3 | prompt | rmse | 0.0786602 | 0.0240599 | 20 | 20261034 | 20 | 0 |

S-ord-4

| scenario | estimand | measure | value | mcse | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-ord-4 | block | bias | -0.0042175 | 0.00192327 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | block | empse | 0.00860111 | 0.00139529 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | block | rel_bias | -0.42175 | 0.192327 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | block | rmse | 0.00938443 | 0.00104742 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | grr_pct_study_var | bias | -0.423974 | 0.474589 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | grr_pct_study_var | empse | 2.12242 | 0.344303 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | grr_pct_study_var | rel_bias | -0.00568569 | 0.00636445 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | grr_pct_study_var | rmse | 2.11168 | 0.301264 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | icc_items | bias | 0.00587712 | 0.00699567 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | icc_items | empse | 0.0312856 | 0.00507519 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | icc_items | rel_bias | 0.0132382 | 0.0157577 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | icc_items | rmse | 0.0310546 | 0.00429559 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | item | bias | 0.00296626 | 0.0317555 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | item | empse | 0.142015 | 0.0230378 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | item | rel_bias | 0.00296626 | 0.0317555 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | item | rmse | 0.138451 | 0.0116007 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | item:model | bias | 0.00605085 | 0.00444423 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | item:model | empse | 0.0198752 | 0.00322418 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | item:model | rel_bias | 0.0672317 | 0.0493803 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | item:model | rmse | 0.020295 | 0.00316686 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | model | bias | -0.0310599 | 0.0122835 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | model | empse | 0.0549337 | 0.00891141 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | model | rel_bias | -0.34511 | 0.136484 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | model | rmse | 0.0618994 | 0.0051961 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | prompt | bias | -0.00597937 | 0.0117696 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | prompt | empse | 0.0526352 | 0.00853856 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | prompt | rel_bias | -0.0956699 | 0.188314 | 20 | 20261035 | 20 | 0 |
| S-ord-4 | prompt | rmse | 0.0516498 | 0.0111695 | 20 | 20261035 | 20 | 0 |

### binary_recovery

Read `binary_recovery_check_results.csv` (check); n_sim = 20 per
scenario.

S-bin-1

| scenario | estimand | measure | value | mcse | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-bin-1 | grr_pct_study_var | bias | 0.315625 | 0.521246 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | grr_pct_study_var | empse | 2.33108 | 0.378151 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | grr_pct_study_var | rel_bias | 0.00358 | 0.00591228 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | grr_pct_study_var | rmse | 2.29387 | 0.432681 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | icc_items | bias | -0.00609149 | 0.00907252 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | icc_items | empse | 0.0405736 | 0.0065819 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | icc_items | rel_bias | -0.02735 | 0.0407344 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | icc_items | rmse | 0.0400126 | 0.00721893 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | item | bias | -0.0394916 | 0.0530328 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | item | empse | 0.23717 | 0.038474 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | item | rel_bias | -0.0394916 | 0.0530328 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | item | rmse | 0.234514 | 0.0434241 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | model | bias | -0.010361 | 0.0175846 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | model | empse | 0.0786406 | 0.0127572 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | model | rel_bias | -0.10361 | 0.175846 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | model | rmse | 0.0773465 | 0.0105884 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | prompt | bias | -0.0424848 | 0.0158788 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | prompt | empse | 0.071012 | 0.0115197 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | prompt | rel_bias | -0.424848 | 0.158788 | 20 | 20261036 | 20 | 0 |
| S-bin-1 | prompt | rmse | 0.0812128 | 0.0127067 | 20 | 20261036 | 20 | 0 |

S-bin-2

| scenario | estimand | measure | value | mcse | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-bin-2 | grr_pct_study_var | bias | 0.861103 | 0.429551 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | grr_pct_study_var | empse | 1.92101 | 0.311629 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | grr_pct_study_var | rel_bias | 0.00976714 | 0.00487222 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | grr_pct_study_var | rmse | 2.06089 | 0.248095 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | icc_items | bias | -0.0156083 | 0.00761306 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | icc_items | empse | 0.0340466 | 0.00552309 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | icc_items | rel_bias | -0.070079 | 0.0341816 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | icc_items | rmse | 0.0366719 | 0.00447617 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | item | bias | -0.0775956 | 0.0463165 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | item | empse | 0.207134 | 0.0336015 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | item | rel_bias | -0.0775956 | 0.0463165 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | item | rmse | 0.216287 | 0.0266694 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | model | bias | 0.00444142 | 0.0190782 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | model | empse | 0.0853202 | 0.0138408 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | model | rel_bias | 0.0444142 | 0.190782 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | model | rmse | 0.0832784 | 0.0118567 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | prompt | bias | -0.00125623 | 0.0124714 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | prompt | empse | 0.0557739 | 0.00904772 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | prompt | rel_bias | -0.0125623 | 0.124714 | 20 | 20261037 | 20 | 0 |
| S-bin-2 | prompt | rmse | 0.0543762 | 0.00743376 | 20 | 20261037 | 20 | 0 |

### two_level

Read `two_level_check_results.csv` (check); n_sim = 20 per scenario.

S-two-1

| scenario | estimand | measure | value | mcse | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-two-1 | grr_pct_study_var | bias | -0.116698 | 0.832751 | 20 | 20261038 | 20 | 0 |
| S-two-1 | grr_pct_study_var | empse | 3.72418 | 0.604141 | 20 | 20261038 | 20 | 0 |
| S-two-1 | grr_pct_study_var | rel_bias | -0.00160809 | 0.0114753 | 20 | 20261038 | 20 | 0 |
| S-two-1 | grr_pct_study_var | rmse | 3.63175 | 0.616356 | 20 | 20261038 | 20 | 0 |
| S-two-1 | icc_items | bias | 0.000374763 | 0.0120577 | 20 | 20261038 | 20 | 0 |
| S-two-1 | icc_items | empse | 0.0539235 | 0.00874755 | 20 | 20261038 | 20 | 0 |
| S-two-1 | icc_items | rel_bias | 0.000791687 | 0.0254718 | 20 | 20261038 | 20 | 0 |
| S-two-1 | icc_items | rmse | 0.0525595 | 0.00883198 | 20 | 20261038 | 20 | 0 |
| S-two-1 | item | bias | 0.0150272 | 0.0514879 | 20 | 20261038 | 20 | 0 |
| S-two-1 | item | empse | 0.230261 | 0.0373532 | 20 | 20261038 | 20 | 0 |
| S-two-1 | item | rel_bias | 0.0150272 | 0.0514879 | 20 | 20261038 | 20 | 0 |
| S-two-1 | item | rmse | 0.224933 | 0.0416088 | 20 | 20261038 | 20 | 0 |
| S-two-1 | model | bias | -0.0190145 | 0.00632065 | 20 | 20261038 | 20 | 0 |
| S-two-1 | model | derived_share | 1 | 0 | 20 | 20261038 | 20 | 0 |
| S-two-1 | model | empse | 0.0282668 | 0.00458548 | 20 | 20261038 | 20 | 0 |
| S-two-1 | model | rel_bias | -0.38029 | 0.126413 | 20 | 20261038 | 20 | 0 |
| S-two-1 | model | rmse | 0.0334756 | 0.00304835 | 20 | 20261038 | 20 | 0 |
| S-two-1 | prompt | bias | 0.0120594 | 0.0168329 | 20 | 20261038 | 20 | 0 |
| S-two-1 | prompt | empse | 0.0752792 | 0.0122119 | 20 | 20261038 | 20 | 0 |
| S-two-1 | prompt | rel_bias | 0.192951 | 0.269327 | 20 | 20261038 | 20 | 0 |
| S-two-1 | prompt | rmse | 0.0743575 | 0.0228065 | 20 | 20261038 | 20 | 0 |

S-two-2

| scenario | estimand | measure | value | mcse | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-two-2 | grr_pct_study_var | bias | 0.357786 | 1.25069 | 20 | 20261039 | 20 | 0 |
| S-two-2 | grr_pct_study_var | empse | 5.59328 | 0.907349 | 20 | 20261039 | 20 | 0 |
| S-two-2 | grr_pct_study_var | rel_bias | 0.00474914 | 0.0166013 | 20 | 20261039 | 20 | 0 |
| S-two-2 | grr_pct_study_var | rmse | 5.46338 | 0.871625 | 20 | 20261039 | 20 | 0 |
| S-two-2 | icc_items | bias | -0.00837576 | 0.0184708 | 20 | 20261039 | 20 | 0 |
| S-two-2 | icc_items | empse | 0.0826037 | 0.0134001 | 20 | 20261039 | 20 | 0 |
| S-two-2 | icc_items | rel_bias | -0.019369 | 0.0427136 | 20 | 20261039 | 20 | 0 |
| S-two-2 | icc_items | rmse | 0.0809467 | 0.0120348 | 20 | 20261039 | 20 | 0 |
| S-two-2 | item | bias | 0.00342284 | 0.0667114 | 20 | 20261039 | 20 | 0 |
| S-two-2 | item | empse | 0.298342 | 0.0483975 | 20 | 20261039 | 20 | 0 |
| S-two-2 | item | rel_bias | 0.00342284 | 0.0667114 | 20 | 20261039 | 20 | 0 |
| S-two-2 | item | rmse | 0.290808 | 0.0492361 | 20 | 20261039 | 20 | 0 |
| S-two-2 | model | bias | 0.0964696 | 0.113807 | 20 | 20261039 | 20 | 0 |
| S-two-2 | model | derived_share | 1 | 0 | 20 | 20261039 | 20 | 0 |
| S-two-2 | model | empse | 0.508959 | 0.0825641 | 20 | 20261039 | 20 | 0 |
| S-two-2 | model | rel_bias | 0.385878 | 0.455227 | 20 | 20261039 | 20 | 0 |
| S-two-2 | model | rmse | 0.505365 | 0.162341 | 20 | 20261039 | 20 | 0 |
| S-two-2 | prompt | bias | -0.0235224 | 0.00614518 | 20 | 20261039 | 20 | 0 |
| S-two-2 | prompt | empse | 0.0274821 | 0.00445818 | 20 | 20261039 | 20 | 0 |
| S-two-2 | prompt | rel_bias | -0.376358 | 0.0983228 | 20 | 20261039 | 20 | 0 |
| S-two-2 | prompt | rmse | 0.0356483 | 0.00382582 | 20 | 20261039 | 20 | 0 |

## Bootstrap intervals: coverage by scenario

This section reads **boot_coverage_check_results.csv** (**check** run),
with **n_sim = 20** repetitions per scenario. The installed
`boot_coverage_results.csv` takes precedence over
`boot_coverage_check_results.csv`. An invalid existing full result stops
the build. Knitting reads the results and starts neither simulations nor
downloads.

The study evaluates the existing 95% percentile intervals from
[`msa_boot()`](https://danielmoj.github.io/llmsa/reference/msa_boot.md)
for gauge R&R study variation and contribution, ndc and item ICC. Every
outer repetition generates a new crossed study and uses the package’s
default number of parametric bootstrap refits. Numeric scenarios include
all three pairwise interactions; the binary logit scenario uses item,
prompt and model effects. The installed `validation/sim/README.md`
specifies the designs, seeds, Monte Carlo standard errors (MCSE),
diagnostics and reproduction commands.

Coverage is the fraction of finite closed intervals containing the true
value; width is their mean width. Their `n_finite` and `n_failed` count
available and unavailable outer repetitions. For bootstrap diagnostics,
the unit of analysis is also the outer repetition: each contributes its
fraction of singular or failed refits, and MCSE is the standard error of
the mean of those fractions. Singular refits with finite statistics
remain in the intervals. Only non-finite values are omitted, separately
for each statistic. The diagnostics count a replicate with any
non-finite statistic as failed and do not also count it as singular.

Short runs establish reproducibility and file structure. They do not
establish nominal coverage. Full runs require at least 1000 repetitions
per scenario (ANK-06) and follow code acceptance. Undercoverage or
overcoverage in those runs is a finding to report, with MCSE, rather
than a reason to alter intervals.

### S-boot-1

| scenario | estimand | measure | value | MCSE | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-boot-1 | block | bias | -0.00243875 | 0.00245516 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | block | empse | 0.0109798 | 0.00178116 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | block | rel_bias | -0.243875 | 0.245516 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | block | rmse | 0.0109762 | 0.00223694 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | bootstrap | failed_share | 0 | 0 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | bootstrap | singular_share | 0.54275 | 0.0461169 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | grr_pct_contribution | bias | 2.47055 | 1.56201 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | grr_pct_contribution | coverage | 1 | 0 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | grr_pct_contribution | empse | 6.98552 | 1.1332 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | grr_pct_contribution | rel_bias | 0.114544 | 0.0724204 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | grr_pct_contribution | rmse | 7.24301 | 0.957301 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | grr_pct_contribution | width | 32.5402 | 2.15083 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | grr_pct_study_var | bias | 2.0487 | 1.66332 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | grr_pct_study_var | coverage | 1 | 0 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | grr_pct_study_var | empse | 7.43862 | 1.2067 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | grr_pct_study_var | rel_bias | 0.044113 | 0.0358151 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | grr_pct_study_var | rmse | 7.53416 | 0.955832 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | grr_pct_study_var | width | 31.7426 | 1.3029 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | icc_items | bias | -0.0247055 | 0.0156201 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | icc_items | coverage | 1 | 0 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | icc_items | empse | 0.0698552 | 0.011332 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | icc_items | rel_bias | -0.0314995 | 0.0199156 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | icc_items | rmse | 0.0724301 | 0.00957301 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | icc_items | width | 0.325402 | 0.0215083 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | item | bias | -0.0116218 | 0.0849496 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | item | empse | 0.379906 | 0.0616289 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | item | rel_bias | -0.0116218 | 0.0849496 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | item | rmse | 0.370469 | 0.0607066 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | item:model | bias | -0.00167901 | 0.00182315 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | item:model | empse | 0.00815339 | 0.00132265 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | item:model | rel_bias | -0.0335803 | 0.0364631 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | item:model | rmse | 0.00812238 | 0.00127238 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | item:prompt | bias | 0.00151534 | 0.000769449 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | item:prompt | empse | 0.00344108 | 0.000558217 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | item:prompt | rel_bias | 0.151534 | 0.0769449 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | item:prompt | rmse | 0.00368039 | 0.000599867 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | model | bias | 0.0156247 | 0.0125608 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | model | empse | 0.0561736 | 0.00911255 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | model | rel_bias | 0.312495 | 0.251216 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | model | rmse | 0.0569371 | 0.0133628 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | ndc | bias | 0.2 | 0.155597 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | ndc | coverage | 1 | 0 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | ndc | empse | 0.695852 | 0.112882 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | ndc | rel_bias | 0.1 | 0.0777987 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | ndc | rmse | 0.707107 | 0.149561 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | ndc | width | 2.45 | 0.135239 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | prompt | bias | 0.00398593 | 0.0155439 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | prompt | empse | 0.0695143 | 0.0112767 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | prompt | rel_bias | 0.0797186 | 0.310877 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | prompt | rmse | 0.0678713 | 0.0228476 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | prompt:model | bias | -0.000431477 | 0.000559923 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | prompt:model | empse | 0.00250405 | 0.000406211 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | prompt:model | rel_bias | -0.0862954 | 0.111985 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | prompt:model | rmse | 0.0024785 | 0.000273847 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | Residual | bias | -0.00119011 | 0.0010499 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | Residual | empse | 0.0046953 | 0.000761678 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | Residual | rel_bias | -0.0119011 | 0.010499 | 20 | 20261102 | 20 | 0 |
| S-boot-1 | Residual | rmse | 0.00472863 | 0.000752154 | 20 | 20261102 | 20 | 0 |

### S-boot-7

| scenario | estimand | measure | value | MCSE | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-boot-7 | bootstrap | failed_share | 0 | 0 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | bootstrap | singular_share | 0.40525 | 0.0452107 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | grr_pct_contribution | bias | -1.30443 | 0.574513 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | grr_pct_contribution | coverage | 1 | 0 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | grr_pct_contribution | empse | 2.5693 | 0.416795 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | grr_pct_contribution | rel_bias | -0.016782 | 0.00739136 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | grr_pct_contribution | rmse | 2.82361 | 0.353205 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | grr_pct_contribution | width | 15.8579 | 0.309403 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | grr_pct_study_var | bias | -0.754533 | 0.327053 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | grr_pct_study_var | coverage | 1 | 0 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | grr_pct_study_var | empse | 1.46262 | 0.237269 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | grr_pct_study_var | rel_bias | -0.00855836 | 0.00370963 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | grr_pct_study_var | rmse | 1.61296 | 0.203601 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | grr_pct_study_var | width | 9.11023 | 0.206417 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | icc_items | bias | 0.0130443 | 0.00574513 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | icc_items | coverage | 1 | 0 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | icc_items | empse | 0.025693 | 0.00416795 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | icc_items | rel_bias | 0.058567 | 0.0257949 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | icc_items | rmse | 0.0282361 | 0.00353205 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | icc_items | width | 0.158579 | 0.00309403 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | item | bias | 0.0600002 | 0.0345138 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | item | empse | 0.15435 | 0.0250389 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | item | rel_bias | 0.0600002 | 0.0345138 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | item | rmse | 0.161966 | 0.0262237 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | model | bias | -0.0353384 | 0.0155519 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | model | empse | 0.0695503 | 0.0112825 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | model | rel_bias | -0.353384 | 0.155519 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | model | rmse | 0.0764473 | 0.00823782 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | ndc | bias | 0 | 0 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | ndc | coverage | 1 | 0 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | ndc | empse | 0 | 0 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | ndc | rel_bias | 0 | 0 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | ndc | rmse | 0 | 0 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | ndc | width | 0 | 0 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | prompt | bias | -0.0347613 | 0.0132451 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | prompt | empse | 0.059234 | 0.00960903 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | prompt | rel_bias | -0.347613 | 0.132451 | 20 | 20261114 | 20 | 0 |
| S-boot-7 | prompt | rmse | 0.0673913 | 0.00774171 | 20 | 20261114 | 20 | 0 |
