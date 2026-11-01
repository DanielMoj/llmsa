# Synthetic plans. The oracle expands frequency weights into observations
# and computes a singular-value rank from pairwise covariance matrices.
# It does not use the product's grouping-level Gram calculation.
latent_grid_reference <- function(d, weights, type, interactions) {
  sizes <- vapply(d, nlevels, integer(1))
  random <- names(sizes)[sizes >= if (type == "ordinal") 3L else 2L]
  fixed <- if (type == "ordinal") names(sizes)[sizes == 2L] else character()
  if (!"item" %in% random || !any(weights > 0)) return("precheck")
  if (interactions) {
    for (pair in list(c("item", "prompt"), c("item", "model"), c("prompt", "model"))) {
      if (all(sizes[pair] > 1L)) random <- c(random, paste(pair, collapse = ":"))
    }
  }
  labels <- lapply(random, function(term) {
    columns <- strsplit(term, ":", fixed = TRUE)[[1L]]
    do.call(paste, c(lapply(d[columns], as.character), sep = "/"))
  })
  if (type == "ordinal" && any(vapply(labels,
    function(x) length(unique(x[weights > 0])) <= 2L, logical(1)))) return("precheck")
  X <- if (length(fixed)) stats::model.matrix(stats::reformulate(fixed), d) else matrix(1, nrow(d), 1L)
  rows <- rep(seq_len(nrow(d)), weights)
  X <- X[rows, , drop = FALSE]
  if (qr(X)$rank < ncol(X)) return("rejected")
  P <- diag(length(rows)) - X %*% solve(crossprod(X), t(X))
  columns <- lapply(labels, function(label) {
    covariance <- outer(label[rows], label[rows], `==`) * 1
    as.vector(P %*% covariance %*% P)
  })
  pairs <- cbind(do.call(cbind, columns), as.vector(P))
  singular <- svd(pairs, nu = 0L, nv = 0L)$d
  # Squaring singular values gives Gram eigenvalues. This is the existing
  # working-precision rank rule, not an empirical comparison tolerance.
  if (min(singular)^2 <= ncol(pairs) * .Machine$double.eps * max(singular)^2) "rejected" else "identifiable"
}

test_that("384 latent decisions match independent covariance ranks (seeds 20261103 through 20261198)", {
  engine <- function(...) stop("Identifiable design reached the engine.", call. = FALSE)
  local_mocked_bindings(clmm = engine, .package = "ordinal")
  local_mocked_bindings(glmer = engine, .package = "lme4")
  for (case in seq_len(96L)) {
    set.seed(20261102L + case, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
    dimensions <- c(items = sample(3:7, 1L), prompts = sample(1:4, 1L), models = sample(1:4, 1L),
      blocks = sample(1:2, 1L), reps = sample(1:2, 1L))
    if (case %% 8L == 0L) dimensions[c("prompts", "models", "blocks", "reps")] <- 1L
    grid <- expand.grid(item = seq_len(dimensions["items"]), prompt = seq_len(dimensions["prompts"]),
      model = seq_len(dimensions["models"]), block = seq_len(dimensions["blocks"]), rep = seq_len(dimensions["reps"]))
    if (nrow(grid) > 64L) grid <- grid[sort(sample.int(nrow(grid), 64L)), ]
    topology <- case %% 6L
    if (topology == 1L) grid <- grid[sort(sample.int(nrow(grid), max(3L, floor(3 * nrow(grid) / 4)))), ]
    if (topology == 2L) grid$model <- grid$prompt
    if (topology == 3L) grid$model <- (grid$item - 1L) %% dimensions["models"] + 1L
    if (topology == 5L) grid$block <- grid$model
    weights <- if (case %% 3L == 0L) rep(1, nrow(grid)) else sample(0:2, nrow(grid), replace = TRUE)
    if (topology == 4L) weights <- (grid$prompt == grid$model) * (1 + case %% 2L)
    d <- data.frame(lapply(grid[c("item", "prompt", "model", "block")], factor))
    interactions <- case %% 2L == 1L
    for (type in c("ordinal", "binary")) {
      response <- if (type == "ordinal") sample(1:5, nrow(grid), replace = TRUE) else
        sample(0:1, nrow(grid), replace = TRUE)
      active <- which(weights > 0)
      if (length(active) >= 2L) response[active[1:2]] <- if (type == "ordinal") c(1L, 5L) else 0:1
      runs <- data.frame(item_id = d$item, prompt_id = d$prompt, model_id = d$model,
        block = d$block, rep = grid$rep,
        value = if (type == "ordinal") ordered(response, levels = 1:5) else response)
      expected <- latent_grid_reference(d, weights, type, interactions)
      if (length(unique(response[active])) < 2L) expected <- "precheck"
      for (link in c("probit", "logit")) {
        outcome <- tryCatch(msa_fit(runs, type = type, link = link,
          interactions = interactions, weights = weights), error = identity)
        expect_s3_class(outcome, "error")
        if (!inherits(outcome, "error")) next
        message <- conditionMessage(outcome)
        got <- if (identical(message, "Identifiable design reached the engine.")) "identifiable" else
          if (grepl("not identifiable", message, fixed = TRUE)) "rejected" else "precheck"
        expect_identical(got, expected,
          info = sprintf("Seed %d, %s %s, interactions %s: %s", 20261102L + case, type, link, interactions, message))
      }
    }
  }
})
