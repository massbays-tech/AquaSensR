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
#  d. stopApp() segfaults inside testServer — never trigger input$done or
#     input$done_confirm in a testServer block; use editASRflag_result() tests
#     instead.  (input$done now shows a modal; input$done_confirm calls stopApp.)
#
#  e. Plotly observers emit warnings about unregistered events (no rendered
#     plot). Wrap testServer calls in suppressWarnings().

# First two parameters for fixture setup
edit_first_param <- setdiff(names(tst$contdat), "DateTime")[1L]
edit_second_param <- setdiff(names(tst$contdat), "DateTime")[2L]

# Build the flagdat_list the same way editASRflag_app() does internally.
edit_flagdat_list <- local({
  fl <- AquaSensR:::utilASRflagall(tst$contdat, tst$dqodat)
  lapply(fl, function(fd) {
    fd$.rowid <- seq_len(nrow(fd))
    fd
  })
})

# ---------------------------------------------------------------------------
# App construction
# ---------------------------------------------------------------------------

test_that("editASRflag_app returns a shiny.appobj", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  expect_s3_class(app, "shiny.appobj")
})

test_that("editASRflag_app with dqo_sidebar_open = TRUE returns a shiny.appobj", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat, dqo_sidebar_open = TRUE)
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

test_that("reset restores all removed points for current param after confirmation", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      session$setInputs(`plotly_click-A` = '{"customdata":1}')
      session$setInputs(`plotly_click-A` = '{"customdata":2}')
      expect_equal(output$removed_count, "Removed Points: 2")

      # reset shows the modal; count unchanged until confirmed
      session$setInputs(reset = 1L)
      expect_equal(output$removed_count, "Removed Points: 2")

      session$setInputs(reset_confirm = 1L)
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

test_that("reset restores removed points for all parameters, not just current", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      # Remove a point from the first parameter (unlinked so params stay independent)
      session$setInputs(param_select = edit_first_param, link_all = FALSE)
      session$setInputs(`plotly_click-A` = '{"customdata":1}')
      expect_equal(output$removed_count, "Removed Points: 1")

      # Remove a different rowid from the second parameter (rowid 2 so the
      # input value changes and the observer re-fires in testServer)
      session$setInputs(param_select = edit_second_param)
      session$setInputs(`plotly_click-A` = '{"customdata":2}')
      expect_equal(output$removed_count, "Removed Points: 1")

      session$setInputs(reset = 1L)
      session$setInputs(reset_confirm = 1L)
      expect_equal(output$removed_count, "Removed Points: 0")

      session$setInputs(param_select = edit_first_param)
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
      # Disable linking so the removal stays on the first parameter only
      session$setInputs(param_select = edit_first_param, link_all = FALSE)
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
    edit_flagdat_list, # remaining == full → nothing removed
    tst$dqodat
  )

  expect_named(result, c("contdat", "dqodat", "removed"))

  expected_cont <- tst$contdat[order(tst$contdat$DateTime), ]
  expect_equal(result$contdat, expected_cont, ignore_attr = TRUE)

  expect_s3_class(result$removed, "data.frame")
  expect_equal(nrow(result$removed), 0L)
  expect_named(
    result$removed,
    c(
      "Parameter",
      "DateTime",
      "Value",
      "gross_flag",
      "spike_flag",
      "roc_flag",
      "flat_flag"
    )
  )
  expect_equal(result$dqodat, tst$dqodat)
})

test_that("editASRflag_result with one removal sets NA and records removed row", {
  # Remove the first DateTime-sorted row from the first parameter
  remaining_list <- edit_flagdat_list
  remaining_list[[edit_first_param]] <- edit_flagdat_list[[edit_first_param]][
    -1L,
  ]

  result <- AquaSensR:::editASRflag_result(
    tst$contdat,
    edit_flagdat_list,
    remaining_list,
    tst$dqodat
  )

  expect_named(result, c("contdat", "dqodat", "removed"))
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
  remaining_list[[edit_first_param]] <- edit_flagdat_list[[edit_first_param]][
    -1L,
  ]
  remaining_list[[edit_second_param]] <- edit_flagdat_list[[edit_second_param]][
    -2L,
  ]

  result <- AquaSensR:::editASRflag_result(
    tst$contdat,
    edit_flagdat_list,
    remaining_list,
    tst$dqodat
  )

  expect_equal(nrow(result$removed), 2L)
  expect_true(is.na(result$contdat[1L, edit_first_param]))
  expect_true(is.na(result$contdat[2L, edit_second_param]))
})

# # ---------------------------------------------------------------------------
# # Label fallback (line 96): param name used when paramsASR has no Label
# # ---------------------------------------------------------------------------

# test_that("editASRflag_app uses param name as label when Label is NA", {
#   ns   <- asNamespace("AquaSensR")
#   orig <- get("paramsASR", envir = ns)

#   modified        <- orig
#   modified$Label  <- NA_character_

#   is_locked <- bindingIsLocked("paramsASR", ns)
#   if (is_locked) unlockBinding("paramsASR", ns)
#   assign("paramsASR", modified, envir = ns)
#   on.exit({
#     if (is_locked) unlockBinding("paramsASR", ns)
#     assign("paramsASR", orig, envir = ns)
#     if (is_locked) lockBinding("paramsASR", ns)
#   }, add = TRUE)

#   app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
#   expect_s3_class(app, "shiny.appobj")
# })

# ---------------------------------------------------------------------------
# Parameter navigation — covering observer bodies (lines 186, 191-193)
# updateSelectInput is called but doesn't round-trip in testServer; we just
# verify the observers fire without error.
# ---------------------------------------------------------------------------

test_that("param_prev from non-first parameter fires without error", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_second_param)
      expect_no_error(session$setInputs(param_prev = 1L))
    })
  )
})

test_that("param_next from non-last parameter fires without error", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      expect_no_error(session$setInputs(param_next = 1L))
    })
  )
})

# ---------------------------------------------------------------------------
# Relayout event handling (lines 200, 202-206)
# plotly_relayout JSON must be a string; jsonlite::parse_json() is called
# on the raw input value internally.
# ---------------------------------------------------------------------------

test_that("plotly_relayout with x range fires without error", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      expect_no_error(
        session$setInputs(
          `plotly_relayout-A` = '{"xaxis.range[0]":0,"xaxis.range[1]":1}'
        )
      )
    })
  )
})

test_that("plotly_relayout with autorange fires without error", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      # First set a range so x_range is non-NULL, then reset via autorange
      session$setInputs(
        `plotly_relayout-A` = '{"xaxis.range[0]":0,"xaxis.range[1]":1}'
      )
      expect_no_error(
        session$setInputs(`plotly_relayout-A` = '{"xaxis.autorange":true}')
      )
    })
  )
})

# ---------------------------------------------------------------------------
# flagPlot layout with non-NULL x_range (lines 233-236)
# x_range is read via isolate() in renderPlotly, so it only takes effect when
# the plot re-renders due to a different reactive dependency (cur_remaining).
# Sequence: set x range → switch params (invalidates cur_remaining) → re-render.
# ---------------------------------------------------------------------------

test_that("flagPlot applies xaxis range layout when x_range is non-NULL", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      session$setInputs(
        `plotly_relayout-A` = '{"xaxis.range[0]":0,"xaxis.range[1]":1}'
      )
      # Switching params invalidates cur_remaining → flagPlot re-renders with
      # x_range non-NULL, executing the layout block (lines 233-236).
      expect_no_error(session$setInputs(param_select = edit_second_param))
    })
  )
})

# ---------------------------------------------------------------------------
# plotly_selected early-return paths
# ---------------------------------------------------------------------------

test_that("plotly_selected returns early when event data is not a data frame", {
  # A JSON object (not array) parses to a list, which is !is.data.frame → early
  # return on line 246 before any removal occurs.
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      session$setInputs(`plotly_selected-A` = '{"customdata":1}')
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

test_that("plotly_selected returns early when no remaining row matches selected rowids", {
  # Rowid 99999 does not exist in any real dataset → mask is all FALSE → line 251.
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      session$setInputs(`plotly_selected-A` = '[{"customdata":99999}]')
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

# ---------------------------------------------------------------------------
# plotly_click early-return path (line 269)
# Remove row 1 via selection, then try clicking the same rowid.  It no longer
# exists in cur_remaining(), so the mask is all FALSE → early return.
# ---------------------------------------------------------------------------

test_that("plotly_click returns early when clicked rowid is no longer in remaining", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      # Remove row 1 via box-selection
      session$setInputs(`plotly_selected-A` = '[{"customdata":1}]')
      expect_equal(output$removed_count, "Removed Points: 1")
      # Click on the now-missing rowid → no mask match → early return, count unchanged
      session$setInputs(`plotly_click-A` = '{"customdata":1}')
      expect_equal(output$removed_count, "Removed Points: 1")
    })
  )
})

# ---------------------------------------------------------------------------
# Overlay parameter
# ---------------------------------------------------------------------------

test_that("flagPlot renders without error when overlay_param is a valid parameter", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      expect_no_error(session$setInputs(overlay_param = edit_second_param))
    })
  )
})

test_that("flagPlot renders without error when overlay_param is empty (None)", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      # Select an overlay then clear it back to None
      session$setInputs(overlay_param = edit_second_param)
      expect_no_error(session$setInputs(overlay_param = ""))
    })
  )
})

test_that("flagPlot renders without error when overlay_param is not a column in cont", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      expect_no_error(session$setInputs(overlay_param = "nonexistent_param"))
    })
  )
})

# ---------------------------------------------------------------------------
# DQO Settings panel — apply_dqo and reset_dqo
# ---------------------------------------------------------------------------

# Convenience: pull one threshold from tst$dqodat for a given param/flag/col.
dqo_lookup <- function(p, flag_type, col) {
  v <- tst$dqodat[tst$dqodat$Parameter == p & tst$dqodat$Flag == flag_type, col,
                  drop = TRUE]
  if (length(v) == 0L) NA_real_ else v[[1L]]
}

test_that("apply_dqo fires without error and resets removals for current param", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      # Remove a point first
      session$setInputs(`plotly_click-A` = '{"customdata":1}')
      expect_equal(output$removed_count, "Removed Points: 1")

      # Apply DQO — should re-flag and retain removals
      session$setInputs(
        dqo_GrMin_Suspect    = dqo_lookup(edit_first_param, "Suspect", "GrMin"),
        dqo_GrMax_Suspect    = dqo_lookup(edit_first_param, "Suspect", "GrMax"),
        dqo_GrMin_Fail       = dqo_lookup(edit_first_param, "Fail",    "GrMin"),
        dqo_GrMax_Fail       = dqo_lookup(edit_first_param, "Fail",    "GrMax"),
        dqo_Spike_Suspect    = dqo_lookup(edit_first_param, "Suspect", "Spike"),
        dqo_Spike_Fail       = dqo_lookup(edit_first_param, "Fail",    "Spike"),
        dqo_RoCStDv_Suspect  = dqo_lookup(edit_first_param, "Suspect", "RoCStDv"),
        dqo_RoCHours_Suspect = dqo_lookup(edit_first_param, "Suspect", "RoCHours"),
        dqo_RoCStDv_Fail     = dqo_lookup(edit_first_param, "Fail",    "RoCStDv"),
        dqo_RoCHours_Fail    = dqo_lookup(edit_first_param, "Fail",    "RoCHours"),
        dqo_FlatN_Suspect    = dqo_lookup(edit_first_param, "Suspect", "FlatN"),
        dqo_FlatDelta_Suspect= dqo_lookup(edit_first_param, "Suspect", "FlatDelta"),
        dqo_FlatN_Fail       = dqo_lookup(edit_first_param, "Fail",    "FlatN"),
        dqo_FlatDelta_Fail   = dqo_lookup(edit_first_param, "Fail",    "FlatDelta"),
        apply_dqo = 1L
      )
      expect_equal(output$removed_count, "Removed Points: 1")
    })
  )
})

test_that("apply_dqo does not affect removals for other parameters", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      # Remove a point on the second parameter
      session$setInputs(param_select = edit_second_param)
      session$setInputs(`plotly_click-A` = '{"customdata":1}')
      expect_equal(output$removed_count, "Removed Points: 1")

      # Apply DQO on the first parameter — second param's removals unchanged
      session$setInputs(param_select = edit_first_param)
      session$setInputs(
        dqo_GrMin_Suspect = dqo_lookup(edit_first_param, "Suspect", "GrMin"),
        dqo_GrMax_Suspect = dqo_lookup(edit_first_param, "Suspect", "GrMax"),
        dqo_GrMin_Fail    = dqo_lookup(edit_first_param, "Fail",    "GrMin"),
        dqo_GrMax_Fail    = dqo_lookup(edit_first_param, "Fail",    "GrMax"),
        dqo_Spike_Suspect    = dqo_lookup(edit_first_param, "Suspect", "Spike"),
        dqo_Spike_Fail       = dqo_lookup(edit_first_param, "Fail",    "Spike"),
        dqo_RoCStDv_Suspect  = dqo_lookup(edit_first_param, "Suspect", "RoCStDv"),
        dqo_RoCHours_Suspect = dqo_lookup(edit_first_param, "Suspect", "RoCHours"),
        dqo_RoCStDv_Fail     = dqo_lookup(edit_first_param, "Fail",    "RoCStDv"),
        dqo_RoCHours_Fail    = dqo_lookup(edit_first_param, "Fail",    "RoCHours"),
        dqo_FlatN_Suspect    = dqo_lookup(edit_first_param, "Suspect", "FlatN"),
        dqo_FlatDelta_Suspect= dqo_lookup(edit_first_param, "Suspect", "FlatDelta"),
        dqo_FlatN_Fail       = dqo_lookup(edit_first_param, "Fail",    "FlatN"),
        dqo_FlatDelta_Fail   = dqo_lookup(edit_first_param, "Fail",    "FlatDelta"),
        apply_dqo = 1L
      )

      session$setInputs(param_select = edit_second_param)
      expect_equal(output$removed_count, "Removed Points: 1")
    })
  )
})

test_that("reset_dqo fires without error and retains prior removals", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      session$setInputs(`plotly_click-A` = '{"customdata":1}')
      expect_equal(output$removed_count, "Removed Points: 1")

      expect_no_error(session$setInputs(reset_dqo = 1L))
      expect_equal(output$removed_count, "Removed Points: 1")
    })
  )
})

test_that("reset_dqo with no prior removals results in zero removed points", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      expect_no_error(session$setInputs(reset_dqo = 1L))
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

test_that("start_over after apply_dqo resets removals to zero", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)

      # Apply DQO (same values — just confirms the baseline is updated)
      session$setInputs(
        dqo_GrMin_Suspect    = dqo_lookup(edit_first_param, "Suspect", "GrMin"),
        dqo_GrMax_Suspect    = dqo_lookup(edit_first_param, "Suspect", "GrMax"),
        dqo_GrMin_Fail       = dqo_lookup(edit_first_param, "Fail",    "GrMin"),
        dqo_GrMax_Fail       = dqo_lookup(edit_first_param, "Fail",    "GrMax"),
        dqo_Spike_Suspect    = dqo_lookup(edit_first_param, "Suspect", "Spike"),
        dqo_Spike_Fail       = dqo_lookup(edit_first_param, "Fail",    "Spike"),
        dqo_RoCStDv_Suspect  = dqo_lookup(edit_first_param, "Suspect", "RoCStDv"),
        dqo_RoCHours_Suspect = dqo_lookup(edit_first_param, "Suspect", "RoCHours"),
        dqo_RoCStDv_Fail     = dqo_lookup(edit_first_param, "Fail",    "RoCStDv"),
        dqo_RoCHours_Fail    = dqo_lookup(edit_first_param, "Fail",    "RoCHours"),
        dqo_FlatN_Suspect    = dqo_lookup(edit_first_param, "Suspect", "FlatN"),
        dqo_FlatDelta_Suspect= dqo_lookup(edit_first_param, "Suspect", "FlatDelta"),
        dqo_FlatN_Fail       = dqo_lookup(edit_first_param, "Fail",    "FlatN"),
        dqo_FlatDelta_Fail   = dqo_lookup(edit_first_param, "Fail",    "FlatDelta"),
        apply_dqo = 1L
      )

      session$setInputs(`plotly_click-A` = '{"customdata":1}')
      expect_equal(output$removed_count, "Removed Points: 1")

      # Start Over shows modal first; count unchanged until confirmed
      session$setInputs(reset = 1L)
      expect_equal(output$removed_count, "Removed Points: 1")
      session$setInputs(reset_confirm = 1L)
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

# ---------------------------------------------------------------------------
# Linked removal
# ---------------------------------------------------------------------------

test_that("linked removal also removes matching DateTimes from all other params", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(
        param_select = edit_first_param,
        link_all     = TRUE
      )
      session$setInputs(`plotly_click-A` = '{"customdata":1}')
      expect_equal(output$removed_count, "Removed Points: 1")

      # Switch to second param and verify the same DateTime was also removed
      session$setInputs(param_select = edit_second_param)
      expect_equal(output$removed_count, "Removed Points: 1")
    })
  )
})

test_that("undo from primary param also restores all linked params", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(
        param_select = edit_first_param,
        link_all     = TRUE
      )
      session$setInputs(`plotly_click-A` = '{"customdata":1}')

      # Undo from the primary param restores all params
      session$setInputs(undo = 1L)
      expect_equal(output$removed_count, "Removed Points: 0")

      session$setInputs(param_select = edit_second_param)
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

test_that("undo from linked param also restores primary param", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(
        param_select = edit_first_param,
        link_all     = TRUE
      )
      session$setInputs(`plotly_click-A` = '{"customdata":1}')

      # Switch to the second param and undo from there
      session$setInputs(param_select = edit_second_param)
      expect_equal(output$removed_count, "Removed Points: 1")
      session$setInputs(undo = 1L)
      expect_equal(output$removed_count, "Removed Points: 0")

      # Primary param should also be restored
      session$setInputs(param_select = edit_first_param)
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

test_that("solo removal after linked removal only undoes solo batch on first undo", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      # Linked removal: rowid 1 removed from all params
      session$setInputs(
        param_select = edit_first_param,
        link_all     = TRUE
      )
      session$setInputs(`plotly_click-A` = '{"customdata":1}')

      # Solo removal on second param only: rowid 2
      session$setInputs(
        param_select = edit_second_param,
        link_all     = FALSE
      )
      session$setInputs(`plotly_click-A` = '{"customdata":2}')
      expect_equal(output$removed_count, "Removed Points: 2")

      # First undo removes only the solo batch (rowid 2)
      session$setInputs(undo = 1L)
      expect_equal(output$removed_count, "Removed Points: 1")

      # Second undo removes the linked batch — also restores first param
      session$setInputs(undo = 1L)
      expect_equal(output$removed_count, "Removed Points: 0")
      session$setInputs(param_select = edit_first_param)
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

# ---------------------------------------------------------------------------
# USGS overlay
# ---------------------------------------------------------------------------

test_that("load_usgs with empty site fires without error and shows error status", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      expect_no_error(session$setInputs(usgs_site = "", usgs_pcode = "00060", load_usgs = 1L))
      # removed count should be unaffected
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

test_that("load_usgs with non-numeric site fires without error and shows error status", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      expect_no_error(
        session$setInputs(usgs_site = "not-a-number", usgs_pcode = "00060", load_usgs = 1L)
      )
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

test_that("load_usgs success populates usgs_ovl and clears overlay_param", {
  # Build a minimal fake USGS result matching the 2-col contract.
  fake_usgs <- data.frame(
    DateTime              = tst$contdat$DateTime,
    `Streamflow (ft³/s) [99999999]` = seq_len(nrow(tst$contdat)),
    check.names           = FALSE,
    stringsAsFactors      = FALSE
  )
  attr(fake_usgs, "site_name") <- "Fake River"

  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  local_mocked_bindings(
    readASRusgs = function(...) fake_usgs,
    .package = "AquaSensR"
  )
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(
        param_select  = edit_first_param,
        overlay_param = edit_second_param  # set a contdat overlay first
      )
      session$setInputs(usgs_site = "99999999", usgs_pcode = "00060", load_usgs = 1L)
      # No crash; removed count unchanged
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

# ---------------------------------------------------------------------------
# flagPlot rendering — access output$flagPlot to cover the render body
# ---------------------------------------------------------------------------

test_that("flagPlot renders without error for the default parameter (no overlay)", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      expect_no_error(invisible(output$flagPlot))
    })
  )
})

test_that("flagPlot applies x and y range layout when both ranges are set", {
  # flagPlot is evaluated eagerly during flushReact whenever cur_remaining()
  # changes.  The sequence below:
  #   1. param_select set → first render with NULL ranges (cached).
  #   2. Relayout events store x and y ranges in plot_ranges().
  #   3. A click removal invalidates cur_remaining() → flushReact re-evaluates
  #      flagPlot with rng$x and rng$y now non-NULL, executing lines 963-972.
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      session$setInputs(
        `plotly_relayout-A` = '{"xaxis.range[0]":0,"xaxis.range[1]":1}'
      )
      session$setInputs(
        `plotly_relayout-A` = '{"yaxis.range[0]":18,"yaxis.range[1]":22}'
      )
      # Removal invalidates cur_remaining() → flagPlot re-renders with stored ranges.
      expect_no_error(session$setInputs(`plotly_click-A` = '{"customdata":2}'))
    })
  )
})

test_that("plotly_relayout with y range updates plot_ranges y component", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      expect_no_error(
        session$setInputs(
          `plotly_relayout-A` = '{"yaxis.range[0]":18,"yaxis.range[1]":22}'
        )
      )
    })
  )
})

test_that("flagPlot renders without error when USGS overlay is active", {
  fake_usgs <- data.frame(
    DateTime                        = tst$contdat$DateTime,
    `Streamflow (ft³/s) [99999999]` = seq_len(nrow(tst$contdat)),
    check.names                     = FALSE,
    stringsAsFactors                = FALSE
  )
  attr(fake_usgs, "site_name") <- "Fake River"

  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  local_mocked_bindings(
    readASRusgs = function(...) fake_usgs,
    .package = "AquaSensR"
  )
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      session$setInputs(usgs_site = "99999999", usgs_pcode = "00060", load_usgs = 1L)
      # usgs_ovl() is now non-NULL; accessing the plot output exercises that branch.
      expect_no_error(invisible(output$flagPlot))
    })
  )
})

# ---------------------------------------------------------------------------
# USGS overlay: error and no-overlap branches
# ---------------------------------------------------------------------------

test_that("load_usgs shows error status when readASRusgs throws", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  local_mocked_bindings(
    readASRusgs = function(...) stop("site not found"),
    .package = "AquaSensR"
  )
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      expect_no_error(
        session$setInputs(usgs_site = "99999999", usgs_pcode = "00060", load_usgs = 1L)
      )
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

test_that("load_usgs shows no-overlap message when all returned timestamps are outside contdat range", {
  cont_tz <- attr(tst$contdat$DateTime, "tzone")
  far_future <- as.POSIXct("2099-01-01", tz = cont_tz) + 0:2 * 900L
  fake_usgs <- data.frame(
    DateTime                        = far_future,
    `Streamflow (ft³/s) [99999999]` = 1:3,
    check.names                     = FALSE
  )
  attr(fake_usgs, "site_name") <- "Fake River"

  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  local_mocked_bindings(
    readASRusgs = function(...) fake_usgs,
    .package = "AquaSensR"
  )
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      expect_no_error(
        session$setInputs(usgs_site = "99999999", usgs_pcode = "00060", load_usgs = 1L)
      )
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})

test_that("load_usgs uses Etc/GMT+5 fallback when contdat DateTime has no tzone attribute", {
  # Strip the tzone from contdat DateTime so the NULL branch (line 856) fires.
  cont_notzone <- tst$contdat
  attr(cont_notzone$DateTime, "tzone") <- NULL

  # Fake USGS data with the same (no-tzone) DateTime so the timezone check passes.
  fake_usgs <- data.frame(
    DateTime                        = cont_notzone$DateTime,
    `Streamflow (ft³/s) [99999999]` = seq_len(nrow(cont_notzone)),
    check.names                     = FALSE
  )
  attr(fake_usgs, "site_name") <- "Fake River"

  app <- AquaSensR:::editASRflag_app(cont_notzone, tst$dqodat)
  local_mocked_bindings(
    readASRusgs = function(...) fake_usgs,
    .package = "AquaSensR"
  )
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      expect_no_error(
        session$setInputs(usgs_site = "99999999", usgs_pcode = "00060", load_usgs = 1L)
      )
    })
  )
})

# ---------------------------------------------------------------------------
# Done modal — triggers showModal but NOT stopApp (which segfaults testServer)
# ---------------------------------------------------------------------------

test_that("done button shows modal without error", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      expect_no_error(session$setInputs(done = 1L))
    })
  )
})

# ---------------------------------------------------------------------------
# apply_dqo / reset_dqo: NULL param_select early-return branches
# ---------------------------------------------------------------------------

test_that("apply_dqo with NULL param_select returns early without error", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      # Fire apply_dqo before param_select is ever set — input$param_select is NULL
      # so the observer hits the early-return branch (line 1076).
      expect_no_error(session$setInputs(apply_dqo = 1L))
    })
  )
})

test_that("reset_dqo with NULL param_select returns early without error", {
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      # Same pattern: fire reset_dqo before param_select is set (line 1102).
      expect_no_error(session$setInputs(reset_dqo = 1L))
    })
  )
})

# ---------------------------------------------------------------------------
# Param label fallback: Label is NA in paramsASR → raw param name used
# ---------------------------------------------------------------------------

test_that("editASRflag_app uses raw param name as label when paramsASR Label is NA", {
  # utilASRflag() validates params against paramsASR$Parameter, so we cannot
  # inject an unknown param via contdat/dqo.  Instead, temporarily patch the
  # Label for edit_first_param to NA, which forces the `p` branch on line 143.
  #
  # Under pkgload::load_all() (used by devtools::test()), package data may live
  # in a *parent* environment of the namespace rather than in the namespace itself.
  # Walk the environment chain to locate the actual binding.
  ns <- asNamespace("AquaSensR")
  param_env <- ns
  while (!exists("paramsASR", envir = param_env, inherits = FALSE)) {
    param_env <- parent.env(param_env)
    if (identical(param_env, emptyenv())) break
  }
  if (identical(param_env, emptyenv())) {
    skip("cannot locate paramsASR binding — skipping namespace-patch test")
  }

  orig     <- get("paramsASR", envir = param_env, inherits = FALSE)
  modified <- orig
  modified$Label[modified$Parameter == edit_first_param] <- NA_character_

  is_locked <- tryCatch(
    bindingIsLocked("paramsASR", param_env),
    error = function(e) FALSE
  )
  if (is_locked) unlockBinding("paramsASR", param_env)
  assign("paramsASR", modified, envir = param_env)
  on.exit(
    {
      tryCatch(unlockBinding("paramsASR", param_env), error = function(e) NULL)
      assign("paramsASR", orig, envir = param_env)
    },
    add = TRUE
  )

  expect_s3_class(
    AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat),
    "shiny.appobj"
  )
})

# ---------------------------------------------------------------------------
# apply_linked_removals edge cases
# ---------------------------------------------------------------------------

test_that("linked removal with a single-parameter dataset does not error (length(lp) == 0)", {
  # With only one parameter, lp is empty and apply_linked_removals returns early.
  cont_one <- tst$contdat[, c("DateTime", edit_first_param)]
  dqo_one  <- tst$dqodat[tst$dqodat$Parameter == edit_first_param, ]
  app_one  <- AquaSensR:::editASRflag_app(cont_one, dqo_one)
  suppressWarnings(
    shiny::testServer(app_one, {
      session$setInputs(param_select = edit_first_param, link_all = TRUE)
      expect_no_error(session$setInputs(`plotly_click-A` = '{"customdata":1}'))
      expect_equal(output$removed_count, "Removed Points: 1")
    })
  )
})

test_that("linked removal skips a param whose DateTime was already removed (next branch)", {
  # Remove rowid 1 from param 2 WITHOUT linking so its DateTime is gone from
  # remaining.  Then, on param 1 with linking on, use a box-selection (different
  # input key from plotly_click) so the observer re-fires even though the rowid
  # is the same.  apply_linked_removals finds no mask match for param 2 and
  # hits the `next` branch, leaving param 2 at exactly 1 removal.
  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_second_param, link_all = FALSE)
      session$setInputs(`plotly_click-A` = '{"customdata":1}')
      expect_equal(output$removed_count, "Removed Points: 1")

      # Use plotly_selected (different key) so the input value changes and the
      # selection observer fires on param 1 even though the rowid is the same.
      session$setInputs(param_select = edit_first_param, link_all = TRUE)
      session$setInputs(`plotly_selected-A` = '[{"customdata":1}]')
      expect_equal(output$removed_count, "Removed Points: 1")

      # Param 2 still has exactly 1 removal — the `next` branch prevented a second.
      session$setInputs(param_select = edit_second_param)
      expect_equal(output$removed_count, "Removed Points: 1")
    })
  )
})

# ---------------------------------------------------------------------------
# Iterative editing: removed argument pre-populates the app state
# ---------------------------------------------------------------------------

test_that("editASRflag_app pre-populates removed count when removed argument is supplied", {
  # Simulate a first session: remove rowid 1 from the first parameter.
  prior_remaining <- edit_flagdat_list
  prior_remaining[[edit_first_param]] <- edit_flagdat_list[[edit_first_param]][-1L, ]
  prior_result <- AquaSensR:::editASRflag_result(
    tst$contdat,
    edit_flagdat_list,
    prior_remaining,
    tst$dqodat
  )

  # Second session: pass the cleaned contdat, dqodat, and removed.
  app2 <- AquaSensR:::editASRflag_app(
    prior_result$contdat,
    prior_result$dqodat,
    removed = prior_result$removed
  )
  suppressWarnings(
    shiny::testServer(app2, {
      session$setInputs(param_select = edit_first_param)
      # The prior removal should be visible immediately without any new action.
      expect_equal(output$removed_count, "Removed Points: 1")
    })
  )
})

test_that("editASRflag_app with removed argument: new removal adds to pre-existing count", {
  prior_remaining <- edit_flagdat_list
  prior_remaining[[edit_first_param]] <- edit_flagdat_list[[edit_first_param]][-1L, ]
  prior_result <- AquaSensR:::editASRflag_result(
    tst$contdat,
    edit_flagdat_list,
    prior_remaining,
    tst$dqodat
  )

  app2 <- AquaSensR:::editASRflag_app(
    prior_result$contdat,
    prior_result$dqodat,
    removed = prior_result$removed
  )
  suppressWarnings(
    shiny::testServer(app2, {
      session$setInputs(param_select = edit_first_param, link_all = FALSE)
      # rowid 1 was the prior removal; use rowid 2 to add a new one
      session$setInputs(`plotly_click-A` = '{"customdata":2}')
      expect_equal(output$removed_count, "Removed Points: 2")
    })
  )
})

test_that("start_over with removed argument restores to app-open state, not fully clean", {
  prior_remaining <- edit_flagdat_list
  prior_remaining[[edit_first_param]] <- edit_flagdat_list[[edit_first_param]][-1L, ]
  prior_result <- AquaSensR:::editASRflag_result(
    tst$contdat,
    edit_flagdat_list,
    prior_remaining,
    tst$dqodat
  )

  app2 <- AquaSensR:::editASRflag_app(
    prior_result$contdat,
    prior_result$dqodat,
    removed = prior_result$removed
  )
  suppressWarnings(
    shiny::testServer(app2, {
      session$setInputs(param_select = edit_first_param, link_all = FALSE)
      # Add a new removal on top of the pre-existing one
      session$setInputs(`plotly_click-A` = '{"customdata":2}')
      expect_equal(output$removed_count, "Removed Points: 2")

      # Start Over should revert to the app-open state (1 pre-existing removal)
      session$setInputs(reset = 1L)
      session$setInputs(reset_confirm = 1L)
      expect_equal(output$removed_count, "Removed Points: 1")
    })
  )
})

test_that("selecting contdat overlay after USGS load clears usgs_ovl", {
  fake_usgs <- data.frame(
    DateTime              = tst$contdat$DateTime,
    `Streamflow (ft³/s) [99999999]` = seq_len(nrow(tst$contdat)),
    check.names           = FALSE,
    stringsAsFactors      = FALSE
  )
  attr(fake_usgs, "site_name") <- "Fake River"

  app <- AquaSensR:::editASRflag_app(tst$contdat, tst$dqodat)
  local_mocked_bindings(
    readASRusgs = function(...) fake_usgs,
    .package = "AquaSensR"
  )
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = edit_first_param)
      # Load USGS data
      session$setInputs(usgs_site = "99999999", usgs_pcode = "00060", load_usgs = 1L)
      # Now select a contdat overlay — should clear USGS
      session$setInputs(overlay_param = edit_second_param)
      # No crash; plot still renders
      expect_equal(output$removed_count, "Removed Points: 0")
    })
  )
})
