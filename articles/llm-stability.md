# Answer stability at temperature zero

The frozen public data from [Atil et al.’s llm-stability
repository](https://github.com/breckbaldwin/llm-stability) contain
**82850 calls** across **5 models**, **8 tasks** and **10 runs**. ANK-40
fixes commit **c089c02ecfdb2a7fee0b321069a2d19cb8f11ae0**, the Apache
2.0 licence and the complete v3 zero-shot selection. The model
configuration uses temperature 0 and top_p_k 1. These are recorded
historical calls; building this article makes no model calls and needs
no external data.

The preparation script `data-raw/make_llm_stability.R` verifies the
source hashes and the complete item grid before publishing the subset.
`SHA256SUMS` covers the stored gzip file and its provenance. The archive
contains other configurations, which are outside this selection.

## What counts as an answer

The parser accepts exactly one distinct valid option label such as `(A)`
in parentheses, ignoring letter case, with no spaces inside the
parentheses. Bare letters, including the English words “A” and “I”, do
not count. Repeated occurrences of the same label count once; different
labels anywhere in the response, including quoted alternatives, make the
answer ambiguous. There is no priority for a final sentence. For
`navigate`, exactly one of the whole words “Yes” or “No” is required.
The key never selects an answer. An empty, unparseable or ambiguous
response remains missing.

`correct` compares the parsed label literally with the source key. A
missing answer has missing correctness. The source also contains
non-label keys:

Non-label answer keys: ruin_names item_id 99; ruin_names item_id 144.

For these `ruin_names` items, every parsed option label counts as a miss
under literal label/key equality, even when its meaning matches the
intended answer. The data retain that limitation; the keys are not
repaired. Thus the hit rate describes this extraction rule, not a human
reassessment of the response text. The provenance records parsing
failures by reason, task and model. Raw response texts are not
distributed.

## Observed repeatability and hit rate

For each task and model, attribute repeatability is the fraction of
items with a present, identical answer in every run. A missing answer
breaks agreement. The hit rate divides the number of `correct == TRUE`
calls by **all** calls, including missing answers. The missing-answer
share is shown alongside both quantities. None of these denominators
depends on a fit.

``` r

cells <- split(items, list(items$task, items$model), drop = TRUE)
rates <- do.call(rbind, lapply(cells, function(d) {
  answers <- split(d$answer, d$item_id)
  identical_answers <- vapply(answers, function(x) !anyNA(x) && length(unique(x)) == 1L, logical(1))
  data.frame(task = d$task[1L], model = d$model[1L], items = length(answers), calls = nrow(d),
    answer_repeatability = mean(identical_answers), hit_rate = mean(d$correct %in% TRUE),
    missing_answer_share = mean(is.na(d$answer)))
}))
rownames(rates) <- NULL
```

| task | model | items | calls | answer_repeatability | hit_rate | missing_answer_share |
|:---|:---|:---|:---|:---|:---|:---|
| college_mathematics | gpt-35-turbo | 100 | 1000 | 0.42 | 0.325 | 0.254 |
| geometric_shapes | gpt-35-turbo | 250 | 2500 | 0.928 | 0.1552 | 0 |
| high_school_european_history | gpt-35-turbo | 165 | 1650 | 0.9212 | 0.7448 | 0.05455 |
| logical_deduction | gpt-35-turbo | 250 | 2500 | 0.924 | 0.5104 | 0.01 |
| navigate | gpt-35-turbo | 250 | 2500 | 0.944 | 0.648 | 0 |
| professional_accounting | gpt-35-turbo | 282 | 2820 | 0.8511 | 0.5564 | 0.02979 |
| public_relations | gpt-35-turbo | 110 | 1100 | 0.9273 | 0.6618 | 0.06364 |
| ruin_names | gpt-35-turbo | 250 | 2500 | 0.952 | 0.6548 | 0.02 |
| college_mathematics | gpt-4o | 100 | 1000 | 0.32 | 0.444 | 0.439 |
| geometric_shapes | gpt-4o | 250 | 2500 | 0.544 | 0.6156 | 0.0016 |
| high_school_european_history | gpt-4o | 165 | 1650 | 0.8848 | 0.8297 | 0.06121 |
| logical_deduction | gpt-4o | 250 | 2500 | 0.836 | 0.9392 | 0.0508 |
| navigate | gpt-4o | 250 | 2500 | 0.908 | 0.92 | 0.0188 |
| professional_accounting | gpt-4o | 282 | 2820 | 0.8227 | 0.8791 | 0.07553 |
| public_relations | gpt-4o | 110 | 1100 | 0.8364 | 0.7355 | 0.07727 |
| ruin_names | gpt-4o | 250 | 2500 | 0.932 | 0.8292 | 0.0044 |
| college_mathematics | llama3-70b | 100 | 1000 | 0.35 | 0.438 | 0.338 |
| geometric_shapes | llama3-70b | 250 | 2500 | 0.58 | 0.36 | 0.022 |
| high_school_european_history | llama3-70b | 165 | 1650 | 0.5576 | 0.5758 | 0.32 |
| logical_deduction | llama3-70b | 250 | 2500 | 0.836 | 0.8704 | 0.0584 |
| navigate | llama3-70b | 250 | 2500 | 0.828 | 0.878 | 0.018 |
| professional_accounting | llama3-70b | 282 | 2820 | 0.3475 | 0.356 | 0.4734 |
| public_relations | llama3-70b | 110 | 1100 | 0.3364 | 0.3036 | 0.57 |
| ruin_names | llama3-70b | 250 | 2500 | 0.756 | 0.718 | 0.138 |
| college_mathematics | llama3-8b | 100 | 1000 | 0.29 | 0.234 | 0.349 |
| geometric_shapes | llama3-8b | 250 | 2500 | 0.62 | 0.2472 | 0.1116 |
| high_school_european_history | llama3-8b | 165 | 1650 | 0.7758 | 0.643 | 0.1848 |
| logical_deduction | llama3-8b | 250 | 2500 | 0.744 | 0.5944 | 0.0708 |
| navigate | llama3-8b | 250 | 2500 | 0.652 | 0.7288 | 0.0052 |
| professional_accounting | llama3-8b | 282 | 2820 | 0.422 | 0.2255 | 0.4826 |
| public_relations | llama3-8b | 110 | 1100 | 0.4818 | 0.3064 | 0.4745 |
| ruin_names | llama3-8b | 250 | 2500 | 0.712 | 0.4936 | 0.1928 |
| college_mathematics | mixtral-8x7b | 100 | 1000 | 0.31 | 0.263 | 0.367 |
| geometric_shapes | mixtral-8x7b | 250 | 2500 | 0.884 | 0.2524 | 0.076 |
| high_school_european_history | mixtral-8x7b | 165 | 1650 | 0.697 | 0.6467 | 0.1909 |
| logical_deduction | mixtral-8x7b | 250 | 2500 | 0.772 | 0.606 | 0.0964 |
| navigate | mixtral-8x7b | 250 | 2500 | 0.76 | 0.5736 | 0.0528 |
| professional_accounting | mixtral-8x7b | 282 | 2820 | 0.4965 | 0.3631 | 0.311 |
| public_relations | mixtral-8x7b | 110 | 1100 | 0.6455 | 0.5518 | 0.2509 |
| ruin_names | mixtral-8x7b | 250 | 2500 | 0.868 | 0.5244 | 0.066 |

Observed proportions, with all items or calls in the denominator.
{.table style="width:100%;"}

## Binary variance components

Each task gets its own binary fit. Item is the question, model is the
source model, and replicate is the original run number. The one prompt
and one block level are constant.
[`msa_counts()`](https://danielmoj.github.io/llmsa/reference/msa_counts.md)
counts all imported calls, including those whose correctness is missing.
The fit drops those missing responses, with its warning recorded below;
it does not recode them as false. Fits use the default probit link and
no interactions. Each fit and
[`msa_grr()`](https://danielmoj.github.io/llmsa/reference/msa_grr.md) is
recomputed here.

``` r

analyses <- lapply(unique(items$task), function(task) {
  d <- items[items$task == task, , drop = FALSE]
  runs <- as_msa_runs(data.frame(item_id = as.character(d$item_id), prompt_id = "task",
                                 model_id = d$model, rep = d$run, value = as.integer(d$correct)))
  counts <- msa_counts(runs)
  diagnostics <- character()
  fit <- withCallingHandlers(msa_fit(runs, type = "binary", interactions = FALSE, link = "probit"),
    warning = function(w) {
      diagnostics <<- c(diagnostics, conditionMessage(w)); invokeRestart("muffleWarning")
    }, message = function(m) {
      diagnostics <<- c(diagnostics, conditionMessage(m)); invokeRestart("muffleMessage")
    })
  grr <- msa_grr(fit)
  components <- setNames(fit$vc$variance, fit$vc$source)
  list(counts = data.frame(task = task, counts),
    summary = data.frame(task = task, item = components[["item"]], model = components[["model"]],
      grr_pct_study_var = grr$summary[["grr_pct_study_var"]], observations = fit$n$observations,
      converged = fit$converged, singular = fit$singular),
    diagnostics = data.frame(task = task, diagnostic = if (length(diagnostics)) paste(unique(diagnostics), collapse = " | ") else "none"))
})
```

| task                         | prompt_id | model_id     |    n | n_valid |
|:-----------------------------|:----------|:-------------|-----:|--------:|
| college_mathematics          | task      | gpt-35-turbo | 1000 |     746 |
| college_mathematics          | task      | gpt-4o       | 1000 |     561 |
| college_mathematics          | task      | llama3-70b   | 1000 |     662 |
| college_mathematics          | task      | llama3-8b    | 1000 |     651 |
| college_mathematics          | task      | mixtral-8x7b | 1000 |     633 |
| geometric_shapes             | task      | gpt-35-turbo | 2500 |    2500 |
| geometric_shapes             | task      | gpt-4o       | 2500 |    2496 |
| geometric_shapes             | task      | llama3-70b   | 2500 |    2445 |
| geometric_shapes             | task      | llama3-8b    | 2500 |    2221 |
| geometric_shapes             | task      | mixtral-8x7b | 2500 |    2310 |
| high_school_european_history | task      | gpt-35-turbo | 1650 |    1560 |
| high_school_european_history | task      | gpt-4o       | 1650 |    1549 |
| high_school_european_history | task      | llama3-70b   | 1650 |    1122 |
| high_school_european_history | task      | llama3-8b    | 1650 |    1345 |
| high_school_european_history | task      | mixtral-8x7b | 1650 |    1335 |
| logical_deduction            | task      | gpt-35-turbo | 2500 |    2475 |
| logical_deduction            | task      | gpt-4o       | 2500 |    2373 |
| logical_deduction            | task      | llama3-70b   | 2500 |    2354 |
| logical_deduction            | task      | llama3-8b    | 2500 |    2323 |
| logical_deduction            | task      | mixtral-8x7b | 2500 |    2259 |
| navigate                     | task      | gpt-35-turbo | 2500 |    2500 |
| navigate                     | task      | gpt-4o       | 2500 |    2453 |
| navigate                     | task      | llama3-70b   | 2500 |    2455 |
| navigate                     | task      | llama3-8b    | 2500 |    2487 |
| navigate                     | task      | mixtral-8x7b | 2500 |    2368 |
| professional_accounting      | task      | gpt-35-turbo | 2820 |    2736 |
| professional_accounting      | task      | gpt-4o       | 2820 |    2607 |
| professional_accounting      | task      | llama3-70b   | 2820 |    1485 |
| professional_accounting      | task      | llama3-8b    | 2820 |    1459 |
| professional_accounting      | task      | mixtral-8x7b | 2820 |    1943 |
| public_relations             | task      | gpt-35-turbo | 1100 |    1030 |
| public_relations             | task      | gpt-4o       | 1100 |    1015 |
| public_relations             | task      | llama3-70b   | 1100 |     473 |
| public_relations             | task      | llama3-8b    | 1100 |     578 |
| public_relations             | task      | mixtral-8x7b | 1100 |     824 |
| ruin_names                   | task      | gpt-35-turbo | 2500 |    2450 |
| ruin_names                   | task      | gpt-4o       | 2500 |    2489 |
| ruin_names                   | task      | llama3-70b   | 2500 |    2155 |
| ruin_names                   | task      | llama3-8b    | 2500 |    2018 |
| ruin_names                   | task      | mixtral-8x7b | 2500 |    2335 |

Imported counts from msa_counts(); missing responses are included.
{.table}

| task | item | model | grr_pct_study_var | observations | converged | singular |
|:---|:---|:---|:---|:---|:---|:---|
| college_mathematics | 1.744 | 0.4297 | 67.11 | 3253 | TRUE | FALSE |
| geometric_shapes | 4.115 | 0.7245 | 54.35 | 11972 | TRUE | FALSE |
| high_school_european_history | 44.1 | 0.2339 | 16.5 | 6911 | TRUE | FALSE |
| logical_deduction | 1.68 | 1.39 | 76.64 | 11784 | TRUE | FALSE |
| navigate | 1.78 | 0.5192 | 67.86 | 12263 | TRUE | FALSE |
| professional_accounting | 4.5 | 1.197 | 57.28 | 10230 | TRUE | FALSE |
| public_relations | 42.14 | 0.1916 | 16.58 | 3920 | TRUE | FALSE |
| ruin_names | 5.37 | 0.4123 | 45.63 | 11447 | TRUE | FALSE |

Latent variance components and percent GRR study variation. {.table}

| task                         | diagnostic                             |
|:-----------------------------|:---------------------------------------|
| college_mathematics          | 1747 missing response(s) were dropped. |
| geometric_shapes             | 528 missing response(s) were dropped.  |
| high_school_european_history | 1339 missing response(s) were dropped. |
| logical_deduction            | 716 missing response(s) were dropped.  |
| navigate                     | 237 missing response(s) were dropped.  |
| professional_accounting      | 3870 missing response(s) were dropped. |
| public_relations             | 1580 missing response(s) were dropped. |
| ruin_names                   | 1053 missing response(s) were dropped. |

Recorded fit warnings and messages. {.table}

The latent residual variance is fixed by the link. It is not a
measurement of observed disagreement between repeated calls; use the
answer-repeatability table for that question. Large latent item
components can accompany a flat likelihood, and missing responses can
select which calls enter the model. The convergence and singularity
flags describe the actual fit. AIAG bands on this scale are conventions,
not evidence of correctness or suitability for another use. See
[`vignette("validation")`](https://danielmoj.github.io/llmsa/articles/validation.md)
for engine comparisons and the simulation findings, including bias with
few prompt or model levels.
