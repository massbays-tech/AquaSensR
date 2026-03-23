test_that("checkASRcont passes valid data without errors", {
  expect_no_error(checkASRcont(tst$contdatchk))

  result <- checkASRcont(tst$contdatchk)
  expect_equal(result, tst$contdatchk)
})

test_that("checkASRcont accepts time as plain HH:MM:SS strings", {
  plain_time_data <- tst$contdatchk
  # data from read_cont_raw() is already in HH:MM:SS format

  expect_no_error(checkASRcont(plain_time_data))

  plain_time_data$Time[1] <- "not-a-time"
  expect_error(
    checkASRcont(plain_time_data),
    "\tChecking time format...\n\tThe following rows have times that are not in a recognizable format: 1",
    fixed = TRUE
  )
})

test_that("checkASRcont accepts 12-hour AM/PM time format", {
  ampm_time_data <- tst$contdatchk
  ampm_time_data$Time <- format(
    lubridate::parse_date_time(ampm_time_data$Time, orders = c('HMS', 'ymd HMS')),
    "%I:%M:%S %p"
  )

  expect_no_error(checkASRcont(ampm_time_data))

  ampm_time_data$Time[1] <- "not-a-time"
  expect_error(
    checkASRcont(ampm_time_data),
    "\tChecking time format...\n\tThe following rows have times that are not in a recognizable format: 1",
    fixed = TRUE
  )
})

test_that("checkASRcont accepts mixed time formats (datetime and plain HH:MM:SS)", {
  mixed_time_data <- tst$contdatchk
  # Set odd rows to Excel-prefixed "1899-12-31 HH:MM:SS", leave even rows as plain "HH:MM:SS"
  odd_rows <- seq(1, nrow(mixed_time_data), by = 2)
  mixed_time_data$Time[odd_rows] <- paste0("1899-12-31 ", mixed_time_data$Time[odd_rows])

  expect_no_error(checkASRcont(mixed_time_data))

  mixed_time_data$Time[1] <- "not-a-time"
  expect_error(
    checkASRcont(mixed_time_data),
    "\tChecking time format...\n\tThe following rows have times that are not in a recognizable format: 1",
    fixed = TRUE
  )
})

test_that("checkASRcont errors on invalid column names", {
  bad_data <- tst$contdatchk
  names(bad_data)[names(bad_data) == "Site"] <- "InvalidColumn"

  expect_error(
    checkASRcont(bad_data),
    "\tChecking column names...\n\tPlease correct the column names or remove: InvalidColumn",
    fixed = TRUE
  )
})

test_that("checkASRcont errors when required columns are missing", {
  # Missing Site column
  bad_data <- tst$contdatchk[, names(tst$contdatchk) != "Site"]

  expect_error(
    checkASRcont(bad_data),
    "\tChecking Site, Date, Time are present...\n\tMissing the following columns: Site",
    fixed = TRUE
  )
})

test_that("checkASRcont errors when no parameter columns present", {
  bad_data <- tst$contdatchk[, c("Site", "Date", "Time")]

  expect_error(
    checkASRcont(bad_data),
    regexp = "\tChecking at least one parameter column is present...\n\tNo parameter columns found. Please include at least one from the Parameter column in paramsASR.",
    fixed = TRUE
  )
})

test_that("checkASRcont errors on invalid date format", {
  bad_data <- tst$contdatchk
  bad_data$Date[1] <- "invalid-date"

  expect_error(
    checkASRcont(bad_data),
    "\tChecking date format...\n\tThe following rows have dates that are not in a recognizable format: 1",
    fixed = TRUE
  )
})

test_that("checkASRcont errors on invalid time format", {
  bad_data <- tst$contdatchk
  bad_data$Time[1] <- "not-a-time"

  expect_error(
    checkASRcont(bad_data),
    "\tChecking time format...\n\tThe following rows have times that are not in a recognizable format: 1",
    fixed = TRUE
  )
})

test_that("checkASRcont errors on missing values", {
  bad_data <- tst$contdatchk
  param_name <- 'Water Temp_C'
  bad_data[[param_name]][3] <- NA

  expected_msg <- paste0(
    "\tChecking for missing values...\n\t",
    "The following columns have missing values in the following rows: ",
    "Water Temp_C (3)"
  )

  expect_error(
    checkASRcont(bad_data),
    expected_msg,
    fixed = TRUE
  )

  bad_data <- tst$contdatchk
  param_name <- 'Water Temp_C'
  bad_data[[param_name]][1] <- NA
  bad_data[[param_name]][3] <- NA

  expected_msg <- paste0(
    "\tChecking for missing values...\n\t",
    "The following columns have missing values in the following rows: ",
    "Water Temp_C (1, 3)"
  )

  expect_error(
    checkASRcont(bad_data),
    expected_msg,
    fixed = TRUE
  )

  bad_data <- tst$contdatchk
  param_name <- 'Water Temp_C'
  bad_data[[param_name]][3] <- NA
  param_name <- 'Site'
  bad_data[[param_name]][2] <- NA

  expected_msg <- paste0(
    "\tChecking for missing values...\n\t",
    "The following columns have missing values in the following rows: ",
    "Site (2); Water Temp_C (3)"
  )

  expect_error(
    checkASRcont(bad_data),
    expected_msg,
    fixed = TRUE
  )

  bad_data <- tst$contdatchk
  param_name <- 'Water Temp_C'
  bad_data[[param_name]][1] <- NA
  bad_data[[param_name]][3] <- NA
  param_name <- 'Site'
  bad_data[[param_name]][2] <- NA

  expected_msg <- paste0(
    "\tChecking for missing values...\n\t",
    "The following columns have missing values in the following rows: ",
    "Site (2); Water Temp_C (1, 3)"
  )

  expect_error(
    checkASRcont(bad_data),
    expected_msg,
    fixed = TRUE
  )
})

test_that("checkASRcont passes valid combined DateTime data", {
  expect_no_error(checkASRcont(tst$contdatchk2))

  result <- checkASRcont(tst$contdatchk2)
  expect_equal(result, tst$contdatchk2)
})

test_that("checkASRcont errors on invalid DateTime format", {
  bad_data <- tst$contdatchk2
  bad_data$DateTime[1] <- "not-a-datetime"

  expect_error(
    checkASRcont(bad_data),
    "\tChecking DateTime format...\n\tThe following rows have DateTime values that are not in a recognizable format: 1",
    fixed = TRUE
  )
})

test_that("checkASRcont errors when Site column missing (combined format)", {
  bad_data <- tst$contdatchk2[, names(tst$contdatchk2) != "Site"]

  expect_error(
    checkASRcont(bad_data),
    "\tChecking Site, DateTime are present...\n\tMissing the following columns: Site",
    fixed = TRUE
  )
})

test_that("checkASRcont errors when no parameter columns present (combined format)", {
  bad_data <- tst$contdatchk2[, c("Site", "DateTime")]

  expect_error(
    checkASRcont(bad_data),
    "\tChecking at least one parameter column is present...\n\tNo parameter columns found. Please include at least one from the Parameter column in paramsASR.",
    fixed = TRUE
  )
})

test_that("checkASRcont errors on non-numeric parameter values", {
  bad_data <- tst$contdatchk
  param_name <- 'Water Temp_C'
  bad_data[[param_name]][3] <- "text"

  expected_msg <- paste0(
    "\tChecking parameter columns for non-numeric values...\n\t",
    "The following parameter columns have non-numeric values in the following rows: ",
    "Water Temp_C (3)"
  )

  expect_error(
    checkASRcont(bad_data),
    expected_msg,
    fixed = TRUE
  )

  bad_data <- tst$contdatchk
  param_name <- 'Water Temp_C'
  bad_data[[param_name]][1] <- "text"
  bad_data[[param_name]][3] <- "text"

  expected_msg <- paste0(
    "\tChecking parameter columns for non-numeric values...\n\t",
    "The following parameter columns have non-numeric values in the following rows: ",
    "Water Temp_C (1, 3)"
  )

  expect_error(
    checkASRcont(bad_data),
    expected_msg,
    fixed = TRUE
  )

  bad_data <- tst$contdatchk
  param_name <- 'Water Temp_C'
  bad_data[[param_name]][3] <- "text"
  param_name <- 'pH_SU'
  bad_data[[param_name]][2] <- "text"

  expected_msg <- paste0(
    "\tChecking parameter columns for non-numeric values...\n\t",
    "The following parameter columns have non-numeric values in the following rows: ",
    "Water Temp_C (3); pH_SU (2)"
  )

  expect_error(
    checkASRcont(bad_data),
    expected_msg,
    fixed = TRUE
  )

  bad_data <- tst$contdatchk
  param_name <- 'Water Temp_C'
  bad_data[[param_name]][1] <- "text"
  bad_data[[param_name]][3] <- "text"
  param_name <- 'pH_SU'
  bad_data[[param_name]][2] <- "text"

  expected_msg <- paste0(
    "\tChecking parameter columns for non-numeric values...\n\t",
    "The following parameter columns have non-numeric values in the following rows: ",
    "Water Temp_C (1, 3); pH_SU (2)"
  )

  expect_error(
    checkASRcont(bad_data),
    expected_msg,
    fixed = TRUE
  )
})
