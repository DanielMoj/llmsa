# A staged source package may omit vignettes while REPO_ROOT identifies its
# source tree. Supply the original documentation fixture byte-for-byte so the
# existing source traversal and literal assertions still examine every file.
# Installed packages already contain doc/validation.Rmd and need no setup.
local({
  root <- Sys.getenv("REPO_ROOT", "")
  destination <- file.path(testthat::test_path("..", ".."), "vignettes", "validation.Rmd")
  installed <- system.file("doc", "validation.Rmd", package = "llmsa")
  if (nzchar(root) && !nzchar(installed) && !file.exists(destination)) {
    original <- file.path(root, "vignettes", "validation.Rmd")
    if (!file.exists(original)) stop("Missing validation vignette in REPO_ROOT: ", original)
    dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
    if (!file.copy(original, destination)) stop("Cannot stage validation vignette: ", destination)
  }
})
