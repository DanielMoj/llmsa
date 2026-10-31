# K-M1b-4: behaviour with two levels. A factor with exactly two levels enters
# an ordinal fit (type = "ordinal") as a fixed effect, its component appears
# in vc with attr(vc, "derived"), print.msa_fit and print.msa_grr mark it as
# derived ("range method, see ?msa_fit"), and msa_fit always emits a
# warning() in this case that names the substitute procedure, its known
# positive bias (E[beta-hat^2/2] = sigma^2 + Var(beta-hat)/2) and the
# reference to the documentation; the documentation of msa_fit() refers to the
# simulation study two_level and the table in vignettes/validation.Rmd.
# Mini-reference (Formelsammlung §4): beta-hat from a direct ordinal::clmm
# with the factor as a fixed effect; the component is the sample variance of
# the level effects {0, beta-hat}. Contract details: CRITERIA.json, ACC-9.
# The test data are constructed from the latent model (setup-m1b.R).

acc_m1b_4_derived_note <- "range method, see ?msa_fit"

acc_m1b_4_fit <- function(name) {
  key <- paste0("m1b4_", name)
  if (is.null(acc_m1b[[key]])) {
    runs <- switch(name,
      two_models = acc_m1b_ordinal_runs(seed = 41L, items = 15L, prompts = 3L, models = 2L, reps = 2L),
      two_blocks = acc_m1b_ordinal_runs(seed = 42L, items = 15L, prompts = 3L, models = 3L, reps = 1L, blocks = 2L),
      three_models = acc_m1b_ordinal_runs(seed = 43L, items = 15L, prompts = 3L, models = 3L, reps = 2L))
    acc_m1b[[key]] <- c(list(runs = runs),
                        acc_m1b_catch(msa_fit(runs, type = "ordinal", levels = acc_m1b_ordinal_levels())))
  }
  acc_m1b[[key]]
}

acc_m1b_4_random_groups <- function(formula) {
  vapply(lme4::findbars(formula), function(b) paste(deparse(b[[3]]), collapse = ""), character(1))
}

acc_m1b_4_fixed_terms <- function(formula) attr(stats::terms(lme4::nobars(formula)), "term.labels")

for (case in list(list(name = "two_models", factor = "model"), list(name = "two_blocks", factor = "block"))) {
  test_that(sprintf("K-M1b-4: with two levels of %s the ordinal fit takes %s as a fixed effect and lists it in attr(vc, \"derived\")",
                    case$factor, case$factor), {
    fit <- acc_m1b_4_fit(case$name)$value
    expect_s3_class(fit, "msa_fit")
    if (!inherits(fit, "msa_fit")) return(invisible())
    expect_true(case$factor %in% acc_m1b_4_fixed_terms(fit$formula), label = paste(case$factor, "is a fixed term of formula"))
    expect_false(case$factor %in% acc_m1b_4_random_groups(fit$formula), label = paste(case$factor, "is a random term of formula"))
    expect_true(case$factor %in% attr(fit$vc, "derived"), label = sprintf("attr(vc, \"derived\") names %s", case$factor))
    expect_true(case$factor %in% fit$vc$source, label = sprintf("vc has a row for %s", case$factor))
  })

  test_that(sprintf("K-M1b-4: msa_fit warns for the two-level %s with the range method, its positive bias Var(beta)/2 and ?msa_fit",
                    case$factor), {
    w <- acc_m1b_4_fit(case$name)$warnings
    hit <- w[grepl("range method", w, ignore.case = TRUE)]
    expect_gte(length(hit), 1L, label = sprintf("warnings naming the range method (all warnings: %s)", paste(w, collapse = " | ")))
    if (!length(hit)) return(invisible())
    msg <- paste(hit, collapse = " ")
    expect_true(grepl("positive", msg, ignore.case = TRUE) && grepl("bias", msg, ignore.case = TRUE),
                label = "the warning names the positive bias")
    expect_true(grepl("Var(", msg, fixed = TRUE), label = "the warning gives the bias term Var(beta-hat)/2")
    expect_true(grepl("?msa_fit", msg, fixed = TRUE), label = "the warning refers to the documentation ?msa_fit")
  })
}

test_that("K-M1b-4: the derived component equals beta-hat^2/2 of a direct ordinal::clmm with model as a fixed effect (Formelsammlung §4; ankerRef: ANK-TOL.engine_ordinal)", {
  res <- acc_m1b_4_fit("two_models")
  fit <- res$value
  expect_s3_class(fit, "msa_fit")
  if (!inherits(fit, "msa_fit")) return(invisible())
  d <- acc_m1b_frame(res$runs, "ordinal", acc_m1b_ordinal_levels())
  direct <- ordinal::clmm(y ~ 1 + model + (1 | item) + (1 | prompt), data = d, link = "probit")
  beta <- stats::coef(direct)[[paste0("model", levels(d$model)[2])]]
  comp <- acc_m1b_clmm_components(direct)
  ref <- c(item = comp[["item"]], prompt = comp[["prompt"]], model = acc_m1b_range_component(beta),
           Residual = acc_m1b_latent_residual("probit"))
  acc_m1a_expect_components(acc_m1a_components(fit), ref, acc_m1b_engine_tol(), sum(ref), "two models, probit")
})

test_that("K-M1b-4: print.msa_fit marks the derived component (\"range method, see ?msa_fit\")", {
  fit <- acc_m1b_4_fit("two_models")$value
  expect_s3_class(fit, "msa_fit")
  if (!inherits(fit, "msa_fit")) return(invisible())
  out <- utils::capture.output(print(fit))
  line <- out[grepl(acc_m1b_4_derived_note, out, fixed = TRUE)]
  expect_gte(length(line), 1L, label = "lines of print(fit) with the derived note")
  expect_true(any(grepl("model", line, fixed = TRUE)), label = "the derived note names the component model")
})

test_that("K-M1b-4: print.msa_grr marks the derived component (\"range method, see ?msa_fit\")", {
  fit <- acc_m1b_4_fit("two_models")$value
  expect_s3_class(fit, "msa_fit")
  if (!inherits(fit, "msa_fit")) return(invisible())
  out <- utils::capture.output(print(msa_grr(fit)))
  line <- out[grepl(acc_m1b_4_derived_note, out, fixed = TRUE)]
  expect_gte(length(line), 1L, label = "lines of print(msa_grr(fit)) with the derived note")
  expect_true(any(grepl("model", line, fixed = TRUE)), label = "the derived note names the component model")
})

test_that("K-M1b-4: without a two-level factor there is no derived component, no range-method warning and no derived note", {
  res <- acc_m1b_4_fit("three_models")
  fit <- res$value
  expect_s3_class(fit, "msa_fit")
  if (!inherits(fit, "msa_fit")) return(invisible())
  expect_length(attr(fit$vc, "derived"), 0L)
  expect_false(any(grepl("range method", res$warnings, ignore.case = TRUE)))
  expect_false(any(grepl(acc_m1b_4_derived_note, utils::capture.output(print(fit)), fixed = TRUE)))
  expect_false(any(grepl(acc_m1b_4_derived_note, utils::capture.output(print(msa_grr(fit))), fixed = TRUE)))
})

test_that("K-M1b-4: the documentation of msa_fit() refers to the simulation study two_level and the table in vignettes/validation.Rmd", {
  txt <- acc_m1b_rd_text("msa_fit")
  expect_true(grepl("two_level", txt, fixed = TRUE), label = "man/msa_fit.Rd names the study two_level")
  expect_true(grepl("vignette(\"validation\"", txt, fixed = TRUE) || grepl("validation.Rmd", txt, fixed = TRUE),
              label = "man/msa_fit.Rd refers to the vignette validation (vignette(\"validation\" ...) or validation.Rmd)")
})
