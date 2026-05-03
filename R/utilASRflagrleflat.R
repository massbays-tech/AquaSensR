#' Compute consecutive run lengths for flatline detection
#'
#' @param vals numeric vector of observed values.
#' @param delta non-negative numeric scalar tolerance.  An observation extends
#'   the current run only when the range (max minus min) of all values in the
#'   run so far, including the new observation, is strictly \eqn{<} \code{delta}.
#'   If this condition fails the run resets.
#'
#' @details For each position \eqn{i}, the run extends only when adding the
#'   current observation to the run keeps the range (max minus min of all
#'   values in the run) strictly \eqn{<} \code{delta}.  This prevents both
#'   large single-step jumps and slow cumulative drift from accumulating run
#'   length.  A range equal to \code{delta} is not considered flatline.
#'   A run length of 1 means the observation is not part of a flat stretch.
#'   \code{NA} values in \code{vals} break the run.
#'
#' @return Integer vector the same length as \code{vals} giving the run length
#'   at each position.
#'
#' @export
#'
#' @examples
#' vals <- c(10, 10, 10.005, 10.003, 12, 12, 12)
#' utilASRflagrleflat(vals, delta = 0.01)
utilASRflagrleflat <- function(vals, delta) {
  n <- length(vals)
  rl <- integer(n)
  rl[1L] <- 1L
  run_min <- vals[1L]
  run_max <- vals[1L]
  for (i in seq_len(n - 1L) + 1L) {
    v <- vals[i]
    if (!is.na(v) && !is.na(run_min)) {
      new_min <- min(run_min, v)
      new_max <- max(run_max, v)
      if (round(new_max - new_min, 10) < delta) {
        rl[i] <- rl[i - 1L] + 1L
        run_min <- new_min
        run_max <- new_max
      } else {
        rl[i] <- 1L
        run_min <- v
        run_max <- v
      }
    } else {
      rl[i] <- 1L
      run_min <- v
      run_max <- v
    }
  }
  rl
}
