#' Read continuous monitoring data from an external file
#'
#' @param contpth character string of path to the continuous data file
#' @param tz character string of time zone for the date and time columns.  See `OlsonNames()` for acceptable time zones.
#' @param runchk logical to run data checks with \code{\link{checkASRcont}}
#'
#' @details
#' The file is imported via \code{\link{utilASRimportcont}}, which forces
#' \code{Date}, \code{Time}, and \code{DateTime} columns to character and
#' converts Excel numeric serial representations to human-readable strings
#' before checks are run.
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
  contdat <- utilASRimportcont(contpth)

  # run checks
  if (runchk) {
    contdat <- checkASRcont(contdat)
  }

  # format results
  out <- formASRcont(contdat, tz = tz)

  return(out)
}
