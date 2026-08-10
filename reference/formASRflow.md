# Format flow or stage height data

Format flow or stage height data

## Usage

``` r
formASRflow(flowdat, tz = "Etc/GMT+5")
```

## Arguments

- flowdat:

  input data frame

- tz:

  character string of time zone for the date and time columns, defaults
  to Etc/GMT+5 (Eastern time zone, no daylight savings). See
  [`OlsonNames()`](https://rdrr.io/r/base/timezones.html) for acceptable
  time zones.

## Value

A formatted data frame of the flow or stage height data

## Details

This function is used internally within
[`readASRflow`](https://massbays-tech.github.io/AquaSensR/reference/readASRflow.md)
to format the input data for downstream analysis. The formatting
includes:

- Combine Date and Time columns (separate column format only): The
  `Time` column is parsed flexibly using
  [`lubridate::parse_date_time()`](https://lubridate.tidyverse.org/reference/parse_date_time.html)
  (accepting 24-hour, 12-hour AM/PM, and Excel-prefixed formats) and
  reformatted to `HH:MM:SS` before being united with `Date` into a
  single `DateTime` column, which is then converted to POSIXct using
  `parse_date_time()` with year-first, month-first, and day-first date
  orders.

- Convert DateTime to POSIXct (combined column format only): The
  `DateTime` column is parsed flexibly using
  [`lubridate::parse_date_time()`](https://lubridate.tidyverse.org/reference/parse_date_time.html)
  with year-first, month-first, and day-first date orders combined with
  24-hour and 12-hour AM/PM time formats, and converted to POSIXct with
  the specified time zone.

- Convert non-numeric columns to numeric: Converts the flow or stage
  height column to numeric if not already.

This is a thin wrapper around
[`formASRcont`](https://massbays-tech.github.io/AquaSensR/reference/formASRcont.md),
which has no logic specific to continuous monitoring data and applies
unmodified to the single-value-column flow/stage format.

## Examples

``` r
flowpth <- system.file('extdata/ExampleFlow1.xlsx', package = 'AquaSensR')

flowdat <- utilASRimportcont(flowpth)

formASRflow(flowdat)
#> # A tibble: 960 × 2
#>    DateTime            Sensor_Depth_ft
#>    <dttm>                        <dbl>
#>  1 2024-08-10 00:00:00            1.41
#>  2 2024-08-10 00:15:00            1.41
#>  3 2024-08-10 00:30:00            1.41
#>  4 2024-08-10 00:45:00            1.41
#>  5 2024-08-10 01:00:00            1.41
#>  6 2024-08-10 01:15:00            1.41
#>  7 2024-08-10 01:30:00            1.4 
#>  8 2024-08-10 01:45:00            1.41
#>  9 2024-08-10 02:00:00            1.4 
#> 10 2024-08-10 02:15:00            1.4 
#> # ℹ 950 more rows
```
