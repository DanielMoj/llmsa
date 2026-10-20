# Contributing

Issues and pull requests are welcome at https://github.com/DanielMoj/llmsa.

* Report a bug with a minimal reproducible example (`reprex`), the output
  of `sessionInfo()` and, for backend problems, the raw response stored by
  `msa_run()`.
* New statistics should come with a reference, a worked example in the
  tests that reproduces a published value, and documentation of the
  assumptions.
* Run `devtools::check()` before submitting; the GitHub Actions workflow
  checks on Linux, macOS and Windows.
