#' Read flow or stage height data from an external file
#'
#' @param flowpth character string of path to the flow or stage height data
#'   file. Supported formats are Excel (\code{.xlsx}), CSV (\code{.csv}), or
#'   comma-delimited text (\code{.txt}).
#' @param tz character string of time zone for the date and time columns, defaults to Etc/GMT+5 (Eastern time zone, no daylight savings).  See `OlsonNames()` for acceptable time zones.
#' @param runchk logical to run data checks with \code{\link{checkASRflow}}
#'
#' @details
#' This is an optional input to the AquaSensR workflow for a simple external
#' file of flow (cfs) or stage/depth height (ft) data, e.g. from a separate
#' logger not otherwise included in \code{contdat}. The file must have a
#' \code{DateTime} column (or separate \code{Date} and \code{Time} columns)
#' plus exactly one flow or stage height column matching an entry in
#' \code{\link{paramsASR}} from the \code{"Water Level"} or \code{"Flow"}
#' groups (e.g. \code{Sensor_Depth_ft}, \code{Gage_Height_ft},
#' \code{Discharge_cfs}, \code{Flow_cfs}). See \code{\link{checkASRflow}} for
#' the full validation details.
#'
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
#' @returns A formatted flow or stage height data frame
#' @importFrom utils read.csv
#' @export
#'
#' @examples
#'
#' flowpth <- system.file('extdata/ExampleFlow2.xlsx', package = 'AquaSensR')
#' readASRflow(flowpth)
#'
#' flowpth <- system.file('extdata/ExampleFlow1.csv', package = 'AquaSensR')
#' readASRflow(flowpth)
#'
#' flowpth <- system.file('extdata/ExampleFlow2.txt', package = 'AquaSensR')
#' readASRflow(flowpth)
readASRflow <- function(flowpth, tz = 'Etc/GMT+5', runchk = TRUE) {
  ext <- tolower(tools::file_ext(flowpth))

  if (ext %in% c("csv", "txt")) {
    nms <- names(read.csv(flowpth, nrows = 0L, check.names = FALSE))
    col_classes <- ifelse(
      nms %in% c("Date", "Time", "DateTime"),
      "character",
      NA
    )
    flowdat <- read.csv(
      flowpth,
      colClasses = col_classes,
      na.strings = c("NA", "na", ""),
      check.names = FALSE
    ) |>
      dplyr::as_tibble()
  } else {
    flowdat <- utilASRimportcont(flowpth)
  }

  # run checks
  if (runchk) {
    flowdat <- checkASRflow(flowdat)
  }

  # format results
  out <- formASRflow(flowdat, tz = tz)

  return(out)
}
