# Read data quality objectives from an external file

Read data quality objectives from an external file

## Usage

``` r
readASRdqo(dqopth, runchk = TRUE)
```

## Arguments

- dqopth:

  character string of path to the data quality objectives file

- runchk:

  logical to run data checks with
  [`checkASRdqo`](https://massbays-tech.github.io/AquaSensR/reference/checkASRdqo.md)

## Value

A formatted data quality objectives data frame that can be used for
downstream analysis

## Details

The file must not be open in another program (e.g. Excel, LibreOffice)
when this function is run, otherwise an error will indicate to close the
file before proceeding.

## Examples

``` r
dqopth <- system.file('extdata/ExampleDQO.xlsx', package = 'AquaSensR')

readASRdqo(dqopth)
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
#>    Parameter          Flag    GrMin GrMax Spike FlatN FlatDelta RoCStDv RoCHours
#>    <chr>              <chr>   <dbl> <dbl> <dbl> <dbl>     <dbl>   <dbl>    <dbl>
#>  1 Water_Temp_C       Suspect  -0.5    28   1.5    60      0.01       6       25
#>  2 Water_Temp_C       Fail     -1      30   2     100      0.01      NA       NA
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
