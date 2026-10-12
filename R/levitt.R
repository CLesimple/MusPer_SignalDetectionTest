#' Create a Levitt transformed up-down staircase engine
#'
#' Implements the transformed up-down method of Levitt (1971). The default
#' 2-down/1-up rule converges on the 70.7% correct point. Uses a two-phase step
#' size: a large step until \code{phase_boundary} reversals have occurred, then a
#' small step. The threshold is the mean of the reversal levels after discarding
#' the first \code{n_discard} reversals.
#'
#' @param start_level Numeric starting stimulus level (dB).
#' @param down Number of consecutive correct responses before decreasing level
#'   (default 2 for 2-down/1-up).
#' @param up Number of incorrect responses before increasing level (default 1).
#' @param step_large Large step size in dB (default 5), used until
#'   \code{phase_boundary} reversals.
#' @param step_small Small step size in dB (default 2), used thereafter.
#' @param phase_boundary Number of reversals after which to switch to the small
#'   step (default 2).
#' @param max_reversals Maximum reversals before stopping (default 6).
#' @param n_discard Number of initial reversals to discard (default 2).
#' @param n_average Number of trailing reversals to average; defaults to
#'   \code{max_reversals - n_discard}.
#' @param se_stop Optional early-stop threshold on
#'   \code{sd(reversals)/sqrt(n)}; set \code{NULL} to disable. Note: an SE based
#'   on very few reversals is itself noisy; treat it as a soft gate.
#' @param min_level,max_level Optional bounds on the stimulus level (dB).
#' @return An object of class \code{"levitt"}.
#' @references Levitt, H. (1971). Transformed up-down methods in psychoacoustics.
#'   JASA, 49(2B), 467-477.
#' @export
levitt_new <- function(start_level, down = 2, up = 1,
                       step_large = 5, step_small = 2, phase_boundary = 2,
                       max_reversals = 6, n_discard = 2, n_average = NULL,
                       se_stop = NULL, min_level = -Inf, max_level = Inf) {
  if (is.null(n_average)) n_average <- max_reversals - n_discard
  structure(list(
    level = start_level, down = down, up = up,
    step_large = step_large, step_small = step_small,
    phase_boundary = phase_boundary, max_reversals = max_reversals,
    n_discard = n_discard, n_average = n_average, se_stop = se_stop,
    min_level = min_level, max_level = max_level,
    consec_correct = 0L, consec_incorrect = 0L,
    last_direction = 0L, reversals = numeric(0),
    history = data.frame(level = numeric(0), correct = logical(0))
  ), class = "levitt")
}

#' @export
engine_next.levitt <- function(engine) engine$level

#' @export
engine_update.levitt <- function(engine, correct) {
  engine$history <- rbind(engine$history,
                          data.frame(level = engine$level, correct = correct))
  if (isTRUE(correct)) {
    engine$consec_correct <- engine$consec_correct + 1L
    engine$consec_incorrect <- 0L
  } else {
    engine$consec_incorrect <- engine$consec_incorrect + 1L
    engine$consec_correct <- 0L
  }

  direction <- 0L
  if (engine$consec_correct >= engine$down) {
    direction <- -1L  # decrease level (harder)
    engine$consec_correct <- 0L
  } else if (engine$consec_incorrect >= engine$up) {
    direction <- 1L   # increase level (easier)
    engine$consec_incorrect <- 0L
  }

  if (direction != 0L) {
    if (engine$last_direction != 0L && direction != engine$last_direction) {
      engine$reversals <- c(engine$reversals, engine$level)
    }
    step <- if (length(engine$reversals) < engine$phase_boundary) {
      engine$step_large
    } else {
      engine$step_small
    }
    engine$level <- engine$level + direction * step
    engine$level <- min(max(engine$level, engine$min_level), engine$max_level)
    engine$last_direction <- direction
  }
  engine
}

#' @export
engine_done.levitt <- function(engine) {
  n <- length(engine$reversals)
  if (n >= engine$max_reversals) return(TRUE)
  if (!is.null(engine$se_stop) && n > engine$n_discard) {
    used <- utils::tail(engine$reversals, n - engine$n_discard)
    if (length(used) >= 2) {
      se <- stats::sd(used) / sqrt(length(used))
      if (is.finite(se) && se < engine$se_stop) return(TRUE)
    }
  }
  FALSE
}

#' @export
engine_threshold.levitt <- function(engine) {
  rev <- engine$reversals
  if (length(rev) > engine$n_discard) {
    used <- utils::tail(rev, min(engine$n_average, length(rev) - engine$n_discard))
  } else {
    used <- rev
  }
  est <- if (length(used)) mean(used) else NA_real_
  se <- if (length(used) >= 2) stats::sd(used) / sqrt(length(used)) else NA_real_
  list(estimate = est, se = se, reversals = rev, history = engine$history)
}
