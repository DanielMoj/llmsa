#' Simulated ACMG/AMP variant classifications by an LLM pipeline
#'
#' A simulated crossed study: 60 variants classified into the five ACMG/AMP
#' tiers (`B` benign, `LB` likely benign, `VUS` uncertain significance,
#' `LP` likely pathogenic, `P` pathogenic) under 4 prompt variants and 3
#' models, 3 replicates each (2160 calls, 12 of them unparseable). The data
#' were generated from a latent-variable model with known variance
#' components (see `attr(acmg_demo, "simulation")` and
#' `data-raw/make_demo_data.R`); `reference` is the true tier. No real
#' variants or models are involved.
#'
#' @format An `msa_runs` data.frame with columns `block`, `item_id`,
#'   `prompt_id`, `model_id`, `rep`, `value`, `reference`.
#' @examples
#' head(acmg_demo)
#' table(acmg_demo$value, useNA = "ifany")
"acmg_demo"

#' Simulated numeric extraction (log10 IC50) by an LLM pipeline
#'
#' A simulated crossed study with a numeric outcome: 40 compounds, 3 prompt
#' variants, 3 models, 3 replicates in each of 2 blocks (days), 2160 calls
#' with 8 missing values. Generated with known effects of prompt, model,
#' block and item:model interaction (see `attr(ic50_demo, "simulation")`);
#' `reference` is the true value.
#'
#' @format An `msa_runs` data.frame with columns `block`, `item_id`,
#'   `prompt_id`, `model_id`, `rep`, `value`, `reference`.
#' @examples
#' head(ic50_demo)
#' msa_grr(msa_fit(ic50_demo, type = "numeric"))
"ic50_demo"
