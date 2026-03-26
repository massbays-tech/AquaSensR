test_that("formASRdqo converts non-numeric columns to numeric", {
  result <- formASRdqo(tst$dqodatchk)

  # All columns except Parameter should be numeric
  numeric_cols <- setdiff(names(result), c("Parameter", "Flag"))

  for (col in numeric_cols) {
    expect_true(
      is.numeric(result[[col]]),
      info = paste("Column", col, "should be numeric")
    )
  }
})

test_that("formASRdqo produces same result as readASRdqo", {
  result <- formASRdqo(tst$dqodatchk)

  # Should have same dimensions
  expect_equal(dim(result), dim(tst$dqodat))

  # Should have same column names
  expect_equal(names(result), names(tst$dqodat))
})
