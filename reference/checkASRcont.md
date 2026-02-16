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

The following checks are made:

- Column names: Should include only Site, Date, Time, and at least one
  parameter column that matches the `Parameter` column in
  [`paramsASR`](https://massbays-tech.github.io/AquaSensR/reference/paramsASR.md)

- Site, Date, Time are present: These columns are required for
  downstream analysis and upload to WQX

- At least one parameter column is present: At least one parameter
  column that matches the `Parameter` column in
  [`paramsASR`](https://massbays-tech.github.io/AquaSensR/reference/paramsASR.md)
  is required for downstream analysis and upload to WQX

- Date format: Should be in a format that can be recognized by
  [`lubridate::ymd()`](https://lubridate.tidyverse.org/reference/ymd.html)

- Time format: Should be in a format that can be recognized by
  [`lubridate::ymd_hms()`](https://lubridate.tidyverse.org/reference/ymd_hms.html)

- Missing values: No missing values in any columns

- Parameter columns should be numeric: All parameter columns should be
  numeric values

## Examples

``` r
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union

contpth <- system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR')

contdat <- suppressWarnings(readxl::read_excel(contpth, na = c('NA', 'na', ''),
     guess_max = Inf)) |>
   dplyr::mutate(dplyr::across(
     dplyr::where(~ inherits(.x, "POSIXct") | inherits(.x, "Date")),
   as.character))

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
#>    Site   Date       Time    `Water Temp_C` DO_pctsat DO_mg_L Conductivity_uS_cm
#>    <chr>  <chr>      <chr>            <dbl>     <dbl>   <dbl>              <dbl>
#>  1 sud096 2024-08-14 1899-1…           24.2      76.9    6.44               410.
#>  2 sud096 2024-08-14 1899-1…           24.2      76.7    6.43               410.
#>  3 sud096 2024-08-14 1899-1…           24.2      76.6    6.42               410.
#>  4 sud096 2024-08-14 1899-1…           24.2      76.5    6.41               410.
#>  5 sud096 2024-08-14 1899-1…           24.2      76.3    6.4                409 
#>  6 sud096 2024-08-14 1899-1…           24.2      76.3    6.39               409.
#>  7 sud096 2024-08-14 1899-1…           24.2      76.2    6.39               409.
#>  8 sud096 2024-08-14 1899-1…           24.2      76.1    6.38               409.
#>  9 sud096 2024-08-14 1899-1…           24.2      76.5    6.41               404.
#> 10 sud096 2024-08-14 1899-1…           24.2      77.6    6.5                399.
#> # ℹ 917 more rows
#> # ℹ 3 more variables: TDS_mg_L <dbl>, Salinity_psu <dbl>, pH_SU <dbl>
```
