# Import continuous monitoring data from an Excel file

Import continuous monitoring data from an Excel file

## Usage

``` r
utilASRimportcont(contpth)
```

## Arguments

- contpth:

  character string of path to the continuous data file

## Value

A data frame with date/time columns as character strings and all other
columns type-guessed by `readxl`.

## Details

Reads an Excel workbook and returns a data frame with `Date`, `Time`,
and `DateTime` columns preserved as character strings, with Excel
numeric representations converted to human-readable text:

- **Date**: integer-like strings (Excel date serial numbers, e.g.
  `"45518"`) are converted to `yyyy-mm-dd` using Excel's origin of
  1899-12-30.

- **Time**: decimal fraction strings between 0 and 1 (Excel time
  fractions, e.g. `"0.58105"`) are converted to `HH:MM:SS`.

- **DateTime**: numeric strings with an integer part (Excel datetime
  serials, e.g. `"45518.58105"`) are converted to `yyyy-mm-dd HH:MM:SS`.

- Text values in any of these columns (e.g. `"2024-08-14"`,
  `"4:30:33 PM"`) are left unchanged.

This function is called internally by
[`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)
and can also be used to prepare data for manual use with
[`checkASRcont`](https://massbays-tech.github.io/AquaSensR/reference/checkASRcont.md)
or
[`formASRcont`](https://massbays-tech.github.io/AquaSensR/reference/formASRcont.md).

## Examples

``` r
contpth <- system.file('extdata/ExampleCont1.xlsx', package = 'AquaSensR')

utilASRimportcont(contpth)
#> # A tibble: 927 × 9
#>    Date       Time  `Water Temp_C` DO_pctsat DO_mg_l Conductivity_uS_cm TDS_mg_l
#>    <chr>      <chr>          <dbl>     <dbl>   <dbl>              <dbl>    <dbl>
#>  1 2024-08-14 13:5…           24.2      76.9    6.44               410.      266
#>  2 2024-08-14 13:5…           24.2      76.7    6.43               410.      266
#>  3 2024-08-14 13:5…           24.2      76.6    6.42               410.      266
#>  4 2024-08-14 13:5…           24.2      76.5    6.41               410.      266
#>  5 2024-08-14 13:5…           24.2      76.3    6.4                409       266
#>  6 2024-08-14 13:5…           24.2      76.3    6.39               409.      266
#>  7 2024-08-14 13:5…           24.2      76.2    6.39               409.      266
#>  8 2024-08-14 13:5…           24.2      76.1    6.38               409.      266
#>  9 2024-08-14 13:5…           24.2      76.5    6.41               404.      262
#> 10 2024-08-14 13:5…           24.2      77.6    6.5                399.      259
#> # ℹ 917 more rows
#> # ℹ 2 more variables: Salinity_ppt <dbl>, pH_SU <dbl>
```
