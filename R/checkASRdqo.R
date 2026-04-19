#' Check data quality objectives
#'
#' @param dqodat input data frame of data quality objectives
#'
#' @details This function is used internally within \code{\link{readASRdqo}} to run several checks on the input data to verify correct formatting before downstream analysis.
#'
#' The following checks are made:
#' \itemize{
#'  \item Column names: Should include only Parameter, Flag, GrMin, GrMax, Spike, FlatN, FlatDelta, RoCStDv, and RoCHours
#'  \item All columns present: All columns from the previous check should be present
#'  \item At least one parameter is present: At least one parameter in the \code{Parameter} column matches the \code{Parameter} column in \code{\link{paramsASR}}
#'  \item Parameter format: All parameters listed in the \code{Parameter} column should match those in the \code{Parameter} column in \code{\link{paramsASR}}
#'  \item Flag column: The \code{Flag} column should contain only "Fail" or "Suspect" entries
#'  \item Numeric columns: All columns except \code{Parameter} and \code{Flag} should be numeric values
#' }
#'
#' @return \code{dqodat} is returned as is if no errors are found, otherwise an informative error message is returned prompting the user to make the required correction to the raw data before proceeding.
#'
#' @export
#'
#' @examples
#' library(dplyr)
#'
#' dqopth <- system.file('extdata/ExampleDQO.xlsx', package = 'AquaSensR')
#'
#' dqodat <- suppressWarnings(readxl::read_excel(dqopth, na = c('NA', 'na', ''),
#'      guess_max = Inf))
#'
#' checkASRdqo(dqodat)
checkASRdqo <- function(dqodat) {
  message('Running checks on data quality objectives...\n')

  # globals
  colnms <- c(
    "Parameter",
    "Flag",
    "GrMin",
    "GrMax",
    "Spike",
    "FlatN",
    "FlatDelta",
    "RoCStDv",
    "RoCHours"
  )
  parms <- paramsASR$Parameter

  # check column names
  msg <- '\tChecking column names...'
  nms <- names(dqodat)
  chk <- nms %in% colnms
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
  msg <- '\tChecking all columns present...'
  nms <- names(dqodat)
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
  msg <- '\tChecking at least one parameter is present...'
  nms <- dqodat$Parameter
  chk <- parms %in% nms
  if (!any(chk)) {
    stop(
      msg,
      '\n\tNo parameters found. Please include at least one from the Parameter column in paramsASR.',
      call. = FALSE
    )
  }
  message(paste(msg, 'OK'))

  # check parameter format
  msg <- '\tChecking parameter format...'
  nms <- dqodat$Parameter
  chk <- nms %in% parms
  if (any(!chk)) {
    tochk <- nms[!chk]
    stop(
      msg,
      '\n\tIncorrect parameter format: ',
      paste(tochk, collapse = ', '),
      call. = FALSE
    )
  }
  message(paste(msg, 'OK'))

  # check flag column
  msg <- '\tChecking Flag column...'
  nms <- dqodat$Flag
  chk <- nms %in% c("Fail", "Suspect")
  if (any(!chk)) {
    tochk <- nms[!chk]
    stop(
      msg,
      '\n\tFlag column should contain only "Fail" or "Suspect" entries. Please correct the following: ',
      paste(unique(tochk), collapse = ', '),
      call. = FALSE
    )
  }
  message(paste(msg, 'OK'))

  # check columns for non-numeric values
  msg <- '\tChecking columns for non-numeric values...'
  nms <- names(dqodat)
  nms <- nms[!nms %in% c("Parameter", "Flag")]
  chk <- sapply(nms, function(x) {
    suppressWarnings(as.numeric(na.omit(dqodat[[x]]))) |> is.na() |> any()
  })
  if (any(chk)) {
    # get rows with non-numeric values
    tochk <- sapply(
      nms[chk],
      function(x) {
        x <- ifelse(is.na(dqodat[[x]]), 1, dqodat[[x]])
        which(suppressWarnings(as.numeric(x)) |> is.na())
      },
      simplify = FALSE
    )

    stop(
      msg,
      '\n\tThe following columns have non-numeric values in the following rows: ',
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

  return(dqodat)
}
