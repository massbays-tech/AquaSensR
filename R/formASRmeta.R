#' Format continuous metadata
#'
#' @param metadat input data frame
#'
#' @details This function is used internally within \code{\link{readASRmeta}} to format the input data for downstream analysis.  The formatting includes:
#'
#' \itemize{
#'  \item Convert non-numeric columns to numeric: Converts all columns except Parameter to numeric if they are not already.
#' }
#'
#' @return A formatted data frame of the continuous data
#'
#' @export
#'
#' @examples
#' metapth <- system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR')
#'
#' metadat <- suppressWarnings(readxl::read_excel(metapth, na = c('NA', 'na', ''),
#'      guess_max = Inf))
#'
#' formASRmeta(metadat)
formASRmeta <- function(metadat) {
  # convert columns that are not Parameter to numeric if not
  out <- metadat |>
    dplyr::mutate(
      dplyr::across(
        -c(Parameter),
        ~ if (!is.numeric(.x)) as.numeric(.x) else .x
      )
    )

  return(out)
}
