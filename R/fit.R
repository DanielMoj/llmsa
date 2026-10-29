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
#' difference `beta` by the range method (`beta^2 / 2`), which is how the
#' AIAG X-bar/R procedure treats two appraisers. Ordinal outcomes need at
#' least three items.
#'
#' @param runs An `msa_runs` object (from [msa_run()] or [as_msa_runs()]).
#' @param type Outcome type.
#' @param levels For ordinal outcomes: the labels in scale order. For binary
#'   outcomes given as labels: a length-two vector whose second element is
#'   the event.
#' @param interactions Include the two-way interactions as random effects?
#'   Default `TRUE` for numeric, `FALSE` otherwise.
#' @param link Link for ordinal and binary outcomes.
#' @param ... Passed on to the model-fitting function. For numeric outcomes,
#'   supplying any argument here selects a direct [lme4::lmer()] call on
#'   the original response, including when an argument is explicitly `NULL`.
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
#' norms. Its `input_rows` maps rows retained during missing-value and
#' numeric parsing checks to the input. Initialization warnings are retained
#' in `numerics$start$warnings` after successful analytic completion, and
#' emitted if completion fails. Final-model convergence checks remain
#' active. Explicit lme4 arguments retain lme4 warnings and errors.
#'
#' Default numeric models store ordinary `nloptwrap` refit control with no
#' extra optimizer options. [msa_boot()] and [lme4::refit()] therefore use
#' normal lme4 optimization; they do not repeat the initial analytic
#' completion. The actual initial method is also recorded in the model's
#' `optinfo$completion`.
#'
#' Constant numeric responses, non-finite values, non-identifiable
#' components and a degenerate residual variance produce named errors.
#' Small representable variation and tied scores are supported without
#' an absolute variance cutoff. Conditioning cannot recover precision
#' already lost in the inputs or in original-scale model arithmetic.
#'
#' @return An object of class `msa_fit`: a list with the fitted `model`, the
#'   variance-component table `vc` (source, variance), the model `formula`,
#'   the analysed `data`, counts `n`, the outcome `type`, and a `singular`
#'   flag (a variance estimated at zero, common with few prompt or model
#'   levels; the point estimate is still valid but its uncertainty is large,
#'   see [msa_boot()] and [msa_plan()]), plus numeric fitting diagnostics
#'   `numerics` (`NULL` for other outcome types).
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
  d <- as.data.frame(runs, stringsAsFactors = FALSE)
  stop_if_missing_cols(d, c("item_id", "prompt_id", "model_id", "rep", "value"), "runs")
  if (!"block" %in% names(d)) d$block <- 1L
  input_rows <- which(!is.na(d$value))
  d <- d[input_rows, , drop = FALSE]
  if (!nrow(d)) stop("No valid (non-missing) values to analyse.", call. = FALSE)

  dat <- data.frame(item = factor(d$item_id), prompt = factor(d$prompt_id),
                    model = factor(d$model_id), block = factor(d$block))

  if (type == "numeric") {
    y <- if (is.numeric(d$value)) as.numeric(d$value) else suppressWarnings(as.numeric(as.character(d$value)))
    if (anyNA(y)) warning(sum(is.na(y)), " value(s) could not be interpreted as numbers and were dropped.")
    dat$y <- y
  } else if (type == "ordinal") {
    if (is.null(levels)) {
      if (is.ordered(d$value)) levels <- levels(d$value) else
        stop("`levels` (labels in scale order) are required for ordinal outcomes.", call. = FALSE)
    }
    y <- factor(as.character(d$value), levels = levels, ordered = TRUE)
    if (anyNA(y)) warning(sum(is.na(y)), " value(s) are not among `levels` and were dropped.")
    dat$y <- y
  } else {
    v <- d$value
    if (is.logical(v)) y <- as.integer(v)
    else if (is.numeric(v)) y <- as.integer(v)
    else if (!is.null(levels)) {
      vv <- as.character(v)
      y <- ifelse(vv %in% levels, as.integer(vv == levels[2]), NA_integer_)
    } else {
      y <- suppressWarnings(as.integer(as.character(v)))
      if (anyNA(y)) stop("Binary values must be 0/1, logical, or labels with `levels` given.", call. = FALSE)
    }
    if (!all(y[!is.na(y)] %in% c(0L, 1L))) stop("Binary values must be 0 or 1.", call. = FALSE)
    dat$y <- y
  }
  input_rows <- input_rows[!is.na(dat$y)]
  dat <- dat[!is.na(dat$y), , drop = FALSE]
  dat <- droplevels(dat)
  if (type == "numeric") {
    if (!nrow(dat)) stop("No valid numeric values to analyse.", call. = FALSE)
    if (any(!is.finite(dat$y))) stop("Numeric response must contain only finite values.", call. = FALSE)
    if (all(dat$y == dat$y[1])) stop("Numeric response has zero variation.", call. = FALSE)
  }

  if (is.null(interactions)) interactions <- type == "numeric"
  nlev <- function(f) nlevels(f)
  terms <- character()
  fixed_two <- character()
  for (m in c("item", "prompt", "model", "block")) {
    if (nlev(dat[[m]]) > 2 || (nlev(dat[[m]]) == 2 && type != "ordinal")) {
      terms <- c(terms, sprintf("(1 | %s)", m))
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
      }
    }
  }
  if (!"(1 | item)" %in% terms) {
    stop(if (type == "ordinal") "At least three items are needed for ordinal outcomes." else
      "At least two items are needed.", call. = FALSE)
  }
  rhs <- c("1", fixed_two, terms)
  form <- stats::as.formula(paste("y ~", paste(rhs, collapse = " + ")))

  numerics <- NULL
  if (type == "numeric" && ...length() == 0L) {
    fitted <- msa_numeric_fit(form, dat)
    model <- fitted$model
    numerics <- fitted$numerics
  } else {
    model <- switch(type,
      numeric = lme4::lmer(form, data = dat, REML = TRUE, ...),
      ordinal = ordinal::clmm(form, data = dat, link = link, ...),
      binary  = lme4::glmer(form, data = dat, family = stats::binomial(link = link), ...))
    if (type == "numeric") numerics <- list(method = "lmer")
  }
  if (type == "numeric") numerics$input_rows <- input_rows

  vc <- vc_from_model(model, type, link)
  if (length(fixed_two)) {
    cf <- stats::coef(model)
    derived <- vapply(fixed_two, function(m) {
      beta <- unname(cf[[paste0(m, levels(dat[[m]])[2])]])
      beta^2 / 2    # range method: two levels with effects 0 and beta
    }, numeric(1))
    vc <- rbind(vc[vc$source != "Residual", , drop = FALSE],
                data.frame(source = fixed_two, variance = unname(derived), stringsAsFactors = FALSE),
                vc[vc$source == "Residual", , drop = FALSE])
    rownames(vc) <- NULL
    attr(vc, "derived") <- fixed_two
  }
  singular <- if (inherits(model, "merMod")) lme4::isSingular(model) else any(vc$variance[vc$source != "Residual"] < 1e-6)

  cell <- stats::aggregate(y ~ item + prompt + model + block, data = dat, FUN = length)
  n <- list(items = nlev(dat$item), prompts = nlev(dat$prompt), models = nlev(dat$model),
            blocks = nlev(dat$block), observations = nrow(dat),
            reps_per_cell = range(cell$y))

  structure(list(model = model, type = type, link = link, formula = form, vc = vc,
                 data = dat, n = n, singular = singular, levels = levels,
                 interactions = interactions, derived = fixed_two, numerics = numerics),
            class = "msa_fit")
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
  if (length(counts) != prod(sizes) || any(counts != counts[1])) return(NULL)
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
  if (residual_v == 0) stop("Degenerate numeric model: residual variance is zero.", call. = FALSE)
  ems <- vapply(terms, function(t) {
    includes <- vapply(terms, function(s) all(s %in% t), logical(1))
    includes * nrow(dat) / prod(sizes[t])
  }, numeric(length(terms)))
  variance <- as.numeric(solve(ems, ms - residual_v))
  if (length(variance) == 1L && variance < 0) {
    variance <- 0
    residual_v <- sum((dat$y - grand)^2) / (nrow(dat) - 1)
  }
  if (any(variance < 0)) return(NULL)
  variance / residual_v
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
    factor <- Matrix::Cholesky(B, LDL = FALSE, perm = TRUE)
    solved <- Matrix::solve(factor, cbind(C, w * zy), system = "A")
    A <- as.matrix(cross - Matrix::crossprod(C, solved[, seq_along(w), drop = FALSE]))
    A <- (A + t(A)) / 2
    u <- as.numeric(solved[, length(w) + 1L])
    residual <- y - as.numeric(Matrix::crossprod(Zt, w * u)) + sum(means * w * u)
    Q <- sum(residual^2) + sum(u^2)
    if (!is.finite(Q) || Q <= 0) stop("Degenerate numeric model: no positive residual variance.", call. = FALSE)
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
  if (anyNA(dat)) stop("Numeric grouping factors must not contain missing values.", call. = FALSE)
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
      initial <- withCallingHandlers(lme4::lmer(form, data = scaled, REML = TRUE, control = control),
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
  derivs <- list(gradient = 2 * theta * solution$state$gradient,
                 Hessian = 4 * outer(theta, theta) * solution$state$Hessian +
                   diag(2 * solution$state$gradient, length(theta)))
  original <- lme4::lFormula(form, data = dat, REML = TRUE, control = control)
  devfun <- do.call(lme4::mkLmerDevfun, original)
  value <- devfun(theta)
  opt <- list(par = theta, fval = value, conv = 0L, feval = solution$evaluations,
              message = paste("REML solution:", finish$method))
  attr(opt, "optimizer") <- "nloptwrap"
  attr(opt, "control") <- list()
  attr(opt, "derivs") <- derivs
  cc <- lme4::checkConv(derivs, theta, ctrl = control$checkConv, lbound = original$reTrms$lower)
  mc <- call("lmer", formula = form, data = quote(dat), REML = TRUE,
             control = quote(lme4::lmerControl(optimizer = "nloptwrap")))
  mc[[1]] <- quote(lme4::lmer)
  model <- lme4::mkMerMod(environment(devfun), opt, original$reTrms, fr = original$fr, mc = mc, lme4conv = cc)
  variances <- as.data.frame(lme4::VarCorr(model))$vcov
  if (!is.finite(value) || any(!is.finite(variances)) || stats::sigma(model) <= 0) {
    stop("Numeric model variance is not representable on the original scale.", call. = FALSE)
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
    cat("note: ", paste(x$derived, collapse = ", "), " ha", if (length(x$derived) > 1) "ve" else "s",
        " only two levels and entered as fixed effect(s); the component is derived from the\n",
        "      estimated difference by the range method (beta^2 / 2), as in the AIAG X-bar/R procedure.\n", sep = "")
  }
  if (isTRUE(x$singular)) {
    cat("note: singular fit (at least one variance estimated at zero). With few prompt or model levels this is expected;\n",
        "      report bootstrap intervals (msa_boot) and consider a larger study (msa_plan).\n", sep = "")
  }
  invisible(x)
}

#' @export
summary.msa_fit <- function(object, ...) print(object, ...)
