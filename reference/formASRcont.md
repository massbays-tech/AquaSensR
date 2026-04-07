# Format continuous data

Format continuous data

## Usage

``` r
formASRcont(contdat, tz = "Etc/GMT+5")
```

## Arguments

- contdat:

  input data frame

- tz:

  character string of time zone for the date and time columns, defaults
  to Etc/GMT+5 (Eastern time zone, no daylight savings). See
  [`OlsonNames()`](https://rdrr.io/r/base/timezones.html) for acceptable
  time zones.

## Value

A formatted data frame of the continuous data

## Details

This function is used internally within
[`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)
to format the input data for downstream analysis. The formatting
includes:

- Combine Date and Time columns (separate column format only): The
  `Time` column is parsed flexibly using
  [`lubridate::parse_date_time()`](https://lubridate.tidyverse.org/reference/parse_date_time.html)
  (accepting 24-hour, 12-hour AM/PM, and Excel-prefixed formats) and
  reformatted to `HH:MM:SS` before being united with `Date` into a
  single `DateTime` column, which is then converted to POSIXct with the
  specified time zone.

- Convert DateTime to POSIXct (combined column format only): The
  `DateTime` column is parsed flexibly using
  [`lubridate::parse_date_time()`](https://lubridate.tidyverse.org/reference/parse_date_time.html)
  (accepting 24-hour and 12-hour AM/PM formats) and converted to POSIXct
  with the specified time zone.

- Convert non-numeric columns to numeric: Converts all columns except
  DateTime to numeric if they are not already.

## Examples

``` r
contpth <- system.file('extdata/ExampleCont1.xlsx', package = 'AquaSensR')

contdat <- utilASRimportcont(contpth)

formASRcont(contdat)
#> # A tibble: 927 × 8
#>    DateTime            `Water Temp_C` DO_pctsat DO_mg_l Conductivity_uS_cm
#>    <dttm>                       <dbl>     <dbl>   <dbl>              <dbl>
#>  1 2024-08-14 13:56:33           24.2      76.9    6.44               410.
#>  2 2024-08-14 13:56:43           24.2      76.7    6.43               410.
#>  3 2024-08-14 13:56:53           24.2      76.6    6.42               410.
#>  4 2024-08-14 13:57:03           24.2      76.5    6.41               410.
#>  5 2024-08-14 13:57:13           24.2      76.3    6.4                409 
#>  6 2024-08-14 13:57:23           24.2      76.3    6.39               409.
#>  7 2024-08-14 13:57:33           24.2      76.2    6.39               409.
#>  8 2024-08-14 13:57:43           24.2      76.1    6.38               409.
#>  9 2024-08-14 13:57:53           24.2      76.5    6.41               404.
#> 10 2024-08-14 13:58:03           24.2      77.6    6.5                399.
#> # ℹ 917 more rows
#> # ℹ 3 more variables: TDS_mg_l <dbl>, Salinity_ppt <dbl>, pH_SU <dbl>
```
