#' Interactive editor for continuous monitoring data
#'
#' Opens a Shiny application displaying the QC flag plot from
#' \code{\link{anlzASRflag}} for each parameter in \code{contdat} and allows
#' the user to interactively select and remove data points. Points are removed
#' by clicking or drawing a selection using the box or lasso tool on the plot.
#' A running table of removed points (including their flag assignments) is shown
#' in the sidebar and is specific to the currently displayed parameter.
#' Individual removal batches can be undone, or the current parameter's session
#' can be fully reset. Clicking \strong{Done / Close} stops the app and returns
#' the filtered datasets for all parameters to the R session.
#'
#' @param cont \code{contdat} data frame returned by \code{\link{readASRcont}}
#' @param dqo \code{dqodat} data frame returned by \code{\link{readASRdqo}}
#'
#' @return A list with two elements, invisibly returned after the app closes:
#'   \describe{
#'     \item{\code{contdat}}{A data frame with the same structure as the input
#'       \code{contdat} (sorted by \code{DateTime}), where values removed by
#'       the user are replaced with \code{NA}.  Rows in which every parameter
#'       was removed are retained with only \code{DateTime} populated.}
#'     \item{\code{removed}}{A data frame of all removed observations across
#'       all parameters, with columns \code{Parameter}, \code{DateTime},
#'       \code{gross_flag}, \code{spike_flag}, \code{roc_flag}, and
#'       \code{flat_flag}.}
#'   }
#'
#' @details
#' QC flags are computed internally via \code{\link{utilASRflagall}}.
#'
#' \subsection{How to select points}{
#'   Zooming and panning with the plot toolbar is recommended to more easily
#'   identify points for removal.  These options are available in the menu on
#'   the top right when hovering over the plot.
#'
#'   Points can be selected for removal three ways.  First, individual points
#'   can be removed by clicking.  Second and third, use the box or lasso
#'   selection tool by hovering over the plot and selecting the desired tool
#'   from the menu on the top right.  Click and drag over the desired area for
#'   the box selection or click and encircle the points with the lasso tool to
#'   add the points to the removal table.  Double-click the plot background to
#'   remove the selected area if present after removal.
#' }
#'
#' \subsection{Controls}{
#'   \itemize{
#'     \item \strong{Parameter}: drop-down selector to switch between
#'       parameters.  Edits to each parameter are preserved independently when
#'       switching.
#'     \item \strong{Undo Last Removal}: restores the most recently removed
#'       point or batch of points for the current parameter (one drag-selection
#'       at a time).
#'     \item \strong{Start Over}: restores all removed points for the current
#'       parameter and resets to the original flagged dataset.
#'     \item \strong{Done / Close}: stops the app and returns the filtered
#'       datasets for all parameters to the R session.
#'   }
#' }
#'
#' The app is constructed inline so that flag data are available directly to
#' the server without file I/O. \code{shiny::runApp()} blocks until
#' \code{shiny::stopApp()} is called by the Done button; its return value
#' becomes the function return value.
#'
#' @examples
#' \dontrun{
#' contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
#' dqopth  <- system.file("extdata/ExampleDQO.xlsx", package = "AquaSensR")
#' contdat <- readASRcont(contpth)
#' dqodat  <- readASRdqo(dqopth)
#' cleaned <- editASRflag(contdat, dqodat)
#' }
#'
#' @export
editASRflag <- function(cont, dqo) {
  shiny::runApp(editASRflag_app(cont, dqo))
}

# Builds the shinyApp object without running it.  Separated from editASRflag()
# so that tests can call shiny::testServer() on the server function directly.
# Not exported.
editASRflag_app <- function(cont, dqo) {
  # Compute flags for all parameters up front
  flagdat_list <- utilASRflagall(cont, dqo)
  params <- names(flagdat_list)

  # Add stable .rowid to each flagdat
  flagdat_list <- lapply(flagdat_list, function(fd) {
    fd$.rowid <- seq_len(nrow(fd))
    fd
  })

  # Build display labels for the parameter selector
  param_labels <- vapply(
    params,
    function(p) {
      lbl <- paramsASR[paramsASR$Parameter == p, "Label"]
      if (length(lbl) == 0L || is.na(lbl[1L])) p else as.character(lbl[1L])
    },
    character(1L)
  )
  param_choices <- stats::setNames(params, param_labels)

  # -------------------------------------------------------------------------
  # UI
  # -------------------------------------------------------------------------
  ui <- bslib::page_sidebar(
    title = "Edit: QC Flags",
    sidebar = bslib::sidebar(
      width = 300,
      open = "open",
      shiny::h4("Parameter"),
      shiny::selectInput(
        "param_select",
        label = NULL,
        choices = param_choices,
        selected = params[1L]
      ),
      shiny::div(
        style = "display: flex; gap: 4px; margin-bottom: 3px;",
        shiny::actionButton(
          "param_prev",
          "\u2190 Prev",
          style = "flex: 1;"
        ),
        shiny::actionButton(
          "param_next",
          "Next \u2192",
          style = "flex: 1;"
        )
      ),
      shiny::hr(),
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
    # `remaining_list`: named list of working copies, one per parameter.
    remaining_list <- shiny::reactiveVal(flagdat_list)

    # `removed_history_list`: named list of per-parameter undo stacks.
    # Each element is a list of removed batches (data frames).
    removed_history_list <- shiny::reactiveVal(
      stats::setNames(lapply(params, function(p) list()), params)
    )

    # Track zoom/pan range; reset when the user switches parameters.
    x_range <- shiny::reactiveVal(NULL)
    shiny::observeEvent(input$param_select, {
      x_range(NULL)
    })

    shiny::observeEvent(input$param_prev, {
      idx <- match(input$param_select, params)
      if (idx > 1L) {
        shiny::updateSelectInput(
          session,
          "param_select",
          selected = params[idx - 1L]
        )
      }
    })

    shiny::observeEvent(input$param_next, {
      idx <- match(input$param_select, params)
      if (idx < length(params)) {
        shiny::updateSelectInput(
          session,
          "param_select",
          selected = params[idx + 1L]
        )
      }
    })

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

    # Convenience accessors for the current parameter's state.
    cur_remaining <- shiny::reactive(remaining_list()[[input$param_select]])
    cur_history <- shiny::reactive(removed_history_list()[[input$param_select]])

    # Helpers to write back into the named lists.
    update_remaining <- function(new_data) {
      rl <- remaining_list()
      rl[[input$param_select]] <- new_data
      remaining_list(rl)
    }
    update_history <- function(new_hist) {
      hl <- removed_history_list()
      hl[[input$param_select]] <- new_hist
      removed_history_list(hl)
    }

    # ---- Plot ---------------------------------------------------------------
    output$flagPlot <- plotly::renderPlotly({
      rng <- shiny::isolate(x_range())
      p <- anlzASRflag(cur_remaining())
      p <- plotly::event_register(p, "plotly_relayout")
      if (!is.null(rng)) {
        p <- plotly::layout(
          p,
          xaxis = list(autorange = FALSE, range = as.list(rng))
        )
      }
      p
    })

    # ---- Box / lasso selection ----------------------------------------------
    shiny::observeEvent(
      plotly::event_data("plotly_selected", session = session),
      {
        sel <- plotly::event_data("plotly_selected", session = session)
        if (!is.data.frame(sel) || nrow(sel) == 0L) {
          return()
        }

        rowids <- unique(sel$customdata)
        dat <- cur_remaining()
        mask <- dat$.rowid %in% rowids
        if (!any(mask)) {
          return()
        }

        to_remove <- dat[mask, , drop = FALSE]
        update_remaining(dat[!mask, , drop = FALSE])
        update_history(c(cur_history(), list(to_remove)))
      }
    )

    # ---- Single-point click -------------------------------------------------
    shiny::observeEvent(
      plotly::event_data("plotly_click", session = session),
      {
        click <- plotly::event_data("plotly_click", session = session)
        if (is.null(click)) {
          return()
        }

        rowid <- click$customdata
        dat <- cur_remaining()
        mask <- dat$.rowid %in% rowid
        if (!any(mask)) {
          return()
        }

        to_remove <- dat[mask, , drop = FALSE]
        update_remaining(dat[!mask, , drop = FALSE])
        update_history(c(cur_history(), list(to_remove)))
      }
    )

    # ---- Undo last removal batch (current parameter only) -------------------
    shiny::observeEvent(input$undo, {
      hist <- cur_history()
      if (length(hist) == 0L) {
        return()
      }

      last_batch <- hist[[length(hist)]]
      update_history(hist[-length(hist)])

      dat <- rbind(cur_remaining(), last_batch)
      update_remaining(dat[order(dat$DateTime), , drop = FALSE])
    })

    # ---- Start over (current parameter only) --------------------------------
    shiny::observeEvent(input$reset, {
      update_remaining(flagdat_list[[input$param_select]])
      update_history(list())
    })

    # ---- Done: return results to the R session ------------------------------
    shiny::observeEvent(input$done, {
      shiny::stopApp(
        returnValue = editASRflag_result(
          cont,
          flagdat_list,
          remaining_list()
        )
      )
    })

    # ---- Removed points count and table (current parameter) ----------------
    removed_points <- shiny::reactive({
      hist <- cur_history()
      fd <- flagdat_list[[input$param_select]]
      cols <- setdiff(names(fd), ".rowid")
      if (length(hist) == 0L) {
        return(fd[0L, cols, drop = FALSE])
      }
      do.call(rbind, lapply(hist, function(x) x[, cols, drop = FALSE]))
    })

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

  shiny::shinyApp(ui, server)
}

# Computes the editASRflag return value from the final reactive state.
# Separated so tests can verify the output logic without triggering stopApp.
# Not exported.
editASRflag_result <- function(cont, flagdat_list, remaining_list) {
  params <- names(flagdat_list)

  # cont sorted by DateTime, with removed values replaced by NA.
  # flagdat .rowid == row index of the DateTime-sorted cont.
  out_cont <- cont[order(cont$DateTime), ]
  for (p in params) {
    removed_rowids <- setdiff(
      flagdat_list[[p]]$.rowid,
      remaining_list[[p]]$.rowid
    )
    if (length(removed_rowids) > 0L) {
      out_cont[removed_rowids, p] <- NA
    }
  }

  # All removed observations stacked into one data frame.
  removed_per_param <- lapply(params, function(p) {
    removed_rowids <- setdiff(
      flagdat_list[[p]]$.rowid,
      remaining_list[[p]]$.rowid
    )
    if (length(removed_rowids) == 0L) {
      return(NULL)
    }
    fd <- flagdat_list[[p]]
    rows <- fd[fd$.rowid %in% removed_rowids, , drop = FALSE]
    data.frame(
      Parameter = p,
      DateTime = rows$DateTime,
      gross_flag = rows$gross_flag,
      spike_flag = rows$spike_flag,
      roc_flag = rows$roc_flag,
      flat_flag = rows$flat_flag,
      stringsAsFactors = FALSE
    )
  })
  removed_per_param <- Filter(Negate(is.null), removed_per_param)
  if (length(removed_per_param) == 0L) {
    out_removed <- data.frame(
      Parameter = character(0),
      DateTime = as.POSIXct(character(0)),
      gross_flag = character(0),
      spike_flag = character(0),
      roc_flag = character(0),
      flat_flag = character(0),
      stringsAsFactors = FALSE
    )
  } else {
    out_removed <- do.call(rbind, removed_per_param)
    out_removed <- out_removed[
      order(out_removed$Parameter, out_removed$DateTime),
    ]
  }

  list(contdat = out_cont, removed = out_removed)
}
