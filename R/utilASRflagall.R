#' Apply QC flags to all parameters in continuous monitoring data
#'
#' A wrapper around \code{\link{utilASRflag}} that iterates over every
#' parameter in \code{contdat} the results as a named list.
#'
#' @param contdat data frame returned by \code{\link{readASRcont}}
#' @param dqodat data frame returned by \code{\link{readASRdqo}}
#'
#' @details
#' Parameters are defined as every column in \code{contdat} other than
#' \code{DateTime}.  If a parameter has no matching entry in
#' \code{dqodat$Parameter} all four of its flags are returned as
#' \code{"pass"}.
#'
#' Each element of the returned list is the data frame produced by
#' \code{\link{utilASRflag}} for that parameter: columns \code{DateTime}, the
#' parameter, \code{gross_flag}, \code{spike_flag}, \code{roc_flag}, and
#' \code{flat_flag}.
#'
#' @return A named list of data frames, one per matched parameter, with names
#'   equal to the parameter column names.
#'
#' @export
#'
#' @examples
#' contpth <- system.file('extdata/ExampleCont1.xlsx', package = 'AquaSensR')
#' dqopth <- system.file('extdata/ExampleDQO.xlsx', package = 'AquaSensR')
#'
#' contdat <- readASRcont(contpth, runchk = FALSE)
#' dqodat <- readASRdqo(dqopth, runchk = FALSE)
#'
#' utilASRflagall(contdat, dqodat)
utilASRflagall <- function(contdat, dqodat) {
  params <- setdiff(names(contdat), "DateTime")

  if (length(params) == 0L) {
    stop("No parameter columns found in contdat.", call. = FALSE)
  }

  out <- lapply(params, function(p) utilASRflag(contdat, dqodat, p))
  stats::setNames(out, params)
}
