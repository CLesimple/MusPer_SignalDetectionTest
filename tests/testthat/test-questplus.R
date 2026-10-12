test_that("QUEST+ posterior mean converges toward the true threshold", {
  set.seed(42)
  ests <- replicate(20, {
    eng <- questplus_new(grid = seq(-20, 20, by = 1), slope = 1,
                         n_trials = 40)
    while (!engine_done(eng)) {
      lev <- engine_next(eng)
      eng <- engine_update(eng, simulate_observer(lev, threshold = 3, slope = 1))
    }
    engine_threshold(eng)$estimate
  })
  expect_true(abs(mean(ests) - 3) < 2)
})

test_that("posterior SD shrinks with trials", {
  set.seed(7)
  eng <- questplus_new(grid = seq(-20, 20, by = 1), n_trials = 40)
  sd0 <- engine_threshold(eng)$se
  for (i in 1:20) {
    lev <- engine_next(eng)
    eng <- engine_update(eng, simulate_observer(lev, threshold = 0))
  }
  expect_true(engine_threshold(eng)$se < sd0)
})
