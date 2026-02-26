# Format continuous metadata

Format continuous metadata

## Usage

``` r
formASRmeta(metadat)
```

## Arguments

- metadat:

  input data frame

## Value

A formatted data frame of the continuous data

## Details

This function is used internally within
[`readASRmeta`](https://massbays-tech.github.io/AquaSensR/reference/readASRmeta.md)
to format the input data for downstream analysis. The formatting
includes:

- Convert non-numeric columns to numeric: Converts all columns except
  Site and Parameter to numeric if they are not already.

## Examples

``` r
metapth <- system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR')

metadat <- suppressWarnings(readxl::read_excel(metapth, na = c('NA', 'na', ''),
     guess_max = Inf))

formASRmeta(metadat)
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
