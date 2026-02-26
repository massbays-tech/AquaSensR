#' Compute consecutive run lengths for flatline detection
#'
#' @param vals numeric vector of observed values.
#' @param delta non-negative numeric scalar.  Two adjacent observations are
#'   considered part of the same flat run if their absolute difference is
#'   less than or equal to \code{delta}.
#'
#' @details For each position \eqn{i}, the run length is the number of
#'   consecutive observations ending at \eqn{i} (including \eqn{i} itself)
#'   for which each successive absolute difference is \eqn{\le} \code{delta}.
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
  for (i in seq_len(n - 1L) + 1L) {
    if (
      !is.na(vals[i]) &&
        !is.na(vals[i - 1L]) &&
        abs(vals[i] - vals[i - 1L]) <= delta
    ) {
      rl[i] <- rl[i - 1L] + 1L
    } else {
      rl[i] <- 1L
    }
  }
  rl
}
