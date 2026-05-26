#' Retrieve USGS time series data for overlay in editASRflag
#'
#' Downloads unit-value (continuous) data from the USGS Water Data API
#' for a given site and parameter over a specified date range.  The result
#' is a two-column data frame compatible with the \code{overlay} argument of
#' \code{\link{anlzASRflag}} and the USGS Overlay feature in
#' \code{\link{editASRflag}}.
#'
#' @param site Character. USGS site number (typically 8 digits,
#'   e.g. \code{"01099500"}).  Find site numbers using the NWIS Mapper at
#'   \url{https://apps.usgs.gov/nwismapper}.
#' @param pcode Character. Five-digit USGS parameter code.  Common codes:
#'   \describe{
#'     \item{\code{"00060"}}{Discharge / streamflow (ft\eqn{^3}/s)}
#'     \item{\code{"00065"}}{Gage height (ft)}
#'     \item{\code{"00045"}}{Precipitation (in)}
#'   }
#' @param start,end Date range as \code{Date} objects or \code{"YYYY-MM-DD"}
#'   character strings.
#'
#' @return A two-column data frame with columns \code{DateTime} (POSIXct, UTC)
#'   and a second column whose name is a human-readable label combining the
#'   parameter description and site number (e.g.
#'   \code{"Streamflow (ft\u00b3/s) [01099500]"}).  The data frame carries a
#'   \code{"site_name"} attribute containing the station name, used by
#'   \code{\link{editASRflag}} for the status message.
#'
#' @details
#' Data are fetched via \code{dataRetrieval::read_waterdata_continuous()},
#' which targets the modern USGS Water Data API
#' (\url{https://api.waterdata.usgs.gov}).  The \code{DateTime} column is
#' returned in UTC by the API so no timezone conversion is needed.
#'
#' The station name shown in the \code{\link{editASRflag}} status line is
#' retrieved with a second lightweight call to
#' \code{dataRetrieval::read_waterdata_monitoring_location()}.  If that call
#' fails the site number is used as a fallback.
#'
#' An error is raised if the site does not record the requested parameter, if
#' the date range returns no observations, or if the API is unreachable.
#'
#' @examples
#' \dontrun{
#' # Fetch streamflow for the Concord R Below R Meadow Brook, at Lowell, MA
#' # 2024-01-01 to 2024-01-02
#' flow <- readASRusgs("01099500", "00060", "2024-01-01", "2024-01-02")
#' head(flow)
#' }
#'
#' @export
readASRusgs <- function(site, pcode, start, end) {
  site <- trimws(as.character(site))
  pcode <- trimws(as.character(pcode))

  if (!nzchar(site) || !grepl("^[0-9]+$", site)) {
    stop("'site' must be a numeric USGS site number (digits only).")
  }
  if (!grepl("^[0-9]{5}$", pcode)) {
    stop("'pcode' must be a 5-digit USGS parameter code (e.g. \"00060\").")
  }

  # Human-readable labels for common parameter codes.
  pcode_labels <- c(
    "00060" = "Streamflow (ft\u00b3/s)",
    "00045" = "Precipitation (in)",
    "00065" = "Gage height (ft)"
  )

  raw <- dataRetrieval::read_waterdata_continuous(
    monitoring_location_id = paste0("USGS-", site),
    parameter_code = pcode,
    time = c(as.character(start), as.character(end))
  )

  if (nrow(raw) == 0L) {
    stop(
      "No data returned for site ",
      site,
      " (parameter ",
      pcode,
      ") between ",
      start,
      " and ",
      end,
      "."
    )
  }

  # Build display label used as column name and y-axis label in anlzASRflag().
  label <- if (pcode %in% names(pcode_labels)) {
    pcode_labels[[pcode]]
  } else {
    paste0("Parameter ", pcode)
  }
  col_name <- paste0(label, " [", site, "]")

  # The new API returns `time` (POSIXct, UTC) and `value` (character).
  out <- data.frame(
    DateTime = raw$time,
    v = suppressWarnings(as.numeric(raw$value)),
    stringsAsFactors = FALSE
  )
  names(out)[2L] <- col_name

  # Attach station name for the editASRflag status message.
  # A lightweight monitoring-location lookup is used; falls back to site number.
  site_name <- tryCatch(
    {
      meta <- dataRetrieval::read_waterdata_monitoring_location(
        monitoring_location_id = paste0("USGS-", site)
      )
      nm <- meta$monitoring_location_name[1L]
      if (length(nm) > 0L && !is.na(nm)) nm else site
    },
    error = function(e) site
  )
  attr(out, "site_name") <- site_name

  out
}
