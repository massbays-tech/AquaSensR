test_that("formASRcont combines Date and Time columns into DateTime", {
  result <- formASRcont(tst$contdatchk, tz = 'Etc/GMT+5')

  # Check that DateTime column exists
  expect_true("DateTime" %in% names(result))

  # Check that Date and Time columns are removed
  expect_false("Date" %in% names(result))
  expect_false("Time" %in% names(result))

  # Check DateTime is POSIXct with correct timezone
  expect_s3_class(result$DateTime, "POSIXct")
  expect_equal(attr(result$DateTime, "tzone"), "Etc/GMT+5")
})

test_that("formASRcont converts non-numeric columns to numeric", {
  result <- formASRcont(tst$contdatchk, tz = 'Etc/GMT+5')

  # All columns except Site and DateTime should be numeric
  numeric_cols <- setdiff(names(result), c("Site", "DateTime"))

  for (col in numeric_cols) {
    expect_true(
      is.numeric(result[[col]]),
      info = paste("Column", col, "should be numeric")
    )
  }
})

test_that("formASRcont preserves Site column", {
  result <- formASRcont(tst$contdatchk, tz = 'Etc/GMT+5')

  expect_true("Site" %in% names(result))
  expect_equal(result$Site, tst$contdatchk$Site)
})

test_that("formASRcont produces same result as readASRcont", {
  result <- formASRcont(tst$contdatchk, tz = 'Etc/GMT+5')

  # Should have same dimensions
  expect_equal(dim(result), dim(tst$contdat))

  # Should have same column names
  expect_equal(names(result), names(tst$contdat))
})

test_that("formASRcont handles combined DateTime input", {
  result <- formASRcont(tst$contdatchk2, tz = 'Etc/GMT+5')

  # DateTime column should exist and be POSIXct with correct timezone
  expect_true("DateTime" %in% names(result))
  expect_s3_class(result$DateTime, "POSIXct")
  expect_equal(attr(result$DateTime, "tzone"), "Etc/GMT+5")

  # Date and Time columns should not be present (they were not in the input)
  expect_false("Date" %in% names(result))
  expect_false("Time" %in% names(result))
})

test_that("formASRcont combined format converts non-numeric columns to numeric", {
  result <- formASRcont(tst$contdatchk2, tz = 'Etc/GMT+5')

  numeric_cols <- setdiff(names(result), c("Site", "DateTime"))
  for (col in numeric_cols) {
    expect_true(
      is.numeric(result[[col]]),
      info = paste("Column", col, "should be numeric")
    )
  }
})

test_that("formASRcont combined format produces same result as readASRcont", {
  result <- formASRcont(tst$contdatchk2, tz = 'Etc/GMT+5')

  expect_equal(dim(result), dim(tst$contdat2))
  expect_equal(names(result), names(tst$contdat2))
})
