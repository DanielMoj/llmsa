#' Estimate the variance components of an LLM measurement system
#'
#' Fits a crossed random-effects model to the parsed values of a study.
#' Items, prompt variants, models and blocks enter as random effects; for
#' numeric outcomes the interactions item:prompt, item:model and
#' prompt:model are included by default. The residual variance is the
#' repeatability (replicate-to-replicate variation under identical
#' conditions).
#'
#' * `type = "numeric"`: linear mixed model fitted by REML, returned as
#'   an [lme4::lmer()] model. See the numeric fitting details below.
#' * `type = "ordinal"`: cumulative link mixed model with
#'   [ordinal::clmm()]. Variance components live on the latent scale, where
#'   the residual variance is fixed (1 for the probit link, pi^2/3 for the
#'   logit link). Interactions are off by default because they are costly in
#'   `clmm`.
#' * `type = "binary"`: generalised linear mixed model with
#'   [lme4::glmer()] and the same latent-scale convention.
#'
#' Factors with a single level (for example one model only) are dropped
#' from the model automatically. For ordinal outcomes `ordinal::clmm`
#' requires more than two levels per random-effect factor; a factor with
#' exactly two levels (two models, two blocks) therefore enters as a fixed
#' effect and its variance component is derived from the estimated
#' difference `beta` by the range method (`beta^2 / 2`). This substitute
#' does not subtract the AIAG handbook correction `EV^2 / (n * r)`.
#' It has positive bias: `E[beta-hat^2 / 2] = sigma^2 + Var(beta-hat) / 2`.
#' Every such fit warns and both print methods identify the derived sources.
#' The `two_level` simulation study and its table in
#' `vignette("validation")` (`vignettes/validation.Rmd`) investigate that
#' bias. Short runs establish reproducibility; quantitative findings require
#' the full simulation runs. With fewer than three ordinal items the error is
#' "At least three items are needed for ordinal outcomes."
#'
#' @param runs An `msa_runs` object (from [msa_run()] or [as_msa_runs()]).
#' @param type Outcome type.
#' @param levels For ordinal outcomes: at least two distinct, non-missing,
#'   non-empty labels in scale order. For binary outcomes: two such labels,
#'   whose second element is the event. When supplied, these labels determine
#'   the coding regardless of the response's storage type. Labels require
#'   this explicit argument; their order of occurrence or factor levels do
#'   not determine the event.
#' @param interactions Include the two-way interactions as random effects?
#'   Default `TRUE` for numeric, `FALSE` otherwise.
#' @param link Link for ordinal and binary outcomes.
#' @param ... Passed on to the model-fitting function. For numeric outcomes,
#'   supplying any argument here selects a direct [lme4::lmer()] call on
#'   the original response, including when an argument is explicitly `NULL`.
#'   Expressions in `subset`, `weights` and `offset` can use the internal
#'   columns `item`, `prompt`, `model`, `block` and `y`. Row-based arguments
#'   refer to the rows remaining after missing or unreadable responses are
#'   removed. Other symbols in these expressions are looked up in the
#'   immediate caller of `msa_fit()`, as in a direct `lmer()` call; a wrapper
#'   forwarding `...` must make them available in that frame. Other arguments
#'   retain their original argument environments when forwarded.
#'
#' @details
#' With no arguments in `...`, the numeric fit preserves the input doubles
#' and conditions their differences before solving for variance ratios.
#' Eligible balanced designs use a closed expected-mean-square solution.
#' Unbalanced designs and multi-factor variance boundaries use an analytic
#' profiled REML score and Hessian, initialized by `lmer`, with nonnegative
#' variance constraints. A boundary solution re-estimates the remaining
#' components. The resulting lme4 model retains the original response scale,
#' row order and factor labels; `vc` is extracted from its `VarCorr()`.
#'
#' The `numerics` field records the method (`"closed_form"`,
#' `"analytic_reml"` or `"lmer"`) and, for the default path, conditioning,
#' initialization diagnostics, active zero constraints and convergence
#' norms. Its `input_rows` maps the rows actually analysed by the model to
#' the input, including exclusions by `subset` or `na.action`. The returned
#' `data` and all counts in `n` describe those same rows. Initialization warnings are retained
#' in `numerics$start$warnings` after successful analytic completion, and
#' emitted if completion fails. Final-model convergence checks remain
#' active. Explicit lme4 arguments retain lme4 warnings and errors.
#' Initialization failures on the default path identify the fitting stage
#' and retain the underlying engine's message.
#' Numerical warnings or errors during original-scale model construction
#' produce a named representability error.
#' Final `checkConv` warnings can precede that error when the model is not
#' representable at working precision.
#'
#' Default numeric models store ordinary `nloptwrap` refit control with no
#' extra optimizer options. [msa_boot()] and [lme4::refit()] therefore use
#' normal lme4 optimization; they do not repeat the initial analytic
#' completion. The actual initial method is also recorded in the model's
#' `optinfo$completion`.
#' Both numeric paths store the fitting data and evaluated arguments in the
#' model call so it remains usable outside the original caller's scope.
#' Printing or deparsing that embedded lme4 call can therefore be lengthy;
#' printing the `msa_fit` object gives the compact study summary.
#'
#' Constant numeric responses, non-finite values, non-identifiable
#' components and a degenerate residual variance produce named errors.
#' There is no absolute variance cutoff for small representable variation
#' or tied scores. A positive residual variance does not guarantee a fit:
#' with high repeatability, initialization, analytic completion or construction
#' of the original-scale model can fail at working precision. Final convergence
#' checks use the standard-deviation-ratio scale: a numerically singular Hessian
#' warning can occur even for an identifiable balanced model with a closed-form
#' solution. Numeric `NaN` and the string `"NaN"` are
#' treated as missing responses, without a parsing warning. Missing numeric
#' grouping values are rejected on both fitting paths. The default path
#' rejects variances whose original-scale representation or model arithmetic
#' loses working precision; conditioning cannot recover digits lost in the inputs.
#'
#' Ordinal and binary fits discard missing responses, and labels outside
#' `levels`, with a warning giving the count. All returned data and study
#' counts describe the retained observations. Missing grouping values are
#' rejected. No remaining response, or a constant response category, produces
#' a named error. Binary numeric values (including numeric strings without
#' `levels`) must be finite and exactly zero or one; they are never rounded.
#' Row selection, including missing weights or offsets handled by `na.action`,
#' precedes the choice of random and two-level fixed effects. Ordinal offsets
#' are retained in `data$.msa_offset` and included in the model formula.
#' Counts in `n` describe data rows; with ordinal frequency weights,
#' `stats::nobs(model)` follows `clmm` and reports the sum of those weights.
#' Non-identifiable two-level fixed effects and ordinal random-effect terms
#' with fewer than three observed levels produce named errors. Before either
#' latent engine is called, random-effect variances must be separately
#' identifiable after accounting for the fixed effects. Confounded grouping
#' factors, including interactions, produce an error naming the affected terms.
#' This check includes the fixed latent residual variance: a random term with
#' one observation per level, or a confounded linear combination of terms,
#' cannot be separated from that residual. If all retained weights are
#' integers, they count as multiplicities, including binomial prior weights
#' for zero/one responses. Otherwise each positive-weight row counts once
#' in this check, including the fixed-effect rank check. Zero-weight rows
#' contribute no information. The original weights are passed to the engine
#' unchanged. Weights must be finite, non-negative numeric values with a
#' finite positive sum. Sparse covariance cross-products avoid dense
#' level-by-level projection blocks when checking large designs.
#' Ordinal singularity describes random effects only, not the derived components.
#' Ordinal and binary estimates are invariant to row order and factor labels
#' only up to the optimization tolerance of the underlying engines.
#'
#' Without `control` in `...`, ordinal fits use
#' `ordinal::clmm.control(iter.max = 2000, eval.max = 4000)`.
#' An explicit `control` passed in `...` replaces both limits, including
#' when it is an empty or partial list. Optimizer options given directly in
#' `...`, such as `iter.max`, take precedence over the corresponding default
#' limit, as in [ordinal::clmm()].
#'
#' `converged` records the final engine diagnosis, independently of
#' `singular`. For `clmm`, success means code zero for `nlminb`, or code one
#' or two for `ucminf`; the matrix fitting path uses `nlminb` even if
#' `ucminf` was requested. For lme4 models, success requires optimizer code
#' zero and no convergence message other than the singular-boundary note.
#' Missing or unreadable codes do not confirm convergence. On both numeric
#' paths the final model decides: initialization diagnostics do not, and a
#' final Hessian or gradient diagnostic means `converged = FALSE` even after
#' analytic completion. Numeric warning behavior remains that of lme4 and
#' its final convergence check. Ordinal and binary non-convergence is warned,
#' including a diagnosis stored by the engine without an emitted warning.
#' A range-method warning alone does not indicate non-convergence.
#'
#' @section Known limitations:
#' Zero-weight rows still contribute levels when selecting random versus
#' two-level fixed effects. An ordinal fit can therefore reject a random
#' factor with fewer than three levels among its positive-weight rows.
#' Use `subset` to exclude those rows when that is the intended design.
#' Numeric fits with explicit arguments in `...` use lme4's diagnostics;
#' the default numeric path's identifiability check does not apply to them.
#'
#' @return An object of class `msa_fit`: a list with the fitted `model`, the
#'   variance-component table `vc` (source, variance), the model `formula`,
#'   the analysed `data`, counts `n`, the outcome `type`, and a `singular`
#'   flag (a variance estimated at zero, common with few prompt or model
#'   levels; the point estimate is still valid but its uncertainty is large,
#'   see [msa_boot()] and [msa_plan()]), plus numeric fitting diagnostics
#'   `numerics` (`NULL` for other outcome types), logical `converged`, and
#'   `derived` (sources estimated from two fixed levels, also in
#'   `attr(vc, "derived")`).
#' @seealso [msa_grr()] to turn the variance components into gauge R&R
#'   statistics.
#' @examples
#' fit <- msa_fit(ic50_demo, type = "numeric")
#' fit
#' \donttest{
#' fit_ord <- msa_fit(acmg_demo, type = "ordinal",
#'                    levels = c("B", "LB", "VUS", "LP", "P"))
#' fit_ord$vc
#' }
#' @export
msa_fit <- function(runs, type = c("numeric", "ordinal", "binary"), levels = NULL,
                    interactions = NULL, link = c("probit", "logit"), ...) {
  type <- match.arg(type)
  link <- match.arg(link)
  d <- as.data.frame(runs)
  if (type == "ordinal" && is.null(levels) && is.ordered(d$value)) {
    levels <- levels(d$value)
  }
  if (type != "numeric" && !is.null(levels)) {
    levels <- as.character(levels)
    invalid <- anyNA(levels) || anyDuplicated(levels) || any(!nzchar(levels))
    if (type == "ordinal" && (length(levels) < 2L || invalid)) {
      stop("Ordinal `levels` must contain at least two distinct, non-missing, non-empty labels.", call. = FALSE)
    }
    if (type == "binary" && (length(levels) != 2L || invalid)) {
      stop("Binary `levels` must contain two distinct, non-missing labels; labels must not be empty.", call. = FALSE)
    }
  }
  stop_if_missing_cols(d, c("item_id", "prompt_id", "model_id", "rep", "value"), "runs")
  if (!"block" %in% names(d)) d$block <- 1L
  if (type != "numeric") {
    if (anyNA(d[c("item_id", "prompt_id", "model_id", "block")])) {
      stop("Ordinal and binary grouping factors must not contain missing values.", call. = FALSE)
    }
    missing <- is.na(d$value)
    if (any(missing)) warning(sum(missing), " missing response(s) were dropped.", call. = FALSE)
  }
  input_rows <- which(!is.na(d$value))
  d <- d[input_rows, , drop = FALSE]
  if (!nrow(d)) stop("No valid (non-missing) values to analyse.", call. = FALSE)
  dat <- data.frame(item = factor(d$item_id), prompt = factor(d$prompt_id),
                    model = factor(d$model_id), block = factor(d$block))

  if (type == "numeric") {
    y <- if (is.numeric(d$value)) as.numeric(d$value) else suppressWarnings(as.numeric(as.character(d$value)))
    unreadable <- is.na(y) & !is.nan(y)
    if (any(unreadable)) warning(sum(unreadable), " value(s) could not be interpreted as numbers and were dropped.")
    dat$y <- y
  } else if (type == "ordinal") {
    if (is.null(levels)) {
      stop("`levels` (labels in scale order) are required for ordinal outcomes.", call. = FALSE)
    }
    y <- factor(as.character(d$value), levels = levels, ordered = TRUE)
    if (anyNA(y)) warning(sum(is.na(y)), " value(s) are not among `levels` and were dropped.")
    dat$y <- y
  } else {
    v <- d$value
    if (!is.null(levels)) {
      vv <- as.character(v)
      y <- ifelse(vv %in% levels, as.integer(vv == levels[2]), NA_integer_)
      if (anyNA(y)) warning(sum(is.na(y)), " value(s) are not among `levels` and were dropped.", call. = FALSE)
    } else if (is.logical(v)) y <- as.integer(v)
    else if (is.numeric(v)) y <- v
    else {
      y <- suppressWarnings(as.numeric(as.character(v)))
      if (anyNA(y)) stop("Binary values must be 0/1, logical, or labels with `levels` given.", call. = FALSE)
    }
    if (!all(y[!is.na(y)] %in% c(0, 1))) stop("Binary values must be 0 or 1.", call. = FALSE)
    dat$y <- as.integer(y)
  }
  input_rows <- input_rows[!is.na(dat$y)]
  dat <- dat[!is.na(dat$y), , drop = FALSE]
  dat <- droplevels(dat)
  if (type == "numeric") {
    if (!nrow(dat)) stop("No valid numeric values to analyse.", call. = FALSE)
    if (anyNA(dat)) stop("Numeric grouping factors must not contain missing values.", call. = FALSE)
    if (any(!is.finite(dat$y))) stop("Numeric response must contain only finite values.", call. = FALSE)
    if (all(dat$y == dat$y[1])) stop("Numeric response has zero variation.", call. = FALSE)
  } else {
    if (!nrow(dat)) stop("No valid response categories to analyse.", call. = FALSE)
  }

  # Evaluate row expressions in the cleaned data mask and other arguments in
  # their promise environments. Embedded values keep later refits in scope.
  caller <- parent.frame()
  dots <- as.list(substitute(list(...)))[-1L]
  args <- dots
  for (i in seq_along(dots)) {
    if (isTRUE(names(dots)[i] %in% c("subset", "weights", "offset"))) {
      args[i] <- list(eval(dots[[i]], envir = dat, enclos = caller))
    } else args[i] <- list(...elt(i))
  }
  if (type != "numeric") {
    row_args <- intersect(names(args), c("subset", "weights", "offset", "na.action"))
    if (length(row_args)) {
      # Let model.frame apply indexing, duplicate indices and na.action once,
      # before choosing effects from the levels actually analysed.
      frame <- do.call(stats::model.frame,
        c(list(formula = y ~ item + prompt + model + block, data = dat,
               drop.unused.levels = TRUE), args[row_args]))
      dat <- frame[c("item", "prompt", "model", "block", "y")]
      args$subset <- NULL
      for (name in intersect(row_args, c("weights", "offset"))) {
        args[name] <- list(frame[[paste0("(", name, ")")]])
      }
    }
    if (!nrow(dat)) stop("No valid response categories to analyse.", call. = FALSE)
    if (anyNA(dat)) stop("Ordinal and binary fitting data contain missing values after row selection.", call. = FALSE)
    weights <- args[["weights"]] %||% rep(1, nrow(dat))
    if (!is.numeric(weights) || any(!is.finite(weights)) || any(weights < 0) ||
        !is.finite(sum(weights)) || sum(weights) <= 0) {
      stop("Ordinal and binary weights must be finite, non-negative numeric values with a finite positive sum.", call. = FALSE)
    }
    # Only integer frequencies add replicated observations. Other weights
    # define observed support for every precheck (ADR-034); args is unchanged.
    if (any(weights != trunc(weights))) weights <- as.numeric(weights > 0)
    if (length(unique(dat$y[weights > 0])) < 2L) stop("Response is constant: at least two observed categories are needed.", call. = FALSE)
  }

  if (is.null(interactions)) interactions <- type == "numeric"
  nlev <- function(f) nlevels(f)
  terms <- character()
  random_groups <- character()
  fixed_two <- character()
  for (m in c("item", "prompt", "model", "block")) {
    if (nlev(dat[[m]]) > 2 || (nlev(dat[[m]]) == 2 && type != "ordinal")) {
      terms <- c(terms, sprintf("(1 | %s)", m))
      random_groups <- c(random_groups, m)
    } else if (nlev(dat[[m]]) == 2) {
      # ordinal::clmm needs > 2 levels per grouping factor; a two-level factor
      # enters as a fixed effect and its component is derived by the range method
      fixed_two <- c(fixed_two, m)
    }
  }
  if (interactions) {
    for (p in list(c("item", "prompt"), c("item", "model"), c("prompt", "model"))) {
      if (nlev(dat[[p[1]]]) > 1 && nlev(dat[[p[2]]]) > 1) {
        terms <- c(terms, sprintf("(1 | %s:%s)", p[1], p[2]))
        random_groups <- c(random_groups, paste(p, collapse = ":"))
      }
    }
  }
  if (!"(1 | item)" %in% terms) {
    stop(if (type == "ordinal") "At least three items are needed for ordinal outcomes." else
      "At least two items are needed.", call. = FALSE)
  }
  if (type == "ordinal") {
    for (group in random_groups) {
      columns <- strsplit(group, ":", fixed = TRUE)[[1L]]
      if (nlevels(interaction(dat[weights > 0, columns, drop = FALSE], drop = TRUE)) <= 2L) {
        stop("Ordinal random-effect term ", group, " requires at least three observed levels.", call. = FALSE)
      }
    }
    if (length(fixed_two)) {
      design <- stats::model.matrix(stats::reformulate(fixed_two), data = dat,
                                     contrasts.arg = args[["contrasts"]])
      if (qr(design * sqrt(weights))$rank < ncol(design)) {
        stop("Ordinal two-level factors ", paste(fixed_two, collapse = ", "),
             " are not identifiable: the fixed-effect design is rank deficient.", call. = FALSE)
      }
    }
  }
  if (type != "numeric") {
    if (!length(fixed_two)) design <- matrix(1, nrow(dat), 1L)
    information <- msa_latent_information(dat, random_groups, design, weights = weights, residual = TRUE)
    ev <- eigen(information, symmetric = TRUE, only.values = TRUE)$values
    null <- ev <= nrow(information) * .Machine$double.eps * max(ev)
    if (any(null)) {
      # The union over the null space names every involved component, even
      # when more than one independent covariance relation is present. Keep
      # the eigenvalue-only rank decision; vectors are only for diagnostics.
      decomposition <- eigen(information, symmetric = TRUE)
      affected <- rowSums(decomposition$vectors[, null, drop = FALSE]^2) > nrow(information) * .Machine$double.eps
      reason <- if (affected[nrow(information)]) " cannot be separated from the fixed latent residual variance" else ""
      stop("Latent variance components are not identifiable: random-effect terms ",
           paste(random_groups[affected[seq_along(random_groups)]], collapse = ", "), reason,
           " after accounting for fixed effects.", call. = FALSE)
    }
  }
  rhs <- c("1", fixed_two)
  if (type == "ordinal") {
    # clmm accepts formula offsets. Put them before random terms so its full
    # and fixed model frames address the offset at the same column position.
    if (!is.null(args[["offset"]])) {
      dat$.msa_offset <- args[["offset"]]
      rhs <- c(rhs, "offset(.msa_offset)")
    }
    args$offset <- NULL
  }
  form <- stats::as.formula(paste("y ~", paste(c(rhs, terms), collapse = " + ")))

  numerics <- NULL
  engine_warnings <- character()
  if (type == "numeric" && ...length() == 0L) {
    fitted <- msa_numeric_fit(form, dat)
    model <- fitted$model
    numerics <- fitted$numerics
  } else if (type == "numeric") {
    model <- do.call(lme4::lmer, c(list(formula = form, data = dat, REML = TRUE), args))
    model@call[[1L]] <- quote(lme4::lmer)
    # dat has generated integer row names. Repeated subset indices acquire
    # make.unique() suffixes in model.frame(), while keeping the same input row.
    analysed <- match(sub("\\..*$", "", rownames(stats::model.frame(model))), rownames(dat))
    input_rows <- input_rows[analysed]
    dat <- droplevels(dat[analysed, , drop = FALSE])
    numerics <- list(method = "lmer")
  } else {
    if (type == "ordinal" && !"control" %in% names(args)) {
      args$control <- ordinal::clmm.control(iter.max = 2000, eval.max = 4000)
    }
    model <- withCallingHandlers(switch(type,
      ordinal = do.call(ordinal::clmm, c(list(formula = form, data = dat, link = link), args)),
      binary = do.call(lme4::glmer, c(list(formula = form, data = dat, family = stats::binomial(link = link)), args))),
      warning = function(w) engine_warnings <<- c(engine_warnings, conditionMessage(w)))
    if (type == "ordinal") model$call[[1L]] <- quote(ordinal::clmm) else model@call[[1L]] <- quote(lme4::glmer)
  }
  if (type == "numeric") numerics$input_rows <- input_rows
  converged <- if (type == "ordinal") msa_clmm_converged(model) else msa_mer_converged(model@optinfo$conv)
  if (!converged && type == "ordinal") {
    warning("Ordinal model did not converge: ", model$optRes$message %||% "missing optimizer success code",
            call. = FALSE)
  } else if (!converged && type == "binary") {
    recorded <- model@optinfo$conv$lme4$messages
    for (message in setdiff(recorded, engine_warnings)) warning(message, call. = FALSE)
    if (!length(recorded)) {
      warning("Binary model did not converge: optimizer code ",
              paste(model@optinfo$conv$opt %||% "missing", collapse = ", "), call. = FALSE)
    }
  }

  vc <- vc_from_model(model, type, link)
  singular <- if (inherits(model, "merMod")) lme4::isSingular(model) else any(vc$variance[vc$source != "Residual"] < 1e-6)
  if (length(fixed_two)) {
    derived <- vapply(fixed_two, function(m) {
      # Evaluate the contrast between levels, including non-treatment coding.
      pair <- dat[rep(1L, 2L), , drop = FALSE]
      pair[[m]] <- factor(levels(dat[[m]]), levels = levels(dat[[m]]))
      design <- stats::model.matrix(stats::delete.response(model$terms), pair,
                                    contrasts.arg = model$contrasts)
      difference <- design[2L, names(model$beta)] - design[1L, names(model$beta)]
      beta <- sum(difference * model$beta)
      beta^2 / 2    # range method: two levels with effects 0 and beta
    }, numeric(1))
    vc <- rbind(vc[vc$source != "Residual", , drop = FALSE],
                data.frame(source = fixed_two, variance = unname(derived), stringsAsFactors = FALSE),
                vc[vc$source == "Residual", , drop = FALSE])
    rownames(vc) <- NULL
    attr(vc, "derived") <- fixed_two
    warning("Two-level component(s) ", paste(fixed_two, collapse = ", "),
            " use the range method (beta-hat^2/2), with positive bias: ",
            "E[beta-hat^2/2] = sigma^2 + Var(beta-hat)/2; see ?msa_fit.", call. = FALSE)
  }
  cell <- stats::aggregate(y ~ item + prompt + model + block, data = dat, FUN = length)
  n <- list(items = nlev(dat$item), prompts = nlev(dat$prompt), models = nlev(dat$model),
            blocks = nlev(dat$block), observations = nrow(dat),
            reps_per_cell = range(cell$y))

  structure(list(model = model, type = type, link = link, formula = form, vc = vc,
                 data = dat, n = n, singular = singular, levels = levels,
                 interactions = interactions, derived = fixed_two, numerics = numerics,
                 converged = converged),
            class = "msa_fit")
}

# Gram matrix of projected covariance components (ADR-029, ADR-032, ADR-034).
# Weighted indicators represent frequency-expanded observations without
# allocating them. With Q spanning sqrt(W) X, G[i,j] = ||Z_i' P Z_j||_F^2.
# The optional residual adds trace(P Z_j Z_j') and sum(weights) - rank(X).
# msa_fit resolves noninteger weights to positive-row indicators beforehand.
# Work in grouping-level space; never form observation covariance matrices.
msa_latent_information <- function(dat, groups, design,
                                   weights = rep(1, nrow(dat)), residual = FALSE) {
  positive <- weights > 0
  dat <- dat[positive, , drop = FALSE]
  weights <- weights[positive]
  design <- design[positive, , drop = FALSE] * sqrt(weights)
  Q <- qr.Q(qr(design))
  Z <- lapply(strsplit(groups, ":", fixed = TRUE), function(columns) {
    group <- interaction(dat[columns], drop = TRUE)
    Matrix::sparseMatrix(i = seq_len(nrow(dat)), j = as.integer(group), x = sqrt(weights),
                         dims = c(nrow(dat), nlevels(group)))
  })
  fixed <- lapply(Z, function(z) as.matrix(Matrix::crossprod(Q, z)))
  fixed_gram <- lapply(fixed, tcrossprod)
  k <- length(Z)
  gram <- matrix(0, k + residual, k + residual)
  for (j in seq_len(k)) {
    for (i in seq_len(j)) {
      # Expand ||N - B_i' B_j||_F^2 into sparse and fixed-space contractions.
      # Squaring a dense projected block accumulates rounding error over
      # every pair of levels, enough to hide exact residual relations.
      counts <- Matrix::crossprod(Z[[i]], Z[[j]])
      gram[i, j] <- gram[j, i] <- sum(counts^2) -
        2 * sum((fixed[[i]] %*% counts) * fixed[[j]]) +
        sum(fixed_gram[[i]] * fixed_gram[[j]])
    }
  }
  # An indicator matrix has full column rank. It can lie wholly in the fixed
  # space only when it has at most as many columns. Resolve that small rank
  # test explicitly so roundoff cannot turn a zero one-component Gram matrix
  # into a positive scalar with an apparent condition number of one.
  spanned <- vapply(Z, function(z) {
    ncol(z) <= ncol(design) && qr(cbind(design, as.matrix(z)))$rank == ncol(design)
  }, logical(1))
  if (residual) {
    gram[k + 1L, seq_len(k)] <- gram[seq_len(k), k + 1L] <-
      sum(weights) - vapply(fixed, function(x) sum(x^2), numeric(1))
    gram[k + 1L, k + 1L] <- sum(weights) - ncol(design)
    spanned <- c(spanned, FALSE)
  }
  gram[spanned, ] <- 0
  gram[, spanned] <- 0
  gram
}

# Engine status is categorical, not a new gradient or Hessian tolerance.
msa_mer_converged <- function(conv) {
  code <- conv$opt
  if (!(is.numeric(code) || is.character(code)) || length(code) != 1L) return(FALSE)
  code <- suppressWarnings(as.numeric(code))
  boundary <- "boundary (singular) fit: see help('isSingular')"
  length(code) == 1L && is.finite(code) && code == 0 &&
    all(conv$lme4$messages %in% boundary)
}

msa_clmm_converged <- function(model) {
  # ordinal only uses the single simple random-effect optimizer outside
  # the matrix path. Multiple terms and useMatrix force nlminb.
  simple <- length(model$ST) == 1L && isTRUE(nrow(model$ST[[1L]]) == 1L)
  method <- if (simple && !isTRUE(model$control$useMatrix)) model$control$method else "nlminb"
  success <- if (identical(method, "nlminb")) 0 else if (identical(method, "ucminf")) c(1, 2) else numeric()
  code <- model$optRes$convergence
  if (!(is.numeric(code) || is.character(code)) || length(code) != 1L) return(FALSE)
  code <- suppressWarnings(as.numeric(code))
  length(code) == 1L && is.finite(code) && code %in% success
}

# Condition differences before taking sums of squares. No absolute cutoff on
# response variation is used: tied scores and very small measurements work.
msa_numeric_condition <- function(y) {
  binary <- 1
  delta <- y - y[1]
  if (any(!is.finite(delta))) {
    binary <- 2^min(floor(log2(max(abs(y)))), .Machine$double.max.exp - 1)
    delta <- y / binary - y[1] / binary
  }
  scale <- max(abs(delta))
  if (!is.finite(scale) || scale == 0) stop("Numeric response cannot be scaled.", call. = FALSE)
  z <- delta / scale
  center <- mean(z)
  list(y = z - center, origin = y[1], center = center, scale = scale, binary_scale = binary)
}

# Orthogonal marginal effects, followed by the EMS linear system. The order
# and labels of the original factors are immaterial to this calculation.
msa_numeric_balanced <- function(dat, terms) {
  factors <- unique(unlist(terms))
  sizes <- vapply(dat[factors], nlevels, integer(1))
  if (prod(sizes) > nrow(dat)) return(NULL)
  counts <- table(interaction(dat[factors], drop = TRUE))
  if (length(counts) != prod(sizes) || any(counts != counts[1])) {
    if (length(terms) == 1L) {
      residual <- dat$y - stats::ave(dat$y, dat[[factors]], FUN = mean)
      msa_numeric_check_residual(sum(residual^2), sum((dat$y - mean(dat$y))^2))
    }
    return(NULL)
  }
  dfs <- vapply(terms, function(t) prod(sizes[t] - 1), numeric(1))
  residual_df <- nrow(dat) - 1 - sum(dfs)
  if (residual_df <= 0) stop("Numeric model has no residual degrees of freedom.", call. = FALSE)
  effects <- vector("list", length(terms))
  ms <- numeric(length(terms))
  grand <- mean(dat$y)
  for (j in order(lengths(terms))) {
    group <- interaction(dat[terms[[j]]], drop = TRUE)
    effect <- stats::ave(dat$y, group, FUN = mean) - grand
    below <- which(vapply(terms, function(t) length(t) < length(terms[[j]]) && all(t %in% terms[[j]]), logical(1)))
    for (k in below) effect <- effect - effects[[k]]
    effects[[j]] <- effect
    ms[j] <- sum(effect^2) / dfs[j]
  }
  residual <- dat$y - grand - Reduce(`+`, effects)
  if (length(terms) == 1L) {
    residual <- dat$y - stats::ave(dat$y, dat[[factors]], FUN = mean)
  }
  residual_v <- sum(residual^2) / residual_df
  msa_numeric_check_residual(sum(residual^2), sum((dat$y - grand)^2))
  ems <- vapply(terms, function(t) {
    includes <- vapply(terms, function(s) all(s %in% t), logical(1))
    includes * nrow(dat) / prod(sizes[t])
  }, numeric(length(terms)))
  variance <- as.numeric(solve(ems, ms - residual_v))
  if (length(variance) == 1L && variance < 0) {
    variance <- 0
  }
  if (any(variance < 0)) return(NULL)
  variance / residual_v
}

# A relative backward-error check on squared residuals; it does not impose
# an absolute lower bound on response variation (ADR-020, rework addendum).
msa_numeric_check_residual <- function(square, total) {
  if (!is.finite(square) || square <= (64 * .Machine$double.eps)^2 * total) {
    stop("Degenerate numeric model: residual variance is zero at working precision.", call. = FALSE)
  }
}

# Profiled REML on the space orthogonal to the intercept. Centering Z'Z is
# equivalent to eliminating X from H, but avoids subtracting nearly equal
# numbers in X'H^-1 X. All square matrices live in the random-effect space.
msa_numeric_reml <- function(Zt, groups, y) {
  n <- length(y)
  nu <- n - 1
  y <- y - mean(y)
  counts <- as.numeric(Matrix::rowSums(Zt))
  means <- counts / n
  cross <- Matrix::forceSymmetric(Matrix::tcrossprod(Zt) - Matrix::tcrossprod(counts) / n)
  cross <- Matrix::Matrix(cross, sparse = TRUE)
  zy <- as.numeric(Zt %*% y)
  blocks <- split(seq_along(groups), groups)
  function(lambda) {
    w <- sqrt(lambda[groups])
    D <- Matrix::Diagonal(x = w)
    C <- D %*% cross
    B <- Matrix::forceSymmetric(Matrix::Diagonal(length(w)) + C %*% D)
    # B is positive definite for finite nonnegative ratios. Failure here
    # means the residual scale cannot be resolved, often as ratios diverge.
    decomposition <- tryCatch(withCallingHandlers({
      factor <- Matrix::Cholesky(B, LDL = FALSE, perm = TRUE)
      list(factor = factor, solved = Matrix::solve(factor, cbind(C, w * zy), system = "A"))
    }, warning = function(w) stop(conditionMessage(w), call. = FALSE)), error = function(e) {
      stop("Numeric model residual variance cannot be resolved at working precision.", call. = FALSE)
    })
    factor <- decomposition$factor
    solved <- decomposition$solved
    A <- as.matrix(cross - Matrix::crossprod(C, solved[, seq_along(w), drop = FALSE]))
    A <- (A + t(A)) / 2
    u <- as.numeric(solved[, length(w) + 1L])
    residual <- y - as.numeric(Matrix::crossprod(Zt, w * u)) + sum(means * w * u)
    Q <- sum(residual^2) + sum(u^2)
    msa_numeric_check_residual(Q, sum(y^2))
    r <- as.numeric(Zt %*% residual) - counts * mean(residual)
    trace <- vapply(blocks, function(i) sum(diag(A)[i]), numeric(1))
    square <- vapply(blocks, function(i) sum(r[i]^2), numeric(1))
    k <- length(blocks)
    gram <- curvature <- matrix(0, k, k)
    for (j in seq_len(k)) {
      for (i in seq_len(j)) {
        block <- A[blocks[[i]], blocks[[j]], drop = FALSE]
        gram[i, j] <- gram[j, i] <- sum(block^2)
        product <- sum(r[blocks[[i]]] * as.numeric(block %*% r[blocks[[j]]]))
        curvature[i, j] <- curvature[j, i] <- -gram[i, j] +
          nu * (2 * product / Q - square[i] * square[j] / Q^2)
      }
    }
    list(value = as.numeric(Matrix::determinant(factor, logarithm = TRUE, sqrt = FALSE)$modulus) +
           log(n) + nu * log(Q / nu),
         gradient = unname(trace - nu * square / Q), Hessian = curvature,
         information = gram - tcrossprod(trace) / nu, residual = Q / nu, df = nu)
  }
}

# An active-set Newton step on variance ratios, not standard deviations.
# Thus a zero theta cannot hide a negative one-sided variance score.
msa_numeric_step <- function(state, lambda) {
  scale <- pmax(1, lambda)
  projected <- ifelse(lambda == 0, pmin(0, state$gradient), state$gradient)
  free <- which(lambda > 0 | state$gradient < 0)
  step <- numeric(length(lambda))
  positive <- TRUE
  repeat {
    if (!length(free)) break
    H <- state$Hessian[free, free, drop = FALSE] * outer(scale[free], scale[free])
    e <- eigen(H, symmetric = TRUE)
    floor <- sqrt(.Machine$double.eps) * max(1, max(abs(e$values)))
    positive <- all(e$values > 0)
    direction <- -as.numeric(e$vectors %*% (crossprod(e$vectors, state$gradient[free] * scale[free]) /
                                           pmax(e$values, floor)))
    blocked <- lambda[free] == 0 & direction < 0
    if (!any(blocked)) {
      step[free] <- direction * scale[free]
      break
    }
    free <- free[!blocked]
  }
  list(step = step, score = max(abs(projected * scale)) / state$df,
       correction = max(abs(step / scale)), positive = positive)
}

msa_numeric_optimize <- function(evaluate, lambda, max_iterations = 100L) {
  target <- sqrt(.Machine$double.eps)
  state <- evaluate(lambda)
  information <- state$information * outer(pmax(1, lambda), pmax(1, lambda))
  ev <- eigen(information, symmetric = TRUE, only.values = TRUE)$values
  if (min(ev) <= length(lambda) * .Machine$double.eps * max(ev)) {
    stop("Numeric variance components are not identifiable.", call. = FALSE)
  }
  evaluations <- 1L
  halves <- entered <- released <- 0L
  for (iteration in seq_len(max_iterations)) {
    direction <- msa_numeric_step(state, lambda)
    if (direction$positive && direction$score <= target && direction$correction <= target) {
      return(list(lambda = lambda, state = state, iterations = iteration - 1L,
                  evaluations = evaluations, scaled_score = direction$score,
                  scaled_step = direction$correction, step_halvings = halves,
                  entered = entered, released = released))
    }
    step <- direction$step
    descending <- which(step < 0)
    alpha <- if (length(descending)) min(1, min(-lambda[descending] / step[descending])) else 1
    slope <- sum(state$gradient * step)
    accepted <- FALSE
    for (backtrack in seq_len(50L)) {
      candidate <- pmax(0, lambda + alpha * step)
      if (length(descending)) {
        hit <- descending[alpha == -lambda[descending] / step[descending]]
        candidate[hit] <- 0
      }
      next_state <- evaluate(candidate)
      evaluations <- evaluations + 1L
      roundoff <- 64 * .Machine$double.eps * max(1, abs(state$value))
      sufficient <- next_state$value <= state$value + alpha * slope / 10000
      improving <- next_state$value <= state$value + roundoff &&
        msa_numeric_step(next_state, candidate)$score < direction$score
      if (slope < 0 && (sufficient || improving)) {
        accepted <- TRUE
        break
      }
      alpha <- alpha / 2
      halves <- halves + 1L
    }
    if (!accepted) break
    entered <- entered + sum(lambda > 0 & candidate == 0)
    released <- released + sum(lambda == 0 & candidate > 0)
    lambda <- candidate
    state <- next_state
  }
  stop(sprintf("Analytic REML did not converge (iterations %d, scaled score %.6g, scaled step %.6g).",
               iteration, direction$score, direction$correction), call. = FALSE)
}

msa_numeric_fit <- function(form, dat) {
  conditioning <- msa_numeric_condition(dat$y)
  scaled <- dat
  scaled$y <- conditioning$y
  control <- lme4::lmerControl(optimizer = "nloptwrap")
  lf <- lme4::lFormula(form, data = scaled, REML = TRUE, control = control)
  names <- names(lf$reTrms$cnms)
  terms <- strsplit(names, ":", fixed = TRUE)
  groups <- rep(seq_along(names), diff(lf$reTrms$Gp))
  evaluate <- msa_numeric_reml(lf$reTrms$Zt, groups, scaled$y)
  lambda <- msa_numeric_balanced(scaled, terms)
  start <- list(warnings = character(), messages = character())
  completed <- FALSE
  on.exit(if (!completed) for (w in start$warnings) warning(w, call. = FALSE), add = TRUE)
  finish <- {
    if (is.null(lambda)) {
      # Every random-intercept block spans the intercept. Rank-revealing QR
      # handles dependencies and missing cells without an N-by-N covariance.
      projection <- stats::lm.fit(as.matrix(Matrix::t(lf$reTrms$Zt)), scaled$y)
      # A saturated span fits every response and cannot diagnose residual variance.
      if (projection$rank < nrow(scaled)) {
        msa_numeric_check_residual(sum(projection$residuals^2), sum(scaled$y^2))
      }
      initial <- withCallingHandlers(tryCatch(
        lme4::lmer(form, data = scaled, REML = TRUE, control = control),
        error = function(e) {
          stop("Numeric model initialization failed: ", conditionMessage(e), call. = FALSE)
        }),
        warning = function(w) {
          start$warnings <<- c(start$warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        }, message = function(m) {
          start$messages <<- c(start$messages, conditionMessage(m))
          invokeRestart("muffleMessage")
        })
      start$source <- "lme4::lmer on the conditioned response"
      start$optimizer <- initial@optinfo$optimizer
      start$convergence <- initial@optinfo$conv
      start$theta <- lme4::getME(initial, "theta")
      solution <- msa_numeric_optimize(evaluate, start$theta^2)
      method <- "analytic_reml"
    } else {
      state <- evaluate(lambda)
      step <- msa_numeric_step(state, lambda)
      solution <- list(lambda = lambda, state = state, iterations = 0L, evaluations = 1L,
                       scaled_score = step$score, scaled_step = step$correction,
                       step_halvings = 0L, entered = 0L, released = 0L)
      method <- "closed_form"
    }
    list(solution = solution, method = method)
  }
  solution <- finish$solution
  theta <- sqrt(solution$lambda)
  # Multiply standard deviations before squaring to avoid an unnecessary
  # overflow/underflow in the squared conditioning scale.
  residual_sd <- sqrt(solution$state$residual) * conditioning$scale * conditioning$binary_scale
  expected_sd <- c(theta * residual_sd, residual_sd)
  expected_variances <- expected_sd^2
  precision <- sqrt(.Machine$double.eps)
  spacing <- .Machine$double.xmin * .Machine$double.eps
  positive <- c(theta > 0, TRUE)
  not_representable <- function(condition = NULL) {
    stop("Numeric model variance is not representable on the original scale at working precision.", call. = FALSE)
  }
  if (any(!is.finite(expected_variances)) || any(expected_variances[positive] <= 0) ||
      any(spacing / expected_variances[positive] > precision)) {
    not_representable()
  }
  derivs <- list(gradient = 2 * theta * solution$state$gradient,
                 Hessian = 4 * outer(theta, theta) * solution$state$Hessian +
                   diag(2 * solution$state$gradient, length(theta)))
  # An exact variance-ratio solution can still fail in original-scale model
  # arithmetic. Stop on a warning as well as an error; never use a partial fit.
  value <- tryCatch({
    original <- lme4::lFormula(form, data = dat, REML = TRUE, control = control)
    devfun <- do.call(lme4::mkLmerDevfun, original)
    devfun(theta)
  }, warning = not_representable, error = not_representable)
  opt <- list(par = theta, fval = value, conv = 0L, feval = solution$evaluations,
              message = paste("REML solution:", finish$method))
  attr(opt, "optimizer") <- "nloptwrap"
  attr(opt, "control") <- list()
  attr(opt, "derivs") <- derivs
  # Keep convergence diagnostics separate from construction failures.
  cc <- lme4::checkConv(derivs, theta, ctrl = control$checkConv, lbound = original$reTrms$lower)
  mc <- call("lmer", formula = form, data = dat, REML = TRUE,
             control = quote(lme4::lmerControl(optimizer = "nloptwrap")))
  mc[[1]] <- quote(lme4::lmer)
  variances <- tryCatch({
    model <- lme4::mkMerMod(environment(devfun), opt, original$reTrms, fr = original$fr, mc = mc, lme4conv = cc)
    as.data.frame(lme4::VarCorr(model))$vcov
  }, warning = not_representable, error = not_representable)
  if (!is.finite(value) || any(!is.finite(variances)) ||
      any(abs(variances[positive] / expected_variances[positive] - 1) > precision)) {
    not_representable()
  }
  solution$lambda <- stats::setNames(solution$lambda, names)
  solution$active <- names[theta == 0]
  numerics <- c(list(method = finish$method, conditioning = conditioning[-1L], start = start), solution)
  model@optinfo$completion <- numerics[c("method", "iterations", "scaled_score", "scaled_step", "active")]
  completed <- TRUE
  list(model = model, numerics = numerics)
}

# Variance components as a data.frame(source, variance). Residual is the
# repeatability; for latent-scale models it is fixed by the link.
vc_from_model <- function(model, type, link) {
  if (inherits(model, "merMod")) {
    v <- as.data.frame(lme4::VarCorr(model))
    out <- data.frame(source = v$grp, variance = v$vcov, stringsAsFactors = FALSE)
    if (type == "binary") {
      out <- out[out$source != "Residual", , drop = FALSE]
      out <- rbind(out, data.frame(source = "Residual", variance = latent_residual(link)))
    }
  } else {
    v <- ordinal::VarCorr(model)
    out <- data.frame(source = names(v), variance = vapply(v, function(m) as.numeric(m)[1], numeric(1)),
                      stringsAsFactors = FALSE)
    out <- rbind(out, data.frame(source = "Residual", variance = latent_residual(link)))
  }
  rownames(out) <- NULL
  out
}

latent_residual <- function(link) if (link == "probit") 1 else pi^2 / 3

#' @export
print.msa_fit <- function(x, ...) {
  cat(sprintf("Variance components of an LLM measurement system (%s outcome%s)\n",
              x$type, if (x$type != "numeric") paste0(", ", x$link, " link, latent scale") else ""))
  cat("  formula: ", deparse(x$formula), "\n", sep = "")
  cat(sprintf("  %d items x %d prompts x %d models x %d block(s); %d observations; %d-%d valid replicates per cell\n",
              x$n$items, x$n$prompts, x$n$models, x$n$blocks, x$n$observations,
              x$n$reps_per_cell[1], x$n$reps_per_cell[2]))
  tab <- x$vc
  tab$sd <- sqrt(tab$variance)
  total <- sum(tab$variance)
  tab$pct <- if (total == 0) rep(NA_real_, nrow(tab)) else 100 * tab$variance / total
  tab$variance <- fmt_num(tab$variance); tab$sd <- fmt_num(tab$sd); tab$pct <- fmt_pct(tab$pct)
  print(tab, row.names = FALSE)
  if (length(x$derived)) {
    for (source in x$derived) cat("  ", source, ": range method, see ?msa_fit\n", sep = "")
  }
  if (isTRUE(x$singular)) {
    cat("note: singular fit (at least one variance estimated at zero). With few prompt or model levels this is expected;\n",
        "      report bootstrap intervals (msa_boot) and consider a larger study (msa_plan).\n", sep = "")
  }
  invisible(x)
}

#' @export
summary.msa_fit <- function(object, ...) print(object, ...)
