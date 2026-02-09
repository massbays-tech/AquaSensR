#' Format continuous data
#'
#' @param contdat input data frame
#' @param tz character string of time zone for the date and time columns  See `OlsonNames()` for acceptable time zones.
#'
#' @details This function is used internally within \code{\link{readASRcont}} to format the input data for downstream analysis.  The formatting includes:
#' 
#' \itemize{
#'   \item Text
#' }
#' 
#' @return A formatted data frame of the continuous data
#' 
#' @export
#'
#' @examples
#' contpth <- system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR')
#' 
#' contdat <- suppressWarnings(readxl::read_excel(contpth, na = c('NA', 'na', ''), 
#'      guess_max = Inf)) %>% 
#'    dplyr::mutate(dplyr::across(
#'      dplyr::where(~ inherits(.x, "POSIXct") | inherits(.x, "Date")), 
#'    as.character))
#'              
#' formASRcont(contdat, tz = 'Etc/GMT+5')
formASRcont <- function(contdat, tz){
  
  out <- contdat
  # combine date and time into a single column, add time zone

  # convert parameters to numeric
  
  return(out)
  
}
