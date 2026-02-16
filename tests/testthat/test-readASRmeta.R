test_that("Checking readASRmeta output format", {
  result <- readASRmeta(tst$metapth, runchk = T)
  expect_s3_class(result, 'tbl_df')
})

test_that("Checking row length from readASRmeta", {
  result <- nrow(readASRmeta(tst$metapth, runchk = T))
  expect_equal(result, 7)
})
