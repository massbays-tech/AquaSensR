#' Interactive editor for continuous monitoring data
#'
#' Opens a Shiny application displaying the QC flag plot from
#' \code{\link{anlzASRflag}} and allows the user to interactively select and
#' remove data points. Points are removed by clicking or drawing a selection
#' using the box or lasso tool on the plot. A running table of removed points (including their flag
#' assignments) is shown in the sidebar. Individual removal batches can be
#' undone, or the session can be fully reset. Clicking \strong{Done / Close}
#' stops the app and returns the filtered dataset to the R session.
#'
#' @param flagdat data frame returned by \code{\link{utilASRflag}}, with
#'   columns \code{DateTime}, the parameter column, and
#'   \code{gross_flag}, \code{spike_flag}, \code{roc_flag}, \code{flat_flag}.
#'
#' @return A data frame with the same structure as \code{flagdat} but with
#'   user-selected points removed, invisibly returned after the app closes.
#'
#' @details
#' \subsection{How to select points}{
#'   Zooming and panning with the plot toolbar is recommended to more easily
#'   identify points for removal.  These options are available in the menu on
#'   the top right when hovering over the plot.
#'
#'   Points can be selected for removal three ways.  First, individual points can be removed
#'   by clicking.  Second and third, use the box or lasso selection tool by
#'   hovering over the plot and selecting the desired tool from the menu
#'   on the top right.  Click and drag over the desired area for the box selection or
#'   click and encircle the points with the lasso tool to add the points
#'   to the removal table.  Double-click the plot background to remove the selected
#'   area if present after removal.
#' }
#'
#' \subsection{Controls}{
#'   \itemize{
#'     \item \strong{Undo Last Removal}: restores the most recently removed
#'       point or batch of points (one drag-selection at a time).
#'     \item \strong{Start Over}: restores all removed points and resets to
#'       the original dataset.
#'     \item \strong{Done / Close}: stops the app and returns the current
#'       filtered dataset to the R session.
#'   }
#' }
#'
#' The app is constructed inline so that \code{flagdat} is available directly
#' to the server without file I/O. \code{shiny::runApp()} blocks until
#' \code{shiny::stopApp()} is called by the Done button; its return value
#' becomes the function return value.
#'
#' @examples
#' \dontrun{
#' contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
#' dqopth  <- system.file("extdata/ExampleDQO.xlsx", package = "AquaSensR")
#' contdat <- readASRcont(contpth, tz = "Etc/GMT+5")
#' dqodat  <- readASRdqo(dqopth)
#' flagdat <- utilASRflag(contdat, dqodat, "Water Temp_C")
#' cleaned <- editASRflag(flagdat)
#' }
#'
#' @export
editASRflag <- function(flagdat) {
  param <- names(flagdat)[2L]
  prmlb <- paramsASR[paramsASR$Parameter == param, "Label"] |> as.character()

  # anlzASRflag() adds .rowid to flagdat internally; replicate that here so
  # the proxy loop and row-matching logic have a consistent stable identifier.
  flagdat$.rowid <- seq_len(nrow(flagdat))

  flag_cols <- c("gross_flag", "spike_flag", "roc_flag", "flat_flag")

  # -------------------------------------------------------------------------
  # UI
  # -------------------------------------------------------------------------
  ui <- bslib::page_sidebar(
    title = paste("Edit:", prmlb),
    sidebar = bslib::sidebar(
      width = 300,
      open = "open",
      shiny::h4("Controls"),
      shiny::actionButton(
        "undo",
        "Undo Last Removal",
        class = "btn-warning",
        style = "width: 100%; margin-bottom: 3px;"
      ),
      shiny::actionButton(
        "reset",
        "Start Over",
        class = "btn-danger",
        style = "width: 100%; margin-bottom: 3px;"
      ),
      shiny::actionButton(
        "done",
        "Done / Close",
        class = "btn-success",
        style = "width: 100%;"
      ),
      shiny::hr(),
      shiny::h4(shiny::textOutput("removed_count", inline = TRUE)),
      shiny::div(
        style = "font-size: 12px;",
        DT::DTOutput("removed_table")
      )
    ),
    shiny::p(
      "Zoom and pan normally with the plot toolbar visible on the top right when the pointer is over the plot.",
      "To remove points: click individual points directly, or use the",
      "\u2018Box Select\u2019 or \u2018Lasso Select\u2019 toolbar buttons to remove a region.",
      "Double-click the plot background to clear selection and start a new one."
    ),
    plotly::plotlyOutput("flagPlot", height = "550px")
  )

  # -------------------------------------------------------------------------
  # Server
  # -------------------------------------------------------------------------
  server <- function(input, output, session) {
    # `remaining` holds the current working copy of flagdat (with .rowid).
    remaining <- shiny::reactiveVal(flagdat)

    # `removed_history` is a list of data frames, one per drag-selection batch.
    # This enables per-batch undo.
    removed_history <- shiny::reactiveVal(list())

    # Flatten removed_history into a single data frame for display.
    removed_points <- shiny::reactive({
      hist <- removed_history()
      cols <- setdiff(names(flagdat), ".rowid")
      if (length(hist) == 0L) {
        return(flagdat[0L, cols, drop = FALSE])
      }
      do.call(rbind, lapply(hist, function(x) x[, cols, drop = FALSE]))
    })

    # Track zoom/pan range so re-renders can restore the current view.
    x_range <- shiny::reactiveVal(NULL)

    shiny::observeEvent(
      plotly::event_data("plotly_relayout", session = session),
      {
        rl <- plotly::event_data("plotly_relayout", session = session)
        if (
          !is.null(rl[["xaxis.range[0]"]]) && !is.null(rl[["xaxis.range[1]"]])
        ) {
          x_range(c(rl[["xaxis.range[0]"]], rl[["xaxis.range[1]"]]))
        } else if (!is.null(rl[["xaxis.autorange"]])) {
          x_range(NULL)
        }
      }
    )

    # ---- Plot: re-renders from remaining() with zoom baked in ---------------
    # event_register is required — plotly_relayout is disabled by default.
    output$flagPlot <- plotly::renderPlotly({
      rng <- shiny::isolate(x_range())
      p <- anlzASRflag(remaining())
      p <- plotly::event_register(p, "plotly_relayout")
      if (!is.null(rng)) {
        p <- plotly::layout(
          p,
          xaxis = list(autorange = FALSE, range = as.list(rng))
        )
      }
      p
    })

    # ---- Handle box / lasso selection ---------------------------------------
    # customdata carries .rowid; unique() deduplicates points that appear in
    # both the base line trace and a flag-marker trace.
    shiny::observeEvent(
      plotly::event_data("plotly_selected", session = session),
      {
        sel <- plotly::event_data("plotly_selected", session = session)
        if (!is.data.frame(sel) || nrow(sel) == 0L) {
          return()
        }

        rowids <- unique(sel$customdata)
        dat <- remaining()
        mask <- dat$.rowid %in% rowids

        if (!any(mask)) {
          return()
        }

        to_remove <- dat[mask, , drop = FALSE]
        remaining(dat[!mask, , drop = FALSE])

        hist <- removed_history()
        removed_history(c(hist, list(to_remove)))
      }
    )

    # ---- Handle single-point click ------------------------------------------
    shiny::observeEvent(
      plotly::event_data("plotly_click", session = session),
      {
        click <- plotly::event_data("plotly_click", session = session)
        if (is.null(click)) {
          return()
        }

        rowid <- click$customdata
        dat <- remaining()
        mask <- dat$.rowid %in% rowid

        if (!any(mask)) {
          return()
        }

        to_remove <- dat[mask, , drop = FALSE]
        remaining(dat[!mask, , drop = FALSE])

        hist <- removed_history()
        removed_history(c(hist, list(to_remove)))
      }
    )

    # ---- Undo last removal batch --------------------------------------------
    shiny::observeEvent(input$undo, {
      hist <- removed_history()
      if (length(hist) == 0L) {
        return()
      }

      last_batch <- hist[[length(hist)]]
      removed_history(hist[-length(hist)])

      dat <- rbind(remaining(), last_batch)
      remaining(dat[order(dat$DateTime), , drop = FALSE])
    })

    # ---- Start over ---------------------------------------------------------
    shiny::observeEvent(input$reset, {
      remaining(flagdat)
      removed_history(list())
    })

    # ---- Done: return filtered data (sans .rowid) to the R session ----------
    shiny::observeEvent(input$done, {
      result <- remaining()
      result$.rowid <- NULL
      shiny::stopApp(returnValue = result)
    })

    # ---- Removed points count and table -------------------------------------
    output$removed_count <- shiny::renderText({
      paste("Removed Points:", nrow(removed_points()))
    })
    output$removed_table <- DT::renderDT({
      rp <- removed_points()
      if (nrow(rp) > 0L) {
        rp$DateTime <- format(rp$DateTime)
      }
      DT::datatable(
        rp,
        options = list(dom = "t", paging = FALSE, scrollX = TRUE),
        rownames = FALSE
      )
    })
  }

  # runApp() blocks until stopApp() is called; its return value is the result
  # of stopApp(), which is the filtered flagdat.
  shiny::runApp(shiny::shinyApp(ui, server))
}
