# Check continuous monitoring metadata

Check continuous monitoring metadata

## Usage

``` r
checkASRmeta(metadat)
```

## Arguments

- metadat:

  input data frame for continuous metadata

## Value

`metadat` is returned as is if no errors are found, otherwise an
informative error message is returned prompting the user to make the
required correction to the raw data before proceeding.

## Details

This function is used internally within
[`readASRmeta`](https://massbays-tech.github.io/AquaSensR/reference/readASRmeta.md)
to run several checks on the input data to verify correct formatting
before downstream analysis.

The following checks are made:

- Column names: Should include only Site, Parameter, Depth, Min, Max,
  Tlower, Tupper, SpikeFail, SpikeSuspect, FlatFailN, FlatFailDelta,
  FlatSuspectN, FlatSuspectDelta, RoCStdev, and RoCHours

- All columns present: All columns from the previous check should be
  present

- At least one parameter is present: At least one parameter in the
  `Parameter` column matches the `Parameter` column in
  [`paramsASR`](https://massbays-tech.github.io/AquaSensR/reference/paramsASR.md)

- Parameter format: All parameters listed in the `Parameter` column
  should match those in the `Parameter` column in
  [`paramsASR`](https://massbays-tech.github.io/AquaSensR/reference/paramsASR.md)

- Numeric columns: All columns except `Site` and `Parameter` should be
  numeric values

## Examples

``` r
library(dplyr)

metapth <- system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR')

metadat <- suppressWarnings(readxl::read_excel(metapth, na = c('NA', 'na', ''),
     guess_max = Inf))

checkASRmeta(metadat)
#> Running checks on continuous metadata...
#>  Checking column names... OK
#>  Checking all columns present... OK
#>  Checking at least one parameter is present... OK
#>  Checking parameter format... OK
#>  Checking columns for non-numeric values... OK
#> 
#> All checks passed!
#> # A tibble: 7 × 15
#>   Site   Parameter        Depth   Min   Max Tlower Tupper SpikeFail SpikeSuspect
#>   <chr>  <chr>            <lgl> <dbl> <dbl>  <dbl>  <dbl>     <dbl>        <dbl>
#> 1 sud096 Water Temp_C     NA        0    35   20     28.3         2          1.5
#> 2 sud096 DO_pctsat        NA        0   150   60     NA          25         10  
#> 3 sud096 DO_mg_L          NA        0    12    4     NA           4          2  
#> 4 sud096 Conductivity_uS… NA        0  1000   NA     NA          10          5  
#> 5 sud096 TDS_mg_L         NA        0  1000   NA     NA         100         50  
#> 6 sud096 Salinity_psu     NA        0    32   NA     NA           5          3  
#> 7 sud096 pH_SU            NA        0    14    6.5    8.3        10          5  
#> # ℹ 6 more variables: FlatFailN <dbl>, FlatFailDelta <dbl>, FlatSuspectN <dbl>,
#> #   FlatSuspectDelta <dbl>, RoCStdev <dbl>, RoCHours <dbl>
```
