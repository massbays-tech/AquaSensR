#' Check continuous monitoring data
#'
#' @param contdat input data frame for results
#'
#' @details This function is used internally within \code{\link{readASRcont}} to run several checks on the input data to verify correct formatting before downstream analysis.
#'
#' The input data can use either of two formats:
#' \itemize{
#'  \item \strong{Separate columns}: \code{Site}, \code{Date}, \code{Time}, and at least one parameter column
#'  \item \strong{Combined column}: \code{Site}, \code{DateTime}, and at least one parameter column
#' }
#'
#' The following checks are made:
#' \itemize{
#'  \item Column names: Should include only Site, Date, Time, DateTime, and at least one parameter column that matches the \code{Parameter} column in \code{\link{paramsASR}}
#'  \item Required columns are present: Site and either Date + Time or DateTime are required for downstream analysis and upload to WQX
#'  \item At least one parameter column is present: At least one parameter column that matches the \code{Parameter} column in \code{\link{paramsASR}} is required for downstream analysis and upload to WQX
#'  \item Date format (separate columns only): Should be in a format recognized by \code{\link[lubridate:ymd]{lubridate::ymd()}} (e.g. \code{"2024-06-01"})
#'  \item Time format (separate columns only): Should be parseable by \code{\link[lubridate:parse_date_time]{lubridate::parse_date_time()}} using 24-hour (\code{"16:30:33"}), 12-hour AM/PM (\code{"4:30:33 PM"}), or Excel-prefixed (\code{"1899-12-31 16:30:33"}) formats
#'  \item DateTime format (combined column only): Should be parseable by \code{\link[lubridate:parse_date_time]{lubridate::parse_date_time()}} using 24-hour or 12-hour AM/PM formats (e.g. \code{"2024-06-01 16:30:33"} or \code{"2024-06-01 4:30:33 PM"})
#'  \item Missing values: No missing values in any columns
#'  \item Parameter columns should be numeric: All parameter columns should be numeric values
#' }
#'
#' @return \code{contdat} is returned as is if no errors are found, otherwise an informative error message is returned prompting the user to make the required correction to the raw data before proceeding.
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
  valid_colnms <- c("Site", "Date", "Time", "DateTime")

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
    msg <- '\tChecking Site, DateTime are present...'
    required <- c("Site", "DateTime")
  } else {
    msg <- '\tChecking Site, Date, Time are present...'
    required <- c("Site", "Date", "Time")
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
    chk <- lubridate::parse_date_time(contdat$DateTime,
      orders = c('ymd IMSp', 'ymd HMS', 'ymd HM'), quiet = TRUE)
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
    chk <- lubridate::ymd(contdat$Date, quiet = TRUE)
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
    chk <- lubridate::parse_date_time(contdat$Time,
      orders = c('IMSp', 'HMS', 'HM', 'ymd IMSp', 'ymd HMS', 'ymd HM'), quiet = TRUE)
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

    stop(
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
  }
  message(paste(msg, 'OK'))

  # check parameter columns for non-numeric values
  msg <- '\tChecking parameter columns for non-numeric values...'
  nms <- names(contdat)
  nms <- nms[nms %in% parms]
  chk <- sapply(nms, function(x) {
    suppressWarnings(as.numeric(contdat[[x]])) |> is.na() |> any()
  })
  if (any(chk)) {
    # get rows with non-numeric values
    tochk <- sapply(
      nms[chk],
      function(x) {
        which(suppressWarnings(as.numeric(contdat[[x]])) |> is.na())
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
