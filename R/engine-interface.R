#' Common adaptive engine interface
#'
#' Both the Levitt staircase (\code{levitt}) and the QUEST+/Psi engine
#' (\code{questplus}) implement this S3 interface so they can be swapped freely.
#'
#' The stimulus level returned by \code{engine_next()} is expressed in dB and is
#' intended to be applied as a \emph{real-time gain on the soft (test) part} of
#' the stimulus. It is NOT a selector into pre-rendered files. The loud part is
#' common to both 2AFC intervals; the signal interval = loud part + soft part
#' scaled by this gain; the non-signal interval = loud part + (silence or
#' matched-spectrum noise). Keep the loud->soft gap identical across intervals.
#'
#' @name engine-interface
NULL

#' Get the next stimulus level (dB) from an engine.
#' @param engine An adaptive engine object.
#' @return Numeric stimulus level in dB.
#' @export
engine_next <- function(engine) UseMethod("engine_next")

#' Update an engine with a response.
#' @param engine An adaptive engine object.
#' @param correct Logical; was the listener's 2AFC response correct?
#' @return The updated engine object.
#' @export
engine_update <- function(engine, correct) UseMethod("engine_update")

#' Is the engine finished?
#' @param engine An adaptive engine object.
#' @return Logical scalar.
#' @export
engine_done <- function(engine) UseMethod("engine_done")

#' Current threshold estimate from an engine.
#' @param engine An adaptive engine object.
#' @return A list with elements \code{estimate}, \code{se}, and \code{history}.
#' @export
engine_threshold <- function(engine) UseMethod("engine_threshold")
