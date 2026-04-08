#' Flag continuous monitoring data with QC criteria
#'
#' @param contdat data frame returned by \code{\link{readASRcont}}
#' @param dqodat data frame returned by \code{\link{readASRdqo}}
#' @param param character string naming the parameter column to evaluate.
#'   Must match one of the parameter columns present in \code{contdat}.
#'   If \code{param} has no matching entry in \code{dqodat$Parameter} all
#'   flags are returned as \code{"pass"}.
#'
#' @details Applies four independent QC checks to the selected parameter in \code{contdat}, matching thresholds from \code{dqodat} by \code{Parameter}.  Each check produces its own flag
#' (\code{"pass"}, \code{"suspect"}, or \code{"fail"}) so the user can see
#' exactly which criteria fired.  Thresholds are read from the two rows in
#' \code{dqodat} that match the parameter — one with \code{Flag == "Fail"} and
#' one with \code{Flag == "Suspect"}.
#'
#' \strong{Gross range} (\code{gross_flag}) — Observations below \code{GrMin}
#' or above \code{GrMax} in the \code{"Fail"} row are flagged \code{"fail"}.
#' Observations below \code{GrMin} or above \code{GrMax} in the
#' \code{"Suspect"} row (but within the fail bounds) are flagged
#' \code{"suspect"}.
#'
#' \strong{Spike} (\code{spike_flag}) — The absolute difference between
#' consecutive observations is compared to \code{Spike} in the \code{"Fail"}
#' row (fail) and \code{Spike} in the \code{"Suspect"} row (suspect).  The
#' second observation in the jump is flagged.
#'
#' \strong{Rate of change} (\code{roc_flag}) — For each observation the
#' standard deviation of all raw values within a trailing \code{RoCHours}-hour
#' window is multiplied by \code{RoCStDv} to produce a threshold.  The
#' observation is flagged \code{"suspect"} if its absolute lag-1 difference
#' exceeds that threshold.  Requires at least 2 values in the window;
#' otherwise \code{"pass"}.  Note that this check only produces
#' \code{"suspect"} flags, not \code{"fail"} flags.  \code{RoCStDv} and
#' \code{RoCHours} are read from the \code{"Suspect"} row only.
#'
#' \strong{Flatline} (\code{flat_flag}) — Counts consecutive observations
#' where the absolute step from the previous observation is within
#' \code{FlatDelta} units.  Observations whose run length reaches \code{FlatN}
#' are flagged, using the \code{"Suspect"} row thresholds for suspect and the
#' \code{"Fail"} row thresholds for fail.
#'
#' Data are sorted by \code{DateTime} before processing.
#'
#' Underlying concepts and code for this function borrow heavily from those
#' in the [ContDataQC](https://leppott.github.io/ContDataQC) package.  Any
#' credit for the approach should go to the
#' [ContDataQC authors](https://leppott.github.io/ContDataQC/authors.html#citation).
#'
#' @return A data frame with columns \code{DateTime}, the
#'   selected parameter, and four flag columns: \code{gross_flag},
#'   \code{spike_flag}, \code{roc_flag}, and \code{flat_flag}.
#'
#' @export
#'
#' @examples
#' contpth <- system.file('extdata/ExampleCont1.xlsx', package = 'AquaSensR')
#' dqopth <- system.file('extdata/ExampleDQO.xlsx', package = 'AquaSensR')
#'
#' contdat <- readASRcont(contpth, runchk = FALSE)
#' dqodat <- readASRdqo(dqopth, runchk = FALSE)
#'
#' utilASRflag(contdat, dqodat, param = 'Water_Temp_C')
utilASRflag <- function(contdat, dqodat, param) {
  # validate param
  parms <- paramsASR$Parameter
  if (!param %in% parms) {
    stop(
      "'",
      param,
      "' is not a recognised parameter. See paramsASR$Parameter.",
      call. = FALSE
    )
  }
  if (!param %in% names(contdat)) {
    stop("'", param, "' column not found in contdat.", call. = FALSE)
  }
  # sort by DateTime so consecutive checks are meaningful
  dat <- contdat[order(contdat$DateTime), ]

  # build output skeleton
  out <- dat[, c("DateTime", param)]
  out$gross_flag <- "pass"
  out$spike_flag <- "pass"
  out$roc_flag <- "pass"
  out$flat_flag <- "pass"

  dqo_rows <- dqodat[dqodat$Parameter == param, ]

  vals <- dat[[param]]
  datetimes <- dat$DateTime
  init <- rep("pass", nrow(dat))

  out$gross_flag <- utilASRflaggross(init, vals, dqo_rows)
  out$spike_flag <- utilASRflagspike(init, vals, dqo_rows)
  out$roc_flag <- utilASRflagroc(init, vals, datetimes, dqo_rows)
  out$flat_flag <- utilASRflagflatline(init, vals, dqo_rows)

  out
}
