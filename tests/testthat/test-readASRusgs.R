# Tests for readASRusgs().
#
# The integration test hits the live NWIS API and is skipped when offline.
# The unit tests exercise input validation without any network calls.

# ---------------------------------------------------------------------------
# Input validation — no network needed
# ---------------------------------------------------------------------------

test_that("readASRusgs errors on empty site number", {
  expect_error(
    readASRusgs("", "00060", "2024-01-01", "2024-01-02"),
    "'site' must be a numeric USGS site number"
  )
})

test_that("readASRusgs errors on non-numeric site number", {
  expect_error(
    readASRusgs("abc123", "00060", "2024-01-01", "2024-01-02"),
    "'site' must be a numeric USGS site number"
  )
})

test_that("readASRusgs errors on pcode that is not 5 digits", {
  expect_error(
    readASRusgs("01646500", "060", "2024-01-01", "2024-01-02"),
    "'pcode' must be a 5-digit USGS parameter code"
  )
})

test_that("readASRusgs errors on pcode with non-digit characters", {
  expect_error(
    readASRusgs("01646500", "0006a", "2024-01-01", "2024-01-02"),
    "'pcode' must be a 5-digit USGS parameter code"
  )
})

# ---------------------------------------------------------------------------
# Integration test — skipped offline
# ---------------------------------------------------------------------------

test_that("readASRusgs returns a valid 2-column data frame for a known site", {
  skip_if_offline()
  # read_waterdata_continuous() segfaults on Windows with curl 6.x + R 4.3.x.
  skip_on_os("windows")
  # USGS 01646500: Potomac River at Little Falls — continuous discharge record.
  result <- readASRusgs("01646500", "00060", "2023-06-01", "2023-06-01")

  expect_s3_class(result, "data.frame")
  expect_equal(ncol(result), 2L)
  expect_named(result, c("DateTime", names(result)[2L]))
  expect_s3_class(result$DateTime, "POSIXct")
  expect_true(is.numeric(result[[2L]]))
  expect_true(nrow(result) > 0L)

  # DateTime should be in UTC.
  expect_equal(attr(result$DateTime, "tzone"), "UTC")

  # Second column name should contain site number.
  expect_true(grepl("01646500", names(result)[2L]))

  # site_name attribute should be set.
  expect_true(!is.null(attr(result, "site_name")))
})
