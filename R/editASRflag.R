#' Interactive flag editor for continuous monitoring data
#'
#' Opens a Shiny application displaying the QC flag plot from
#' \code{\link{anlzASRflag}} and allows the user to interactively select and
#' remove data points. Points are removed by drawing a selection rectangle on
#' the plot. A running table of removed points (including their flag
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
#'   Draw a rectangle on the plot by clicking and dragging. All points within
#'   the rectangle are removed immediately and added to the removal table. You
#'   can also use the plotly lasso tool from the mode-bar.
#' }
#'
#' \subsection{Controls}{
#'   \itemize{
#'     \item \strong{Undo Last Removal} — restores the most recently removed
#'       batch of points (one drag-selection at a time).
#'     \item \strong{Start Over} — restores all removed points and resets to
#'       the original dataset.
#'     \item \strong{Done / Close} — stops the app and returns the current
#'       filtered dataset to the R session.
#'   }
#' }
#'
#' \subsection{Shiny in a package}{
#'   The app is constructed inline so that \code{flagdat} is available directly
#'   to the server without file I/O. \code{shiny::runApp()} blocks until
#'   \code{shiny::stopApp()} is called by the Done button; its return value
#'   becomes the function return value.
#' }
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

  # anlzASRflag() adds .rowid to flagdat internally; replicate that here so
  # the proxy loop and row-matching logic have a consistent stable identifier.
  flagdat$.rowid <- seq_len(nrow(flagdat))

  flag_cols <- c("gross_flag", "spike_flag", "roc_flag", "flat_flag")

  # -------------------------------------------------------------------------
  # UI
  # -------------------------------------------------------------------------
  ui <- shiny::fluidPage(
    shiny::titlePanel(paste("Edit Flags:", param)),
    shiny::sidebarLayout(
      shiny::sidebarPanel(
        width = 3,
        shiny::h4("Controls"),
        shiny::actionButton(
          "undo",
          "Undo Last Removal",
          class = "btn-warning",
          style = "width: 100%;"
        ),
        shiny::br(),
        shiny::br(),
        shiny::actionButton(
          "reset",
          "Start Over",
          class = "btn-danger",
          style = "width: 100%;"
        ),
        shiny::br(),
        shiny::br(),
        shiny::actionButton(
          "done",
          "Done / Close",
          class = "btn-success",
          style = "width: 100%;"
        ),
        shiny::hr(),
        shiny::h4("Removed Points"),
        DT::DTOutput("removed_table")
      ),
      shiny::mainPanel(
        width = 9,
        shiny::p(
          "Zoom and pan normally with the plot toolbar.",
          "To remove points: click individual points directly, or use the",
          "\u2018Box Select\u2019 or \u2018Lasso Select\u2019 toolbar buttons to remove a region."
        ),
        plotly::plotlyOutput("flagPlot", height = "550px")
      )
    )
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

    # ---- Plot (rendered once from original flagdat) -------------------------
    # Does not depend on remaining(), so zoom/pan state is never reset by
    # a re-render. All data updates go through plotlyProxy below.
    output$flagPlot <- plotly::renderPlotly({
      anlzASRflag(flagdat)
    })

    # ---- Update traces in-place via proxy when remaining() changes ----------
    # A single restyle call updates all 9 traces simultaneously without
    # touching layout, so zoom/pan is preserved.
    shiny::observeEvent(remaining(), {
      dat   <- remaining()
      proxy <- plotly::plotlyProxy("flagPlot", session)

      xs  <- list(dat$DateTime)
      ys  <- list(dat[[param]])
      cds <- list(dat$.rowid)

      for (fc in flag_cols) {
        for (sev in c("suspect", "fail")) {
          sub <- dat[!is.na(dat[[fc]]) & dat[[fc]] == sev, , drop = FALSE]
          xs  <- c(xs,  list(sub$DateTime))
          ys  <- c(ys,  list(sub[[param]]))
          cds <- c(cds, list(sub$.rowid))
        }
      }

      plotly::plotlyProxyInvoke(
        proxy, "restyle",
        list(x = xs, y = ys, customdata = cds),
        as.list(0:8)
      )
    }, ignoreInit = TRUE)

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
        if (is.null(click)) return()

        rowid <- click$customdata
        dat   <- remaining()
        mask  <- dat$.rowid %in% rowid

        if (!any(mask)) return()

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

    # ---- Removed points table -----------------------------------------------
    output$removed_table <- DT::renderDT({
      rp <- removed_points()
      if (nrow(rp) > 0L) {
        rp$DateTime <- format(rp$DateTime)
      }
      DT::datatable(rp, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
    })
  }

  # runApp() blocks until stopApp() is called; its return value is the result
  # of stopApp(), which is the filtered flagdat.
  shiny::runApp(shiny::shinyApp(ui, server))
}
