#' Check continuous monitoring data
#'
#' @param contdat input data frame for results
#' @param warn logical to return warnings to the console (default)
#'
#' @details This function is used internally within \code{\link{readASRcont}} to run several checks on the input data to verify correct formatting before downstream analysis.
#' 
#' The following checks are made: 
#' \itemize{
#'  \item Column name spelling: Should be the following: 
#'  \item Columns present: All columns from the previous check should be present
#' }
#' 
#' @return \code{contdat} is returned as is if no errors are found, otherwise an informative error message is returned prompting the user to make the required correction to the raw data before proceeding. Checks with warnings can be fixed at the discretion of the user before proceeding.
#' 
#' @export
#'
#' @examples
#' library(dplyr)
#' 
#' contpth <- system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR')
#' 
#' contdat <- suppressWarnings(readxl::read_excel(respth, na = c('NA', 'na', ''), guess_max = Inf)) %>% 
#'   dplyr::mutate_if(function(x) !lubridate::is.POSIXct(x), as.character)
#'              
#' checkASRcont(contdat)
checkASRcont <- function(contdat, warn = TRUE){
  
  message('Running checks on results data...\n')
  wrn <- 0
  
  # globals
  colnms <- c("")
  
  
  # check field names
  msg <- '\tChecking column names...'
  nms <- names(contdat)
  chk <- nms %in% colnms
  if(any(!chk)){
    tochk <- nms[!chk]
    stop(msg, '\n\tPlease correct the column names or remove: ', paste(tochk, collapse = ', '), call. = FALSE)
  }
  message(paste(msg, 'OK'))
  
  # check all fields are present
  msg <- '\tChecking all required columns are present...'
  nms <- names(contdat)
  chk <- colnms %in% nms
  if(any(!chk)){
    tochk <- colnms[!chk]
    stop(msg, '\n\tMissing the following columns: ', paste(tochk, collapse = ', '), call. = FALSE)
  }
  message(paste(msg, 'OK'))
  
  # final out message
  outmsg <- '\nAll checks passed'
  if(wrn > 0)
    outmsg <- paste0(outmsg, ' (', wrn, ' WARNING(s))')
  outmsg <- paste0(outmsg, '!')
  message(outmsg)
  
  return(contdat)
  
}