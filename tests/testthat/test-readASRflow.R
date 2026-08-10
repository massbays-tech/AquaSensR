test_that("Checking readASRflow output format", {
  result <- readASRflow(tst$flowpth, runchk = T)
  expect_s3_class(result, 'tbl_df')
})

test_that("Checking row length from readASRflow", {
  result <- nrow(readASRflow(tst$flowpth, runchk = T))
  expect_equal(result, 960)
})

test_that("readASRflow output format is correct for combined DateTime file", {
  result <- readASRflow(tst$flowpth2, runchk = T)
  expect_s3_class(result, 'tbl_df')
})

test_that("readASRflow row count is correct for combined DateTime file", {
  result <- nrow(readASRflow(tst$flowpth2, runchk = T))
  expect_equal(result, 960)
})

test_that("readASRflow reads CSV with separate Date/Time columns", {
  result <- readASRflow(tst$flowpthcsv, runchk = TRUE)
  expect_s3_class(result, 'tbl_df')
  expect_equal(nrow(result), 960)
  expect_s3_class(result$DateTime, 'POSIXct')
  expect_true(is.numeric(result$Sensor_Depth_ft))
})

test_that("readASRflow reads CSV with combined DateTime column", {
  result <- readASRflow(tst$flowpthcsv2, runchk = TRUE)
  expect_s3_class(result, 'tbl_df')
  expect_equal(nrow(result), 960)
  expect_s3_class(result$DateTime, 'POSIXct')
  expect_true(is.numeric(result$Sensor_Depth_ft))
})

test_that("readASRflow reads TXT with separate Date/Time columns", {
  result <- readASRflow(tst$flowpthtxt, runchk = TRUE)
  expect_s3_class(result, 'tbl_df')
  expect_equal(nrow(result), 960)
  expect_s3_class(result$DateTime, 'POSIXct')
  expect_true(is.numeric(result$Sensor_Depth_ft))
})

test_that("readASRflow reads TXT with combined DateTime column", {
  result <- readASRflow(tst$flowpthtxt2, runchk = TRUE)
  expect_s3_class(result, 'tbl_df')
  expect_equal(nrow(result), 960)
  expect_s3_class(result$DateTime, 'POSIXct')
  expect_true(is.numeric(result$Sensor_Depth_ft))
})

test_that("readASRflow CSV output has same columns and values as xlsx", {
  xlsx <- readASRflow(tst$flowpth, runchk = FALSE)
  csv  <- readASRflow(tst$flowpthcsv, runchk = FALSE)
  expect_equal(names(csv), names(xlsx))
  expect_equal(nrow(csv), nrow(xlsx))
  expect_equal(csv$Sensor_Depth_ft, xlsx$Sensor_Depth_ft)
})

test_that("readASRflow TXT output has same columns and values as xlsx", {
  xlsx <- readASRflow(tst$flowpth, runchk = FALSE)
  txt  <- readASRflow(tst$flowpthtxt, runchk = FALSE)
  expect_equal(names(txt), names(xlsx))
  expect_equal(nrow(txt), nrow(xlsx))
  expect_equal(txt$Sensor_Depth_ft, xlsx$Sensor_Depth_ft)
})

test_that("readASRflow separate-column and combined-DateTime variants agree", {
  separate <- readASRflow(tst$flowpth, runchk = FALSE)
  combined <- readASRflow(tst$flowpth2, runchk = FALSE)
  expect_equal(separate$DateTime, combined$DateTime)
  expect_equal(separate$Sensor_Depth_ft, combined$Sensor_Depth_ft)
})
