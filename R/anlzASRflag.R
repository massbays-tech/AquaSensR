#' Plot QC flag results for a continuous monitoring parameter
#'
#' @param flagdat data frame returned by \code{\link{utilASRflag}}.
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
#' @return An interactive \code{plotly} object.
#'
#' @seealso \code{\link{editASRflag}}, which uses this function internally to
#'   render the plot inside a Shiny app.
#'
#' @export
#'
#' @examples
#' contpth <- system.file('extdata/ExampleCont1.xlsx', package = 'AquaSensR')
#' dqopth <- system.file('extdata/ExampleDQO.xlsx', package = 'AquaSensR')
#'
#' contdat <- readASRcont(contpth, tz = 'Etc/GMT+5', runchk = FALSE)
#' dqodat <- readASRdqo(dqopth, runchk = FALSE)
#'
#' flagdat <- utilASRflag(contdat, dqodat, param = 'Water Temp_C')
#' anlzASRflag(flagdat)
anlzASRflag <- function(flagdat) {
  param <- names(flagdat)[2L]
  ylab <- paramsASR[paramsASR$Parameter == param, "Label"] |> as.character()

  # .rowid provides a stable point identifier passed as customdata to every
  # trace, used by editASRflag() to match plotly selections back to rows.
  # Harmless in standalone use.
  flagdat$.rowid <- seq_len(nrow(flagdat))

  flag_cols <- c("gross_flag", "spike_flag", "roc_flag", "flat_flag")
  check_labels <- c(
    gross_flag = "Gross range",
    spike_flag = "Spike",
    roc_flag = "Rate of change",
    flat_flag = "Flatline"
  )
  check_colors <- c(
    "Gross range" = "#E41A1C",
    "Spike" = "#FF7F00",
    "Rate of change" = "#984EA3",
    "Flatline" = "#377EB8"
  )
  sev_symbols <- c(suspect = "triangle-up", fail = "x")
  sev_sizes <- c(suspect = 9, fail = 11)

  # Base time series line (trace 0) -------------------------------------------
  # Invisible markers (opacity = 0) are added alongside the line so that
  # plotly's box/lasso selection and click events can target individual data
  # points. Without them, line-only traces are not selectable.
  p <- plotly::plot_ly(
    data = flagdat,
    x = ~DateTime,
    y = flagdat[[param]],
    customdata = ~.rowid,
    type = "scatter",
    mode = "lines+markers",
    line = list(color = "gray60", width = 1),
    marker = list(opacity = 0, size = 6),
    name = param,
    showlegend = FALSE,
    hovertemplate = paste0(
      "<b>",
      param,
      "</b>: %{y}<br>",
      "<b>DateTime</b>: %{x}",
      "<extra></extra>"
    )
  )

  # Flag marker traces (traces 1-8) -------------------------------------------
  # All 8 traces are always added (even if empty) so that trace indices are
  # stable for plotlyProxy restyle calls in editASRflag(). Empty traces are
  # hidden from the legend and have no visual impact.
  for (fc in flag_cols) {
    chk <- check_labels[[fc]]
    color <- check_colors[[chk]]

    for (sev in c("suspect", "fail")) {
      sub <- flagdat[
        !is.na(flagdat[[fc]]) & flagdat[[fc]] == sev,
        ,
        drop = FALSE
      ]

      p <- plotly::add_trace(
        p,
        data = sub,
        x = ~DateTime,
        y = sub[[param]],
        customdata = ~.rowid,
        inherit = FALSE,
        type = "scatter",
        mode = "markers",
        marker = list(
          color = color,
          symbol = sev_symbols[[sev]],
          size = sev_sizes[[sev]],
          line = list(color = "white", width = 0.5)
        ),
        name = paste0(chk, " \u2013 ", sev),
        legendgroup = paste0(chk, "_", sev),
        showlegend = nrow(sub) > 0L,
        hovertemplate = paste0(
          "<b>Check</b>: ",
          chk,
          "<br>",
          "<b>Severity</b>: ",
          sev,
          "<br>",
          "<b>",
          param,
          "</b>: %{y}<br>",
          "<b>DateTime</b>: %{x}",
          "<extra></extra>"
        )
      )
    }
  }

  plotly::layout(
    p,
    xaxis = list(title = ""),
    yaxis = list(title = ylab),
    legend = list(
      title = list(text = "<b>Check \u2013 Severity</b>"),
      tracegroupgap = 4
    ),
    dragmode = "zoom",
    hovermode = "closest"
  )
}
