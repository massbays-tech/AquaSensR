#' Apply gross range QC flag
#'
#' @param flag character vector of current flag values (\code{"pass"},
#'   \code{"suspect"}, or \code{"fail"}).
#' @param vals numeric vector of observed values, the same length as
#'   \code{flag}.
#' @param meta single-row data frame of metadata for the parameter being
#'   checked.  Must contain numeric columns \code{Min}, \code{Max},
#'   \code{Tlower}, and \code{Tupper}.
#'
#' @details Observations below \code{Min} or above \code{Max} are flagged
#'   \code{"fail"}.  Observations below \code{Tlower} or above \code{Tupper}
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
#' meta <- data.frame(Min = -1, Max = 30, Tlower = 0, Tupper = 25)
#' utilASRflaggross(flag, vals, meta)
utilASRflaggross <- function(flag, vals, meta) {
  if (!is.na(meta$Tlower)) {
    flag <- utilASRflagupdategupdate(flag, "suspect", vals < meta$Tlower)
  }
  if (!is.na(meta$Tupper)) {
    flag <- utilASRflagupdategupdate(flag, "suspect", vals > meta$Tupper)
  }
  if (!is.na(meta$Min)) {
    flag <- utilASRflagupdategupdate(flag, "fail", vals < meta$Min)
  }
  if (!is.na(meta$Max)) {
    flag <- utilASRflagupdategupdate(flag, "fail", vals > meta$Max)
  }
  flag
}
