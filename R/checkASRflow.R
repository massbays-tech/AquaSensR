#' Check flow or stage height data
#'
#' @param flowdat input data frame for results
#'
#' @details This function is used internally within \code{\link{readASRflow}} to run several checks on the input data to verify correct formatting before downstream analysis.
#'
#' The input data can use either of two formats:
#' \itemize{
#'  \item \strong{Separate columns}: \code{Date}, \code{Time}, and exactly one flow or stage height column
#'  \item \strong{Combined column}: \code{DateTime}, and exactly one flow or stage height column
#' }
#'
#' Unlike \code{\link{checkASRcont}}, which allows any number of parameter columns from the full \code{\link{paramsASR}} list, \code{checkASRflow} restricts the accepted value column to entries in \code{\link{paramsASR}} whose \code{Parameter Group} is \code{"Water Level"} or \code{"Flow"} (e.g. \code{Sensor_Depth_ft}, \code{Gage_Height_ft}, \code{Discharge_cfs}, \code{Flow_cfs}), and requires exactly one such column.  If your logger reports paired stage and discharge, split the export into two single-column files (or use \code{\link{readASRcont}}/\code{\link{checkASRcont}} instead, which allow multiple parameter columns).
#'
#' The following checks are made:
#' \itemize{
#'  \item Column names: Should include only Date, Time, DateTime, and exactly one flow or stage height column that matches the \code{Parameter} column in \code{\link{paramsASR}} for the \code{"Water Level"} or \code{"Flow"} groups
#'  \item Required columns are present: Either Date + Time or DateTime are required for downstream analysis
#'  \item Exactly one flow or stage height column is present: Zero or more than one matching column is an error
#'  \item Date format (separate columns only): Should be parseable by \code{\link[lubridate:parse_date_time]{lubridate::parse_date_time()}} using year-first (\code{"2024-06-01"}), month-first (\code{"06/01/2024"}), or day-first (\code{"01/06/2024"}) formats
#'  \item Time format (separate columns only): Should be parseable by \code{\link[lubridate:parse_date_time]{lubridate::parse_date_time()}} using 24-hour (\code{"16:30:33"}), 12-hour AM/PM (\code{"4:30:33 PM"}), or Excel-prefixed (\code{"1899-12-31 16:30:33"}) formats
#'  \item DateTime format (combined column only): Should be parseable by \code{\link[lubridate:parse_date_time]{lubridate::parse_date_time()}} using year-first, month-first, or day-first date order combined with 24-hour or 12-hour AM/PM time (e.g. \code{"2024-06-01 16:30:33"}, \code{"06/01/2024 16:30:33"}, or \code{"2024-06-01 4:30:33 PM"})
#'  \item Missing values: Missing values in the flow or stage height column produce a warning rather than an error, since cleaned data files may legitimately contain \code{NA} values.  Missing values in \code{DateTime}, \code{Date}, or \code{Time} columns still cause an error.
#'  \item The flow or stage height column should be numeric
#' }
#'
#' @return \code{flowdat} is returned as is if no errors are found.  An informative error is raised for structural problems (unrecognised column names, missing required columns, zero or multiple flow/stage columns, unparseable date/time values, or non-numeric values).  Missing values produce a warning instead of an error.
#'
#' @export
#'
#' @examples
#' flowpth <- system.file('extdata/ExampleFlow1.xlsx', package = 'AquaSensR')
#'
#' flowdat <- utilASRimportcont(flowpth)
#'
#' checkASRflow(flowdat)
checkASRflow <- function(flowdat) {
  message('Running checks on flow/stage data...\n')

  # globals - restricted to Water Level and Flow parameter groups
  parms <- paramsASR$Parameter[
    paramsASR[["Parameter Group"]] %in% c("Water Level", "Flow")
  ]
  valid_colnms <- c("Date", "Time", "DateTime")

  # detect input format
  has_datetime <- 'DateTime' %in% names(flowdat)

  # check column names
  msg <- '\tChecking column names...'
  nms <- names(flowdat)
  chk <- nms %in% c(valid_colnms, parms)
  if (any(!chk)) {
    tochk <- nms[!chk]
    stop(
      msg,
      '\n\tPlease correct the column names or remove: ',
      paste(tochk, collapse = ', '),
      call. = FALSE
    )
  }
  message(paste(msg, 'OK'))

  # check required header columns
  if (has_datetime) {
    msg <- '\tChecking DateTime is present...'
    required <- c("DateTime")
  } else {
    msg <- '\tChecking Date, Time are present...'
    required <- c("Date", "Time")
  }
  chk <- required %in% nms
  if (any(!chk)) {
    tochk <- required[!chk]
    stop(
      msg,
      '\n\tMissing the following columns: ',
      paste(tochk, collapse = ', '),
      call. = FALSE
    )
  }
  message(paste(msg, 'OK'))

  # checking exactly one flow or stage height column is present
  msg <- '\tChecking exactly one flow or stage height column is present...'
  nms <- names(flowdat)
  matched <- parms[parms %in% nms]
  if (length(matched) == 0L) {
    stop(
      msg,
      '\n\tNo flow or stage height column found. Please include exactly one from: ',
      paste(parms, collapse = ', '),
      call. = FALSE
    )
  }
  if (length(matched) > 1L) {
    stop(
      msg,
      '\n\tMultiple flow or stage height columns found, only one is allowed: ',
      paste(matched, collapse = ', '),
      call. = FALSE
    )
  }
  message(paste(msg, 'OK'))

  # check date/time format
  if (has_datetime) {
    msg <- '\tChecking DateTime format...'
    chk <- lubridate::parse_date_time(
      flowdat$DateTime,
      orders = c(
        'ymd IMSp',
        'mdy IMSp',
        'dmy IMSp',
        'ymd HMS',
        'mdy HMS',
        'dmy HMS',
        'ymd HM',
        'mdy HM',
        'dmy HM'
      ),
      quiet = TRUE
    )
    if (any(is.na(chk))) {
      tochk <- which(is.na(chk))
      stop(
        msg,
        '\n\tThe following rows have DateTime values that are not in a recognizable format: ',
        paste(tochk, collapse = ', '),
        call. = FALSE
      )
    }
    message(paste(msg, 'OK'))
  } else {
    # check dates
    msg <- '\tChecking date format...'
    chk <- lubridate::parse_date_time(
      flowdat$Date,
      orders = c('ymd', 'mdy', 'dmy'),
      quiet = TRUE
    )
    if (any(is.na(chk))) {
      tochk <- which(is.na(chk))
      stop(
        msg,
        '\n\tThe following rows have dates that are not in a recognizable format: ',
        paste(tochk, collapse = ', '),
        call. = FALSE
      )
    }
    message(paste(msg, 'OK'))

    # check times
    msg <- '\tChecking time format...'
    chk <- lubridate::parse_date_time(
      flowdat$Time,
      orders = c('IMSp', 'HMS', 'HM', 'ymd IMSp', 'ymd HMS', 'ymd HM'),
      quiet = TRUE
    )
    if (any(is.na(chk))) {
      tochk <- which(is.na(chk))
      stop(
        msg,
        '\n\tThe following rows have times that are not in a recognizable format: ',
        paste(tochk, collapse = ', '),
        call. = FALSE
      )
    }
    message(paste(msg, 'OK'))
  }

  # check for missing values
  msg <- '\tChecking for missing values...'
  chk <- sapply(flowdat, function(x) any(is.na(x)))
  if (any(chk)) {
    nms <- names(flowdat)[chk]
    tochk <- sapply(
      nms,
      function(x) {
        which(is.na(flowdat[[x]]))
      },
      simplify = FALSE
    )

    warning(
      msg,
      '\n\tThe following columns have missing values in the following rows: ',
      paste(
        sapply(names(tochk), function(x) {
          paste0(x, ' (', paste(tochk[[x]], collapse = ', '), ')')
        }),
        collapse = '; '
      ),
      call. = FALSE
    )
    message(paste(msg, 'WARNING'))
  } else {
    message(paste(msg, 'OK'))
  }

  # check flow/stage height column for non-numeric values
  msg <- '\tChecking flow or stage height column for non-numeric values...'
  vals <- flowdat[[matched]][!is.na(flowdat[[matched]])]
  chk <- any(is.na(suppressWarnings(as.numeric(vals))))
  if (chk) {
    non_na_idx <- which(!is.na(flowdat[[matched]]))
    is_bad <- is.na(suppressWarnings(as.numeric(flowdat[[matched]][non_na_idx])))
    tochk <- non_na_idx[is_bad]

    stop(
      msg,
      '\n\tThe following rows have non-numeric values in column ',
      matched,
      ': ',
      paste(tochk, collapse = ', '),
      call. = FALSE
    )
  }
  message(paste(msg, 'OK'))

  # final out message
  outmsg <- '\nAll checks passed!'
  message(outmsg)

  return(flowdat)
}
