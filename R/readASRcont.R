#' Read continuous monitoring data from an external file
#'
#' @param contpth character string of path to the results file
#' @param runchk logical to run data checks with \code{\link{checkASRcont}}
#'
#' @returns A formatted continuous monitoring data frame that can be used for downstream analysis
#' @export
#'
#' @examples
#' 
#' contpth <- system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR')
#' 
#' readASRcont(contpth)
readASRcont <- function(contpth, runchk = TRUE, warn = TRUE){
  
  contdat <- suppressWarnings(readxl::read_excel(contpth, na = c('NA', 'na', ''), guess_max = Inf)) %>% 
    dplyr::mutate_if(function(x) !lubridate::is.POSIXct(x), as.character)
  
  # run checks
  if(runchk)
    contdat <- checkASRcont(contdat, warn = warn)
  
  # format results
  out <- formASRcont(contdat)
  
  return(out)
  
}