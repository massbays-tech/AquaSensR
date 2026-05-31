make_drift_cont <- function(n = 10, tz = "Etc/GMT+5") {
  data.frame(
    DateTime = seq(
      as.POSIXct("2024-08-01 00:00:00", tz = tz),
      by = "hour",
      length.out = n
    ),
    Water_Temp_C = seq(20, by = 0.5, length.out = n),
    stringsAsFactors = FALSE
  )
}

test_that("values outside window are unchanged", {
  cont <- make_drift_cont(10)
  res  <- utilASRdrift(cont, "Water_Temp_C", cal_ref = 25.0,
                       cont$DateTime[4], cont$DateTime[7])
  expect_equal(res$Water_Temp_C[1:3],  cont$Water_Temp_C[1:3])
  expect_equal(res$Water_Temp_C[8:10], cont$Water_Temp_C[8:10])
})

test_that("correction at drift_start_time is zero", {
  cont <- make_drift_cont(10)
  res  <- utilASRdrift(cont, "Water_Temp_C", cal_ref = 99.0,
                       cont$DateTime[4], cont$DateTime[7])
  expect_equal(res$Water_Temp_C[4], cont$Water_Temp_C[4])
})

test_that("correction at drift_end_time equals cal_ref", {
  cont <- make_drift_cont(10)
  res  <- utilASRdrift(cont, "Water_Temp_C", cal_ref = 23.5,
                       cont$DateTime[4], cont$DateTime[7])
  expect_equal(res$Water_Temp_C[7], 23.5)
})

test_that("correction is linear across the window", {
  cont <- make_drift_cont(6)
  cal_ref <- 25.0
  res     <- utilASRdrift(cont, "Water_Temp_C", cal_ref = cal_ref,
                          cont$DateTime[1], cont$DateTime[6])
  cal_check <- cont$Water_Temp_C[6]
  expected  <- cont$Water_Temp_C + (cal_ref - cal_check) * (0:5) / 5
  expect_equal(res$Water_Temp_C, expected)
})

test_that("returns cont unchanged when window contains no data", {
  cont <- make_drift_cont(5)
  t_out <- cont$DateTime[5] + 3600
  res   <- utilASRdrift(cont, "Water_Temp_C", cal_ref = 25.0, t_out, t_out + 3600)
  expect_equal(res$Water_Temp_C, cont$Water_Temp_C)
})

test_that("warns and returns cont unchanged for single-row window", {
  cont <- make_drift_cont(5)
  t    <- cont$DateTime[3]
  expect_warning(
    res <- utilASRdrift(cont, "Water_Temp_C", cal_ref = 25.0, t, t),
    "fewer than 2 observations"
  )
  expect_equal(res$Water_Temp_C, cont$Water_Temp_C)
})

test_that("stops on unknown parameter", {
  cont <- make_drift_cont(5)
  expect_error(
    utilASRdrift(cont, "nonexistent", cal_ref = 20.0,
                 cont$DateTime[1], cont$DateTime[5]),
    "'nonexistent' column not found"
  )
})

test_that("zero drift when cal_ref equals cal_check leaves values unchanged", {
  cont      <- make_drift_cont(6)
  cal_check <- cont$Water_Temp_C[6]
  res       <- utilASRdrift(cont, "Water_Temp_C", cal_ref = cal_check,
                            cont$DateTime[1], cont$DateTime[6])
  expect_equal(res$Water_Temp_C, cont$Water_Temp_C)
})
