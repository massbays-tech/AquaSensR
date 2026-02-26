#' Apply spike QC flag
#'
#' @param flag character vector of current flag values (\code{"pass"},
#'   \code{"suspect"}, or \code{"fail"}).
#' @param vals numeric vector of observed values, the same length as
#'   \code{flag}.
#' @param meta single-row data frame of metadata for the parameter being
#'   checked.  Optional numeric columns \code{SpikeSuspect} and
#'   \code{SpikeFail} define the absolute-difference thresholds.  Either or
#'   both columns may be absent or \code{NA}, in which case that level of
#'   check is skipped.
#'
#' @details The absolute difference between each observation and the preceding
#'   one is computed.  If the difference is greater than or equal to
#'   \code{SpikeSuspect} the observation is flagged \code{"suspect"};
#'   greater than or equal to \code{SpikeFail} flags \code{"fail"}.
#'   The first observation always receives \code{NA} for the difference and
#'   is not flagged by this check.
#'
#' @return Updated character flag vector.
#'
#' @export
#'
#' @examples
#' flag <- rep("pass", 5)
#' vals <- c(10, 10.5, 14, 10.2, 10.3)
#' meta <- data.frame(SpikeSuspect = 1.5, SpikeFail = 2.0)
#' utilASRflagspike(flag, vals, meta)
utilASRflagspike <- function(flag, vals, meta) {
  diffs <- c(NA_real_, abs(diff(vals)))
  if ("SpikeSuspect" %in% names(meta) && !is.na(meta$SpikeSuspect)) {
    flag <- utilASRflagupdate(
      flag,
      "suspect",
      diffs >= meta$SpikeSuspect
    )
  }
  if ("SpikeFail" %in% names(meta) && !is.na(meta$SpikeFail)) {
    flag <- utilASRflagupdate(flag, "fail", diffs >= meta$SpikeFail)
  }
  flag
}
