test_that("Checking readASRdqo output format", {
  result <- readASRdqo(tst$dqopth, runchk = T)
  expect_s3_class(result, 'tbl_df')
})

test_that("Checking row length from readASRdqo", {
  result <- nrow(readASRdqo(tst$dqopth, runchk = T))
  expect_equal(result, 14)
})
