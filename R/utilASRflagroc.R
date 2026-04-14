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
#'   where \code{Flag == "Suspect"}.  Each row's numeric columns \code{RoCStDv}
#'   (SD multiplier) and \code{RoCHours} (trailing window width in hours)
#'   control the check independently.  If either column is \code{NA} for a
#'   given row that severity level is skipped entirely.
#'
#' @details For each observation the standard deviation of all raw values
#'   within a trailing \code{RoCHours}-hour window ending at (and including)
#'   that observation is multiplied by \code{RoCStDv} to produce a threshold.
#'   The observation is flagged if the absolute lag-1 difference exceeds that
#'   threshold — \code{"suspect"} using the \code{"Suspect"} row thresholds
#'   and \code{"fail"} using the \code{"Fail"} row thresholds.  At least 2
#'   values must fall within the window to compute the standard deviation;
#'   otherwise the observation is skipped.  Flags are only ever upgraded (pass
#'   -> suspect -> fail), never downgraded.
#'
#' @return Updated character flag vector.
#'
#' @export
#'
#' @examples
#' flag <- rep("pass", 6)
#' vals <- c(10, 10.2, 10.1, 10.3, 15.0, 10.2)
#' datetimes <- as.POSIXct("2024-01-01") + seq(0, 5) * 900  # 15-min intervals
#' dqo <- data.frame(Flag = c("Fail", "Suspect"), RoCStDv = c(2, 3), RoCHours = c(2, 2))
#' utilASRflagroc(flag, vals, datetimes, dqo)
utilASRflagroc <- function(flag, vals, datetimes, dqo) {
  susp <- dqo[dqo$Flag == "Suspect", ]
  fail <- dqo[dqo$Flag == "Fail", ]

  diffs <- c(NA_real_, diff(vals)) # signed lag-1 differences; first is NA
  times_num <- as.numeric(datetimes)

  roc_is_flagged <- function(roc_stdv, roc_hours) {
    win_sec <- roc_hours * 3600
    roc_sd <- vapply(
      seq_along(vals),
      function(i) {
        if (is.na(diffs[i])) {
          return(NA_real_)
        }
        in_win <- times_num <= times_num[i] &
          (times_num[i] - times_num) <= win_sec
        v <- vals[in_win & !is.na(vals)]
        if (length(v) < 2L) NA_real_ else stats::sd(v)
      },
      numeric(1L)
    )
    !is.na(diffs) & !is.na(roc_sd) & abs(diffs) > roc_sd * roc_stdv
  }

  if (nrow(susp) > 0 &&
      "RoCStDv" %in% names(susp) && !is.na(susp$RoCStDv) &&
      "RoCHours" %in% names(susp) && !is.na(susp$RoCHours)) {
    flag <- utilASRflagupdate(flag, "suspect", roc_is_flagged(susp$RoCStDv, susp$RoCHours))
  }

  if (nrow(fail) > 0 &&
      "RoCStDv" %in% names(fail) && !is.na(fail$RoCStDv) &&
      "RoCHours" %in% names(fail) && !is.na(fail$RoCHours)) {
    flag <- utilASRflagupdate(flag, "fail", roc_is_flagged(fail$RoCStDv, fail$RoCHours))
  }

  flag
}
