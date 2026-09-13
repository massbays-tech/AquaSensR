#' Combined bulk removal, drift correction, and flag review workflow
#'
#' Opens a small launcher screen with one icon per step for
#' Bulk Removal, Drift Correction, and Flag Review arranged horizontally.
#' Clicking an icon opens that step's
#' editor (\code{\link{editASRbulk}}, \code{\link{editASRdrift}}, or
#' \code{\link{editASRflag}}) in place, inside the same running app. When
#' that editor's Done / Close button is clicked, the launcher screen
#' reopens with the updated data, so each step's output feeds the next
#' step's input. The arrangement of the icons implies the order of operations,
#' but any editor can be selected in any order. Click the Finish & Return to R
#' button to end the session and return the combined result.
#'
#' @param cont \code{contdat} data frame returned by \code{\link{readASRcont}}.
#' @param dqo \code{dqodat} data frame returned by \code{\link{readASRdqo}},
#'   used by the Flag Review step.
#' @param ext Optional external data frame returned by
#'   \code{\link{readASRcont}}, passed through to both the Drift Correction
#'   and Flag Review steps (see their \code{ext} argument for details).
#'
#' @return A list with five elements, invisibly returned once
#'   Finish & Return to R is clicked from the main interface:
#'   \describe{
#'     \item{\code{contdat}}{The data frame after all edits made across every
#'       step, sorted by \code{DateTime}.}
#'     \item{\code{dqodat}}{The DQO thresholds data frame, reflecting any
#'       edits made in the Flag Review step's DQO Settings panel.}
#'     \item{\code{bulk_removed}}{The Bulk Removal step's removed-points log
#'       (see \code{\link{editASRbulk}}).}
#'     \item{\code{corrections}}{The Drift Correction step's corrections log
#'       (see \code{\link{editASRdrift}}).}
#'     \item{\code{removed}}{The Flag Review step's removed-points log,
#'       including QC flag columns (see \code{\link{editASRflag}}).}
#'   }
#'
#' @details
#' Each step is the same editor used by its standalone function
#' (\code{\link{editASRbulk}}, \code{\link{editASRdrift}},
#' \code{\link{editASRflag}}), mounted in place as one step of this app
#' rather than opened as an independent process.  Each selection of Done /
#' Close save/discard within an editor behaves exactly as it does when called
#' directly.  Output from one editing section is passed to next selected editor.
#'
#' Icons are always clickable, in any order, any number of times. Every step
#' always starts from the most current data, i.e., the output of whichever
#' step was completed most recently, regardless of the icons' left-to-right
#' order (e.g. reopening Bulk Removal after Drift Correction and Flag Review
#' have already run starts from the drift-corrected, flag-cleaned data, not
#' the originally supplied \code{cont}). Its new output again feeds forward
#' into whatever step runs next. Results from steps completed earlier are
#' not automatically re-run or invalidated when an earlier step is
#' revisited.  It is up to the user to re-run any downstream steps that
#' should reflect the change.
#'
#' As in the standalone editors, closing the browser tab or window directly
#' (instead of clicking Finish & Return to R) triggers the browser's own
#' "leave site?" confirmation once any edits exist to lose, whether that is
#' from viewing an editor mid-edit or from having completed at least one step
#' without yet clicking Finish. This warning is a single safety net that
#' spans the whole session, not one per editor. Dismissing it keeps the
#' session open. Choosing to leave anyway loses only what the per-step
#' ungraceful-close safety net does not already cover: any edits made in the
#' currently open, not-yet-Done step are lost, while steps whose own
#' Done/Close has already fired are preserved and returned as if Finish had
#' been clicked.
#'
#' @examples
#' \dontrun{
#' contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
#' dqopth  <- system.file("extdata/ExampleDQO.xlsx", package = "AquaSensR")
#' contdat <- readASRcont(contpth)
#' dqodat  <- readASRdqo(dqopth)
#'
#' result <- editASRworkflow(contdat, dqodat)
#' }
#'
#' @export
editASRworkflow <- function(cont, dqo, ext = NULL) {
  shiny::runApp(editASRworkflow_app(cont, dqo, ext = ext))
}

# Builds the combined workflow shinyApp object without running it. Not
# exported. A thin id = NULL / on_finish = NULL wrapper around
# editASRworkflow_ui()/editASRworkflow_server(), the same functions used were
# this ever mounted as a step of some still-larger app.
editASRworkflow_app <- function(cont, dqo, ext = NULL) {
  ui <- editASRworkflow_ui(NULL)
  server <- function(input, output, session) {
    editASRworkflow_server(NULL, cont, dqo, ext = ext, on_finish = NULL)
  }
  shiny::shinyApp(ui, server)
}

# Builds the combined workflow's persistent shell UI: a single uiOutput that
# editASRworkflow_server() swaps between the icon-screen launcher and
# whichever step's own _ui() is currently active. Not exported.
#
# @param id Shiny module id. NULL for standalone use.
editASRworkflow_ui <- function(id = NULL) {
  ns <- shiny::NS(id)
  # A bare tagList() (unlike each step's own bslib::page_sidebar()) is not a
  # bslib "page" object, so it never gets the <body>-level fillable setup
  # bslib normally establishes for its top-level ui -- without it, a step's
  # sidebar mounted below (inside uiOutput(), itself just an ordinary,
  # non-participating div by default) has no height-constrained ancestor to
  # fill, so it grows to fit its content instead of scrolling internally.
  # page_fillable() plus fill = TRUE on the dynamic uiOutput() gives both
  # ends of that chain what they need to participate correctly.
  bslib::page_fillable(
    padding = 0,
    title = "AquaSensR Workflow",
    if (is.null(id)) {
      # Standalone only -- if this were ever mounted as a step of some
      # still-larger app (id != NULL), that outer app owns the browser tab
      # and is responsible for its own beforeunload warning, the same
      # convention each individual editor's own _ui() already follows.
      shiny::tags$head(shiny::tags$script(shiny::HTML(
        'var appDirty = false;
         window.addEventListener("beforeunload", function (e) {
           if (!appDirty) return;
           e.preventDefault();
           e.returnValue =
             "Closing without clicking Finish & Return to R will lose any unsaved edits.";
           return e.returnValue;
         });
         Shiny.addCustomMessageHandler("setDirty", function(msg) {
           appDirty = msg.dirty;
         });
         Shiny.addCustomMessageHandler("closeWindow", function(msg) {
           appDirty = false;
           window.close();
         });'
      )))
    },
    shiny::uiOutput(ns("main_view"), fill = TRUE)
  )
}

# Builds the icon-screen launcher UI shown between steps. Not exported. Just
# a plain fragment (not its own bslib "page" object) since it is always
# mounted inside editASRworkflow_ui()'s page_fillable() shell, which already
# owns the document title and page-level role.
#
# @param ns   Namespacing function from the owning module (shiny::NS(id)).
# @param state List with bulk_done/drift_done/flag_done logical flags (see
#   editASRworkflow()); only those three elements are used here.
editASRworkflow_menu_ui <- function(ns, state) {
  shiny::div(
    style = "padding: 24px;",
    shiny::div(
      style = "text-align: center; margin-top: 24px;",
      shiny::a(
        href = "https://massbays-tech.github.io/AquaSensR",
        target = "_blank",
        shiny::img(
          src = "aquasensr-www/logo.png",
          height = "120px",
          alt = "AquaSensR logo"
        )
      ),
      shiny::div(
        style = "max-width: 700px; margin: 16px auto 0; color: #555;",
        shiny::p(
          "AquaSensR helps you quality-control continuous water quality monitoring data.
          Remove bad points in bulk, correct instrument drift, and review automated QC flags
          before exporting a cleaned dataset.",
          style = "margin-bottom: 12px;"
        ),
        shiny::p(
          "View the package documentation at ",
          shiny::a(
            "massbays-tech.github.io/AquaSensR",
            href = "https://massbays-tech.github.io/AquaSensR",
            target = "_blank"
          ),
          ", including the ",
          shiny::a(
            "Quality control overview",
            href = "https://massbays-tech.github.io/AquaSensR/articles/qcoverview.html",
            target = "_blank"
          ),
          " and ",
          shiny::a(
            "Drift correction",
            href = "https://massbays-tech.github.io/AquaSensR/articles/driftcorrection.html",
            target = "_blank"
          ),
          " vignettes for details on each editor's methods.",
          style = "margin-bottom: 12px;"
        ),
        shiny::p(
          "Click an icon below to start a step. You can run the steps in any order, any number of times.",
          style = "margin-bottom: 0;"
        )
      )
    ),
    shiny::div(
      style = "display: flex; justify-content: center; gap: 32px; margin-top: 48px;",
      step_tile(ns("bulk_icon"), "Bulk Removal", "scissors", state$bulk_done),
      step_tile(
        ns("drift_icon"),
        "Drift Correction",
        "chart-line",
        state$drift_done
      ),
      step_tile(ns("flag_icon"), "Flag Review", "flag", state$flag_done)
    ),
    shiny::div(
      style = "text-align: center; margin-top: 48px;",
      shiny::actionButton(
        ns("finish"),
        "Finish & Return to R",
        style = "background-color: #037B71; border-color: #037B71; color: #fff;"
      )
    ),
    shiny::tags$footer(
      style = "text-align: center; margin-top: 64px; padding-top: 16px; border-top: 1px solid #eee; color: #999; font-size: 0.85em;",
      paste0("AquaSensR ", utils::packageVersion("AquaSensR")),
      " \u00b7 ",
      shiny::a(
        "GitHub",
        href = "https://github.com/massbays-tech/AquaSensR",
        target = "_blank"
      ),
      " \u00b7 ",
      shiny::a(
        "Report an issue",
        href = "https://github.com/massbays-tech/AquaSensR/issues",
        target = "_blank"
      ),
      " \u00b7 License: CC0"
    )
  )
}

# Builds the combined workflow's server logic. Not exported.
#
# @param id        Shiny module id (see editASRworkflow_ui()).
# @param cont      contdat data frame (see editASRworkflow).
# @param dqo       dqodat data frame (see editASRworkflow).
# @param ext       Optional external data frame (see editASRworkflow).
# @param on_finish Optional callback invoked with the combined result list
#   when the user clicks Finish & Return to R. When NULL (standalone use),
#   Finish instead calls shiny::stopApp() directly.
editASRworkflow_server <- function(
  id,
  cont,
  dqo,
  ext = NULL,
  on_finish = NULL
) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    state <- shiny::reactiveVal(list(
      contdat = cont,
      dqodat = dqo,
      bulk_removed = NULL,
      corrections = NULL,
      removed = NULL,
      bulk_done = FALSE,
      drift_done = FALSE,
      flag_done = FALSE
    ))
    active_step <- shiny::reactiveVal("menu")

    # Fresh module id per visit: re-invoking moduleServer() with the same id
    # does not tear down the previous mount's observers, so a fixed id would
    # let a stale prior mount's plotly::event_data() source and namespaced
    # inputs linger indefinitely. A fresh id per visit makes a stale mount's
    # inputs/events permanently unreachable once its DOM is replaced.
    bulk_visit <- shiny::reactiveVal(0L)
    drift_visit <- shiny::reactiveVal(0L)
    flag_visit <- shiny::reactiveVal(0L)

    if (is.null(id)) {
      # TRUE whenever leaving the page right now would lose something: either
      # a step is currently open (its own in-progress edits, if any, aren't
      # tracked up here -- see editASRworkflow()'s docs on the
      # ungraceful-close safety net -- so being on a step at all is treated
      # as unsaved), or at least one step has already completed its own
      # Done/Close but the combined result hasn't been returned via Finish
      # yet. Mirrors each individual editor's own has_unsaved_edits/setDirty
      # pattern, just scoped to the whole workflow instead of one step.
      has_unsaved <- shiny::reactive({
        active_step() != "menu" ||
          isTRUE(state()$bulk_done) ||
          isTRUE(state()$drift_done) ||
          isTRUE(state()$flag_done)
      })

      shiny::observe({
        session$sendCustomMessage("setDirty", list(dirty = has_unsaved()))
      })
    }

    output$main_view <- shiny::renderUI({
      switch(
        active_step(),
        menu = editASRworkflow_menu_ui(ns, state()),
        bulk = editASRbulk_ui(
          ns(sprintf("bulk_%d", bulk_visit())),
          state()$contdat
        ),
        drift = editASRdrift_ui(
          ns(sprintf("drift_%d", drift_visit())),
          state()$contdat,
          ext = ext
        ),
        flag = editASRflag_ui(
          ns(sprintf("flag_%d", flag_visit())),
          state()$contdat,
          ext = ext
        )
      )
    })

    shiny::observeEvent(input$bulk_icon, {
      bulk_visit(bulk_visit() + 1L)
      mod_id <- sprintf("bulk_%d", bulk_visit())
      editASRbulk_server(
        mod_id,
        state()$contdat,
        removed = state()$bulk_removed,
        on_done = function(res) {
          s <- state()
          s$contdat <- res$contdat
          s$bulk_removed <- res$removed
          s$bulk_done <- TRUE
          state(s)
          active_step("menu")
        }
      )
      active_step("bulk")
    })

    shiny::observeEvent(input$drift_icon, {
      drift_visit(drift_visit() + 1L)
      mod_id <- sprintf("drift_%d", drift_visit())
      editASRdrift_server(
        mod_id,
        state()$contdat,
        ext = ext,
        on_done = function(res) {
          s <- state()
          s$contdat <- res$contdat
          s$corrections <- res$corrections
          s$drift_done <- TRUE
          state(s)
          active_step("menu")
        }
      )
      active_step("drift")
    })

    shiny::observeEvent(input$flag_icon, {
      flag_visit(flag_visit() + 1L)
      mod_id <- sprintf("flag_%d", flag_visit())
      editASRflag_server(
        mod_id,
        state()$contdat,
        state()$dqodat,
        removed = state()$removed,
        ext = ext,
        on_done = function(res) {
          s <- state()
          s$contdat <- res$contdat
          s$dqodat <- res$dqodat
          s$removed <- res$removed
          s$flag_done <- TRUE
          state(s)
          active_step("menu")
        }
      )
      active_step("flag")
    })

    finish_result <- function() {
      s <- state()
      list(
        contdat = s$contdat,
        dqodat = s$dqodat,
        bulk_removed = s$bulk_removed,
        corrections = s$corrections,
        removed = s$removed
      )
    }

    shiny::observeEvent(input$finish, {
      if (is.null(id)) {
        # Clear the dirty flag first so the deliberate act of finishing does
        # not immediately re-trigger the beforeunload warning it just guarded
        # against.
        session$sendCustomMessage("setDirty", list(dirty = FALSE))
      }
      if (is.null(on_finish)) {
        shiny::stopApp(returnValue = finish_result())
      } else {
        on_finish(finish_result())
      }
    })

    # Top-level ungraceful-close safety net, covering only steps whose own
    # Done has already fired -- an in-progress-but-unfinished step's edits
    # are lost on ungraceful disconnect, same as any single-page form losing
    # an unsaved edit on tab close.
    session$onSessionEnded(function() {
      if (inherits(session, "MockShinySession")) {
        return(invisible(NULL))
      }
      shiny::isolate({
        if (is.null(on_finish)) {
          shiny::stopApp(returnValue = finish_result())
        } else {
          on_finish(finish_result())
        }
      })
    })
  })
}

# Builds one clickable step tile for editASRworkflow_menu_ui(): a large icon,
# the step label, and a "Done" line shown only once that step has been run
# at least once in the current session. Not exported.
step_tile <- function(id, label, icon_name, done) {
  shiny::actionButton(
    id,
    label = shiny::tagList(
      shiny::div(shiny::icon(icon_name), style = "font-size: 40px;"),
      shiny::div(
        label,
        style = "font-size: 16px; font-weight: 600; margin-top: 8px;"
      ),
      if (isTRUE(done)) {
        shiny::div(
          "\u2713 Done",
          style = "font-size: 12px; color: #2a7d2e; margin-top: 4px;"
        )
      } else {
        shiny::div(" ", style = "font-size: 12px; margin-top: 4px;")
      }
    ),
    style = paste0(
      "width: 160px; height: 160px; display: flex; flex-direction: column; ",
      "align-items: center; justify-content: center; ",
      "background-color: #fff; border: 4px solid #037B71; border-radius: 12px; ",
      "color: #0E3455;"
    )
  )
}
