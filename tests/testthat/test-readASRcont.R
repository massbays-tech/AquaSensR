test_that("Checking readASRcont output format", {
  result <- readASRcont(tst$contpth, runchk = T)
  expect_s3_class(result, 'tbl_df')
})

test_that("Checking row length from readASRcont", {
  result <- nrow(readASRcont(tst$contpth, runchk = T))
  expect_equal(result, 927)
})

test_that("readASRcont output format is correct for combined DateTime file", {
  result <- readASRcont(tst$contpth2, runchk = T)
  expect_s3_class(result, 'tbl_df')
})

test_that("readASRcont row count is correct for combined DateTime file", {
  result <- nrow(readASRcont(tst$contpth2, runchk = T))
  expect_equal(result, 927)
})

test_that("readASRcont reads CSV with separate Date/Time columns", {
  result <- readASRcont(tst$contpthcsv, runchk = TRUE)
  expect_s3_class(result, 'tbl_df')
  expect_equal(nrow(result), 927)
  expect_s3_class(result$DateTime, 'POSIXct')
  expect_true(is.numeric(result$Water_Temp_C))
})

test_that("readASRcont reads CSV with combined DateTime column", {
  result <- readASRcont(tst$contpthcsv2, runchk = TRUE)
  expect_s3_class(result, 'tbl_df')
  expect_equal(nrow(result), 927)
  expect_s3_class(result$DateTime, 'POSIXct')
  expect_true(is.numeric(result$Water_Temp_C))
})

test_that("readASRcont reads TXT with separate Date/Time columns", {
  result <- readASRcont(tst$contpthtxt, runchk = TRUE)
  expect_s3_class(result, 'tbl_df')
  expect_equal(nrow(result), 927)
  expect_s3_class(result$DateTime, 'POSIXct')
  expect_true(is.numeric(result$Water_Temp_C))
})

test_that("readASRcont reads TXT with combined DateTime column", {
  result <- readASRcont(tst$contpthtxt2, runchk = TRUE)
  expect_s3_class(result, 'tbl_df')
  expect_equal(nrow(result), 927)
  expect_s3_class(result$DateTime, 'POSIXct')
  expect_true(is.numeric(result$Water_Temp_C))
})

test_that("readASRcont CSV output has same columns and values as xlsx", {
  xlsx <- readASRcont(tst$contpth, runchk = FALSE)
  csv  <- readASRcont(tst$contpthcsv, runchk = FALSE)
  expect_equal(names(csv), names(xlsx))
  expect_equal(nrow(csv), nrow(xlsx))
  expect_equal(csv$Water_Temp_C, xlsx$Water_Temp_C)
})

test_that("readASRcont TXT output has same columns and values as xlsx", {
  xlsx <- readASRcont(tst$contpth, runchk = FALSE)
  txt  <- readASRcont(tst$contpthtxt, runchk = FALSE)
  expect_equal(names(txt), names(xlsx))
  expect_equal(nrow(txt), nrow(xlsx))
  expect_equal(txt$Water_Temp_C, xlsx$Water_Temp_C)
})
