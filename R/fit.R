#' Estimate the variance components of an LLM measurement system
#'
#' Fits a crossed random-effects model to the parsed values of a study.
#' Items, prompt variants, models and blocks enter as random effects; for
#' numeric outcomes the interactions item:prompt, item:model and
#' prompt:model are included by default. The residual variance is the
#' repeatability (replicate-to-replicate variation under identical
#' conditions).
#'
#' * `type = "numeric"`: linear mixed model fitted by REML with
#'   [lme4::lmer()].
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
#' @param ... Passed on to the model-fitting function.
#'
#' @return An object of class `msa_fit`: a list with the fitted `model`, the
#'   variance-component table `vc` (source, variance), the model `formula`,
#'   the analysed `data`, counts `n`, the outcome `type`, and a `singular`
#'   flag (a variance estimated at zero, common with few prompt or model
#'   levels; the point estimate is still valid but its uncertainty is large,
#'   see [msa_boot()] and [msa_plan()]).
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
  d <- d[!is.na(d$value), , drop = FALSE]
  if (!nrow(d)) stop("No valid (non-missing) values to analyse.", call. = FALSE)

  dat <- data.frame(item = factor(d$item_id), prompt = factor(d$prompt_id),
                    model = factor(d$model_id), block = factor(d$block))

  if (type == "numeric") {
    y <- suppressWarnings(as.numeric(as.character(d$value)))
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
  dat <- dat[!is.na(dat$y), , drop = FALSE]
  dat <- droplevels(dat)

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

  model <- switch(type,
    numeric = lme4::lmer(form, data = dat, REML = TRUE, ...),
    ordinal = ordinal::clmm(form, data = dat, link = link, ...),
    binary  = lme4::glmer(form, data = dat, family = stats::binomial(link = link), ...))

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
                 interactions = interactions, derived = fixed_two),
            class = "msa_fit")
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
  tab$pct <- 100 * tab$variance / sum(tab$variance)
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
