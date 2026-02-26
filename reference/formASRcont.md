# Format continuous data

Format continuous data

## Usage

``` r
formASRcont(contdat, tz)
```

## Arguments

- contdat:

  input data frame

- tz:

  character string of time zone for the date and time columns See
  [`OlsonNames()`](https://rdrr.io/r/base/timezones.html) for acceptable
  time zones.

## Value

A formatted data frame of the continuous data

## Details

This function is used internally within
[`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)
to format the input data for downstream analysis. The formatting
includes:

- Combine Date and Time columns: Combines into a single DateTime column,
  converts to POSIXct with the specified time zone.

- Convert non-numeric columns to numeric: Converts all columns except
  Site and DateTime to numeric if they are not already.

## Examples

``` r
contpth <- system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR')

contdat <- suppressWarnings(readxl::read_excel(contpth, na = c('NA', 'na', ''),
     guess_max = Inf)) |>
   dplyr::mutate(dplyr::across(
     dplyr::where(~ inherits(.x, "POSIXct") | inherits(.x, "Date")),
   as.character))

formASRcont(contdat, tz = 'Etc/GMT+5')
#> # A tibble: 927 × 9
#>    Site  DateTime            `Water Temp_C` DO_pctsat DO_mg_l Conductivity_uS_cm
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
#> # ℹ 3 more variables: TDS_mg_l <dbl>, Salinity_ppt <dbl>, pH_SU <dbl>
```
