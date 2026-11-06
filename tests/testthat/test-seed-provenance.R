seed_provenance_roundtrip <- function(x) unserialize(serialize(x, NULL))
seed_provenance_without <- function(x) { attr(x, "seed") <- NULL; x }

test_that("PB seed provenance records only a seed that randomized the design", {
  old <- .Random.seed_get()
  on.exit(.Random.seed_set(old), add = TRUE)
  for (seed in list(17001L, 17001)) {
    seeded <- pb_design(list(label = c("low", "high")), seed = seed)
    expect_identical(attr(seeded, "seed", exact = TRUE), seed)
    expect_identical(seed_provenance_roundtrip(seeded), seeded)
    set.seed(seed)
    unseeded <- pb_design(list(label = c("low", "high")))
    expect_null(attr(unseeded, "seed", exact = TRUE))
    expect_identical(seed_provenance_without(seeded), unseeded)
    fixed <- pb_design(list(label = c("low", "high")), randomize = FALSE, seed = seed)
    expect_null(attr(fixed, "seed", exact = TRUE))
    expect_identical(fixed, pb_design(list(label = c("low", "high")), randomize = FALSE))
  }
})

test_that("robustness copies the design seed without changing any other output", {
  old <- .Random.seed_get()
  on.exit(.Random.seed_set(old), add = TRUE)
  set.seed(17002L)
  for (seed in list(NULL, 17002L, 17002)) {
    design <- pb_design(7, seed = seed)
    plain <- as.data.frame(attr(design, "coded"))
    response <- seq(0.1, 0.8, length.out = nrow(design))
    for (transform in c("none", "logit")) {
      result <- msa_robustness(design, response, transform = transform)
      without_seed <- msa_robustness(plain, response, factors = names(plain), transform = transform)
      expect_identical(attr(result, "seed", exact = TRUE), seed)
      expect_identical(seed_provenance_without(result), without_seed)
      expect_identical(seed_provenance_roundtrip(result), result)
    }
  }
  # A plain design's explicit provenance is authoritative too, without inference.
  attr(plain, "seed") <- 17003L
  expect_identical(attr(msa_robustness(plain, response, factors = names(plain)), "seed"), 17003L)
})

test_that("bootstrap seed provenance survives serialization without changing replicates or RNG", {
  fit <- msa_fit(ic50_demo, type = "numeric")
  old <- .Random.seed_get()
  on.exit(.Random.seed_set(old), add = TRUE)
  for (seed in list(17004L, 17004)) {
    explicit <- msa_boot(fit, nsim = 3, seed = seed)
    state <- .Random.seed_get()
    expect_identical(attr(explicit, "seed", exact = TRUE), seed)
    expect_identical(seed_provenance_roundtrip(explicit), explicit)
    set.seed(seed)
    implicit <- msa_boot(fit, nsim = 3)
    expect_null(attr(implicit, "seed", exact = TRUE))
    expect_identical(seed_provenance_without(explicit), implicit)
    expect_identical(.Random.seed_get(), state)
  }
})
