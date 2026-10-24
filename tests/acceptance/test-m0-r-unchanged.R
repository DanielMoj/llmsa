# K-M0-4: M0 does not change R/ (docs/01-fachspezifikation.md §10), later
# milestones do, and the acceptance tests keep running in every later tests and
# mutation gate. Until the orchestrator marks M0 as done, the working tree is
# checked; afterwards the frozen result of M0, tag done/M0 (CRITERIA.json, open
# item ACC-1).

test_that("K-M0-4: ANK-01 records 13 files under R/ with SHA-256 and size", {
  files <- acc_anchor("ANK-01")$value
  expect_length(files, 13L)
  expect_true(all(grepl("^R/[^/]+$", names(files))))
  for (path in names(files)) {
    expect_match(files[[path]]$sha256, "^[0-9a-f]{64}$", info = path)
    expect_true(is.numeric(files[[path]]$bytes) && files[[path]]$bytes > 0, info = path)
  }
})

test_that("K-M0-4: the files under R/ are byte-identical with commit 332a2d5 (ankerRef: ANK-01)", {
  files <- acc_anchor("ANK-01")$value
  root <- acc_repo_root()
  observed <- if (acc_milestone_done("M0")) {
    acc_r_files_at(root, "done/M0")
  } else {
    acc_r_files_worktree(root)
  }
  expect_setequal(observed$path, names(files))
  for (path in intersect(names(files), observed$path)) {
    row <- observed[observed$path == path, ]
    expect_identical(row$sha256, files[[path]]$sha256, info = path)
    expect_identical(row$bytes, as.numeric(files[[path]]$bytes), info = path)
  }
})
