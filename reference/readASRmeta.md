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
#> # A tibble: 7 × 13
#>   Parameter GrMinFail GrMaxFail GrMinSuspect GrMaxSuspect SpikeFail SpikeSuspect
#>   <chr>         <dbl>     <dbl>        <dbl>        <dbl>     <dbl>        <dbl>
#> 1 Water Te…        -1        30         -0.5           28         2          1.5
#> 2 DO_pctsat        -1       120          0            100        25         10  
#> 3 DO_mg_l           1        18          2             16         4          2  
#> 4 Conducti…        10      1500         20           1200        10          5  
#> 5 TDS_mg_l         10      1500         20           1200       100         50  
#> 6 Salinity…         2        41          3             37         5          3  
#> 7 pH_SU             3        12          4             11        10          5  
#> # ℹ 6 more variables: FlatFailN <dbl>, FlatFailDelta <dbl>, FlatSuspectN <dbl>,
#> #   FlatSuspectDelta <dbl>, RoCN <dbl>, RoCHours <dbl>
```
