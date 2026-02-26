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

- Column names: Should include only Site, Parameter, Depth, GrMinFail,
  GrMaxFail, GrMinSuspect, GrMaxSuspect, SpikeFail, SpikeSuspect,
  FlatFailN, FlatFailDelta, FlatSuspectN, FlatSuspectDelta, RoCStdev,
  and RoCHours

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
#>   Site   Parameter Depth GrMinFail GrMaxFail GrMinSuspect GrMaxSuspect SpikeFail
#>   <chr>  <chr>     <lgl>     <dbl>     <dbl>        <dbl>        <dbl>     <dbl>
#> 1 sud096 Water Te… NA           -1        30         -0.5           25         2
#> 2 sud096 DO_pctsat NA           -1       120          0            100        25
#> 3 sud096 DO_mg_l   NA            1        18          2             16         4
#> 4 sud096 Conducti… NA           10      1500         20           1200        10
#> 5 sud096 TDS_mg_l  NA           10      1500         20           1200       100
#> 6 sud096 Salinity… NA            2        41          3             37         5
#> 7 sud096 pH_SU     NA            3        12          4             11        10
#> # ℹ 7 more variables: SpikeSuspect <dbl>, FlatFailN <dbl>, FlatFailDelta <dbl>,
#> #   FlatSuspectN <dbl>, FlatSuspectDelta <dbl>, RoCStdev <dbl>, RoCHours <dbl>
```
