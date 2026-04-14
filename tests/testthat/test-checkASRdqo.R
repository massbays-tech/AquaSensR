test_that("checkASRdqo passes valid data without errors", {
  expect_no_error(checkASRdqo(tst$dqodatchk))

  result <- checkASRdqo(tst$dqodatchk)
  expect_equal(result, tst$dqodatchk)
})

test_that("checkASRdqo errors on invalid column names", {
  bad_data <- tst$dqodatchk
  names(bad_data)[names(bad_data) == "GrMin"] <- "InvalidColumn"

  expect_error(
    checkASRdqo(bad_data),
    "\tChecking column names...\n\tPlease correct the column names or remove: InvalidColumn",
    fixed = TRUE
  )
})

test_that("checkASRdqo errors when required columns are missing", {
  bad_data <- tst$dqodatchk[, names(tst$dqodatchk) != "GrMin"]

  expect_error(
    checkASRdqo(bad_data),
    "\tChecking all columns present...\n\tMissing the following columns: GrMin",
    fixed = TRUE
  )
})

test_that("checkASRdqo errors when no parameters present", {
  bad_data <- tst$dqodatchk[0, ]

  expect_error(
    checkASRdqo(bad_data),
    regexp = "\tChecking at least one parameter is present...\n\tNo parameters found. Please include at least one from the Parameter column in paramsASR.",
    fixed = TRUE
  )
})

test_that("checkASRdqo errors on invalid parameter format", {
  bad_data <- tst$dqodatchk
  bad_data$Parameter[1] <- "invalid-parameter"

  expect_error(
    checkASRdqo(bad_data),
    "\tChecking parameter format...\n\tIncorrect parameter format: invalid-parameter",
    fixed = TRUE
  )
})

test_that("checkASRdqo errors on invalid Flag values", {
  bad_data <- tst$dqodatchk
  bad_data$Flag[1] <- "Invalid"

  expect_error(
    checkASRdqo(bad_data),
    '\tChecking Flag column...\n\tFlag column should contain only "Fail" or "Suspect" entries. Please correct the following: Invalid',
    fixed = TRUE
  )
})

test_that("checkASRdqo accepts RoC values in Fail rows", {
  good_data <- tst$dqodatchk
  fail_idx <- which(good_data$Flag == "Fail")[1]
  good_data$RoCStDv[fail_idx] <- 6
  good_data$RoCHours[fail_idx] <- 24

  expect_no_error(checkASRdqo(good_data))
})

test_that("checkASRdqo errors on non-numeric values", {
  bad_data <- tst$dqodatchk
  param_name <- 'GrMin'
  bad_data[[param_name]][3] <- "text"

  expected_msg <- paste0(
    "\tChecking columns for non-numeric values...\n\t",
    "The following columns have non-numeric values in the following rows: ",
    "GrMin (3)"
  )

  expect_error(
    checkASRdqo(bad_data),
    expected_msg,
    fixed = TRUE
  )

  bad_data <- tst$dqodatchk
  param_name <- 'GrMin'
  bad_data[[param_name]][1] <- "text"
  bad_data[[param_name]][3] <- "text"

  expected_msg <- paste0(
    "\tChecking columns for non-numeric values...\n\t",
    "The following columns have non-numeric values in the following rows: ",
    "GrMin (1, 3)"
  )

  expect_error(
    checkASRdqo(bad_data),
    expected_msg,
    fixed = TRUE
  )

  bad_data <- tst$dqodatchk
  bad_data[['GrMin']][3] <- "text"
  bad_data[['GrMax']][2] <- "text"

  expected_msg <- paste0(
    "\tChecking columns for non-numeric values...\n\t",
    "The following columns have non-numeric values in the following rows: ",
    "GrMin (3); GrMax (2)"
  )

  expect_error(
    checkASRdqo(bad_data),
    expected_msg,
    fixed = TRUE
  )

  bad_data <- tst$dqodatchk
  bad_data[['GrMin']][1] <- "text"
  bad_data[['GrMin']][3] <- "text"
  bad_data[['GrMax']][2] <- "text"

  expected_msg <- paste0(
    "\tChecking columns for non-numeric values...\n\t",
    "The following columns have non-numeric values in the following rows: ",
    "GrMin (1, 3); GrMax (2)"
  )

  expect_error(
    checkASRdqo(bad_data),
    expected_msg,
    fixed = TRUE
  )
})
