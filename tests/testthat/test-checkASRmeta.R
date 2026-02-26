test_that("checkASRmeta passes valid data without errors", {
  expect_no_error(checkASRmeta(tst$metadatchk))

  result <- checkASRmeta(tst$metadatchk)
  expect_equal(result, tst$metadatchk)
})

test_that("checkASRmeta errors on invalid column names", {
  bad_data <- tst$metadatchk
  names(bad_data)[names(bad_data) == "Site"] <- "InvalidColumn"

  expect_error(
    checkASRmeta(bad_data),
    "\tChecking column names...\n\tPlease correct the column names or remove: InvalidColumn",
    fixed = TRUE
  )
})

test_that("checkASRmeta errors when required columns are missing", {
  # Missing Site column
  bad_data <- tst$metadatchk[, names(tst$metadatchk) != "Site"]

  expect_error(
    checkASRmeta(bad_data),
    "\tChecking all columns present...\n\tMissing the following columns: Site",
    fixed = TRUE
  )
})

test_that("checkASRmeta errors when no parameters present", {
  bad_data <- tst$metadatchk[-c(1:7), ]

  expect_error(
    checkASRmeta(bad_data),
    regexp = "\tChecking at least one parameter is present...\n\tNo parameters found. Please include at least one from the Parameter column in paramsASR.",
    fixed = TRUE
  )
})

test_that("checkASRmeta errors on invalid parameter format", {
  bad_data <- tst$metadatchk
  bad_data$Parameter[1] <- "invalid-parameter"

  expect_error(
    checkASRmeta(bad_data),
    "\tChecking parameter format...\n\tIncorrect parameter format: invalid-parameter",
    fixed = TRUE
  )
})

test_that("checkASRmeta errors on non-numeric values", {
  bad_data <- tst$metadatchk
  param_name <- 'Depth'
  bad_data[[param_name]][3] <- "text"

  expected_msg <- paste0(
    "\tChecking columns for non-numeric values...\n\t",
    "The following columns have non-numeric values in the following rows: ",
    "Depth (3)"
  )

  expect_error(
    checkASRmeta(bad_data),
    expected_msg,
    fixed = TRUE
  )

  bad_data <- tst$metadatchk
  param_name <- 'Depth'
  bad_data[[param_name]][1] <- "text"
  bad_data[[param_name]][3] <- "text"

  expected_msg <- paste0(
    "\tChecking columns for non-numeric values...\n\t",
    "The following columns have non-numeric values in the following rows: ",
    "Depth (1, 3)"
  )

  expect_error(
    checkASRmeta(bad_data),
    expected_msg,
    fixed = TRUE
  )

  bad_data <- tst$metadatchk
  param_name <- 'Depth'
  bad_data[[param_name]][3] <- "text"
  param_name <- 'GrMaxSuspect'
  bad_data[[param_name]][2] <- "text"

  expected_msg <- paste0(
    "\tChecking columns for non-numeric values...\n\t",
    "The following columns have non-numeric values in the following rows: ",
    "Depth (3); GrMaxSuspect (2)"
  )

  expect_error(
    checkASRmeta(bad_data),
    expected_msg,
    fixed = TRUE
  )

  bad_data <- tst$metadatchk
  param_name <- 'GrMinFail'
  bad_data[[param_name]][1] <- "text"
  bad_data[[param_name]][3] <- "text"
  param_name <- 'GrMinSuspect'
  bad_data[[param_name]][2] <- "text"

  expected_msg <- paste0(
    "\tChecking columns for non-numeric values...\n\t",
    "The following columns have non-numeric values in the following rows: ",
    "GrMinFail (1, 3); GrMinSuspect (2)"
  )

  expect_error(
    checkASRmeta(bad_data),
    expected_msg,
    fixed = TRUE
  )
})
