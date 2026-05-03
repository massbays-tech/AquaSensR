#' Read continuous monitoring data from an external file
#'
#' @param contpth character string of path to the continuous data file.
#'   Supported formats are Excel (\code{.xlsx}), CSV (\code{.csv}), or
#'   comma-delimited text (\code{.txt}).
#' @param tz character string of time zone for the date and time columns, defaults to Etc/GMT+5 (Eastern time zone, no daylight savings).  See `OlsonNames()` for acceptable time zones.
#' @param runchk logical to run data checks with \code{\link{checkASRcont}}
#'
#' @details
#' For Excel files the file is imported via \code{\link{utilASRimportcont}},
#' which forces \code{Date}, \code{Time}, and \code{DateTime} columns to
#' character and converts Excel numeric serial representations to
#' human-readable strings.  Excel files must not be open in another program
#' (e.g. Excel, LibreOffice) when this function is run.
#'
#' For CSV and comma-delimited text files the file is read with
#' \code{read.csv}, with \code{Date}, \code{Time}, and \code{DateTime} columns
#' forced to character and all other columns type-guessed.  No lock-file check
#' is performed for these formats.
#'
#' Always verify the correct time zone for your data.  If your data are in a different time zone than Etc/GMT+5 (default), specify the correct time zone in the \code{tz} argument.
#'
#' @returns A formatted continuous monitoring data frame that can be used for downstream analysis
#' @export
#'
#' @examples
#'
#' contpth <- system.file('extdata/ExampleCont2.xlsx', package = 'AquaSensR')
#' readASRcont(contpth)
#'
#' contpth <- system.file('extdata/ExampleCont1.csv', package = 'AquaSensR')
#' readASRcont(contpth)
#'
#' contpth <- system.file('extdata/ExampleCont2.txt', package = 'AquaSensR')
#' readASRcont(contpth)
readASRcont <- function(contpth, tz = 'Etc/GMT+5', runchk = TRUE) {
  ext <- tolower(tools::file_ext(contpth))

  if (ext %in% c("csv", "txt")) {
    nms <- names(read.csv(contpth, nrows = 0L, check.names = FALSE))
    col_classes <- ifelse(
      nms %in% c("Date", "Time", "DateTime"),
      "character",
      NA
    )
    contdat <- read.csv(
      contpth,
      colClasses = col_classes,
      na.strings = c("NA", "na", ""),
      check.names = FALSE
    ) |>
      dplyr::as_tibble()
  } else {
    contdat <- utilASRimportcont(contpth)
  }

  # run checks
  if (runchk) {
    contdat <- checkASRcont(contdat)
  }

  # format results
  out <- formASRcont(contdat, tz = tz)

  return(out)
}
