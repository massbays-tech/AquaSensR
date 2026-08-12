test_that("formASRflow combines Date and Time columns into DateTime", {
  result <- formASRflow(tst$flowdatchk)

  # Check that DateTime column exists
  expect_true("DateTime" %in% names(result))

  # Check that Date and Time columns are removed
  expect_false("Date" %in% names(result))
  expect_false("Time" %in% names(result))

  # Check DateTime is POSIXct with correct timezone
  expect_s3_class(result$DateTime, "POSIXct")
  expect_equal(attr(result$DateTime, "tzone"), "Etc/GMT+5")
})

test_that("formASRflow converts non-numeric columns to numeric", {
  result <- formASRflow(tst$flowdatchk)

  # All columns except DateTime should be numeric
  numeric_cols <- setdiff(names(result), c("DateTime"))

  for (col in numeric_cols) {
    expect_true(
      is.numeric(result[[col]]),
      info = paste("Column", col, "should be numeric")
    )
  }
})

test_that("formASRflow produces same result as readASRflow", {
  result <- formASRflow(tst$flowdatchk)

  # Should have same dimensions
  expect_equal(dim(result), dim(tst$flowdat))

  # Should have same column names
  expect_equal(names(result), names(tst$flowdat))
})

test_that("formASRflow handles combined DateTime input", {
  result <- formASRflow(tst$flowdatchk2)

  # DateTime column should exist and be POSIXct with correct timezone
  expect_true("DateTime" %in% names(result))
  expect_s3_class(result$DateTime, "POSIXct")
  expect_equal(attr(result$DateTime, "tzone"), "Etc/GMT+5")

  # Date and Time columns should not be present (they were not in the input)
  expect_false("Date" %in% names(result))
  expect_false("Time" %in% names(result))
})

test_that("formASRflow combined format converts non-numeric columns to numeric", {
  result <- formASRflow(tst$flowdatchk2)

  numeric_cols <- setdiff(names(result), c("DateTime"))
  for (col in numeric_cols) {
    expect_true(
      is.numeric(result[[col]]),
      info = paste("Column", col, "should be numeric")
    )
  }
})

test_that("formASRflow combined format produces same result as readASRflow", {
  result <- formASRflow(tst$flowdatchk2)

  expect_equal(dim(result), dim(tst$flowdat2))
  expect_equal(names(result), names(tst$flowdat2))
})

test_that("formASRflow delegates to formASRcont", {
  result_flow <- formASRflow(tst$flowdatchk)
  result_cont <- formASRcont(tst$flowdatchk)

  expect_equal(result_flow, result_cont)
})
