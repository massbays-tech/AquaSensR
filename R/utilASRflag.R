#' Flag continuous monitoring data with QC criteria
#'
#' @param contdat data frame returned by \code{\link{readASRcont}}
#' @param metadat data frame returned by \code{\link{readASRmeta}}
#' @param param character string naming the parameter column to evaluate.
#'   Must match one of the parameter columns present in \code{contdat} and
#'   one of the entries in the \code{Parameter} column of \code{metadat}.
#'
#' @details Applies four independent QC checks to the selected parameter for
#' every site in \code{contdat}, matching thresholds from \code{metadat} by
#' \code{Site} and \code{Parameter}.  Each check produces its own flag
#' (\code{"pass"}, \code{"suspect"}, or \code{"fail"}) so the caller can see
#' exactly which criteria fired.  If multiple metadata rows match a given
#' site/parameter pair the first row is used and a warning is issued.
#'
#' \strong{Gross range} (\code{gross_flag}) — Observations below \code{Min}
#' or above \code{Max} are flagged \code{"fail"}.  Observations below
#' \code{Tlower} or above \code{Tupper} (but within the fail bounds) are
#' flagged \code{"suspect"}.
#'
#' \strong{Spike} (\code{spike_flag}) — The absolute difference between
#' consecutive observations is compared to \code{SpikeFail} (fail) and
#' \code{SpikeSuspect} (suspect).  The second observation in the jump is
#' flagged.
#'
#' \strong{Rate of change} (\code{roc_flag}) — For each observation the
#' absolute difference from the previous observation is compared to
#' \code{RoCStdev} standard deviations of all absolute differences within a
#' rolling \code{RoCHours}-hour window centered on that observation.
#' Observations exceeding the threshold are flagged \code{"suspect"}.
#' Requires at least 3 differences in the window; otherwise \code{"pass"}.
#'
#' \strong{Flatline} (\code{flat_flag}) — Counts consecutive observations
#' where the absolute step from the previous observation is within
#' \code{FlatSuspectDelta} (or \code{FlatFailDelta}) units.  Observations
#' whose run length reaches \code{FlatSuspectN} (or \code{FlatFailN}) are
#' flagged.
#'
#' Data are sorted by \code{Site} and \code{DateTime} before processing.
#'
#' @return A data frame with columns \code{Site}, \code{DateTime}, the
#'   selected parameter, and four flag columns: \code{gross_flag},
#'   \code{spike_flag}, \code{roc_flag}, and \code{flat_flag}.
#'
#' @export
#'
#' @examples
#' contpth <- system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR')
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

  # sort by Site then DateTime so consecutive checks are meaningful
  dat <- contdat[order(contdat$Site, contdat$DateTime), ]

  # build output skeleton
  out <- dat[, c("Site", "DateTime", param)]
  out$gross_flag <- "pass"
  out$spike_flag <- "pass"
  out$roc_flag <- "pass"
  out$flat_flag <- "pass"

  for (site in unique(dat$Site)) {
    site_idx <- which(dat$Site == site)

    meta_rows <- metadat[metadat$Site == site & metadat$Parameter == param, ]

    if (nrow(meta_rows) == 0L) {
      next
    }

    if (nrow(meta_rows) > 1L) {
      warning(
        "Multiple metadata rows for site '",
        site,
        "' parameter '",
        param,
        "'. Using the first row.",
        call. = FALSE
      )
      meta_rows <- meta_rows[1L, ]
    }

    vals <- dat[[param]][site_idx]
    datetimes <- dat$DateTime[site_idx]
    init <- rep("pass", length(site_idx))

    out$gross_flag[site_idx] <- utilASRflaggross(init, vals, meta_rows)
    out$spike_flag[site_idx] <- utilASRflagspike(init, vals, meta_rows)
    out$roc_flag[site_idx] <- utilASRflagroc(init, vals, datetimes, meta_rows)
    out$flat_flag[site_idx] <- utilASRflagflatline(init, vals, meta_rows)
  }

  out
}
