make_drift_cont_app <- function(n = 24, tz = "Etc/GMT+5") {
  data.frame(
    DateTime = seq(
      as.POSIXct("2024-08-01 00:00:00", tz = tz),
      by = "hour",
      length.out = n
    ),
    Water_Temp_C = seq(20, by = 0.1, length.out = n),
    stringsAsFactors = FALSE
  )
}

make_empty_log <- function(tz = "Etc/GMT+5") {
  data.frame(
    Parameter     = character(0),
    drift_start   = as.POSIXct(character(0), tz = tz),
    drift_end     = as.POSIXct(character(0), tz = tz),
    cal_ref       = numeric(0),
    cal_check     = numeric(0),
    drift_applied = numeric(0),
    stringsAsFactors = FALSE
  )
}

test_that("editASRdrift_app() returns a shiny app object", {
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
  expect_s3_class(app, "shiny.appobj")
})

test_that("editASRdrift_result() returns correct list structure", {
  cont <- make_drift_cont_app()
  log  <- make_empty_log()
  res  <- editASRdrift_result(cont, log)
  expect_named(res, c("contdat", "corrections"))
  expect_s3_class(res$contdat, "data.frame")
  expect_s3_class(res$corrections, "data.frame")
})

test_that("editASRdrift_result() sorts contdat by DateTime", {
  cont <- make_drift_cont_app()
  shuffled <- cont[sample(nrow(cont)), ]
  res <- editASRdrift_result(shuffled, make_empty_log())
  expect_true(all(diff(as.numeric(res$contdat$DateTime)) >= 0))
})

test_that("editASRdrift_result() preserves corrections data frame", {
  cont <- make_drift_cont_app()
  tz   <- "Etc/GMT+5"
  log  <- data.frame(
    Parameter     = "Water_Temp_C",
    drift_start   = as.POSIXct("2024-08-01 03:00:00", tz = tz),
    drift_end     = as.POSIXct("2024-08-01 10:00:00", tz = tz),
    cal_ref       = 21.5,
    cal_check     = 21.0,
    drift_applied = 0.5,
    stringsAsFactors = FALSE
  )
  res <- editASRdrift_result(cont, log)
  expect_equal(nrow(res$corrections), 1L)
  expect_equal(res$corrections$drift_applied, 0.5)
})

test_that("server initialises with empty selections and unchanged data", {
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      expect_equal(working_cont()$Water_Temp_C, cont$Water_Temp_C)
      expect_equal(length(selected_points()), 0L)
      expect_equal(nrow(corrections_log()), 0L)
    })
  )
})

test_that("server selected_period output reflects empty selection", {
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      expect_match(output$selected_period, "Click plot")
    })
  )
})

test_that("server start-over resets working_cont and log", {
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(reset_confirm = 1)
      expect_equal(working_cont()$Water_Temp_C, cont$Water_Temp_C)
      expect_equal(nrow(corrections_log()), 0L)
    })
  )
})

# ---------------------------------------------------------------------------
# App construction edge cases
# ---------------------------------------------------------------------------

test_that("app handles cont with NULL timezone attribute", {
  cont <- make_drift_cont_app()
  attr(cont$DateTime, "tzone") <- NULL
  expect_s3_class(AquaSensR:::editASRdrift_app(cont), "shiny.appobj")
})

test_that("app handles cont with empty-string timezone attribute", {
  cont <- make_drift_cont_app()
  attr(cont$DateTime, "tzone") <- ""
  expect_s3_class(AquaSensR:::editASRdrift_app(cont), "shiny.appobj")
})

test_that("app uses parameter name as label when param is not in paramsASR", {
  cont <- data.frame(
    DateTime      = seq(as.POSIXct("2024-08-01", tz = "Etc/GMT+5"), by = "hour", length.out = 10),
    custom_sensor = rnorm(10),
    stringsAsFactors = FALSE
  )
  expect_s3_class(AquaSensR:::editASRdrift_app(cont), "shiny.appobj")
})

# ---------------------------------------------------------------------------
# Plotly click — selecting the drift period
# ---------------------------------------------------------------------------

# Helper: format a DateTime as the JSON plotly would send to the click observer.
# The click handler uses as.POSIXct(click$x, origin = "1970-01-01") which
# treats the numeric value as seconds since epoch — the same unit as as.numeric()
# on a POSIXct.
click_json <- function(dt) paste0('{"x":', as.numeric(dt), '}')

test_that("first plotly click shows start time in selected_period", {
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(`plotly_click-A` = click_json(cont$DateTime[5]))
      expect_match(output$selected_period, "Start:")
      expect_match(output$selected_period, "Click again")
    })
  )
})

test_that("two plotly clicks show start and end in selected_period", {
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(`plotly_click-A` = click_json(cont$DateTime[5]))
      session$setInputs(`plotly_click-A` = click_json(cont$DateTime[15]))
      expect_match(output$selected_period, "Start:")
      expect_match(output$selected_period, "End:")
    })
  )
})

test_that("third plotly click resets selection back to empty", {
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(`plotly_click-A` = click_json(cont$DateTime[5]))
      session$setInputs(`plotly_click-A` = click_json(cont$DateTime[15]))
      session$setInputs(`plotly_click-A` = click_json(cont$DateTime[20]))
      expect_match(output$selected_period, "Click plot")
    })
  )
})

test_that("switching parameter resets selected points", {
  cont        <- make_drift_cont_app()
  cont$DO_mg_l <- rnorm(nrow(cont), 8, 0.5)
  app <- AquaSensR:::editASRdrift_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(`plotly_click-A` = click_json(cont$DateTime[5]))
      expect_match(output$selected_period, "Start:")
      session$setInputs(param_select = "DO_mg_l")
      expect_match(output$selected_period, "Click plot")
    })
  )
})

# ---------------------------------------------------------------------------
# Apply correction
# ---------------------------------------------------------------------------

test_that("apply_correction corrects end value to cal_ref and logs the correction", {
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(`plotly_click-A` = click_json(cont$DateTime[3]))
      session$setInputs(`plotly_click-A` = click_json(cont$DateTime[20]))
      session$setInputs(cal_ref = 22.0, apply_correction = 1)

      t2 <- cont$DateTime[20]
      expect_equal(working_cont()$Water_Temp_C[working_cont()$DateTime == t2], 22.0)
      expect_equal(nrow(corrections_log()), 1L)
      expect_equal(corrections_log()$cal_ref, 22.0)
      expect_equal(length(selected_points()), 0L)
    })
  )
})

test_that("apply_correction leaves start value unchanged", {
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(`plotly_click-A` = click_json(cont$DateTime[3]))
      session$setInputs(`plotly_click-A` = click_json(cont$DateTime[20]))
      original_start <- cont$Water_Temp_C[3]
      session$setInputs(cal_ref = 22.0, apply_correction = 1)

      t1 <- cont$DateTime[3]
      expect_equal(working_cont()$Water_Temp_C[working_cont()$DateTime == t1], original_start)
    })
  )
})

test_that("apply_correction is a no-op when fewer than 2 points are selected", {
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      original_vals <- working_cont()$Water_Temp_C
      session$setInputs(cal_ref = 22.0, apply_correction = 1)
      expect_equal(working_cont()$Water_Temp_C, original_vals)
      expect_equal(nrow(corrections_log()), 0L)
    })
  )
})

test_that("apply_correction is a no-op when cal_ref is NA", {
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      session$setInputs(`plotly_click-A` = click_json(cont$DateTime[3]))
      session$setInputs(`plotly_click-A` = click_json(cont$DateTime[20]))
      original_vals <- working_cont()$Water_Temp_C
      session$setInputs(cal_ref = NA, apply_correction = 1)
      expect_equal(working_cont()$Water_Temp_C, original_vals)
    })
  )
})

test_that("corrections_count updates after apply and after undo", {
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      expect_equal(output$corrections_count, "Corrections Log: 0")
      session$setInputs(`plotly_click-A` = click_json(cont$DateTime[3]))
      session$setInputs(`plotly_click-A` = click_json(cont$DateTime[20]))
      session$setInputs(cal_ref = 22.0, apply_correction = 1)
      expect_equal(output$corrections_count, "Corrections Log: 1")
      session$setInputs(undo = 1L)
      expect_equal(output$corrections_count, "Corrections Log: 0")
    })
  )
})

# ---------------------------------------------------------------------------
# Undo
# ---------------------------------------------------------------------------

test_that("undo restores original values after a correction", {
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      original_vals <- working_cont()$Water_Temp_C
      session$setInputs(`plotly_click-A` = click_json(cont$DateTime[3]))
      session$setInputs(`plotly_click-A` = click_json(cont$DateTime[20]))
      session$setInputs(cal_ref = 22.0, apply_correction = 1)
      expect_false(identical(working_cont()$Water_Temp_C, original_vals))
      session$setInputs(undo = 1L)
      expect_equal(working_cont()$Water_Temp_C, original_vals)
      expect_equal(nrow(corrections_log()), 0L)
    })
  )
})

test_that("undo with no history is a no-op", {
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      original_vals <- working_cont()$Water_Temp_C
      expect_no_error(session$setInputs(undo = 1L))
      expect_equal(working_cont()$Water_Temp_C, original_vals)
    })
  )
})

# ---------------------------------------------------------------------------
# Reset and Done modals (don't call *_confirm — stopApp segfaults in testServer)
# ---------------------------------------------------------------------------

test_that("reset observer fires without error", {
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      expect_no_error(session$setInputs(reset = 1L))
    })
  )
})

test_that("done observer fires without error", {
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      expect_no_error(session$setInputs(done = 1L))
    })
  )
})

# ---------------------------------------------------------------------------
# Zoom state via plotly_relayout
# ---------------------------------------------------------------------------

test_that("plotly_relayout stores x and y ranges", {
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
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
  cont <- make_drift_cont_app()
  app  <- AquaSensR:::editASRdrift_app(cont)
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
# Parameter navigation
# ---------------------------------------------------------------------------

test_that("param_prev and param_next fire without error", {
  cont         <- make_drift_cont_app()
  cont$DO_mg_l <- rnorm(nrow(cont), 8, 0.5)
  app <- AquaSensR:::editASRdrift_app(cont)
  suppressWarnings(
    shiny::testServer(app, {
      session$setInputs(param_select = "Water_Temp_C")
      expect_no_error(session$setInputs(param_next = 1L))
      expect_no_error(session$setInputs(param_prev = 1L))
    })
  )
})
