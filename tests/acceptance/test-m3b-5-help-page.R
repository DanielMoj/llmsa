# K-M3b-5 (help page): the help page of msa_robustness() calls the method
# conservative and alpha a nominal value (ADR-050); ADR-050 Nr. 3 drops the
# sentence "at the 5 % level per effect". The false alarm rate of K-M3b-5 is
# the class A simulation tests/simulation/test-lenth-h0.R. The page is read as
# plain text from man/msa_robustness.Rd at the repository root
# (acc_m1b_rd_text(), setup-m1b.R) and split into sentences; the form of the
# check is ACC-15.

acc_m3b_5_sentences <- function() {
  s <- trimws(strsplit(acc_m1b_rd_text("msa_robustness"), "(?<=[.;!?])\\s+", perl = TRUE)[[1]])
  s[nzchar(s)]
}

test_that("K-M3b-5: the help page of msa_robustness() calls the method conservative (ADR-050)", {
  s <- acc_m3b_5_sentences()
  # "not conservative", "non-conservative", "anti-conservative" or
  # "unconservative" says the opposite and does not count.
  called <- grepl("(?i)(?<!not )(?<!non-)(?<!non)(?<!anti-)(?<!anti)(?<!un)conservativ", s, perl = TRUE)
  expect_true(any(called),
              label = sprintf("a sentence of man/msa_robustness.Rd calls the method conservative; sentences: %s",
                              paste(shQuote(s), collapse = " ")))
})

test_that("K-M3b-5: the help page of msa_robustness() calls alpha a nominal value (ADR-050)", {
  s <- acc_m3b_5_sentences()
  hit <- grepl("alpha|α|significance level", s, ignore.case = TRUE) & grepl("nominal", s, ignore.case = TRUE)
  expect_true(any(hit),
              label = sprintf("a sentence of man/msa_robustness.Rd that names alpha (or the significance level) calls it nominal; sentences: %s",
                              paste(shQuote(s), collapse = " ")))
})

test_that("K-M3b-5: the help page of msa_robustness() no longer says \"at the 5 % level per effect\" (ADR-050 Nr. 3)", {
  # Spacing around the percent sign does not matter.
  txt <- acc_m1b_rd_text("msa_robustness")
  expect_false(grepl("at the 5\\s*%\\s*level per effect", txt, ignore.case = TRUE, perl = TRUE),
               label = "man/msa_robustness.Rd still contains \"at the 5 % level per effect\"")
})
