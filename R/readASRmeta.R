#' Read continuous monitoring metadata from an external file
#'
#' @param metapth character string of path to the metadata file
#' @param runchk logical to run data checks with \code{\link{checkASRmeta}}
#'
#' @returns A formatted metadata data frame that can be used for downstream analysis
#' @export
#'
#' @examples
#'
#' metapth <- system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR')
#'
#' readASRmeta(metapth)
readASRmeta <- function(metapth, runchk = TRUE) {
  metadat <- suppressWarnings(readxl::read_excel(
    metapth,
    na = c('NA', 'na', ''),
    guess_max = Inf
  ))

  # run checks
  if (runchk) {
    metadat <- checkASRmeta(metadat)
  }

  # format results
  out <- formASRmeta(metadat)

  return(out)
}
