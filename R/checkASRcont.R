#' Check continuous monitoring data
#'
#' @param contdat input data frame for results
#'
#' @details This function is used internally within \code{\link{readASRcont}} to run several checks on the input data to verify correct formatting before downstream analysis.
#'
#' The input data can use either of two formats:
#' \itemize{
#'  \item \strong{Separate columns}: \code{Date}, \code{Time}, and at least one parameter column
#'  \item \strong{Combined column}: \code{DateTime}, and at least one parameter column
#' }
#'
#' The following checks are made:
#' \itemize{
#'  \item Column names: Should include only Date, Time, DateTime, and at least one parameter column that matches the \code{Parameter} column in \code{\link{paramsASR}}
#'  \item Required columns are present: Either Date + Time or DateTime are required for downstream analysis and upload to WQX
#'  \item At least one parameter column is present: At least one parameter column that matches the \code{Parameter} column in \code{\link{paramsASR}} is required for downstream analysis and upload to WQX
#'  \item Date format (separate columns only): Should be parseable by \code{\link[lubridate:parse_date_time]{lubridate::parse_date_time()}} using year-first (\code{"2024-06-01"}), month-first (\code{"06/01/2024"}), or day-first (\code{"01/06/2024"}) formats
#'  \item Time format (separate columns only): Should be parseable by \code{\link[lubridate:parse_date_time]{lubridate::parse_date_time()}} using 24-hour (\code{"16:30:33"}), 12-hour AM/PM (\code{"4:30:33 PM"}), or Excel-prefixed (\code{"1899-12-31 16:30:33"}) formats
#'  \item DateTime format (combined column only): Should be parseable by \code{\link[lubridate:parse_date_time]{lubridate::parse_date_time()}} using year-first, month-first, or day-first date order combined with 24-hour or 12-hour AM/PM time (e.g. \code{"2024-06-01 16:30:33"}, \code{"06/01/2024 16:30:33"}, or \code{"2024-06-01 4:30:33 PM"})
#'  \item Missing values: Missing values in parameter columns produce a warning rather than an error, since cleaned data files may legitimately contain \code{NA} values.  Missing values in \code{DateTime}, \code{Date}, or \code{Time} columns still cause an error.
#'  \item Parameter columns should be numeric: All parameter columns should be numeric values
#' }
#'
#' @return \code{contdat} is returned as is if no errors are found.  An informative error is raised for structural problems (unrecognised column names, missing required columns, unparseable date/time values, or non-numeric parameter values).  Missing values in parameter columns produce a warning instead of an error.
#'
#' @export
#'
#' @examples
#' contpth <- system.file('extdata/ExampleCont1.xlsx', package = 'AquaSensR')
#'
#' contdat <- utilASRimportcont(contpth)
#'
#' checkASRcont(contdat)
checkASRcont <- function(contdat) {
  message('Running checks on continuous data...\n')

  # globals
  parms <- paramsASR$Parameter
  valid_colnms <- c("Date", "Time", "DateTime")

  # detect input format
  has_datetime <- 'DateTime' %in% names(contdat)

  # check column names
  msg <- '\tChecking column names...'
  nms <- names(contdat)
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

  # checking at least one parameter column is present
  msg <- '\tChecking at least one parameter column is present...'
  nms <- names(contdat)
  chk <- parms %in% nms
  if (!any(chk)) {
    stop(
      msg,
      '\n\tNo parameter columns found. Please include at least one from the Parameter column in paramsASR.',
      call. = FALSE
    )
  }
  message(paste(msg, 'OK'))

  # check date/time format
  if (has_datetime) {
    msg <- '\tChecking DateTime format...'
    chk <- lubridate::parse_date_time(
      contdat$DateTime,
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
      contdat$Date,
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
      contdat$Time,
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
  chk <- sapply(contdat, function(x) any(is.na(x)))
  if (any(chk)) {
    nms <- names(contdat)[chk]
    tochk <- sapply(
      nms,
      function(x) {
        which(is.na(contdat[[x]]))
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

  # check parameter columns for non-numeric values
  msg <- '\tChecking parameter columns for non-numeric values...'
  nms <- names(contdat)
  nms <- nms[nms %in% parms]
  chk <- sapply(nms, function(x) {
    vals <- contdat[[x]][!is.na(contdat[[x]])]
    any(is.na(suppressWarnings(as.numeric(vals))))
  })
  if (any(chk)) {
    # get rows with non-numeric values (excluding pre-existing NAs)
    tochk <- sapply(
      nms[chk],
      function(x) {
        non_na_idx <- which(!is.na(contdat[[x]]))
        is_bad <- is.na(suppressWarnings(as.numeric(contdat[[x]][non_na_idx])))
        non_na_idx[is_bad]
      },
      simplify = FALSE
    )

    stop(
      msg,
      '\n\tThe following parameter columns have non-numeric values in the following rows: ',
      paste(
        sapply(names(tochk), function(x) {
          paste0(x, ' (', paste(tochk[[x]], collapse = ', '), ')')
        }),
        collapse = '; '
      ),
      call. = FALSE
    )
  }
  message(paste(msg, 'OK'))

  # final out message
  outmsg <- '\nAll checks passed!'
  message(outmsg)

  return(contdat)
}
