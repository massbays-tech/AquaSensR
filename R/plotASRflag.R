#' Plot QC flag results for a continuous monitoring parameter
#'
#' @param flagdat data frame returned by \code{\link{flagASRcont}}.
#'
#' @details Produces an interactive \pkg{plotly} time series showing all
#' observations as a line, with non-passing observations overlaid as markers.
#' Marker \strong{colour} indicates which QC check fired:
#' \itemize{
#'   \item \strong{Gross range} — red
#'   \item \strong{Spike} — orange
#'   \item \strong{Rate of change} — purple
#'   \item \strong{Flatline} — blue
#' }
#' Marker \strong{shape} indicates severity:
#' \itemize{
#'   \item \strong{Suspect} — upward triangle
#'   \item \strong{Fail} — cross (×)
#' }
#' An observation flagged by multiple checks appears as a marker for each
#' check that fired, allowing all sources of concern to be visible.
#'
#' When \code{flagdat} contains more than one site, the plot uses vertically
#' stacked subplots that share a common x-axis. Legend items are shown once
#' and apply across all subplots.
#'
#' @return An interactive \code{plotly} object.
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
#' flagdat <- flagASRcont(contdat, metadat, param = 'Water Temp_C')
#' plotASRflag(flagdat)
plotASRflag <- function(flagdat) {

  # parameter is always the third column (Site, DateTime, param, flags...)
  param <- names(flagdat)[3L]

  flag_cols <- c("gross_flag", "spike_flag", "roc_flag", "flat_flag")

  check_labels <- c(
    gross_flag = "Gross range",
    spike_flag = "Spike",
    roc_flag   = "Rate of change",
    flat_flag  = "Flatline"
  )
  check_colors <- c(
    "Gross range"    = "#E41A1C",
    "Spike"          = "#FF7F00",
    "Rate of change" = "#984EA3",
    "Flatline"       = "#377EB8"
  )
  sev_symbols <- c(suspect = "triangle-up", fail = "x")
  sev_sizes   <- c(suspect = 9, fail = 11)

  sites <- unique(flagdat$Site)

  # build one plotly panel per site
  make_panel <- function(site_dat, site, show_legend) {

    # base time series line
    p <- plotly::plot_ly(
      data = site_dat,
      x    = ~DateTime,
      y    = site_dat[[param]],
      type = "scatter",
      mode = "lines",
      line = list(color = "gray60", width = 1),
      name = param,
      showlegend  = FALSE,
      hovertemplate = paste0(
        "<b>", param, "</b>: %{y}<br>",
        "<b>DateTime</b>: %{x}",
        "<extra>", site, "</extra>"
      )
    )

    # one trace per check × severity
    for (fc in flag_cols) {
      chk   <- check_labels[fc]
      color <- check_colors[chk]

      for (sev in c("suspect", "fail")) {
        sub <- site_dat[!is.na(site_dat[[fc]]) & site_dat[[fc]] == sev, ]
        if (nrow(sub) == 0L) next

        p <- plotly::add_trace(
          p,
          data = sub,
          x    = ~DateTime,
          y    = sub[[param]],
          type = "scatter",
          mode = "markers",
          marker = list(
            color  = color,
            symbol = sev_symbols[sev],
            size   = sev_sizes[sev],
            line   = list(color = "white", width = 0.5)
          ),
          line        = list(width = 0),
          name        = paste0(chk, " \u2013 ", sev),
          legendgroup = paste0(chk, "_", sev),
          showlegend  = show_legend,
          hovertemplate = paste0(
            "<b>Check</b>: ", chk, "<br>",
            "<b>Severity</b>: ", sev, "<br>",
            "<b>", param, "</b>: %{y}<br>",
            "<b>DateTime</b>: %{x}",
            "<extra>", site, "</extra>"
          )
        )

        # after the first site has added legend items, suppress for subsequent sites
        show_legend <- FALSE
      }
    }

    # site label as y-axis title
    plotly::layout(
      p,
      yaxis = list(title = paste0(site, "<br><sub>", param, "</sub>"))
    )
  }

  if (length(sites) == 1L) {

    p <- make_panel(flagdat, sites, show_legend = TRUE)
    plotly::layout(
      p,
      title  = list(text = param, font = list(size = 14)),
      xaxis  = list(title = "Date / Time"),
      yaxis  = list(title = param),
      legend = list(title = list(text = "<b>Check \u2013 Severity</b>"),
                    tracegroupgap = 4),
      hovermode = "x unified"
    )

  } else {

    panels <- vector("list", length(sites))
    show_leg <- TRUE
    for (i in seq_along(sites)) {
      site_dat   <- flagdat[flagdat$Site == sites[i], ]
      panels[[i]] <- make_panel(site_dat, sites[i], show_legend = show_leg)
      show_leg   <- FALSE
    }

    plotly::subplot(panels,
      nrows   = length(sites),
      shareX  = TRUE,
      titleY  = TRUE,
      margin  = 0.04
    ) |>
      plotly::layout(
        title  = list(text = param, font = list(size = 14)),
        xaxis  = list(title = "Date / Time"),
        legend = list(title = list(text = "<b>Check \u2013 Severity</b>"),
                      tracegroupgap = 4),
        hovermode = "x unified"
      )
  }
}
