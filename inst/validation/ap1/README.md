# Running the AP1 study

AP1 is an internal application of llmsa. The approved design is in `plan.yaml`;
the four entry points are `llmsa:::acmg_items()`, `acmg_prompts()`, `acmg_plan()`
and `acmg_evaluate()`. Statistics remain provisional until M1 is accepted.
Re-evaluate the same store after M1 without collecting new responses.

Run the commands below from the source-package root with the frozen toolchain.
The runner uses the source package through `pkgload`. Every invocation requires
an explicit `--backend mock` or `--backend api`, including evaluation. There is
no implicit API mode. The API path reads `OPENAI_API_KEY` and
`OPENROUTER_API_KEY` from the operator's environment; the mock and evaluation
paths do not read credentials. Do not place credentials in the plan or commands.

## Stores and reports

Choose an absolute path outside the working tree with a `.sqlite`, `.sqlite3`
or `.db` extension. Without `--store`, the path is
`../llmsa-runs/ap1_runs.sqlite`. Reports must also be outside the tree; an
omitted `--report-dir` uses a temporary directory. The persistent
`ap1_metadata` table identifies the store as `api` or `mock`. A conflicting mode
or response provenance aborts before requests or writes, including in a store
containing only failed calls. Use separate stores for synthetic and API runs.

The runs table retains raw replies, parsed values, errors, request hashes,
timestamps and response metadata. It does not save rendered prompts or item
reference/protein columns. Treat raw replies as study data. Copy the closed
store after each part/block and record its SHA-256 outside the working tree.
The mode marker is included in every SQLite copy.

## Offline exercise

These commands produce explicitly synthetic responses. The mock never reads
the reference classes to choose an answer. Mock results do not establish
provider identity or API costs and therefore cannot pass the API pilot rules.

```sh
Rscript --vanilla inst/validation/ap1/run.R --part pilot --backend mock --store /absolute/studies/ap1-mock.sqlite
Rscript --vanilla inst/validation/ap1/run.R --part main --backend mock --store /absolute/studies/ap1-mock.sqlite
Rscript --vanilla inst/validation/ap1/run.R --part robustness --backend mock --store /absolute/studies/ap1-mock.sqlite
Rscript --vanilla inst/validation/ap1/run.R --evaluate-only --backend mock --store /absolute/studies/ap1-mock.sqlite --report-dir /absolute/studies/ap1-mock-reports
```

## API collection

Before collection, the operator checks access, prices, spending limits and
logging/training settings against `docs/03` A.8. Use the dedicated AP1 accounts
and keys. The plan fixes model IDs, endpoints, provider order, quantizations,
seeds and reasoning effort. Routed requests disallow fallback. Sol omits the
temperature field; Qwen receives no reasoning override. Token assumptions in
the cost plan are not request limits. Each request uses the client timeout
`timeout_s` of its model from the plan (1800 s). It is meant to stop hung
connections; at the slowest Qwen throughput seen in pilot 2 it still allows the
longest answer the Qwen endpoint can return (ADR-014). Plan changes require an
ADR.

```sh
Rscript --vanilla inst/validation/ap1/run.R --part pilot --backend api --store /absolute/studies/ap1-api.sqlite
```

The pilot makes 30 calls per model on the ten disjoint pilot items. It reports
five rules per model, median and maximum latency, completion tokens, reasoning
tokens and projected costs. Recognized classes, including incorrect
classifications, count toward the required 27 parser hits. Missing or duplicated
keys prevent a pass. Costs use the completion-token 90th percentile, including
reasoning, for all planned main and PB calls. The sum must be strictly below the
budget using the approved numeric USD/EUR comparison; no exchange rate is
introduced. Missing provider or usage metadata cannot establish a pass. Backend
errors, stored calls with an error such as a client timeout, may make up at most
`error_share_trigger` of a model's pilot calls, that is 1 of 30; unreadable
answers are parser failures, not backend errors. A pilot that would trigger a
repeat day in the main plan therefore does not pass (ADR-014).

The pilot command exits successfully even when a rule fails: inspect its
`passed`/`failed` output. Both API main and API robustness commands refuse to
start until every model passes every rule in the same API store. There is no
override. If a provider is missing from a response, the pilot prints the
affected response IDs for the operator's sample check through
`GET /api/v1/generation`. The builder does not invent the provider. A change to
the evidence path or plan needs the ADR process.

Resume skips every stored call key, including failed calls. A new pilot after
a failed pilot therefore needs a **new store**. Archive the old store and its
hash; repeatedly invoking the same command does not replace failed calls.

After a passing pilot, archive its store. Collect the two main blocks on
separate days; the complete seeded order is generated before block filtering.

```sh
Rscript --vanilla inst/validation/ap1/run.R --part main --block 1 --backend api --store /absolute/studies/ap1-api.sqlite
Rscript --vanilla inst/validation/ap1/run.R --part main --block 2 --backend api --store /absolute/studies/ap1-api.sqlite
Rscript --vanilla inst/validation/ap1/run.R --part robustness --backend api --store /absolute/studies/ap1-api.sqlite --insaid-path /absolute/local/insaid_vangijn2018.tsv
```

After each block, diagnostics identify changed serving providers, changed model
snapshots and backend error shares strictly above the approved threshold.
Parsing failures are reported separately. A repeat day is an operator decision:
archive the replaced post-block store and its SHA-256, restore a copy from
**before the affected block**, and collect that block into the restored copy.
Resuming the post-block store would skip its keys. Keep later blocks in separate
archived copies and continue the approved collection sequence from the restored
store; do not merge duplicate calls into an evaluation.

API robustness requires the local INSAID TSV whose SHA-256 is recorded in the
shipped `extdata/items_ap1_2026-10-24/QUELLE.txt`. Missing or incorrect input
aborts before any request. References and protein notation are joined only in
memory. F2 uses the available protein notation; INSAID reference classes are
never persisted by this pipeline. The source TSV remains outside the repository.

## Evaluation and interpretation

```sh
Rscript --vanilla inst/validation/ap1/run.R --evaluate-only --backend api --store /absolute/studies/ap1-api.sqlite --insaid-path /absolute/local/insaid_vangijn2018.tsv --report-dir /absolute/studies/ap1-api-reports
```

Evaluation makes no API requests. The TSV is optional for evaluation: without
it, INSAID references stay missing, and reference metrics use available ERepo
references. The command and reports state that basis, eligible counts and
exclusions. With the TSV, reports expose INSAID references only as aggregate
metrics. Each model gets its own report. Constructed runs without response
metadata are labelled `unverified`, never represented as an API collection.
Synthetic provenance is an additional label and does not replace statistical
bands.

Main assessment needs exactly 18 calls per item/model with valid unique design
keys. PB assessment needs exactly one call per item/prompt/model. Missing,
additional or duplicated cells prevent full assessment. Errors and missing
responses remain in the planned denominators. NA is a modal category; ties
have no modal response. Reference metrics exclude ties and missing references,
but NA modal responses are errors with agreement weight zero. The separately
reported `msa_agreement()` values are complete-case diagnostics.

Ordinal probit fits fall back to numeric scores only on a fit error or a
convergence warning as defined in ADR-006. All warnings and available diagnostics
are retained. A mere optimizer switch or a zero variance component does not
trigger fallback. Numeric fallback uses the package defaults, including
interactions. Undefined or incomplete criteria and the corresponding overall
assessment remain `not assessed`. The joint fit is a research result without
a verdict.

The report lists the approved thresholds, item-bootstrap interval, stratified
reference metrics, dangerous ERepo errors, PB effects and half-normal plot,
request/response metadata, policy evidence, hashes and versions. Percent GRR
comparisons require the same item set. Sol's provider-default temperature and
the open models' temperature zero prevent a direct repeatability comparison.
The frozen OpenRouter logging page contains no CoreWeave or DeepInfra-specific
retention record; this evidence gap is stated in the plan and reports. The
operator must supply a dated provider-specific record before such a policy
can be claimed.

To regenerate the shipped item freeze, the operator supplies the anchored
sources under `../quellen/daten/` and runs `Rscript --vanilla
data-raw/make_items_ap1.R` from the repository root. The script verifies source
hashes and schemas before changing any output, downloads nothing, and writes
the two CSVs, provenance and checksums. A changed freeze requires a Golden ADR.
