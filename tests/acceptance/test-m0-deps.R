# K-M0-1: decided by the deps gate (orchestrator/gates.d/10-deps.sh running
# orchestrator/lib/r-deps.R); the installed versions are in
# orchestrator/state/M0/gate-deps.log. The test below re-checks the condition
# itself with its own parser of DESCRIPTION.

test_that("K-M0-1: every package named in DESCRIPTION under Depends, Imports and Suggests is installed", {
  deps <- acc_description_deps(
    file.path(acc_pkg_root(), "DESCRIPTION"), c("Depends", "Imports", "Suggests")
  )
  expect_true(nrow(deps) > 0L)
  for (i in seq_len(nrow(deps))) {
    dep <- deps[i, ]
    required <- trimws(paste(dep$op, dep$version))
    label <- sprintf("%s: %s %s", dep$field, dep$package, required)
    installed <- acc_installed_version(dep$package)
    expect_false(is.na(installed), info = label)
    expect_true(
      !is.na(installed) && acc_version_satisfies(installed, dep$op, dep$version),
      info = paste0(label, "; installed: ", installed)
    )
  }
})
