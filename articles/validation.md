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
| ANK-TOL.reml_anova | Independent stats::aov EMS solution | Synthetic design 2 (seed 1) model | 0.00163326075749218 | 0.00163326845691075 | 0.000119652855913307 absolute | PASS |
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
| ANK-TOL.oracle | SixSigma::ss.rr, unrounded StdDev | Reproducibility % study variation | 8.1557618547825 | 8.15576186968176 | 0.00081557618547825 absolute | PASS |
| ANK-TOL.oracle | SixSigma::ss.rr, unrounded StdDev | prompt % study variation | 8.1557618547825 | 8.15576186968176 | 0.00081557618547825 absolute | PASS |
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
| SmLs04  |             10.81152 |        10.265686 |        10.286173 |    10.043134 |
| SmLs05  |             10.24344 |         9.923803 |        10.286173 |     9.943746 |
| SmLs06  |             10.29010 |         9.936698 |        10.286172 |     9.934948 |
| SmLs07  |                   NA |               NA |         4.250358 |     4.022777 |
| SmLs08  |                   NA |               NA |         3.670512 |     3.922443 |
| SmLs09  |                   NA |               NA |         3.224860 |     3.914684 |

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
repetitions with a derived model component. The full-run tables below
report its measured bias and MCSE in each scenario. A bias that does not
exceed the reporting threshold does not establish general unbiasedness.
Fewer than three ordinal items are rejected.

Component findings use ANK-TOL.bias_report: the absolute relative bias
must exceed both 0.1 and 3 times its MCSE. The two-level model bias is
always reported; its direction is resolved only beyond 3 MCSE. These are
reporting rules, not acceptance criteria for the estimates. Full-run
findings are computed from the read tables, never selected by scenario
name.

### ordinal_recovery

Read `ordinal_recovery_results.csv` (full); n_sim = 1000 per scenario.

S-ord-1

| scenario | estimand | measure | value | mcse | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-ord-1 | grr_pct_study_var | bias | -0.125273 | 0.110754 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | grr_pct_study_var | empse | 3.50234 | 0.0783538 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | grr_pct_study_var | rel_bias | -0.00168297 | 0.00148791 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | grr_pct_study_var | rmse | 3.50283 | 0.0767646 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | icc_items | bias | 0.000637983 | 0.00165117 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | icc_items | empse | 0.0522147 | 0.00116814 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | icc_items | rel_bias | 0.00143068 | 0.00370276 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | icc_items | rmse | 0.0521925 | 0.00116872 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | item | bias | 0.00395243 | 0.00635032 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | item | empse | 0.200815 | 0.0044926 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | item | rel_bias | 0.00395243 | 0.00635032 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | item | rmse | 0.200753 | 0.00435086 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | item:model | bias | 0.00211939 | 0.000972256 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | item:model | empse | 0.0307454 | 0.000687833 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | item:model | rel_bias | 0.0235487 | 0.0108028 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | item:model | rmse | 0.030803 | 0.000724317 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | model | bias | -0.0181983 | 0.00227219 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | model | empse | 0.0718531 | 0.00160749 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | model | rel_bias | -0.202203 | 0.0252466 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | model | rmse | 0.074087 | 0.00212371 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | prompt | bias | -0.00952569 | 0.00165618 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | prompt | empse | 0.052373 | 0.00117168 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | prompt | rel_bias | -0.152411 | 0.0264989 | 1000 | 20261032 | 1000 | 0 |
| S-ord-1 | prompt | rmse | 0.0532065 | 0.00180531 | 1000 | 20261032 | 1000 | 0 |

S-ord-2

| scenario | estimand | measure | value | mcse | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-ord-2 | grr_pct_study_var | bias | 0.0347232 | 0.113032 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | grr_pct_study_var | empse | 3.57438 | 0.0799656 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | grr_pct_study_var | rel_bias | 0.000466485 | 0.00151851 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | grr_pct_study_var | rmse | 3.57276 | 0.0774861 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | icc_items | bias | -0.00179339 | 0.00168449 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | icc_items | empse | 0.0532684 | 0.00119171 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | icc_items | rel_bias | -0.00402168 | 0.00377748 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | icc_items | rmse | 0.0532719 | 0.00116873 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | item | bias | -0.0016251 | 0.0064879 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | item | empse | 0.205165 | 0.00458993 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | item | rel_bias | -0.0016251 | 0.0064879 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | item | rmse | 0.205069 | 0.00483422 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | item:model | bias | 0.00160385 | 0.000717591 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | item:model | empse | 0.0226922 | 0.000507667 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | item:model | rel_bias | 0.0178205 | 0.00797323 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | item:model | rmse | 0.0227375 | 0.000498283 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | model | bias | -0.0168554 | 0.00230711 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | model | empse | 0.0729573 | 0.00163219 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | model | rel_bias | -0.187283 | 0.0256346 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | model | rmse | 0.0748435 | 0.0027447 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | prompt | bias | -0.00435936 | 0.0012259 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | prompt | empse | 0.0387663 | 0.000867275 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | prompt | rel_bias | -0.0697498 | 0.0196144 | 1000 | 20261033 | 1000 | 0 |
| S-ord-2 | prompt | rmse | 0.0389914 | 0.000974564 | 1000 | 20261033 | 1000 | 0 |

S-ord-3

| scenario | estimand | measure | value | mcse | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-ord-3 | grr_pct_study_var | bias | 0.168115 | 0.129819 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | grr_pct_study_var | empse | 4.10523 | 0.0918417 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | grr_pct_study_var | rel_bias | 0.00294099 | 0.00227104 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | grr_pct_study_var | rmse | 4.10662 | 0.0938126 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | icc_items | bias | -0.00360842 | 0.00150216 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | icc_items | empse | 0.0475026 | 0.00106272 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | icc_items | rel_bias | -0.00535977 | 0.00223124 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | icc_items | rmse | 0.0476158 | 0.00117126 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | item | bias | -0.000680181 | 0.0161926 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | item | empse | 0.512054 | 0.0114556 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | item | rel_bias | -0.000265696 | 0.00632523 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | item | rmse | 0.511799 | 0.0120317 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | item:model | bias | 0.00179274 | 0.00103592 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | item:model | empse | 0.0327587 | 0.000732873 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | item:model | rel_bias | 0.0199194 | 0.0115102 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | item:model | rmse | 0.0327913 | 0.000729274 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | model | bias | -0.0153654 | 0.00224351 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | model | empse | 0.0709461 | 0.0015872 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | model | rel_bias | -0.170727 | 0.0249279 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | model | rmse | 0.0725563 | 0.00207564 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | prompt | bias | -0.0068387 | 0.00179576 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | prompt | empse | 0.056787 | 0.00127043 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | prompt | rel_bias | -0.109419 | 0.0287322 | 1000 | 20261034 | 1000 | 0 |
| S-ord-3 | prompt | rmse | 0.0571691 | 0.00226492 | 1000 | 20261034 | 1000 | 0 |

S-ord-4

| scenario | estimand | measure | value | mcse | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-ord-4 | block | bias | 0.000995367 | 0.000451907 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | block | empse | 0.0142906 | 0.000319707 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | block | rel_bias | 0.0995367 | 0.0451907 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | block | rmse | 0.0143181 | 0.000619793 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | grr_pct_study_var | bias | -0.286697 | 0.0879519 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | grr_pct_study_var | empse | 2.78128 | 0.0622225 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | grr_pct_study_var | rel_bias | -0.00384474 | 0.00117947 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | grr_pct_study_var | rmse | 2.79464 | 0.0601791 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | icc_items | bias | 0.00349472 | 0.00130511 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | icc_items | empse | 0.0412713 | 0.000923317 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | icc_items | rel_bias | 0.00787186 | 0.00293977 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | icc_items | rmse | 0.0413985 | 0.000876557 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | item | bias | -0.00139942 | 0.00487517 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | item | empse | 0.154166 | 0.00344899 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | item | rel_bias | -0.00139942 | 0.00487517 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | item | rmse | 0.154096 | 0.00355198 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | item:model | bias | 6.53399e-05 | 0.0005059 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | item:model | empse | 0.015998 | 0.000357905 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | item:model | rel_bias | 0.000725999 | 0.00562112 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | item:model | rmse | 0.0159901 | 0.000364165 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | model | bias | -0.0210329 | 0.00217048 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | model | empse | 0.0686366 | 0.00153553 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | model | rel_bias | -0.233699 | 0.0241164 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | model | rmse | 0.0717541 | 0.00228411 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | prompt | bias | -0.0124167 | 0.00150468 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | prompt | empse | 0.0475823 | 0.0010645 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | prompt | rel_bias | -0.198667 | 0.0240749 | 1000 | 20261035 | 1000 | 0 |
| S-ord-4 | prompt | rmse | 0.0491526 | 0.00138499 | 1000 | 20261035 | 1000 | 0 |

Reportable findings (values and MCSE on the stated measure’s scale):

| scenario | estimand | measure  | value     | mcse      | direction       |
|:---------|:---------|:---------|:----------|:----------|:----------------|
| S-ord-1  | model    | rel_bias | -0.202203 | 0.0252466 | underestimation |
| S-ord-1  | prompt   | rel_bias | -0.152411 | 0.0264989 | underestimation |
| S-ord-2  | model    | rel_bias | -0.187283 | 0.0256346 | underestimation |
| S-ord-3  | model    | rel_bias | -0.170727 | 0.0249279 | underestimation |
| S-ord-3  | prompt   | rel_bias | -0.109419 | 0.0287322 | underestimation |
| S-ord-4  | model    | rel_bias | -0.233699 | 0.0241164 | underestimation |
| S-ord-4  | prompt   | rel_bias | -0.198667 | 0.0240749 | underestimation |

### binary_recovery

Read `binary_recovery_results.csv` (full); n_sim = 1000 per scenario.

S-bin-1

| scenario | estimand | measure | value | mcse | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-bin-1 | grr_pct_study_var | bias | -0.00921081 | 0.0766766 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | grr_pct_study_var | empse | 2.42473 | 0.0542457 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | grr_pct_study_var | rel_bias | -0.000104475 | 0.000869711 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | grr_pct_study_var | rmse | 2.42353 | 0.0554421 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | icc_items | bias | -0.000424939 | 0.00134707 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | icc_items | empse | 0.0425981 | 0.000953 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | icc_items | rel_bias | -0.00190792 | 0.00604817 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | icc_items | rmse | 0.042579 | 0.000947994 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | item | bias | -0.0024475 | 0.00781291 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | item | empse | 0.247066 | 0.00552733 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | item | rel_bias | -0.0024475 | 0.00781291 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | item | rmse | 0.246955 | 0.00653193 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | model | bias | -0.0223711 | 0.00254839 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | model | empse | 0.080587 | 0.00180288 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | model | rel_bias | -0.223711 | 0.0254839 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | model | rmse | 0.0835957 | 0.00261557 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | prompt | bias | -0.0213736 | 0.00268401 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | prompt | empse | 0.0848759 | 0.00189883 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | prompt | rel_bias | -0.213736 | 0.0268401 | 1000 | 20261036 | 1000 | 0 |
| S-bin-1 | prompt | rmse | 0.0874845 | 0.00408693 | 1000 | 20261036 | 1000 | 0 |

S-bin-2

| scenario | estimand | measure | value | mcse | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-bin-2 | grr_pct_study_var | bias | 0.122293 | 0.0697509 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | grr_pct_study_var | empse | 2.20572 | 0.049346 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | grr_pct_study_var | rel_bias | 0.00138711 | 0.000791156 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | grr_pct_study_var | rmse | 2.208 | 0.04854 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | icc_items | bias | -0.00264387 | 0.00122904 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | icc_items | empse | 0.0388658 | 0.000869501 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | icc_items | rel_bias | -0.0118706 | 0.00551825 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | icc_items | rmse | 0.0389362 | 0.000849537 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | item | bias | -0.0122441 | 0.00713126 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | item | empse | 0.22551 | 0.00504508 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | item | rel_bias | -0.0122441 | 0.00713126 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | item | rmse | 0.22573 | 0.00512394 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | model | bias | -0.0204216 | 0.00246023 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | model | empse | 0.0777992 | 0.00174051 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | model | rel_bias | -0.204216 | 0.0246023 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | model | rmse | 0.0803972 | 0.0024753 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | prompt | bias | -0.00772928 | 0.00236007 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | prompt | empse | 0.0746321 | 0.00166966 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | prompt | rel_bias | -0.0772928 | 0.0236007 | 1000 | 20261037 | 1000 | 0 |
| S-bin-2 | prompt | rmse | 0.0749942 | 0.00265563 | 1000 | 20261037 | 1000 | 0 |

Reportable findings (values and MCSE on the stated measure’s scale):

| scenario | estimand | measure  | value     | mcse      | direction       |
|:---------|:---------|:---------|:----------|:----------|:----------------|
| S-bin-1  | model    | rel_bias | -0.223711 | 0.0254839 | underestimation |
| S-bin-1  | prompt   | rel_bias | -0.213736 | 0.0268401 | underestimation |
| S-bin-2  | model    | rel_bias | -0.204216 | 0.0246023 | underestimation |

### two_level

Read `two_level_results.csv` (full); n_sim = 1000 per scenario.

S-two-1

| scenario | estimand | measure | value | mcse | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-two-1 | grr_pct_study_var | bias | 0.0195007 | 0.117693 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | grr_pct_study_var | empse | 3.72178 | 0.0832632 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | grr_pct_study_var | rel_bias | 0.000268719 | 0.00162181 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | grr_pct_study_var | rmse | 3.71997 | 0.0803388 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | icc_items | bias | -0.00166685 | 0.00171623 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | icc_items | empse | 0.0542718 | 0.00121416 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | icc_items | rel_bias | -0.00352122 | 0.00362553 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | icc_items | rmse | 0.0542703 | 0.0012048 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | item | bias | -0.00228672 | 0.0064614 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | item | empse | 0.204327 | 0.00457118 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | item | rel_bias | -0.00228672 | 0.0064614 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | item | rmse | 0.204238 | 0.00455895 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | model | bias | -0.000353299 | 0.002273 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | model | empse | 0.0718787 | 0.00160806 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | model | rel_bias | -0.00706598 | 0.0454601 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | model | rmse | 0.0718436 | 0.0038696 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | prompt | bias | -0.0132124 | 0.00150343 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | prompt | empse | 0.0475425 | 0.00106361 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | prompt | rel_bias | -0.211399 | 0.0240548 | 1000 | 20261038 | 1000 | 0 |
| S-two-1 | prompt | rmse | 0.0493214 | 0.00169582 | 1000 | 20261038 | 1000 | 0 |

Derived-component diagnostic:

| scenario | estimand | measure       | value | mcse | n_sim | seed     | n_finite | n_failed |
|:---------|:---------|:--------------|:------|:-----|:------|:---------|:---------|:---------|
| S-two-1  | model    | derived_share | 1     | 0    | 1000  | 20261038 | 1000     | 0        |

S-two-2

| scenario | estimand | measure | value | mcse | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-two-2 | grr_pct_study_var | bias | -0.62879 | 0.14806 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | grr_pct_study_var | empse | 4.68207 | 0.104747 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | grr_pct_study_var | rel_bias | -0.00834636 | 0.0019653 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | grr_pct_study_var | rmse | 4.72178 | 0.103211 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | icc_items | bias | 0.00724472 | 0.00223798 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | icc_items | empse | 0.0707713 | 0.00158329 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | icc_items | rel_bias | 0.0167534 | 0.00517534 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | icc_items | rmse | 0.0711059 | 0.00162535 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | item | bias | 0.00245465 | 0.00623866 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | item | empse | 0.197284 | 0.00441361 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | item | rel_bias | 0.00245465 | 0.00623866 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | item | rmse | 0.1972 | 0.00516144 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | model | bias | -0.00168061 | 0.0116002 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | model | empse | 0.366831 | 0.00820668 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | model | rel_bias | -0.00672243 | 0.0464008 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | model | rmse | 0.366651 | 0.0235318 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | prompt | bias | -0.0117955 | 0.00133598 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | prompt | empse | 0.0422472 | 0.00094515 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | prompt | rel_bias | -0.188728 | 0.0213756 | 1000 | 20261039 | 1000 | 0 |
| S-two-2 | prompt | rmse | 0.0438427 | 0.00164755 | 1000 | 20261039 | 1000 | 0 |

Derived-component diagnostic:

| scenario | estimand | measure       | value | mcse | n_sim | seed     | n_finite | n_failed |
|:---------|:---------|:--------------|:------|:-----|:------|:---------|:---------|:---------|
| S-two-2  | model    | derived_share | 1     | 0    | 1000  | 20261039 | 1000     | 0        |

Reportable findings (values and MCSE on the stated measure’s scale):

| scenario | estimand | measure | value | mcse | direction |
|:---|:---|:---|:---|:---|:---|
| S-two-1 | model | bias | -0.000353299 | 0.002273 | no direction resolved at the report threshold |
| S-two-2 | model | bias | -0.00168061 | 0.0116002 | no direction resolved at the report threshold |

### Ordinal convergence sensitivity

The main summaries above retain finite estimates even when a fit did not
converge. The following separate analysis compares all finite estimates
with only those whose recorded `converged` flag is true. Singular fits
are retained in both eligible groups. Each n comes from the replicate
rows used by that group, independently of the result table’s n_sim.
Non-convergence, singularity and missing flags are counted separately
per actual outer repetition.

Bias MCSE is EmpSE divided by the square root of n; relative bias and
its MCSE divide by the truth and its absolute value, respectively. EmpSE
MCSE uses the ADEMP approximation in the formula collection, section 9.
Selecting on convergence can itself introduce selection bias: this
comparison is a descriptive sensitivity analysis, not a replacement
estimator or a reason to discard inconvenient estimates from the main
study.

| scenario | n | nonconverged | convergence_unknown | nonconverged_share | nonconverged_mcse | singular | singular_unknown | singular_share | singular_mcse |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-ord-1 | 1000 | 9 | 0 | 0.009 | 0.00298647 | 812 | 0 | 0.812 | 0.0123554 |
| S-ord-2 | 1000 | 18 | 0 | 0.018 | 0.00420428 | 797 | 0 | 0.797 | 0.0127197 |
| S-ord-3 | 1000 | 20 | 0 | 0.02 | 0.00442719 | 812 | 0 | 0.812 | 0.0123554 |
| S-ord-4 | 1000 | 16 | 0 | 0.016 | 0.00396787 | 789 | 0 | 0.789 | 0.0129027 |

Diagnostics over actual outer repetitions; unknown flags are shown
separately. {.table}

S-ord-1

| scenario | estimand | selection | n | bias | bias_mcse | rel_bias | rel_bias_mcse | empse | empse_mcse | status |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-ord-1 | grr_pct_study_var | all finite estimates | 1000 | -0.125273 | 0.110754 | -0.00168297 | 0.00148791 | 3.50234 | 0.0783538 | available |
| S-ord-1 | grr_pct_study_var | converged finite estimates | 991 | -0.117658 | 0.111316 | -0.00158067 | 0.00149546 | 3.50425 | 0.0787521 | available |
| S-ord-1 | icc_items | all finite estimates | 1000 | 0.000637983 | 0.00165117 | 0.00143068 | 0.00370276 | 0.0522147 | 0.00116814 | available |
| S-ord-1 | icc_items | converged finite estimates | 991 | 0.000523478 | 0.00165959 | 0.0011739 | 0.00372162 | 0.052244 | 0.0011741 | available |
| S-ord-1 | item | all finite estimates | 1000 | 0.00395243 | 0.00635032 | 0.00395243 | 0.00635032 | 0.200815 | 0.0044926 | available |
| S-ord-1 | item | converged finite estimates | 991 | 0.00390423 | 0.00638922 | 0.00390423 | 0.00638922 | 0.201134 | 0.00452014 | available |
| S-ord-1 | item:model | all finite estimates | 1000 | 0.00211939 | 0.000972256 | 0.0235487 | 0.0108028 | 0.0307454 | 0.000687833 | available |
| S-ord-1 | item:model | converged finite estimates | 991 | 0.0021756 | 0.0009794 | 0.0241734 | 0.0108822 | 0.0308317 | 0.00069289 | available |
| S-ord-1 | model | all finite estimates | 1000 | -0.0181983 | 0.00227219 | -0.202203 | 0.0252466 | 0.0718531 | 0.00160749 | available |
| S-ord-1 | model | converged finite estimates | 991 | -0.0181243 | 0.0022806 | -0.201382 | 0.0253399 | 0.0717935 | 0.00161344 | available |
| S-ord-1 | prompt | all finite estimates | 1000 | -0.00952569 | 0.00165618 | -0.152411 | 0.0264989 | 0.052373 | 0.00117168 | available |
| S-ord-1 | prompt | converged finite estimates | 991 | -0.00926904 | 0.00166774 | -0.148305 | 0.0266839 | 0.0525008 | 0.00117987 | available |

S-ord-2

| scenario | estimand | selection | n | bias | bias_mcse | rel_bias | rel_bias_mcse | empse | empse_mcse | status |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-ord-2 | grr_pct_study_var | all finite estimates | 1000 | 0.0347232 | 0.113032 | 0.000466485 | 0.00151851 | 3.57438 | 0.0799656 | available |
| S-ord-2 | grr_pct_study_var | converged finite estimates | 982 | 0.0355778 | 0.114488 | 0.000477966 | 0.00153808 | 3.5877 | 0.0809965 | available |
| S-ord-2 | icc_items | all finite estimates | 1000 | -0.00179339 | 0.00168449 | -0.00402168 | 0.00377748 | 0.0532684 | 0.00119171 | available |
| S-ord-2 | icc_items | converged finite estimates | 982 | -0.00181562 | 0.00170576 | -0.00407154 | 0.00382517 | 0.0534532 | 0.00120677 | available |
| S-ord-2 | item | all finite estimates | 1000 | -0.0016251 | 0.0064879 | -0.0016251 | 0.0064879 | 0.205165 | 0.00458993 | available |
| S-ord-2 | item | converged finite estimates | 982 | -0.00151254 | 0.00657985 | -0.00151254 | 0.00657985 | 0.206192 | 0.00465503 | available |
| S-ord-2 | item:model | all finite estimates | 1000 | 0.00160385 | 0.000717591 | 0.0178205 | 0.00797323 | 0.0226922 | 0.000507667 | available |
| S-ord-2 | item:model | converged finite estimates | 982 | 0.00150289 | 0.000727319 | 0.0166987 | 0.00808132 | 0.0227919 | 0.000514554 | available |
| S-ord-2 | model | all finite estimates | 1000 | -0.0168554 | 0.00230711 | -0.187283 | 0.0256346 | 0.0729573 | 0.00163219 | available |
| S-ord-2 | model | converged finite estimates | 982 | -0.0167918 | 0.00233361 | -0.186575 | 0.025929 | 0.0731281 | 0.00165095 | available |
| S-ord-2 | prompt | all finite estimates | 1000 | -0.00435936 | 0.0012259 | -0.0697498 | 0.0196144 | 0.0387663 | 0.000867275 | available |
| S-ord-2 | prompt | converged finite estimates | 982 | -0.00439241 | 0.00123293 | -0.0702786 | 0.0197269 | 0.0386362 | 0.000872258 | available |

S-ord-3

| scenario | estimand | selection | n | bias | bias_mcse | rel_bias | rel_bias_mcse | empse | empse_mcse | status |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-ord-3 | grr_pct_study_var | all finite estimates | 1000 | 0.168115 | 0.129819 | 0.00294099 | 0.00227104 | 4.10523 | 0.0918417 | available |
| S-ord-3 | grr_pct_study_var | converged finite estimates | 980 | 0.163064 | 0.130847 | 0.00285263 | 0.00228901 | 4.09614 | 0.0925697 | available |
| S-ord-3 | icc_items | all finite estimates | 1000 | -0.00360842 | 0.00150216 | -0.00535977 | 0.00223124 | 0.0475026 | 0.00106272 | available |
| S-ord-3 | icc_items | converged finite estimates | 980 | -0.00354303 | 0.00151343 | -0.00526264 | 0.00224798 | 0.0473779 | 0.0010707 | available |
| S-ord-3 | item | all finite estimates | 1000 | -0.000680181 | 0.0161926 | -0.000265696 | 0.00632523 | 0.512054 | 0.0114556 | available |
| S-ord-3 | item | converged finite estimates | 980 | -0.000357753 | 0.016346 | -0.000139747 | 0.00638515 | 0.51171 | 0.0115643 | available |
| S-ord-3 | item:model | all finite estimates | 1000 | 0.00179274 | 0.00103592 | 0.0199194 | 0.0115102 | 0.0327587 | 0.000732873 | available |
| S-ord-3 | item:model | converged finite estimates | 980 | 0.0017884 | 0.00105051 | 0.0198711 | 0.0116724 | 0.0328863 | 0.000743205 | available |
| S-ord-3 | model | all finite estimates | 1000 | -0.0153654 | 0.00224351 | -0.170727 | 0.0249279 | 0.0709461 | 0.0015872 | available |
| S-ord-3 | model | converged finite estimates | 980 | -0.0156277 | 0.00226048 | -0.173641 | 0.0251165 | 0.0707643 | 0.00159922 | available |
| S-ord-3 | prompt | all finite estimates | 1000 | -0.0068387 | 0.00179576 | -0.109419 | 0.0287322 | 0.056787 | 0.00127043 | available |
| S-ord-3 | prompt | converged finite estimates | 980 | -0.00682311 | 0.00181755 | -0.10917 | 0.0290809 | 0.0568984 | 0.00128586 | available |

S-ord-4

| scenario | estimand | selection | n | bias | bias_mcse | rel_bias | rel_bias_mcse | empse | empse_mcse | status |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-ord-4 | block | all finite estimates | 1000 | 0.000995367 | 0.000451907 | 0.0995367 | 0.0451907 | 0.0142906 | 0.000319707 | available |
| S-ord-4 | block | converged finite estimates | 984 | 0.000979918 | 0.000455505 | 0.0979918 | 0.0455505 | 0.0142886 | 0.000322254 | available |
| S-ord-4 | grr_pct_study_var | all finite estimates | 1000 | -0.286697 | 0.0879519 | -0.00384474 | 0.00117947 | 2.78128 | 0.0622225 | available |
| S-ord-4 | grr_pct_study_var | converged finite estimates | 984 | -0.298257 | 0.0888445 | -0.00399976 | 0.00119144 | 2.78694 | 0.0628545 | available |
| S-ord-4 | icc_items | all finite estimates | 1000 | 0.00349472 | 0.00130511 | 0.00787186 | 0.00293977 | 0.0412713 | 0.000923317 | available |
| S-ord-4 | icc_items | converged finite estimates | 984 | 0.00366331 | 0.00131824 | 0.00825161 | 0.00296933 | 0.0413515 | 0.000932608 | available |
| S-ord-4 | item | all finite estimates | 1000 | -0.00139942 | 0.00487517 | -0.00139942 | 0.00487517 | 0.154166 | 0.00344899 | available |
| S-ord-4 | item | converged finite estimates | 984 | -0.000412487 | 0.00492568 | -0.000412487 | 0.00492568 | 0.154512 | 0.00348475 | available |
| S-ord-4 | item:model | all finite estimates | 1000 | 6.53399e-05 | 0.0005059 | 0.000725999 | 0.00562112 | 0.015998 | 0.000357905 | available |
| S-ord-4 | item:model | converged finite estimates | 984 | 0.000112316 | 0.000512275 | 0.00124796 | 0.00569195 | 0.0160695 | 0.000362418 | available |
| S-ord-4 | model | all finite estimates | 1000 | -0.0210329 | 0.00217048 | -0.233699 | 0.0241164 | 0.0686366 | 0.00153553 | available |
| S-ord-4 | model | converged finite estimates | 984 | -0.0208426 | 0.00218585 | -0.231585 | 0.0242872 | 0.0685675 | 0.00154642 | available |
| S-ord-4 | prompt | all finite estimates | 1000 | -0.0124167 | 0.00150468 | -0.198667 | 0.0240749 | 0.0475823 | 0.0010645 | available |
| S-ord-4 | prompt | converged finite estimates | 984 | -0.0123292 | 0.00152227 | -0.197267 | 0.0243563 | 0.0477516 | 0.00107695 | available |

## Bootstrap intervals: coverage by scenario

This section reads **boot_coverage_results.csv** (**full** run), with
**n_sim = 1000** repetitions per scenario. The installed
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
than a reason to alter intervals. The reporting threshold is
ANK-TOL.mc_factor.report, or 3 MCSE from the nominal level. A zero MCSE
does not hide a deviation from nominal. The continuous GRR and ICC
statistics are monotone functions of the same variance ratio; their
percentile coverages coincide in these results. The integer-valued ndc
has discrete steps, which can produce conservative intervals and
overcoverage. The findings below identify every affected scenario and
interval estimand individually.

### S-boot-1

| scenario | estimand | measure | value | MCSE | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-boot-1 | block | bias | -0.000179057 | 0.00044736 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | block | empse | 0.0141468 | 0.000316489 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | block | rel_bias | -0.0179057 | 0.044736 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | block | rmse | 0.0141408 | 0.000754699 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | grr_pct_contribution | bias | 0.915966 | 0.245928 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | grr_pct_contribution | coverage | 0.949 | 0.00695694 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | grr_pct_contribution | empse | 7.77691 | 0.173984 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | grr_pct_contribution | rel_bias | 0.0424675 | 0.0114021 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | grr_pct_contribution | rmse | 7.8268 | 0.235994 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | grr_pct_contribution | width | 29.743 | 0.266317 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | grr_pct_study_var | bias | 0.321111 | 0.248453 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | grr_pct_study_var | coverage | 0.949 | 0.00695694 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | grr_pct_study_var | empse | 7.85679 | 0.175771 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | grr_pct_study_var | rel_bias | 0.00691423 | 0.00534975 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | grr_pct_study_var | rmse | 7.85942 | 0.190564 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | grr_pct_study_var | width | 29.9091 | 0.155596 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | icc_items | bias | -0.00915966 | 0.00245928 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | icc_items | coverage | 0.949 | 0.00695694 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | icc_items | empse | 0.0777691 | 0.00173984 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | icc_items | rel_bias | -0.0116786 | 0.00313558 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | icc_items | rmse | 0.078268 | 0.00235994 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | icc_items | width | 0.29743 | 0.00266317 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | item | bias | 0.0101384 | 0.010449 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | item | empse | 0.330427 | 0.00739227 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | item | rel_bias | 0.0101384 | 0.010449 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | item | rmse | 0.330417 | 0.00794962 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | item:model | bias | -0.000329439 | 0.000391851 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | item:model | empse | 0.0123914 | 0.000277219 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | item:model | rel_bias | -0.00658877 | 0.00783703 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | item:model | rmse | 0.0123896 | 0.00027226 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | item:prompt | bias | 0.000269881 | 0.000112845 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | item:prompt | empse | 0.00356847 | 7.98333e-05 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | item:prompt | rel_bias | 0.0269881 | 0.0112845 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | item:prompt | rmse | 0.00357688 | 8.80177e-05 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | model | bias | 0.00170806 | 0.00173827 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | model | empse | 0.0549688 | 0.00122975 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | model | rel_bias | 0.0341611 | 0.0347653 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | model | rmse | 0.0549678 | 0.00229036 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | ndc | bias | 0.239 | 0.0206956 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | ndc | coverage | 0.998 | 0.0014128 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | ndc | empse | 0.654452 | 0.0146413 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | ndc | rel_bias | 0.1195 | 0.0103478 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | ndc | rmse | 0.696419 | 0.0162818 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | ndc | width | 2.23835 | 0.0195815 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | prompt | bias | -0.00287615 | 0.00158321 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | prompt | empse | 0.0500654 | 0.00112006 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | prompt | rel_bias | -0.0575229 | 0.0316641 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | prompt | rmse | 0.0501229 | 0.00200897 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | prompt:model | bias | -4.03718e-05 | 0.00013373 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | prompt:model | empse | 0.0042289 | 9.46085e-05 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | prompt:model | rel_bias | -0.00807437 | 0.0267459 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | prompt:model | rmse | 0.00422698 | 0.00015905 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | Residual | bias | -0.000159097 | 0.000141341 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | Residual | empse | 0.0044696 | 9.99933e-05 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | Residual | rel_bias | -0.00159097 | 0.00141341 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | Residual | rmse | 0.0044702 | 9.9621e-05 | 1000 | 20261102 | 1000 | 0 |

Bootstrap diagnostics:

| scenario | estimand | measure | value | MCSE | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-boot-1 | bootstrap | failed_share | 0 | 0 | 1000 | 20261102 | 1000 | 0 |
| S-boot-1 | bootstrap | singular_share | 0.494705 | 0.00627041 | 1000 | 20261102 | 1000 | 0 |

### S-boot-2

| scenario | estimand | measure | value | MCSE | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-boot-2 | block | bias | 0.000220631 | 0.000451261 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | block | empse | 0.0142701 | 0.00031925 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | block | rel_bias | 0.0220631 | 0.0451261 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | block | rmse | 0.0142647 | 0.000812554 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | grr_pct_contribution | bias | 1.24046 | 0.221046 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | grr_pct_contribution | coverage | 0.951 | 0.00682635 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | grr_pct_contribution | empse | 6.9901 | 0.156382 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | grr_pct_contribution | rel_bias | 0.0575121 | 0.0102485 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | grr_pct_contribution | rmse | 7.09587 | 0.198168 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | grr_pct_contribution | width | 28.8245 | 0.228313 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | grr_pct_study_var | bias | 0.779473 | 0.226028 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | grr_pct_study_var | coverage | 0.951 | 0.00682635 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | grr_pct_study_var | empse | 7.14763 | 0.159906 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | grr_pct_study_var | rel_bias | 0.0167838 | 0.00486688 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | grr_pct_study_var | rmse | 7.18646 | 0.1658 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | grr_pct_study_var | width | 28.8115 | 0.1319 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | icc_items | bias | -0.0124046 | 0.00221046 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | icc_items | coverage | 0.951 | 0.00682635 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | icc_items | empse | 0.069901 | 0.00156382 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | icc_items | rel_bias | -0.0158158 | 0.00281834 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | icc_items | rmse | 0.0709587 | 0.00198168 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | icc_items | width | 0.288245 | 0.00228313 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | item | bias | -0.00138368 | 0.0100515 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | item | empse | 0.317856 | 0.00711103 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | item | rel_bias | -0.00138368 | 0.0100515 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | item | rmse | 0.3177 | 0.00851007 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | item:model | bias | -7.47711e-05 | 0.0003891 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | item:model | empse | 0.0123044 | 0.000275273 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | item:model | rel_bias | -0.00149542 | 0.007782 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | item:model | rmse | 0.0122985 | 0.000323379 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | item:prompt | bias | 6.57683e-07 | 7.93903e-05 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | item:prompt | empse | 0.00251054 | 5.61655e-05 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | item:prompt | rel_bias | 6.57683e-05 | 0.00793903 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | item:prompt | rmse | 0.00250929 | 5.95317e-05 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | model | bias | 0.000476092 | 0.00178082 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | model | empse | 0.0563144 | 0.00125986 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | model | rel_bias | 0.00952183 | 0.0356164 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | model | rmse | 0.0562883 | 0.00272253 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | ndc | bias | 0.2 | 0.0186104 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | ndc | coverage | 1 | 0 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | ndc | empse | 0.588512 | 0.0131661 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | ndc | rel_bias | 0.1 | 0.00930519 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | ndc | rmse | 0.621289 | 0.016204 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | ndc | width | 2.12513 | 0.0185214 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | prompt | bias | 0.00142641 | 0.00116433 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | prompt | empse | 0.0368194 | 0.00082372 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | prompt | rel_bias | 0.0285282 | 0.0232867 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | prompt | rmse | 0.0368287 | 0.00106195 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | prompt:model | bias | -2.77905e-05 | 9.29801e-05 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | prompt:model | empse | 0.00294029 | 6.57797e-05 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | prompt:model | rel_bias | -0.00555811 | 0.018596 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | prompt:model | rmse | 0.00293895 | 8.73629e-05 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | Residual | bias | 4.87301e-05 | 0.000109439 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | Residual | empse | 0.00346076 | 7.74237e-05 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | Residual | rel_bias | 0.000487301 | 0.00109439 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | Residual | rmse | 0.00345937 | 7.35628e-05 | 1000 | 20261104 | 1000 | 0 |

Bootstrap diagnostics:

| scenario | estimand | measure | value | MCSE | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-boot-2 | bootstrap | failed_share | 0 | 0 | 1000 | 20261104 | 1000 | 0 |
| S-boot-2 | bootstrap | singular_share | 0.349435 | 0.00656497 | 1000 | 20261104 | 1000 | 0 |

### S-boot-3

| scenario | estimand | measure | value | MCSE | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-boot-3 | block | bias | -0.000172993 | 0.000435335 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | block | empse | 0.0137665 | 0.000307982 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | block | rel_bias | -0.0172993 | 0.0435335 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | block | rmse | 0.0137607 | 0.000634914 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | grr_pct_contribution | bias | 0.387751 | 0.18443 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | grr_pct_contribution | coverage | 0.946 | 0.00714731 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | grr_pct_contribution | empse | 5.83219 | 0.130477 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | grr_pct_contribution | rel_bias | 0.0179776 | 0.00855084 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | grr_pct_contribution | rmse | 5.84215 | 0.154136 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | grr_pct_contribution | width | 22.9189 | 0.261929 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | grr_pct_study_var | bias | 0.0196257 | 0.192325 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | grr_pct_study_var | coverage | 0.946 | 0.00714731 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | grr_pct_study_var | empse | 6.08184 | 0.136062 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | grr_pct_study_var | rel_bias | 0.000422585 | 0.00414118 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | grr_pct_study_var | rmse | 6.07883 | 0.13497 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | grr_pct_study_var | width | 23.4262 | 0.18891 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | icc_items | bias | -0.00387751 | 0.0018443 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | icc_items | coverage | 0.946 | 0.00714731 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | icc_items | empse | 0.0583219 | 0.00130477 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | icc_items | rel_bias | -0.00494383 | 0.00235148 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | icc_items | rmse | 0.0584215 | 0.00154136 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | icc_items | width | 0.229189 | 0.00261929 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | item | bias | 0.00531278 | 0.00634644 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | item | empse | 0.200692 | 0.00448986 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | item | rel_bias | 0.00531278 | 0.00634644 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | item | rmse | 0.200662 | 0.00484784 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | item:model | bias | 0.000224093 | 0.000258125 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | item:model | empse | 0.00816264 | 0.000182613 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | item:model | rel_bias | 0.00448185 | 0.00516251 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | item:model | rmse | 0.00816163 | 0.000206612 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | item:prompt | bias | -1.35528e-05 | 6.70549e-05 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | item:prompt | empse | 0.00212046 | 4.74387e-05 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | item:prompt | rel_bias | -0.00135528 | 0.00670549 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | item:prompt | rmse | 0.00211944 | 4.77642e-05 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | model | bias | 0.00169466 | 0.00172843 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | model | empse | 0.0546576 | 0.00122279 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | model | rel_bias | 0.0338933 | 0.0345685 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | model | rmse | 0.0546566 | 0.00247138 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | ndc | bias | 0.231 | 0.0166107 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | ndc | coverage | 0.991 | 0.00298647 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | ndc | empse | 0.525276 | 0.0117514 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | ndc | rel_bias | 0.1155 | 0.00830534 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | ndc | rmse | 0.573585 | 0.0133058 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | ndc | width | 1.7328 | 0.0159767 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | prompt | bias | 0.00177739 | 0.00171982 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | prompt | empse | 0.0543853 | 0.0012167 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | prompt | rel_bias | 0.0355477 | 0.0343963 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | prompt | rmse | 0.0543872 | 0.00256672 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | prompt:model | bias | -0.000168708 | 0.000112811 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | prompt:model | empse | 0.0035674 | 7.98094e-05 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | prompt:model | rel_bias | -0.0337416 | 0.0225622 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | prompt:model | rmse | 0.0035696 | 0.000112136 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | Residual | bias | 0.000222021 | 9.12617e-05 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | Residual | empse | 0.00288595 | 6.4564e-05 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | Residual | rel_bias | 0.00222021 | 0.000912617 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | Residual | rmse | 0.00289304 | 6.69745e-05 | 1000 | 20261106 | 1000 | 0 |

Bootstrap diagnostics:

| scenario | estimand | measure | value | MCSE | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-boot-3 | bootstrap | failed_share | 0 | 0 | 1000 | 20261106 | 1000 | 0 |
| S-boot-3 | bootstrap | singular_share | 0.356445 | 0.00633671 | 1000 | 20261106 | 1000 | 0 |

### S-boot-4

| scenario | estimand | measure | value | MCSE | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-boot-4 | block | bias | 0.00010448 | 0.000431586 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | block | empse | 0.0136479 | 0.00030533 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | block | rel_bias | 0.010448 | 0.0431586 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | block | rmse | 0.0136415 | 0.000735005 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | grr_pct_contribution | bias | 0.122506 | 0.162809 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | grr_pct_contribution | coverage | 0.953 | 0.00669261 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | grr_pct_contribution | empse | 5.14848 | 0.115181 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | grr_pct_contribution | rel_bias | 0.00567982 | 0.00754843 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | grr_pct_contribution | rmse | 5.14737 | 0.122037 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | grr_pct_contribution | width | 20.6844 | 0.207511 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | grr_pct_study_var | bias | -0.188594 | 0.172517 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | grr_pct_study_var | coverage | 0.953 | 0.00669261 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | grr_pct_study_var | empse | 5.45547 | 0.122049 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | grr_pct_study_var | rel_bias | -0.00406085 | 0.00371468 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | grr_pct_study_var | rmse | 5.456 | 0.113409 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | grr_pct_study_var | width | 21.4077 | 0.151213 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | icc_items | bias | -0.00122506 | 0.00162809 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | icc_items | coverage | 0.953 | 0.00669261 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | icc_items | empse | 0.0514848 | 0.00115181 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | icc_items | rel_bias | -0.00156195 | 0.00207582 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | icc_items | rmse | 0.0514737 | 0.00122037 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | icc_items | width | 0.206844 | 0.00207511 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | item | bias | 0.00316322 | 0.00681111 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | item | empse | 0.215386 | 0.00481859 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | item | rel_bias | 0.00316322 | 0.00681111 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | item | rmse | 0.215302 | 0.00517149 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | item:model | bias | -5.93925e-05 | 0.000256426 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | item:model | empse | 0.00810892 | 0.000181412 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | item:model | rel_bias | -0.00118785 | 0.00512853 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | item:model | rmse | 0.00810508 | 0.000184828 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | item:prompt | bias | 4.43358e-05 | 5.09981e-05 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | item:prompt | empse | 0.0016127 | 3.60791e-05 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | item:prompt | rel_bias | 0.00443358 | 0.00509981 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | item:prompt | rmse | 0.0016125 | 3.74237e-05 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | model | bias | -0.00210709 | 0.00154269 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | model | empse | 0.0487842 | 0.00109139 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | model | rel_bias | -0.0421417 | 0.0308538 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | model | rmse | 0.0488053 | 0.00188038 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | ndc | bias | 0.252 | 0.0156442 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | ndc | coverage | 0.996 | 0.001996 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | ndc | empse | 0.494713 | 0.0110676 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | ndc | rel_bias | 0.126 | 0.0078221 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | ndc | rmse | 0.554977 | 0.0138807 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | ndc | width | 1.61745 | 0.0160421 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | prompt | bias | -0.00112919 | 0.00116458 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | prompt | empse | 0.0368272 | 0.000823894 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | prompt | rel_bias | -0.0225837 | 0.0232916 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | prompt | rmse | 0.0368261 | 0.00132992 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | prompt:model | bias | -0.000148256 | 8.25028e-05 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | prompt:model | empse | 0.00260897 | 5.83675e-05 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | prompt:model | rel_bias | -0.0296512 | 0.0165006 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | prompt:model | rmse | 0.00261187 | 7.2973e-05 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | Residual | bias | 5.93742e-05 | 7.10002e-05 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | Residual | empse | 0.00224522 | 5.02299e-05 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | Residual | rel_bias | 0.000593742 | 0.000710002 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | Residual | rmse | 0.00224489 | 5.07284e-05 | 1000 | 20261108 | 1000 | 0 |

Bootstrap diagnostics:

| scenario | estimand | measure | value | MCSE | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-boot-4 | bootstrap | failed_share | 0 | 0 | 1000 | 20261108 | 1000 | 0 |
| S-boot-4 | bootstrap | singular_share | 0.23507 | 0.0057105 | 1000 | 20261108 | 1000 | 0 |

### S-boot-5

| scenario | estimand | measure | value | MCSE | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-boot-5 | block | bias | -0.000256022 | 0.000459752 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | block | empse | 0.0145386 | 0.000325256 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | block | rel_bias | -0.0256022 | 0.0459752 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | block | rmse | 0.0145336 | 0.000856827 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | grr_pct_contribution | bias | 0.382877 | 0.333661 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | grr_pct_contribution | coverage | 0.953 | 0.00669261 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | grr_pct_contribution | empse | 10.5513 | 0.236052 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | grr_pct_contribution | rel_bias | 0.00796797 | 0.00694375 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | grr_pct_contribution | rmse | 10.553 | 0.231152 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | grr_pct_contribution | width | 38.6024 | 0.194795 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | grr_pct_study_var | bias | -0.140745 | 0.240496 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | grr_pct_study_var | coverage | 0.953 | 0.00669261 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | grr_pct_study_var | empse | 7.60516 | 0.170142 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | grr_pct_study_var | rel_bias | -0.00203038 | 0.00346939 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | grr_pct_study_var | rmse | 7.60266 | 0.16267 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | grr_pct_study_var | width | 27.9416 | 0.122013 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | icc_items | bias | -0.00382877 | 0.00333661 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | icc_items | coverage | 0.953 | 0.00669261 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | icc_items | empse | 0.105513 | 0.00236052 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | icc_items | rel_bias | -0.00737038 | 0.00642297 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | icc_items | rmse | 0.10553 | 0.00231152 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | icc_items | width | 0.386024 | 0.00194795 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | item | bias | -0.00359063 | 0.0104924 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | item | empse | 0.331797 | 0.00742293 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | item | rel_bias | -0.00359063 | 0.0104924 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | item | rmse | 0.331651 | 0.00893643 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | item:model | bias | 0.00132569 | 0.000577165 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | item:model | empse | 0.0182516 | 0.000408322 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | item:model | rel_bias | 0.0265139 | 0.0115433 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | item:model | rmse | 0.0182906 | 0.000440177 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | item:prompt | bias | 0.000148159 | 0.000255979 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | item:prompt | empse | 0.00809475 | 0.000181095 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | item:prompt | rel_bias | 0.0148159 | 0.0255979 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | item:prompt | rmse | 0.00809206 | 0.000211122 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | model | bias | 0.000700834 | 0.00180431 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | model | empse | 0.0570572 | 0.00127648 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | model | rel_bias | 0.0140167 | 0.0360861 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | model | rmse | 0.0570329 | 0.00281029 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | ndc | bias | 0.068 | 0.00796489 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | ndc | coverage | 1 | 0 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | ndc | empse | 0.251872 | 0.00563484 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | ndc | rel_bias | 0.068 | 0.00796489 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | ndc | rmse | 0.260768 | 0.015272 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | ndc | width | 0.6629 | 0.0163448 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | prompt | bias | -0.00421825 | 0.00894692 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | prompt | empse | 0.282926 | 0.00632959 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | prompt | rel_bias | -0.0140608 | 0.0298231 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | prompt | rmse | 0.282816 | 0.00980394 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | prompt:model | bias | 0.000319217 | 0.000185588 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | prompt:model | empse | 0.00586881 | 0.000131296 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | prompt:model | rel_bias | 0.0638433 | 0.0371176 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | prompt:model | rmse | 0.00587456 | 0.000203789 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | Residual | bias | -0.000762179 | 0.000688856 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | Residual | empse | 0.0217835 | 0.000487338 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | Residual | rel_bias | -0.00152436 | 0.00137771 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | Residual | rmse | 0.021786 | 0.000454697 | 1000 | 20261110 | 1000 | 0 |

Bootstrap diagnostics:

| scenario | estimand | measure | value | MCSE | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-boot-5 | bootstrap | failed_share | 0 | 0 | 1000 | 20261110 | 1000 | 0 |
| S-boot-5 | bootstrap | singular_share | 0.73465 | 0.00448964 | 1000 | 20261110 | 1000 | 0 |

### S-boot-6

| scenario | estimand | measure | value | MCSE | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-boot-6 | block | bias | -0.00035723 | 0.000488198 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | block | empse | 0.0154382 | 0.000345381 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | block | rel_bias | -0.035723 | 0.0488198 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | block | rmse | 0.0154346 | 0.000928394 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | grr_pct_contribution | bias | 0.835364 | 0.307717 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | grr_pct_contribution | coverage | 0.933 | 0.00790639 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | grr_pct_contribution | empse | 9.73086 | 0.217698 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | grr_pct_contribution | rel_bias | 0.0173846 | 0.00640384 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | grr_pct_contribution | rmse | 9.7618 | 0.20911 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | grr_pct_contribution | width | 36.1101 | 0.129018 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | grr_pct_study_var | bias | 0.248904 | 0.221395 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | grr_pct_study_var | coverage | 0.933 | 0.00790639 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | grr_pct_study_var | empse | 7.00112 | 0.156628 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | grr_pct_study_var | rel_bias | 0.00359068 | 0.00319383 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | grr_pct_study_var | rmse | 7.00204 | 0.14516 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | grr_pct_study_var | width | 26.0067 | 0.0949652 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | icc_items | bias | -0.00835364 | 0.00307717 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | icc_items | coverage | 0.933 | 0.00790639 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | icc_items | empse | 0.0973086 | 0.00217698 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | icc_items | rel_bias | -0.0160808 | 0.00592355 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | icc_items | rmse | 0.097618 | 0.0020911 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | icc_items | width | 0.361101 | 0.00129018 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | item | bias | 0.00537149 | 0.0107247 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | item | empse | 0.339144 | 0.00758728 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | item | rel_bias | 0.00537149 | 0.0107247 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | item | rmse | 0.339017 | 0.0092193 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | item:model | bias | -0.000414347 | 0.000480579 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | item:model | empse | 0.0151972 | 0.000339991 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | item:model | rel_bias | -0.00828694 | 0.00961158 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | item:model | rmse | 0.0151953 | 0.000375231 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | item:prompt | bias | 0.000386655 | 0.000197721 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | item:prompt | empse | 0.00625249 | 0.00013988 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | item:prompt | rel_bias | 0.0386655 | 0.0197721 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | item:prompt | rmse | 0.00626131 | 0.000157147 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | model | bias | 0.000716321 | 0.00161988 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | model | empse | 0.0512251 | 0.001146 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | model | rel_bias | 0.0143264 | 0.0323976 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | model | rmse | 0.0512045 | 0.00180904 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | ndc | bias | 0.051 | 0.00696042 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | ndc | coverage | 1 | 0 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | ndc | empse | 0.220108 | 0.00492422 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | ndc | rel_bias | 0.051 | 0.00696042 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | ndc | rmse | 0.225832 | 0.0154106 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | ndc | width | 0.581825 | 0.0165824 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | prompt | bias | 0.00541509 | 0.00682438 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | prompt | empse | 0.215806 | 0.00482798 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | prompt | rel_bias | 0.0180503 | 0.0227479 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | prompt | rmse | 0.215766 | 0.00762393 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | prompt:model | bias | -0.000217224 | 0.000138215 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | prompt:model | empse | 0.00437073 | 9.77814e-05 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | prompt:model | rel_bias | -0.0434447 | 0.0276429 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | prompt:model | rmse | 0.00437394 | 0.000140261 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | Residual | bias | 0.00047745 | 0.000560556 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | Residual | empse | 0.0177263 | 0.000396571 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | Residual | rel_bias | 0.0009549 | 0.00112111 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | Residual | rmse | 0.0177239 | 0.000407437 | 1000 | 20261112 | 1000 | 0 |

Bootstrap diagnostics:

| scenario | estimand | measure | value | MCSE | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-boot-6 | bootstrap | failed_share | 0 | 0 | 1000 | 20261112 | 1000 | 0 |
| S-boot-6 | bootstrap | singular_share | 0.607905 | 0.00580555 | 1000 | 20261112 | 1000 | 0 |

### S-boot-7

| scenario | estimand | measure | value | MCSE | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-boot-7 | grr_pct_contribution | bias | 0.382422 | 0.126935 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | grr_pct_contribution | coverage | 0.928 | 0.00817411 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | grr_pct_contribution | empse | 4.01403 | 0.0898014 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | grr_pct_contribution | rel_bias | 0.00492003 | 0.00163307 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | grr_pct_contribution | rmse | 4.03021 | 0.0823988 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | grr_pct_contribution | width | 15.3459 | 0.0603585 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | grr_pct_study_var | bias | 0.187419 | 0.0718707 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | grr_pct_study_var | coverage | 0.928 | 0.00817411 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | grr_pct_study_var | empse | 2.27275 | 0.0508457 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | grr_pct_study_var | rel_bias | 0.00212581 | 0.0008152 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | grr_pct_study_var | rmse | 2.27933 | 0.0463656 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | grr_pct_study_var | width | 8.7328 | 0.0404198 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | icc_items | bias | -0.00382422 | 0.00126935 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | icc_items | coverage | 0.928 | 0.00817411 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | icc_items | empse | 0.0401403 | 0.000898014 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | icc_items | rel_bias | -0.0171703 | 0.00569921 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | icc_items | rmse | 0.0403021 | 0.000823988 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | icc_items | width | 0.153459 | 0.000603585 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | item | bias | -0.0228867 | 0.00715257 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | item | empse | 0.226184 | 0.00506016 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | item | rel_bias | -0.0228867 | 0.00715257 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | item | rmse | 0.227227 | 0.00474553 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | model | bias | -0.0202493 | 0.00264045 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | model | empse | 0.0834983 | 0.00186801 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | model | rel_bias | -0.202493 | 0.0264045 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | model | rmse | 0.085878 | 0.00281279 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | ndc | bias | 0 | 0 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | ndc | coverage | 1 | 0 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | ndc | empse | 0 | 0 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | ndc | rel_bias | 0 | 0 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | ndc | rmse | 0 | 0 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | ndc | width | 0 | 0 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | prompt | bias | -0.0204982 | 0.00260761 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | prompt | empse | 0.0824599 | 0.00184478 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | prompt | rel_bias | -0.204982 | 0.0260761 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | prompt | rmse | 0.0849294 | 0.00322761 | 1000 | 20261114 | 1000 | 0 |

Bootstrap diagnostics:

| scenario | estimand | measure | value | MCSE | n_sim | seed | n_finite | n_failed |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| S-boot-7 | bootstrap | failed_share | 0 | 0 | 1000 | 20261114 | 1000 | 0 |
| S-boot-7 | bootstrap | singular_share | 0.37961 | 0.00665147 | 1000 | 20261114 | 1000 | 0 |

Reportable interval findings:

| scenario | estimand | measure  | value | mcse       | direction    |
|:---------|:---------|:---------|:------|:-----------|:-------------|
| S-boot-1 | ndc      | coverage | 0.998 | 0.0014128  | overcoverage |
| S-boot-2 | ndc      | coverage | 1     | 0          | overcoverage |
| S-boot-3 | ndc      | coverage | 0.991 | 0.00298647 | overcoverage |
| S-boot-4 | ndc      | coverage | 0.996 | 0.001996   | overcoverage |
| S-boot-5 | ndc      | coverage | 1     | 0          | overcoverage |
| S-boot-6 | ndc      | coverage | 1     | 0          | overcoverage |
| S-boot-7 | ndc      | coverage | 1     | 0          | overcoverage |
