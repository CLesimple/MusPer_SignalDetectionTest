#' Simulated 2AFC observer
#'
#' Returns a logical "correct" response drawn from a logistic 2AFC psychometric
#' function with guess rate 0.5. Useful for testing and tuning the adaptive
#' engines before collecting real data.
#'
#' @param level Stimulus level (dB).
#' @param threshold True threshold (dB).
#' @param slope Psychometric slope (default 1).
#' @param lapse Lapse rate (default 0.02).
#' @param guess Guess rate (default 0.5).
#' @return Logical scalar.
#' @export
simulate_observer <- function(level, threshold, slope = 1, lapse = 0.02,
                              guess = 0.5) {
  p <- 1 / (1 + exp(-slope * (level - threshold)))
  pc <- guess + (1 - guess - lapse) * p
  stats::runif(1) < pc
}
