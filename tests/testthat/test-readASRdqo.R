test_that("readASRdqo errors when Excel lock file exists", {
  tmp <- tempfile(fileext = '.xlsx')
  file.copy(tst$dqopth, tmp)
  on.exit(unlink(c(tmp, lock_file)), add = TRUE)

  lock_file <- file.path(dirname(tmp), paste0('~$', basename(tmp)))
  file.create(lock_file)

  expect_error(
    readASRdqo(tmp),
    'appears to be open in another program'
  )
})

test_that("readASRdqo errors when LibreOffice lock file exists", {
  tmp <- tempfile(fileext = '.xlsx')
  file.copy(tst$dqopth, tmp)
  on.exit(unlink(c(tmp, lock_file)), add = TRUE)

  lock_file <- file.path(dirname(tmp), paste0('.~lock.', basename(tmp), '#'))
  file.create(lock_file)

  expect_error(
    readASRdqo(tmp),
    'appears to be open in another program'
  )
})

test_that("readASRdqo succeeds when no lock file exists", {
  tmp <- tempfile(fileext = '.xlsx')
  file.copy(tst$dqopth, tmp)
  on.exit(unlink(tmp), add = TRUE)

  expect_s3_class(readASRdqo(tmp), 'tbl_df')
})

test_that("Checking readASRdqo output format", {
  result <- readASRdqo(tst$dqopth, runchk = T)
  expect_s3_class(result, 'tbl_df')
})

test_that("Checking row length from readASRdqo", {
  result <- nrow(readASRdqo(tst$dqopth, runchk = T))
  expect_equal(result, 14)
})
