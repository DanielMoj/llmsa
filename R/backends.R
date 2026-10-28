#' Backends: how a prompt becomes a response
#'
#' A backend is a function `function(prompt, model, row)` that sends `prompt`
#' to `model` and returns the raw text response (a length-one character
#' vector). `row` is the corresponding row of the design and can be ignored.
#' A backend may instead return a list with elements `text` and `meta`;
#' `meta` (a named list, e.g. token counts or the model snapshot id
#' reported by the API) is stored with the run. Any client library can be
#' wrapped this way; three backends are provided.
#'
#' * `backend_mock()` simulates an LLM for examples, tests and teaching.
#'   The default simulation draws a latent score from the item's `truth`
#'   plus prompt, model and replicate noise and writes a short sentence
#'   that contains the resulting label or number, so that the whole chain
#'   from prompt to parser can be exercised offline.
#' * `backend_ellmer()` wraps one or several `ellmer` chat objects (one per
#'   model id). Each call uses a fresh clone, so no conversation history
#'   leaks between calls.
#' * `backend_openai_compatible()` talks to any server that implements the
#'   OpenAI chat-completions API: OpenAI itself, Ollama (`base_url =
#'   "http://localhost:11434/v1"`), vLLM, LM Studio, Azure-style proxies.
#'
#' @param truth A named vector giving the latent true value of every
#'   `item_id` (numeric). For ordinal mocks this is the latent position; the
#'   label is obtained by cutting at `thresholds`.
#' @param levels Optional ordered labels. If given, the mock returns a label;
#'   otherwise it returns a number.
#' @param thresholds Cut points on the latent scale (length
#'   `length(levels) - 1`).
#' @param sd_prompt,sd_model,sd_rep Standard deviations of the prompt effect,
#'   the model effect and the replicate noise on the latent scale. Prompt and
#'   model effects are drawn once per prompt id / model id and kept fixed.
#' @param p_fail Probability that the mock returns an unparseable response,
#'   to exercise failure handling.
#' @param template A sprintf-style sentence with one `%s` for the value.
#' @param seed Seed for the mock's private random number stream.
#' @param chats For `backend_ellmer()`: an `ellmer` Chat object, or a named
#'   list of Chat objects keyed by model id.
#' @param base_url,api_key,temperature,system,max_tokens,timeout,... For
#'   `backend_openai_compatible()`: server URL (without the trailing
#'   `/chat/completions`), API key (may be empty for local servers),
#'   sampling temperature, optional system message, token limit, request
#'   timeout in seconds, and further fields merged into the JSON body.
#'   `temperature = NULL` omits the temperature field. A non-empty, non-NA
#'   `row$system` overrides `system` and precedes the user message. The reply's
#'   `id`, `model` (as `model_snapshot`), `usage`, `system_fingerprint` (including
#'   null) and optional `provider` are recorded in `meta`. A reasoning text in
#'   `message.reasoning` (as some OpenRouter endpoints return it) is recorded
#'   as `reasoning` when it is a non-empty string; otherwise the key is absent.
#'   `reasoning_details` is not stored. `finish_reason` and
#'   `native_finish_reason` of the first choice are recorded under these names
#'   when they are non-empty strings, so that a reply cut at the token limit can
#'   be told apart from an unreadable one. Requested routing
#'   is recorded as `provider_order`, `quantizations` and `allow_fallbacks`.
#'   Requested `seed`, `temperature` and `reasoning_effort`, when present, are
#'   retained as metadata for comparison with the study plan, and the request
#'   timeout as `timeout_s`.
#'   Only `message.content` is parsed; credentials and headers are not stored.
#'
#' @return A backend function.
#' @name backends
#' @examples
#' truth <- c(v1 = 1.2, v2 = -0.4)
#' bk <- backend_mock(truth, levels = c("Benign", "VUS", "Pathogenic"),
#'                    thresholds = c(-0.5, 0.5), seed = 1)
#' bk("Classify v1", "model-a", list(item_id = "v1", prompt_id = "P1", model_id = "model-a"))
NULL

#' @rdname backends
#' @export
backend_mock <- function(truth, levels = NULL, thresholds = NULL,
                         sd_prompt = 0.2, sd_model = 0.2, sd_rep = 0.3,
                         p_fail = 0, template = "The result is: %s.",
                         seed = NULL) {
  if (is.null(names(truth))) stop("`truth` must be a named vector keyed by item_id.", call. = FALSE)
  if (!is.null(levels) && length(thresholds) != length(levels) - 1) {
    stop("`thresholds` must have length `length(levels) - 1`.", call. = FALSE)
  }
  rng <- new.env()
  rng$prompt_eff <- numeric(0)
  rng$model_eff <- numeric(0)
  rng$seed <- seed %||% sample.int(.Machine$integer.max, 1)
  rng$counter <- 0L

  draw <- function(key, sd, slot) {
    eff <- get(slot, envir = rng)
    if (!key %in% names(eff)) {
      # one effect per key, derived deterministically from the seed and the key
      s <- (sum(utf8ToInt(key)) * 7919L + rng$seed) %% .Machine$integer.max
      old <- .Random.seed_get()
      set.seed(s); val <- stats::rnorm(1, 0, sd); .Random.seed_set(old)
      eff[key] <- val
      assign(slot, eff, envir = rng)
    }
    unname(eff[key])
  }

  function(prompt, model, row = NULL) {
    id <- row$item_id %||% NA_character_
    if (is.na(id) || !id %in% names(truth)) {
      stop(sprintf("backend_mock: unknown item_id '%s' (not in `truth`).", id), call. = FALSE)
    }
    pid <- as.character(row$prompt_id %||% "P")
    mid <- as.character(row$model_id %||% model)
    rng$counter <- rng$counter + 1L
    old <- .Random.seed_get()
    set.seed(rng$seed + rng$counter)
    on.exit(.Random.seed_set(old), add = TRUE)
    if (p_fail > 0 && stats::runif(1) < p_fail) {
      return(list(text = "I'm sorry, I cannot help with that request.",
                  meta = list(mock = TRUE)))
    }
    eta <- unname(truth[id]) + draw(pid, sd_prompt, "prompt_eff") +
      draw(mid, sd_model, "model_eff") + stats::rnorm(1, 0, sd_rep)
    val <- if (is.null(levels)) formatC(eta, digits = 3, format = "f") else
      levels[findInterval(eta, thresholds) + 1]
    list(text = sprintf(template, val), meta = list(mock = TRUE, latent = eta))
  }
}

.Random.seed_get <- function() {
  if (exists(".Random.seed", envir = globalenv(), inherits = FALSE))
    get(".Random.seed", envir = globalenv(), inherits = FALSE) else NULL
}
.Random.seed_set <- function(old) {
  if (is.null(old)) {
    if (exists(".Random.seed", envir = globalenv(), inherits = FALSE))
      rm(".Random.seed", envir = globalenv())
  } else assign(".Random.seed", old, envir = globalenv())
  invisible(NULL)
}

#' @rdname backends
#' @export
backend_ellmer <- function(chats) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("Package `ellmer` is required for backend_ellmer().", call. = FALSE)
  }
  if (!is.list(chats) || inherits(chats, "Chat")) chats <- list(default = chats)
  function(prompt, model, row = NULL) {
    key <- as.character(row$model_id %||% model)
    chat <- chats[[key]] %||% chats[[model]] %||% if (length(chats) == 1) chats[[1]] else NULL
    if (is.null(chat)) stop(sprintf("backend_ellmer: no chat object for model id '%s'.", key), call. = FALSE)
    ch <- chat$clone()
    txt <- ch$chat(prompt, echo = "none")
    list(text = as.character(txt), meta = list(client = "ellmer"))
  }
}

#' @rdname backends
#' @export
backend_openai_compatible <- function(base_url = "https://api.openai.com/v1",
                                      api_key = Sys.getenv("OPENAI_API_KEY"),
                                      temperature = 0, system = NULL,
                                      max_tokens = NULL, timeout = 120, ...) {
  if (!requireNamespace("httr2", quietly = TRUE)) {
    stop("Package `httr2` is required for backend_openai_compatible().", call. = FALSE)
  }
  extra <- list(...)
  base_url <- sub("/+$", "", base_url)
  function(prompt, model, row = NULL) {
    messages <- list()
    sys <- system
    if (length(row$system) == 1L && !is.na(row$system) && nzchar(row$system)) sys <- row$system
    if (!is.null(sys)) messages[[length(messages) + 1]] <- list(role = "system", content = sys)
    messages[[length(messages) + 1]] <- list(role = "user", content = prompt)
    body <- list(model = model, messages = messages)
    if (!is.null(temperature)) body$temperature <- temperature
    body <- c(body, extra)
    if (!is.null(max_tokens)) body$max_tokens <- max_tokens
    req <- httr2::request(paste0(base_url, "/chat/completions"))
    req <- httr2::req_headers(req, "Content-Type" = "application/json")
    if (nzchar(api_key)) req <- httr2::req_headers(req, Authorization = paste("Bearer", api_key))
    req <- httr2::req_body_json(req, body)
    req <- httr2::req_timeout(req, timeout)
    req <- httr2::req_retry(req, max_tries = 3)
    resp <- httr2::req_perform(req)
    js <- httr2::resp_body_json(resp)
    txt <- js$choices[[1]]$message$content
    meta <- list(model_snapshot = js$model, id = js$id, usage = js$usage,
                 system_fingerprint = js$system_fingerprint)
    if ("provider" %in% names(js)) meta["provider"] <- list(js$provider)
    # Exact match: `$` would also accept `reasoning_details`, which is not stored.
    reasoning <- js$choices[[1]]$message[["reasoning"]]
    if (is.character(reasoning) && length(reasoning) == 1L && !is.na(reasoning) && nzchar(reasoning)) {
      meta$reasoning <- reasoning
    }
    # Exact match, as for reasoning; only non-empty strings are recorded.
    for (field in c("finish_reason", "native_finish_reason")) {
      value <- js[["choices"]][[1]][[field]]
      if (is.character(value) && length(value) == 1L && !is.na(value) && nzchar(value)) meta[[field]] <- value
    }
    if (!is.null(body$provider)) {
      meta$provider_order <- body$provider$order
      meta$quantizations <- body$provider$quantizations
      meta$allow_fallbacks <- body$provider$allow_fallbacks
    }
    for (field in intersect(c("seed", "temperature", "reasoning_effort"), names(body))) {
      meta[field] <- body[field]
    }
    meta$timeout_s <- timeout
    list(text = as.character(txt %||% NA_character_), meta = meta)
  }
}
