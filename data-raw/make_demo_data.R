# Simulated demonstration data with known variance components.
# Run from the package root: source("data-raw/make_demo_data.R")

set.seed(20261020)

# --- acmg_demo: ordinal five-tier classification --------------------------
# 60 variants, 4 prompt variants, 3 models, 3 replicates.
# Latent scale: item truth + prompt effect + model effect + item:model + noise,
# cut at fixed thresholds into B < LB < VUS < LP < P.
levels_acmg <- c("B", "LB", "VUS", "LP", "P")
n_items <- 60
item_truth <- rnorm(n_items, 0, 1.6)
thresholds <- c(-1.5, -0.5, 0.5, 1.5)
reference <- levels_acmg[findInterval(item_truth, thresholds) + 1]
items <- sprintf("VAR%03d", seq_len(n_items))
prompts <- c("concise", "role", "criteria", "json")
models <- c("model-a", "model-b", "model-c")
prompt_eff <- setNames(rnorm(4, 0, 0.25), prompts)
model_eff <- setNames(c(0.05, -0.30, 0.20), models)
d <- expand.grid(rep = 1:3, model_id = models, prompt_id = prompts, item_id = items,
                 stringsAsFactors = FALSE)
d <- d[, c("item_id", "prompt_id", "model_id", "rep")]
im <- rnorm(n_items * 3, 0, 0.30)
names(im) <- as.vector(outer(items, models, paste, sep = "|"))
eta <- item_truth[match(d$item_id, items)] + prompt_eff[d$prompt_id] + model_eff[d$model_id] +
  im[paste(d$item_id, d$model_id, sep = "|")] + rnorm(nrow(d), 0, 0.45)
d$value <- levels_acmg[findInterval(eta, thresholds) + 1]
# a few unparseable responses
d$value[sample.int(nrow(d), 12)] <- NA
d$reference <- reference[match(d$item_id, items)]
d$block <- 1L
acmg_demo <- d[, c("block", "item_id", "prompt_id", "model_id", "rep", "value", "reference")]
rownames(acmg_demo) <- NULL
class(acmg_demo) <- c("msa_runs", "data.frame")
attr(acmg_demo, "simulation") <- list(item_sd = 1.6, prompt_sd = 0.25, model_eff = model_eff,
                                      item_model_sd = 0.30, residual_sd = 0.45,
                                      thresholds = thresholds)

# --- ic50_demo: numeric extraction (log10 IC50 in nM) ----------------------
# 40 compounds, 3 prompt variants, 3 models, 3 replicates, 2 blocks (days).
n_c <- 40
truth <- rnorm(n_c, 2.0, 1.0)             # log10 IC50
comp <- sprintf("CPD%03d", seq_len(n_c))
prompts2 <- c("direct", "stepwise", "table")
models2 <- c("model-a", "model-b", "model-c")
pe <- setNames(c(0.00, 0.08, -0.05), prompts2)
me <- setNames(c(0.00, -0.12, 0.10), models2)
be <- c(0, 0.04)
d2 <- expand.grid(rep = 1:3, model_id = models2, prompt_id = prompts2, item_id = comp,
                  block = 1:2, stringsAsFactors = FALSE)
d2 <- d2[, c("block", "item_id", "prompt_id", "model_id", "rep")]
im2 <- rnorm(n_c * 3, 0, 0.08)
names(im2) <- as.vector(outer(comp, models2, paste, sep = "|"))
d2$value <- truth[match(d2$item_id, comp)] + pe[d2$prompt_id] + me[d2$model_id] + be[d2$block] +
  im2[paste(d2$item_id, d2$model_id, sep = "|")] + rnorm(nrow(d2), 0, 0.12)
d2$value <- round(d2$value, 3)
d2$value[sample.int(nrow(d2), 8)] <- NA
d2$reference <- round(truth[match(d2$item_id, comp)], 3)
ic50_demo <- d2
rownames(ic50_demo) <- NULL
class(ic50_demo) <- c("msa_runs", "data.frame")
attr(ic50_demo, "simulation") <- list(item_sd = 1.0, prompt_eff = pe, model_eff = me,
                                      block_eff = be, item_model_sd = 0.08, residual_sd = 0.12)

save(acmg_demo, file = "data/acmg_demo.rda", compress = "xz", version = 2)
save(ic50_demo, file = "data/ic50_demo.rda", compress = "xz", version = 2)
cat("acmg_demo:", nrow(acmg_demo), "rows; ic50_demo:", nrow(ic50_demo), "rows\n")
