# K-M3c-6 (class A part, docs/01 §8; docs/04 M3c): the comparison of the
# empirical coefficient of variation of the prompt component with the planning
# rule CV ~ sqrt(2 / nu), nu = a - 1 (ankerRef: ANK-89), is reported per
# candidate plan together with the share of boundary estimates in
# vignettes/validation.Rmd and is no pass criterion; this file generates the
# numbers and checks only their completeness. The candidate plans S-plan-1 to
# S-plan-4, the components (S-boot-1), the seeds and the vignette table are
# defined in tests/acceptance/setup-m3c.R (ACC-8); that the vignette reports
# the numbers generated here is part of the completeness check (ACC-8). The
# acceptance test of the vignette structure is test-m3c-6-vignette.R.
#
# ADEMP. Aim: precision of the REML estimate of the prompt component against
# the planning rule (BL-50). Data: msa_plan(plan, vc = S-boot-1 components,
# nsim = ANK-06, seed = 20261108 + i) for candidate plan i. Estimand: the prompt
# component 0.05. Performance measures (reported, no threshold): empirical CV
# = sd / mean of the prompt estimates of all repetitions, the share of
# boundary estimates (prompt component exactly 0) with MCSE sqrt(p (1 - p) /
# n_sim) (Formelsammlung §9), the rule value sqrt(2 / nu). Seeds, RNG,
# versions and runtime are reported in a message.

test_that("K-M3c-6: msa_plan() with n_sim = ANK-06 for the candidate plans S-plan-1 to S-plan-4 gives complete numbers for the planning-rule comparison (empirical CV of the prompt component, share of boundary estimates with MCSE), and the knitted vignette reports them", {
  t0 <- proc.time()[["elapsed"]]
  env <- sim_m3c_env()
  n_sim <- as.integer(sim_value("ANK-06", "n_sim_min"))
  numerator <- as.numeric(sim_value("ANK-89", "numerator"))
  offset <- as.integer(sim_value("ANK-89", "nu_offset"))
  plans <- env$acc_m3c_plans
  design <- c("n_items", "n_prompts", "n_models", "n_reps", "n_blocks")
  fits <- sim_with_seed(env$acc_m3c_plan_seed(0L), sim_parallel(seq_len(nrow(plans)), function(i) {
    msa_plan(plans[i, design], vc = env$acc_m3c_plan_vc, nsim = n_sim, seed = env$acc_m3c_plan_seed(i), verbose = FALSE)
  }, cores = nrow(plans)))
  numbers <- list()
  report <- character()
  for (i in seq_len(nrow(plans))) {
    id <- plans$plan[i]
    rep <- attr(fits[[i]], "replicates", exact = TRUE)
    complete <- is.data.frame(rep) && all(env$acc_m3c_replicate_columns %in% names(rep))
    expect_true(complete, label = sprintf("%s: attribute replicates with the columns %s", id, paste(env$acc_m3c_replicate_columns, collapse = ", ")))
    if (!complete) next
    expect_identical(nrow(rep), n_sim, label = sprintf("%s: repetitions", id))
    expect_identical(sort(as.integer(rep$sim)), seq_len(n_sim), label = sprintf("%s: repetitions 1 to %d", id, n_sim))
    expect_true(all(is.finite(rep$prompt) & rep$prompt >= 0), label = sprintf("%s: prompt estimates finite and non-negative", id))
    expect_true(all(is.finite(rep$estimate)), label = sprintf("%s: %%GRR estimates finite", id))
    s <- env$acc_m3c_prompt_summary(as.numeric(rep$prompt))
    nu <- plans$n_prompts[i] - offset
    rule <- sqrt(numerator / nu)
    expect_true(is.finite(s$cv) && s$cv > 0, label = sprintf("%s: empirical CV %.4f", id, s$cv))
    expect_true(s$boundary >= 0 && s$boundary <= 1, label = sprintf("%s: share of boundary estimates %.4f", id, s$boundary))
    numbers[[id]] <- c(s, list(nu = nu, rule = rule))
    report <- c(report, sprintf("%s (items %d, prompts %d, models %d, replicates %d, blocks %d): nu %d, rule %.4f, empirical CV %.4f, boundary share %.4f (MCSE %.4f); n_sim %d, %s",
                                id, plans$n_items[i], plans$n_prompts[i], plans$n_models[i], plans$n_reps[i], plans$n_blocks[i], nu, rule,
                                s$cv, s$boundary, s$mcse, n_sim, sim_session_note(env$acc_m3c_plan_seed(i))))
  }
  message("K-M3c-6 (tests/simulation/test-plan-satterthwaite.R, msa_plan, ", sprintf("%.1f s", proc.time()[["elapsed"]] - t0), "):\n",
          paste(report, collapse = "\n"))
  if (length(numbers) != nrow(plans)) return(invisible())
  k <- env$acc_m1a_knit_validation()
  expect_null(k$error)
  sec <- env$acc_m3c_plan_section(k$lines)
  expect_true(!is.null(sec), label = "a section of the vignette whose header names the planning rule")
  if (is.null(sec)) return(invisible())
  tab <- env$acc_m3c_plan_table(sec)
  expect_true(!is.null(tab), label = "the planning-rule table of the vignette")
  if (is.null(tab)) return(invisible())
  for (id in names(numbers)) {
    r <- tab[tab$plan == id, , drop = FALSE]
    expect_identical(nrow(r), 1L, label = sprintf("%s: one row in the vignette", id))
    if (nrow(r) != 1L) next
    x <- numbers[[id]]
    expect_identical(suppressWarnings(as.integer(r$nu)), as.integer(x$nu), label = sprintf("%s: nu", id))
    expect_identical(suppressWarnings(as.numeric(gsub("[^0-9]", "", r$n_sim))), as.numeric(x$n), label = sprintf("%s: n_sim", id))
    expect_true(env$acc_m3c_shows(r$cv_rule, x$rule), label = sprintf("%s: cv_rule %s shows %.6f", id, r$cv_rule, x$rule))
    expect_true(env$acc_m3c_shows(r$cv_empirical, x$cv), label = sprintf("%s: cv_empirical %s shows %.6f", id, r$cv_empirical, x$cv))
    expect_true(env$acc_m3c_shows(r$boundary_share, x$boundary), label = sprintf("%s: boundary_share %s shows %.6f", id, r$boundary_share, x$boundary))
    expect_true(env$acc_m3c_shows(r$mcse_boundary, x$mcse), label = sprintf("%s: mcse_boundary %s shows %.6f", id, r$mcse_boundary, x$mcse))
  }
})
