#' Format data quality objectives
#'
#' @param dqodat input data frame
#'
#' @details This function is used internally within \code{\link{readASRdqo}} to format the input data for downstream analysis.  The formatting includes:
#'
#' \itemize{
#'  \item Convert non-numeric columns to numeric: Converts all columns except \code{Parameter} and \code{Flag} to numeric if they are not already.
#' }
#'
#' @return A formatted data frame of the data quality objectives
#'
#' @export
#'
#' @examples
#' dqopth <- system.file('extdata/ExampleDQO.xlsx', package = 'AquaSensR')
#'
#' dqodat <- suppressWarnings(readxl::read_excel(dqopth, na = c('NA', 'na', ''),
#'      guess_max = Inf))
#'
#' formASRdqo(dqodat)
formASRdqo <- function(dqodat) {
  # convert columns that are not Parameter to numeric if not
  out <- dqodat |>
    dplyr::mutate(
      dplyr::across(
        -c(Parameter, Flag),
        ~ if (!is.numeric(.x)) as.numeric(.x) else .x
      )
    )

  return(out)
}
