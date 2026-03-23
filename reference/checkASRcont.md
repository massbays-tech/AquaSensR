# Check continuous monitoring data

Check continuous monitoring data

## Usage

``` r
checkASRcont(contdat)
```

## Arguments

- contdat:

  input data frame for results

## Value

`contdat` is returned as is if no errors are found, otherwise an
informative error message is returned prompting the user to make the
required correction to the raw data before proceeding.

## Details

This function is used internally within
[`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)
to run several checks on the input data to verify correct formatting
before downstream analysis.

The input data can use either of two formats:

- **Separate columns**: `Site`, `Date`, `Time`, and at least one
  parameter column

- **Combined column**: `Site`, `DateTime`, and at least one parameter
  column

The following checks are made:

- Column names: Should include only Site, Date, Time, DateTime, and at
  least one parameter column that matches the `Parameter` column in
  [`paramsASR`](https://massbays-tech.github.io/AquaSensR/reference/paramsASR.md)

- Required columns are present: Site and either Date + Time or DateTime
  are required for downstream analysis and upload to WQX

- At least one parameter column is present: At least one parameter
  column that matches the `Parameter` column in
  [`paramsASR`](https://massbays-tech.github.io/AquaSensR/reference/paramsASR.md)
  is required for downstream analysis and upload to WQX

- Date format (separate columns only): Should be in a format recognized
  by
  [`lubridate::ymd()`](https://lubridate.tidyverse.org/reference/ymd.html)
  (e.g. `"2024-06-01"`)

- Time format (separate columns only): Should be parseable by
  [`lubridate::parse_date_time()`](https://lubridate.tidyverse.org/reference/parse_date_time.html)
  using 24-hour (`"16:30:33"`), 12-hour AM/PM (`"4:30:33 PM"`), or
  Excel-prefixed (`"1899-12-31 16:30:33"`) formats

- DateTime format (combined column only): Should be parseable by
  [`lubridate::parse_date_time()`](https://lubridate.tidyverse.org/reference/parse_date_time.html)
  using 24-hour or 12-hour AM/PM formats (e.g. `"2024-06-01 16:30:33"`
  or `"2024-06-01 4:30:33 PM"`)

- Missing values: No missing values in any columns

- Parameter columns should be numeric: All parameter columns should be
  numeric values

## Examples

``` r
contpth <- system.file('extdata/ExampleCont1.xlsx', package = 'AquaSensR')

contdat <- utilASRimportcont(contpth)

checkASRcont(contdat)
#> Running checks on continuous data...
#>  Checking column names... OK
#>  Checking Site, Date, Time are present... OK
#>  Checking at least one parameter column is present... OK
#>  Checking date format... OK
#>  Checking time format... OK
#>  Checking for missing values... OK
#>  Checking parameter columns for non-numeric values... OK
#> 
#> All checks passed!
#> # A tibble: 927 × 10
#>    Site   Date       Time    `Water Temp_C` DO_pctsat DO_mg_l Conductivity_uS_cm
#>    <chr>  <chr>      <chr>            <dbl>     <dbl>   <dbl>              <dbl>
#>  1 sud096 2024-08-14 13:56:…           24.2      76.9    6.44               410.
#>  2 sud096 2024-08-14 13:56:…           24.2      76.7    6.43               410.
#>  3 sud096 2024-08-14 13:56:…           24.2      76.6    6.42               410.
#>  4 sud096 2024-08-14 13:57:…           24.2      76.5    6.41               410.
#>  5 sud096 2024-08-14 13:57:…           24.2      76.3    6.4                409 
#>  6 sud096 2024-08-14 13:57:…           24.2      76.3    6.39               409.
#>  7 sud096 2024-08-14 13:57:…           24.2      76.2    6.39               409.
#>  8 sud096 2024-08-14 13:57:…           24.2      76.1    6.38               409.
#>  9 sud096 2024-08-14 13:57:…           24.2      76.5    6.41               404.
#> 10 sud096 2024-08-14 13:58:…           24.2      77.6    6.5                399.
#> # ℹ 917 more rows
#> # ℹ 3 more variables: TDS_mg_l <dbl>, Salinity_ppt <dbl>, pH_SU <dbl>
```
