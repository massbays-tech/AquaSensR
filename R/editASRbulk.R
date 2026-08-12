#' Interactive bulk removal editor
#'
#' Opens a Shiny application for quickly removing a contiguous stretch of
#' continuous monitoring data across every parameter at once, typically
#' because a sensor was out of the water at the start, end, or middle of a
#' deployment. Removal is always linked so that a selection made while viewing one
#' parameter removes the same timestamps from every other parameter.
#' Unlike \code{\link{editASRflag}}, no QC flags are computed and no DQO
#' thresholds are involved. This is a coarse first pass meant to run before
#' other QC processes.
#'
#' @param cont \code{contdat} data frame returned by \code{\link{readASRcont}},
#'   or the \code{contdat} element of a previous \code{editASRbulk} result for
#'   iterative editing.
#' @param removed Optional data frame: the \code{removed} element returned by
#'   a previous call to \code{editASRbulk} (or a compatible \code{removed}
#'   data frame from \code{\link{editASRflag}}, since both share the same
#'   \code{Parameter}/\code{DateTime}/\code{Value} columns). When supplied,
#'   the corresponding timestamps are pre-populated as removed (excluded from
#'   the plot, shown in the Removed Points table) without any new action.
#'
#' @return A list with two elements, invisibly returned after the app closes:
#'   \describe{
#'     \item{\code{contdat}}{A data frame with the same structure as the input
#'       \code{cont} (sorted by \code{DateTime}), where every parameter at a
#'       removed timestamp is replaced with \code{NA}. Rows are retained with only \code{DateTime}
#'       populated.}
#'     \item{\code{removed}}{A data frame of all removed observations across
#'       all parameters, with columns \code{Parameter}, \code{DateTime}, and
#'       \code{Value}. Can be passed as the \code{removed} argument to a later
#'       \code{editASRbulk}.}
#'   }
#'
#' @details
#' \subsection{How to select a range}{
#'   Zooming and panning with the plot toolbar is recommended to more easily
#'   identify the portion to remove. Hover over the plot and choose the
#'   \strong{Box Select} or \strong{Lasso Select} tool from the menu on the
#'   top right, then click and drag (box) or click and encircle (lasso) the
#'   points to remove. The removal applies to every parameter at those
#'   timestamps, not just the one currently displayed.
#' }
#'
#' \subsection{Controls}{
#'   \itemize{
#'     \item \strong{Parameter}: drop-down selector to switch between
#'       parameters. Removed timestamps are shared across all parameters, so
#'       switching parameters never changes what has been removed.
#'     \item \strong{Undo Last Removal}: restores the most recently removed
#'       selection, across every parameter.
#'     \item \strong{Start Over}: undoes all removals made in the current
#'       session, reverting to the state the app was in when it opened. Any
#'       removals passed in via the \code{removed} argument are preserved.
#'     \item \strong{Export Progress}: saves the current cleaned data as an
#'       Excel file in a ZIP archive. If any points have been removed, a
#'       removed-observations file is included as well.
#'     \item \strong{Done / Close}: stops the app. Choosing
#'       \strong{Close, save edits} returns the filtered data for all
#'       parameters whereas choosing \strong{Close, discard edits} returns the
#'       original unmodified data. Closing the browser tab or window
#'       directly (without clicking \strong{Done / Close}) also saves edits,
#'       equivalent to \strong{Close, save edits}. Refreshing the page has
#'       the same effect.
#'   }
#' }
#'
#' @examples
#' \dontrun{
#' contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
#' contdat <- readASRcont(contpth)
#'
#' # First session: trim obvious out-of-water stretches
#' trimmed <- editASRbulk(contdat)
#' }
#'
#' @export
editASRbulk <- function(cont, removed = NULL) {
  shiny::runApp(editASRbulk_app(cont, removed = removed))
}

# Builds the shinyApp object without running it. Separated from editASRbulk()
# so that tests can call shiny::testServer() on the server function directly.
# Not exported.
#
# @param cont    contdat data frame (see editASRbulk).
# @param removed Optional removed data frame (see editASRbulk).
editASRbulk_app <- function(cont, removed = NULL) {
  full_cont <- cont[order(cont$DateTime), ]
  full_cont$.rowid <- seq_len(nrow(full_cont))
  params <- setdiff(names(full_cont), c("DateTime", ".rowid"))

  tz <- attr(full_cont$DateTime, "tzone")
  if (is.null(tz) || !nzchar(tz)) {
    tz <- "UTC"
  }

  param_labels <- vapply(
    params,
    function(p) {
      lbl <- paramsASR$Label[paramsASR$Parameter == p]
      if (length(lbl) == 0L || is.na(lbl[1L])) p else as.character(lbl[1L])
    },
    character(1L)
  )
  param_choices <- stats::setNames(params, param_labels)

  # Prior removals become the initial history entry, preserved through
  # "Start Over" and returned by "Close, discard edits". Only
  # Parameter/DateTime/Value are used, so a `removed` argument carried over
  # from editASRflag() (which also has flag columns) works unmodified.
  init_history <- if (!is.null(removed) && nrow(removed) > 0L) {
    list(removed[, c("Parameter", "DateTime", "Value"), drop = FALSE])
  } else {
    list()
  }
  init_removed_points <- if (length(init_history) == 0L) {
    NULL
  } else {
    do.call(rbind, init_history)
  }

  empty_removed <- data.frame(
    Parameter = character(0),
    DateTime = as.POSIXct(character(0), tz = tz),
    Value = numeric(0),
    stringsAsFactors = FALSE
  )
  if (is.null(init_removed_points)) {
    init_removed_points <- empty_removed
  }

  # -------------------------------------------------------------------------
  # UI
  # -------------------------------------------------------------------------
  ui <- bslib::page_sidebar(
    title = "Edit: Bulk Removal",
    sidebar = bslib::sidebar(
      width = 300,
      open = "open",
      shiny::div(
        style = "display: flex; align-items: center; gap: 6px;",
        shiny::h4("Parameter", style = "margin: 0;"),
        bslib::popover(
          shiny::icon(
            "circle-info",
            style = "color: #6c757d; cursor: pointer;"
          ),
          title = "Parameter",
          "Select the parameter to display. Removed timestamps apply to every parameter, so switching parameters never changes what has been removed."
        )
      ),
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
          style = "flex: 1; background-color: #ebebeb;"
        ),
        shiny::actionButton(
          "param_next",
          "Next \u2192",
          style = "flex: 1; background-color: #ebebeb;"
        )
      ),
      shiny::hr(),
      shiny::div(
        style = "display: flex; align-items: center; gap: 6px;",
        shiny::h4("Controls", style = "margin: 0;"),
        bslib::popover(
          shiny::icon(
            "circle-info",
            style = "color: #6c757d; cursor: pointer;"
          ),
          title = "Controls",
          shiny::tags$ul(
            style = "padding-left: 1.2em; margin: 0;",
            shiny::tags$li(
              shiny::tags$b("Undo Last Removal:"),
              " restores the most recently removed selection, across every parameter."
            ),
            shiny::tags$li(
              shiny::tags$b("Start Over:"),
              " undoes all removals made in the current session, reverting to the state the app was in when it opened. Any removals loaded from a prior session are preserved."
            ),
            shiny::tags$li(
              shiny::tags$b("Export Progress:"),
              " saves the current cleaned data as an Excel file in a ZIP archive. If any points have been removed, a removed-observations file is included as well."
            ),
            shiny::tags$li(
              shiny::tags$b("Done / Close:"),
              " stops the app and returns the cleaned data."
            ),
            shiny::tags$li(
              shiny::tags$b("Closing the browser tab directly:"),
              ' also saves edits automatically, the same as "Close, save edits."',
              " If edits have been made, the browser may show its own generic",
              " warning before closing. This can be safely dismissed since the",
              " edits will still be saved."
            )
          )
        )
      ),
      shiny::actionButton(
        "undo",
        "Undo Last Removal",
        style = "width: 100%; background-color: #eee685; border-color: #eee685; color: #000000ff;"
      ),
      shiny::actionButton(
        "reset",
        "Start Over",
        style = "width: 100%; background-color: #ff6633; border-color: #ff6633; color: #fff;"
      ),
      shiny::downloadButton(
        "export_progress",
        "Export Progress",
        icon = NULL,
        style = "width: 100%; display: block; background-color: #3BAD99; border-color: #3BAD99; color: #fff;"
      ),
      shiny::actionButton(
        "done",
        "Done / Close",
        style = "width: 100%; background-color: #037B71; border-color: #037B71; color: #fff;"
      ),
      shiny::hr(),
      shiny::div(
        style = "display: flex; align-items: center; gap: 6px;",
        shiny::h4(
          shiny::textOutput("removed_count", inline = TRUE),
          style = "margin: 0;"
        ),
        bslib::popover(
          shiny::icon(
            "circle-info",
            style = "color: #6c757d; cursor: pointer;"
          ),
          title = "Removed Points",
          "Every observation removed during this session, across all parameters."
        )
      ),
      shiny::div(
        style = "font-size: 12px;",
        DT::DTOutput("removed_table")
      )
    ),
    shiny::tags$head(shiny::tags$script(shiny::HTML(
      'document.addEventListener("click", function(e) {
         var el = document.getElementById("bulkPlot");
         if (!el) return;
         var btn = e.target.closest("[data-title]");
         if (!btn || btn.dataset.title !== "Reset axes" || !el.contains(btn)) return;
         e.stopPropagation();
         Plotly.relayout(el, {"xaxis.autorange": true, "yaxis.autorange": true});
       }, true);
       var appDirty = false;
       window.addEventListener("beforeunload", function (e) {
         if (!appDirty) return;
         e.preventDefault();
         e.returnValue =
           "Closing without using Done / Close will automatically save your current edits.";
         return e.returnValue;
       });
       Shiny.addCustomMessageHandler("setDirty", function(msg) {
         appDirty = msg.dirty;
       });
       Shiny.addCustomMessageHandler("closeWindow", function(msg) {
         appDirty = false;
         window.close();
       });'
    ))),
    shiny::p(
      "Zoom and pan normally with the plot toolbar visible on the top right when the pointer is over the plot.",
      "To remove a stretch of data, use the \u2018Box Select\u2019 or \u2018Lasso Select\u2019 toolbar buttons.",
      "The removal applies to every parameter at those timestamps, not just the one shown.",
      "Double-click the plot background to clear a selection and start a new one."
    ),
    plotly::plotlyOutput("bulkPlot", height = "550px")
  )

  # -------------------------------------------------------------------------
  # Server
  # -------------------------------------------------------------------------
  server <- function(input, output, session) {
    plot_ranges <- shiny::reactiveVal(list(x = NULL, y = NULL))

    # `history`: single global undo stack (removal is always linked, so there
    # is exactly one removal timeline shared by every parameter). Each entry
    # is a data frame with columns Parameter/DateTime/Value covering every
    # parameter at the timestamps removed together in one action.
    history <- shiny::reactiveVal(init_history)

    removed_points <- shiny::reactive({
      hist <- history()
      if (length(hist) == 0L) {
        return(empty_removed)
      }
      do.call(rbind, hist)
    })

    removed_dt <- shiny::reactive({
      rp <- removed_points()
      if (nrow(rp) == 0L) full_cont$DateTime[0L] else unique(rp$DateTime)
    })

    remaining <- shiny::reactive({
      full_cont[!full_cont$DateTime %in% removed_dt(), , drop = FALSE]
    })

    # ---- Parameter navigation -----------------------------------------------
    shiny::observeEvent(input$param_select, {
      plot_ranges(list(x = NULL, y = NULL))
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

    # ---- Zoom state ---------------------------------------------------------
    shiny::observeEvent(
      plotly::event_data("plotly_relayout", session = session),
      {
        ev <- plotly::event_data("plotly_relayout", session = session)
        pr <- plot_ranges()

        if (
          !is.null(ev[["xaxis.range[0]"]]) && !is.null(ev[["xaxis.range[1]"]])
        ) {
          pr$x <- c(ev[["xaxis.range[0]"]], ev[["xaxis.range[1]"]])
        }
        if (
          !is.null(ev[["yaxis.range[0]"]]) && !is.null(ev[["yaxis.range[1]"]])
        ) {
          pr$y <- c(ev[["yaxis.range[0]"]], ev[["yaxis.range[1]"]])
        }
        if (
          !is.null(ev[["xaxis.autorange"]]) || !is.null(ev[["yaxis.autorange"]])
        ) {
          pr$x <- NULL
          pr$y <- NULL
        }

        plot_ranges(pr)
      }
    )

    # ---- Box / lasso selection -----------------------------------------------
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

        sel_rows <- dat[mask, , drop = FALSE]
        new_batch <- do.call(
          rbind,
          lapply(params, function(p) {
            data.frame(
              Parameter = p,
              DateTime = sel_rows$DateTime,
              Value = sel_rows[[p]],
              stringsAsFactors = FALSE
            )
          })
        )
        history(c(history(), list(new_batch)))
      }
    )

    # ---- Undo last removal batch ---------------------------------------------
    shiny::observeEvent(input$undo, {
      hist <- history()
      if (length(hist) == 0L) {
        return()
      }
      history(hist[-length(hist)])
    })

    # ---- Start over (all parameters) -----------------------------------------
    shiny::observeEvent(input$reset, {
      shiny::showModal(shiny::modalDialog(
        "This will undo all removals made in the current session, reverting to the state the app was in when it opened. Proceed?",
        title = "Start Over",
        footer = shiny::tagList(
          shiny::modalButton("Cancel"),
          shiny::actionButton(
            "reset_confirm",
            "Proceed",
            style = "background-color: #ff6633; border-color: #ff6633; color: #fff;"
          )
        ),
        easyClose = TRUE
      ))
    })

    shiny::observeEvent(input$reset_confirm, {
      shiny::removeModal()
      history(init_history)
    })

    # ---- Ungraceful close safety net (browser tab/window closed without
    # clicking Done/Close, or the page was refreshed) --------------------------
    app_closing <- FALSE

    has_unsaved_edits <- shiny::reactive({
      length(history()) != length(init_history)
    })

    shiny::observe({
      session$sendCustomMessage("setDirty", list(dirty = has_unsaved_edits()))
    })

    session$onSessionEnded(function() {
      if (isTRUE(app_closing) || inherits(session, "MockShinySession")) {
        return(invisible(NULL))
      }
      shiny::isolate(
        shiny::stopApp(
          returnValue = editASRbulk_result(full_cont, removed_points())
        )
      )
    })

    # ---- Done: confirm then return results to the R session -----------------
    shiny::observeEvent(input$done, {
      shiny::showModal(shiny::modalDialog(
        "Choose how to close the app.",
        title = "Done / Close",
        footer = shiny::div(
          style = "display: flex; gap: 4px; justify-content: flex-end;",
          shiny::modalButton("Cancel"),
          shiny::actionButton(
            "done_discard",
            "Close, discard edits",
            style = "background-color: #ff6633; border-color: #ff6633; color: #fff;"
          ),
          shiny::actionButton(
            "done_confirm",
            "Close, save edits",
            style = "background-color: #037B71; border-color: #037B71; color: #fff;"
          )
        ),
        easyClose = TRUE
      ))
    })

    shiny::observeEvent(input$done_discard, {
      app_closing <<- TRUE
      shiny::removeModal()
      session$sendCustomMessage("closeWindow", list())
      shiny::stopApp(
        returnValue = editASRbulk_result(full_cont, init_removed_points)
      )
    })

    shiny::observeEvent(input$done_confirm, {
      app_closing <<- TRUE
      shiny::removeModal()
      session$sendCustomMessage("closeWindow", list())
      shiny::stopApp(
        returnValue = editASRbulk_result(full_cont, removed_points())
      )
    })

    # ---- Export Progress: zip of Excel files --------------------------------
    output$export_progress <- shiny::downloadHandler(
      filename = function() {
        paste0(
          "AquaSensR_bulk_export_",
          format(Sys.time(), "%Y%m%d_%H%M%S"),
          ".zip"
        )
      },
      content = function(file) {
        res <- editASRbulk_result(full_cont, removed_points())
        fmt_dt <- function(df) {
          if ("DateTime" %in% names(df) && inherits(df$DateTime, "POSIXct")) {
            df$DateTime <- format(df$DateTime)
          }
          df
        }

        tmp_dir <- tempfile()
        dir.create(tmp_dir)
        files_to_zip <- character(0)

        cont_path <- file.path(tmp_dir, "contdat.xlsx")
        writexl::write_xlsx(fmt_dt(res$contdat), cont_path)
        files_to_zip <- c(files_to_zip, cont_path)

        if (nrow(res$removed) > 0L) {
          removed_path <- file.path(tmp_dir, "removed.xlsx")
          writexl::write_xlsx(fmt_dt(res$removed), removed_path)
          files_to_zip <- c(files_to_zip, removed_path)
        }

        zip::zip(file, files = files_to_zip, mode = "cherry-pick")
      }
    )

    # ---- Plot -----------------------------------------------------------------
    output$bulkPlot <- plotly::renderPlotly({
      p_name <- input$param_select
      if (is.null(p_name)) {
        return(NULL)
      }

      dat <- remaining()
      dat <- dat[!is.na(dat[[p_name]]), , drop = FALSE]

      lbl <- paramsASR$Label[paramsASR$Parameter == p_name]
      y_label <- if (length(lbl) == 0L || is.na(lbl[1L])) {
        p_name
      } else {
        as.character(lbl[1L])
      }

      # Invisible markers (opacity = 0) let plotly's box/lasso selection
      # target individual points; a line-only trace is not selectable.
      p <- plotly::plot_ly(
        data = dat,
        x = ~DateTime,
        y = dat[[p_name]],
        customdata = ~.rowid,
        type = "scatter",
        mode = "lines+markers",
        line = list(color = "#1f77b4", width = 1),
        marker = list(opacity = 0, size = 6),
        name = y_label,
        showlegend = FALSE,
        hovertemplate = paste0(
          "<b>",
          y_label,
          "</b>: %{y}<br>",
          "<b>DateTime</b>: %{x}",
          "<extra></extra>"
        )
      ) |>
        plotly::layout(
          xaxis = list(title = ""),
          yaxis = list(title = y_label),
          dragmode = "zoom",
          hovermode = "closest"
        ) |>
        plotly::config(
          displaylogo = FALSE,
          modeBarButtonsToRemove = c(
            "zoomIn2d",
            "zoomOut2d",
            "autoScale2d",
            "hoverClosestCartesian",
            "hoverCompareCartesian",
            "toggleSpikelines",
            "toImage"
          )
        )

      p <- plotly::event_register(p, "plotly_relayout")
      rng <- shiny::isolate(plot_ranges())
      if (!is.null(rng$x)) {
        p <- plotly::layout(
          p,
          xaxis = list(autorange = FALSE, range = as.list(rng$x))
        )
      }
      if (!is.null(rng$y)) {
        p <- plotly::layout(
          p,
          yaxis = list(autorange = FALSE, range = as.list(rng$y))
        )
      }
      p
    })

    # ---- Removed points count and table (all parameters) --------------------
    output$removed_count <- shiny::renderText({
      paste("Removed Timestamps:", length(removed_dt()))
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

# Computes the editASRbulk return value from the final reactive state.
# Separated so tests can verify the output logic without triggering stopApp.
# Not exported.
editASRbulk_result <- function(full_cont, removed_points) {
  out_cont <- full_cont[, setdiff(names(full_cont), ".rowid"), drop = FALSE]

  if (nrow(removed_points) > 0L) {
    for (p in unique(removed_points$Parameter)) {
      if (!p %in% names(out_cont)) {
        next
      }
      dt <- removed_points$DateTime[removed_points$Parameter == p]
      out_cont[out_cont$DateTime %in% dt, p] <- NA
    }
  }

  removed_points <- removed_points[
    order(removed_points$Parameter, removed_points$DateTime),
  ]
  rownames(removed_points) <- NULL

  list(contdat = out_cont, removed = removed_points)
}
