# Tests for editASRworkflow(), the combined bulk/drift/flag SPA built on
# editASRbulk_ui()/_server(), editASRdrift_ui()/_server(), and
# editASRflag_ui()/_server() (see test-editASRbulk.R / test-editASRdrift.R /
# test-editASRflag.R for that module conversion's own coverage).
#
# editASRworkflow_server() owns two things not covered elsewhere:
#   1. Mounting the right child module (fresh id per visit) and switching
#      `active_step` when an icon is clicked.
#   2. Unpacking each child's on_done() result into `state()` and assembling
#      the combined Finish result.
#
# Both are tested here by mocking the three child _server() functions to
# capture how editASRworkflow_server() calls them, rather than driving a real
# nested module through testServer() (which only instruments the module
# passed to testServer() directly, not further-nested children -- see the
# testServer() note in test-editASRflag.R). This isolates editASRworkflow's
# own orchestration logic from the children's already-covered internals.
#
# stopApp() segfaults inside testServer() (see other test files in this
# suite) -- Finish is tested either via a mocked stopApp() (standalone) or
# via a captured on_finish() callback (embedded), never a real stopApp().

mock_child_server <- function(captured_env) {
  function(id, cont, ..., removed = NULL, on_done = NULL) {
    captured_env$id <- id
    captured_env$cont <- cont
    captured_env$removed <- removed
    captured_env$on_done <- on_done
  }
}

# ---------------------------------------------------------------------------
# App / UI construction
# ---------------------------------------------------------------------------

test_that("editASRworkflow_app() returns a shiny app object", {
  app <- AquaSensR:::editASRworkflow_app(tst$contdat, tst$dqodat)
  expect_s3_class(app, "shiny.appobj")
})

test_that("editASRworkflow_ui() produces a uiOutput shell", {
  ui <- AquaSensR:::editASRworkflow_ui(NULL)
  ui_html <- as.character(ui)
  expect_true(grepl("main_view", ui_html, fixed = TRUE))
})

test_that("step_tile() shows a Done marker only when done = TRUE", {
  done_tile <- AquaSensR:::step_tile("bulk_icon", "Bulk Removal", "scissors", TRUE)
  not_done_tile <- AquaSensR:::step_tile("bulk_icon", "Bulk Removal", "scissors", FALSE)

  done_html <- as.character(done_tile)
  not_done_html <- as.character(not_done_tile)

  expect_true(grepl("Done", done_html, fixed = TRUE))
  expect_false(grepl("Done", not_done_html, fixed = TRUE))
})

test_that("editASRworkflow_menu_ui() reflects done state on each tile", {
  state <- list(
    contdat = tst$contdat,
    dqodat = tst$dqodat,
    bulk_done = TRUE,
    drift_done = FALSE,
    flag_done = TRUE
  )
  ui <- AquaSensR:::editASRworkflow_menu_ui(shiny::NS(NULL), state)
  ui_html <- as.character(ui)

  # Two of the three tiles are done; a precise per-tile check would require
  # parsing tile boundaries, so just confirm the marker's overall count.
  n_done <- lengths(regmatches(ui_html, gregexpr("Done", ui_html)))
  expect_equal(n_done, 2L)
})

# ---------------------------------------------------------------------------
# Icon clicks: mount the right child module and switch active_step
# ---------------------------------------------------------------------------

test_that("clicking Bulk Removal mounts a bulk module with the current contdat and switches to it", {
  captured <- new.env()
  local_mocked_bindings(
    editASRbulk_server = mock_child_server(captured),
    .package = "AquaSensR"
  )
  suppressWarnings(
    shiny::testServer(
      AquaSensR:::editASRworkflow_server,
      args = list(id = NULL, cont = tst$contdat, dqo = tst$dqodat),
      {
        session$setInputs(bulk_icon = 1L)
        expect_equal(active_step(), "bulk")
        expect_equal(captured$id, "bulk_1")
        expect_equal(captured$cont, tst$contdat)
        expect_null(captured$removed)
        expect_true(is.function(captured$on_done))
      }
    )
  )
})

test_that("clicking Drift Correction mounts a drift module with the current contdat and switches to it", {
  captured <- new.env()
  local_mocked_bindings(
    editASRdrift_server = mock_child_server(captured),
    .package = "AquaSensR"
  )
  suppressWarnings(
    shiny::testServer(
      AquaSensR:::editASRworkflow_server,
      args = list(id = NULL, cont = tst$contdat, dqo = tst$dqodat),
      {
        session$setInputs(drift_icon = 1L)
        expect_equal(active_step(), "drift")
        expect_equal(captured$id, "drift_1")
        expect_equal(captured$cont, tst$contdat)
        expect_true(is.function(captured$on_done))
      }
    )
  )
})

test_that("clicking Flag Review mounts a flag module with the current contdat/dqodat and switches to it", {
  captured <- new.env()
  local_mocked_bindings(
    editASRflag_server = mock_child_server(captured),
    .package = "AquaSensR"
  )
  suppressWarnings(
    shiny::testServer(
      AquaSensR:::editASRworkflow_server,
      args = list(id = NULL, cont = tst$contdat, dqo = tst$dqodat),
      {
        session$setInputs(flag_icon = 1L)
        expect_equal(active_step(), "flag")
        expect_equal(captured$id, "flag_1")
        expect_equal(captured$cont, tst$contdat)
        expect_null(captured$removed)
        expect_true(is.function(captured$on_done))
      }
    )
  )
})

test_that("revisiting a step mounts a fresh module id each time", {
  captured <- new.env()
  captured$ids <- character(0)
  local_mocked_bindings(
    editASRbulk_server = function(id, cont, ..., removed = NULL, on_done = NULL) {
      captured$ids <- c(captured$ids, id)
    },
    .package = "AquaSensR"
  )
  suppressWarnings(
    shiny::testServer(
      AquaSensR:::editASRworkflow_server,
      args = list(id = NULL, cont = tst$contdat, dqo = tst$dqodat),
      {
        session$setInputs(bulk_icon = 1L)
        session$setInputs(bulk_icon = 2L)
        session$setInputs(bulk_icon = 3L)
      }
    )
  )
  expect_equal(captured$ids, c("bulk_1", "bulk_2", "bulk_3"))
})

# ---------------------------------------------------------------------------
# on_done chaining: a child module's result flows into state() and back to
# the menu
# ---------------------------------------------------------------------------

test_that("bulk on_done updates contdat/bulk_removed/bulk_done and returns to the menu", {
  captured <- new.env()
  local_mocked_bindings(
    editASRbulk_server = mock_child_server(captured),
    .package = "AquaSensR"
  )
  removed_df <- data.frame(DateTime = tst$contdat$DateTime[1L])
  suppressWarnings(
    shiny::testServer(
      AquaSensR:::editASRworkflow_server,
      args = list(id = NULL, cont = tst$contdat, dqo = tst$dqodat),
      {
        session$setInputs(bulk_icon = 1L)
        modified_cont <- tst$contdat
        modified_cont[1L, 2L] <- NA
        captured$on_done(list(contdat = modified_cont, removed = removed_df))

        expect_equal(active_step(), "menu")
        expect_true(state()$bulk_done)
        expect_equal(state()$contdat, modified_cont)
        expect_equal(state()$bulk_removed, removed_df)
      }
    )
  )
})

test_that("drift on_done updates contdat/corrections/drift_done and returns to the menu", {
  captured <- new.env()
  local_mocked_bindings(
    editASRdrift_server = mock_child_server(captured),
    .package = "AquaSensR"
  )
  corrections_df <- data.frame(DateTime = tst$contdat$DateTime[1L], offset = 1)
  suppressWarnings(
    shiny::testServer(
      AquaSensR:::editASRworkflow_server,
      args = list(id = NULL, cont = tst$contdat, dqo = tst$dqodat),
      {
        session$setInputs(drift_icon = 1L)
        modified_cont <- tst$contdat
        modified_cont[1L, 2L] <- 999
        captured$on_done(list(contdat = modified_cont, corrections = corrections_df))

        expect_equal(active_step(), "menu")
        expect_true(state()$drift_done)
        expect_equal(state()$contdat, modified_cont)
        expect_equal(state()$corrections, corrections_df)
      }
    )
  )
})

test_that("flag on_done updates contdat/dqodat/removed/flag_done and returns to the menu", {
  captured <- new.env()
  local_mocked_bindings(
    editASRflag_server = mock_child_server(captured),
    .package = "AquaSensR"
  )
  removed_df <- data.frame(DateTime = tst$contdat$DateTime[1L])
  modified_dqo <- tst$dqodat
  modified_dqo[1L, "GrMax"] <- 9999
  suppressWarnings(
    shiny::testServer(
      AquaSensR:::editASRworkflow_server,
      args = list(id = NULL, cont = tst$contdat, dqo = tst$dqodat),
      {
        session$setInputs(flag_icon = 1L)
        modified_cont <- tst$contdat
        modified_cont[1L, 2L] <- NA
        captured$on_done(list(
          contdat = modified_cont,
          dqodat = modified_dqo,
          removed = removed_df
        ))

        expect_equal(active_step(), "menu")
        expect_true(state()$flag_done)
        expect_equal(state()$contdat, modified_cont)
        expect_equal(state()$dqodat, modified_dqo)
        expect_equal(state()$removed, removed_df)
      }
    )
  )
})

test_that("revisiting bulk after flag has completed starts from the latest contdat, not the original", {
  bulk_captured <- new.env()
  flag_captured <- new.env()
  local_mocked_bindings(
    editASRbulk_server = mock_child_server(bulk_captured),
    editASRflag_server = mock_child_server(flag_captured),
    .package = "AquaSensR"
  )
  suppressWarnings(
    shiny::testServer(
      AquaSensR:::editASRworkflow_server,
      args = list(id = NULL, cont = tst$contdat, dqo = tst$dqodat),
      {
        # Complete the flag step first, changing contdat.
        session$setInputs(flag_icon = 1L)
        flag_modified_cont <- tst$contdat
        flag_modified_cont[1L, 2L] <- NA
        flag_captured$on_done(list(
          contdat = flag_modified_cont,
          dqodat = tst$dqodat,
          removed = data.frame(DateTime = tst$contdat$DateTime[1L])
        ))
        expect_equal(state()$contdat, flag_modified_cont)

        # Revisiting bulk starts from whatever contdat is current (the
        # flag-modified data), not the original -- editASRworkflow() always
        # threads the latest contdat forward into the next step opened,
        # regardless of which step that is.
        session$setInputs(bulk_icon = 1L)
        expect_equal(bulk_captured$cont, flag_modified_cont)
      }
    )
  )
})

# ---------------------------------------------------------------------------
# Finish: assembles the combined result
# ---------------------------------------------------------------------------

test_that("Finish assembles the combined result and calls stopApp when standalone", {
  bulk_captured <- new.env()
  local_mocked_bindings(
    editASRbulk_server = mock_child_server(bulk_captured),
    .package = "AquaSensR"
  )
  stop_captured <- NULL
  local_mocked_bindings(
    stopApp = function(returnValue = NULL, ...) stop_captured <<- returnValue,
    .package = "shiny"
  )
  removed_df <- data.frame(DateTime = tst$contdat$DateTime[1L])
  modified_cont <- tst$contdat
  modified_cont[1L, 2L] <- NA
  suppressWarnings(
    shiny::testServer(
      AquaSensR:::editASRworkflow_server,
      args = list(id = NULL, cont = tst$contdat, dqo = tst$dqodat),
      {
        session$setInputs(bulk_icon = 1L)
        bulk_captured$on_done(list(contdat = modified_cont, removed = removed_df))

        session$setInputs(finish = 1L)
      }
    )
  )
  expect_named(
    stop_captured,
    c("contdat", "dqodat", "bulk_removed", "corrections", "removed")
  )
  expect_equal(stop_captured$contdat, modified_cont)
  expect_equal(stop_captured$dqodat, tst$dqodat)
  expect_equal(stop_captured$bulk_removed, removed_df)
  expect_null(stop_captured$corrections)
  expect_null(stop_captured$removed)
})

test_that("on_finish is called instead of stopApp when supplied", {
  captured <- NULL
  suppressWarnings(
    shiny::testServer(
      AquaSensR:::editASRworkflow_server,
      args = list(
        id = "wf_1",
        cont = tst$contdat,
        dqo = tst$dqodat,
        on_finish = function(res) captured <<- res
      ),
      {
        session$setInputs(finish = 1L)
      }
    )
  )
  expect_false(is.null(captured))
  expect_named(
    captured,
    c("contdat", "dqodat", "bulk_removed", "corrections", "removed")
  )
})

# ---------------------------------------------------------------------------
# onSessionEnded — ungraceful close safety net (covers completed steps only)
# ---------------------------------------------------------------------------

test_that("session$close() saves completed-step state instead of erroring", {
  bulk_captured <- new.env()
  local_mocked_bindings(
    editASRbulk_server = mock_child_server(bulk_captured),
    .package = "AquaSensR"
  )
  stop_captured <- NULL
  local_mocked_bindings(
    stopApp = function(returnValue = NULL, ...) stop_captured <<- returnValue,
    .package = "shiny"
  )
  removed_df <- data.frame(DateTime = tst$contdat$DateTime[1L])
  modified_cont <- tst$contdat
  modified_cont[1L, 2L] <- NA
  suppressWarnings(
    shiny::testServer(
      AquaSensR:::editASRworkflow_server,
      args = list(id = NULL, cont = tst$contdat, dqo = tst$dqodat),
      {
        session$setInputs(bulk_icon = 1L)
        bulk_captured$on_done(list(contdat = modified_cont, removed = removed_df))

        expect_no_error(session$close())
      }
    )
  )
  expect_equal(stop_captured$contdat, modified_cont)
  expect_equal(stop_captured$bulk_removed, removed_df)
})

# ---------------------------------------------------------------------------
# has_unsaved -- drives the top-level beforeunload warning (standalone only,
# mirroring each individual editor's own has_unsaved_edits/setDirty pattern,
# just scoped to the whole session instead of one step)
# ---------------------------------------------------------------------------

test_that("has_unsaved is FALSE at the menu before anything has been done", {
  suppressWarnings(
    shiny::testServer(
      AquaSensR:::editASRworkflow_server,
      args = list(id = NULL, cont = tst$contdat, dqo = tst$dqodat),
      {
        expect_false(has_unsaved())
      }
    )
  )
})

test_that("has_unsaved is TRUE while an editor is open, even before it reports any edit", {
  captured <- new.env()
  local_mocked_bindings(
    editASRbulk_server = mock_child_server(captured),
    .package = "AquaSensR"
  )
  suppressWarnings(
    shiny::testServer(
      AquaSensR:::editASRworkflow_server,
      args = list(id = NULL, cont = tst$contdat, dqo = tst$dqodat),
      {
        session$setInputs(bulk_icon = 1L)
        expect_true(has_unsaved())
      }
    )
  )
})

test_that("has_unsaved stays TRUE back at the menu once a step has completed", {
  captured <- new.env()
  local_mocked_bindings(
    editASRdrift_server = mock_child_server(captured),
    .package = "AquaSensR"
  )
  suppressWarnings(
    shiny::testServer(
      AquaSensR:::editASRworkflow_server,
      args = list(id = NULL, cont = tst$contdat, dqo = tst$dqodat),
      {
        session$setInputs(drift_icon = 1L)
        captured$on_done(list(
          contdat = tst$contdat,
          corrections = data.frame(DateTime = tst$contdat$DateTime[1L])
        ))
        expect_equal(active_step(), "menu")
        expect_true(has_unsaved())
      }
    )
  )
})

test_that("has_unsaved is not exposed in embedded mode (id != NULL)", {
  # Mirrors editASRbulk/drift/flag's own convention: the per-instance
  # has_unsaved/setDirty wiring is skipped entirely when this module is
  # embedded, since the embedding caller owns the browser tab and its own
  # safety net.
  suppressWarnings(
    shiny::testServer(
      AquaSensR:::editASRworkflow_server,
      args = list(id = "wf_1", cont = tst$contdat, dqo = tst$dqodat, on_finish = function(res) NULL),
      {
        expect_false(exists("has_unsaved", inherits = FALSE))
      }
    )
  )
})
