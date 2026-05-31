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
