#' Apply spike QC flag
#'
#' @param flag character vector of current flag values (\code{"pass"},
#'   \code{"suspect"}, or \code{"fail"}).
#' @param vals numeric vector of observed values, the same length as
#'   \code{flag}.
#' @param dqo two-row data frame from data quality objectives for the parameter
#'   being checked, containing one row where \code{Flag == "Fail"} and one
#'   where \code{Flag == "Suspect"}.  Optional numeric column \code{Spike}
#'   defines the absolute-difference threshold for each severity level.
#'   Either row may have \code{NA} for \code{Spike}, in which case that level
#'   of check is skipped.
#'
#' @details The absolute difference between each observation and the preceding
#'   one is computed.  If the difference is greater than or equal to
#'   \code{Spike} in the \code{"Suspect"} row the observation is flagged
#'   \code{"suspect"}; greater than or equal to \code{Spike} in the
#'   \code{"Fail"} row flags \code{"fail"}.
#'   The first observation always receives \code{NA} for the difference and
#'   is not flagged by this check.
#'
#' @return Updated character flag vector.
#'
#' @export
#'
#' @examples
#' flag <- rep("pass", 5)
#' vals <- c(10, 10.5, 14, 10.2, 10.3)
#' dqo <- data.frame(Flag = c("Fail", "Suspect"), Spike = c(2.0, 1.5))
#' utilASRflagspike(flag, vals, dqo)
utilASRflagspike <- function(flag, vals, dqo) {
  diffs <- c(NA_real_, abs(diff(vals)))
  susp <- dqo[dqo$Flag == "Suspect", ]
  fail <- dqo[dqo$Flag == "Fail", ]

  if (nrow(susp) > 0 && "Spike" %in% names(dqo) && !is.na(susp$Spike)) {
    flag <- utilASRflagupdate(flag, "suspect", diffs >= susp$Spike)
  }
  if (nrow(fail) > 0 && "Spike" %in% names(dqo) && !is.na(fail$Spike)) {
    flag <- utilASRflagupdate(flag, "fail", diffs >= fail$Spike)
  }
  flag
}
