#' Apply flatline QC flag
#'
#' @param flag character vector of current flag values (\code{"pass"},
#'   \code{"suspect"}, or \code{"fail"}).
#' @param vals numeric vector of observed values, the same length as
#'   \code{flag}.
#' @param meta single-row data frame of metadata for the parameter being
#'   checked.  Optional numeric columns \code{FlatSuspectN},
#'   \code{FlatSuspectDelta}, \code{FlatFailN}, and \code{FlatFailDelta}
#'   define the run-length and tolerance thresholds.  Either pair may be
#'   absent or \code{NA}, in which case that level of check is skipped.
#'
#' @details Uses \code{\link{utilASRflagrleflat}} to compute consecutive run lengths.
#'   An observation is flagged \code{"suspect"} when its run length (computed
#'   with \code{FlatSuspectDelta}) reaches \code{FlatSuspectN}, and
#'   \code{"fail"} when its run length (computed with \code{FlatFailDelta})
#'   reaches \code{FlatFailN}.
#'
#' @return Updated character flag vector.
#'
#' @export
#'
#' @examples
#' flag <- rep("pass", 8)
#' vals <- c(10, 10, 10.005, 10.002, 10.001, 10.003, 12, 12)
#' meta <- data.frame(FlatSuspectN = 3, FlatSuspectDelta = 0.01,
#'                    FlatFailN = 5,    FlatFailDelta = 0.01)
#' utilASRflagflatline(flag, vals, meta)
utilASRflagflatline <- function(flag, vals, meta) {
  has_susp <- "FlatSuspectN" %in%
    names(meta) &&
    !is.na(meta$FlatSuspectN) &&
    "FlatSuspectDelta" %in% names(meta) &&
    !is.na(meta$FlatSuspectDelta)
  has_fail <- "FlatFailN" %in%
    names(meta) &&
    !is.na(meta$FlatFailN) &&
    "FlatFailDelta" %in% names(meta) &&
    !is.na(meta$FlatFailDelta)

  if (has_susp) {
    rl <- utilASRflagrleflat(vals, meta$FlatSuspectDelta)
    flag <- utilASRflagupdategupdate(flag, "suspect", rl >= meta$FlatSuspectN)
  }
  if (has_fail) {
    rl <- utilASRflagrleflat(vals, meta$FlatFailDelta)
    flag <- utilASRflagupdategupdate(flag, "fail", rl >= meta$FlatFailN)
  }
  flag
}
