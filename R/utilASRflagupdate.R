#' Update QC flag severity
#'
#' @param flag character vector of current flag values; each element must be
#'   one of \code{"pass"}, \code{"suspect"}, or \code{"fail"}.
#' @param level scalar character string — the new flag level to apply
#'   (\code{"pass"}, \code{"suspect"}, or \code{"fail"}).
#' @param condition logical vector the same length as \code{flag}.  Elements
#'   that are \code{TRUE} and whose current flag is less severe than
#'   \code{level} will be upgraded.  \code{NA} values in \code{condition} are
#'   treated as \code{FALSE}.
#'
#' @details Severity is ordered \code{"pass"} < \code{"suspect"} <
#'   \code{"fail"}.  A flag is only ever upgraded, never downgraded.
#'
#' @return Character vector the same length as \code{flag} with flags updated
#'   where \code{condition} is \code{TRUE} and \code{level} is more severe
#'   than the existing flag.
#'
#' @export
#'
#' @examples
#' flag <- c("pass", "pass", "suspect", "fail")
#' utilASRflagupdate(flag, "suspect", c(TRUE, FALSE, TRUE, TRUE))
#' utilASRflagupdate(flag, "fail",    c(TRUE, TRUE, FALSE, FALSE))
utilASRflagupdate <- function(flag, level, condition) {
  sev <- c(pass = 0L, suspect = 1L, fail = 2L)
  upgrade <- !is.na(condition) & condition & sev[[level]] > sev[flag]
  flag[upgrade] <- level
  flag
}
