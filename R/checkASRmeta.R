#' Check continuous monitoring metadata
#'
#' @param metadat input data frame for continuous metadata
#'
#' @details This function is used internally within \code{\link{readASRmeta}} to run several checks on the input data to verify correct formatting before downstream analysis.
#'
#' The following checks are made:
#' \itemize{
#'  \item Column names: Should include only Site, Parameter, Depth, GrMinFail, GrMaxFail, GrMinSuspect, GrMaxSuspect, SpikeFail, SpikeSuspect, FlatFailN, FlatFailDelta, FlatSuspectN, FlatSuspectDelta, RoCStdev, and RoCHours
#'  \item All columns present: All columns from the previous check should be present
#'  \item At least one parameter is present: At least one parameter in the \code{Parameter} column matches the \code{Parameter} column in \code{\link{paramsASR}}
#'  \item Parameter format: All parameters listed in the \code{Parameter} column should match those in the \code{Parameter} column in \code{\link{paramsASR}}
#'  \item Numeric columns: All columns except \code{Site} and \code{Parameter} should be numeric values
#' }
#'
#' @return \code{metadat} is returned as is if no errors are found, otherwise an informative error message is returned prompting the user to make the required correction to the raw data before proceeding.
#'
#' @export
#'
#' @examples
#' library(dplyr)
#'
#' metapth <- system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR')
#'
#' metadat <- suppressWarnings(readxl::read_excel(metapth, na = c('NA', 'na', ''),
#'      guess_max = Inf))
#'
#' checkASRmeta(metadat)
checkASRmeta <- function(metadat) {
  message('Running checks on continuous metadata...\n')

  # globals
  colnms <- c(
    "Site",
    "Parameter",
    "Depth",
    "GrMinFail",
    "GrMaxFail",
    "GrMinSuspect",
    "GrMaxSuspect",
    "SpikeFail",
    "SpikeSuspect",
    "FlatFailN",
    "FlatFailDelta",
    "FlatSuspectN",
    "FlatSuspectDelta",
    "RoCStdev",
    "RoCHours"
  )
  parms <- paramsASR$Parameter

  # check column names
  msg <- '\tChecking column names...'
  nms <- names(metadat)
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
  nms <- names(metadat)
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
  nms <- metadat$Parameter
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
  nms <- metadat$Parameter
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

  # check columns for non-numeric values
  msg <- '\tChecking columns for non-numeric values...'
  nms <- names(metadat)
  nms <- nms[!nms %in% c("Site", "Parameter")]
  chk <- sapply(nms, function(x) {
    suppressWarnings(as.numeric(na.omit(metadat[[x]]))) |> is.na() |> any()
  })
  if (any(chk)) {
    # get rows with non-numeric values
    tochk <- sapply(
      nms[chk],
      function(x) {
        x <- ifelse(is.na(metadat[[x]]), 1, metadat[[x]])
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

  return(metadat)
}
