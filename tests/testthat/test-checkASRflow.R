test_that("checkASRflow passes valid data without errors", {
  expect_no_error(checkASRflow(tst$flowdatchk))

  result <- checkASRflow(tst$flowdatchk)
  expect_equal(result, tst$flowdatchk)
})

test_that("checkASRflow accepts time as plain HH:MM:SS strings", {
  plain_time_data <- tst$flowdatchk
  # data from utilASRimportcont() is already in HH:MM:SS format

  expect_no_error(checkASRflow(plain_time_data))

  plain_time_data$Time[1] <- "not-a-time"
  expect_error(
    checkASRflow(plain_time_data),
    "\tChecking time format...\n\tThe following rows have times that are not in a recognizable format: 1",
    fixed = TRUE
  )
})

test_that("checkASRflow accepts 12-hour AM/PM time format", {
  ampm_time_data <- tst$flowdatchk
  ampm_time_data$Time <- format(
    lubridate::parse_date_time(
      ampm_time_data$Time,
      orders = c('HMS', 'ymd HMS')
    ),
    "%I:%M:%S %p"
  )

  expect_no_error(checkASRflow(ampm_time_data))

  ampm_time_data$Time[1] <- "not-a-time"
  expect_error(
    checkASRflow(ampm_time_data),
    "\tChecking time format...\n\tThe following rows have times that are not in a recognizable format: 1",
    fixed = TRUE
  )
})

test_that("checkASRflow errors on invalid column names", {
  bad_data <- tst$flowdatchk
  names(bad_data)[names(bad_data) == "Date"] <- "InvalidColumn"

  expect_error(
    checkASRflow(bad_data),
    "\tChecking column names...\n\tPlease correct the column names or remove: InvalidColumn",
    fixed = TRUE
  )
})

test_that("checkASRflow errors when required columns are missing", {
  # Missing Date column
  bad_data <- tst$flowdatchk[, names(tst$flowdatchk) != "Date"]

  expect_error(
    checkASRflow(bad_data),
    "\tChecking Date, Time are present...\n\tMissing the following columns: Date",
    fixed = TRUE
  )
})

test_that("checkASRflow errors when zero flow/stage columns present", {
  bad_data <- tst$flowdatchk[, c("Date", "Time")]

  expect_error(
    checkASRflow(bad_data),
    "\tChecking exactly one flow or stage height column is present...\n\tNo flow or stage height column found. Please include exactly one from: ",
    fixed = TRUE
  )
})

test_that("checkASRflow errors when multiple flow/stage columns present (same group)", {
  bad_data <- tst$flowdatchk
  bad_data$Gage_Height_ft <- bad_data$Sensor_Depth_ft

  expect_error(
    checkASRflow(bad_data),
    "\tChecking exactly one flow or stage height column is present...\n\tMultiple flow or stage height columns found, only one is allowed: Gage_Height_ft, Sensor_Depth_ft",
    fixed = TRUE
  )
})

test_that("checkASRflow errors when multiple flow/stage columns present (Discharge_cfs + Flow_cfs)", {
  bad_data <- tst$flowdatchk
  bad_data$Sensor_Depth_ft <- NULL
  bad_data$Discharge_cfs <- 1
  bad_data$Flow_cfs <- 2

  expect_error(
    checkASRflow(bad_data),
    "\tChecking exactly one flow or stage height column is present...\n\tMultiple flow or stage height columns found, only one is allowed: Discharge_cfs, Flow_cfs",
    fixed = TRUE
  )
})

test_that("checkASRflow rejects an unrelated cont parameter at the column-name check, not cardinality", {
  bad_data <- tst$flowdatchk
  bad_data$Water_Temp_C <- 20

  expect_error(
    checkASRflow(bad_data),
    "\tChecking column names...\n\tPlease correct the column names or remove: Water_Temp_C",
    fixed = TRUE
  )
})

test_that("checkASRflow accepts the Flow_cfs alias", {
  good_data <- tst$flowdatchk
  good_data$Sensor_Depth_ft <- NULL
  good_data$Flow_cfs <- "10.5"

  expect_no_error(checkASRflow(good_data))
})

test_that("checkASRflow accepts Date in MM/DD/YYYY (month-first) format", {
  mdy_data <- tst$flowdatchk
  mdy_data$Date <- "8/10/2024"
  expect_no_error(checkASRflow(mdy_data))
})

test_that("checkASRflow accepts Date in DD/MM/YYYY (day-first) format", {
  dmy_data <- tst$flowdatchk
  dmy_data$Date <- "10/08/2024"
  expect_no_error(checkASRflow(dmy_data))
})

test_that("checkASRflow errors on invalid date format", {
  bad_data <- tst$flowdatchk
  bad_data$Date[1] <- "invalid-date"

  expect_error(
    checkASRflow(bad_data),
    "\tChecking date format...\n\tThe following rows have dates that are not in a recognizable format: 1",
    fixed = TRUE
  )
})

test_that("checkASRflow errors on invalid time format", {
  bad_data <- tst$flowdatchk
  bad_data$Time[1] <- "not-a-time"

  expect_error(
    checkASRflow(bad_data),
    "\tChecking time format...\n\tThe following rows have times that are not in a recognizable format: 1",
    fixed = TRUE
  )
})

test_that("checkASRflow warns on missing values", {
  bad_data <- tst$flowdatchk
  bad_data$Sensor_Depth_ft[3] <- NA

  expected_msg <- paste0(
    "\tChecking for missing values...\n\t",
    "The following columns have missing values in the following rows: ",
    "Sensor_Depth_ft (3)"
  )

  expect_warning(
    checkASRflow(bad_data),
    expected_msg,
    fixed = TRUE
  )
})

test_that("checkASRflow passes valid combined DateTime data", {
  expect_no_error(checkASRflow(tst$flowdatchk2))

  result <- checkASRflow(tst$flowdatchk2)
  expect_equal(result, tst$flowdatchk2)
})

test_that("checkASRflow errors on invalid DateTime format", {
  bad_data <- tst$flowdatchk2
  bad_data$DateTime[1] <- "not-a-datetime"

  expect_error(
    checkASRflow(bad_data),
    "\tChecking DateTime format...\n\tThe following rows have DateTime values that are not in a recognizable format: 1",
    fixed = TRUE
  )
})

test_that("checkASRflow errors when DateTime column missing (combined format)", {
  # Removing DateTime causes the function to treat the data as separate-column
  # format, so it reports Date and Time as missing
  bad_data <- tst$flowdatchk2[, names(tst$flowdatchk2) != "DateTime"]

  expect_error(
    checkASRflow(bad_data),
    "\tChecking Date, Time are present...\n\tMissing the following columns: Date, Time",
    fixed = TRUE
  )
})

test_that("checkASRflow errors when zero flow/stage columns present (combined format)", {
  bad_data <- tst$flowdatchk2[, c("DateTime")]

  expect_error(
    checkASRflow(bad_data),
    "\tChecking exactly one flow or stage height column is present...\n\tNo flow or stage height column found. Please include exactly one from: ",
    fixed = TRUE
  )
})

test_that("checkASRflow errors on non-numeric flow/stage values", {
  bad_data <- tst$flowdatchk
  bad_data$Sensor_Depth_ft[3] <- "text"

  expected_msg <- paste0(
    "\tChecking flow or stage height column for non-numeric values...\n\t",
    "The following rows have non-numeric values in column Sensor_Depth_ft: 3"
  )

  expect_error(
    checkASRflow(bad_data),
    expected_msg,
    fixed = TRUE
  )

  bad_data <- tst$flowdatchk
  bad_data$Sensor_Depth_ft[1] <- "text"
  bad_data$Sensor_Depth_ft[3] <- "text"

  expected_msg <- paste0(
    "\tChecking flow or stage height column for non-numeric values...\n\t",
    "The following rows have non-numeric values in column Sensor_Depth_ft: 1, 3"
  )

  expect_error(
    checkASRflow(bad_data),
    expected_msg,
    fixed = TRUE
  )
})
