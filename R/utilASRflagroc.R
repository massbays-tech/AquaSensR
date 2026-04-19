#' Apply rate-of-change QC flag
#'
#' @param flag character vector of current flag values (\code{"pass"},
#'   \code{"suspect"}, or \code{"fail"}).
#' @param vals numeric vector of observed values, the same length as
#'   \code{flag}.
#' @param datetimes POSIXct vector of observation timestamps, the same length
#'   as \code{flag}.
#' @param dqo two-row data frame from data quality objectives for the parameter
#'   being checked, containing one row where \code{Flag == "Fail"} and one
#'   where \code{Flag == "Suspect"}.  The \code{"Suspect"} row's numeric
#'   columns \code{RoCStDv} (SD multiplier) and \code{RoCHours} (trailing window
#'   width in hours) control the check.  If either column is \code{NA} in the
#'   \code{"Suspect"} row the check is skipped.  Rate-of-change thresholds are
#'   not applied to \code{"Fail"} flags.
#'
#' @details For each observation the standard deviation of all raw values
#'   within a trailing \code{RoCHours}-hour window ending just before (and
#'   excluding) that observation is multiplied by \code{RoCStDv} to produce a
#'   threshold.
#'   The observation is flagged \code{"suspect"} if the absolute lag-1
#'   difference exceeds that threshold.  At least 2 values must fall within
#'   the window to compute the standard deviation; otherwise the observation
#'   is skipped.  This check only produces \code{"suspect"} flags; it does
#'   not produce \code{"fail"} flags.
#'
#' @return Updated character flag vector.
#'
#' @export
#'
#' @examples
#' flag <- rep("pass", 6)
#' vals <- c(10, 10.2, 10.1, 10.3, 15.0, 10.2)
#' datetimes <- as.POSIXct("2024-01-01") + seq(0, 5) * 900  # 15-min intervals
#' dqo <- data.frame(Flag = c("Fail", "Suspect"), RoCStDv = c(NA, 3), RoCHours = c(NA, 2))
#' utilASRflagroc(flag, vals, datetimes, dqo)
utilASRflagroc <- function(flag, vals, datetimes, dqo) {
  susp <- dqo[dqo$Flag == "Suspect", ]
  if (nrow(susp) == 0) {
    return(flag)
  }
  if (!("RoCStDv" %in% names(susp)) || is.na(susp$RoCStDv)) {
    return(flag)
  }
  if (!("RoCHours" %in% names(susp)) || is.na(susp$RoCHours)) {
    return(flag)
  }

  diffs <- c(NA_real_, diff(vals)) # signed lag-1 differences; first is NA
  times_num <- as.numeric(datetimes)
  win_sec <- susp$RoCHours * 3600 # trailing window width in seconds

  roc_sd <- vapply(
    seq_along(vals),
    function(i) {
      if (is.na(diffs[i])) {
        return(NA_real_)
      }
      in_win <- times_num < times_num[i] &
        (times_num[i] - times_num) <= win_sec
      v <- vals[in_win & !is.na(vals)]
      if (length(v) < 2L) NA_real_ else stats::sd(v)
    },
    numeric(1L)
  )
  is_roc <- !is.na(diffs) &
    !is.na(roc_sd) &
    abs(diffs) > roc_sd * susp$RoCStDv
  utilASRflagupdate(flag, "suspect", is_roc)
}
