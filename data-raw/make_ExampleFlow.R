library(readxl)
library(writexl)
library(dplyr)
library(lubridate)

# One-time source: a real depth-logger export supplied by the user. Not
# checked into the repo; re-run this script from the original file if the
# ExampleFlow* fixtures ever need to be regenerated.
src_pth <- file.path(
  Sys.getenv('USERPROFILE'),
  'Desktop',
  'Orpheus_ELZ-Depth_Logger_2023-06-01_2023-08-01.xlsx'
)

src <- read_excel(src_pth) |>
  arrange(DateTime)

# Trim to the same scale as ExampleCont1/2 (~927 rows) rather than the full
# ~2 months, keeping the native 15-minute cadence: 960 rows = 10 days.
n_keep <- 960L
trimmed <- src[seq_len(n_keep), ]

# Re-anchor timestamps so the window overlaps ExampleCont2's actual range
# (2024-08-14 13:56:33 to 2024-08-14 16:30:53) instead of the source file's
# native 2023 dates -- the two example datasets should share the same
# calendar period even though contdat's own window is a much narrower slice
# within it. Only the calendar labels move; the Sensor_Depth_ft values (in
# original row order) are unchanged. Built as a fresh evenly-spaced sequence
# rather than shifting the source POSIXct values directly, since readxl's
# tz attribute on the source column is not 'Etc/GMT+5' and naive arithmetic
# on it would silently reintroduce a UTC-offset error.
trimmed$DateTime <- seq(
  as.POSIXct('2024-08-10 00:00:00', tz = 'Etc/GMT+5'),
  by = '15 min',
  length.out = n_keep
)

stopifnot(
  min(trimmed$DateTime) <= as.POSIXct('2024-08-14 13:56:33', tz = 'Etc/GMT+5'),
  max(trimmed$DateTime) >= as.POSIXct('2024-08-14 16:30:53', tz = 'Etc/GMT+5')
)

# ---- ExampleFlow2: combined DateTime column (closest to the source file) --
# `flow2`/`flow1` (below) keep DateTime as POSIXct for in-memory computation
# (bounds check, csv/txt formatting). The xlsx sheets store DateTime/Date/Time
# as plain ISO text, matching ExampleCont2.xlsx's own convention (confirmed by
# reading it back with col_types = 'text': its DateTime cells are literal
# "2024-08-14 13:56:33" strings, not Excel date-typed cells) -- this sidesteps
# writexl's POSIXct-to-Excel-serial conversion, which serializes based on the
# absolute UTC instant and silently reintroduces the 'Etc/GMT+5' offset as a
# visible clock-time shift when reopened.
flow2 <- trimmed

flow2_xlsx <- flow2 |>
  mutate(DateTime = format(DateTime, '%Y-%m-%d %H:%M:%S'))
write_xlsx(flow2_xlsx, 'inst/extdata/ExampleFlow2.xlsx')

# ---- ExampleFlow1: split into separate Date + Time columns, mirroring how -
# ---- ExampleCont1 relates to ExampleCont2 ----------------------------------
flow1 <- flow2 |>
  mutate(
    # as.Date.POSIXct() defaults to tz = 'UTC' regardless of DateTime's own
    # tzone attribute -- must pass tz explicitly or the last 5 hours of each
    # local day (19:00-23:59, the Etc/GMT+5 offset) roll into the next date.
    Date = as.Date(DateTime, tz = 'Etc/GMT+5'),
    Time = DateTime,
    .before = 1
  ) |>
  select(-DateTime)

flow1_xlsx <- flow1 |>
  mutate(
    Date = format(Date, '%Y-%m-%d'),
    Time = format(Time, '%H:%M:%S')
  )
write_xlsx(flow1_xlsx, 'inst/extdata/ExampleFlow1.xlsx')

# ---- csv/txt variants, matching ExampleCont1/2's raw-Excel-export style: --
# ---- comma-delimited, UTF-8 BOM, non-zero-padded M/D/YYYY dates and -------
# ---- non-zero-padded 12-hour h:mm:ss AM/PM times ---------------------------
fmt_date <- function(x) {
  # as.Date.POSIXct() defaults to tz = 'UTC' regardless of x's own tzone
  # attribute (unlike lubridate's hour()/minute()/second() below, which are
  # tz-attribute-aware) -- must pass tz explicitly here too, for the same
  # reason as the Date/DateTime split above.
  x <- as.Date(x, tz = 'Etc/GMT+5')
  sprintf('%d/%d/%d', month(x), day(x), year(x))
}
fmt_time <- function(x) {
  h12 <- hour(x) %% 12L
  h12[h12 == 0L] <- 12L
  ampm <- ifelse(hour(x) < 12L, 'AM', 'PM')
  sprintf('%d:%02d:%02d %s', h12, minute(x), round(second(x)), ampm)
}

write_flat <- function(df, path) {
  out <- df
  if ('DateTime' %in% names(out)) {
    out$DateTime <- paste(fmt_date(out$DateTime), fmt_time(out$DateTime))
  } else {
    out$Date <- fmt_date(out$Date)
    out$Time <- fmt_time(out$Time)
  }
  con <- file(path, open = 'wb')
  writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con)
  write.table(
    out,
    con,
    sep = ',',
    row.names = FALSE,
    quote = FALSE
  )
  close(con)
}

write_flat(flow1, 'inst/extdata/ExampleFlow1.csv')
file.copy('inst/extdata/ExampleFlow1.csv', 'inst/extdata/ExampleFlow1.txt', overwrite = TRUE)
write_flat(flow2, 'inst/extdata/ExampleFlow2.csv')
file.copy('inst/extdata/ExampleFlow2.csv', 'inst/extdata/ExampleFlow2.txt', overwrite = TRUE)

cat('ExampleFlow1/2 written,', nrow(flow2), 'rows each\n')
cat('DateTime range:', format(range(flow2$DateTime)), '\n')
