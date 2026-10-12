#' Create a QUEST+/Psi Bayesian adaptive engine (2AFC)
#'
#' Maintains a posterior over the threshold parameter on a stimulus grid and
#' places each trial at the level that minimizes expected posterior entropy
#' (information-maximizing placement). Implements a 1-parameter special case of
#' the QUEST+/Psi family for a 2AFC psychometric function with fixed guess rate
#' 0.5 and a configurable lapse rate.
#'
#' @param grid Numeric vector of candidate stimulus levels (dB).
#' @param prior Optional prior over \code{grid} (defaults to uniform).
#' @param slope Psychometric slope (logistic) in probability-per-dB-ish units
#'   (default 1). Fixed in this 1-parameter implementation.
#' @param lapse Lapse rate (default 0.02).
#' @param guess Guess rate (default 0.5 for 2AFC).
#' @param n_trials Maximum number of trials (default 40).
#' @param sd_stop Optional early-stop threshold on the posterior SD (dB).
#' @return An object of class \code{"questplus"}.
#' @references Watson, A. B., & Pelli, D. G. (1983). QUEST: A Bayesian adaptive
#'   psychometric method. Perception & Psychophysics, 33(2), 113-120.
#'   Kontsevich, L. L., & Tyler, C. W. (1999). Bayesian adaptive estimation of
#'   psychometric slope and threshold. Vision Research, 39(16), 2729-2737.
#' @export
questplus_new <- function(grid, prior = NULL, slope = 1, lapse = 0.02,
                          guess = 0.5, n_trials = 40, sd_stop = NULL) {
  if (is.null(prior)) prior <- rep(1 / length(grid), length(grid))
  prior <- prior / sum(prior)
  structure(list(
    grid = grid, posterior = prior, slope = slope, lapse = lapse,
    guess = guess, n_trials = n_trials, sd_stop = sd_stop,
    n_done = 0L,
    history = data.frame(level = numeric(0), correct = logical(0))
  ), class = "questplus")
}

# Psychometric function: P(correct | level, threshold)
.qp_pcorrect <- function(level, threshold, slope, guess, lapse) {
  p <- 1 / (1 + exp(-slope * (level - threshold)))
  guess + (1 - guess - lapse) * p
}

.qp_entropy <- function(p) {
  p <- p[p > 0]
  -sum(p * log(p))
}

#' @export
engine_next.questplus <- function(engine) {
  grid <- engine$grid; post <- engine$posterior
  # Expected entropy after testing each candidate level.
  exp_H <- vapply(grid, function(lev) {
    pc <- .qp_pcorrect(lev, grid, engine$slope, engine$guess, engine$lapse)
    p_corr <- sum(post * pc)
    p_inc <- 1 - p_corr
    post_c <- post * pc; post_c <- post_c / sum(post_c)
    post_i <- post * (1 - pc); post_i <- post_i / sum(post_i)
    p_corr * .qp_entropy(post_c) + p_inc * .qp_entropy(post_i)
  }, numeric(1))
  grid[which.min(exp_H)]
}

#' @export
engine_update.questplus <- function(engine, correct) {
  level <- engine_next(engine)
  pc <- .qp_pcorrect(level, engine$grid, engine$slope, engine$guess, engine$lapse)
  like <- if (isTRUE(correct)) pc else (1 - pc)
  post <- engine$posterior * like
  engine$posterior <- post / sum(post)
  engine$n_done <- engine$n_done + 1L
  engine$history <- rbind(engine$history,
                          data.frame(level = level, correct = correct))
  engine
}

#' @export
engine_done.questplus <- function(engine) {
  if (engine$n_done >= engine$n_trials) return(TRUE)
  if (!is.null(engine$sd_stop)) {
    sd_post <- .qp_sd(engine)
    if (is.finite(sd_post) && sd_post < engine$sd_stop) return(TRUE)
  }
  FALSE
}

.qp_mean <- function(engine) sum(engine$grid * engine$posterior)
.qp_sd <- function(engine) {
  m <- .qp_mean(engine)
  sqrt(sum(engine$posterior * (engine$grid - m)^2))
}

#' @export
engine_threshold.questplus <- function(engine) {
  list(estimate = .qp_mean(engine), se = .qp_sd(engine),
       posterior = engine$posterior, history = engine$history)
}
