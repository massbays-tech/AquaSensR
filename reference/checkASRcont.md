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

`contdat` is returned as is if no errors are found. An informative error
is raised for structural problems (unrecognised column names, missing
required columns, unparseable date/time values, or non-numeric parameter
values). Missing values in parameter columns produce a warning instead
of an error.

## Details

This function is used internally within
[`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)
to run several checks on the input data to verify correct formatting
before downstream analysis.

The input data can use either of two formats:

- **Separate columns**: `Date`, `Time`, and at least one parameter
  column

- **Combined column**: `DateTime`, and at least one parameter column

The following checks are made:

- Column names: Should include only Date, Time, DateTime, and at least
  one parameter column that matches the `Parameter` column in
  [`paramsASR`](https://massbays-tech.github.io/AquaSensR/reference/paramsASR.md)

- Required columns are present: Either Date + Time or DateTime are
  required for downstream analysis and upload to WQX

- At least one parameter column is present: At least one parameter
  column that matches the `Parameter` column in
  [`paramsASR`](https://massbays-tech.github.io/AquaSensR/reference/paramsASR.md)
  is required for downstream analysis and upload to WQX

- Date format (separate columns only): Should be parseable by
  [`lubridate::parse_date_time()`](https://lubridate.tidyverse.org/reference/parse_date_time.html)
  using year-first (`"2024-06-01"`), month-first (`"06/01/2024"`), or
  day-first (`"01/06/2024"`) formats

- Time format (separate columns only): Should be parseable by
  [`lubridate::parse_date_time()`](https://lubridate.tidyverse.org/reference/parse_date_time.html)
  using 24-hour (`"16:30:33"`), 12-hour AM/PM (`"4:30:33 PM"`), or
  Excel-prefixed (`"1899-12-31 16:30:33"`) formats

- DateTime format (combined column only): Should be parseable by
  [`lubridate::parse_date_time()`](https://lubridate.tidyverse.org/reference/parse_date_time.html)
  using year-first, month-first, or day-first date order combined with
  24-hour or 12-hour AM/PM time (e.g. `"2024-06-01 16:30:33"`,
  `"06/01/2024 16:30:33"`, or `"2024-06-01 4:30:33 PM"`)

- Missing values: Missing values in parameter columns produce a warning
  rather than an error, since cleaned data files may legitimately
  contain `NA` values. Missing values in `DateTime`, `Date`, or `Time`
  columns still cause an error.

- Parameter columns should be numeric: All parameter columns should be
  numeric values

## Examples

``` r
contpth <- system.file('extdata/ExampleCont1.xlsx', package = 'AquaSensR')

contdat <- utilASRimportcont(contpth)

checkASRcont(contdat)
#> Running checks on continuous data...
#>  Checking column names... OK
#>  Checking Date, Time are present... OK
#>  Checking at least one parameter column is present... OK
#>  Checking date format... OK
#>  Checking time format... OK
#>  Checking for missing values... OK
#>  Checking parameter columns for non-numeric values... OK
#> 
#> All checks passed!
#> # A tibble: 927 × 9
#>    Date       Time    Water_Temp_C DO_pctsat DO_mg_l Conductivity_uS_cm TDS_mg_l
#>    <chr>      <chr>          <dbl>     <dbl>   <dbl>              <dbl>    <dbl>
#>  1 2024-08-14 13:56:…         24.2      76.9    6.44               410.      266
#>  2 2024-08-14 13:56:…         24.2      76.7    6.43               410.      266
#>  3 2024-08-14 13:56:…         24.2      76.6    6.42               410.      266
#>  4 2024-08-14 13:57:…         24.2      76.5    6.41               410.      266
#>  5 2024-08-14 13:57:…         24.2      76.3    6.4                409       266
#>  6 2024-08-14 13:57:…         24.2      76.3    6.39               409.      266
#>  7 2024-08-14 13:57:…         24.2      76.2    6.39               409.      266
#>  8 2024-08-14 13:57:…         24.2      76.1    6.38               409.      266
#>  9 2024-08-14 13:57:…         24.2      76.5    6.41               404.      262
#> 10 2024-08-14 13:58:…         24.2      77.6    6.5                399.      259
#> # ℹ 917 more rows
#> # ℹ 2 more variables: Salinity_ppt <dbl>, pH_SU <dbl>
```
