# Check data quality objectives

Check data quality objectives

## Usage

``` r
checkASRdqo(dqodat)
```

## Arguments

- dqodat:

  input data frame fordata quality objectives

## Value

`dqodat` is returned as is if no errors are found, otherwise an
informative error message is returned prompting the user to make the
required correction to the raw data before proceeding.

## Details

This function is used internally within
[`readASRdqo`](https://massbays-tech.github.io/AquaSensR/reference/readASRdqo.md)
to run several checks on the input data to verify correct formatting
before downstream analysis.

The following checks are made:

- Column names: Should include only Parameter, Flag, GrMin, GrMax,
  Spike, FlatN, FlatDelta, RoCN, and RoCHours

- All columns present: All columns from the previous check should be
  present

- At least one parameter is present: At least one parameter in the
  `Parameter` column matches the `Parameter` column in
  [`paramsASR`](https://massbays-tech.github.io/AquaSensR/reference/paramsASR.md)

- Parameter format: All parameters listed in the `Parameter` column
  should match those in the `Parameter` column in
  [`paramsASR`](https://massbays-tech.github.io/AquaSensR/reference/paramsASR.md)

- Flag column: The `Flag` column should contain only "Fail" or "Suspect"
  entries

- Rate of Change: No entries for Fail Flag rows

- Numeric columns: All columns except `Parameter` and `Flag` should be
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

dqopth <- system.file('extdata/ExampleDQO.xlsx', package = 'AquaSensR')

dqodat <- suppressWarnings(readxl::read_excel(dqopth, na = c('NA', 'na', ''),
     guess_max = Inf))

checkASRdqo(dqodat)
#> Running checks on data quality objectives...
#>  Checking column names... OK
#>  Checking all columns present... OK
#>  Checking at least one parameter is present... OK
#>  Checking parameter format... OK
#>  Checking Flag column... OK
#>  Checking Rate of Change flags... OK
#>  Checking columns for non-numeric values... OK
#> 
#> All checks passed!
#> # A tibble: 14 × 9
#>    Parameter          Flag    GrMin GrMax Spike FlatN FlatDelta  RoCN RoCHours
#>    <chr>              <chr>   <dbl> <dbl> <dbl> <dbl>     <dbl> <dbl>    <dbl>
#>  1 Water Temp_C       Suspect  -0.5    28   1.5    60      0.01     6       25
#>  2 Water Temp_C       Fail     -1      30   2     100      0.01    NA       NA
#>  3 DO_pctsat          Suspect   0     100  10      30      0.01     6       25
#>  4 DO_pctsat          Fail     -1     120  25      60      0.01    NA       NA
#>  5 DO_mg_l            Suspect   2      16   2      30      0.01     6       25
#>  6 DO_mg_l            Fail      1      18   4      60      0.01    NA       NA
#>  7 Conductivity_uS_cm Suspect  20    1200   5      30      0.01     6       25
#>  8 Conductivity_uS_cm Fail     10    1500  10      60      0.01    NA       NA
#>  9 TDS_mg_l           Suspect  20    1200  50      30      0.01     6       25
#> 10 TDS_mg_l           Fail     10    1500 100      60      0.01    NA       NA
#> 11 Salinity_ppt       Suspect   3      37   3      30      0.01     6       25
#> 12 Salinity_ppt       Fail      2      41   5      60      0.01    NA       NA
#> 13 pH_SU              Suspect   4      11   5      30      0.01     6       25
#> 14 pH_SU              Fail      3      12  10      60      0.01    NA       NA
```
