#' Apply flatline QC flag
#'
#' @param flag character vector of current flag values (\code{"pass"},
#'   \code{"suspect"}, or \code{"fail"}).
#' @param vals numeric vector of observed values, the same length as
#'   \code{flag}.
#' @param dqo two-row data frame of data quality objectives for the parameter
#'   being checked, containing one row where \code{Flag == "Fail"} and one
#'   where \code{Flag == "Suspect"}.  Optional numeric columns \code{FlatN}
#'   and \code{FlatDelta} define the run-length and tolerance thresholds for
#'   each severity level.  Either row may have \code{NA} for these columns,
#'   in which case that level of check is skipped.
#'
#' @details Uses \code{\link{utilASRflagrleflat}} to compute consecutive run lengths.
#'   A run extends as long as the range (max minus min) of all values in the
#'   run so far is strictly less than \code{FlatDelta}.  An observation is
#'   flagged \code{"suspect"} when its run length reaches \code{FlatN} (using
#'   \code{FlatDelta} from the \code{"Suspect"} row), and \code{"fail"} when
#'   its run length reaches \code{FlatN} (using \code{FlatDelta} from the
#'   \code{"Fail"} row).
#'
#' @return Updated character flag vector.
#'
#' @export
#'
#' @examples
#' flag <- rep("pass", 8)
#' vals <- c(10, 10, 10.005, 10.002, 10.001, 10.003, 12, 12)
#' dqo <- data.frame(
#'   Flag = c("Fail", "Suspect"),
#'   FlatN = c(5, 3), FlatDelta = c(0.01, 0.01)
#' )
#' utilASRflagflatline(flag, vals, dqo)
utilASRflagflatline <- function(flag, vals, dqo) {
  susp <- dqo[dqo$Flag == "Suspect", ]
  fail <- dqo[dqo$Flag == "Fail", ]

  has_susp <- nrow(susp) > 0 &&
    "FlatN" %in% names(dqo) &&
    !is.na(susp$FlatN) &&
    "FlatDelta" %in% names(dqo) &&
    !is.na(susp$FlatDelta)
  has_fail <- nrow(fail) > 0 &&
    "FlatN" %in% names(dqo) &&
    !is.na(fail$FlatN) &&
    "FlatDelta" %in% names(dqo) &&
    !is.na(fail$FlatDelta)

  if (has_susp) {
    rl <- utilASRflagrleflat(vals, susp$FlatDelta)
    flag <- utilASRflagupdate(flag, "suspect", rl >= susp$FlatN)
  }
  if (has_fail) {
    rl <- utilASRflagrleflat(vals, fail$FlatDelta)
    flag <- utilASRflagupdate(flag, "fail", rl >= fail$FlatN)
  }
  flag
}
