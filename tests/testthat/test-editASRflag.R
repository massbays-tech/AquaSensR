# Tests for editASRflag split across two approaches:
#
# 1. shiny::testServer() via editASRflag_app() — tests reactive server logic
#    (removals, undo, reset, navigation) without a browser.
#
# 2. Direct calls to editASRflag_result() — tests the "done" output logic
#    as pure R (no stopApp, no Shiny reactive domain needed).
#
# Key testServer quirks this file accounts for:
#
#  a. input$param_select starts NULL — set it manually before every output read.
#
#  b. plotly::event_data() reads session$input[[eventID]] and then calls
#     jsonlite::parse_json() on the value, so injected values MUST be JSON
#     strings, not R objects:
#       session$setInputs(`plotly_click-A`    = '{"customdata":1}')
#       session$setInputs(`plotly_selected-A` = '[{"customdata":1},{"customdata":2}]')
#
#  c. updateSelectInput() does not round-trip in testServer (no browser), so
#     param_next / param_prev cannot be tested by reading input$param_select.
#     Navigation is tested by manually switching param_select instead.
#
#  d. stopApp() segfaults inside testServer — never trigger input$done in a
#     testServer block; use editASRflag_result() tests instead.
#
#  e. Plotly observers emit warnings about unregistered events (no rendered
#     plot). Wrap testServer calls in suppressWarnings().

# First two parameters for fixture setup
edit_first_param  <- setdiff(names(tst$contdat), "DateTime")[1L]
edit_second_param <- setdiff(names(tst$contdat), "DateTime")[2L]

# Build the flagdat_list the same way editASRflag_app() does internally.
edit_flagdat_list <- local({
  fl <- AquaSensR:::utilASRflagall(tst$contdat, tst$dqodat)
  lapply(fl, function(fd) { fd$.rowid <- seq_len(nrow(fd)); fd })
})

# ---------------------------------------------------------------------------
# App construction
# ---------------------------------------------------------------------------

test_that("editASRflag_app returns a shiny.appobj", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  expect_s3_class(app, "shiny.appobj")
})

# ---------------------------------------------------------------------------
# Initial state
# ---------------------------------------------------------------------------

test_that("removed_count output starts at zero", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

# ---------------------------------------------------------------------------
# Single-point click removal
# ---------------------------------------------------------------------------

test_that("plotly_click removes the targeted point and updates removed_count", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      session$setInputs(`plotly_click-A` = '{"customdata":1}')
      expect_equal(output$removed_count, "Removed Points: 1")
    })
  )
})

# ---------------------------------------------------------------------------
# Box / lasso selection removal
# ---------------------------------------------------------------------------

test_that("plotly_selected removes multiple points at once", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      session$setInputs(
        `plotly_selected-A` = '[{"customdata":1},{"customdata":2},{"customdata":3}]'
      )
      expect_equal(output$removed_count, "Removed Points: 3")
    })
  )
})

# ---------------------------------------------------------------------------
# Undo
# ---------------------------------------------------------------------------

test_that("undo after one click restores the removed point", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      session$setInputs(`plotly_click-A` = '{"customdata":1}')
      expect_equal(output$removed_count, "Removed Points: 1")

      session$setInputs(undo = 1L)
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

test_that("undo when nothing removed does not error", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      expect_no_error(session$setInputs(undo = 1L))
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

test_that("undo is per-batch: two clicks require two undos to fully restore", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      session$setInputs(`plotly_click-A` = '{"customdata":1}')
      session$setInputs(`plotly_click-A` = '{"customdata":2}')
      expect_equal(output$removed_count, "Removed Points: 2")

      session$setInputs(undo = 1L)
      expect_equal(output$removed_count, "Removed Points: 1")

      session$setInputs(undo = 1L)
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

# ---------------------------------------------------------------------------
# Reset
# ---------------------------------------------------------------------------

test_that("reset restores all removed points for the current parameter", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      session$setInputs(`plotly_click-A` = '{"customdata":1}')
      session$setInputs(`plotly_click-A` = '{"customdata":2}')
      expect_equal(output$removed_count, "Removed Points: 2")

      session$setInputs(reset = 1L)
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

# ---------------------------------------------------------------------------
# Parameter navigation — use manual param_select switch (updateSelectInput
# does not round-trip in testServer, so param_next/prev cannot be verified
# by reading input$param_select)
# ---------------------------------------------------------------------------

test_that("param_prev at the first parameter does not change selection", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      session$setInputs(param_prev = 1L)
      expect_equal(input$param_select, edit_first_param)
    })
  )
})

test_that("removals are tracked independently per parameter", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      # Remove a point on the first parameter
      session$setInputs(param_select = edit_first_param)
      session$setInputs(`plotly_click-A` = '{"customdata":1}')
      expect_equal(output$removed_count, "Removed Points: 1")

      # Switch to the second parameter — its count is independent
      session$setInputs(param_select = edit_second_param)
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

# ---------------------------------------------------------------------------
# editASRflag_result() — "done" output logic tested as pure R (no stopApp)
# ---------------------------------------------------------------------------

test_that("editASRflag_result with no removals returns sorted contdat and empty removed", {
  result <- AquaSensR:::editASRflag_result(
    tst$contdat,
    edit_flagdat_list,
    edit_flagdat_list  # remaining == full → nothing removed
  )

  expect_named(result, c("contdat", "removed"))

  expected_cont <- tst$contdat[order(tst$contdat$DateTime), ]
  expect_equal(result$contdat, expected_cont, ignore_attr = TRUE)

  expect_s3_class(result$removed, "data.frame")
  expect_equal(nrow(result$removed), 0L)
  expect_named(
    result$removed,
    c("Parameter", "DateTime", "gross_flag", "spike_flag", "roc_flag", "flat_flag")
  )
})

test_that("editASRflag_result with one removal sets NA and records removed row", {
  # Remove the first DateTime-sorted row from the first parameter
  remaining_list <- edit_flagdat_list
  remaining_list[[edit_first_param]] <- edit_flagdat_list[[edit_first_param]][-1L, ]

  result <- AquaSensR:::editASRflag_result(tst$contdat, edit_flagdat_list, remaining_list)

  expect_named(result, c("contdat", "removed"))
  expect_equal(nrow(result$removed), 1L)
  expect_equal(result$removed$Parameter[1L], edit_first_param)
  expect_true(is.na(result$contdat[1L, edit_first_param]))
  # All other parameter columns for that row should be intact
  other_params <- setdiff(names(edit_flagdat_list), edit_first_param)
  for (p in other_params) {
    expect_false(is.na(result$contdat[1L, p]))
  }
})

test_that("editASRflag_result with removals across multiple parameters records all", {
  remaining_list <- edit_flagdat_list
  remaining_list[[edit_first_param]]  <- edit_flagdat_list[[edit_first_param]][-1L, ]
  remaining_list[[edit_second_param]] <- edit_flagdat_list[[edit_second_param]][-2L, ]

  result <- AquaSensR:::editASRflag_result(tst$contdat, edit_flagdat_list, remaining_list)

  expect_equal(nrow(result$removed), 2L)
  expect_true(is.na(result$contdat[1L, edit_first_param]))
  expect_true(is.na(result$contdat[2L, edit_second_param]))
})
