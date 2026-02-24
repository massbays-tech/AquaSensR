#' Flag continuous monitoring data with QC criteria
#'
#' @param contdat data frame returned by \code{\link{readASRcont}}
#' @param metadat data frame returned by \code{\link{readASRmeta}}
#' @param param character string naming the parameter column to evaluate.
#'   Must match one of the parameter columns present in \code{contdat} and
#'   one of the entries in the \code{Parameter} column of \code{metadat}.
#'
#' @details Applies four independent QC checks to the selected parameter for
#' every site in \code{contdat}, matching thresholds from \code{metadat} by
#' \code{Site} and \code{Parameter}.  Each check produces its own flag
#' (\code{"pass"}, \code{"suspect"}, or \code{"fail"}) so the caller can see
#' exactly which criteria fired.  If multiple metadata rows match a given
#' site/parameter pair the first row is used and a warning is issued.
#'
#' \strong{Gross range} (\code{gross_flag}) — Observations below \code{Min}
#' or above \code{Max} are flagged \code{"fail"}.  Observations below
#' \code{Tlower} or above \code{Tupper} (but within the fail bounds) are
#' flagged \code{"suspect"}.
#'
#' \strong{Spike} (\code{spike_flag}) — The absolute difference between
#' consecutive observations is compared to \code{SpikeFail} (fail) and
#' \code{SpikeSuspect} (suspect).  The second observation in the jump is
#' flagged.
#'
#' \strong{Rate of change} (\code{roc_flag}) — For each observation the
#' absolute difference from the previous observation is compared to
#' \code{RoCStdev} standard deviations of all absolute differences within a
#' rolling \code{RoCHours}-hour window centered on that observation.
#' Observations exceeding the threshold are flagged \code{"suspect"}.
#' Requires at least 3 differences in the window; otherwise \code{"pass"}.
#'
#' \strong{Flatline} (\code{flat_flag}) — Counts consecutive observations
#' where the absolute step from the previous observation is within
#' \code{FlatSuspectDelta} (or \code{FlatFailDelta}) units.  Observations
#' whose run length reaches \code{FlatSuspectN} (or \code{FlatFailN}) are
#' flagged.
#'
#' Data are sorted by \code{Site} and \code{DateTime} before processing.
#'
#' @return A data frame with columns \code{Site}, \code{DateTime}, the
#'   selected parameter, and four flag columns: \code{gross_flag},
#'   \code{spike_flag}, \code{roc_flag}, and \code{flat_flag}.
#'
#' @export
#'
#' @examples
#' contpth <- system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR')
#' metapth <- system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR')
#'
#' contdat <- readASRcont(contpth, tz = 'Etc/GMT+5', runchk = FALSE)
#' metadat <- readASRmeta(metapth, runchk = FALSE)
#'
#' flagASRcont(contdat, metadat, param = 'Water Temp_C')
flagASRcont <- function(contdat, metadat, param) {

  # validate param
  parms <- paramsASR$Parameter
  if (!param %in% parms)
    stop("'", param, "' is not a recognised parameter. See paramsASR$Parameter.",
         call. = FALSE)
  if (!param %in% names(contdat))
    stop("'", param, "' column not found in contdat.", call. = FALSE)
  if (!param %in% metadat$Parameter)
    stop("'", param, "' not found in metadat$Parameter.", call. = FALSE)

  # sort by Site then DateTime so consecutive checks are meaningful
  dat <- contdat[order(contdat$Site, contdat$DateTime), ]

  # build output skeleton
  out <- dat[, c("Site", "DateTime", param)]
  out$gross_flag <- "pass"
  out$spike_flag <- "pass"
  out$roc_flag   <- "pass"
  out$flat_flag  <- "pass"

  for (site in unique(dat$Site)) {

    site_idx <- which(dat$Site == site)

    meta_rows <- metadat[metadat$Site == site & metadat$Parameter == param, ]

    if (nrow(meta_rows) == 0L) next

    if (nrow(meta_rows) > 1L) {
      warning(
        "Multiple metadata rows for site '", site, "' parameter '", param,
        "'. Using the first row.",
        call. = FALSE
      )
      meta_rows <- meta_rows[1L, ]
    }

    vals      <- dat[[param]][site_idx]
    datetimes <- dat$DateTime[site_idx]
    init      <- rep("pass", length(site_idx))

    out$gross_flag[site_idx] <- flagGross(init, vals, meta_rows)
    out$spike_flag[site_idx] <- flagSpike(init, vals, meta_rows)
    out$roc_flag[site_idx]   <- flagRoC(init, vals, datetimes, meta_rows)
    out$flat_flag[site_idx]  <- flagFlatline(init, vals, meta_rows)
  }

  out
}

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
#' updateFlag(flag, "suspect", c(TRUE, FALSE, TRUE, TRUE))
#' updateFlag(flag, "fail",    c(TRUE, TRUE, FALSE, FALSE))
updateFlag <- function(flag, level, condition) {
  sev     <- c(pass = 0L, suspect = 1L, fail = 2L)
  upgrade <- !is.na(condition) & condition & sev[[level]] > sev[flag]
  flag[upgrade] <- level
  flag
}

#' Apply gross range QC flag
#'
#' @param flag character vector of current flag values (\code{"pass"},
#'   \code{"suspect"}, or \code{"fail"}).
#' @param vals numeric vector of observed values, the same length as
#'   \code{flag}.
#' @param meta single-row data frame of metadata for the parameter being
#'   checked.  Must contain numeric columns \code{Min}, \code{Max},
#'   \code{Tlower}, and \code{Tupper}.
#'
#' @details Observations below \code{Min} or above \code{Max} are flagged
#'   \code{"fail"}.  Observations below \code{Tlower} or above \code{Tupper}
#'   (but within the fail bounds) are flagged \code{"suspect"}.
#'   \code{NA} threshold values are silently skipped.
#'
#' @return Updated character flag vector.
#'
#' @export
#'
#' @examples
#' flag <- rep("pass", 5)
#' vals <- c(-2, 0, 15, 26, 32)
#' meta <- data.frame(Min = -1, Max = 30, Tlower = 0, Tupper = 25)
#' flagGross(flag, vals, meta)
flagGross <- function(flag, vals, meta) {
  if (!is.na(meta$Tlower)) flag <- updateFlag(flag, "suspect", vals < meta$Tlower)
  if (!is.na(meta$Tupper)) flag <- updateFlag(flag, "suspect", vals > meta$Tupper)
  if (!is.na(meta$Min))    flag <- updateFlag(flag, "fail",    vals < meta$Min)
  if (!is.na(meta$Max))    flag <- updateFlag(flag, "fail",    vals > meta$Max)
  flag
}

#' Apply spike QC flag
#'
#' @param flag character vector of current flag values (\code{"pass"},
#'   \code{"suspect"}, or \code{"fail"}).
#' @param vals numeric vector of observed values, the same length as
#'   \code{flag}.
#' @param meta single-row data frame of metadata for the parameter being
#'   checked.  Optional numeric columns \code{SpikeSuspect} and
#'   \code{SpikeFail} define the absolute-difference thresholds.  Either or
#'   both columns may be absent or \code{NA}, in which case that level of
#'   check is skipped.
#'
#' @details The absolute difference between each observation and the preceding
#'   one is computed.  If the difference is greater than or equal to
#'   \code{SpikeSuspect} the observation is flagged \code{"suspect"};
#'   greater than or equal to \code{SpikeFail} flags \code{"fail"}.
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
#' meta <- data.frame(SpikeSuspect = 1.5, SpikeFail = 2.0)
#' flagSpike(flag, vals, meta)
flagSpike <- function(flag, vals, meta) {
  diffs <- c(NA_real_, abs(diff(vals)))
  if ("SpikeSuspect" %in% names(meta) && !is.na(meta$SpikeSuspect))
    flag <- updateFlag(flag, "suspect", diffs >= meta$SpikeSuspect)
  if ("SpikeFail" %in% names(meta) && !is.na(meta$SpikeFail))
    flag <- updateFlag(flag, "fail", diffs >= meta$SpikeFail)
  flag
}

#' Apply rate-of-change QC flag
#'
#' @param flag character vector of current flag values (\code{"pass"},
#'   \code{"suspect"}, or \code{"fail"}).
#' @param vals numeric vector of observed values, the same length as
#'   \code{flag}.
#' @param datetimes POSIXct vector of observation timestamps, the same length
#'   as \code{flag}.
#' @param meta single-row data frame of metadata for the parameter being
#'   checked.  Optional numeric columns \code{RoCStdev} (number of standard
#'   deviations) and \code{RoCHours} (full window width in hours) control the
#'   check.  If either column is absent or \code{NA} the check is skipped.
#'
#' @details For each observation the absolute difference from the previous
#'   observation is compared to \code{RoCStdev} × the standard deviation of
#'   all absolute differences within a \code{RoCHours}-hour window centered
#'   on that observation.  The observation is flagged \code{"suspect"} if its
#'   difference exceeds this threshold.  At least 3 differences must fall
#'   within the window; otherwise the observation is skipped.  This check
#'   only produces \code{"suspect"} flags; it does not produce \code{"fail"}
#'   flags.
#'
#' @return Updated character flag vector.
#'
#' @export
#'
#' @examples
#' flag <- rep("pass", 6)
#' vals <- c(10, 10.2, 10.1, 10.3, 15.0, 10.2)
#' datetimes <- as.POSIXct("2024-01-01") + seq(0, 5) * 900  # 15-min intervals
#' meta <- data.frame(RoCStdev = 3, RoCHours = 2)
#' flagRoC(flag, vals, datetimes, meta)
flagRoC <- function(flag, vals, datetimes, meta) {
  if (!("RoCStdev" %in% names(meta)) || is.na(meta$RoCStdev)) return(flag)
  if (!("RoCHours" %in% names(meta)) || is.na(meta$RoCHours)) return(flag)

  diffs     <- c(NA_real_, abs(diff(vals)))
  times_num <- as.numeric(datetimes)
  half_win  <- meta$RoCHours * 1800  # half of full window in seconds

  roc_sd <- vapply(seq_along(vals), function(i) {
    if (is.na(diffs[i])) return(NA_real_)
    in_win <- abs(times_num - times_num[i]) <= half_win
    d <- diffs[in_win & !is.na(diffs)]
    if (length(d) < 3L) NA_real_ else stats::sd(d)
  }, numeric(1L))

  is_roc <- !is.na(diffs) & !is.na(roc_sd) & roc_sd > 0 &
            diffs >= meta$RoCStdev * roc_sd
  updateFlag(flag, "suspect", is_roc)
}

#' Compute consecutive run lengths for flatline detection
#'
#' @param vals numeric vector of observed values.
#' @param delta non-negative numeric scalar.  Two adjacent observations are
#'   considered part of the same flat run if their absolute difference is
#'   less than or equal to \code{delta}.
#'
#' @details For each position \eqn{i}, the run length is the number of
#'   consecutive observations ending at \eqn{i} (including \eqn{i} itself)
#'   for which each successive absolute difference is \eqn{\le} \code{delta}.
#'   A run length of 1 means the observation is not part of a flat stretch.
#'   \code{NA} values in \code{vals} break the run.
#'
#' @return Integer vector the same length as \code{vals} giving the run length
#'   at each position.
#'
#' @export
#'
#' @examples
#' vals <- c(10, 10, 10.005, 10.003, 12, 12, 12)
#' rleFlat(vals, delta = 0.01)
rleFlat <- function(vals, delta) {
  n  <- length(vals)
  rl <- integer(n)
  rl[1L] <- 1L
  for (i in seq_len(n - 1L) + 1L) {
    if (!is.na(vals[i]) && !is.na(vals[i - 1L]) &&
        abs(vals[i] - vals[i - 1L]) <= delta) {
      rl[i] <- rl[i - 1L] + 1L
    } else {
      rl[i] <- 1L
    }
  }
  rl
}

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
#' @details Uses \code{\link{rleFlat}} to compute consecutive run lengths.
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
#' flagFlatline(flag, vals, meta)
flagFlatline <- function(flag, vals, meta) {
  has_susp <- "FlatSuspectN" %in% names(meta) && !is.na(meta$FlatSuspectN) &&
              "FlatSuspectDelta" %in% names(meta) && !is.na(meta$FlatSuspectDelta)
  has_fail <- "FlatFailN" %in% names(meta) && !is.na(meta$FlatFailN) &&
              "FlatFailDelta" %in% names(meta) && !is.na(meta$FlatFailDelta)

  if (has_susp) {
    rl   <- rleFlat(vals, meta$FlatSuspectDelta)
    flag <- updateFlag(flag, "suspect", rl >= meta$FlatSuspectN)
  }
  if (has_fail) {
    rl   <- rleFlat(vals, meta$FlatFailDelta)
    flag <- updateFlag(flag, "fail", rl >= meta$FlatFailN)
  }
  flag
}
