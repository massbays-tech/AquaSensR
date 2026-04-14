#' Compute consecutive run lengths for flatline detection
#'
#' @param vals numeric vector of observed values.
#' @param delta non-negative numeric scalar tolerance.  An observation extends
#'   the current run only when both (1) its absolute difference from the
#'   immediately preceding observation is \eqn{\le} \code{delta}, and (2) its
#'   absolute difference from the first observation in the run (the anchor) is
#'   \eqn{\le} \code{delta}.  Either condition failing resets the run.
#'
#' @details For each position \eqn{i}, the run extends only when both
#'   conditions hold: (1) the step from the previous observation is
#'   \eqn{\le} \code{delta} (prevents a large single-step jump from continuing
#'   the run), and (2) the value is within \eqn{\le} \code{delta} of the first
#'   observation in the current run (prevents slow cumulative drift from
#'   accumulating run length indefinitely).  Either condition failing resets the
#'   run and anchors to the current observation.
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
  run_start_val <- vals[1L]
  for (i in seq_len(n - 1L) + 1L) {
    if (
      !is.na(vals[i]) &&
        !is.na(vals[i - 1L]) &&
        !is.na(run_start_val) &&
        abs(vals[i] - vals[i - 1L]) <= delta &&
        abs(vals[i] - run_start_val) <= delta
    ) {
      rl[i] <- rl[i - 1L] + 1L
    } else {
      rl[i] <- 1L
      run_start_val <- vals[i]
    }
  }
  rl
}
