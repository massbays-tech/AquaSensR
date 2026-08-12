# Tests for editASRbulk split across two approaches (same convention as
# test-editASRflag.R / test-editASRdrift.R):
#
# 1. shiny::testServer() via editASRbulk_app() — tests reactive server logic
#    (removals, undo, reset, navigation) without a browser.
#
# 2. Direct calls to editASRbulk_result() — tests the "done" output logic as
#    pure R (no stopApp, no Shiny reactive domain needed).
#
# Key testServer quirks (see test-editASRflag.R for the fuller writeup):
#  - plotly::event_data() requires JSON-string input, e.g.
#    session$setInputs(`plotly_selected-A` = '[{"customdata":1}]')
#  - updateSelectInput() does not round-trip in testServer, so param_next /
#    param_prev are only checked for "fires without error".
#  - stopApp() segfaults inside testServer — never trigger input$done_confirm
#    or input$done_discard in a testServer block.
#  - session$close() auto-invokes onSessionEnded(); the
#    inherits(session, "MockShinySession") guard must stay in place.
#
# Unlike editASRflag, removal here is global (always linked), so there is a
# single removal history shared by every parameter rather than a per-parameter
# list — tests exercise that directly via the `history()`/`removed_points()`
# reactives exposed in the server environment.

make_bulk_cont <- function(n = 24, tz = "Etc/GMT+5") {
  data.frame(
    DateTime = seq(
      as.POSIXct("2024-08-01 00:00:00", tz = tz),
      by = "hour",
      length.out = n
    ),
    Water_Temp_C = seq(20, by = 0.1, length.out = n),
    DO_mg_l = seq(8, by = -0.02, length.out = n),
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# App construction
# ---------------------------------------------------------------------------

test_that("editASRbulk_app() returns a shiny app object", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  expect_s3_class(app, "shiny.appobj")
})

test_that("app handles cont with NULL timezone attribute", {
  cont <- make_bulk_cont()
  attr(cont$DateTime, "tzone") <- NULL
  expect_s3_class(AquaSensR:::editASRbulk_app(cont), "shiny.appobj")
})

test_that("app handles cont with empty-string timezone attribute", {
  cont <- make_bulk_cont()
  attr(cont$DateTime, "tzone") <- ""
  expect_s3_class(AquaSensR:::editASRbulk_app(cont), "shiny.appobj")
})

test_that("app uses parameter name as label when param is not in paramsASR", {
  cont <- data.frame(
    DateTime = seq(
      as.POSIXct("2024-08-01", tz = "Etc/GMT+5"),
      by = "hour",
      length.out = 10
    ),
    custom_sensor = rnorm(10),
    stringsAsFactors = FALSE
  )
  expect_s3_class(AquaSensR:::editASRbulk_app(cont), "shiny.appobj")
})

# ---------------------------------------------------------------------------
# Initial state
# ---------------------------------------------------------------------------

test_that("removed_count output starts at zero", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      expect_equal(output$removed_count, "Removed Timestamps: 0")
    })
  )
})

# ---------------------------------------------------------------------------
# Box / lasso selection removal — always linked across every parameter
# ---------------------------------------------------------------------------

test_that("plotly_selected removes the targeted timestamps from every parameter", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(
        `plotly_selected-A` = '[{"customdata":1},{"customdata":2}]'
      )
      expect_equal(output$removed_count, "Removed Timestamps: 2")

      rp <- removed_points()
      expect_equal(nrow(rp), 4L) # 2 timestamps x 2 parameters
      expect_setequal(rp$Parameter, c("Water_Temp_C", "DO_mg_l"))
    })
  )
})

test_that("removal is visible after switching parameters (global, not per-param)", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(`plotly_selected-A` = '[{"customdata":1}]')
      expect_equal(output$removed_count, "Removed Timestamps: 1")

      session$setInputs(param_select = "DO_mg_l")
      expect_equal(output$removed_count, "Removed Timestamps: 1")
    })
  )
})

test_that("plotly_selected with an empty selection is a no-op", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      expect_no_error(session$setInputs(`plotly_selected-A` = "null"))
      expect_equal(output$removed_count, "Removed Timestamps: 0")
    })
  )
})

# ---------------------------------------------------------------------------
# Undo
# ---------------------------------------------------------------------------

test_that("undo restores the removed timestamps for every parameter", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(`plotly_selected-A` = '[{"customdata":1},{"customdata":2}]')
      expect_equal(output$removed_count, "Removed Timestamps: 2")

      session$setInputs(undo = 1L)
      expect_equal(output$removed_count, "Removed Timestamps: 0")
    })
  )
})

test_that("undo is per-batch: two selections require two undos to fully restore", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(`plotly_selected-A` = '[{"customdata":1}]')
      session$setInputs(`plotly_selected-A` = '[{"customdata":2}]')
      expect_equal(output$removed_count, "Removed Timestamps: 2")

      session$setInputs(undo = 1L)
      expect_equal(output$removed_count, "Removed Timestamps: 1")

      session$setInputs(undo = 1L)
      expect_equal(output$removed_count, "Removed Timestamps: 0")
    })
  )
})

test_that("undo with no history is a no-op", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      expect_no_error(session$setInputs(undo = 1L))
      expect_equal(output$removed_count, "Removed Timestamps: 0")
    })
  )
})

# ---------------------------------------------------------------------------
# Reset / Start Over (don't call reset_confirm-triggered stopApp — n/a here,
# reset_confirm just clears history, no stopApp involved)
# ---------------------------------------------------------------------------

test_that("reset shows the modal without clearing removals until confirmed", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(`plotly_selected-A` = '[{"customdata":1},{"customdata":2}]')
      expect_equal(output$removed_count, "Removed Timestamps: 2")

      session$setInputs(reset = 1L)
      expect_equal(output$removed_count, "Removed Timestamps: 2")

      session$setInputs(reset_confirm = 1L)
      expect_equal(output$removed_count, "Removed Timestamps: 0")
    })
  )
})

# ---------------------------------------------------------------------------
# Parameter navigation — use manual param_select switch (updateSelectInput
# does not round-trip in testServer)
# ---------------------------------------------------------------------------

test_that("param_prev at the first parameter does not change selection", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(param_prev = 1L)
      expect_equal(input$param_select, "Water_Temp_C")
    })
  )
})

test_that("param_prev and param_next fire without error", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      expect_no_error(session$setInputs(param_next = 1L))
      expect_no_error(session$setInputs(param_prev = 1L))
    })
  )
})

# ---------------------------------------------------------------------------
# Zoom state via plotly_relayout
# ---------------------------------------------------------------------------

test_that("plotly_relayout stores x and y ranges", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(
        `plotly_relayout-A` = '{"xaxis.range[0]":1000,"xaxis.range[1]":2000,"yaxis.range[0]":15,"yaxis.range[1]":25}'
      )
      expect_equal(plot_ranges()$x, c(1000, 2000))
      expect_equal(plot_ranges()$y, c(15, 25))
    })
  )
})

test_that("plotly_relayout autorange resets stored ranges to NULL", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(`plotly_relayout-A` = '{"xaxis.range[0]":1000,"xaxis.range[1]":2000}')
      session$setInputs(`plotly_relayout-A` = '{"xaxis.autorange":true}')
      expect_null(plot_ranges()$x)
    })
  )
})

# ---------------------------------------------------------------------------
# Plot rendering
# ---------------------------------------------------------------------------

test_that("bulkPlot renders without error for the default parameter", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      expect_no_error(invisible(output$bulkPlot))
    })
  )
})

test_that("bulkPlot renders without error after a removal", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(`plotly_selected-A` = '[{"customdata":1}]')
      expect_no_error(invisible(output$bulkPlot))
    })
  )
})

# ---------------------------------------------------------------------------
# Done modal (don't call *_confirm/*_discard — stopApp segfaults in testServer)
# ---------------------------------------------------------------------------

test_that("done observer fires without error", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      expect_no_error(session$setInputs(done = 1L))
    })
  )
})

# ---------------------------------------------------------------------------
# Ungraceful close safety net
# ---------------------------------------------------------------------------

test_that("session$close() does not error when app closed without Done/Close", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      expect_no_error(session$close())
    })
  )
})

test_that("session$close() is a no-op once Done/Close has already fired", {
  cont <- make_bulk_cont()
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$env$app_closing <- TRUE
      expect_no_error(session$close())
    })
  )
})

# ---------------------------------------------------------------------------
# Iterative editing: removed argument pre-populates the app state
# ---------------------------------------------------------------------------

test_that("editASRbulk_app pre-populates removed count when removed argument is supplied", {
  cont <- make_bulk_cont()
  full_cont <- cont
  full_cont$.rowid <- seq_len(nrow(full_cont))
  prior_removed <- data.frame(
    Parameter = c("Water_Temp_C", "DO_mg_l"),
    DateTime = full_cont$DateTime[1L],
    Value = c(full_cont$Water_Temp_C[1L], full_cont$DO_mg_l[1L]),
    stringsAsFactors = FALSE
  )
  prior_result <- AquaSensR:::editASRbulk_result(full_cont, prior_removed)

  app2 <- AquaSensR:::editASRbulk_app(
    prior_result$contdat,
    removed = prior_result$removed
  )
  suppressWarnings(
    shiny::testServer(app2, {
      session$setInputs(param_select = "Water_Temp_C")
      expect_equal(output$removed_count, "Removed Timestamps: 1")
    })
  )
})

test_that("editASRbulk_app with removed argument: new removal adds to pre-existing count", {
  cont <- make_bulk_cont()
  full_cont <- cont
  full_cont$.rowid <- seq_len(nrow(full_cont))
  prior_removed <- data.frame(
    Parameter = c("Water_Temp_C", "DO_mg_l"),
    DateTime = full_cont$DateTime[1L],
    Value = c(full_cont$Water_Temp_C[1L], full_cont$DO_mg_l[1L]),
    stringsAsFactors = FALSE
  )
  prior_result <- AquaSensR:::editASRbulk_result(full_cont, prior_removed)

  app2 <- AquaSensR:::editASRbulk_app(
    prior_result$contdat,
    removed = prior_result$removed
  )
  suppressWarnings(
    shiny::testServer(app2, {
      session$setInputs(param_select = "Water_Temp_C")
      # rowid 1 was the prior removal (now NA); rowid 2 is a fresh point
      session$setInputs(`plotly_selected-A` = '[{"customdata":2}]')
      expect_equal(output$removed_count, "Removed Timestamps: 2")
    })
  )
})

test_that("start_over with removed argument restores to app-open state, not fully clean", {
  cont <- make_bulk_cont()
  full_cont <- cont
  full_cont$.rowid <- seq_len(nrow(full_cont))
  prior_removed <- data.frame(
    Parameter = c("Water_Temp_C", "DO_mg_l"),
    DateTime = full_cont$DateTime[1L],
    Value = c(full_cont$Water_Temp_C[1L], full_cont$DO_mg_l[1L]),
    stringsAsFactors = FALSE
  )
  prior_result <- AquaSensR:::editASRbulk_result(full_cont, prior_removed)

  app2 <- AquaSensR:::editASRbulk_app(
    prior_result$contdat,
    removed = prior_result$removed
  )
  suppressWarnings(
    shiny::testServer(app2, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(`plotly_selected-A` = '[{"customdata":2}]')
      expect_equal(output$removed_count, "Removed Timestamps: 2")

      session$setInputs(reset = 1L)
      session$setInputs(reset_confirm = 1L)
      expect_equal(output$removed_count, "Removed Timestamps: 1")
    })
  )
})

# ---------------------------------------------------------------------------
# editASRbulk_result() — "done" output logic tested as pure R (no stopApp)
# ---------------------------------------------------------------------------

test_that("editASRbulk_result with no removals returns sorted contdat and empty removed", {
  cont <- make_bulk_cont()
  full_cont <- cont[order(cont$DateTime), ]
  full_cont$.rowid <- seq_len(nrow(full_cont))
  empty_removed <- data.frame(
    Parameter = character(0),
    DateTime = as.POSIXct(character(0), tz = "Etc/GMT+5"),
    Value = numeric(0),
    stringsAsFactors = FALSE
  )

  result <- AquaSensR:::editASRbulk_result(full_cont, empty_removed)

  expect_named(result, c("contdat", "removed"))
  expect_equal(result$contdat, cont[order(cont$DateTime), ], ignore_attr = TRUE)
  expect_equal(nrow(result$removed), 0L)
  expect_named(result$removed, c("Parameter", "DateTime", "Value"))
})

test_that("editASRbulk_result sets NA for every parameter at a removed timestamp", {
  cont <- make_bulk_cont()
  full_cont <- cont[order(cont$DateTime), ]
  full_cont$.rowid <- seq_len(nrow(full_cont))
  removed <- data.frame(
    Parameter = c("Water_Temp_C", "DO_mg_l"),
    DateTime = full_cont$DateTime[1L],
    Value = c(full_cont$Water_Temp_C[1L], full_cont$DO_mg_l[1L]),
    stringsAsFactors = FALSE
  )

  result <- AquaSensR:::editASRbulk_result(full_cont, removed)

  expect_equal(nrow(result$removed), 2L)
  expect_true(is.na(result$contdat$Water_Temp_C[1L]))
  expect_true(is.na(result$contdat$DO_mg_l[1L]))
  # DateTime itself is retained for a fully-removed row
  expect_false(is.na(result$contdat$DateTime[1L]))
  # Other rows are untouched
  expect_false(is.na(result$contdat$Water_Temp_C[2L]))
})

test_that("editASRbulk_result ignores a removed Parameter absent from contdat", {
  cont <- make_bulk_cont()
  full_cont <- cont[order(cont$DateTime), ]
  full_cont$.rowid <- seq_len(nrow(full_cont))
  removed <- data.frame(
    Parameter = "not_a_real_param",
    DateTime = full_cont$DateTime[1L],
    Value = 1,
    stringsAsFactors = FALSE
  )

  expect_no_error(
    result <- AquaSensR:::editASRbulk_result(full_cont, removed)
  )
  expect_false(is.na(result$contdat$Water_Temp_C[1L]))
})

# ---------------------------------------------------------------------------
# Edge case: single-parameter dataset
# ---------------------------------------------------------------------------

test_that("app and result helper work with a single-parameter dataset", {
  cont <- make_bulk_cont()[, c("DateTime", "Water_Temp_C")]
  app <- AquaSensR:::editASRbulk_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(`plotly_selected-A` = '[{"customdata":1}]')
      expect_equal(output$removed_count, "Removed Timestamps: 1")

      session$setInputs(param_prev = 1L)
      session$setInputs(param_next = 1L)
      expect_equal(input$param_select, "Water_Temp_C")
    })
  )
})
