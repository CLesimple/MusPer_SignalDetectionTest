#' Create an interleaved multi-track experiment
#'
#' Manages multiple adaptive tracks (e.g. listener x condition x signal) within
#' a session. Tracks are interleaved to spread learning and fatigue across
#' conditions and to discourage listener strategy. On each step a track is
#' selected (randomly among unfinished tracks, or round-robin) and its next
#' stimulus level is returned; the response is routed back to that track.
#'
#' @param engines A named list of adaptive engine objects (one per track).
#' @param method Track selection: "random" (default) or "roundrobin".
#' @return An object of class \code{"experiment"}.
#' @export
experiment_new <- function(engines, method = c("random", "roundrobin")) {
  method <- match.arg(method)
  structure(list(engines = engines, method = method, rr_index = 0L),
            class = "experiment")
}

#' Select the next track and its stimulus level.
#' @param experiment An \code{experiment} object.
#' @return A list with \code{track} (name) and \code{level}, or \code{NULL} when
#'   all tracks are finished.
#' @export
experiment_next <- function(experiment) {
  unfinished <- names(experiment$engines)[
    !vapply(experiment$engines, engine_done, logical(1))]
  if (!length(unfinished)) return(NULL)
  if (experiment$method == "random") {
    track <- sample(unfinished, 1)
  } else {
    experiment$rr_index <- (experiment$rr_index %% length(unfinished)) + 1L
    track <- unfinished[experiment$rr_index]
  }
  list(track = track, level = engine_next(experiment$engines[[track]]))
}

#' Route a response back to a track.
#' @param experiment An \code{experiment} object.
#' @param track Track name returned by \code{experiment_next()}.
#' @param correct Logical; was the response correct?
#' @return The updated \code{experiment} object.
#' @export
experiment_update <- function(experiment, track, correct) {
  experiment$engines[[track]] <- engine_update(experiment$engines[[track]], correct)
  experiment
}
