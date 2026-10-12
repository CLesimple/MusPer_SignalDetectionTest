test_that("common interface dispatches to both engines", {
  lv <- levitt_new(start_level = 10)
  qp <- questplus_new(grid = seq(-20, 20, by = 2))
  expect_type(engine_next(lv), "double")
  expect_type(engine_next(qp), "double")
  lv <- engine_update(lv, TRUE)
  qp <- engine_update(qp, TRUE)
  expect_false(engine_done(lv))
  expect_false(engine_done(qp))
  expect_true(is.list(engine_threshold(lv)))
  expect_true(is.list(engine_threshold(qp)))
})

test_that("experiment interleaves tracks and finishes", {
  engines <- list(
    s1 = levitt_new(start_level = 10, max_reversals = 4),
    s2 = questplus_new(grid = seq(-10, 10, by = 2), n_trials = 10)
  )
  exp <- experiment_new(engines, method = "roundrobin")
  guard <- 0
  repeat {
    nx <- experiment_next(exp)
    if (is.null(nx)) break
    exp <- experiment_update(exp, nx$track,
                             simulate_observer(nx$level, threshold = 0))
    guard <- guard + 1
    if (guard > 1000) break
  }
  expect_true(is.null(experiment_next(exp)))
})
