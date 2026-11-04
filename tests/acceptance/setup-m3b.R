# Helpers for the M3b acceptance tests (docs/04-weitere-bausteine.md, K-M3b-1
# to K-M3b-6); a setup file for the reason given in setup-acceptance.R.
#
# Reference values come from reference/anchors/ (ANK-80 Plackett & Burman 1946,
# ANK-81 Lenth 1989, ANK-82 Daniel 1959, ANK-06, ANK-TOL) or from the oracles
# the criteria name (FrF2::pb with boxtyssedal = FALSE, unrepx::PSE,
# DoE.base::ME.Lenth with simulated = FALSE, stats::lm), called at test time on
# the same data; no package output is frozen. Local data: Tab. 2 and Tab. 3 of
# Lenth (1989) under reference/quellen/data/lenth/ (protected, git-ignored,
# docs/01 §6); a missing or altered file fails the test, it never skips it
# (AGENTS.md).
# The mini-references below are written from the sources (pages in the
# anchors) and Formelsammlung §7, independently of R/robustness.R.
# The false alarm rate of K-M3b-5 is a class A simulation and lives in
# tests/simulation/test-lenth-h0.R (docs/01 §8); the help page part of K-M3b-5
# is tested in test-m3b-5-help-page.R. Interpretations of points on which the
# spec is silent, and the contradictions found between the criteria and their
# sources or oracles (decided in ADR-050), are listed in
# orchestrator/handoff/M3b/CRITERIA.json under "open" (ACC-n).

acc_m3b <- new.env(parent = emptyenv())   # cache for one test run

# Anchors ------------------------------------------------------------------------

# Nested value of an anchor, e.g. acc_m3b_value("ANK-81", "example_II", "pse").
acc_m3b_value <- function(id, ...) {
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
acc_m3b_tol <- function(entry, key) {
  e <- acc_anchor("ANK-TOL")$value[[entry]]
  if (is.null(e)) stop("acceptance: ANK-TOL has no entry ", entry, call. = FALSE)
  v <- e[[key]]
  if (is.null(v)) stop("acceptance: ANK-TOL.", entry, " has no key ", key, call. = FALSE)
  v
}

acc_m3b_arith <- function() as.numeric(acc_m3b_tol("arithmetic", "abs_tol"))

# Half a unit of the last printed digit (docs/01 §2 Nr. 6) plus the arithmetic
# allowance for the binary representation of the printed decimals (ANK-81,
# tolerance.published).
acc_m3b_printed_tol <- function(decimals) 0.5 * 10^(-as.numeric(decimals)) + acc_m3b_arith()

# Seeded block with the RNG of docs/01 §5; the caller's RNG state is restored.
acc_m3b_with_seed <- function(seed, expr) {
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

# Plackett-Burman matrices (ANK-80) ----------------------------------------------------

acc_m3b_sizes <- function() as.integer(unlist(acc_m3b_value("ANK-80", "sizes")))

# Generator of ANK-80 for N runs as a vector of +1/-1 of length N - 1.
acc_m3b_generator <- function(N) {
  g <- acc_m3b_value("ANK-80", "generators", as.character(N))
  chars <- strsplit(g, "")[[1]]
  coding <- acc_m3b_value("ANK-80", "coding")
  if (!all(chars %in% names(coding)) || length(chars) != N - 1L) {
    stop("acceptance: ANK-80 generator for N = ", N, " is not a +/- string of length N - 1", call. = FALSE)
  }
  as.numeric(unlist(coding[chars]))
}

# Mini-reference of the construction (Plackett & Burman 1946, p. 319 and 323):
# the generator is the first row of the cyclic part, every further row is the
# row above shifted cyclically by one place to the right ("row_right") or to
# the left ("row_left"); or the generator is the first column and every
# further column the column before shifted down by one place ("column_down",
# the printed example of p. 319). A final row of -1 is added.
acc_m3b_pb_forms <- c("row_right", "row_left", "column_down")

acc_m3b_pb_reference <- function(N, form = acc_m3b_pb_forms) {
  form <- match.arg(form)
  g <- acc_m3b_generator(N)
  m <- N - 1L
  i <- row(diag(m))
  j <- col(diag(m))
  k <- switch(form,
              row_right = (j - i) %% m,
              row_left = (i + j - 2L) %% m,
              column_down = (i - j) %% m)
  rbind(matrix(g[k + 1L], m, m), rep(-1, m))
}

# Design matrix of a pb_design() result: the documented attribute `coded`,
# as a plain double matrix.
acc_m3b_coded <- function(d) {
  X <- attr(d, "coded")
  if (is.null(X)) stop("acceptance: the pb_design() result carries no attribute `coded`", call. = FALSE)
  X <- as.matrix(X)
  storage.mode(X) <- "double"
  dimnames(X) <- NULL
  X
}

acc_m3b_rows <- function(X) apply(X, 1, paste, collapse = ",")

# Row patterns as a sorted multiset; radix sorting keeps locale collation out.
acc_m3b_sorted_rows <- function(X) sort(acc_m3b_rows(X), method = "radix")

# Absolute J3 characteristics |sum_r x_ra x_rb x_rc| over all column triples, a
# multiset that row permutations, column permutations and column sign changes
# leave unchanged.
acc_m3b_j3 <- function(X) {
  cmb <- utils::combn(ncol(X), 3)
  sort(abs(colSums(X[, cmb[1, ], drop = FALSE] * X[, cmb[2, ], drop = FALSE] * X[, cmb[3, ], drop = FALSE])))
}

acc_m3b_j3_table <- function(X) {
  t <- table(acc_m3b_j3(X))
  paste(names(t), as.integer(t), sep = ":", collapse = " ")
}

# Equivalence of two +1/-1 designs up to row permutation, column permutation and
# sign changes of columns. Searches sigma, pi and s with
# A[i, j] == s[j] * B[sigma[i], pi[j]] and verifies every entry: the columns of
# A are signed so that its row 1 is +1, those of B so that a candidate row r is
# +1; columns are then matched one at a time, keeping a partial match only
# while the multisets of the row patterns agree and row 1 of A still meets row
# r of B. Patterns use the digits 0/1 and radix sorting, so no locale collation
# enters the comparison.
acc_m3b_equivalence <- function(A, B, budget = 1e6) {
  if (!identical(dim(A), dim(B))) return(list(found = FALSE, verified = FALSE, reason = "dimensions differ"))
  if (!all(A %in% c(-1, 1)) || !all(B %in% c(-1, 1))) {
    return(list(found = FALSE, verified = FALSE, reason = "entries other than +1/-1"))
  }
  N <- nrow(A)
  m <- ncol(A)
  nodes <- 0
  A1 <- sweep(A, 2, A[1, ], `*`)
  for (r in seq_len(N)) {
    B1 <- sweep(B, 2, B[r, ], `*`)
    pi <- integer(m)
    used <- logical(m)
    sa <- rep("", N)
    sb <- rep("", N)
    extend <- function(k) {
      nodes <<- nodes + 1
      if (nodes > budget) stop("acceptance: equivalence search exceeded its budget of ", budget, " nodes", call. = FALSE)
      if (k > m) return(TRUE)
      for (cand in which(!used)) {
        na <- paste0(sa, ifelse(A1[, k] > 0, "1", "0"))
        nb <- paste0(sb, ifelse(B1[, cand] > 0, "1", "0"))
        if (na[1] != nb[r] || !identical(sort(na, method = "radix"), sort(nb, method = "radix"))) next
        keep_a <- sa
        keep_b <- sb
        sa <<- na
        sb <<- nb
        used[cand] <<- TRUE
        pi[k] <<- cand
        if (extend(k + 1L)) return(TRUE)
        sa <<- keep_a
        sb <<- keep_b
        used[cand] <<- FALSE
        pi[k] <<- 0L
      }
      FALSE
    }
    if (extend(1L)) {
      sigma <- match(sa, sb)
      s <- A[1, ] * B[r, pi]
      ok <- !anyNA(sigma) && !anyDuplicated(sigma) &&
        all(A == sweep(B[sigma, pi, drop = FALSE], 2, s, `*`))
      return(list(found = TRUE, verified = ok, sigma = sigma, pi = pi, s = s, nodes = nodes))
    }
  }
  list(found = FALSE, verified = FALSE, nodes = nodes, reason = "no row, column and sign mapping exists")
}

# FrF2::pb() as oracle (docs/01 §6) with nruns = N and boxtyssedal = FALSE as
# K-M3b-2 names them (ADR-050 Nr. 1; with the default TRUE, FrF2 returns the
# Box-Tyssedal design for N = 16, ACC-5); randomize = FALSE only fixes the row
# order that K-M3b-2 leaves free, every other argument stays at its default
# (ACC-4). FrF2's notes on aliasing (warnings and printed text) are no part of
# the comparison and are muffled.
acc_m3b_frf2 <- function(N, boxtyssedal = FALSE) {
  d <- NULL
  utils::capture.output(d <- withCallingHandlers(
    FrF2::pb(nruns = N, boxtyssedal = boxtyssedal, randomize = FALSE),
    warning = function(w) invokeRestart("muffleWarning"),
    message = function(m) invokeRestart("muffleMessage")
  ))
  X <- as.matrix(attr(d, "desnum"))
  if (is.null(X) || !identical(dim(X), c(as.integer(N), as.integer(N) - 1L))) {
    stop("acceptance: FrF2::pb(nruns = ", N, ", boxtyssedal = ", boxtyssedal, ") gave no ", N, " x ", N - 1,
         " design matrix", call. = FALSE)
  }
  storage.mode(X) <- "double"
  dimnames(X) <- NULL
  X
}

# Lenth's method (ANK-81) ---------------------------------------------------------------

# Mini-reference of Lenth (1989), Gl. (1)-(5), p. 470: s0, PSE over the
# contrasts strictly below 2.5 s0, ME and SME with d = m/3 degrees of freedom,
# and the flags |c| > ME and |c| > SME.
acc_m3b_lenth_reference <- function(effects, alpha) {
  meth <- acc_m3b_value("ANK-81", "method")
  a <- abs(effects)
  m <- length(a)
  s0 <- meth$s0_factor * stats::median(a)
  pse <- meth$pse_factor * stats::median(a[a < meth$trim_factor * s0])
  d <- m / meth$df_divisor
  me <- stats::qt(1 - alpha / 2, d) * pse
  sme <- stats::qt((1 + (1 - alpha)^(1 / m)) / 2, d) * pse
  list(s0 = s0, pse = pse, me = me, sme = sme, active = a > me, active_simultaneous = a > sme)
}

# Effects as differences of the level means (Formelsammlung §7), one per column.
acc_m3b_mean_differences <- function(X, y) {
  apply(X, 2, function(x) mean(y[x > 0]) - mean(y[x < 0]))
}

# A finite numeric attribute of an msa_robustness() result (pse, me, sme,
# response_mean); a missing one stops the test instead of an empty comparison.
acc_m3b_attr <- function(x, name) {
  v <- attr(x, name, exact = TRUE)
  if (!is.numeric(v) || length(v) != 1L || !is.finite(v)) {
    stop("acceptance: the msa_robustness() result lacks a finite attribute `", name, "`", call. = FALSE)
  }
  as.numeric(v)
}

# Row of an msa_robustness() result per factor, in the order of `labels`.
acc_m3b_by_factor <- function(r, labels, column) {
  i <- match(labels, r$factor)
  if (anyNA(i)) {
    stop("acceptance: msa_robustness() lacks the factors ", paste(labels[is.na(i)], collapse = ", "), call. = FALSE)
  }
  r[[column]][i]
}

# CSV of reference/quellen/data/lenth/ with the SHA-256, columns and rows of ANK-81.
acc_m3b_lenth_file <- function(meta) {
  path <- file.path(acc_repo_root(), meta$path)
  if (!file.exists(path)) {
    stop("acceptance: local table of Lenth (1989) missing (K-M3b-3, ANK-81, docs/01 §6): ", path, call. = FALSE)
  }
  if (!identical(acc_sha256(path), meta$sha256)) {
    stop("acceptance: ", path, " is not the file of ANK-81 (SHA-256 differs)", call. = FALSE)
  }
  d <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  if (!identical(names(d), as.character(unlist(meta$columns))) || nrow(d) != meta$rows) {
    stop("acceptance: ", path, " does not have the columns and rows of ANK-81", call. = FALSE)
  }
  d
}

# Contrast columns named by products of single-letter base factors ("TWC").
acc_m3b_contrast_columns <- function(d, base, labels) {
  X <- vapply(labels, function(l) {
    chars <- strsplit(l, "")[[1]]
    if (!all(chars %in% base)) stop("acceptance: contrast ", l, " is no product of ", paste(base, collapse = ", "), call. = FALSE)
    Reduce(`*`, lapply(chars, function(ch) as.numeric(d[[ch]])))
  }, numeric(nrow(d)))
  colnames(X) <- labels
  X
}

# Example "II" or "IV" of Lenth (1989): the 15 contrast columns as a plain
# data.frame design, the response, the printed estimates of Tab. 3 and the
# anchor entry.
acc_m3b_lenth_example <- function(example) {
  key <- paste0("lenth_", example)
  if (!is.null(acc_m3b[[key]])) return(acc_m3b[[key]])
  ex <- acc_m3b_value("ANK-81", paste0("example_", example))
  d <- acc_m3b_lenth_file(ex$data_file)
  tab <- acc_m3b_lenth_file(acc_m3b_value("ANK-81", "contrasts_file"))
  tab <- tab[tab$example == example, , drop = FALSE]
  tab <- tab[order(tab$index), , drop = FALSE]
  if (nrow(tab) != ex$m) stop("acceptance: Tab. 3 of ANK-81 lacks contrasts of example ", example, call. = FALSE)
  base <- as.character(unlist(ex$base_factors))
  X <- acc_m3b_contrast_columns(d, base, tab$contrast)
  out <- list(design = as.data.frame(X, check.names = FALSE), X = X, labels = tab$contrast,
              y = as.numeric(d[[ex$response]]), printed = as.numeric(tab$estimate_table3), meta = ex)
  acc_m3b[[key]] <- out
  out
}

# Contrast columns of the full 2^k factorial (all 2^k - 1 main effects and
# interactions, standard order), for designs with m = 2^k - 1 effects.
acc_m3b_full_contrasts <- function(k) {
  base <- as.matrix(expand.grid(rep(list(c(-1, 1)), k)))
  X <- vapply(seq_len(2^k - 1), function(j) {
    bits <- which(bitwAnd(j, 2L^(seq_len(k) - 1L)) > 0)
    Reduce(`*`, lapply(bits, function(b) base[, b]))
  }, numeric(2^k))
  colnames(X) <- paste0("c", seq_len(ncol(X)))
  X
}

# DoE.base::ME.Lenth() as oracle for PSE, ME and SME (K-M3b-3, ADR-050 Nr. 2):
# simulated = FALSE selects Lenth's t quantiles with d = m/3 instead of the
# stored simulated critical values, alpha is the nominal level of the test.
# unrepx::ME() is no oracle (it draws ME and SME from a simulated reference
# distribution, ACC-7); unrepx::PSE() still is, for the PSE. A missing or
# non-finite value stops the test instead of an empty comparison.
acc_m3b_doe_lenth <- function(effects, alpha) {
  o <- DoE.base::ME.Lenth(unname(effects), simulated = FALSE, alpha = alpha)
  out <- c(pse = unname(o$PSE), me = unname(o$ME), sme = unname(o$SME))
  if (length(out) != 3L || !all(is.finite(out))) {
    stop("acceptance: DoE.base::ME.Lenth(simulated = FALSE) gave no finite PSE, ME and SME", call. = FALSE)
  }
  out
}

# Half-normal plot (ANK-82) -------------------------------------------------------------

# Mini-reference of the positions (Daniel 1959, p. 314; Formelsammlung §7).
acc_m3b_halfnormal_q <- function(m) stats::qnorm(0.5 + (seq_len(m) - 0.5) / (2 * m))

acc_m3b_dl_name <- function(entry) {
  f <- tryCatch(entry[[2]][[1]], error = function(e) NULL)
  if (is.list(f) && !is.null(f$name)) as.character(f$name) else ""
}

acc_m3b_as_text <- function(v) {
  if (is.null(v)) return(character())
  if (is.expression(v)) return(vapply(as.list(v), function(z) paste(deparse(z), collapse = " "), ""))
  if (is.language(v)) return(paste(deparse(v), collapse = " "))
  as.character(v)
}

# Records plot(x) on a null PDF device and returns what the display list drew:
# point sets (C_plotXY with their type), axis labels and titles (C_title),
# margin texts (C_mtext) and texts (C_text, which includes legend entries).
acc_m3b_plot_record <- function(x) {
  grDevices::pdf(NULL)
  dev <- grDevices::dev.cur()
  on.exit(grDevices::dev.off(dev), add = TRUE)
  grDevices::dev.control("enable")
  plot(x)
  dl <- grDevices::recordPlot()[[1]]
  out <- list(points = list(), xlab = character(), ylab = character(), main = character(),
              mtext = character(), text = character())
  for (e in dl) {
    args <- e[[2]]
    switch(acc_m3b_dl_name(e),
      C_plotXY = {
        out$points[[length(out$points) + 1L]] <- list(x = as.numeric(args[[2]]$x), y = as.numeric(args[[2]]$y),
                                                     type = as.character(args[[3]]))
      },
      C_title = {
        out$main <- c(out$main, acc_m3b_as_text(args[[2]]), acc_m3b_as_text(args[[3]]))
        out$xlab <- c(out$xlab, acc_m3b_as_text(args[[4]]))
        out$ylab <- c(out$ylab, acc_m3b_as_text(args[[5]]))
      },
      C_mtext = {
        out$mtext <- c(out$mtext, acc_m3b_as_text(args[[2]]))
      },
      C_text = {
        out$text <- c(out$text, acc_m3b_as_text(args[[3]]))
      },
      NULL)
  }
  out
}

# Point sets of the record that draw symbols for all m effects.
acc_m3b_effect_points <- function(rec, m) {
  Filter(function(p) p$type %in% c("p", "b", "o") && length(p$x) == m, rec$points)
}

# An msa_robustness object with m effects from the 2^5 contrasts (m <= 31) and
# a seeded response with distinct effect sizes.
acc_m3b_robustness_m <- function(m, seed = 5L) {
  X <- acc_m3b_full_contrasts(5)[, seq_len(m), drop = FALSE]
  y <- acc_m3b_with_seed(seed, as.numeric(X %*% seq(0.1, 3.1, length.out = m) / 16 + stats::rnorm(nrow(X), 0, 0.01)))
  msa_robustness(as.data.frame(X), y, factors = colnames(X))
}
