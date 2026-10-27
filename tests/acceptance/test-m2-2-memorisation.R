# K-M2-2: memorisation flags prior_clinvar_class_*, prior_date_*, prior_differs_*
# per cut-off date of the three models, recomputed from ClinVar submission_summary
# (ANK-41, column layout ANK-63) with the cut-off dates ANK-50, ANK-65, ANK-66.
# Readings the spec leaves open are all admitted (ACC-6, acc_m2_prior_options()).

acc_m2_flag_rows <- function() {
  items <- acc_m2_items()
  pilot <- acc_m2_pilot()
  rbind(cbind(file = "items.csv", items, stringsAsFactors = FALSE),
        cbind(file = "pilot.csv", pilot, stringsAsFactors = FALSE))
}

test_that("K-M2-2: the flags of every erepo row of items.csv and pilot.csv follow ClinVar before each cut-off date (ankerRef: ANK-41, ANK-50, ANK-63, ANK-65, ANK-66)", {
  d <- acc_m2_flag_rows()
  er <- d[d$source == "erepo", , drop = FALSE]
  pool <- acc_m2_pool()
  er$clinvar_id <- pool$clinvar_id[match(er$hgvs, pool$hgvs)]
  expect_false(anyNA(er$clinvar_id))
  rows <- acc_m2_clinvar_rows(er$clinvar_id[!is.na(er$clinvar_id)])
  expect_true(nrow(rows) > 0L)
  cut <- acc_m2_cutoffs()
  bad <- character()
  for (i in seq_len(nrow(er))) {
    if (is.na(er$clinvar_id[i])) next
    r <- rows[rows$VariationID == er$clinvar_id[i], , drop = FALSE]
    for (s in names(cut)) {
      cls <- er[[paste0("prior_clinvar_class_", s)]][i]
      dt <- er[[paste0("prior_date_", s)]][i]
      differs <- er[[paste0("prior_differs_", s)]][i]
      opts <- acc_m2_prior_options(r, cut[[s]], er$panel[i])
      parsed <- acc_m2_parse_date(dt)
      date_txt <- if (nzchar(dt) && !is.na(parsed)) format(parsed, "%Y-%m-%d") else if (nzchar(dt)) paste("unreadable:", dt) else ""
      ok <- any(tolower(trimws(opts$class)) == tolower(trimws(cls)) & opts$date == date_txt)
      if (!ok) {
        bad <- c(bad, sprintf("%s %s %s: class '%s' date '%s'; admissible: %s", er$file[i], er$item_id[i], s, cls, dt,
                              paste(unique(paste0(opts$class, "@", opts$date)), collapse = " | ")))
      }
      want_differs <- !tolower(cls) %in% "none" && !identical(tolower(cls), tolower(er$reference[i]))
      if (!identical(toupper(differs), if (want_differs) "TRUE" else "FALSE")) {
        bad <- c(bad, sprintf("%s %s %s: prior_differs '%s' with class '%s' and reference '%s'", er$file[i], er$item_id[i], s,
                              differs, cls, er$reference[i]))
      }
    }
  }
  expect_identical(bad, character())
})

test_that("K-M2-2: prior_date is empty exactly for class none and lies before the cut-off date; prior_differs is TRUE or FALSE", {
  d <- acc_m2_flag_rows()
  er <- d[d$source == "erepo", , drop = FALSE]
  cut <- acc_m2_cutoffs()
  for (s in names(cut)) {
    cls <- er[[paste0("prior_clinvar_class_", s)]]
    dt <- er[[paste0("prior_date_", s)]]
    expect_true(all(nzchar(cls)), info = s)
    expect_identical(!nzchar(dt), tolower(cls) == "none", info = s)
    parsed <- acc_m2_parse_date(dt[nzchar(dt)])
    expect_false(anyNA(parsed), info = s)
    expect_true(all(parsed <= cut[[s]]), info = s)
    expect_true(all(toupper(er[[paste0("prior_differs_", s)]]) %in% c("TRUE", "FALSE")), info = s)
  }
})

test_that("K-M2-2: all nine flag columns are empty for the INSAID items", {
  items <- acc_m2_items()
  d <- items[items$source == "insaid", , drop = FALSE]
  expect_identical(nrow(d), as.integer(acc_anchor("ANK-59")$value$insaid_items))
  for (col in acc_m2_columns()[9:17]) expect_true(all(d[[col]] == ""), info = col)
})

test_that("K-M2-2: the admissible flag values detect a wrong cut-off date and a wrong majority", {
  rows <- data.frame(
    VariationID = "1",
    ClinicalSignificance = c("Pathogenic", "Likely pathogenic", "Likely pathogenic", "Benign", "Uncertain significance"),
    DateLastEvaluated = c("Mar 01, 2020", "Jun 01, 2024", "Jun 01, 2024", "Jun 01, 2024", "Jan 05, 2026"),
    ReviewStatus = c("criteria provided, single submitter", "criteria provided, single submitter",
                     "no assertion criteria provided", "criteria provided, single submitter", "reviewed by expert panel"),
    Submitter = c("Lab A", "Lab B", "Lab C", "Lab D", "ClinGen Example Variant Curation Expert Panel"),
    stringsAsFactors = FALSE
  )
  rows$date <- acc_m2_parse_date(rows$DateLastEvaluated)
  o <- acc_m2_prior_options(rows, as.Date("2025-01-01"), "Example VCEP")
  expect_identical(unique(o$class), "Likely pathogenic")
  expect_identical(unique(o$date), "2024-06-01")
  o <- acc_m2_prior_options(rows, as.Date("2023-12-31"), "Example VCEP")
  expect_identical(unique(paste(o$class, o$date)), "Pathogenic 2020-03-01")
  o <- acc_m2_prior_options(rows, as.Date("2019-12-31"), "Example VCEP")
  expect_identical(unique(o$class), "none")
  rows2 <- rows[c(1, 2, 4), , drop = FALSE]
  o <- acc_m2_prior_options(rows2, as.Date("2025-01-01"), "Example VCEP")
  expect_identical(unique(o$class), "conflicting")
  # the expert panel's own submission never counts
  o <- acc_m2_prior_options(rows, as.Date("2026-06-01"), "Example VCEP")
  expect_false("Uncertain significance" %in% o$class)
})
