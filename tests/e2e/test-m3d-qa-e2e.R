# QA / Red Team E2E tests for M3d (fixed seed: 20261106)

qa_m3d_anchor <- function(id) {
  root <- Sys.getenv("REPO_ROOT", unset = "")
  rel <- file.path("reference", "anchors", paste0(id, ".json"))
  candidates <- c(
    if (nzchar(root)) file.path(root, rel),
    testthat::test_path("..", "..", rel),
    system.file("validation", "latent", "anchors", paste0(id, ".json"), package = "llmsa")
  )
  hit <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (!length(hit)) stop("Anchor file not found: ", id, call. = FALSE)
  jsonlite::read_json(hit[1L], simplifyVector = FALSE)
}

qa_m3d_fixture_path <- function(name) {
  root <- Sys.getenv("REPO_ROOT", unset = "")
  rel <- file.path("tests", "fixtures", "api", name)
  candidates <- c(
    if (nzchar(root)) file.path(root, rel),
    testthat::test_path("..", "fixtures", "api", name)
  )
  hit <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (!length(hit)) stop("Fixture file not found: ", name, call. = FALSE)
  hit[1L]
}

qa_m3d_comparable_store <- function(x) {
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  x <- x[, setdiff(names(x), c("timestamp", "latency_s")), drop = FALSE]
  keys <- paste(x$block, x$item_id, x$prompt_id, x$model_id, x$rep, sep = "|")
  x <- x[order(keys, method = "radix"), , drop = FALSE]
  rownames(x) <- NULL
  x
}

test_that("QA-M3d-E2E-1: multi-stage interruptions, CSV/SQLite store fidelity and backend_mock row-stream isolation hold end-to-end (seed = 20261106)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  set.seed(20261106L)

  truth <- c("001" = 0.8, "010" = -0.4)
  items <- data.frame(
    item_id = names(truth),
    text = paste("compound", names(truth)),
    stringsAsFactors = FALSE
  )
  d <- msa_design(
    items,
    prompts = c("01" = "Report the IC50 of {text}.", "10" = "IC50 of {text}, please."),
    models = c("01" = "01.00", "02" = "02.00"),
    reps = 2L,
    blocks = 2L,
    order = "random",
    seed = 20261106L
  )
  new_mock <- function() backend_mock(truth, p_fail = 0.25, seed = 20261106L)

  for (ext in c("csv", "sqlite")) {
    full_store <- tempfile("qa-m3d-full-", fileext = paste0(".", ext))
    step_store <- tempfile("qa-m3d-step-", fileext = paste0(".", ext))
    on.exit(unlink(c(full_store, step_store)), add = TRUE)

    ref_runs <- msa_run(d, new_mock(), parse = parse_number(), store = full_store, verbose = FALSE)

    # Stage 1: interrupt after 7 calls
    n1 <- 0L
    bk1 <- new_mock()
    int_bk1 <- function(prompt, model, row) {
      n1 <<- n1 + 1L
      if (n1 > 7L) {
        stop(structure(
          list(message = "qa simulated interrupt", call = NULL),
          class = c("qa_m3d_interrupt", "interrupt", "condition")
        ))
      }
      bk1(prompt, model, row)
    }
    cnd1 <- tryCatch(
      msa_run(d, int_bk1, parse = parse_number(), store = step_store, verbose = FALSE),
      interrupt = identity
    )
    expect_s3_class(cnd1, "interrupt")
    expect_identical(nrow(llmsa:::read_store(step_store)), 7L)

    # Stage 2: resume with a fresh mock, then abort after 11 additional calls (18 total)
    n2 <- 0L
    bk2 <- new_mock()
    int_bk2 <- function(prompt, model, row) {
      n2 <<- n2 + 1L
      if (n2 > 11L) {
        stop(structure(
          list(message = "qa simulated network abort", call = NULL),
          class = c("acmg_network_abort", "condition")
        ))
      }
      bk2(prompt, model, row)
    }
    cnd2 <- tryCatch(
      msa_run(d, int_bk2, parse = parse_number(), store = step_store, resume = TRUE, verbose = FALSE),
      acmg_network_abort = identity
    )
    expect_s3_class(cnd2, "acmg_network_abort")
    expect_identical(nrow(llmsa:::read_store(step_store)), 18L)

    # Stage 3: resume to completion with a fresh mock
    resumed_runs <- msa_run(d, new_mock(), parse = parse_number(), store = step_store, resume = TRUE, verbose = FALSE)
    expect_identical(qa_m3d_comparable_store(resumed_runs), qa_m3d_comparable_store(ref_runs))
    expect_identical(attr(resumed_runs, "design"), attr(ref_runs, "design"))

    if (ext == "csv") {
      raw_csv <- utils::read.csv(step_store, colClasses = "character", stringsAsFactors = FALSE)
      ref_csv <- utils::read.csv(full_store, colClasses = "character", stringsAsFactors = FALSE)
      expect_identical(qa_m3d_comparable_store(raw_csv), qa_m3d_comparable_store(ref_csv))
      expect_true(all(raw_csv$item_id %in% c("001", "010")))
      expect_true(all(raw_csv$prompt_id %in% c("01", "10")))
      expect_true(all(raw_csv$model_id %in% c("01", "02")))
      expect_true(all(raw_csv$model %in% c("01.00", "02.00")))
    } else {
      con_step <- DBI::dbConnect(RSQLite::SQLite(), step_store)
      con_full <- DBI::dbConnect(RSQLite::SQLite(), full_store)
      db_step <- DBI::dbReadTable(con_step, "runs")
      db_full <- DBI::dbReadTable(con_full, "runs")
      DBI::dbDisconnect(con_step)
      DBI::dbDisconnect(con_full)
      expect_identical(qa_m3d_comparable_store(db_step), qa_m3d_comparable_store(db_full))
    }

    # Stage 4: resuming a completed store invokes neither backend nor parser
    again <- msa_run(
      d,
      function(...) stop("completed calls must not be re-executed"),
      parse = function(...) stop("completed calls must not be re-parsed"),
      store = step_store,
      resume = TRUE,
      verbose = FALSE
    )
    expect_identical(qa_m3d_comparable_store(again), qa_m3d_comparable_store(resumed_runs))
  }
})

test_that("QA-M3d-E2E-2: backend_openai_compatible and backend_ellmer replay recordings, isolate chat turns, preserve metadata on empty content and match Rd diagnostics (seed = 20261106)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  for (pkg in c("httr2", "jsonlite", "ellmer", "DBI", "RSQLite")) skip_if_not_installed(pkg)
  set.seed(20261106L)

  ank94 <- qa_m3d_anchor("ANK-94")$value$files
  rec_map <- c(sol = "sol.json", llama = "llama.json", qwen = "qwen.json")
  recordings <- lapply(rec_map, function(fn) {
    path <- qa_m3d_fixture_path(fn)
    list(
      raw = readBin(path, "raw", file.info(path)$size),
      parsed = jsonlite::fromJSON(path, simplifyVector = FALSE),
      spec = ank94[[fn]]
    )
  })

  # 1. Replay of the 3 ANK-94 recordings across both backends and msa_run()
  chats <- lapply(recordings, function(r) {
    ellmer::chat_openai_compatible(
      base_url = sub("/chat/completions$", "", r$spec$request_url),
      model = r$spec$request_model,
      credentials = function() "qa-m3d-key",
      echo = "none"
    )
  })
  ell_bk <- backend_ellmer(chats)
  oai_bks <- lapply(recordings, function(r) {
    backend_openai_compatible(
      base_url = sub("/chat/completions$", "", r$spec$request_url),
      api_key = "qa-m3d-key"
    )
  })

  httr2::local_mocked_responses(function(req) {
    url <- httr2::req_get_url(req)
    raw <- httr2::req_dry_run(req, quiet = TRUE)$body
    txt <- if (is.raw(raw)) rawToChar(raw) else as.character(raw)
    body <- jsonlite::fromJSON(txt, simplifyVector = FALSE)
    msg_txt <- paste(unlist(lapply(body$messages, function(m) m$content)), collapse = " ")

    if (grepl("fail:", msg_txt, fixed = TRUE)) {
      hit <- regmatches(msg_txt, regexpr("fail:[a-z0-9_]+", msg_txt))
      kind <- sub("^fail:", "", hit)
      hdr <- list("Content-Type" = "application/json")
      return(switch(
        kind,
        http_500 = httr2::response(500L, url = url, method = "POST", headers = hdr,
                                   body = charToRaw('{"error":{"message":"Internal error"}}')),
        http_401 = httr2::response(401L, url = url, method = "POST", headers = hdr,
                                   body = charToRaw('{"error":{"message":"Unauthorized"}}')),
        timeout = stop(errorCondition("Operation timed out",
                                      class = c("curl_error_operation_timedout", "curl_error"))),
        empty_body = httr2::response(200L, url = url, method = "POST", headers = hdr, body = raw()),
        null_content = {
          obj <- recordings$llama$parsed
          obj$choices[[1L]]$message["content"] <- list(NULL)
          httr2::response(200L, url = url, method = "POST", headers = hdr,
                          body = charToRaw(as.character(jsonlite::toJSON(obj, auto_unbox = TRUE, null = "null", digits = NA))))
        },
        empty_content = {
          obj <- recordings$llama$parsed
          obj$choices[[1L]]$message["content"] <- list("")
          httr2::response(200L, url = url, method = "POST", headers = hdr,
                          body = charToRaw(as.character(jsonlite::toJSON(obj, auto_unbox = TRUE, null = "null", digits = NA))))
        },
        ws_content = {
          obj <- recordings$llama$parsed
          obj$choices[[1L]]$message["content"] <- list("   \t  ")
          httr2::response(200L, url = url, method = "POST", headers = hdr,
                          body = charToRaw(as.character(jsonlite::toJSON(obj, auto_unbox = TRUE, null = "null", digits = NA))))
        }
      ))
    }

    for (r in recordings) {
      if (identical(url, r$spec$request_url) && identical(body$model, r$spec$request_model)) {
        return(httr2::response(200L, url = url, method = "POST",
                               headers = list("Content-Type" = "application/json"),
                               body = r$raw))
      }
    }
    stop("Unexpected request in QA-M3d-E2E-2 mock", call. = FALSE)
  })

  for (id in names(recordings)) {
    rec <- recordings[[id]]
    for (res in list(
      oai_bks[[id]]("Classify PAH variant.", rec$spec$request_model, list(model_id = id)),
      ell_bk("Classify PAH variant.", rec$spec$request_model, list(model_id = id))
    )) {
      expect_identical(res$text, rec$spec$content)
      expect_identical(res$meta$model_snapshot, rec$spec$response_model)
      expect_identical(res$meta$provider, rec$parsed$provider)
      expect_identical(res$meta$usage, rec$parsed$usage)
      expect_identical(jsonlite::parse_json(llmsa:::meta_to_json(res$meta))$usage, rec$parsed$usage)
    }
    expect_length(chats[[id]]$get_turns(), 0L)
  }

  # 2. Failure & empty-response sequence including whitespace-only response
  kinds <- c("ok_first", "http_500", "http_401", "timeout", "empty_body",
             "null_content", "empty_content", "ws_content", "ok_last")
  prompts_txt <- ifelse(startsWith(kinds, "ok_"),
                        paste("PAH variant", kinds),
                        paste0("variant fail:", kinds))
  d_fail <- msa_design(
    data.frame(item_id = kinds, text = prompts_txt, stringsAsFactors = FALSE),
    prompts = c(concise = "Classify {text}."),
    models = c(llama = recordings$llama$spec$request_model),
    reps = 1L,
    blocks = 1L,
    order = "fixed"
  )
  parser_seen <- character()
  choice_parser <- parse_choice(c("Benign", "Likely benign", "Uncertain significance",
                                  "Likely pathogenic", "Pathogenic"))
  tracked_parser <- function(txt) {
    parser_seen <<- c(parser_seen, txt)
    choice_parser(txt)
  }

  for (bk in list(oai_bks$llama, backend_ellmer(list(llama = chats$llama)))) {
    parser_seen <- character()
    sq <- tempfile("qa-m3d-fail-", fileext = ".sqlite")
    on.exit(unlink(sq), add = TRUE)
    r_fail <- suppressMessages(msa_run(d_fail, bk, parse = tracked_parser, store = sq, verbose = FALSE))
    expect_identical(nrow(r_fail), 9L)
    expect_identical(r_fail$value[c(1L, 9L)], rep("Uncertain significance", 2L))
    expect_true(all(is.na(r_fail$error[c(1L, 8L, 9L)])))
    expect_true(all(!is.na(r_fail$error[2:7]) & nzchar(trimws(r_fail$error[2:7]))))
    expect_true(all(is.na(r_fail$value[2:8])))
    # Parser was called only on ok_first, ws_content, and ok_last (never on transport or empty-content errors)
    expect_length(parser_seen, 3L)
  }
})

test_that("QA-M3d-E2E-3: msa_report renders ANK-93 numbers, Westgard table, SHA-256 hash, seeds, model metadata and conventions in Markdown and HTML (seed = 20261106)", {
  old_opt <- options(testthat.progress.max_fails = Inf)
  on.exit(options(old_opt), add = TRUE)
  for (pkg in c("rmarkdown", "knitr", "digest", "jsonlite")) skip_if_not_installed(pkg)
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  set.seed(20261106L)

  ids <- sprintf("I%02d", 1:8)
  truth <- stats::setNames(seq(-1.4, 1.4, length.out = 8L), ids)
  items <- data.frame(
    item_id = ids,
    text = paste("sample", ids),
    reference = unname(truth) + 0.05,
    stringsAsFactors = FALSE
  )
  d <- msa_design(
    items,
    prompts = c(P1 = "IC50 of {text}?", P2 = "Value for {text}?"),
    models = c(sol = "model-sol", llama = "model-llama", qwen = "model-qwen"),
    reps = 2L,
    blocks = 2L,
    seed = 314159L
  )
  runs <- msa_run(
    d,
    backend_mock(truth, sd_prompt = 0.2, sd_model = 0.25, sd_rep = 0.15, seed = 20261106L),
    parse = parse_number(),
    verbose = FALSE
  )
  # Attach realistic multi-provider / quantization / unreadable metadata
  runs$meta[runs$model_id == "sol"] <- '{"model_snapshot":"mercury-coder-small","provider_order":["Inception"]}'
  llama_idx <- which(runs$model_id == "llama")
  runs$meta[llama_idx] <- '{"model_snapshot":"llama-3.3-70b","provider":"Chutes","quantizations":["fp16"]}'
  runs$meta[llama_idx[1L]] <- '{"model_snapshot":"llama-3.3-70b","provider":"AccTestHost","quantizations":["fp16","bf16"]}'
  qwen_idx <- which(runs$model_id == "qwen")
  runs$meta[qwen_idx] <- '{"model_snapshot":"qwen3-235b","provider":"Nebius","quantizations":["fp8"]}'
  runs$meta[qwen_idx[1L]] <- "legacy_unreadable_meta"

  fit <- suppressMessages(suppressWarnings(msa_fit(runs, type = "numeric")))
  grr <- msa_grr(fit)
  boot <- suppressMessages(suppressWarnings(msa_boot(fit, nsim = 3L, seed = 271828L)))
  bias <- suppressMessages(msa_bias(runs, "reference"))

  pb <- pb_design(
    list(fmt = c("plain", "json"), temp = c("0", "0.3"), units = c("nM", "uM"),
         typos = c("no", "yes"), ctx = c("short", "long"), role = c("user", "expert"),
         lang = c("en", "de")),
    n_runs = 8L,
    seed = 161803L
  )
  rob <- msa_robustness(pb, c(0.92, 0.85, 0.91, 0.72, 0.90, 0.74, 0.89, 0.73), transform = "logit")

  chart_vals <- c(0.5, 0.3, 2.4, 2.2, 0.4, 3.5, -1.2, 0.6, 1.2, 1.4, 1.3, 1.6,
                  0.8, 0.2, -0.3, -0.5, -0.2, -0.8, -0.4, -0.6, -0.1, -0.9, -0.3, -0.7)
  chart <- msa_control_chart(chart_vals, center = 0, sd = 1)

  expected_hash <- llmsa:::msa_report_hash(runs)

  out_md <- tempfile("qa-m3d-rep-", fileext = ".md")
  out_html <- tempfile("qa-m3d-rep-", fileext = ".html")
  on.exit(unlink(c(out_md, out_html)), add = TRUE)

  msa_report(
    grr, runs = runs, boot = boot, bias = bias, robustness = rob,
    control_chart = chart,
    output_file = out_md,
    output_format = rmarkdown::md_document(variant = "gfm", pandoc_args = "--wrap=none"),
    quiet = TRUE
  )
  msa_report(
    grr, runs = runs, boot = boot, bias = bias, robustness = rob,
    control_chart = chart,
    output_file = out_html,
    output_format = rmarkdown::html_document(),
    quiet = TRUE
  )

  for (f in c(out_md, out_html)) {
    txt <- paste(readLines(f, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    norm <- gsub("[[:space:]]+", " ", txt)
    expect_match(norm, expected_hash, fixed = TRUE)
    expect_false(grepl("(?i)\\bmd5\\b", norm, perl = TRUE))
    expect_match(norm, "Design seed: 314159", fixed = TRUE)
    expect_match(norm, "Bootstrap seed: 271828", fixed = TRUE)
    expect_match(norm, "Plackett-Burman seed: 161803", fixed = TRUE)
    expect_match(norm, "constant 1.41", fixed = TRUE)
    expect_match(norm, "thresholds 1 % and 9 % are a convention", fixed = TRUE)
    expect_match(norm, "excludes block interactions and three-way interactions", fixed = TRUE)
    expect_match(norm, "R_4s uses the range of two consecutive standardized values.", fixed = TRUE)
    expect_match(norm, "AccTestHost; Chutes", fixed = TRUE)
    expect_match(norm, "bf16; fp16", fixed = TRUE)
    expect_match(norm, "Model ID qwen: unreadable metadata in 1 row(s)", fixed = TRUE)
    expect_false(grepl("Inception", norm, fixed = TRUE))
  }
})
