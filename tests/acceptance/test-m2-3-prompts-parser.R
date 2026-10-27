# K-M2-3: prompt templates of A.3 (ANK-69), rendering, parse_choice(whole_word),
# and the parser use of the pipeline. The whole-word parser has an independent
# mini-reference (acc_m2_parse_ww()); random inputs follow ANK-TOL.parser_cases.

test_that("K-M2-3: acmg_prompts() returns exactly the templates concise, role and json with the wording of A.3 (ankerRef: ANK-69)", {
  got <- acc_m2_main_templates()
  want <- acc_m2_templates()
  expect_identical(sort(names(got)), sort(names(want)))
  expect_identical(unname(got[names(want)]), unname(want))
})

test_that("K-M2-3: every template holds exactly the placeholders {gene} and {hgvs} and no reference class placeholder", {
  got <- acc_m2_main_templates()
  for (id in names(got)) {
    ph <- regmatches(got[[id]], gregexpr("\\{[A-Za-z_][A-Za-z0-9_]*\\}", got[[id]]))[[1]]
    expect_setequal(ph, unlist(acc_anchor("ANK-69")$value$placeholders))
    expect_false(grepl("{reference}", got[[id]], fixed = TRUE), info = id)
  }
})

test_that("K-M2-3: render_prompt fills the templates for every item without remaining {gene}, {hgvs} (main plan: gene, transcript and c. notation)", {
  render <- acc_m2_fn("render_prompt")
  tpl <- acc_m2_main_templates()
  for (items in list(acc_m2_fn("acmg_items")(), acc_m2_fn("acmg_items")(pilot = TRUE))) {
    for (i in seq_len(nrow(items))) {
      fields <- as.list(items[i, , drop = FALSE])
      for (id in names(tpl)) {
        out <- render(tpl[[id]], fields)
        expect_false(grepl("{gene}", out, fixed = TRUE) || grepl("{hgvs}", out, fixed = TRUE), info = paste(items$item_id[i], id))
        expect_identical(out, acc_m2_fill(tpl[[id]], items$gene[i], items$hgvs[i]), info = paste(items$item_id[i], id))
      }
    }
  }
  ex <- acc_anchor("ANK-69")$value$main_plan_variant_text$example
  expect_identical(acc_m2_fill("{gene} {hgvs}", "PAH", "NM_000277.2:c.1A>G"), ex)
})

test_that("K-M2-3: parse_choice() gains whole_word = FALSE as new last argument (docs/01 §4)", {
  fm <- acc_signature(llmsa::parse_choice)
  expect_identical(vapply(fm, `[[`, "", "name"), c("levels", "aliases", "whole_word"))
  expect_identical(fm[[2]]$default, "NULL")
  expect_identical(fm[[3]]$default, "FALSE")
})

test_that("K-M2-3: with whole_word = FALSE parse_choice() behaves as in v0.1.0", {
  classes <- acc_m2_classes()
  al <- acc_m2_aliases()
  aliases <- as.list(al)
  inputs <- c("Likely pathogenic", "Pathogenicity cannot be assessed", "Benign or likely benign", "P", "help",
              "Uncertain significance", "VUS", "lb", "The answer is: LIKELY BENIGN.", "", NA,
              "Classification: likely pathogenic (PS1, PM2)", "unable to classify", "vous", "pathogenic variant")
  for (with_aliases in c(FALSE, TRUE)) {
    p_new <- if (with_aliases) llmsa::parse_choice(classes, aliases) else llmsa::parse_choice(classes)
    p_def <- if (with_aliases) llmsa::parse_choice(classes, aliases, whole_word = FALSE) else llmsa::parse_choice(classes, whole_word = FALSE)
    for (x in inputs) {
      want <- acc_m2_parse_v010(x, classes, if (with_aliases) aliases else NULL)
      expect_identical(p_new(x), want, info = paste(with_aliases, x))
      expect_identical(p_def(x), want, info = paste(with_aliases, x))
    }
  }
})

test_that("K-M2-3: whole_word = TRUE: the cases of K-M2-3 (ankerRef: ANK-69)", {
  classes <- acc_m2_classes()
  p <- llmsa::parse_choice(classes, as.list(acc_m2_aliases()), whole_word = TRUE)
  cases <- list(
    "Likely pathogenic" = "Likely pathogenic",
    "Pathogenic (P)" = "Pathogenic",
    "Unable to classify" = NA_character_,
    "Pathogenicity cannot be assessed" = NA_character_,
    "Benign or likely benign" = NA_character_,
    "B" = "Benign", "LB" = "Likely benign", "VUS" = "Uncertain significance",
    "LP" = "Likely pathogenic", "P" = "Pathogenic"
  )
  for (x in names(cases)) {
    expect_identical(p(x), cases[[x]], info = x)
    expect_identical(acc_m2_parse_ww(x), cases[[x]], info = paste("mini-reference:", x))
  }
  for (ab in c("B", "LB", "VUS", "LP", "P")) {
    expect_identical(p(paste0("Answer: ", ab, ".")), cases[[ab]], info = ab)
    expect_identical(p(paste0("The class is ", tolower(ab))), cases[[ab]], info = ab)
  }
})

test_that("K-M2-3: whole_word = TRUE agrees with the mini-reference on aliases and random texts (ankerRef: ANK-69, ANK-TOL.parser_cases)", {
  classes <- acc_m2_classes()
  al <- acc_m2_aliases()
  p <- llmsa::parse_choice(classes, as.list(al), whole_word = TRUE)
  for (a in names(al)) {
    for (form in c(a, toupper(a), tolower(a), paste0("(", a, ")"), paste0(a, "."), paste0("Result: ", a, "!"))) {
      expect_identical(p(form), unname(al[[a]]), info = form)
    }
  }
  pc <- acc_m2_tol("parser_cases")
  vocab <- c(classes, names(al), "likely", "pathogenicity", "benignity", "uncertainty", "not", "or", "and", "is", "the",
             "variant", "class", "answer", "significance", "probably", "p53", "Bp", "LPS", "Pathogenic-like", "VUSs")
  seps <- c(" ", ", ", ". ", "; ", ": ", " (", ") ", " - ", "\n", "/", "! ", "? ", "\"", "'")
  old <- if (exists(".Random.seed", envir = globalenv())) get(".Random.seed", envir = globalenv()) else NULL
  on.exit(if (is.null(old)) rm(".Random.seed", envir = globalenv()) else assign(".Random.seed", old, envir = globalenv()), add = TRUE)
  set.seed(pc$seed)
  bad <- character()
  for (k in seq_len(pc$n)) {
    n <- sample.int(5L, 1L)
    w <- sample(vocab, n, replace = TRUE)
    w <- ifelse(stats::runif(n) < 0.3, toupper(w), ifelse(stats::runif(n) < 0.5, tolower(w), w))
    s <- sample(seps, n, replace = TRUE)
    x <- paste0(paste0(w, s), collapse = "")
    got <- p(x)
    want <- acc_m2_parse_ww(x)
    if (!identical(got, want)) bad <- c(bad, sprintf("%s -> %s, expected %s", deparse(x), format(got), format(want)))
    if (length(bad) >= 20L) break
  }
  expect_identical(bad, character())
})

test_that("K-M2-3: the pipeline parses concise, role and robustness answers with parse_choice(whole_word = TRUE) and json answers with parse_json_field(\"classification\") first", {
  m <- acc_m2_mock_ok()
  rows <- acc_m2_store_rows(m$store)
  expect_true(nrow(rows) > 0L)
  json_field <- llmsa::parse_json_field("classification")
  want <- vapply(seq_len(nrow(rows)), function(i) {
    txt <- rows$response[i]
    if (identical(rows$prompt_id[i], "json")) txt <- json_field(txt)
    acc_m2_parse_ww(txt)
  }, character(1))
  got <- as.character(rows$value)
  mismatch <- which(!(is.na(got) & is.na(want)) & !(!is.na(got) & !is.na(want) & got == want))
  expect_identical(length(mismatch), 0L,
                   info = paste(utils::head(sprintf("%s/%s: %s -> %s, expected %s", rows$item_id[mismatch], rows$prompt_id[mismatch],
                                                    deparse(rows$response[mismatch]), got[mismatch], want[mismatch]), 10), collapse = "\n"))
})
