#' Interactive drift correction editor
#'
#' Opens a Shiny application for interactively correcting instrument drift in
#' continuous water quality monitoring data.  Click the plot twice to mark the
#' start and end of a drift period, enter the reference value measured by an
#' independent calibrated instrument at the end of the deployment, and click
#' \strong{Apply Correction}.  A third click resets the selection.
#'
#' @param cont \code{contdat} data frame returned by \code{\link{readASRcont}}
#'
#' @return A list with two elements, invisibly returned after the app closes:
#'   \describe{
#'     \item{\code{contdat}}{A data frame with the same structure as the input
#'       \code{cont} (sorted by \code{DateTime}), with drift-corrected values
#'       replacing the originals in all corrected windows.}
#'     \item{\code{corrections}}{A data frame summarising every correction
#'       applied, with columns \code{Parameter}, \code{drift_start},
#'       \code{drift_end}, \code{cal_ref}, \code{cal_check}, and
#'       \code{drift_applied}.}
#'   }
#'
#' @details
#' \subsection{How to correct drift}{
#'   Zoom and pan with the plot toolbar to identify the drift period.  Click
#'   once to set the start time and click again to set the end time.  Clicking
#'   a third time resets the selection.  Once two times are selected, enter the
#'   \strong{Reference value} (the true reading from an independent calibrated
#'   instrument at the end of the deployment) and click
#'   \strong{Apply Correction}.
#'
#'   The \code{cal_check} value (the deployed sensor reading at the end of the
#'   window) is inferred automatically from the data.  The correction is
#'   distributed linearly across the window: zero at the start, full correction
#'   at the end.  See \code{\link{utilASRdrift}} for the algorithm.
#'
#'   Multiple corrections can be applied per parameter (e.g., one per
#'   deployment period), and each can be individually undone.
#' }
#'
#' \subsection{Controls}{
#'   \itemize{
#'     \item \strong{Parameter}: drop-down selector to switch between
#'       parameters.  Corrections are tracked independently for each parameter.
#'     \item \strong{Undo Last Correction}: reverses the most recently applied
#'       correction for the current parameter.
#'     \item \strong{Start Over}: restores all original values for every
#'       parameter and clears the corrections log.
#'     \item \strong{Export Progress}: saves the current corrected data and
#'       corrections log as Excel files in a ZIP archive.
#'     \item \strong{Done / Close}: stops the app and returns the corrected
#'       data and corrections summary to the R session.
#'   }
#' }
#'
#' @examples
#' \dontrun{
#' contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
#' contdat <- readASRcont(contpth)
#' result  <- editASRdrift(contdat)
#' }
#'
#' @export
editASRdrift <- function(cont) {
  shiny::runApp(editASRdrift_app(cont))
}

# Builds the shinyApp object without running it.  Separated from editASRdrift()
# so tests can call shiny::testServer() on the server function directly.
# Not exported.
editASRdrift_app <- function(cont) {

  params <- setdiff(names(cont), "DateTime")

  tz <- attr(cont$DateTime, "tzone")
  if (is.null(tz) || !nzchar(tz)) tz <- "UTC"

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
    title = "Edit: Drift Correction",
    sidebar = bslib::sidebar(
      width = 300,
      open = "open",
      shiny::div(
        style = "display: flex; align-items: center; gap: 6px;",
        shiny::h4("Parameter", style = "margin: 0;"),
        bslib::popover(
          shiny::icon("circle-info", style = "color: #6c757d; cursor: pointer;"),
          title = "Parameter",
          "Select the parameter to review and correct. Use Prev and Next to cycle through all available parameters. Corrections are tracked independently for each parameter."
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
        shiny::h4("Drift Period", style = "margin: 0;"),
        bslib::popover(
          shiny::icon("circle-info", style = "color: #6c757d; cursor: pointer;"),
          title = "Drift Period",
          "Click the plot once to set the start of the drift window, then click again to set the end. A third click resets the selection. Once two times are selected, enter the reference value and click Apply Correction."
        )
      ),
      shiny::verbatimTextOutput("selected_period"),
      shiny::uiOutput("cal_ref_ui"),
      shiny::hr(),
      shiny::div(
        style = "display: flex; align-items: center; gap: 6px;",
        shiny::h4("Controls", style = "margin: 0;"),
        bslib::popover(
          shiny::icon("circle-info", style = "color: #6c757d; cursor: pointer;"),
          title = "Controls",
          shiny::tags$ul(
            style = "padding-left: 1.2em; margin: 0;",
            shiny::tags$li(
              shiny::tags$b("Undo Last Correction:"),
              " reverses the most recently applied correction for the current parameter."
            ),
            shiny::tags$li(
              shiny::tags$b("Start Over:"),
              " restores all original values for every parameter and clears the corrections log."
            ),
            shiny::tags$li(
              shiny::tags$b("Export Progress:"),
              " saves the current corrected data and corrections log as Excel files in a ZIP archive."
            ),
            shiny::tags$li(
              shiny::tags$b("Done / Close:"),
              " stops the app and returns the corrected data."
            )
          )
        )
      ),
      shiny::actionButton(
        "undo",
        "Undo Last Correction",
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
        shiny::h4(shiny::textOutput("corrections_count", inline = TRUE), style = "margin: 0;"),
        bslib::popover(
          shiny::icon("circle-info", style = "color: #6c757d; cursor: pointer;"),
          title = "Corrections Log",
          "All corrections applied during this session across all parameters, in order. Each row shows the parameter, drift window, reference value, inferred sensor check value, and total drift applied."
        )
      ),
      shiny::div(
        style = "font-size: 12px;",
        DT::DTOutput("corrections_table")
      )
    ),
    shiny::tags$head(shiny::tags$script(shiny::HTML(
      'document.addEventListener("click", function(e) {
         var el = document.getElementById("driftPlot");
         if (!el) return;
         var btn = e.target.closest("[data-title]");
         if (!btn || btn.dataset.title !== "Reset axes" || !el.contains(btn)) return;
         e.stopPropagation();
         Plotly.relayout(el, {"xaxis.autorange": true, "yaxis.autorange": true});
       }, true);
       Shiny.addCustomMessageHandler("closeWindow", function(msg) {
         window.close();
       });'
    ))),
    shiny::p(
      "Click the plot twice to select the start and end of the drift period.",
      "A third click resets the selection.",
      "Zoom and pan with the toolbar (visible when the pointer is over the plot) to inspect the data."
    ),
    plotly::plotlyOutput("driftPlot", height = "550px")
  )

  # -------------------------------------------------------------------------
  # Server
  # -------------------------------------------------------------------------
  server <- function(input, output, session) {

    working_cont    <- shiny::reactiveVal(cont)
    selected_points <- shiny::reactiveVal(list())
    plot_ranges     <- shiny::reactiveVal(list(x = NULL, y = NULL))

    correction_history_list <- shiny::reactiveVal(
      stats::setNames(lapply(params, function(p) list()), params)
    )

    empty_log <- data.frame(
      Parameter     = character(0),
      drift_start   = as.POSIXct(character(0), tz = tz),
      drift_end     = as.POSIXct(character(0), tz = tz),
      cal_ref       = numeric(0),
      cal_check     = numeric(0),
      drift_applied = numeric(0),
      stringsAsFactors = FALSE
    )
    corrections_log <- shiny::reactiveVal(empty_log)

    cur_history <- shiny::reactive(correction_history_list()[[input$param_select]])

    update_history <- function(new_hist) {
      hl <- correction_history_list()
      hl[[input$param_select]] <- new_hist
      correction_history_list(hl)
    }

    # ---- Parameter navigation -----------------------------------------------
    shiny::observeEvent(input$param_select, {
      plot_ranges(list(x = NULL, y = NULL))
      selected_points(list())
    })

    shiny::observeEvent(input$param_prev, {
      idx <- match(input$param_select, params)
      if (idx > 1L) {
        shiny::updateSelectInput(session, "param_select", selected = params[idx - 1L])
      }
    })

    shiny::observeEvent(input$param_next, {
      idx <- match(input$param_select, params)
      if (idx < length(params)) {
        shiny::updateSelectInput(session, "param_select", selected = params[idx + 1L])
      }
    })

    # ---- Zoom state ---------------------------------------------------------
    shiny::observeEvent(
      plotly::event_data("plotly_relayout", session = session),
      {
        ev <- plotly::event_data("plotly_relayout", session = session)
        pr <- plot_ranges()
        if (!is.null(ev[["xaxis.range[0]"]]) && !is.null(ev[["xaxis.range[1]"]])) {
          pr$x <- c(ev[["xaxis.range[0]"]], ev[["xaxis.range[1]"]])
        }
        if (!is.null(ev[["yaxis.range[0]"]]) && !is.null(ev[["yaxis.range[1]"]])) {
          pr$y <- c(ev[["yaxis.range[0]"]], ev[["yaxis.range[1]"]])
        }
        if (!is.null(ev[["xaxis.autorange"]]) || !is.null(ev[["yaxis.autorange"]])) {
          pr$x <- NULL
          pr$y <- NULL
        }
        plot_ranges(pr)
      }
    )

    # ---- Click to mark drift period endpoints -------------------------------
    shiny::observeEvent(
      plotly::event_data("plotly_click", session = session),
      {
        click <- plotly::event_data("plotly_click", session = session)
        if (is.null(click)) return()

        current_pts <- selected_points()
        if (length(current_pts) >= 2L) {
          selected_points(list())
          return()
        }

        # Snap click x to the nearest DateTime in the data
        click_ts <- as.POSIXct(click$x, origin = "1970-01-01", tz = tz)
        dat <- working_cont()
        nearest <- dat$DateTime[which.min(abs(as.numeric(dat$DateTime) - as.numeric(click_ts)))]
        selected_points(c(current_pts, list(nearest)))
      }
    )

    # ---- Selected period display --------------------------------------------
    output$selected_period <- shiny::renderText({
      pts <- selected_points()
      if (length(pts) == 0L) return("Click plot to select start of drift period.")
      if (length(pts) == 1L) {
        return(paste0("Start: ", format(pts[[1L]]), "\nClick again to select end."))
      }
      paste0("Start: ", format(pts[[1L]]), "\nEnd:   ", format(pts[[2L]]))
    })

    # ---- Conditional reference value input and Apply button -----------------
    output$cal_ref_ui <- shiny::renderUI({
      if (length(selected_points()) == 2L) {
        shiny::tagList(
          shiny::numericInput(
            "cal_ref",
            "Reference value (independent sonde)",
            value = NA,
            min = 0,
            max = NA,
            step = 0.01
          ),
          shiny::actionButton(
            "apply_correction",
            "Apply Correction",
            style = "width: 100%; background-color: #4a7ebf; border-color: #4a7ebf; color: #fff; margin-top: 4px;"
          )
        )
      }
    })

    # ---- Apply drift correction ---------------------------------------------
    shiny::observeEvent(input$apply_correction, {
      pts <- selected_points()
      if (length(pts) < 2L) return()
      if (is.null(input$cal_ref) || is.na(input$cal_ref)) return()

      p           <- input$param_select
      t1          <- min(pts[[1L]], pts[[2L]])
      t2          <- max(pts[[1L]], pts[[2L]])
      cal_ref_val <- input$cal_ref

      dat       <- working_cont()
      in_window <- dat$DateTime >= t1 & dat$DateTime <= t2
      if (!any(in_window)) return()

      window_vals   <- dat[[p]][in_window]
      cal_check_val <- window_vals[length(window_vals)]

      # Save pre-correction values for undo
      update_history(c(cur_history(), list(list(pre_values = dat[[p]]))))

      working_cont(utilASRdrift(dat, p, cal_ref_val, t1, t2))

      new_row <- data.frame(
        Parameter     = p,
        drift_start   = t1,
        drift_end     = t2,
        cal_ref       = cal_ref_val,
        cal_check     = cal_check_val,
        drift_applied = round(cal_ref_val - cal_check_val, 4L),
        stringsAsFactors = FALSE
      )
      corrections_log(rbind(corrections_log(), new_row))

      selected_points(list())
    })

    # ---- Undo last correction (current parameter) ---------------------------
    shiny::observeEvent(input$undo, {
      hist <- cur_history()
      if (length(hist) == 0L) return()

      last_entry <- hist[[length(hist)]]
      update_history(hist[-length(hist)])

      p    <- input$param_select
      dat  <- working_cont()
      dat[[p]] <- last_entry$pre_values
      working_cont(dat)

      log        <- corrections_log()
      param_rows <- which(log$Parameter == p)
      if (length(param_rows) > 0L) {
        corrections_log(log[-param_rows[length(param_rows)], , drop = FALSE])
      }
    })

    # ---- Start Over (all parameters) ----------------------------------------
    shiny::observeEvent(input$reset, {
      shiny::showModal(shiny::modalDialog(
        "This will restore all original values for every parameter and clear the corrections log. Proceed?",
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
      working_cont(cont)
      correction_history_list(
        stats::setNames(lapply(params, function(p) list()), params)
      )
      corrections_log(empty_log)
      selected_points(list())
    })

    # ---- Done / Close -------------------------------------------------------
    shiny::observeEvent(input$done, {
      shiny::showModal(shiny::modalDialog(
        "Are you sure you want to close the app?",
        title = "Done / Close",
        footer = shiny::tagList(
          shiny::modalButton("Cancel"),
          shiny::actionButton(
            "done_confirm",
            "Close",
            style = "background-color: #037B71; border-color: #037B71; color: #fff;"
          )
        ),
        easyClose = TRUE
      ))
    })

    shiny::observeEvent(input$done_confirm, {
      shiny::removeModal()
      session$sendCustomMessage("closeWindow", list())
      shiny::stopApp(
        returnValue = editASRdrift_result(working_cont(), corrections_log())
      )
    })

    # ---- Export Progress ----------------------------------------------------
    output$export_progress <- shiny::downloadHandler(
      filename = function() {
        paste0("AquaSensR_drift_export_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".zip")
      },
      content = function(file) {
        res <- editASRdrift_result(working_cont(), corrections_log())
        fmt_dt <- function(df) {
          for (col in names(df)) {
            if (inherits(df[[col]], "POSIXct")) df[[col]] <- format(df[[col]])
          }
          df
        }
        tmp_dir <- tempfile()
        dir.create(tmp_dir)
        files_to_zip <- character(0)

        cont_path <- file.path(tmp_dir, "contdat.xlsx")
        writexl::write_xlsx(fmt_dt(res$contdat), cont_path)
        files_to_zip <- c(files_to_zip, cont_path)

        if (nrow(res$corrections) > 0L) {
          corr_path <- file.path(tmp_dir, "corrections.xlsx")
          writexl::write_xlsx(fmt_dt(res$corrections), corr_path)
          files_to_zip <- c(files_to_zip, corr_path)
        }

        zip::zip(file, files = files_to_zip, mode = "cherry-pick")
      }
    )

    # ---- Plot ---------------------------------------------------------------
    output$driftPlot <- plotly::renderPlotly({
      p_name <- input$param_select
      dat    <- working_cont()
      pts    <- selected_points()

      lbl     <- paramsASR[paramsASR$Parameter == p_name, "Label"]
      y_label <- if (length(lbl) == 0L || is.na(lbl[1L])) p_name else as.character(lbl[1L])

      p <- plotly::plot_ly(dat, x = ~DateTime) |>
        plotly::add_trace(
          y         = dat[[p_name]],
          name      = y_label,
          type      = "scatter",
          mode      = "lines",
          line      = list(color = "#1f77b4")
        ) |>
        plotly::layout(
          xaxis     = list(title = ""),
          yaxis     = list(title = y_label),
          clickmode = "event"
        )

      # Add vertical markers for selected period endpoints.
      # Y range is locked to the data range to prevent the segments from
      # expanding the axis beyond the actual data.
      if (length(pts) > 0L) {
        y_vals <- dat[[p_name]]
        y_rng  <- range(y_vals, na.rm = TRUE)
        rng_y  <- shiny::isolate(plot_ranges()$y)
        if (!is.null(rng_y)) y_rng <- rng_y

        line_colors <- c("#e41a1c", "#984ea3")
        for (i in seq_along(pts)) {
          p <- p |> plotly::add_segments(
            x         = pts[[i]], xend = pts[[i]],
            y         = y_rng[1L], yend = y_rng[2L],
            line      = list(color = line_colors[i], dash = "dash", width = 1.5),
            showlegend = FALSE,
            hoverinfo = "none"
          )
        }
        p <- plotly::layout(p, yaxis = list(autorange = FALSE, range = as.list(y_rng)))
      }

      p <- plotly::event_register(p, "plotly_relayout")

      rng <- shiny::isolate(plot_ranges())
      if (!is.null(rng$x)) {
        p <- plotly::layout(p, xaxis = list(autorange = FALSE, range = as.list(rng$x)))
      }
      if (!is.null(rng$y) && length(pts) == 0L) {
        p <- plotly::layout(p, yaxis = list(autorange = FALSE, range = as.list(rng$y)))
      }

      p
    })

    # ---- Corrections count and table ----------------------------------------
    output$corrections_count <- shiny::renderText({
      paste("Corrections Log:", nrow(corrections_log()))
    })

    output$corrections_table <- DT::renderDT({
      log <- corrections_log()
      display <- log
      for (col in c("drift_start", "drift_end")) {
        if (col %in% names(display)) display[[col]] <- format(display[[col]])
      }
      DT::datatable(
        display,
        options  = list(dom = "t", paging = FALSE, scrollX = TRUE),
        rownames = FALSE
      )
    })

  }

  shiny::shinyApp(ui, server)
}

# Computes the editASRdrift return value from the final reactive state.
# Not exported.
editASRdrift_result <- function(working_cont, corrections_log) {
  list(
    contdat     = working_cont[order(working_cont$DateTime), ],
    corrections = corrections_log
  )
}

