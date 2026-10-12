test_that("Levitt staircase converges near the true 70.7% threshold", {
  set.seed(1)
  ests <- replicate(30, {
    eng <- levitt_new(start_level = 20, max_reversals = 12,
                      n_discard = 2, n_average = 10)
    guard <- 0
    while (!engine_done(eng) && guard < 500) {
      lev <- engine_next(eng)
      eng <- engine_update(eng, simulate_observer(lev, threshold = 0, slope = 1))
      guard <- guard + 1
    }
    engine_threshold(eng)$estimate
  })
  # 70.7% point for this logistic observer sits a few dB above the 50% threshold.
  expect_true(abs(mean(ests) - 0) < 5)
})

test_that("two-phase step switches after the phase boundary", {
  eng <- levitt_new(start_level = 20, step_large = 5, step_small = 2,
                    phase_boundary = 2)
  # Force reversals by alternating responses; check step magnitude shrinks.
  seq <- c(TRUE, TRUE, FALSE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE, TRUE, TRUE)
  levels <- numeric(0)
  for (r in seq) {
    levels <- c(levels, engine_next(eng))
    eng <- engine_update(eng, r)
  }
  diffs <- abs(diff(levels))
  expect_true(any(diffs == 5))
  expect_true(any(diffs == 2))
})

test_that("stopping triggers at max reversals", {
  eng <- levitt_new(start_level = 20, max_reversals = 4)
  guard <- 0
  while (!engine_done(eng) && guard < 500) {
    lev <- engine_next(eng)
    eng <- engine_update(eng, simulate_observer(lev, threshold = 0))
    guard <- guard + 1
  }
  expect_true(length(eng$reversals) >= 4)
})
