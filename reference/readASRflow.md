# Read flow or stage height data from an external file

Read flow or stage height data from an external file

## Usage

``` r
readASRflow(flowpth, tz = "Etc/GMT+5", runchk = TRUE)
```

## Arguments

- flowpth:

  character string of path to the flow or stage height data file.
  Supported formats are Excel (`.xlsx`), CSV (`.csv`), or
  comma-delimited text (`.txt`).

- tz:

  character string of time zone for the date and time columns, defaults
  to Etc/GMT+5 (Eastern time zone, no daylight savings). See
  [`OlsonNames()`](https://rdrr.io/r/base/timezones.html) for acceptable
  time zones.

- runchk:

  logical to run data checks with
  [`checkASRflow`](https://massbays-tech.github.io/AquaSensR/reference/checkASRflow.md)

## Value

A formatted flow or stage height data frame

## Details

This is an optional input to the AquaSensR workflow for a simple
external file of flow (cfs) or stage/depth height (ft) data, e.g. from a
separate logger not otherwise included in `contdat`. The file must have
a `DateTime` column (or separate `Date` and `Time` columns) plus exactly
one flow or stage height column matching an entry in
[`paramsASR`](https://massbays-tech.github.io/AquaSensR/reference/paramsASR.md)
from the `"Water Level"` or `"Flow"` groups (e.g. `Sensor_Depth_ft`,
`Gage_Height_ft`, `Discharge_cfs`, `Flow_cfs`). See
[`checkASRflow`](https://massbays-tech.github.io/AquaSensR/reference/checkASRflow.md)
for the full validation details.

For Excel files the file is imported via
[`utilASRimportcont`](https://massbays-tech.github.io/AquaSensR/reference/utilASRimportcont.md),
which forces `Date`, `Time`, and `DateTime` columns to character and
converts Excel numeric serial representations to human-readable strings.
Excel files must not be open in another program (e.g. Excel,
LibreOffice) when this function is run.

For CSV and comma-delimited text files the file is read with `read.csv`,
with `Date`, `Time`, and `DateTime` columns forced to character and all
other columns type-guessed. No lock-file check is performed for these
formats.

Always verify the correct time zone for your data. If your data are in a
different time zone than Etc/GMT+5 (default), specify the correct time
zone in the `tz` argument.

## Examples

``` r

flowpth <- system.file('extdata/ExampleFlow2.xlsx', package = 'AquaSensR')
readASRflow(flowpth)
#> Running checks on flow/stage data...
#>  Checking column names... OK
#>  Checking DateTime is present... OK
#>  Checking exactly one flow or stage height column is present... OK
#>  Checking DateTime format... OK
#>  Checking for missing values... OK
#>  Checking flow or stage height column for non-numeric values... OK
#> 
#> All checks passed!
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

flowpth <- system.file('extdata/ExampleFlow1.csv', package = 'AquaSensR')
readASRflow(flowpth)
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

flowpth <- system.file('extdata/ExampleFlow2.txt', package = 'AquaSensR')
readASRflow(flowpth)
#> Running checks on flow/stage data...
#>  Checking column names... OK
#>  Checking DateTime is present... OK
#>  Checking exactly one flow or stage height column is present... OK
#>  Checking DateTime format... OK
#>  Checking for missing values... OK
#>  Checking flow or stage height column for non-numeric values... OK
#> 
#> All checks passed!
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
