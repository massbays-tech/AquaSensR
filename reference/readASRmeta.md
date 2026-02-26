# Read continuous monitoring metadata from an external file

Read continuous monitoring metadata from an external file

## Usage

``` r
readASRmeta(metapth, runchk = TRUE)
```

## Arguments

- metapth:

  character string of path to the metadata file

- runchk:

  logical to run data checks with
  [`checkASRmeta`](https://massbays-tech.github.io/AquaSensR/reference/checkASRmeta.md)

## Value

A formatted metadata data frame that can be used for downstream analysis

## Examples

``` r
metapth <- system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR')

readASRmeta(metapth)
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
#>   <chr>  <chr>     <dbl>     <dbl>     <dbl>        <dbl>        <dbl>     <dbl>
#> 1 sud096 Water Te…    NA        -1        30         -0.5           25         2
#> 2 sud096 DO_pctsat    NA        -1       120          0            100        25
#> 3 sud096 DO_mg_l      NA         1        18          2             16         4
#> 4 sud096 Conducti…    NA        10      1500         20           1200        10
#> 5 sud096 TDS_mg_l     NA        10      1500         20           1200       100
#> 6 sud096 Salinity…    NA         2        41          3             37         5
#> 7 sud096 pH_SU        NA         3        12          4             11        10
#> # ℹ 7 more variables: SpikeSuspect <dbl>, FlatFailN <dbl>, FlatFailDelta <dbl>,
#> #   FlatSuspectN <dbl>, FlatSuspectDelta <dbl>, RoCStdev <dbl>, RoCHours <dbl>
```
