# ADR-015: the AP1 runner repeats a call that failed before its request was
# sent instead of storing it (E1), keeps every other failure as a backend error
# row (E2), marks calls repeated after pauses (E3) and logs its progress (E4).
# acmg_wait() is replaced, so no test waits.

# The condition httr2 1.3.0 signals for a failed transfer: its own
# capture_curl_error() around the condition curl 8.1.0 raises for a libcurl
# error number. Error strings and buffers are those of libcurl 8.18.
ap1_test_curl_failure <- function(errnum, strerror, errbuf, host = "openrouter.ai") {
  httr2:::capture_curl_error(curl:::raise_libcurl_error(errnum, strerror, errbuf, host))
}

ap1_test_forms <- list(
  list(name = "name resolution", e1 = TRUE, errnum = 6L, class = "curl_error_couldnt_resolve_host",
       strerror = "Could not resolve hostname", errbuf = "Could not resolve host: openrouter.ai"),
  list(name = "proxy name resolution", e1 = TRUE, errnum = 5L, class = "curl_error_couldnt_resolve_proxy",
       strerror = "Could not resolve proxy name", errbuf = "Could not resolve proxy: proxy.invalid"),
  list(name = "connection", e1 = TRUE, errnum = 7L, class = "curl_error_couldnt_connect",
       strerror = "Could not connect to server",
       errbuf = "Failed to connect to openrouter.ai port 443 after 3 ms: Could not connect to server"),
  list(name = "TLS handshake (TLS connect error)", e1 = TRUE, errnum = 35L, class = "curl_error_ssl_connect_error",
       strerror = "SSL connect error", errbuf = "TLS connect error: error:0A000126:SSL routines::unexpected eof while reading"),
  list(name = "TLS handshake (OpenSSL SSL_connect)", e1 = TRUE, errnum = 35L, class = "curl_error_ssl_connect_error",
       strerror = "SSL connect error", errbuf = "OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to openrouter.ai:443 "),
  list(name = "TLS handshake (certificate)", e1 = TRUE, errnum = 60L, class = "curl_error_peer_failed_verification",
       strerror = "SSL peer certificate or SSH remote key was not OK",
       errbuf = "SSL certificate problem: unable to get local issuer certificate"),
  list(name = "timeout while resolving", e1 = TRUE, errnum = 28L, class = "curl_error_operation_timedout",
       strerror = "Timeout was reached", errbuf = "Resolving timed out after 10002 milliseconds"),
  list(name = "timeout while connecting", e1 = TRUE, errnum = 28L, class = "curl_error_operation_timedout",
       strerror = "Timeout was reached", errbuf = "Connection timed out after 10001 milliseconds"),
  list(name = "timeout while connecting (connection filter)", e1 = TRUE, errnum = 28L, class = "curl_error_operation_timedout",
       strerror = "Timeout was reached", errbuf = "Connection timeout after 10001 ms"),
  list(name = "timeout during the transfer", e1 = FALSE, errnum = 28L, class = "curl_error_operation_timedout",
       strerror = "Timeout was reached", errbuf = "Operation timed out after 120002 milliseconds with 334 bytes received"),
  list(name = "timeout during the transfer with a known size", e1 = FALSE, errnum = 28L, class = "curl_error_operation_timedout",
       strerror = "Timeout was reached", errbuf = "Operation timed out after 120002 milliseconds with 334 out of 1000 bytes received"),
  list(name = "timeout without a phase", e1 = FALSE, errnum = 28L, class = "curl_error_operation_timedout",
       strerror = "Timeout was reached", errbuf = "Operation timed out"),
  list(name = "send failure", e1 = FALSE, errnum = 55L, class = "curl_error_send_error",
       strerror = "Failed sending data to the peer", errbuf = "Send failure: Broken pipe"),
  list(name = "receive failure", e1 = FALSE, errnum = 56L, class = "curl_error_recv_error",
       strerror = "Failure when receiving data from the peer", errbuf = "Recv failure: Connection reset by peer"),
  list(name = "empty reply", e1 = FALSE, errnum = 52L, class = "curl_error_got_nothing",
       strerror = "Server returned nothing (no headers, no data)", errbuf = "Empty reply from server")
)

for (form in ap1_test_forms) {
  test_that(sprintf("%s: %s is %s", if (form$e1) "E1" else "E2", form$name,
                    if (form$e1) "a network failure before sending" else "a backend error"), {
    for (pkg in c("httr2", "curl")) skip_if_not_installed(pkg)
    cnd <- ap1_test_curl_failure(form$errnum, form$strerror, form$errbuf)
    expect_identical(class(cnd), c("httr2_failure", "httr2_error", "rlang_error", "error", "condition"))
    expect_identical(class(cnd$parent), c(form$class, "curl_error", "error", "condition"))
    expect_identical(conditionMessage(cnd$parent), sprintf("%s [openrouter.ai]:\n%s", form$strerror, form$errbuf))
    expect_identical(acmg_network_failure(cnd), form$e1)
    expect_identical(acmg_network_failure(cnd$parent), form$e1)
    # The same condition through backend_openai_compatible() and httr2::req_perform().
    httr2::local_mocked_responses(function(req) cnd)
    got <- tryCatch(backend_openai_compatible(api_key = "", temperature = NULL)("Synthetic prompt", "synthetic-model"),
                    error = function(e) e)
    expect_s3_class(got, "httr2_failure")
    expect_s3_class(got$parent, form$class)
    expect_identical(acmg_network_failure(got), form$e1)
    expect_identical(acmg_network_cause(got), sprintf("%s [openrouter.ai]: %s", form$strerror, trimws(form$errbuf)))
  })
}

test_that("E2: HTTP status errors, unreadable bodies and other errors are backend errors", {
  skip_if_not_installed("httr2")
  backend <- backend_openai_compatible(api_key = "", temperature = NULL)
  for (status in c(400L, 429L, 500L, 503L)) {
    httr2::local_mocked_responses(function(req) httr2::response(status_code = status))
    got <- tryCatch(backend("Synthetic prompt", "synthetic-model"), error = function(e) e)
    expect_s3_class(got, paste0("httr2_http_", status))
    expect_false(acmg_network_failure(got), info = status)
  }
  httr2::local_mocked_responses(function(req) {
    httr2::response(status_code = 200L, headers = list(`Content-Type` = "application/json"), body = charToRaw("not json"))
  })
  got <- tryCatch(backend("Synthetic prompt", "synthetic-model"), error = function(e) e)
  expect_s3_class(got, "error")
  expect_false(acmg_network_failure(got))
  expect_false(acmg_network_failure(simpleError("Could not resolve host: openrouter.ai")))
  expect_false(acmg_network_failure("Could not resolve host: openrouter.ai"))
})

test_that("missing or invalid network fields fail plan validation", {
  p <- ap1_test_plan()
  bad <- p; bad$network <- NULL
  expect_error(acmg_validate_plan(bad), "^Invalid AP1 plan field: network$")
  bad <- p; bad$network <- "30"
  expect_error(acmg_validate_plan(bad), "^Invalid AP1 plan field: network$")
  for (nm in c("first_pause_s", "max_pause_s", "total_pause_s")) {
    bad <- p; bad$network[[nm]] <- NULL
    expect_error(acmg_validate_plan(bad), paste0("^Invalid AP1 plan field: network.", nm, "$"), info = nm)
    for (value in list(0, -30, NA, NA_real_, Inf, -Inf, "30", TRUE, c(30, 60), list(30))) {
      bad <- p; bad$network[nm] <- list(value)
      expect_error(acmg_validate_plan(bad), paste0("^Invalid AP1 plan field: network.", nm, "$"), info = paste(nm, format(value)))
    }
  }
  copy <- tempfile(fileext = ".yaml")
  on.exit(unlink(copy), add = TRUE)
  bad <- p; bad$network$total_pause_s <- NULL
  yaml::write_yaml(bad, copy)
  expect_error(acmg_plan(copy), "network.total_pause_s", fixed = TRUE)
  good <- p; good$network$first_pause_s <- 0.5
  expect_identical(acmg_validate_plan(good), good)
})

# A synthetic API reply for each request, as in test-acmg-api.R; requests
# listed in `failures` (by number) get that condition instead.
ap1_test_network_mock <- function(plan, failures, sink) {
  sink$requests <- list()
  models <- acmg_models(plan)
  function(req) {
    body <- ap1_test_request_body(req)
    sink$requests[[length(sink$requests) + 1L]] <- body
    i <- length(sink$requests)
    if (i <= length(failures) && !is.null(failures[[i]])) return(failures[[i]])
    key <- names(models)[vapply(models, function(m) identical(m$id, body$model), logical(1))]
    reply <- jsonlite::fromJSON(ap1_test_meta(key, plan), simplifyVector = FALSE)
    reply$model <- reply$model_snapshot; reply$model_snapshot <- NULL
    json <- startsWith(body$messages[[1]]$content, "Return a JSON object")
    reply$choices <- list(list(message = list(content = if (json) '{"classification":"Benign"}' else "Benign")))
    ap1_test_response(reply)
  }
}

ap1_test_dns_failure <- function() {
  ap1_test_curl_failure(6L, "Could not resolve hostname", "Could not resolve host: openrouter.ai")
}

ap1_test_transfer_timeout <- function() {
  ap1_test_curl_failure(28L, "Timeout was reached", "Operation timed out after 1800002 milliseconds with 334 bytes received")
}

test_that("two network failures, then success: one row with network_retries 2 and network_wait_s 90, two pause lines", {
  for (pkg in c("httr2", "curl", "DBI", "RSQLite")) skip_if_not_installed(pkg)
  p <- ap1_test_plan(); ap1_test_keys()
  on.exit(Sys.unsetenv(c("OPENAI_API_KEY", "OPENROUTER_API_KEY")), add = TRUE)
  waits <- numeric()
  local_mocked_bindings(acmg_wait = function(seconds) waits <<- c(waits, seconds))
  sink <- new.env(parent = emptyenv())
  httr2::local_mocked_responses(ap1_test_network_mock(p, list(ap1_test_dns_failure(), ap1_test_dns_failure()), sink))
  store <- tempfile(fileext = ".sqlite")
  on.exit(unlink(store), add = TRUE)
  log <- capture_messages(capture.output(acmg_run_cli(c("--part", "pilot", "--backend", "api", "--store", store))))
  expect_equal(waits, c(30, 60))
  rows <- acmg_store_read(store, "api")
  expect_identical(nrow(rows), as.integer(length(p$models) * p$pilot$calls_per_model))
  expect_false(anyDuplicated(run_key(rows)) > 0L)
  expect_true(all(is.na(rows$error)))
  expect_identical(length(sink$requests), nrow(rows) + 2L)
  expect_identical(sink$requests[[3]], sink$requests[[1]])
  first <- jsonlite::fromJSON(rows$meta[rows$position == 1L], simplifyVector = FALSE)
  expect_equal(first$network_retries, 2)
  expect_equal(first$network_wait_s, 90)
  expect_false(any(grepl("network_", rows$meta[rows$position != 1L], fixed = TRUE)))
  pauses <- grep("network pause [0-9]", log, value = TRUE)
  expect_length(pauses, 2L)
  expect_match(pauses[1], "pilot block 1: network pause 30 s before retry 1 of ", fixed = TRUE)
  expect_match(pauses[2], "pilot block 1: network pause 60 s before retry 2 of ", fixed = TRUE)
  expect_true(all(grepl("Could not resolve hostname [openrouter.ai]: Could not resolve host: openrouter.ai", pauses, fixed = TRUE)))
  expect_true(all(grepl("^\\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [^]]*\\] AP1 pilot block 1: ", log)))
  expect_match(log[1], sprintf("AP1 pilot block 1: start, %d open\n", nrow(rows)), fixed = TRUE)
  expect_true(acmg_pilot(rows, p)$passed)
})

test_that("network failures up to the limit stop the run without a row; resume starts with exactly that call", {
  for (pkg in c("httr2", "curl", "DBI", "RSQLite")) skip_if_not_installed(pkg)
  p <- ap1_test_plan(); ap1_test_keys()
  on.exit(Sys.unsetenv(c("OPENAI_API_KEY", "OPENROUTER_API_KEY")), add = TRUE)
  net <- p$network
  expect_equal(c(net$first_pause_s, net$max_pause_s, net$total_pause_s), c(30, 600, 43200))
  waits <- numeric()
  local_mocked_bindings(acmg_wait = function(seconds) waits <<- c(waits, seconds))
  sink <- new.env(parent = emptyenv())
  # The first five calls succeed; every later request fails before sending.
  httr2::local_mocked_responses(ap1_test_network_mock(p, c(rep(list(NULL), 5L), rep(list(ap1_test_dns_failure()), 100L)), sink))
  store <- tempfile(fileext = ".sqlite")
  on.exit(unlink(store), add = TRUE)
  args <- c("--part", "pilot", "--backend", "api", "--store", store)
  log <- capture_messages(error <- tryCatch(capture.output(acmg_run_cli(args)), error = function(e) e))
  expect_s3_class(error, "error")
  # 30 s doubling to 600 s; the last pause is shortened to the rest of 43200 s.
  expect_equal(waits, c(30, 60, 120, 240, 480, rep(600, 70), 270))
  expect_identical(length(sink$requests), 5L + length(waits) + 1L)
  design <- acmg_design(acmg_items(pilot = TRUE), p, "pilot")
  aborted <- design[design$position == 6L, , drop = FALSE]
  expect_match(conditionMessage(error), sprintf(
    "^AP1 network unavailable: %s %s %s rep %s \\(block 1, position 6\\) still failed before sending after 76 network retries and 43200 s of pauses \\(limit 43200 s\\): Could not resolve hostname \\[openrouter\\.ai\\]: Could not resolve host: openrouter\\.ai\\. No row was stored for this call; continue with the same command\\.$",
    aborted$model_id, aborted$prompt_id, aborted$item_id, aborted$rep))
  expect_length(grep("network pause [0-9]", log), length(waits))
  expect_match(log[length(log)], "pilot block 1: network limit of 43200 s reached for ", fixed = TRUE)
  before <- read_store(store)
  expect_identical(sort(before$position), 1:5)
  expect_false(run_key(aborted) %in% run_key(before))
  # The same command continues with exactly the aborted call.
  resumed <- new.env(parent = emptyenv())
  httr2::local_mocked_responses(ap1_test_network_mock(p, list(), resumed))
  log <- capture_messages(capture.output(acmg_run_cli(args)))
  expect_match(log[1], sprintf("AP1 pilot block 1: start, %d open\n", nrow(design) - 5L), fixed = TRUE)
  after <- read_store(store)
  expect_identical(nrow(after), nrow(design))
  expect_identical(after$position[6], 6L)
  expect_identical(run_key(after[6, , drop = FALSE]), run_key(aborted))
  expect_identical(resumed$requests[[1]]$model, aborted$model)
  expect_identical(resumed$requests[[1]]$messages[[1]]$content, aborted$prompt)
  head <- after[1:5, , drop = FALSE]
  rownames(head) <- NULL
  expect_identical(head, before)
})

test_that("an E2 failure is stored at once without a pause, and its message is unchanged", {
  for (pkg in c("httr2", "curl", "DBI", "RSQLite")) skip_if_not_installed(pkg)
  p <- ap1_test_plan(); ap1_test_keys()
  on.exit(Sys.unsetenv(c("OPENAI_API_KEY", "OPENROUTER_API_KEY")), add = TRUE)
  waits <- numeric()
  local_mocked_bindings(acmg_wait = function(seconds) waits <<- c(waits, seconds))
  timeout <- ap1_test_transfer_timeout()
  sink <- new.env(parent = emptyenv())
  httr2::local_mocked_responses(ap1_test_network_mock(p, list(timeout), sink))
  store <- tempfile(fileext = ".sqlite")
  on.exit(unlink(store), add = TRUE)
  log <- capture_messages(capture.output(acmg_run_cli(c("--part", "pilot", "--backend", "api", "--store", store))))
  expect_length(waits, 0L)
  expect_false(any(grepl("network pause", log, fixed = TRUE)))
  rows <- read_store(store)
  expect_identical(nrow(rows), as.integer(length(p$models) * p$pilot$calls_per_model))
  expect_identical(length(sink$requests), nrow(rows))
  failed <- rows[!is.na(rows$error), , drop = FALSE]
  expect_identical(failed$position, 1L)
  expect_identical(failed$error, conditionMessage(timeout))
  expect_true(is.na(failed$meta))
})

test_that("a network failure followed by an E2 failure is stored with the retry note", {
  for (pkg in c("httr2", "curl", "DBI", "RSQLite")) skip_if_not_installed(pkg)
  p <- ap1_test_plan(); ap1_test_keys()
  on.exit(Sys.unsetenv(c("OPENAI_API_KEY", "OPENROUTER_API_KEY")), add = TRUE)
  waits <- numeric()
  local_mocked_bindings(acmg_wait = function(seconds) waits <<- c(waits, seconds))
  timeout <- ap1_test_transfer_timeout()
  sink <- new.env(parent = emptyenv())
  httr2::local_mocked_responses(ap1_test_network_mock(p, list(ap1_test_dns_failure(), timeout), sink))
  store <- tempfile(fileext = ".sqlite")
  on.exit(unlink(store), add = TRUE)
  log <- capture_messages(capture.output(acmg_run_cli(c("--part", "pilot", "--backend", "api", "--store", store))))
  expect_equal(waits, 30)
  rows <- read_store(store)
  failed <- rows[!is.na(rows$error), , drop = FALSE]
  expect_identical(failed$position, 1L)
  expect_identical(failed$error, paste0(conditionMessage(timeout), " [after 1 network retries, 30 s]"))
  expect_identical(length(grep("network pause [0-9]", log)), 1L)
  expect_identical(length(grep("backend error (", log, fixed = TRUE)), 1L)
})

test_that("the progress log shows open calls, every 100 calls and each backend error, never a reply", {
  p <- ap1_test_plan()
  items <- data.frame(item_id = sprintf("synthetic-%03d", 1:70), text = "Synthetic prompt", stringsAsFactors = FALSE)
  design <- msa_design(items, prompts = c(concise = "{text}"), models = c(sol = "s", llama = "l", qwen = "q"),
                       reps = 1, blocks = 1, order = "fixed")
  expect_identical(nrow(design), 210L)
  reply <- "Synthetic reply text that must stay out of the log"
  backend <- function(prompt, model, row) {
    if (row$position == 150L) stop("HTTP 503 Service Unavailable.")
    list(text = reply, meta = list(id = "synthetic-id"))
  }
  watch <- acmg_watch(backend, p, "main")
  log <- capture_messages({
    watch$start(1L, nrow(design))
    runs <- msa_run(design, watch$backend, verbose = FALSE)
  })
  failed <- design$model_id[design$position == 150L]
  errors <- function(n) paste(names(acmg_models(p)), ifelse(names(acmg_models(p)) == failed, n, 0L), sep = " ", collapse = ", ")
  lines <- sub("^\\[[^]]*\\] AP1 ", "", sub("\n$", "", log))
  expect_identical(lines, c(
    "main block 1: start, 210 open",
    paste0("main block 1: 100 done, 110 open; backend errors since start: ", errors(0L)),
    paste0("main block 1: backend error (", failed, "); 150 done, 60 open; backend errors since start: ", errors(1L)),
    paste0("main block 1: 200 done, 10 open; backend errors since start: ", errors(1L))))
  expect_false(any(grepl(reply, log, fixed = TRUE)))
  expect_false(any(grepl("HTTP 503", log, fixed = TRUE)))
  expect_identical(runs$error[runs$position == 150L], "HTTP 503 Service Unavailable.")
  expect_false(any(grepl("network_", runs$meta, fixed = TRUE)))
  # Backend errors are counted since the start of the process, across blocks.
  row <- as.list(design[design$position == 150L, , drop = FALSE])
  row$block <- 2L
  log <- capture_messages({
    watch$start(2L, 1L)
    expect_error(watch$backend(row$prompt, row$model, row), "HTTP 503 Service Unavailable.", fixed = TRUE)
  })
  lines <- sub("^\\[[^]]*\\] AP1 ", "", sub("\n$", "", log))
  expect_identical(lines, c("main block 2: start, 1 open",
                            paste0("main block 2: backend error (", failed, "); 1 done, 0 open; backend errors since start: ", errors(2L))))
})
