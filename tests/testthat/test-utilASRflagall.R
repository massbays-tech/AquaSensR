# ---------------------------------------------------------------------------
# Input validation
# ---------------------------------------------------------------------------

test_that("utilASRflagall errors when contdat has no parameter columns", {
  cd <- data.frame(DateTime = Sys.time())
  expect_error(
    utilASRflagall(cd, tst$dqodat),
    "No parameter columns found in contdat"
  )
})

# ---------------------------------------------------------------------------
# Output structure
# ---------------------------------------------------------------------------

test_that("utilASRflagall returns a named list with one element per parameter", {
  result <- utilASRflagall(tst$contdat, tst$dqodat)

  params <- setdiff(names(tst$contdat), "DateTime")
  expect_type(result, "list")
  expect_named(result, params)
  for (p in params) {
    expect_s3_class(result[[p]], "data.frame")
    expect_true("DateTime" %in% names(result[[p]]))
    expect_true(p %in% names(result[[p]]))
  }
})
