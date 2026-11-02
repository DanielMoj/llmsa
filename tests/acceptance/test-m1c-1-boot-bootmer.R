# K-M1c-1: for numeric and binary fits msa_boot(fit, nsim, level, seed) gives
# the same percentile quantiles as lme4::bootMer(fit$model, FUN, nsim, seed,
# type = "parametric") with a FUN written in this test from lme4::VarCorr after
# Formelsammlung §3 (acc_m1c_reference_fun() in setup-m1c.R; tolerance
# ANK-TOL.engine_boot), for level 0.90 and 0.95; no script under R/ contains
# one of the parallel calls forbidden by docs/01 §5 (mclapply, mcmapply,
# mcparallel, pvec, parallel = "multicore"; pattern test).
# Test form where the spec is silent (quantile definition, tolerance per
# statistic, scanned tokens): CRITERIA.json M1c, open ACC-1.

for (design in c("numeric", "binary")) {
  test_that(sprintf("K-M1c-1: the %s test fit and its reference bootstrap are usable (ankerRef: ANK-16, ANK-28)", design), {
    fit <- acc_m1c_fit(design)
    expect_identical(fit$type, design)
    expect_true(inherits(fit$model, "merMod"), label = sprintf("%s fit: lme4 model", design))
    ref <- acc_m1c_reference_boot(design)
    expect_identical(dim(ref$t), c(acc_m1c_boot_runs[[design]]$nsim, length(acc_m1c_statistics) + 2L))
    expect_true(all(is.finite(ref$t[, acc_m1c_statistics])), label = sprintf("%s: every reference replicate is finite", design))
    acc_m1c_expect_ndc_away_from_integers(ref, sprintf("%s reference bootstrap", design))
  })

  for (level in acc_m1c_levels) {
    test_that(sprintf("K-M1c-1: msa_boot() on the %s fit gives the percentile quantiles of lme4::bootMer with the reference FUN, level %s (ankerRef: ANK-TOL.engine_boot)",
                      design, format(level)), {
      res <- acc_m1c_msa_boot(design, level)
      expect_false(inherits(res$value, "error"),
                   label = sprintf("msa_boot() on the %s fit runs (%s)", design,
                                   if (inherits(res$value, "error")) conditionMessage(res$value) else "ok"))
      if (inherits(res$value, "error")) return(invisible())
      acc_m1c_expect_quantiles(res$value, acc_m1c_reference_boot(design), level, sprintf("%s fit", design))
    })
  }
}

# Pattern test over the parsed code (comments are no calls): a banned function
# as a call, a symbol, a namespace-qualified name or a string constant (get(),
# match.fun()), and the value "multicore" assigned to `parallel` as an
# argument, a list element or a field.
acc_m1c_banned_calls <- c("mclapply", "mcmapply", "mcparallel", "pvec")

acc_m1c_parallel_findings <- function(text) {
  pd <- utils::getParseData(parse(text = text, keep.source = TRUE), includeText = TRUE)
  if (is.null(pd) || !nrow(pd)) return(character())
  pd <- pd[pd$terminal & pd$token != "COMMENT", , drop = FALSE]
  pd <- pd[order(pd$line1, pd$col1), , drop = FALSE]
  bare <- gsub("^[\"'`]|[\"'`]$", "", pd$text)
  found <- character()
  banned <- bare %in% acc_m1c_banned_calls &
    pd$token %in% c("SYMBOL_FUNCTION_CALL", "SYMBOL", "SYMBOL_SUB", "STR_CONST", "SYMBOL_PACKAGE")
  found <- c(found, sprintf("line %d: %s", pd$line1[banned], pd$text[banned]))
  for (i in which(pd$token == "STR_CONST" & bare == "multicore")) {
    if (i < 2L || !pd$token[i - 1L] %in% c("EQ_SUB", "EQ_ASSIGN", "LEFT_ASSIGN")) next
    before <- bare[max(1L, i - 4L):(i - 2L)]
    if ("parallel" %in% before) found <- c(found, sprintf("line %d: parallel = %s", pd$line1[i], pd$text[i]))
  }
  found
}

test_that("K-M1c-1: the pattern test finds every forbidden parallel call in constructed code and none in allowed code", {
  forbidden <- c("parallel::mclapply(x, f)", "mcmapply(f, x, y)", "parallel::mcparallel(f())", "parallel::pvec(x, f)",
                 "lme4::bootMer(m, f, nsim = 10, parallel = \"multicore\", ncpus = 2)",
                 "opts$parallel <- \"multicore\"", "args[[\"parallel\"]] <- 'multicore'",
                 "do.call(get(\"mclapply\", asNamespace(\"parallel\")), list(x, f))", "g <- parallel::mclapply")
  for (code in forbidden) {
    expect_true(length(acc_m1c_parallel_findings(code)) > 0L, label = sprintf("pattern test finds `%s`", code))
  }
  allowed <- c("lme4::bootMer(m, f, nsim = 10, parallel = \"snow\", cl = cl)",
               "# parallel::mclapply is not used under R/ (docs/01 §5)",
               "if (identical(p, \"multicore\")) stop(\"use parallel = 'snow' with a cluster\")",
               "lapply(x, f)")
  for (code in allowed) {
    expect_identical(acc_m1c_parallel_findings(code), character(), label = sprintf("pattern test accepts `%s`", code))
  }
})

test_that("K-M1c-1: no script under R/ contains mclapply, mcmapply, mcparallel, pvec or parallel = \"multicore\" (docs/01 §5)", {
  dir <- file.path(acc_pkg_root(), "R")
  files <- list.files(dir, pattern = "\\.[RrSsq]$", full.names = TRUE)
  expect_true(length(files) > 0L, label = sprintf("R scripts under %s", dir))
  for (f in files) {
    text <- readLines(f, warn = FALSE, encoding = "UTF-8")
    found <- tryCatch(acc_m1c_parallel_findings(text), error = function(e) paste("parse error:", conditionMessage(e)))
    expect_identical(found, character(), label = sprintf("forbidden parallel calls in R/%s", basename(f)))
  }
})
