test_that("the latent repeatability note follows the component table without changing results", {
  # Synthetic components isolate output wording from engine variability.
  fit <- structure(list(vc = data.frame(source = c("item", "prompt", "Residual"),
    variance = c(5, 2, 1)), type = "numeric", link = "probit", singular = FALSE,
    n = list(items = 6L, prompts = 3L, models = 1L, blocks = 1L, observations = 54L)),
    class = "msa_fit")
  baseline <- msa_grr(fit)
  note <- paste0("  On the latent scale, Repeatability is the residual variance fixed by the link, ",
    "not a measurement of disagreement between replicates; see the share of cells ",
    "with identical replicates from msa_agreement().")
  for (type in c("numeric", "ordinal", "binary")) {
    fit$type <- type
    g <- msa_grr(fit)
    lines <- capture.output(returned <- withVisible(print(g)))
    expect_identical(returned, list(value = g, visible = FALSE))
    for (field in c("table", "summary", "verdict")) expect_identical(g[[field]], baseline[[field]])
    if (type == "numeric") {
      expect_false(any(grepl("On the latent scale", lines, fixed = TRUE)))
    } else {
      expect_identical(sum(lines == note), 1L)
      expect_identical(which(lines == note), grep("^[[:space:]]*Total variation", lines) + 1L)
    }
  }
})
