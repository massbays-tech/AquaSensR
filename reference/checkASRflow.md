# Check flow or stage height data

Check flow or stage height data

## Usage

``` r
checkASRflow(flowdat)
```

## Arguments

- flowdat:

  input data frame for results

## Value

`flowdat` is returned as is if no errors are found. An informative error
is raised for structural problems (unrecognised column names, missing
required columns, zero or multiple flow/stage columns, unparseable
date/time values, or non-numeric values). Missing values produce a
warning instead of an error.

## Details

This function is used internally within
[`readASRflow`](https://massbays-tech.github.io/AquaSensR/reference/readASRflow.md)
to run several checks on the input data to verify correct formatting
before downstream analysis.

The input data can use either of two formats:

- **Separate columns**: `Date`, `Time`, and exactly one flow or stage
  height column

- **Combined column**: `DateTime`, and exactly one flow or stage height
  column

Unlike
[`checkASRcont`](https://massbays-tech.github.io/AquaSensR/reference/checkASRcont.md),
which allows any number of parameter columns from the full
[`paramsASR`](https://massbays-tech.github.io/AquaSensR/reference/paramsASR.md)
list, `checkASRflow` restricts the accepted value column to entries in
[`paramsASR`](https://massbays-tech.github.io/AquaSensR/reference/paramsASR.md)
whose `Parameter Group` is `"Water Level"` or `"Flow"` (e.g.
`Sensor_Depth_ft`, `Gage_Height_ft`, `Discharge_cfs`, `Flow_cfs`), and
requires exactly one such column. If your logger reports paired stage
and discharge, split the export into two single-column files (or use
[`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)/[`checkASRcont`](https://massbays-tech.github.io/AquaSensR/reference/checkASRcont.md)
instead, which allow multiple parameter columns).

The following checks are made:

- Column names: Should include only Date, Time, DateTime, and exactly
  one flow or stage height column that matches the `Parameter` column in
  [`paramsASR`](https://massbays-tech.github.io/AquaSensR/reference/paramsASR.md)
  for the `"Water Level"` or `"Flow"` groups

- Required columns are present: Either Date + Time or DateTime are
  required for downstream analysis

- Exactly one flow or stage height column is present: Zero or more than
  one matching column is an error

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

- Missing values: Missing values in the flow or stage height column
  produce a warning rather than an error, since cleaned data files may
  legitimately contain `NA` values. Missing values in `DateTime`,
  `Date`, or `Time` columns still cause an error.

- The flow or stage height column should be numeric

## Examples

``` r
flowpth <- system.file('extdata/ExampleFlow1.xlsx', package = 'AquaSensR')

flowdat <- utilASRimportcont(flowpth)

checkASRflow(flowdat)
#> Running checks on flow/stage data...
#>  Checking column names... OK
#>  Checking Date, Time are present... OK
#>  Checking exactly one flow or stage height column is present... OK
#>  Checking date format... OK
#>  Checking time format... OK
#>  Checking for missing values... OK
#>  Checking flow or stage height column for non-numeric values... OK
#> 
#> All checks passed!
#> # A tibble: 960 × 3
#>    Date       Time     Sensor_Depth_ft
#>    <chr>      <chr>              <dbl>
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
