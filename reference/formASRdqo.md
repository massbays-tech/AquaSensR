# Format data quality objectives

Format data quality objectives

## Usage

``` r
formASRdqo(dqodat)
```

## Arguments

- dqodat:

  input data frame

## Value

A formatted data frame of the data quality objectives

## Details

This function is used internally within
[`readASRdqo`](https://massbays-tech.github.io/AquaSensR/reference/readASRdqo.md)
to format the input data for downstream analysis. The formatting
includes:

- Convert non-numeric columns to numeric: Converts all columns except
  `Parameter` and `Flag` to numeric if they are not already.

## Examples

``` r
dqopth <- system.file('extdata/ExampleDQO.xlsx', package = 'AquaSensR')

dqodat <- suppressWarnings(readxl::read_excel(dqopth, na = c('NA', 'na', ''),
     guess_max = Inf))

formASRdqo(dqodat)
#> # A tibble: 14 × 9
#>    Parameter          Flag    GrMin GrMax Spike FlatN FlatDelta RoCStDv RoCHours
#>    <chr>              <chr>   <dbl> <dbl> <dbl> <dbl>     <dbl>   <dbl>    <dbl>
#>  1 Water_Temp_C       Suspect  -0.5    28   1.5    60      0.01       6       25
#>  2 Water_Temp_C       Fail     -1      30   2     100      0.01       8       25
#>  3 DO_pctsat          Suspect   0     100  10      30      0.01       6       25
#>  4 DO_pctsat          Fail     -1     120  25      60      0.01      NA       NA
#>  5 DO_mg_l            Suspect   2      16   2      30      0.01       6       25
#>  6 DO_mg_l            Fail      1      18   4      60      0.01      NA       NA
#>  7 Conductivity_uS_cm Suspect  20    1200   5      30      0.01       6       25
#>  8 Conductivity_uS_cm Fail     10    1500  10      60      0.01      NA       NA
#>  9 TDS_mg_l           Suspect  20    1200  50      30      0.01       6       25
#> 10 TDS_mg_l           Fail     10    1500 100      60      0.01      NA       NA
#> 11 Salinity_ppt       Suspect   3      37   3      30      0.01       6       25
#> 12 Salinity_ppt       Fail      2      41   5      60      0.01      NA       NA
#> 13 pH_SU              Suspect   4      11   5      30      0.01       6       25
#> 14 pH_SU              Fail      3      12  10      60      0.01      NA       NA
```
