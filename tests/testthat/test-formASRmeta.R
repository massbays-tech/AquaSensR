test_that("formASRmeta converts non-numeric columns to numeric", {
  result <- formASRmeta(tst$metadatchk)

  # All columns except Parameter should be numeric
  numeric_cols <- setdiff(names(result), c("Parameter"))

  for (col in numeric_cols) {
    expect_true(
      is.numeric(result[[col]]),
      info = paste("Column", col, "should be numeric")
    )
  }
})

test_that("formASRmeta produces same result as readASRmeta", {
  result <- formASRmeta(tst$metadatchk)

  # Should have same dimensions
  expect_equal(dim(result), dim(tst$metadat))

  # Should have same column names
  expect_equal(names(result), names(tst$metadat))
})
