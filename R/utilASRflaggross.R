#' Apply gross range QC flag
#'
#' @param flag character vector of current flag values (\code{"pass"},
#'   \code{"suspect"}, or \code{"fail"}).
#' @param vals numeric vector of observed values, the same length as
#'   \code{flag}.
#' @param dqo two-row data frame from data quality objectives for the parameter
#'   being checked, containing one row where \code{Flag == "Fail"} and one
#'   where \code{Flag == "Suspect"}.  Must contain numeric columns \code{GrMin}
#'   and \code{GrMax}.
#'
#' @details Observations below \code{GrMin} or above \code{GrMax} in the
#'   \code{"Fail"} row are flagged \code{"fail"}.  Observations below
#'   \code{GrMin} or above \code{GrMax} in the \code{"Suspect"} row (but
#'   within the fail bounds) are flagged \code{"suspect"}.
#'   \code{NA} threshold values are silently skipped.
#'
#' @return Updated character flag vector.
#'
#' @export
#'
#' @examples
#' flag <- rep("pass", 5)
#' vals <- c(-2, 0, 15, 26, 32)
#' dqo <- data.frame(
#'   Flag = c("Fail", "Suspect"),
#'   GrMin = c(-1, 0), GrMax = c(30, 25)
#' )
#' utilASRflaggross(flag, vals, dqo)
utilASRflaggross <- function(flag, vals, dqo) {
  susp <- dqo[dqo$Flag == "Suspect", ]
  fail <- dqo[dqo$Flag == "Fail", ]

  if (nrow(susp) > 0) {
    if (!is.na(susp$GrMin)) flag <- utilASRflagupdate(flag, "suspect", vals < susp$GrMin)
    if (!is.na(susp$GrMax)) flag <- utilASRflagupdate(flag, "suspect", vals > susp$GrMax)
  }
  if (nrow(fail) > 0) {
    if (!is.na(fail$GrMin)) flag <- utilASRflagupdate(flag, "fail", vals < fail$GrMin)
    if (!is.na(fail$GrMax)) flag <- utilASRflagupdate(flag, "fail", vals > fail$GrMax)
  }
  flag
}
