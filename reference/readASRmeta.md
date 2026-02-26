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
#>   Site   Parameter        Depth   Min   Max Tlower Tupper SpikeFail SpikeSuspect
#>   <chr>  <chr>            <dbl> <dbl> <dbl>  <dbl>  <dbl>     <dbl>        <dbl>
#> 1 sud096 Water Temp_C        NA     0    35   20     28.3         2          1.5
#> 2 sud096 DO_pctsat           NA     0   150   60     NA          25         10  
#> 3 sud096 DO_mg_l             NA     0    12    4     NA           4          2  
#> 4 sud096 Conductivity_uS…    NA     0  1000   NA     NA          10          5  
#> 5 sud096 TDS_mg_l            NA     0  1000   NA     NA         100         50  
#> 6 sud096 Salinity_ppt        NA     0    32   NA     NA           5          3  
#> 7 sud096 pH_SU               NA     0    14    6.5    8.3        10          5  
#> # ℹ 6 more variables: FlatFailN <dbl>, FlatFailDelta <dbl>, FlatSuspectN <dbl>,
#> #   FlatSuspectDelta <dbl>, RoCStdev <dbl>, RoCHours <dbl>
```
