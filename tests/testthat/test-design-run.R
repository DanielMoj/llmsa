test_that("msa_design crosses items, prompts, models, reps and blocks", {
  d <- msa_design(c(a = "x", b = "y", c = "z"), prompts = c("P {text}", "Q {text}"),
                  models = c("m1", "m2"), reps = 2, blocks = 2, seed = 1)
  expect_s3_class(d, "msa_design")
  expect_equal(nrow(d), 3 * 2 * 2 * 2 * 2)
  expect_setequal(unique(d$model_id), c("m1", "m2"))
  expect_setequal(unique(d$prompt_id), c("P1", "P2"))
  expect_true(all(d$position[d$block == 1] == seq_len(24)))
  expect_equal(d$prompt[d$item_id == "a" & d$prompt_id == "P1"][1], "P x")
})

test_that("prompt placeholders use any item column", {
  items <- data.frame(item_id = c("v1", "v2"), text = c("t1", "t2"), gene = c("BRCA2", "TP53"))
  d <- msa_design(items, prompts = c(g = "{gene}: {text} ({item_id})"), models = "m", reps = 1, order = "fixed")
  expect_equal(d$prompt, c("BRCA2: t1 (v1)", "TP53: t2 (v2)"))
})

test_that("design validates input", {
  expect_error(msa_design(c("a", "a"), "P", "m"), NA)
  expect_error(msa_design(data.frame(item_id = c("a", "a"), text = 1:2), "P", "m"), "unique")
  expect_error(msa_design("a", character(), "m"))
  expect_error(msa_design("a", "P", "m", reps = 0))
})

test_that("mock backend, parser, run, store and resume work together", {
  truth <- c(v1 = 1.5, v2 = -1.5, v3 = 0)
  lv <- c("B", "VUS", "P")
  d <- msa_design(c(v1 = "a", v2 = "b", v3 = "c"), prompts = c(a = "A {text}", b = "B {text}"),
                  models = c("m1", "m2"), reps = 2, seed = 1)
  bk <- backend_mock(truth, levels = lv, thresholds = c(-0.5, 0.5), sd_rep = 0.01,
                     sd_prompt = 0.01, sd_model = 0.01, seed = 3)
  store <- tempfile(fileext = ".csv")
  r <- msa_run(d, bk, parse = parse_choice(lv), store = store, verbose = FALSE)
  expect_s3_class(r, "msa_runs")
  expect_equal(nrow(r), nrow(d))
  expect_true(all(r$value[r$item_id == "v1"] == "P"))
  expect_true(all(r$value[r$item_id == "v2"] == "B"))
  expect_true(all(nchar(r$prompt_hash) == 32))
  expect_true(file.exists(store))
  # resume skips everything already stored
  r2 <- msa_run(d, bk, parse = parse_choice(lv), store = store, resume = TRUE, verbose = FALSE)
  expect_equal(nrow(r2), nrow(d))
  expect_equal(nrow(utils::read.csv(store)), nrow(d))
  # a block can be run separately
  d2 <- msa_design(c(v1 = "a", v2 = "b"), prompts = "A {text}", models = "m1", reps = 1, blocks = 2)
  r3 <- msa_run(d2, bk, block = 2, verbose = FALSE)
  expect_equal(unique(r3$block), 2L)
})

test_that("backend errors and parse failures are recorded, not fatal", {
  bad <- function(prompt, model, row) if (row$item_id == "v2") stop("boom") else "The result is: 3.5"
  d <- msa_design(c(v1 = "a", v2 = "b"), prompts = "A {text}", models = "m", reps = 1, order = "fixed")
  r <- msa_run(d, bad, parse = parse_number(), verbose = FALSE)
  expect_equal(r$value, c("3.5", NA))
  expect_equal(r$error, c(NA, "boom"))
})

test_that("sqlite store works when RSQLite is available", {
  skip_if_not_installed("RSQLite"); skip_if_not_installed("DBI")
  d <- msa_design(c(v1 = "a", v2 = "b"), prompts = "A {text}", models = "m", reps = 2, seed = 1)
  bk <- function(prompt, model, row) list(text = "42", meta = list(tokens = 3))
  store <- tempfile(fileext = ".sqlite")
  r <- msa_run(d, bk, parse = parse_number(), store = store, verbose = FALSE)
  con <- DBI::dbConnect(RSQLite::SQLite(), store)
  on.exit(DBI::dbDisconnect(con))
  expect_equal(DBI::dbGetQuery(con, "select count(*) as n from runs")$n, 4)
  expect_true(grepl("tokens", r$meta[1]))
})

test_that("as_msa_runs renames columns and adds a block", {
  df <- data.frame(id = c("a", "b"), p = "P1", m = "m1", r = 1, y = c(1, 2))
  x <- as_msa_runs(df, item = "id", prompt = "p", model = "m", rep = "r", value = "y")
  expect_s3_class(x, "msa_runs")
  expect_true(all(c("item_id", "prompt_id", "model_id", "rep", "value", "block") %in% names(x)))
  expect_error(as_msa_runs(df), "missing")
})

test_that("parsers extract values", {
  expect_equal(parse_number()("IC50 ~ 12.5 nM"), 12.5)
  expect_equal(parse_number(decimal = ",")("Wert: 3,25"), 3.25)
  expect_true(is.na(parse_number()("no number here")))
  lv <- c("Benign", "Likely benign", "VUS", "Likely pathogenic", "Pathogenic")
  pc <- parse_choice(lv, aliases = list(LP = "Likely pathogenic"))
  expect_equal(pc("Class: likely pathogenic (PS1)"), "Likely pathogenic")
  expect_equal(pc("Pathogenic."), "Pathogenic")
  expect_equal(pc("-> LP"), "Likely pathogenic")
  expect_true(is.na(pc("unclear")))
  expect_equal(parse_json_field("class")('{"class": "VUS", "n": 2}'), "VUS")
  expect_equal(parse_json_field("n")('x {"class": "VUS", "n": 2} y'), "2")
  expect_true(is.na(parse_json_field("class")("no json")))
})
