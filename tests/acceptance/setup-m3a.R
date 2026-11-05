# Helpers for the M3a acceptance tests (docs/04-weitere-bausteine.md, K-M3a-1
# to K-M3a-7); a setup file for the reason given in setup-acceptance.R.
#
# Reference values come from reference/anchors/ (ANK-70 Cohen 1968, ANK-72
# Fleiss 1971 with Fleiss, Nee & Landis 1979, ANK-73 Krippendorff 2011, ANK-74
# to ANK-76 AIAG 2010, ANK-06, ANK-TOL) or from the oracles the criteria name
# (irr::kappa2, psych::cohen.kappa, DescTools::CohenKappa, irr::kappam.fleiss,
# irr::kripp.alpha, stats::t.test, stats::lm), called at test time on the same
# data; no package output is frozen. Values of constructed data sets are
# determined by hand in the test files (K-M3a-4) and checked a second time by
# the mini-references below.
# Local data: the AIAG data sheets of the bias, linearity and attribute studies
# under reference/quellen/data/aiag/ (protected, git-ignored, docs/01 §6); a
# missing or altered file fails the test, it never skips it (AGENTS.md). A
# sheet is bound to its anchor by the SHA-256 of a canonical form of its
# content (ACC-2).
# The mini-references are written from the sources (pages in the anchors) and
# Formelsammlung §5 and §6, independently of R/agreement.R.
# Names of new result fields, which the spec does not fix, and every other
# interpretation are listed in orchestrator/handoff/M3a/CRITERIA.json under
# "open" (ACC-n).

acc_m3a <- new.env(parent = emptyenv())   # cache for one test run

# Anchors ------------------------------------------------------------------------

# Nested value of an anchor, e.g. acc_m3a_value("ANK-70", "kappa").
acc_m3a_value <- function(id, ...) {
  path <- c(...)
  v <- acc_anchor(id)$value
  for (k in path) {
    v <- v[[k]]
    if (is.null(v)) {
      stop("acceptance: ", id, " has no value ", paste(path, collapse = "$"), call. = FALSE)
    }
  }
  v
}

# Value of ANK-TOL entry `entry`, key `key`; a missing key stops the test
# instead of turning into an exact comparison (BL-72).
acc_m3a_tol <- function(entry, key) {
  e <- acc_anchor("ANK-TOL")$value[[entry]]
  if (is.null(e)) stop("acceptance: ANK-TOL has no entry ", entry, call. = FALSE)
  v <- e[[key]]
  if (is.null(v)) stop("acceptance: ANK-TOL.", entry, " has no key ", key, call. = FALSE)
  v
}

acc_m3a_arith <- function() as.numeric(acc_m3a_tol("arithmetic", "abs_tol"))
acc_m3a_pkg <- function() as.numeric(acc_m3a_tol("package_compare", "abs_tol"))

# Half a unit of the last printed digit (docs/01 §2 Nr. 6) plus the arithmetic
# allowance for the binary representation of the printed decimals.
acc_m3a_printed_tol <- function(decimals) 0.5 * 10^(-as.numeric(decimals)) + acc_m3a_arith()

acc_m3a_num <- function(x) as.numeric(unlist(x))

# A JSON array of rows as a numeric matrix.
acc_m3a_matrix <- function(rows) do.call(rbind, lapply(rows, acc_m3a_num))

# Data --------------------------------------------------------------------------------

# Seeded block with the RNG of docs/01 §5; the caller's RNG state is restored.
acc_m3a_with_seed <- function(seed, expr) {
  kind <- RNGkind()
  had <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (had) old <- get(".Random.seed", envir = globalenv())
  on.exit({
    RNGkind(kind[1], kind[2], kind[3])
    if (had) assign(".Random.seed", old, envir = globalenv())
    else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) rm(".Random.seed", envir = globalenv())
  }, add = TRUE)
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  set.seed(seed)
  expr
}

# An msa_runs object from vectors in the roles of Formelsammlung §1.
acc_m3a_runs <- function(item, prompt, model, rep, value, block = 1L) {
  as_msa_runs(data.frame(block = block, item_id = as.character(item), prompt_id = as.character(prompt),
                         model_id = as.character(model), rep = as.integer(rep), value = value,
                         stringsAsFactors = FALSE))
}

# Evaluates `expr`, records the texts of the messages and warnings it signals
# (muffled) and returns an error as the value instead of raising it.
acc_m3a_conditions <- function(expr) {
  msgs <- character()
  warns <- character()
  value <- withCallingHandlers(
    tryCatch(expr, error = function(e) e),
    message = function(m) {
      msgs <<- c(msgs, conditionMessage(m))
      invokeRestart("muffleMessage")
    },
    warning = function(w) {
      warns <<- c(warns, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
  list(value = value, messages = msgs, warnings = warns, notes = c(msgs, warns))
}

# Product accessors -----------------------------------------------------------------

# Cohen's kappa of an msa_agreement() result: "all" responses or the "modal"
# response per item against the reference (fields of v0.1.0).
acc_m3a_kappa <- function(ag, which = c("all", "modal")) {
  which <- match.arg(which)
  name <- paste0("kappa_", which, "_vs_reference")
  k <- ag$kappa
  if (is.null(k) || !name %in% names(k)) {
    stop("acceptance: the msa_agreement() result has no kappa element ", name, call. = FALSE)
  }
  unname(k[[name]])
}

# Scopes of the alpha table of v0.1.0.
acc_m3a_scopes <- c(replicates = "replicates (within prompt & model)",
                    prompts = "across prompts (within model)",
                    models = "across models (within prompt)",
                    all = "all conditions")

# One cell of the alpha table of an msa_agreement() result.
acc_m3a_alpha <- function(ag, scope, column = "alpha") {
  a <- ag$alpha
  if (!is.data.frame(a) || !all(c("scope", column) %in% names(a))) {
    stop("acceptance: the alpha table of msa_agreement() lacks the columns scope and ", column, call. = FALSE)
  }
  i <- which(a$scope == acc_m3a_scopes[[scope]])
  if (length(i) != 1L) stop("acceptance: the alpha table has no single row \"", acc_m3a_scopes[[scope]], "\"", call. = FALSE)
  a[[column]][i]
}

# Cohen's kappa that msa_agreement() gives between two vectors of labels on
# the same objects: one item per pair, the first label as the response and
# the second as the reference (one prompt, one model, one replicate).
acc_m3a_pair_kappa <- function(x, y, levels, weights = "unweighted") {
  ids <- sprintf("pair%05d", seq_along(x))
  runs <- acc_m3a_runs(item = ids, prompt = "first", model = "m", rep = 1L, value = as.character(x))
  ag <- msa_agreement(runs, levels = levels, reference = stats::setNames(as.character(y), ids), weights = weights)
  acc_m3a_kappa(ag, "all")
}

# Cohen's kappa (Formelsammlung §5) -------------------------------------------------

acc_m3a_weight_types <- c("unweighted", "linear", "quadratic")

# Agreement weights of Formelsammlung §5 for K ordered categories.
acc_m3a_weights <- function(K, type = acc_m3a_weight_types) {
  type <- match.arg(type)
  d <- abs(outer(seq_len(K), seq_len(K), "-"))
  switch(type,
         unweighted = (d == 0) * 1,
         linear = 1 - d / (K - 1),
         quadratic = 1 - (d / (K - 1))^2)
}

acc_m3a_crosstab <- function(x, y, levels) {
  unclass(table(factor(x, levels = levels), factor(y, levels = levels)))
}

# Mini-reference: weighted kappa of a K x K table of counts or proportions
# with agreement weights w (Formelsammlung §5; Cohen 1968, Formula 8 with
# w = 1 - v / v_max, footnote 3).
acc_m3a_kappa_table <- function(tab, w) {
  p <- tab / sum(tab)
  pe <- outer(rowSums(p), colSums(p))
  (sum(w * p) - sum(w * pe)) / (1 - sum(w * pe))
}

# Oracles of K-M3a-1 on the pairs (x, y) with the categories `levels` in scale
# order. irr::kappa2 builds its scale from the observed codes, so the caller
# passes pairs in which every category occurs (ACC-4); the codes 1..K make irr
# sort the categories numerically. psych takes disagreement weights (|i - j|
# or its square), DescTools agreement weights by name; psych's note on
# confidence limits beyond +-1 is no part of the comparison and is muffled.
acc_m3a_oracle_kappa <- function(x, y, levels, type = acc_m3a_weight_types) {
  type <- match.arg(type)
  K <- length(levels)
  tab <- acc_m3a_crosstab(x, y, levels)
  d <- abs(outer(seq_len(K), seq_len(K), "-"))
  r <- cbind(match(x, levels), match(y, levels))
  irr_w <- c(unweighted = "unweighted", linear = "equal", quadratic = "squared")[[type]]
  desc_w <- c(unweighted = "Unweighted", linear = "Equal-Spacing", quadratic = "Fleiss-Cohen")[[type]]
  psych_k <- suppressWarnings(if (type == "unweighted") {
    psych::cohen.kappa(tab)$kappa
  } else {
    psych::cohen.kappa(tab, w = if (type == "linear") d else d^2)$weighted.kappa
  })
  c(irr = irr::kappa2(r, weight = irr_w)$value,
    psych = unname(psych_k),
    DescTools = unname(DescTools::CohenKappa(tab, weights = desc_w)))
}

# Cohen's (1968) Table 1 as 200 pairs (Judge B as response, Judge A as
# reference), from the anchor (ANK-70).
acc_m3a_cohen_pairs <- function() {
  if (!is.null(acc_m3a$cohen)) return(acc_m3a$cohen)
  lv <- as.character(unlist(acc_m3a_value("ANK-70", "categories")))
  N <- as.numeric(acc_m3a_value("ANK-70", "N"))
  f <- N * acc_m3a_matrix(acc_m3a_value("ANK-70", "observed_proportions"))
  if (any(abs(f - round(f)) > acc_m3a_arith())) stop("acceptance: ANK-70 proportions times N are not whole counts", call. = FALSE)
  f <- round(f)
  out <- list(levels = lv, counts = f,
              response = rep(lv[row(f)], times = as.vector(f)),
              reference = rep(lv[col(f)], times = as.vector(f)))
  acc_m3a$cohen <- out
  out
}

# Fleiss' kappa (Formelsammlung §5) ----------------------------------------------------

# Counts n_ic of the valid answers of each item per category.
acc_m3a_counts <- function(item, value, levels) {
  ok <- !is.na(value)
  unclass(table(factor(item[ok], levels = unique(item)), factor(value[ok], levels = levels)))
}

# Mini-reference of Formelsammlung §5 (Fleiss 1971, Gl. (1)-(8)) with the
# variance of Fleiss, Nee & Landis (1979), Gl. (12), on counts n_ic with the
# same number m of ratings per item.
acc_m3a_fleiss_ref <- function(n_ic) {
  m <- unique(rowSums(n_ic))
  if (length(m) != 1L || m < 2) stop("acceptance: Fleiss mini-reference needs the same number m >= 2 of ratings per item", call. = FALSE)
  N <- nrow(n_ic)
  P_i <- (rowSums(n_ic^2) - m) / (m * (m - 1))
  p <- colSums(n_ic) / (N * m)
  q <- 1 - p
  P_bar <- mean(P_i)
  P_e <- sum(p^2)
  pq <- sum(p * q)
  var_fnl <- 2 / (N * m * (m - 1) * pq^2) * (pq^2 - sum(p * q * (q - p)))
  list(P_bar = P_bar, P_e = P_e, kappa = (P_bar - P_e) / (1 - P_e), se = sqrt(var_fnl), p = p, m = m, N = N)
}

# Ratings matrix (items x m) of the valid answers for irr::kappam.fleiss,
# which drops every row with a missing value.
acc_m3a_rating_matrix <- function(item, value) {
  ok <- !is.na(value)
  rows <- split(as.character(value[ok]), factor(item[ok], levels = unique(item)))
  do.call(rbind, rows)
}

# Names that mark a standard error in a result list.
acc_m3a_se_pattern <- "(?i)(^|[._])(se|se0|ase|sd|std|stderr)([._0-9]|$)|std[._ ]?err|standard[._ ]?error"

acc_m3a_se_fields <- function(x) {
  nm <- names(x)
  if (is.null(nm)) return(list())
  x[grepl(acc_m3a_se_pattern, nm, perl = TRUE)]
}

# The Fleiss part of an msa_agreement(fleiss = TRUE) result: element `fleiss`
# with the numeric element `kappa` (ACC-8).
acc_m3a_fleiss <- function(ag) {
  f <- ag$fleiss
  if (!is.list(f) || is.null(f$kappa) || !is.numeric(f$kappa) || length(f$kappa) != 1L) {
    stop("acceptance: the msa_agreement(fleiss = TRUE) result has no element fleiss$kappa (numeric of length 1)", call. = FALSE)
  }
  f
}

# Krippendorff's alpha (Formelsammlung §5) ----------------------------------------------

acc_m3a_metric_of <- c(unweighted = "nominal", linear = "ordinal", quadratic = "interval")

# Mini-reference in the general form of Krippendorff (2011), section E (PDF
# 9-10), without a coincidence matrix: values-by-units counts n_uc of the
# units with at least two valid values, n.c and n.. over these units;
# alpha = 1 - (n.. - 1) sum_u 1/(n_u. - 1) sum_{c<k} n_uc n_uk d2_ck /
# sum_{c<k} n.c n.k d2_ck. Values are the category scores 1..K (ordinal: the
# frequencies n.g between c and k, PDF 6; ratio PDF 7).
acc_m3a_kripp_ref <- function(scores, units, K, metric = c("nominal", "ordinal", "interval", "ratio")) {
  metric <- match.arg(metric)
  ok <- !is.na(scores)
  n_uc <- unclass(table(factor(units[ok], levels = unique(units)), factor(scores[ok], levels = seq_len(K))))
  n_uc <- n_uc[rowSums(n_uc) >= 2, , drop = FALSE]
  n_u <- rowSums(n_uc)
  n_c <- colSums(n_uc)
  n <- sum(n_c)
  d2 <- function(c, k) {
    switch(metric,
           nominal = as.numeric(c != k),
           interval = (c - k)^2,
           ratio = ((c - k) / (c + k))^2,
           ordinal = (sum(n_c[c:k]) - (n_c[c] + n_c[k]) / 2)^2)
  }
  num <- 0
  den <- 0
  for (c in seq_len(K - 1L)) {
    for (k in seq(c + 1L, K)) {
      w <- d2(c, k)
      num <- num + w * sum(n_uc[, c] * n_uc[, k] / (n_u - 1))
      den <- den + w * n_c[c] * n_c[k]
    }
  }
  list(alpha = 1 - (n - 1) * num / den, n = n, n_c = n_c, units = nrow(n_uc))
}

# Krippendorff's (2011) example (ANK-73) as observer x unit matrix.
acc_m3a_kripp_example <- function() {
  data <- acc_m3a_value("ANK-73", "data")
  obs <- as.character(unlist(acc_m3a_value("ANK-73", "observers")))
  do.call(rbind, lapply(obs, function(o) vapply(data[[o]], function(v) if (is.null(v)) NA_real_ else as.numeric(v), numeric(1))))
}

# Runs of an observer x unit matrix: observers as prompts (one model, one
# replicate) or as replicates (one prompt, one model); categories "1".."K".
acc_m3a_matrix_runs <- function(mat, observers_as = c("prompts", "replicates")) {
  observers_as <- match.arg(observers_as)
  units <- sprintf("u%02d", seq_len(ncol(mat)))
  item <- rep(units, each = nrow(mat))
  obs <- rep(seq_len(nrow(mat)), times = ncol(mat))
  value <- ifelse(is.na(as.vector(mat)), NA_character_, as.character(as.vector(mat)))
  if (observers_as == "prompts") {
    acc_m3a_runs(item = item, prompt = paste0("obs", obs), model = "m", rep = 1L, value = value)
  } else {
    acc_m3a_runs(item = item, prompt = "p", model = "m", rep = obs, value = value)
  }
}

# Attribute statistics (Formelsammlung §5) ----------------------------------------------

# Mini-reference with explicit loops over items, cells and units: hit rate
# (share of valid answers equal to the reference) overall and per prompt x
# model, share of items with at least one valid answer whose valid answers are
# all correct, modal answer per item (most frequent valid answer, ties to the
# lowest category in scale order, NA without valid answer), repeatability
# (share of item x prompt x model cells with identical valid answers among the
# cells with at least two) overall and per prompt x model, reproducibility
# across prompts (units item x model), across models (units item x prompt) and
# overall (units item), each over the units with at least two valid answers.
# Percentages.
acc_m3a_attribute_ref <- function(d, ref, levels) {
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  pct <- function(x) if (length(x)) 100 * mean(x) else NA_real_
  same <- function(v) {
    v <- v[!is.na(v)]
    if (length(v) < 2L) NA else all(v == v[1])
  }
  d$ref <- unname(ref[d$item_id])
  valid <- !is.na(d$value)
  hit <- d$value[valid] == d$ref[valid]
  cond <- unique(d[, c("prompt_id", "model_id")])
  acc_by <- vapply(seq_len(nrow(cond)), function(i) {
    s <- valid & d$prompt_id == cond$prompt_id[i] & d$model_id == cond$model_id[i]
    pct(d$value[s] == d$ref[s])
  }, numeric(1))
  items <- unique(d$item_id)
  all_correct <- unlist(lapply(items, function(it) {
    s <- valid & d$item_id == it
    if (!any(s)) NULL else all(d$value[s] == d$ref[s])
  }))
  modal <- vapply(items, function(it) {
    v <- d$value[valid & d$item_id == it]
    if (!length(v)) return(NA_character_)
    n <- vapply(levels, function(l) sum(v == l), numeric(1))
    levels[which(n == max(n))[1]]
  }, character(1))
  unit_share <- function(keys) {
    u <- unique(d[, keys, drop = FALSE])
    r <- vapply(seq_len(nrow(u)), function(i) {
      s <- rep(TRUE, nrow(d))
      for (k in keys) s <- s & d[[k]] == u[[k]][i]
      same(d$value[s])
    }, logical(1))
    list(units = u, consistent = r)
  }
  cells <- unit_share(c("item_id", "prompt_id", "model_id"))
  rep_by <- vapply(seq_len(nrow(cond)), function(i) {
    s <- cells$units$prompt_id == cond$prompt_id[i] & cells$units$model_id == cond$model_id[i]
    pct(cells$consistent[s & !is.na(cells$consistent)])
  }, numeric(1))
  share <- function(u) pct(u$consistent[!is.na(u$consistent)])
  list(accuracy_overall = pct(hit),
       accuracy = data.frame(prompt_id = cond$prompt_id, model_id = cond$model_id, pct_correct = acc_by, stringsAsFactors = FALSE),
       pct_items_all_correct = pct(all_correct),
       modal = stats::setNames(unname(modal), items),
       repeatability_overall = share(cells),
       repeatability = data.frame(prompt_id = cond$prompt_id, model_id = cond$model_id, pct_items_consistent = rep_by,
                                  stringsAsFactors = FALSE),
       reproducibility = c(across_prompts = share(unit_share(c("item_id", "model_id"))),
                           across_models = share(unit_share(c("item_id", "prompt_id"))),
                           overall = share(unit_share("item_id"))))
}

# Value of a per prompt x model table (accuracy, repeatability) of
# msa_agreement() or of the mini-reference.
acc_m3a_cell <- function(tab, prompt, model, column) {
  if (!is.data.frame(tab) || !all(c("prompt_id", "model_id", column) %in% names(tab))) {
    stop("acceptance: table lacks the columns prompt_id, model_id and ", column, call. = FALSE)
  }
  i <- which(tab$prompt_id == prompt & tab$model_id == model)
  if (length(i) != 1L) stop("acceptance: no single row for prompt ", prompt, " and model ", model, call. = FALSE)
  tab[[column]][i]
}

# Modal answers of an msa_agreement() result keyed by item.
acc_m3a_modal <- function(ag) {
  m <- ag$modal
  if (!is.data.frame(m) || !all(c("item_id", "value") %in% names(m))) {
    stop("acceptance: the msa_agreement() result has no modal table with item_id and value", call. = FALSE)
  }
  stats::setNames(as.character(m$value), m$item_id)
}

# Bias and linearity (Formelsammlung §6) ---------------------------------------------------

# Mini-reference of the t interval and test of AIAG (2010), p. 88-89
# (Formelsammlung §6) on deviations d.
acc_m3a_t_ref <- function(d, level = 0.95) {
  n <- length(d)
  m <- mean(d)
  s <- sqrt(sum((d - m)^2) / (n - 1))
  se <- s / sqrt(n)
  q <- stats::qt(1 - (1 - level) / 2, n - 1)
  t <- m / se
  c(n = n, bias = m, sd = s, se = se, t = t, t_quantile = q, lower = m - q * se, upper = m + q * se,
    p_value = 2 * stats::pt(-abs(t), n - 1))
}

# Mini-reference of the handbook computation of AIAG (2010), p. 96-98: slope a
# and intercept b from the sums over all g·m single values, s with gm - 2
# degrees of freedom, t values of slope and intercept, the t quantile and R².
# s is taken from the residuals, sum (y - b - a x)², which equals the
# handbook's sum y² - b sum y - a sum x y for the least-squares line without
# its cancellation.
acc_m3a_lin_ref <- function(x, y, level = 0.95) {
  gm <- length(y)
  a <- (sum(x * y) - sum(x) * sum(y) / gm) / (sum(x^2) - sum(x)^2 / gm)
  b <- mean(y) - a * mean(x)
  s <- sqrt(sum((y - b - a * x)^2) / (gm - 2))
  sxx <- sum((x - mean(x))^2)
  list(slope = a, intercept = b, s = s, sxx = sxx, xbar = mean(x), n = gm, df = gm - 2,
       t_quantile = stats::qt(1 - (1 - level) / 2, gm - 2),
       t_slope = a / (s / sqrt(sxx)),
       t_intercept = b / (sqrt(1 / gm + mean(x)^2 / sxx) * s),
       r_squared = 1 - sum((y - b - a * x)^2) / sum((y - mean(y))^2))
}

# Confidence band of the line at x0 (AIAG 2010, p. 97).
acc_m3a_band_ref <- function(L, x0) {
  h <- L$t_quantile * L$s * sqrt(1 / L$n + (x0 - L$xbar)^2 / L$sxx)
  fit <- L$intercept + L$slope * x0
  cbind(reference = x0, fit = fit, lower = fit - h, upper = fit + h)
}

# "Bias = 0" lies entirely within the band from the smallest to the largest
# reference value (AIAG 2010, p. 98; ACC-12): the concave lower bound has its
# maximum and the convex upper bound its minimum at an end of the range or at
# the stationary point x̄ ± |a| Sxx / sqrt(n (t² s² - a² Sxx)), which exists
# when t² s² > a² Sxx.
acc_m3a_in_band_ref <- function(L, lo, hi) {
  cand <- c(lo, hi)
  den <- L$n * (L$t_quantile^2 * L$s^2 - L$slope^2 * L$sxx)
  if (den > 0) {
    u <- abs(L$slope) * L$sxx / sqrt(den)
    cand <- c(cand, L$xbar + u, L$xbar - u)
  }
  cand <- cand[cand >= lo & cand <= hi]
  B <- acc_m3a_band_ref(L, cand)
  all(B[, "lower"] <= 0 & B[, "upper"] >= 0)
}

# Item means of the deviations (mean over the valid values of an item) with
# the reference of the item.
acc_m3a_item_means <- function(item, x, d) {
  f <- factor(item, levels = unique(item))
  data.frame(reference = as.numeric(tapply(x, f, function(v) v[1])), bias = as.numeric(tapply(d, f, mean)))
}

# A named numeric field of an msa_bias() result, with the elements `keys`
# (finite unless allowed to be NA).
acc_m3a_bias_field <- function(b, field, keys) {
  v <- b[[field]]
  if (is.null(v) || !is.numeric(v) || is.null(names(v)) || !all(keys %in% names(v))) {
    stop("acceptance: the msa_bias() result has no numeric field ", field, " with the elements ",
         paste(keys, collapse = ", "), call. = FALSE)
  }
  v[keys]
}

# Text checks of the note on the two linearity computations (Formelsammlung
# Nr. 2, ACC-13): it names the item means, the degrees of freedom of both
# regressions (as numbers of the data or as gm - 2 and g - 2) and the
# correlation of the replicates of an item.
acc_m3a_norm <- function(x) {
  x <- paste(x, collapse = " ")
  x <- gsub("\\\\([[:punct:]])", "\\1", x)
  for (ch in c("`", "*", "‘", "’", "“", "”", "„", "\"", "'")) x <- gsub(ch, "", x, fixed = TRUE)
  trimws(gsub("[[:space:]]+", " ", x))
}

acc_m3a_difference_named <- function(text, df_handbook, df_means) {
  t <- acc_m3a_norm(text)
  num <- function(k) grepl(sprintf("(?<![0-9.,])%d(?![0-9]|[.,][0-9])", as.integer(k)), t, perl = TRUE)
  c(item_means = grepl("(?i)item[- ]?means?", t, perl = TRUE),
    degrees_of_freedom = grepl("(?i)degrees? of freedom|\\bdf\\b", t, perl = TRUE),
    df_handbook = num(df_handbook) || grepl("(?i)\\bg\\s*[·*×]?\\s*m\\s*[-−–]\\s*2\\b", t, perl = TRUE),
    df_item_means = num(df_means) || grepl("(?i)\\bg\\s*[-−–]\\s*2\\b", t, perl = TRUE),
    correlation = grepl("(?i)correlat|not independent|dependen", t, perl = TRUE))
}

# AIAG data sheets (ANK-74 to ANK-76) ------------------------------------------------------

acc_m3a_int <- function(v, what) {
  x <- suppressWarnings(as.numeric(v))
  if (anyNA(x) || any(abs(x - round(x)) > 0)) stop("acceptance: column ", what, " holds no whole numbers", call. = FALSE)
  as.integer(round(x))
}

acc_m3a_dbl <- function(v, what) {
  x <- suppressWarnings(as.numeric(v))
  if (anyNA(x)) stop("acceptance: column ", what, " holds no numbers", call. = FALSE)
  x
}

# Canonical form of a data sheet (canonical_form of the anchor): rows sorted,
# columns in anchor order, whole numbers as %d, reference and value of the bias
# and linearity sheets as %.2f.
acc_m3a_canonical_lines <- function(id, d) {
  if (identical(id, "ANK-74")) {
    part <- acc_m3a_int(d$part, "part")
    trial <- acc_m3a_int(d$trial, "trial")
    appraiser <- as.character(d$appraiser)
    o <- order(part, appraiser, trial, method = "radix")
    sprintf("%d,%s,%d,%d,%d", part[o], appraiser[o], trial[o],
            acc_m3a_int(d$value, "value")[o], acc_m3a_int(d$reference, "reference")[o])
  } else {
    part <- acc_m3a_int(d$part, "part")
    trial <- acc_m3a_int(d$trial, "trial")
    o <- order(part, trial, method = "radix")
    sprintf("%d,%.2f,%d,%.2f", part[o], acc_m3a_dbl(d$reference, "reference")[o], trial[o],
            acc_m3a_dbl(d$value, "value")[o])
  }
}

acc_m3a_canonical_sha256 <- function(lines) {
  f <- tempfile("acc-m3a-canon-")
  on.exit(unlink(f), add = TRUE)
  con <- file(f, "wb")
  writeBin(charToRaw(enc2utf8(paste0(paste(lines, collapse = "\n"), "\n"))), con)
  close(con)
  acc_sha256(f)
}

# Data sheet of anchor `id` from reference/quellen/data/aiag/ with the columns,
# rows and content hash of the anchor; once per test run.
acc_m3a_aiag <- function(id) {
  key <- paste0("aiag_", id)
  if (!is.null(acc_m3a[[key]])) return(acc_m3a[[key]])
  meta <- acc_m3a_value(id, "data_file")
  path <- file.path(acc_repo_root(), meta$path)
  if (!file.exists(path)) {
    stop("acceptance: local AIAG data sheet missing (", id, ", docs/01 §6, ACC-2): ", path, call. = FALSE)
  }
  d <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  cols <- as.character(unlist(meta$columns))
  if (!identical(names(d), cols) || nrow(d) != as.integer(meta$rows)) {
    stop("acceptance: ", path, " does not have the columns (", paste(cols, collapse = ", "), ") and ", meta$rows,
         " rows of ", id, call. = FALSE)
  }
  if (!identical(acc_m3a_canonical_sha256(acc_m3a_canonical_lines(id, d)), meta$content_sha256)) {
    stop("acceptance: ", path, " does not hold the data of ", id, " (SHA-256 of the canonical form differs)", call. = FALSE)
  }
  acc_m3a[[key]] <- d
  d
}

# Bias and linearity sheets as runs: item = part, one prompt (the operator),
# one model (the gage), replicate = trial; reference per part.
acc_m3a_numeric_runs <- function(d) {
  acc_m3a_runs(item = paste0("part", d$part), prompt = "operator", model = "gage", rep = d$trial,
               value = as.numeric(d$value))
}

acc_m3a_numeric_reference <- function(d) {
  r <- unique(data.frame(item_id = paste0("part", d$part), reference = as.numeric(d$reference), stringsAsFactors = FALSE))
  if (anyDuplicated(r$item_id)) stop("acceptance: a part carries two reference values", call. = FALSE)
  r
}

# Attribute sheet as runs: item = part, prompt = appraiser, one model,
# replicate = trial, categories "0" and "1"; reference decision per part.
acc_m3a_attribute_runs <- function(d, appraisers = c("A", "B", "C")) {
  d <- d[d$appraiser %in% appraisers, , drop = FALSE]
  acc_m3a_runs(item = paste0("part", d$part), prompt = d$appraiser, model = "gage", rep = d$trial,
               value = as.character(d$value))
}

acc_m3a_attribute_reference <- function(d) {
  r <- unique(data.frame(part = paste0("part", d$part), reference = as.character(d$reference), stringsAsFactors = FALSE))
  if (anyDuplicated(r$part)) stop("acceptance: a part carries two reference decisions", call. = FALSE)
  stats::setNames(r$reference, r$part)
}

# Decisions of one appraiser in the order part, trial.
acc_m3a_decisions <- function(d, appraiser) {
  s <- d[d$appraiser == appraiser, , drop = FALSE]
  s <- s[order(s$part, s$trial, method = "radix"), , drop = FALSE]
  list(key = paste(s$part, s$trial), value = as.character(s$value), reference = as.character(s$reference))
}

# Vignette (K-M3a-7) --------------------------------------------------------------------

# Lines of the section of the knitted vignette whose header names the bias
# and the coverage (ACC-15); NULL without such a header.
acc_m3a_coverage_section <- function(lines) {
  lines <- acc_m1a_unfence(lines)
  is_header <- grepl("^#{1,6}[[:space:]]", lines)
  title <- trimws(sub("^#{1,6}[[:space:]]+", "", lines))
  hit <- which(is_header & grepl("(?i)\\bbias\\b", title, perl = TRUE) & grepl("(?i)coverage", title, perl = TRUE))
  if (!length(hit)) return(NULL)
  start <- hit[1]
  level <- nchar(sub("^(#{1,6}).*$", "\\1", lines))
  stop_at <- which(is_header & seq_along(lines) > start & level <= level[start])
  lines[seq(start, if (length(stop_at)) stop_at[1] - 1L else length(lines))]
}

# Rows of the scenario table of the section: a table whose columns start with
# scenario, coverage, mcse and n_sim (case-insensitive) and that holds the
# scenarios S-bias-1 and S-bias-2.
acc_m3a_coverage_rows <- function(section) {
  for (tab in acc_m1a_tables(section)) {
    cols <- lapply(c(scenario = "scenario", coverage = "coverage", mcse = "mcse", n_sim = "n_sim"),
                   function(w) acc_m1a_column(tab, w))
    if (any(vapply(cols, is.null, logical(1)))) next
    sc <- trimws(cols$scenario)
    if (!all(c("S-bias-1", "S-bias-2") %in% sc)) next
    return(data.frame(scenario = sc, coverage = trimws(cols$coverage), mcse = trimws(cols$mcse),
                      n_sim = trimws(cols$n_sim), stringsAsFactors = FALSE))
  }
  NULL
}

# A number shown in a cell: the first number token; a trailing percent sign
# turns it into a proportion. Returns the value and half a unit of the last
# shown digit on the proportion scale.
acc_m3a_shown_number <- function(cell) {
  tok <- regmatches(cell, regexpr("[-+]?(?:[0-9]+\\.?[0-9]*|\\.[0-9]+)(?:[eE][-+]?[0-9]+)?", cell, perl = TRUE))
  if (!length(tok)) return(c(value = NA_real_, half = NA_real_))
  x <- as.numeric(tok)
  mant <- sub("[eE].*$", "", tok)
  expo <- if (grepl("[eE]", tok)) as.numeric(sub("^.*[eE]", "", tok)) else 0
  dec <- if (grepl("\\.", mant)) nchar(sub("^[^.]*\\.", "", mant)) else 0
  half <- 0.5 * 10^(expo - dec)
  scale <- if (grepl("%", cell, fixed = TRUE)) 100 else 1
  c(value = x / scale, half = half / scale)
}
