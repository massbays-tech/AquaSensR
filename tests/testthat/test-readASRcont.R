test_that("Checking readASRcont output format", {
  result <- readASRcont(tst$contpth, tz = 'Etc/GMT+5', runchk = T)
  expect_s3_class(result, 'tbl_df')
})

test_that("Checking row length from readASRcont", {
  result <- nrow(readASRcont(tst$contpth, tz = 'Etc/GMT+5', runchk = T))
  expect_equal(result, 927)
})

test_that("readASRcont output format is correct for combined DateTime file", {
  result <- readASRcont(tst$contpth2, tz = 'Etc/GMT+5', runchk = T)
  expect_s3_class(result, 'tbl_df')
})

test_that("readASRcont row count is correct for combined DateTime file", {
  result <- nrow(readASRcont(tst$contpth2, tz = 'Etc/GMT+5', runchk = T))
  expect_equal(result, 927)
})
