#' Apply rate-of-change QC flag
#'
#' @param flag character vector of current flag values (\code{"pass"},
#'   \code{"suspect"}, or \code{"fail"}).
#' @param vals numeric vector of observed values, the same length as
#'   \code{flag}.
#' @param datetimes POSIXct vector of observation timestamps, the same length
#'   as \code{flag}.
#' @param meta single-row data frame of metadata for the parameter being
#'   checked.  Optional numeric columns \code{RoCStdev} (number of standard
#'   deviations) and \code{RoCHours} (full window width in hours) control the
#'   check.  If either column is absent or \code{NA} the check is skipped.
#'
#' @details For each observation the absolute difference from the previous
#'   observation is compared to \code{RoCStdev} × the standard deviation of
#'   all absolute differences within a \code{RoCHours}-hour window centered
#'   on that observation.  The observation is flagged \code{"suspect"} if its
#'   difference exceeds this threshold.  At least 3 differences must fall
#'   within the window; otherwise the observation is skipped.  This check
#'   only produces \code{"suspect"} flags; it does not produce \code{"fail"}
#'   flags.
#'
#' @return Updated character flag vector.
#'
#' @export
#'
#' @examples
#' flag <- rep("pass", 6)
#' vals <- c(10, 10.2, 10.1, 10.3, 15.0, 10.2)
#' datetimes <- as.POSIXct("2024-01-01") + seq(0, 5) * 900  # 15-min intervals
#' meta <- data.frame(RoCStdev = 3, RoCHours = 2)
#' utilASRflagroc(flag, vals, datetimes, meta)
utilASRflagroc <- function(flag, vals, datetimes, meta) {
  if (!("RoCStdev" %in% names(meta)) || is.na(meta$RoCStdev)) {
    return(flag)
  }
  if (!("RoCHours" %in% names(meta)) || is.na(meta$RoCHours)) {
    return(flag)
  }

  diffs <- c(NA_real_, abs(diff(vals)))
  times_num <- as.numeric(datetimes)
  half_win <- meta$RoCHours * 1800 # half of full window in seconds

  roc_sd <- vapply(
    seq_along(vals),
    function(i) {
      if (is.na(diffs[i])) {
        return(NA_real_)
      }
      in_win <- abs(times_num - times_num[i]) <= half_win
      d <- diffs[in_win & !is.na(diffs)]
      if (length(d) < 3L) NA_real_ else stats::sd(d)
    },
    numeric(1L)
  )

  is_roc <- !is.na(diffs) &
    !is.na(roc_sd) &
    roc_sd > 0 &
    diffs >= meta$RoCStdev * roc_sd
  utilASRflagupdategupdate(flag, "suspect", is_roc)
}
