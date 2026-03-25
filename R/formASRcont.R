#' Format continuous data
#'
#' @param contdat input data frame
#' @param tz character string of time zone for the date and time columns  See `OlsonNames()` for acceptable time zones.
#'
#' @details This function is used internally within \code{\link{readASRcont}} to format the input data for downstream analysis.  The formatting includes:
#'
#' \itemize{
#'   \item Combine Date and Time columns (separate column format only): The \code{Time} column is parsed flexibly using \code{\link[lubridate:parse_date_time]{lubridate::parse_date_time()}} (accepting 24-hour, 12-hour AM/PM, and Excel-prefixed formats) and reformatted to \code{HH:MM:SS} before being united with \code{Date} into a single \code{DateTime} column, which is then converted to POSIXct with the specified time zone.
#'   \item Convert DateTime to POSIXct (combined column format only): The \code{DateTime} column is parsed flexibly using \code{\link[lubridate:parse_date_time]{lubridate::parse_date_time()}} (accepting 24-hour and 12-hour AM/PM formats) and converted to POSIXct with the specified time zone.
#'   \item Convert non-numeric columns to numeric: Converts all columns except DateTime to numeric if they are not already.
#' }
#'
#' @return A formatted data frame of the continuous data
#'
#' @export
#'
#' @examples
#' contpth <- system.file('extdata/ExampleCont1.xlsx', package = 'AquaSensR')
#'
#' contdat <- utilASRimportcont(contpth)
#'
#' formASRcont(contdat, tz = 'Etc/GMT+5')
formASRcont <- function(contdat, tz) {
  # combine date and time into a single DateTime column, or convert existing
  if ('DateTime' %in% names(contdat)) {
    out <- contdat |>
      dplyr::mutate(
        DateTime = lubridate::parse_date_time(
          DateTime,
          orders = c('ymd IMSp', 'ymd HMS', 'ymd HM'),
          tz = tz
        )
      )
  } else {
    out <- contdat |>
      dplyr::mutate(
        Time = format(
          lubridate::parse_date_time(
            Time,
            orders = c('IMSp', 'HMS', 'HM', 'ymd IMSp', 'ymd HMS', 'ymd HM'),
            quiet = TRUE
          ),
          '%H:%M:%S',
          tz = 'UTC'
        )
      ) |>
      tidyr::unite('DateTime', Date, Time, sep = ' ', remove = TRUE) |>
      dplyr::mutate(
        DateTime = lubridate::ymd_hms(DateTime, tz = tz)
      )
  }

  # convert columns that are not DateTime to numeric if not
  out <- out |>
    dplyr::mutate(
      dplyr::across(
        -c(DateTime),
        ~ if (!is.numeric(.x)) as.numeric(.x) else .x
      )
    )

  return(out)
}
