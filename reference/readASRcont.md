# Read continuous monitoring data from an external file

Read continuous monitoring data from an external file

## Usage

``` r
readASRcont(contpth, tz = "Etc/GMT+5", runchk = TRUE)
```

## Arguments

- contpth:

  character string of path to the continuous data file

- tz:

  character string of time zone for the date and time columns, defaults
  to Etc/GMT+5 (Eastern time zone, no daylight savings). See
  [`OlsonNames()`](https://rdrr.io/r/base/timezones.html) for acceptable
  time zones.

- runchk:

  logical to run data checks with
  [`checkASRcont`](https://massbays-tech.github.io/AquaSensR/reference/checkASRcont.md)

## Value

A formatted continuous monitoring data frame that can be used for
downstream analysis

## Details

The file is imported via
[`utilASRimportcont`](https://massbays-tech.github.io/AquaSensR/reference/utilASRimportcont.md),
which forces `Date`, `Time`, and `DateTime` columns to character and
converts Excel numeric serial representations to human-readable strings
before checks are run.

Always verify the correct time zone for your data. If your data are in a
different time zone than Etc/GMT+5 (default), specify the correct time
zone in the `tz` argument.

## Examples

``` r
contpth <- system.file('extdata/ExampleCont2.xlsx', package = 'AquaSensR')

readASRcont(contpth)
#> Running checks on continuous data...
#>  Checking column names... OK
#>  Checking DateTime is present... OK
#>  Checking at least one parameter column is present... OK
#>  Checking DateTime format... OK
#>  Checking for missing values... OK
#>  Checking parameter columns for non-numeric values... OK
#> 
#> All checks passed!
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
