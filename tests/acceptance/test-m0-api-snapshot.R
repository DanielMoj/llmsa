# K-M0-7: the API snapshot ANK-02 and the interface rule of
# docs/01-fachspezifikation.md §4. Every check runs through acc_api_violations()
# and, as an independently written mini-reference, acc_api_superset_reference();
# both must agree on every case.

# A constructed snapshot with the default texts written out by hand.
toy_snapshot <- list(
  exports = c("f", "g"),
  functions = list(
    f = list(
      list(name = "x", default = NULL),
      list(name = "y", default = "1"),
      list(name = "...", default = NULL)
    ),
    g = list(list(name = "a", default = "c(\"u\", \"v\")"))
  )
)

toy_api <- function(f = function(x, y = 1, ...) NULL,
                    g = function(a = c("u", "v")) NULL,
                    exports = c("f", "g"),
                    more = list()) {
  list(exports = exports, functions = c(list(f = f, g = g), more))
}

test_that("K-M0-7: ANK-02 holds the export list and the formals() of the 22 functions of v0.1.0", {
  snapshot <- acc_api_snapshot()
  expect_length(snapshot$exports, 22L)
  expect_setequal(names(snapshot$functions), snapshot$exports)
  for (f in names(snapshot$functions)) {
    for (arg in snapshot$functions[[f]]) {
      expect_true(is.character(arg$name) && length(arg$name) == 1L && nzchar(arg$name), info = f)
      expect_true(is.null(arg$default) || (is.character(arg$default) && length(arg$default) == 1L),
                  info = f)
    }
  }
})

test_that("K-M0-7: the loaded package is a superset of the API snapshot (ankerRef: ANK-02)", {
  snapshot <- acc_api_snapshot()
  api <- acc_package_api(names(snapshot$functions))
  expect_identical(acc_api_violations(snapshot, api), character())
  expect_true(acc_api_superset_reference(snapshot, api))
})

test_that("K-M0-7: further exports and arguments behind the snapshot arguments pass", {
  accepted <- list(
    unchanged = toy_api(),
    further_export = toy_api(exports = c("f", "g", "h"), more = list(h = function(z) z)),
    trailing_arguments = toy_api(
      f = function(x, y = 1, ..., z = TRUE) NULL,
      g = function(a = c("u", "v"), b = NULL) NULL
    )
  )
  for (case in names(accepted)) {
    expect_identical(acc_api_violations(toy_snapshot, accepted[[case]]), character(), info = case)
    expect_true(acc_api_superset_reference(toy_snapshot, accepted[[case]]), info = case)
  }
})

test_that("K-M0-7: a missing argument, another default or a reordered argument list fail", {
  rejected <- list(
    missing_argument = toy_api(f = function(x, ...) NULL),
    other_default = toy_api(f = function(x, y = 2, ...) NULL),
    reordered = toy_api(f = function(y = 1, x, ...) NULL),
    argument_inserted_before = toy_api(f = function(x, w = 0, y = 1, ...) NULL),
    renamed_argument = toy_api(f = function(x, yy = 1, ...) NULL),
    default_added = toy_api(f = function(x = 0, y = 1, ...) NULL),
    default_removed = toy_api(g = function(a) NULL),
    not_exported = toy_api(exports = "f"),
    no_function = toy_api(g = NULL)
  )
  for (case in names(rejected)) {
    expect_true(length(acc_api_violations(toy_snapshot, rejected[[case]])) > 0L, info = case)
    expect_false(acc_api_superset_reference(toy_snapshot, rejected[[case]]), info = case)
  }
})

test_that("K-M0-7: altered copies of the loaded API fail, an extended copy passes", {
  snapshot <- acc_api_snapshot()
  api <- acc_package_api(names(snapshot$functions))
  n_args <- vapply(snapshot$functions, length, integer(1))
  first_default <- vapply(snapshot$functions, function(args) {
    hit <- which(!vapply(args, function(arg) is.null(arg$default), logical(1)))
    if (length(hit)) hit[1] else NA_integer_
  }, integer(1))
  two_args <- names(snapshot$functions)[n_args >= 2L][1]
  defaulted <- names(snapshot$functions)[!is.na(first_default)][1]
  expect_false(is.na(two_args))
  expect_false(is.na(defaulted))

  alter <- function(name, edit) {
    copy <- api
    fn <- copy$functions[[name]]
    formals(fn) <- edit(formals(fn))
    copy$functions[[name]] <- fn
    copy
  }
  rejected <- list(
    missing_argument = alter(two_args, function(fm) fm[-1L]),
    other_default = alter(defaulted, function(fm) {
      fm[[first_default[[defaulted]]]] <- as.name("acc_other_default")
      fm
    }),
    reordered = alter(two_args, function(fm) fm[c(2L, 1L, seq_along(fm)[-(1:2)])]),
    not_exported = {
      copy <- api
      copy$exports <- setdiff(copy$exports, two_args)
      copy
    }
  )
  for (case in names(rejected)) {
    expect_true(length(acc_api_violations(snapshot, rejected[[case]])) > 0L, info = case)
    expect_false(acc_api_superset_reference(snapshot, rejected[[case]]), info = case)
  }

  extended <- alter(two_args, function(fm) c(as.list(fm), alist(acc_new_argument = NULL)))
  extended$exports <- c(extended$exports, "acc_new_export")
  extended$functions$acc_new_export <- function() NULL
  expect_identical(acc_api_violations(snapshot, extended), character())
  expect_true(acc_api_superset_reference(snapshot, extended))
})

test_that("K-M0-7: a snapshot change without an ADR in the same milestone fails the golden-adr gate", {
  show <- function(result) paste(c(result$stdout, result$stderr), collapse = "\n")
  without_adr <- acc_golden_adr_gate("reference/anchors/ANK-02.json")
  expect_identical(without_adr$status, 1L, info = show(without_adr))
  with_adr <- acc_golden_adr_gate(
    c("reference/anchors/ANK-02.json", "docs/decisions/ADR-001-api-snapshot.md")
  )
  expect_identical(with_adr$status, 0L, info = show(with_adr))
  unrelated <- acc_golden_adr_gate("NEWS.md")
  expect_identical(unrelated$status, 0L, info = show(unrelated))
})
