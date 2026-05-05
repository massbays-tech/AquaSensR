test_that("utilASRopencheck errors when Excel lock file exists", {
  tmp <- tempfile(fileext = '.xlsx')
  file.copy(tst$contpth, tmp)
  on.exit(unlink(c(tmp, lock_file)), add = TRUE)

  lock_file <- file.path(dirname(tmp), paste0('~$', basename(tmp)))
  file.create(lock_file)

  expect_error(
    utilASRopencheck(tmp, \() readxl::read_excel(tmp, n_max = 0)),
    'appears to be open in another program'
  )
})

test_that("utilASRopencheck errors when LibreOffice lock file exists", {
  tmp <- tempfile(fileext = '.xlsx')
  file.copy(tst$contpth, tmp)
  on.exit(unlink(c(tmp, lock_file)), add = TRUE)

  lock_file <- file.path(dirname(tmp), paste0('.~lock.', basename(tmp), '#'))
  file.create(lock_file)

  expect_error(
    utilASRopencheck(tmp, \() readxl::read_excel(tmp, n_max = 0)),
    'appears to be open in another program'
  )
})

test_that("utilASRopencheck errors when fn raises a zip 'cannot be opened' error", {
  tmp <- tempfile(fileext = '.xlsx')
  file.copy(tst$contpth, tmp)
  on.exit(unlink(tmp), add = TRUE)

  expect_error(
    utilASRopencheck(tmp, \() stop("zip file 'file.xlsx' cannot be opened")),
    'appears to be open in another program'
  )
})

test_that("utilASRopencheck re-throws unrelated errors from fn", {
  tmp <- tempfile(fileext = '.xlsx')
  file.copy(tst$contpth, tmp)
  on.exit(unlink(tmp), add = TRUE)

  expect_error(
    utilASRopencheck(tmp, \() stop("something else went wrong")),
    'something else went wrong'
  )
})

test_that("utilASRopencheck returns fn() result when file is not locked", {
  tmp <- tempfile(fileext = '.xlsx')
  file.copy(tst$contpth, tmp)
  on.exit(unlink(tmp), add = TRUE)

  result <- utilASRopencheck(tmp, \() readxl::read_excel(tmp, n_max = 0))
  expect_s3_class(result, 'tbl_df')
})
