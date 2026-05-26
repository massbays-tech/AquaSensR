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
# Mocked unit tests — exercise the function body without network access.
# local_mocked_bindings() replaces the dataRetrieval bindings for the
# duration of each test so no HTTP calls are made.
# ---------------------------------------------------------------------------

test_that("readASRusgs returns a valid 2-col data frame with correct column name for streamflow", {
  fake_raw <- data.frame(
    time  = as.POSIXct("2024-01-01", tz = "UTC") + 0:3 * 900L,
    value = c("100", "110", "105", "95"),
    stringsAsFactors = FALSE
  )
  fake_meta <- data.frame(
    monitoring_location_name = "Fake River at Fakeville",
    stringsAsFactors = FALSE
  )
  local_mocked_bindings(
    read_waterdata_continuous          = function(...) fake_raw,
    read_waterdata_monitoring_location = function(...) fake_meta,
    .package = "dataRetrieval"
  )
  result <- readASRusgs("01234567", "00060", "2024-01-01", "2024-01-02")
  expect_s3_class(result, "data.frame")
  expect_equal(ncol(result), 2L)
  expect_equal(names(result)[1L], "DateTime")
  expect_true(grepl("Streamflow", names(result)[2L]))
  expect_true(grepl("01234567", names(result)[2L]))
  expect_s3_class(result$DateTime, "POSIXct")
  expect_equal(attr(result$DateTime, "tzone"), "Etc/GMT+5")
  expect_true(is.numeric(result[[2L]]))
  expect_equal(nrow(result), 4L)
  expect_equal(attr(result, "site_name"), "Fake River at Fakeville")
})

test_that("readASRusgs uses Precipitation label for pcode 00045", {
  fake_raw <- data.frame(
    time  = as.POSIXct("2024-01-01", tz = "UTC") + 0:2 * 3600L,
    value = c("0.1", "0.0", "0.5"),
    stringsAsFactors = FALSE
  )
  fake_meta <- data.frame(monitoring_location_name = "Site A", stringsAsFactors = FALSE)
  local_mocked_bindings(
    read_waterdata_continuous          = function(...) fake_raw,
    read_waterdata_monitoring_location = function(...) fake_meta,
    .package = "dataRetrieval"
  )
  result <- readASRusgs("01234567", "00045", "2024-01-01", "2024-01-02")
  expect_true(grepl("Precipitation", names(result)[2L]))
})

test_that("readASRusgs uses Gage height label for pcode 00065", {
  fake_raw <- data.frame(
    time  = as.POSIXct("2024-01-01", tz = "UTC") + 0:2 * 900L,
    value = c("3.5", "3.6", "3.4"),
    stringsAsFactors = FALSE
  )
  fake_meta <- data.frame(monitoring_location_name = "Site B", stringsAsFactors = FALSE)
  local_mocked_bindings(
    read_waterdata_continuous          = function(...) fake_raw,
    read_waterdata_monitoring_location = function(...) fake_meta,
    .package = "dataRetrieval"
  )
  result <- readASRusgs("01234567", "00065", "2024-01-01", "2024-01-02")
  expect_true(grepl("Gage height", names(result)[2L]))
})

test_that("readASRusgs uses 'Parameter XXXXX' fallback label for unknown pcode", {
  fake_raw <- data.frame(
    time  = as.POSIXct("2024-01-01", tz = "UTC") + 0:2 * 900L,
    value = c("1.5", "2.0", "1.8"),
    stringsAsFactors = FALSE
  )
  fake_meta <- data.frame(monitoring_location_name = "Site C", stringsAsFactors = FALSE)
  local_mocked_bindings(
    read_waterdata_continuous          = function(...) fake_raw,
    read_waterdata_monitoring_location = function(...) fake_meta,
    .package = "dataRetrieval"
  )
  result <- readASRusgs("01234567", "99999", "2024-01-01", "2024-01-02")
  expect_true(grepl("Parameter 99999", names(result)[2L]))
})

test_that("readASRusgs errors when the API returns zero rows", {
  fake_raw <- data.frame(
    time  = as.POSIXct(character(0L), tz = "UTC"),
    value = character(0L),
    stringsAsFactors = FALSE
  )
  local_mocked_bindings(
    read_waterdata_continuous = function(...) fake_raw,
    .package = "dataRetrieval"
  )
  expect_error(
    readASRusgs("01234567", "00060", "2024-01-01", "2024-01-01"),
    "No data returned"
  )
})

test_that("readASRusgs falls back to site number when monitoring_location lookup errors", {
  fake_raw <- data.frame(
    time  = as.POSIXct("2024-01-01", tz = "UTC") + 0:2 * 900L,
    value = c("100", "110", "105"),
    stringsAsFactors = FALSE
  )
  local_mocked_bindings(
    read_waterdata_continuous          = function(...) fake_raw,
    read_waterdata_monitoring_location = function(...) stop("network error"),
    .package = "dataRetrieval"
  )
  result <- readASRusgs("01234567", "00060", "2024-01-01", "2024-01-02")
  expect_equal(attr(result, "site_name"), "01234567")
})

test_that("readASRusgs falls back to site number when monitoring_location_name is NA", {
  fake_raw <- data.frame(
    time  = as.POSIXct("2024-01-01", tz = "UTC") + 0:2 * 900L,
    value = c("100", "110", "105"),
    stringsAsFactors = FALSE
  )
  fake_meta <- data.frame(
    monitoring_location_name = NA_character_,
    stringsAsFactors = FALSE
  )
  local_mocked_bindings(
    read_waterdata_continuous          = function(...) fake_raw,
    read_waterdata_monitoring_location = function(...) fake_meta,
    .package = "dataRetrieval"
  )
  result <- readASRusgs("01234567", "00060", "2024-01-01", "2024-01-02")
  expect_equal(attr(result, "site_name"), "01234567")
})

test_that("readASRusgs converts DateTime to the requested tz", {
  fake_raw <- data.frame(
    time  = as.POSIXct("2024-06-01 12:00:00", tz = "UTC"),
    value = "42",
    stringsAsFactors = FALSE
  )
  fake_meta <- data.frame(monitoring_location_name = "Site D", stringsAsFactors = FALSE)
  local_mocked_bindings(
    read_waterdata_continuous          = function(...) fake_raw,
    read_waterdata_monitoring_location = function(...) fake_meta,
    .package = "dataRetrieval"
  )
  result <- readASRusgs("01234567", "00060", "2024-06-01", "2024-06-02",
                        tz = "America/New_York")
  expect_equal(attr(result$DateTime, "tzone"), "America/New_York")
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

  # DateTime should be in the default timezone (Etc/GMT+5).
  expect_equal(attr(result$DateTime, "tzone"), "Etc/GMT+5")

  # Second column name should contain site number.
  expect_true(grepl("01646500", names(result)[2L]))

  # site_name attribute should be set.
  expect_true(!is.null(attr(result, "site_name")))
})
