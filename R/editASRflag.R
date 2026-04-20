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
#'     \item \strong{Overlay}: optional drop-down to display a second parameter
#'       as a gray line on a right-side y-axis, useful for spotting co-occurring
#'       changes across parameters.
#'     \item \strong{Undo Last Removal}: restores the most recently removed
#'       point or batch of points for the current parameter (one drag-selection
#'       at a time).
#'     \item \strong{Start Over}: restores all removed points for the current
#'       parameter and resets to the most recently applied DQO thresholds.
#'     \item \strong{Done / Close}: stops the app and returns the filtered
#'       datasets for all parameters to the R session.
#'   }
#' }
#'
#' \subsection{DQO Settings panel}{
#'   A collapsible panel on the right side of the plot exposes the numeric QC
#'   thresholds for the currently selected parameter.  Each of the four checks
#'   (gross range, spike, rate of change, flatline) shows independent
#'   \strong{Suspect} and \strong{Fail} threshold columns.
#'
#'   \itemize{
#'     \item \strong{Apply}: re-computes flags for the current parameter using
#'       the edited thresholds.  Previously removed points are retained.
#'     \item \strong{Reset to original}: reverts the inputs to the values
#'       supplied in \code{dqo} and re-computes flags.  Any points already
#'       removed are retained.
#'   }
#'
#'   Threshold edits are per-parameter and independent; switching parameters
#'   shows that parameter's current thresholds without affecting others.
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
      shiny::div(
        style = "display: flex; align-items: center; gap: 6px;",
        shiny::h4("Parameter", style = "margin: 0;"),
        bslib::popover(
          shiny::icon(
            "circle-info",
            style = "color: #6c757d; cursor: pointer;"
          ),
          title = "Parameter",
          "Select the parameter to review and edit. Use Prev and Next to cycle through all available parameters. Edits are tracked independently for each parameter."
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
      shiny::div(
        style = "display: flex; align-items: center; gap: 6px;",
        shiny::h4("Overlay", style = "margin: 0;"),
        bslib::popover(
          shiny::icon(
            "circle-info",
            style = "color: #6c757d; cursor: pointer;"
          ),
          title = "Overlay",
          "Optionally display a second parameter on the plot. This can help identify whether flagged observations in the current parameter can be explained with changes in another."
        )
      ),
      shiny::selectizeInput(
        "overlay_param",
        label = NULL,
        choices = c("None" = ""),
        selected = "",
        options = list(allowEmptyOption = TRUE)
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
              " restores the most recently removed point or selection batch."
            ),
            shiny::tags$li(
              shiny::tags$b("Start Over:"),
              " restores all removed points for the current parameter."
            ),
            shiny::tags$li(
              shiny::tags$b("Done / Close:"),
              " stops the app and returns the cleaned data."
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
          "Points removed during this session for the current parameter. The table shows each removed observation along with its flag values from all four QC checks."
        )
      ),
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
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        position = "right",
        open = "closed",
        title = "DQO Settings",
        width = 310,
        shiny::p(shiny::tags$small(
          "Edit thresholds and click Apply.",
          "Previously removed points are retained with DQO changes."
        )),
        shiny::div(
          style = "display: flex; gap: 4px; margin-bottom: 6px;",
          shiny::actionButton(
            "apply_dqo",
            "Apply",
            style = "flex: 1; background-color: #4a7ebf; border-color: #4a7ebf; color: #fff;"
          ),
          shiny::actionButton(
            "reset_dqo",
            "Reset to original",
            style = "flex: 1; background-color: #ebebeb;"
          )
        ),
        shiny::div(
          style = "display: flex; align-items: center; gap: 6px; margin-top: 10px;",
          shiny::h6("Gross range", style = "font-weight: bold; margin: 0;"),
          bslib::popover(
            shiny::icon(
              "circle-info",
              style = "color: #6c757d; cursor: pointer;"
            ),
            title = "Gross range",
            "Flags observations outside absolute physical or sensor limits and Fail bounds are flagged suspect."
          )
        ),
        shiny::fluidRow(
          shiny::column(
            6,
            shiny::tags$small(shiny::strong("Suspect")),
            shiny::numericInput(
              "dqo_GrMin_Suspect",
              "Min",
              value = NA,
              width = "100%"
            ),
            shiny::numericInput(
              "dqo_GrMax_Suspect",
              "Max",
              value = NA,
              width = "100%"
            )
          ),
          shiny::column(
            6,
            shiny::tags$small(shiny::strong("Fail")),
            shiny::numericInput(
              "dqo_GrMin_Fail",
              "Min",
              value = NA,
              width = "100%"
            ),
            shiny::numericInput(
              "dqo_GrMax_Fail",
              "Max",
              value = NA,
              width = "100%"
            )
          )
        ),
        shiny::hr(style = "margin: 6px 0;"),
        shiny::div(
          style = "display: flex; align-items: center; gap: 6px;",
          shiny::h6("Spike", style = "font-weight: bold; margin: 0;"),
          bslib::popover(
            shiny::icon(
              "circle-info",
              style = "color: #6c757d; cursor: pointer;"
            ),
            title = "Spike",
            "Flags abrupt step changes between consecutive observations. The absolute lag-1 difference is compared to a fixed threshold. Values at or above the threshold are flagged."
          )
        ),
        shiny::fluidRow(
          shiny::column(
            6,
            shiny::tags$small(shiny::strong("Suspect")),
            shiny::numericInput(
              "dqo_Spike_Suspect",
              "Threshold",
              value = NA,
              width = "100%"
            )
          ),
          shiny::column(
            6,
            shiny::tags$small(shiny::strong("Fail")),
            shiny::numericInput(
              "dqo_Spike_Fail",
              "Threshold",
              value = NA,
              width = "100%"
            )
          )
        ),
        shiny::hr(style = "margin: 6px 0;"),
        shiny::div(
          style = "display: flex; align-items: center; gap: 6px;",
          shiny::h6("Rate of change", style = "font-weight: bold; margin: 0;"),
          bslib::popover(
            shiny::icon(
              "circle-info",
              style = "color: #6c757d; cursor: pointer;"
            ),
            title = "Rate of change",
            "Flags steps that are large relative to recent variability. The standard deviation of the preceding window (hours) is multiplied by the SD multiplier to produce an adaptive threshold."
          )
        ),
        shiny::fluidRow(
          shiny::column(
            6,
            shiny::tags$small(shiny::strong("Suspect")),
            shiny::numericInput(
              "dqo_RoCStDv_Suspect",
              "SD mult.",
              value = NA,
              width = "100%"
            ),
            shiny::numericInput(
              "dqo_RoCHours_Suspect",
              "Window (hr)",
              value = NA,
              width = "100%"
            )
          ),
          shiny::column(
            6,
            shiny::tags$small(shiny::strong("Fail")),
            shiny::numericInput(
              "dqo_RoCStDv_Fail",
              "SD mult.",
              value = NA,
              width = "100%"
            ),
            shiny::numericInput(
              "dqo_RoCHours_Fail",
              "Window (hr)",
              value = NA,
              width = "100%"
            )
          )
        ),
        shiny::hr(style = "margin: 6px 0;"),
        shiny::div(
          style = "display: flex; align-items: center; gap: 6px;",
          shiny::h6("Flatline", style = "font-weight: bold; margin: 0;"),
          bslib::popover(
            shiny::icon(
              "circle-info",
              style = "color: #6c757d; cursor: pointer;"
            ),
            title = "Flatline",
            "Flags runs of nearly identical consecutive values. An observation is flagged if all absolute differences over the preceding N readings fall within Delta."
          )
        ),
        shiny::fluidRow(
          shiny::column(
            6,
            shiny::tags$small(shiny::strong("Suspect")),
            shiny::numericInput(
              "dqo_FlatN_Suspect",
              "N",
              value = NA,
              width = "100%"
            ),
            shiny::numericInput(
              "dqo_FlatDelta_Suspect",
              "Delta",
              value = NA,
              width = "100%"
            )
          ),
          shiny::column(
            6,
            shiny::tags$small(shiny::strong("Fail")),
            shiny::numericInput(
              "dqo_FlatN_Fail",
              "N",
              value = NA,
              width = "100%"
            ),
            shiny::numericInput(
              "dqo_FlatDelta_Fail",
              "Delta",
              value = NA,
              width = "100%"
            )
          )
        )
      ),
      plotly::plotlyOutput("flagPlot", height = "550px")
    )
  )

  # -------------------------------------------------------------------------
  # Server
  # -------------------------------------------------------------------------
  server <- function(input, output, session) {
    # Mutable copy of the DQO used for on-the-fly threshold edits.
    working_dqo <- shiny::reactiveVal(dqo)

    # Tracks the current DQO-adjusted flag baseline per parameter.
    # "Start Over" and "Done" use this so they stay consistent after DQO edits.
    base_flagdat_list <- shiny::reactiveVal(flagdat_list)

    # Pull one threshold value from a DQO data frame.
    dqo_val <- function(wd, p, flag_type, col) {
      v <- wd[wd$Parameter == p & wd$Flag == flag_type, col, drop = TRUE]
      if (length(v) == 0L) NA_real_ else v[[1L]]
    }

    # Push all 14 DQO threshold inputs for parameter p from working_dqo.
    update_dqo_inputs <- function(wd, p) {
      gv <- function(ft, col) dqo_val(wd, p, ft, col)
      shiny::updateNumericInput(
        session,
        "dqo_GrMin_Suspect",
        value = gv("Suspect", "GrMin")
      )
      shiny::updateNumericInput(
        session,
        "dqo_GrMax_Suspect",
        value = gv("Suspect", "GrMax")
      )
      shiny::updateNumericInput(
        session,
        "dqo_GrMin_Fail",
        value = gv("Fail", "GrMin")
      )
      shiny::updateNumericInput(
        session,
        "dqo_GrMax_Fail",
        value = gv("Fail", "GrMax")
      )
      shiny::updateNumericInput(
        session,
        "dqo_Spike_Suspect",
        value = gv("Suspect", "Spike")
      )
      shiny::updateNumericInput(
        session,
        "dqo_Spike_Fail",
        value = gv("Fail", "Spike")
      )
      shiny::updateNumericInput(
        session,
        "dqo_RoCStDv_Suspect",
        value = gv("Suspect", "RoCStDv")
      )
      shiny::updateNumericInput(
        session,
        "dqo_RoCHours_Suspect",
        value = gv("Suspect", "RoCHours")
      )
      shiny::updateNumericInput(
        session,
        "dqo_RoCStDv_Fail",
        value = gv("Fail", "RoCStDv")
      )
      shiny::updateNumericInput(
        session,
        "dqo_RoCHours_Fail",
        value = gv("Fail", "RoCHours")
      )
      shiny::updateNumericInput(
        session,
        "dqo_FlatN_Suspect",
        value = gv("Suspect", "FlatN")
      )
      shiny::updateNumericInput(
        session,
        "dqo_FlatDelta_Suspect",
        value = gv("Suspect", "FlatDelta")
      )
      shiny::updateNumericInput(
        session,
        "dqo_FlatN_Fail",
        value = gv("Fail", "FlatN")
      )
      shiny::updateNumericInput(
        session,
        "dqo_FlatDelta_Fail",
        value = gv("Fail", "FlatDelta")
      )
    }

    # Re-flag parameter p with wd, retaining any points already removed.
    reflag_param <- function(wd, p) {
      removed_rowids <- setdiff(
        base_flagdat_list()[[p]]$.rowid,
        cur_remaining()$.rowid
      )

      working_dqo(wd)
      new_fd <- utilASRflag(cont, wd, param = p)
      new_fd$.rowid <- seq_len(nrow(new_fd))

      bfl <- base_flagdat_list()
      bfl[[p]] <- new_fd
      base_flagdat_list(bfl)

      rl <- remaining_list()
      hl <- removed_history_list()
      if (length(removed_rowids) > 0L) {
        rl[[p]] <- new_fd[!new_fd$.rowid %in% removed_rowids, , drop = FALSE]
        hl[[p]] <- list(new_fd[
          new_fd$.rowid %in% removed_rowids,
          ,
          drop = FALSE
        ])
      } else {
        rl[[p]] <- new_fd
        hl[[p]] <- list()
      }
      remaining_list(rl)
      removed_history_list(hl)
    }

    # Populate overlay choices on startup, excluding the initially selected param.
    shiny::observe({
      others <- params[params != input$param_select]
      shiny::updateSelectInput(
        session,
        "overlay_param",
        choices = c("None" = "", stats::setNames(others, param_labels[others])),
        selected = ""
      )
      update_dqo_inputs(working_dqo(), input$param_select)
    }) |>
      shiny::bindEvent(TRUE, once = TRUE)

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
      others <- params[params != input$param_select]
      shiny::updateSelectInput(
        session,
        "overlay_param",
        choices = c("None" = "", stats::setNames(others, param_labels[others])),
        selected = ""
      )
      update_dqo_inputs(working_dqo(), input$param_select)
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
      ovl_param <- input$overlay_param
      ovl <- if (
        !is.null(ovl_param) && nzchar(ovl_param) && ovl_param %in% names(cont)
      ) {
        cont[, c("DateTime", ovl_param), drop = FALSE]
      } else {
        NULL
      }
      p <- anlzASRflag(cur_remaining(), overlay = ovl)
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

    # ---- Apply DQO edits and re-flag (current parameter only) ---------------
    shiny::observeEvent(input$apply_dqo, {
      p <- input$param_select
      if (is.null(p)) {
        return()
      }
      wd <- working_dqo()
      sm <- wd$Parameter == p & wd$Flag == "Suspect"
      fm <- wd$Parameter == p & wd$Flag == "Fail"
      wd[sm, "GrMin"] <- input$dqo_GrMin_Suspect
      wd[sm, "GrMax"] <- input$dqo_GrMax_Suspect
      wd[sm, "Spike"] <- input$dqo_Spike_Suspect
      wd[sm, "RoCStDv"] <- input$dqo_RoCStDv_Suspect
      wd[sm, "RoCHours"] <- input$dqo_RoCHours_Suspect
      wd[sm, "FlatN"] <- input$dqo_FlatN_Suspect
      wd[sm, "FlatDelta"] <- input$dqo_FlatDelta_Suspect
      wd[fm, "GrMin"] <- input$dqo_GrMin_Fail
      wd[fm, "GrMax"] <- input$dqo_GrMax_Fail
      wd[fm, "Spike"] <- input$dqo_Spike_Fail
      wd[fm, "RoCStDv"] <- input$dqo_RoCStDv_Fail
      wd[fm, "RoCHours"] <- input$dqo_RoCHours_Fail
      wd[fm, "FlatN"] <- input$dqo_FlatN_Fail
      wd[fm, "FlatDelta"] <- input$dqo_FlatDelta_Fail
      reflag_param(wd, p)
    })

    # ---- Reset DQO to original values (current parameter only) --------------
    shiny::observeEvent(input$reset_dqo, {
      p <- input$param_select
      if (is.null(p)) {
        return()
      }

      wd <- working_dqo()
      orig <- dqo[dqo$Parameter == p, , drop = FALSE]
      for (ft in c("Suspect", "Fail")) {
        wd_mask <- wd$Parameter == p & wd$Flag == ft
        orig_mask <- orig$Flag == ft
        if (any(wd_mask) && any(orig_mask)) {
          wd[wd_mask, ] <- orig[orig_mask, ]
        }
      }
      update_dqo_inputs(wd, p)
      reflag_param(wd, p)
    })

    # ---- Start over (current parameter only) --------------------------------
    shiny::observeEvent(input$reset, {
      shiny::showModal(shiny::modalDialog(
        "This will restore all removed points for the current parameter. Proceed?",
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
      update_remaining(base_flagdat_list()[[input$param_select]])
      update_history(list())
    })

    # ---- Done: confirm then return results to the R session -----------------
    shiny::observeEvent(input$done, {
      shiny::showModal(shiny::modalDialog(
        "Are you sure you want to close the app?",
        title = "Done / Close",
        footer = shiny::tagList(
          shiny::modalButton("Cancel"),
          shiny::actionButton("done_confirm", "Close",
            style = "background-color: #037B71; border-color: #037B71; color: #fff;")
        ),
        easyClose = TRUE
      ))
    })

    shiny::observeEvent(input$done_confirm, {
      shiny::removeModal()
      shiny::stopApp(
        returnValue = editASRflag_result(
          cont,
          base_flagdat_list(),
          remaining_list()
        )
      )
    })

    # ---- Removed points count and table (current parameter) ----------------
    removed_points <- shiny::reactive({
      hist <- cur_history()
      fd <- base_flagdat_list()[[input$param_select]]
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
