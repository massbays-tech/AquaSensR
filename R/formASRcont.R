#' Format continuous data
#'
#' @param contdat input data frame
#' @param tz character string of time zone for the date and time columns  See `OlsonNames()` for acceptable time zones.
#'
#' @details This function is used internally within \code{\link{readASRcont}} to format the input data for downstream analysis.  The formatting includes:
#' 
#' \itemize{
#'   \item Combine Date and Time columns: Combines into a single DateTime column, converts to POSIXct with the specified time zone.
#'  \item Convert non-numeric columns to numeric: Converts all columns except Site and DateTime to numeric if they are not already.
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
  
  # combine date and time into a single column, add time zone
  out <- contdat |> 
    dplyr::mutate(
      Time = gsub('(^.*\\s)', '', Time)
    ) |> 
    tidyr::unite('DateTime', Date, Time, sep = ' ', remove = TRUE) |>
    dplyr::mutate(
      DateTime = lubridate::ymd_hms(DateTime, tz = tz)
    )

  # convert columns that are not Site, DateTime to numeric if not
  out <- out |> 
    dplyr::mutate(
      dplyr::across(
        -c(Site, DateTime), 
        ~ if(!is.numeric(.x)) as.numeric(.x) else .x
      )
    )
  
  return(out)
  
}
