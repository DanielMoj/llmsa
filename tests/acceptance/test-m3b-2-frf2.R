# K-M3b-2: every matrix of K-M3b-1 is identical to FrF2::pb(nruns = N) up to row
# permutation, column permutation and sign changes of columns (ankerRef:
# ANK-TOL.frf2_unrepx: "Matrizen exakt bis auf Permutation und Vorzeichen").
# The oracle runs at test time (docs/01 §6); the test exhibits the mapping and
# checks every entry, and it names the J3 multisets when no mapping exists
# (ACC-4). For N = 16, FrF2::pb() returns by default the Box-Tyssedal design,
# which is not isomorphic to the cyclic design of Plackett & Burman; this
# contradiction between K-M3b-1 and K-M3b-2 is ACC-5.

acc_m3b_2_check <- function(N) {
  A <- acc_m3b_coded(pb_design(N - 1L, n_runs = N, randomize = FALSE))
  B <- acc_m3b_frf2(N)
  inv_a <- acc_m3b_j3_table(A)
  inv_b <- acc_m3b_j3_table(B)
  e <- if (identical(acc_m3b_j3(A), acc_m3b_j3(B))) acc_m3b_equivalence(A, B) else
    list(found = FALSE, verified = FALSE, reason = "J3 multisets differ")
  list(e = e, inv_a = inv_a, inv_b = inv_b)
}

test_that("K-M3b-2: the matrices for N = 8, 12, 16, 20, 24 equal FrF2::pb(nruns = N) up to row and column permutation and column signs (ANK-TOL.frf2_unrepx)", {
  rule <- acc_m3b_tol("frf2_unrepx", "matrices")
  expect_identical(rule, "exakt bis auf Permutation und Vorzeichen")
  for (N in acc_m3b_sizes()) {
    res <- acc_m3b_2_check(N)
    expect_true(isTRUE(res$e$found) && isTRUE(res$e$verified),
                label = sprintf("N = %d: pb_design() and FrF2::pb(nruns = %d) are equivalent (%s); J3 multisets llmsa %s | FrF2 %s",
                                N, N, if (isTRUE(res$e$found)) "mapping found" else res$e$reason, res$inv_a, res$inv_b))
  }
})

test_that("K-M3b-2: the equivalence check finds a hidden permutation and sign change and rejects a non-equivalent design", {
  # Positive and negative controls of the test helper (docs/01 §2 Nr. 1).
  A <- acc_m3b_pb_reference(12L, "row_right")
  perm <- acc_m3b_with_seed(1L, list(r = sample.int(12L), c = sample.int(11L), s = sample(c(-1, 1), 11L, replace = TRUE)))
  B <- sweep(A[perm$r, perm$c], 2, perm$s, `*`)
  e <- acc_m3b_equivalence(A, B)
  expect_true(isTRUE(e$found) && isTRUE(e$verified))
  expect_true(all(A == sweep(B[e$sigma, e$pi], 2, e$s, `*`)))
  # Flipping a 2 x 2 block breaks the orthogonality of the columns; such a
  # matrix is no relabelling of the design (8 runs keep the exhaustive search
  # short).
  A8 <- acc_m3b_pb_reference(8L, "row_right")
  C <- A8
  C[1:2, 1:2] <- -C[1:2, 1:2]
  expect_false(isTRUE(acc_m3b_equivalence(A8, C)$found))
  # The regular 16-run design and the Box-Tyssedal design have different J3
  # multisets (Box & Tyssedal 1996 designs are not regular).
  bt <- acc_m3b_frf2(16L)
  expect_false(identical(acc_m3b_j3(acc_m3b_pb_reference(16L, "row_right")), acc_m3b_j3(bt)))
})
