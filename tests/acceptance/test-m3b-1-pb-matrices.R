# K-M3b-1: the Plackett-Burman matrices for N = 8, 12, 16, 20, 24 arise from the
# generator rows of Plackett & Burman (1946) (ankerRef: ANK-80) by N - 2 cyclic
# shifts and a row of -1; with a leading column of ones H'H = N I, and every
# factor column sums to 0. The matrix under test is the attribute `coded` of
# pb_design(N - 1, n_runs = N, randomize = FALSE) (ACC-3); it must equal one of
# the three forms of the construction the source allows (generator as first row
# shifted right or left, or as first column shifted down; P&B p. 319 and 323).

test_that("K-M3b-1: pb_design() builds each matrix from the generator of ANK-80 by N - 2 cyclic shifts of one place and a final row of -1", {
  for (N in acc_m3b_sizes()) {
    d <- pb_design(N - 1L, n_runs = N, randomize = FALSE)
    X <- acc_m3b_coded(d)
    expect_identical(dim(X), c(N, N - 1L), label = sprintf("N = %d: dimension of the coded matrix", N))
    if (!identical(dim(X), c(N, N - 1L))) next
    expect_true(all(X[N, ] == -1), label = sprintf("N = %d: the last row is all -1", N))
    hits <- vapply(acc_m3b_pb_forms, function(form) isTRUE(all(X == acc_m3b_pb_reference(N, form))), logical(1))
    expect_true(any(hits),
                label = sprintf("N = %d: the coded matrix equals the generator %s of ANK-80 shifted cyclically (forms %s); first row %s",
                                N, acc_m3b_value("ANK-80", "generators", as.character(N)),
                                paste(acc_m3b_pb_forms, collapse = ", "),
                                paste(ifelse(X[1, ] > 0, "+", "-"), collapse = "")))
  }
})

test_that("K-M3b-1: with a leading column of ones H'H = N I, and every factor column sums to 0", {
  for (N in acc_m3b_sizes()) {
    X <- acc_m3b_coded(pb_design(N - 1L, n_runs = N, randomize = FALSE))
    expect_true(all(X %in% c(-1, 1)), label = sprintf("N = %d: entries are -1 or +1", N))
    H <- cbind(1, X)
    expect_identical(dim(H), c(N, N))
    if (!identical(dim(H), c(N, N))) next
    expect_true(all(crossprod(H) == N * diag(N)), label = sprintf("N = %d: H'H = N I", N))
    expect_true(all(colSums(X) == 0), label = sprintf("N = %d: every factor column sums to 0", N))
  }
})

test_that("K-M3b-1: the coded columns of the returned data.frame are the coded matrix", {
  for (N in acc_m3b_sizes()) {
    d <- pb_design(N - 1L, n_runs = N, randomize = FALSE)
    X <- acc_m3b_coded(d)
    cols <- colnames(attr(d, "coded"))
    expect_identical(length(cols), N - 1L)
    expect_true(all(cols %in% names(d)), label = sprintf("N = %d: every coded column is a column of the design", N))
    if (!all(cols %in% names(d))) next
    expect_true(all(as.matrix(as.data.frame(d)[, cols]) == X),
                label = sprintf("N = %d: the data.frame holds the coded matrix", N))
  }
})

test_that("K-M3b-1: the mini-reference reproduces the source: first rows of ANK-80, the printed first row of p. 319, H'H = N I in every form", {
  # Self-check of the reference construction against the source, so that a
  # wrong reference cannot pass a wrong product.
  for (N in acc_m3b_sizes()) {
    g <- acc_m3b_generator(N)
    for (form in acc_m3b_pb_forms) {
      R <- acc_m3b_pb_reference(N, form)
      H <- cbind(1, R)
      expect_true(all(crossprod(H) == N * diag(N)), label = sprintf("reference %s, N = %d: Hadamard", form, N))
      expect_true(all(colSums(R) == 0), label = sprintf("reference %s, N = %d: balanced columns", form, N))
      if (form == "column_down") expect_identical(R[seq_len(N - 1L), 1], g) else expect_identical(R[1, ], g)
    }
    expect_identical(acc_m3b_sorted_rows(acc_m3b_pb_reference(N, "row_right")),
                     acc_m3b_sorted_rows(acc_m3b_pb_reference(N, "row_left")))
  }
  printed <- acc_m3b_value("ANK-80", "construction", "example_page_319")
  first_row <- regmatches(printed, regexpr("[+-]{15}$", printed))
  R16 <- acc_m3b_pb_reference(16L, "column_down")
  expect_identical(paste(ifelse(R16[1, ] > 0, "+", "-"), collapse = ""), first_row)
})
