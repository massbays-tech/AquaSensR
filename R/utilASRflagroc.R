#' Apply rate-of-change QC flag
#'
#' @param flag character vector of current flag values (\code{"pass"},
#'   \code{"suspect"}, or \code{"fail"}).
#' @param vals numeric vector of observed values, the same length as
#'   \code{flag}.
#' @param datetimes POSIXct vector of observation timestamps, the same length
#'   as \code{flag}.
#' @param meta single-row data frame of metadata for the parameter being
#'   checked.  Optional numeric columns \code{RoCN} (SD multiplier) and
#'   \code{RoCHours} (trailing window width in hours) control the check.  If
#'   either column is absent or \code{NA} the check is skipped.
#'
#' @details For each observation the standard deviation of all raw values
#'   within a trailing \code{RoCHours}-hour window ending at (and including)
#'   that observation is multiplied by \code{RoCN} to produce a threshold.
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
#' meta <- data.frame(RoCN = 3, RoCHours = 2)
#' utilASRflagroc(flag, vals, datetimes, meta)
utilASRflagroc <- function(flag, vals, datetimes, meta) {
  if (!("RoCN" %in% names(meta)) || is.na(meta$RoCN)) {
    return(flag)
  }
  if (!("RoCHours" %in% names(meta)) || is.na(meta$RoCHours)) {
    return(flag)
  }

  diffs <- c(NA_real_, diff(vals))  # signed lag-1 differences; first is NA
  times_num <- as.numeric(datetimes)
  win_sec <- meta$RoCHours * 3600  # trailing window width in seconds

  roc_sd <- vapply(
    seq_along(vals),
    function(i) {
      if (is.na(diffs[i])) {
        return(NA_real_)
      }
      in_win <- times_num <= times_num[i] & (times_num[i] - times_num) <= win_sec
      v <- vals[in_win & !is.na(vals)]
      if (length(v) < 2L) NA_real_ else stats::sd(v)
    },
    numeric(1L)
  )

  is_roc <- !is.na(diffs) &
    !is.na(roc_sd) &
    abs(diffs) > roc_sd * meta$RoCN
  utilASRflagupdate(flag, "suspect", is_roc)
}
