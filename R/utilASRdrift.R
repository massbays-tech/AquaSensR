#' Apply linear drift correction to a continuous monitoring parameter
#'
#' Corrects for instrument drift over a specified window using a
#' linear interpolation approach.  The correction at the start of the window is
#' zero and grows linearly to \code{cal_ref - cal_check} at the end, where
#' \code{cal_check} is inferred from the data as the sensor reading at
#' \code{drift_end_time}.
#'
#' @param cont \code{contdat} data frame returned by \code{\link{readASRcont}}
#' @param param character string naming the parameter column to correct
#' @param cal_ref numeric; the true or accepted value measured by an
#'   independent calibrated instrument at the end of the deployment period
#' @param drift_start_time start of the drift window (POSIXct or coercible)
#' @param drift_end_time end of the drift window (POSIXct or coercible)
#'
#' @return A copy of \code{cont} with corrected values for \code{param} in the
#'   drift window.  Values outside the window are unchanged.
#'
#' @details
#' The \code{cal_check} value (what the deployed sensor was actually reading at
#' \code{drift_end_time}) is inferred directly from the data, so only the
#' independent reference reading (\code{cal_ref}) needs to be supplied.  The
#' total drift \code{cal_ref - cal_check} is distributed linearly across the
#' window: zero correction is applied at \code{drift_start_time} and the full
#' correction is applied at \code{drift_end_time}.
#'
#' This correction formula is as follows:
#' \deqn{
#'   \mathrm{adj} = \mathrm{sensor} +
#'   (\mathrm{cal\_ref} - \mathrm{cal\_check}) \times
#'   \frac{i - i_{\min}}{i_{\max} - i_{\min}}
#' }
#'
#' @export
#'
#' @examples
#' contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
#' contdat <- readASRcont(contpth, runchk = FALSE)
#' t1 <- min(contdat$DateTime)
#' t2 <- max(contdat$DateTime)
#' utilASRdrift(contdat, "Water_Temp_C", cal_ref = 26, t1, t2)
utilASRdrift <- function(
  cont,
  param,
  cal_ref,
  drift_start_time,
  drift_end_time
) {
  if (!param %in% names(cont)) {
    stop("'", param, "' column not found in cont.", call. = FALSE)
  }

  tz <- attr(cont$DateTime, "tzone")
  if (is.null(tz) || !nzchar(tz)) {
    tz <- "UTC"
  }

  drift_start_time <- as.POSIXct(drift_start_time, tz = tz)
  drift_end_time <- as.POSIXct(drift_end_time, tz = tz)

  in_window <- cont$DateTime >= drift_start_time &
    cont$DateTime <= drift_end_time
  if (!any(in_window)) {
    return(cont)
  }

  window_vals <- cont[[param]][in_window]
  n <- length(window_vals)

  if (n < 2L) {
    warning(
      "Drift window contains fewer than 2 observations. No correction applied.",
      call. = FALSE
    )
    return(cont)
  }

  cal_check <- window_vals[n]
  fraction <- (seq_len(n) - 1L) / (n - 1L)

  out <- cont
  out[[param]][in_window] <- window_vals + (cal_ref - cal_check) * fraction
  out
}
