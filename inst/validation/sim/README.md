# ADEMP simulation studies

These scripts implement the M1b and M1c scenarios in `docs/02-statistikkern.md`
and the contracts in ADR-023, ADR-025 and ADR-042. They load the installed `llmsa` and
installed helpers through `system.file()`, independently of the working
directory. Use a library containing the accepted package and frozen engines.

## Aims, generation and estimands

`ordinal_recovery` studies recovery of latent variance components with a
probit cumulative link mixed model. The four scenarios use independent
normal item, prompt, model and item-by-model effects, standard normal
observation noise, and five classes separated at -1.5, -0.5, 0.5 and 1.5.
S-ord-4 additionally draws block effects. The fitted model includes all
three pairwise interactions; item-by-prompt and prompt-by-model have true
variance zero and still contribute to the fitted GRR. The two-level block
enters as a fixed effect with a derived variance.

`binary_recovery` uses Bernoulli draws with probability `plogis(mu + eta)`
and independent normal item, prompt and model effects. There is no extra
normal observation noise. Both scenarios fit logit models without
interactions; their theoretical latent residual is `pi^2 / 3`.

`two_level` uses the same ordinal thresholds, the probit link, and no
interactions. Both model effects are independently redrawn in every
replication. It studies the derived variance `beta-hat^2 / 2`, including its
known positive bias; it does not fix the realised difference between models.

`sim_scenarios()` records the complete dimensions and true components from
the specification. Each study estimates every nonzero scenario component
except the link-fixed residual, plus percent GRR (study variation) and item
ICC. GRR includes all non-item components and the residual. `two_level`
additionally reports the fraction of fits with a derived model component.

## Measures and diagnoses

Each estimand has Bias, relative Bias, empirical SE and RMSE, each with MCSE
according to Formelsammlung section 9 and ADR-023. MCSE of relative Bias is
MCSE(Bias) divided by the absolute truth; MCSE(RMSE) uses the delta method.
An exactly zero RMSE has zero MCSE. The derived fraction has binomial MCSE
and uses all planned replications as its denominator.

Failed fits remain as `NA` estimates with their error and unavailable fit
counts as `NA`; no replication is replaced. Singular and non-converged fits
with finite estimates remain in the summary, with separate flags. Summary
rows give `n_sim`, `n_finite` and `n_failed`; performance calculations use
finite estimates. Every warning and message is retained in the replicate
and session files. Counts come from the returned fit, never the design plan.
The link-fixed residual is checked against the generating model.
Absent error, warning and message diagnoses are stored as `NA`, so a plain
CSV reader retains the same cells even when only a longer run has messages.

The script writes the replicate and session files before aggregation.
Fewer than two finite estimates for a required target cause a named error,
nonzero exit, an aggregation diagnosis in the session, and no result file.
An output directory with any existing file of that study is rejected before
computation. Use a fresh directory for every attempt. A process killed by the
operating system or an unwritable disk cannot promise saved output.

## Seeds, workers and files

For scenario index `j` and repetition `r`, the seed is
`20261031 + j + 8 * (r - 1)`. Permanent indices are S-ord-1 through S-ord-4,
S-bin-1 through S-bin-2, then S-two-1 and S-two-2, in that order. Each task
uses Mersenne-Twister, normal kind Inversion and sample kind Rejection, and
restores the caller's random state. Neither task order, selected scenarios,
`n_sim` nor workers change a task's draws.

On Unix the default worker count comes from ANK-TOL.sim_runtime.cores.
`LLMSA_SIM_WORKERS` may select a smaller positive integer; Windows uses the
sequential route. Parallelism is confined to these validation scripts, with
no nested parallelism or automatic fork seeding. Engine namespaces load
before forking. The session records the R/package versions, implementation
SHA-256, invocation, seeds, RNG, workers, elapsed time and all diagnoses.

For study `name`, `--out` receives `name_results.csv`, `name_replicates.csv`
and `name_session.txt`. CSVs are deterministically sorted and written with
`write.csv(row.names = FALSE)`, preserving the comparison after
`format(x, digits = 15)`. No time/version fields enter the replicates.
The committed short-run triplets have `_check_` in their names and use
ANK-TOL.n_check. They demonstrate execution and reproduction, not statistical
precision at the full-run minimum. The vignette only reads their tables.

## Full runs after code acceptance

The operator runs and commits the full triplets before M1d. The following
commands read the required minimum from the installed ANK-06 copy. Replace
the output paths with fresh directories outside the working tree; set
`R_LIBS` externally if a dedicated library is needed. There is no download.

```r
library(llmsa)
root <- system.file("validation", "sim", package = "llmsa", mustWork = TRUE)
e <- new.env(parent = globalenv())
sys.source(file.path(root, "simulation_helpers.R"), e)
n <- e$latent_anchors(e$latent_context(repo_root = ""))[["ANK-06"]]$value$n_sim_min
rscript <- file.path(R.home("bin"), "Rscript")
run <- function(study, out) {
  status <- system2(rscript, c(shQuote(file.path(root, paste0(study, ".R"))),
                              "--n-sim", n, "--out", shQuote(out)))
  if (status != 0L) stop("Study failed: ", study)
}
run("ordinal_recovery", "/path/outside/repository/ordinal-full")
run("binary_recovery", "/path/outside/repository/binary-full")
run("two_level", "/path/outside/repository/two-level-full")
```

For a short run, obtain `n` from `ANK-TOL$value$n_check$n_sim` instead. All
scenarios run by default. `--scenarios S-ord-2,S-ord-4`, for example, selects
exactly those scenarios; option order is free. Unknown/duplicate options or
IDs, empty IDs, invalid repetition numbers and seed overflow fail explicitly.
Never change seeds, designs or thresholds in response to an unfavourable fit.

If running scenarios separately, use one fresh directory per complete
scenario and the same `n_sim`, package build, R/engine versions and RNG.
The executable merger below checks these conditions, complete disjoint
coverage, schemas, keys, truths, repetition seeds and summary consistency.
It retains the individual estimates and result rows without refitting or
averaging summaries. Original sessions, paths and hashes are included in
the combined session; it does not invent a combined runtime.

```r
# With `e` loaded as above, after successful scenario runs:
e$sim_merge("ordinal_recovery",
            c("/path/ord-1", "/path/ord-2", "/path/ord-3", "/path/ord-4"),
            "/path/merged-ordinal")
e$sim_merge("binary_recovery", c("/path/bin-1", "/path/bin-2"),
            "/path/merged-binary")
e$sim_merge("two_level", c("/path/two-1", "/path/two-2"),
            "/path/merged-two-level")
```

Splitting repetitions within a scenario is not supported. After M1c, verify
the first ANK-TOL.n_check repetitions again before relying on earlier full
runs. Changes to fitting, generation, engines or seed rules may require new
operator runs. M1d checks full-run completeness, reproduction and reported
findings; a short run does not establish recovery or coverage.

## Bootstrap interval coverage

`boot_coverage.R` implements docs/02 M1c and ADR-042. It estimates coverage
and width of the existing 95% percentile intervals, using `msa_fit()`,
`msa_grr()` and `msa_boot()` from the installed package. It never supplies
`nsim` to `msa_boot()`: the package default applies to short and full runs.
Only outer repetitions are parallel; each bootstrap runs sequentially.

The data-generating model draws independent centred normal effects for every
component below and an independent normal residual per numeric observation.
The intercept is zero. S-boot-7 draws Bernoulli observations with probability
`plogis(item + prompt + model)`, with no added normal observation noise.
The logit residual variance from ANK-28 is used only in the true latent
statistics. All scenarios have three models and three replicates per cell.

| Scenario | Outcome | Items | Prompts | Blocks | Components |
| --- | --- | ---: | ---: | ---: | --- |
| S-boot-1 | numeric | 20 | 3 | 2 | A |
| S-boot-2 | numeric | 20 | 5 | 2 | A |
| S-boot-3 | numeric | 50 | 3 | 2 | A |
| S-boot-4 | numeric | 50 | 5 | 2 | A |
| S-boot-5 | numeric | 20 | 3 | 2 | B |
| S-boot-6 | numeric | 20 | 5 | 2 | B |
| S-boot-7 | binary, logit | 60 | 3 | 1 | item 1, prompt 0.1, model 0.1 |

A has item 1, prompt 0.05, model 0.05, block 0.01, item:prompt 0.01,
item:model 0.05, prompt:model 0.005 and residual 0.1. B replaces only prompt
with 0.3 and residual with 0.5. These are specification parameters.
Numeric fits use default interactions; binary fits use the logit link and
default absence of interactions. True GRR is the sum of every component
except item, and total variance includes item. True ndc uses the factor,
floor and minimum in the verified ANK-16 copy. The generator and truth
calculation do not call `msa_simulate()` or `msa_grr()`.

Every component is a point estimand, except the fixed binary residual, as
are `grr_pct_study_var`, `grr_pct_contribution`, `ndc` and `icc_items`.
The four derived statistics have intervals. The replicate file contains
`scenario`, `rep`, `estimand`, `estimate`, `true`, `lower`, `upper`, the
actual fitted `items`, `prompts`, `models`, `blocks`, `observations`, and
the actual `boot_nsim`, `boot_level`, `n_singular`, `n_failed`. Component
intervals are unavailable (`NA`). Separate columns retain both seeds,
original-fit convergence and singularity, and the stage, error, warnings
and messages of failed attempts. Absent diagnoses are `NA`.

If fitting fails, estimates, intervals and fitted/bootstrap counts are `NA`.
If only the bootstrap fails, point estimates and fit counts remain; intervals
and bootstrap counts become `NA`. No repetition is replaced. Finite
non-converged or singular original fits remain with their diagnoses.

Point estimands have Bias, relative Bias, EmpSE and RMSE with the formulas
described above. Coverage uses closed intervals with two finite endpoints;
MCSE is `sqrt(p * (1 - p) / n)`. Width uses the same intervals and has MCSE
`sd(width) / sqrt(n)`. Under estimand `bootstrap`, `singular_share` and
`failed_share` first divide the actual count by `boot_nsim` per repetition,
then average those fractions, with MCSE `sd(fraction) / sqrt(n)`. Bootstrap
refits within one outer repetition are not treated as independent Bernoulli
trials. Every result row reports its actual `n_finite` and `n_failed` outer
repetitions; `n_sim` remains the requested run length. Fewer than two usable
values of any required measure cause a named aggregation failure after saving
replicates and session diagnostics, without publishing a result file.

For S-boot-j and repetition r, the data seed is
`20261102 + 2 * (j - 1) + 14 * (r - 1)` and the bootstrap seed is one larger.
Both use Mersenne-Twister, Inversion and Rejection, restoring the caller's
RNG state. Seeds are independent of selection, order, `n_sim` and workers;
overflow is rejected before fitting. The result column `seed` is the data
seed of repetition one of its scenario. The session records the rule and
both sets of starting seeds, package versions, actual runtime and diagnoses.
The implementation SHA-256 includes fitting, bootstrap, generation, truth,
seeds and study helpers, including the reused M1b helpers.

The same `--n-sim`, `--out`, `--scenarios` and `LLMSA_SIM_WORKERS` rules apply
as above. Unknown or repeated options/scenarios and existing study outputs
are rejected. Output names are `boot_coverage_results.csv`,
`boot_coverage_replicates.csv` and `boot_coverage_session.txt`.
For the committed short run, run exactly S-boot-1 and S-boot-7 with
ANK-TOL.n_check; rename the genuine triplet to `boot_coverage_check_*`.

```r
library(llmsa)
root <- system.file("validation", "sim", package = "llmsa", mustWork = TRUE)
b <- new.env(parent = globalenv())
sys.source(file.path(root, "boot_coverage_helpers.R"), b)
run_coverage <- function(n, out, scenarios = NULL) {
  args <- c(shQuote(file.path(root, "boot_coverage.R")), "--n-sim", n,
            "--out", shQuote(out))
  if (!is.null(scenarios)) args <- c(args, "--scenarios", paste(scenarios, collapse = ","))
  status <- system2(file.path(R.home("bin"), "Rscript"), args)
  if (status != 0L) stop("Coverage study failed; inspect the output diagnostics.")
}
run_coverage(b$boot_parameters()$n_check, "/path/outside/repository/coverage-check",
             c("S-boot-1", "S-boot-7"))
# Operator, after code acceptance: all seven scenarios and at least ANK-06.
run_coverage(b$boot_parameters()$n_min, "/path/outside/repository/coverage-full")
```

For separate scenario runs, use fresh directories with the same `n_sim`,
implementation and engines. `boot_merge()` checks the versions, seeds, truths,
counts, complete disjoint scenarios and all summary calculations. It keeps
the original estimates and result rows, and records each input's hashes and
session. It does not refit or invent a combined runtime.

```r
b$boot_merge(paste0("/path/outside/repository/coverage-", seq_len(7L)),
              "/path/outside/repository/coverage-merged")
```

Measure actual wall time with the intended workers before scheduling full
runs. `elapsed_seconds` records the computation time of each run. Scale a
complete scenario's observed time by the ratio of planned repetitions only
as a planning estimate; optimizer costs vary across repetitions. Do not
shorten the bootstrap or omit slow scenarios to meet a runtime estimate.
After M1c, the operator must regenerate all three latent full runs as well
as this full study with the accepted code (ADR-041). The updated ordinal
limits change the implementation hash even for studies whose estimates stay
the same. M1d evaluates completeness, first-repetition reproduction and the
findings. Short-run coverage is not evidence of nominal coverage.

The vignette reads coverage tables through `boot_coverage_results.R` without
loading a simulation generator (ADR-043). It uses the full results file when
present, otherwise the short results file; an invalid full file is an error.
The displayed results and run size always come from the selected file.
