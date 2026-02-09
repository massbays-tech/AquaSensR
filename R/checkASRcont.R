#' Check continuous monitoring data
#'
#' @param contdat input data frame for results
#'
#' @details This function is used internally within \code{\link{readASRcont}} to run several checks on the input data to verify correct formatting before downstream analysis.
#'
#' The following checks are made:
#' \itemize{
#'  \item: Column names: Should include only Site, Date, Time, and at least one parameter column that matches the \code{Label} column in \code{\link{paramsASR}}
#'  \item: Site, Date, Time are present: These columns are required for downstream analysis and upload to WQX
#'  \item: At least one parameter column is present: At least one parameter column that matches the \code{Label} column in \code{\link{paramsASR}} is required for downstream analysis and upload to WQX
#'  \item Date format: Should be in a format that can be recognized by \code{\link[lubridate:ymd]{lubridate::ymd()}}
#'  \item Time format: Should be in a format that can be recognized by \code{\link[lubridate:ymd_hms]{lubridate::ymd_hms()}}
#'  \item Parameter columns should be numeric: All parameter columns should be numeric values
#' }
#'
#' @return \code{contdat} is returned as is if no errors are found, otherwise an informative error message is returned prompting the user to make the required correction to the raw data before proceeding.
#'
#' @export
#'
#' @examples
#' library(dplyr)
#'
#' contpth <- system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR')
#'
#' contdat <- suppressWarnings(readxl::read_excel(contpth, na = c('NA', 'na', ''),
#'      guess_max = Inf)) |>
#'    dplyr::mutate(dplyr::across(
#'      dplyr::where(~ inherits(.x, "POSIXct") | inherits(.x, "Date")),
#'    as.character))
#'
#' checkASRcont(contdat)
checkASRcont <- function(contdat) {
  message('Running checks on continuous data...\n')

  # globals
  colnms <- c("Site", "Date", "Time")
  parms <- paramsASR$Label

  # check column names
  msg <- '\tChecking column names...'
  nms <- names(contdat)
  chk <- nms %in% c(colnms, parms)
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

  # check header columns
  msg <- '\tChecking Site, Date, Time are present...'
  nms <- names(contdat)
  chk <- colnms %in% nms
  if (any(!chk)) {
    tochk <- colnms[!chk]
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
      '\n\tNo parameter columns found. Please include at least one from the Label column in paramsASR.',
      call. = FALSE
    )
  }
  message(paste(msg, 'OK'))

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
  chk <- lubridate::ymd_hms(contdat$Time, quiet = TRUE)
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
