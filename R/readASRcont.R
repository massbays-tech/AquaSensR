#' Read continuous monitoring data from an external file
#'
#' @param contpth character string of path to the continuous data file
#' @param tz character string of time zone for the date and time columns  See `OlsonNames()` for acceptable time zones.
#' @param runchk logical to run data checks with \code{\link{checkASRcont}}
#'
#' @returns A formatted continuous monitoring data frame that can be used for downstream analysis
#' @export
#'
#' @examples
#'
#' contpth <- system.file('extdata/ExampleCont2.xlsx', package = 'AquaSensR')
#'
#' readASRcont(contpth, tz = 'Etc/GMT+5')
readASRcont <- function(contpth, tz, runchk = TRUE) {
  contdat <- suppressWarnings(readxl::read_excel(
    contpth,
    na = c('NA', 'na', ''),
    guess_max = Inf
  )) |>
    dplyr::mutate(dplyr::across(
      dplyr::any_of(c("DateTime", "Time")) & dplyr::where(~ inherits(.x, "POSIXct")),
      function(x) format(x, '%Y-%m-%d %H:%M:%S')
    )) |>
    dplyr::mutate(dplyr::across(
      dplyr::any_of("Date") & dplyr::where(~ inherits(.x, c("POSIXct", "Date"))),
      function(x) format(x, '%Y-%m-%d')
    ))

  # run checks
  if (runchk) {
    contdat <- checkASRcont(contdat)
  }

  # format results
  out <- formASRcont(contdat, tz = tz)

  return(out)
}
