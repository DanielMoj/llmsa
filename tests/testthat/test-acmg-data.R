test_that("AP1 reads only shipped items and validates explicit plans", {
  p <- ap1_test_plan()
  items <- acmg_items(); pilot <- acmg_items(pilot = TRUE)
  expect_identical(nrow(items), as.integer(p$design$items))
  expect_length(intersect(items$item_id, pilot$item_id), 0L)
  expect_true(all(is.na(items$reference[items$source == "insaid"])))
  expect_true(all(is.na(items$prior_differs_sol[items$source == "insaid"])))
  expect_true(all(items$protein[items$source == "insaid"] == ""))
  expect_identical(acmg_items(tempfile()), items)
  copy <- tempfile(fileext = ".yaml")
  p$design$seed <- 37L
  yaml::write_yaml(p, copy)
  expect_identical(acmg_plan(copy)$design$seed, 37L)
  for (field in c("cou", "models", "evaluation")) {
    bad <- p; bad[[field]] <- NULL; yaml::write_yaml(bad, copy)
    expect_error(acmg_plan(copy), "Invalid AP1 plan")
  }
  bad <- p; bad$design$items <- -1
  expect_error(acmg_validate_plan(bad), "design.items")
  bad <- p; bad$pilot$calls_per_model <- 1
  expect_error(acmg_validate_plan(bad), "pilot counts")
  bad <- p; bad$models[[1]]$seed <- 1.5
  expect_error(acmg_validate_plan(bad), "seed")
})

test_that("synthetic INSAID import checks the hash, schema and joins only in memory", {
  p <- ap1_test_plan()
  path <- tempfile(fileext = ".tsv")
  synthetic <- data.frame(gene = c("SYN1", "SYN2"), cdna = c("c.1A>G", "c.2A>T"),
                           protein = c("p.(Synthetic1)", "p.Synthetic2"),
                           classification = c("VOUS", "Benign"), status = "Validated")
  utils::write.table(synthetic, path, sep = "\t", quote = FALSE, row.names = FALSE)
  hash <- acmg_hash(path)
  items <- data.frame(item_id = c("synthetic-2", "synthetic-1"), source = "insaid", gene = rev(synthetic$gene),
                       hgvs = paste0("NM_1.1:", rev(synthetic$cdna)), reference = NA_character_, protein = "")
  got <- acmg_import_insaid(path, items, hash, acmg_parser(p))
  expect_identical(got$reference, c("Benign", "Uncertain significance"))
  expect_identical(got$protein, c("p.Synthetic2", "p.Synthetic1"))
  expect_identical(acmg_hash(path), hash)
  expect_true(all(is.na(items$reference)))
  expect_error(acmg_import_insaid(path, items, paste0("wrong-", hash), acmg_parser(p)), "SHA-256")
  expect_error(acmg_check_insaid(NULL, hash), "insaid-path")
  utils::write.table(rbind(synthetic, synthetic[1, ]), path, sep = "\t", quote = FALSE, row.names = FALSE)
  expect_error(acmg_import_insaid(path, items, acmg_hash(path), acmg_parser(p)), "duplicate")
  utils::write.table(synthetic[, -2], path, sep = "\t", quote = FALSE, row.names = FALSE)
  expect_error(acmg_import_insaid(path, items, acmg_hash(path), acmg_parser(p)), "cdna")
})

test_that("synthetic ERepo parsing enforces NM c notation, dates and anchored pool counts", {
  p <- ap1_test_plan()
  x <- data.frame(variant = c("NM_1.2(SYN):c.1A>G (p.Synthetic)", "NM_2.3:c.2A>G", "NC_1.1:g.3A>G",
                              "NM_1.2(SYN):c.4A>G", "NM_1.2(SYN):c.5A>G"),
                  Retracted = c("false", "false", "false", "true", "false"),
                  approval = c("2026-05-01", "2026-05-01", "2026-05-01", "2026-05-01", "2026-04-30"),
                  published = "2026-06-01", gene = "SYN", Assertion = "Benign", panel = "Synthetic VCEP", id = as.character(1:5))
  names(x) <- c("#Variation", "Retracted", "Approval Date", "Published Date", "HGNC Gene Symbol", "Assertion", "Expert Panel", "ClinVar Variation Id")
  got <- acmg_erepo_pool(x, p$cutoff_date, acmg_parser(p))
  expect_identical(got$hgvs, c("NM_1.2:c.1A>G", "NM_2.3:c.2A>G"))
  expect_identical(got$protein, c("p.Synthetic", ""))
  synthetic_counts <- list(classifications = 2, genes = 1, panels = 1, per_class = list(Benign = 2))
  expect_invisible(acmg_check_pool(got, synthetic_counts, acmg_parser(p)))
  synthetic_counts$classifications <- 3
  expect_error(acmg_check_pool(got, synthetic_counts, acmg_parser(p)), "ANK-51")
})

test_that("round-robin handles exhausted groups and a continued pilot without replacement", {
  p <- ap1_test_plan()
  # Explicitly synthetic, deliberately unequal pools.
  pool <- data.frame(id = 1:10, panel = rep(c("A", "B", "C"), c(5, 4, 1)))
  chosen <- acmg_seeded(p$design$seed, acmg_round_robin(pool, "panel", 8))
  expect_identical(chosen$panel, c("A", "B", "C", "A", "B", "A", "B", "A"))
  expect_false(anyDuplicated(chosen$id) > 0L)
  again <- acmg_seeded(p$design$seed, acmg_round_robin(pool, "panel", 8))
  expect_identical(chosen, again)
  expect_error(acmg_round_robin(pool, "panel", 11), "Insufficient")
  set.seed(31); before <- .Random.seed
  acmg_seeded(p$design$seed, runif(3))
  expect_identical(.Random.seed, before)
  expect_error(acmg_seeded(p$design$seed, stop("synthetic failure")), "synthetic failure")
  expect_identical(.Random.seed, before)
})

test_that("prior flags use strict dates, five classes, latest majority and the own panel", {
  p <- ap1_test_plan(); cl <- acmg_classes(p)
  # Independent synthetic submissions, including a flagged entry and a cutoff boundary.
  rows <- data.frame(date = as.Date(c("2025-01-01", "2025-02-01", "2025-02-01", "2025-02-01", "2025-03-01", NA)),
                      ClinicalSignificance = c("Benign", "Pathogenic", "PATHOGENIC", "Likely pathogenic", "Benign", "Benign"),
                      ReviewStatus = c("single", "flagged submission", "single", "single", "single", "single"),
                      Submitter = paste("Synthetic lab", 1:6))
  get_prior <- function(r, panel = "Example VCEP") acmg_prior(r, "2025-03-01", panel, "Benign", cl, "reviewed by expert panel")
  expect_identical(get_prior(rows)$class, "Pathogenic")
  expect_identical(get_prior(rows)$date, "2025-02-01")
  expect_true(get_prior(rows)$differs)
  expect_identical(get_prior(rows[-3, ])$class, "conflicting")
  expect_identical(get_prior(rows[6, ])$class, "none")
  rows$ClinicalSignificance[2:4] <- c("not provided", "other", "risk allele")
  expect_identical(get_prior(rows)$class, "Benign")
  rows <- rows[1:2, ]; rows$ClinicalSignificance <- c("Benign", "Pathogenic")
  rows$ReviewStatus[2] <- "reviewed by expert panel"
  rows$Submitter[2] <- "ClinGen   Example  Variant Curation Expert Panel"
  expect_identical(get_prior(rows)$class, "Benign")
  # With no name match, exclude all expert-panel submissions conservatively.
  expect_identical(get_prior(rows, "Unmatched VCEP")$class, "Benign")
  expect_true(get_prior(rows, "Unmatched VCEP")$panel_fallback)
  expect_false(get_prior(rows)$panel_fallback)
  expect_error(acmg_clinvar_dates("not a date"), "DateLastEvaluated")
})
