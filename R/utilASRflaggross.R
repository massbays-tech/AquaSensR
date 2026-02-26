#' Apply gross range QC flag
#'
#' @param flag character vector of current flag values (\code{"pass"},
#'   \code{"suspect"}, or \code{"fail"}).
#' @param vals numeric vector of observed values, the same length as
#'   \code{flag}.
#' @param meta single-row data frame of metadata for the parameter being
#'   checked.  Must contain numeric columns \code{GrMinFail}, \code{GrMaxFail},
#'   \code{GrMinSuspect}, and \code{GrMaxSuspect}.
#'
#' @details Observations below \code{GrMinFail} or above \code{GrMaxFail} are flagged
#'   \code{"fail"}.  Observations below \code{GrMinSuspect} or above \code{GrMaxSuspect}
#'   (but within the fail bounds) are flagged \code{"suspect"}.
#'   \code{NA} threshold values are silently skipped.
#'
#' @return Updated character flag vector.
#'
#' @export
#'
#' @examples
#' flag <- rep("pass", 5)
#' vals <- c(-2, 0, 15, 26, 32)
#' meta <- data.frame(GrMinFail = -1, GrMaxFail = 30, GrMinSuspect = 0, GrMaxSuspect = 25)
#' utilASRflaggross(flag, vals, meta)
utilASRflaggross <- function(flag, vals, meta) {
  if (!is.na(meta$GrMinSuspect)) {
    flag <- utilASRflagupdate(flag, "suspect", vals < meta$GrMinSuspect)
  }
  if (!is.na(meta$GrMaxSuspect)) {
    flag <- utilASRflagupdate(flag, "suspect", vals > meta$GrMaxSuspect)
  }
  if (!is.na(meta$GrMinFail)) {
    flag <- utilASRflagupdate(flag, "fail", vals < meta$GrMinFail)
  }
  if (!is.na(meta$GrMaxFail)) {
    flag <- utilASRflagupdate(flag, "fail", vals > meta$GrMaxFail)
  }
  flag
}
