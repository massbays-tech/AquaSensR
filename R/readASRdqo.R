#' Read data quality objectives from an external file
#'
#' @param dqopth character string of path to the data quality objectives file
#' @param runchk logical to run data checks with \code{\link{checkASRdqo}}
#'
#' @returns A formatted data quality objectives data frame that can be used for downstream analysis
#' @export
#'
#' @details The file must not be open in another program (e.g. Excel, LibreOffice) when this function is run, otherwise an error will indicate to close the file before proceeding.
#'
#' @examples
#'
#' dqopth <- system.file('extdata/ExampleDQO.xlsx', package = 'AquaSensR')
#'
#' readASRdqo(dqopth)
readASRdqo <- function(dqopth, runchk = TRUE) {
  dqodat <- utilASRopencheck(dqopth, \() suppressWarnings(readxl::read_excel(
    dqopth,
    na = c('NA', 'na', ''),
    guess_max = Inf
  )))

  # run checks
  if (runchk) {
    dqodat <- checkASRdqo(dqodat)
  }

  # format results
  out <- formASRdqo(dqodat)

  return(out)
}
