#' Flag continuous monitoring data with QC criteria
#'
#' @param contdat data frame returned by \code{\link{readASRcont}}
#' @param metadat data frame returned by \code{\link{readASRmeta}}
#' @param param character string naming the parameter column to evaluate.
#'   Must match one of the parameter columns present in \code{contdat} and
#'   one of the entries in the \code{Parameter} column of \code{metadat}.
#'
#' @details Applies four independent QC checks to the selected parameter in \code{contdat}, matching thresholds from \code{metadat} by \code{Parameter}.  Each check produces its own flag
#' (\code{"pass"}, \code{"suspect"}, or \code{"fail"}) so the user can see
#' exactly which criteria fired.  If multiple metadata rows match a given
#' parameter the first row is used and a warning is issued.
#'
#' \strong{Gross range} (\code{gross_flag}) — Observations below \code{GrMinFail}
#' or above \code{GrMaxFail} are flagged \code{"fail"}.  Observations below
#' \code{GrMinSuspect} or above \code{GrMaxSuspect} (but within the fail bounds) are
#' flagged \code{"suspect"}.
#'
#' \strong{Spike} (\code{spike_flag}) — The absolute difference between
#' consecutive observations is compared to \code{SpikeFail} (fail) and
#' \code{SpikeSuspect} (suspect).  The second observation in the jump is
#' flagged.
#'
#' \strong{Rate of change} (\code{roc_flag}) — For each observation the
#' standard deviation of all raw values within a trailing \code{RoCHours}-hour
#' window is multiplied by \code{RoCN} to produce a threshold.  The
#' observation is flagged \code{"suspect"} if its absolute lag-1 difference
#' exceeds that threshold.  Requires at least 2 values in the window;
#' otherwise \code{"pass"}.  Note that this check only produces
#' \code{"suspect"} flags, not \code{"fail"} flags.
#'
#' \strong{Flatline} (\code{flat_flag}) — Counts consecutive observations
#' where the absolute step from the previous observation is within
#' \code{FlatSuspectDelta} (or \code{FlatFailDelta}) units.  Observations
#' whose run length reaches \code{FlatSuspectN} (or \code{FlatFailN}) are
#' flagged.
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
#' metapth <- system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR')
#'
#' contdat <- readASRcont(contpth, tz = 'Etc/GMT+5', runchk = FALSE)
#' metadat <- readASRmeta(metapth, runchk = FALSE)
#'
#' utilASRflag(contdat, metadat, param = 'Water Temp_C')
utilASRflag <- function(contdat, metadat, param) {
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
  if (!param %in% metadat$Parameter) {
    stop("'", param, "' not found in metadat$Parameter.", call. = FALSE)
  }

  # sort by DateTime so consecutive checks are meaningful
  dat <- contdat[order(contdat$DateTime), ]

  # build output skeleton
  out <- dat[, c("DateTime", param)]
  out$gross_flag <- "pass"
  out$spike_flag <- "pass"
  out$roc_flag <- "pass"
  out$flat_flag <- "pass"

  meta_rows <- metadat[metadat$Parameter == param, ]

  if (nrow(meta_rows) > 1L) {
    warning(
      "Multiple metadata rows for parameter '",
      param,
      "'. Using the first row.",
      call. = FALSE
    )
    meta_rows <- meta_rows[1L, ]
  }

  vals <- dat[[param]]
  datetimes <- dat$DateTime
  init <- rep("pass", nrow(dat))

  out$gross_flag <- utilASRflaggross(init, vals, meta_rows)
  out$spike_flag <- utilASRflagspike(init, vals, meta_rows)
  out$roc_flag <- utilASRflagroc(init, vals, datetimes, meta_rows)
  out$flat_flag <- utilASRflagflatline(init, vals, meta_rows)

  out
}
