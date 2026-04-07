test_that("utilASRimportcont errors when Excel lock file exists (Excel)", {
  tmp <- tempfile(fileext = '.xlsx')
  file.copy(tst$contpth, tmp)
  on.exit(unlink(c(tmp, lock_file)), add = TRUE)

  lock_file <- file.path(dirname(tmp), paste0('~$', basename(tmp)))
  file.create(lock_file)

  expect_error(
    utilASRimportcont(tmp),
    'appears to be open in another program'
  )
})

test_that("utilASRimportcont errors when LibreOffice lock file exists", {
  tmp <- tempfile(fileext = '.xlsx')
  file.copy(tst$contpth, tmp)
  on.exit(unlink(c(tmp, lock_file)), add = TRUE)

  lock_file <- file.path(dirname(tmp), paste0('.~lock.', basename(tmp), '#'))
  file.create(lock_file)

  expect_error(
    utilASRimportcont(tmp),
    'appears to be open in another program'
  )
})

test_that("utilASRimportcont succeeds when no lock file exists", {
  tmp <- tempfile(fileext = '.xlsx')
  file.copy(tst$contpth, tmp)
  on.exit(unlink(tmp), add = TRUE)

  expect_s3_class(utilASRimportcont(tmp), 'tbl_df')
})
