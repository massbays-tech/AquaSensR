# Read continuous monitoring data from an external file

Read continuous monitoring data from an external file

## Usage

``` r
readASRcont(contpth, tz, runchk = TRUE)
```

## Arguments

- contpth:

  character string of path to the results file

- tz:

  character string of time zone for the date and time columns See
  [`OlsonNames()`](https://rdrr.io/r/base/timezones.html) for acceptable
  time zones.

- runchk:

  logical to run data checks with
  [`checkASRcont`](https://massbays-tech.github.io/AquaSensR/reference/checkASRcont.md)

## Value

A formatted continuous monitoring data frame that can be used for
downstream analysis

## Examples

``` r
contpth <- system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR')

readASRcont(contpth, tz = 'Etc/GMT+5')
#> Running checks on continuous data...
#>  Checking column names... OK
#>  Checking Site, Date, Time are present... OK
#>  Checking at least one parameter column is present... OK
#>  Checking date format... OK
#>  Checking time format... OK
#>  Checking parameter columns for non-numeric values... OK
#> 
#> All checks passed!
#> # A tibble: 927 × 9
#>    Site  DateTime            `Water Temp_C` DO_pctsat DO_mg_L Conductivity_uS_cm
#>    <chr> <dttm>                       <dbl>     <dbl>   <dbl>              <dbl>
#>  1 sud0… 2024-08-14 13:56:33           24.2      76.9    6.44               410.
#>  2 sud0… 2024-08-14 13:56:43           24.2      76.7    6.43               410.
#>  3 sud0… 2024-08-14 13:56:53           24.2      76.6    6.42               410.
#>  4 sud0… 2024-08-14 13:57:03           24.2      76.5    6.41               410.
#>  5 sud0… 2024-08-14 13:57:13           24.2      76.3    6.4                409 
#>  6 sud0… 2024-08-14 13:57:23           24.2      76.3    6.39               409.
#>  7 sud0… 2024-08-14 13:57:33           24.2      76.2    6.39               409.
#>  8 sud0… 2024-08-14 13:57:43           24.2      76.1    6.38               409.
#>  9 sud0… 2024-08-14 13:57:53           24.2      76.5    6.41               404.
#> 10 sud0… 2024-08-14 13:58:03           24.2      77.6    6.5                399.
#> # ℹ 917 more rows
#> # ℹ 3 more variables: TDS_mg_L <dbl>, Salinity_psu <dbl>, pH_SU <dbl>
```
