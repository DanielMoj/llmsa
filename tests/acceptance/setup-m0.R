# Helpers for the M0 acceptance tests (docs/01-fachspezifikation.md §10); a
# setup file for the reason given in setup-acceptance.R.

# K-M0-1 ----------------------------------------------------------------------

# Dependencies named in the given DESCRIPTION fields as a data frame with the
# columns field, package, op and version (op and version are "" without a
# version requirement). Written independently of the deps gate
# (orchestrator/lib/r-deps.R).
acc_description_deps <- function(path, fields) {
  dcf <- read.dcf(path, fields = fields)
  rows <- list()
  for (field in fields) {
    value <- dcf[1L, field]
    if (is.na(value)) next
    for (entry in strsplit(value, ",", fixed = TRUE)[[1]]) {
      entry <- gsub("[[:space:]]+", "", entry)
      if (!nzchar(entry)) next
      m <- regmatches(entry, regexec(
        "^([[:alpha:]][[:alnum:].]*)(\\((>=|>|<=|<|==|!=)([^()]+)\\))?$", entry
      ))[[1]]
      if (!length(m)) stop("acceptance: unreadable dependency in ", path, ": ", entry, call. = FALSE)
      rows[[length(rows) + 1L]] <- data.frame(
        field = field, package = m[2], op = m[4], version = m[5], stringsAsFactors = FALSE
      )
    }
  }
  if (!length(rows)) {
    return(data.frame(field = character(), package = character(), op = character(),
                      version = character(), stringsAsFactors = FALSE))
  }
  do.call(rbind, rows)
}

# Installed version from the package's own DESCRIPTION, NA when not installed.
acc_installed_version <- function(package) {
  if (identical(package, "R")) return(as.character(getRversion()))
  path <- find.package(package, quiet = TRUE)
  if (!length(path)) return(NA_character_)
  unname(read.dcf(file.path(path[1], "DESCRIPTION"), fields = "Version")[1L, 1L])
}

acc_version_satisfies <- function(installed, op, required) {
  if (!nzchar(op)) return(TRUE)
  cmp <- utils::compareVersion(installed, required)
  switch(op,
    ">=" = cmp >= 0, ">" = cmp > 0, "<=" = cmp <= 0, "<" = cmp < 0,
    "==" = cmp == 0, "!=" = cmp != 0
  )
}

# K-M0-4 ----------------------------------------------------------------------

# Files under R/ in the working tree: path relative to the root, size, SHA-256.
acc_r_files_worktree <- function(root) {
  rel <- list.files(file.path(root, "R"), recursive = TRUE, all.files = TRUE, no.. = TRUE)
  full <- file.path(root, "R", rel)
  data.frame(
    path = file.path("R", rel), bytes = as.numeric(file.size(full)),
    sha256 = acc_sha256(full), stringsAsFactors = FALSE
  )
}

# Files under R/ in the git revision `ref`, read with git ls-tree and
# git cat-file into a temporary file, never into the working tree.
acc_r_files_at <- function(root, ref) {
  listing <- acc_git(root, "ls-tree", "-r", "--name-only", "--full-name", ref, "R")
  if (listing$status != 0L) {
    stop("acceptance: git ls-tree ", ref, " failed: ", paste(listing$stderr, collapse = " "),
         call. = FALSE)
  }
  blob <- tempfile("acc-blob-")
  on.exit(unlink(blob), add = TRUE)
  rows <- lapply(listing$stdout, function(path) {
    read <- acc_git(root, "cat-file", "blob", paste0(ref, ":", path), stdout_file = blob)
    if (read$status != 0L) {
      stop("acceptance: git cat-file ", ref, ":", path, " failed: ",
           paste(read$stderr, collapse = " "), call. = FALSE)
    }
    data.frame(path = path, bytes = as.numeric(file.size(blob)), sha256 = acc_sha256(blob),
               stringsAsFactors = FALSE)
  })
  if (!length(rows)) {
    return(data.frame(path = character(), bytes = numeric(), sha256 = character(),
                      stringsAsFactors = FALSE))
  }
  do.call(rbind, rows)
}

# K-M0-7 ----------------------------------------------------------------------
#
# Interface rule, docs/01-fachspezifikation.md §4. An API is
#   list(exports = <character>, functions = <named list of functions, NULL if absent>),
# a snapshot is
#   list(exports = <character>, functions = <named list of argument lists>),
# each argument list(name = <character>, default = <deparse() text or NULL>),
# as stored in reference/anchors/ANK-02.json.

acc_api_snapshot <- function() {
  value <- acc_anchor("ANK-02")$value
  list(exports = as.character(unlist(value$exports)), functions = value$functions)
}

# Default value as stored in ANK-02: deparse() text with lines joined by "\n";
# NULL for an argument without default.
acc_default_text <- function(value) {
  if (identical(value, quote(expr = ))) return(NULL)
  paste(deparse(value, width.cutoff = 500L), collapse = "\n")
}

acc_signature <- function(fn) {
  fm <- formals(fn)
  lapply(seq_along(fm), function(i) list(name = names(fm)[i], default = acc_default_text(fm[[i]])))
}

# The loaded package as an API: exports from the NAMESPACE file the namespace
# was loaded from (pkgload exports every object of a source package, so
# getNamespaceExports() would overstate them), functions from the namespace.
acc_package_api <- function(names) {
  ns <- asNamespace(acc_pkg)
  root <- acc_pkg_root()
  info <- parseNamespaceFile(basename(root), dirname(root), mustExist = TRUE)
  exports <- info$exports
  for (pattern in info$exportPatterns) {
    exports <- c(exports, ls(ns, pattern = pattern, all.names = TRUE))
  }
  list(
    exports = unique(exports),
    functions = lapply(stats::setNames(names, names), function(name) {
      get0(name, envir = ns, mode = "function", inherits = FALSE)
    })
  )
}

# Superset check: every snapshot function is exported and keeps every snapshot
# argument at the same position with the same default; further exports and
# arguments behind the snapshot arguments are allowed. One message per
# violation, character() if there is none.
acc_api_violations <- function(snapshot, api) {
  show <- function(default) if (is.null(default)) "no default" else default
  found <- character()
  for (f in union(snapshot$exports, names(snapshot$functions))) {
    if (!f %in% api$exports) found <- c(found, sprintf("%s: not exported", f))
    fn <- api$functions[[f]]
    if (!is.function(fn)) {
      found <- c(found, sprintf("%s: no function of this name", f))
      next
    }
    have <- acc_signature(fn)
    want <- snapshot$functions[[f]]
    for (i in seq_along(want)) {
      if (i > length(have)) {
        found <- c(found, sprintf("%s: argument %d `%s` is missing", f, i, want[[i]]$name))
      } else if (!identical(have[[i]]$name, want[[i]]$name)) {
        found <- c(found, sprintf("%s: argument %d is `%s`, the snapshot has `%s`",
                                  f, i, have[[i]]$name, want[[i]]$name))
      } else if (!identical(have[[i]]$default, want[[i]]$default)) {
        found <- c(found, sprintf("%s: default of `%s` is %s, the snapshot has %s",
                                  f, want[[i]]$name, show(have[[i]]$default), show(want[[i]]$default)))
      }
    }
  }
  found
}

# Independent mini-reference for acc_api_violations(): written as tokens
# "name<US>=default" (or "name<US>-" without default), the snapshot signature
# must be a prefix of the current one, and the snapshot exports a subset of the
# current exports. Here a missing default is recognised by its empty deparse().
acc_api_superset_reference <- function(snapshot, api) {
  if (!all(snapshot$exports %in% api$exports)) return(FALSE)
  for (f in names(snapshot$functions)) {
    fn <- api$functions[[f]]
    if (!(f %in% api$exports) || !is.function(fn)) return(FALSE)
    fm <- formals(fn)
    current <- character()
    for (i in seq_along(fm)) {
      text <- paste(deparse(fm[[i]], width.cutoff = 500L), collapse = "\n")
      current <- c(current, paste0(names(fm)[i], "\u001f", if (nzchar(text)) paste0("=", text) else "-"))
    }
    expected <- character()
    for (arg in snapshot$functions[[f]]) {
      expected <- c(expected, paste0(arg$name, "\u001f",
                                     if (is.null(arg$default)) "-" else paste0("=", arg$default)))
    }
    if (length(current) < length(expected)) return(FALSE)
    if (!identical(current[seq_along(expected)], expected)) return(FALSE)
  }
  TRUE
}

# Runs the gate orchestrator/gates.d/87-golden-adr.sh of the repository against
# a fake `git` whose `git diff --name-only` lists `changed`. The real git
# history is never read or changed. Returns the result of acc_run().
acc_golden_adr_gate <- function(changed) {
  root <- acc_repo_root()
  bin <- tempfile("acc-fake-git-")
  dir.create(bin)
  on.exit(unlink(bin, recursive = TRUE), add = TRUE)
  changed_file <- file.path(bin, "changed.txt")
  writeLines(changed, changed_file)
  git <- file.path(bin, "git")
  writeLines(c(
    "#!/bin/sh",
    "# fake git for the K-M0-7 acceptance test: answers `git -C <dir> diff --name-only <base>` only",
    "[ \"$1\" = \"-C\" ] && shift 2",
    "if [ \"$1\" = \"diff\" ] && [ \"$2\" = \"--name-only\" ]; then cat \"$ACC_FAKE_GIT_DIFF\"; exit 0; fi",
    "echo \"fake git: unexpected call: $*\" >&2",
    "exit 2"
  ), git)
  Sys.chmod(git, "755")
  acc_run("bash", shQuote(file.path(root, "orchestrator", "gates.d", "87-golden-adr.sh")), env = c(
    paste0("PATH=", shQuote(paste(bin, Sys.getenv("PATH"), sep = .Platform$path.sep))),
    paste0("ORCH=", shQuote(file.path(root, "orchestrator"))),
    paste0("REPO_ROOT=", shQuote(root)),
    "MILESTONE=M0",
    "ROUND=1",
    "BASE_SHA=0000000000000000000000000000000000000000",
    paste0("ACC_FAKE_GIT_DIFF=", shQuote(changed_file))
  ))
}
