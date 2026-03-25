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
  Parameter to numeric if they are not already.

## Examples

``` r
metapth <- system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR')

metadat <- suppressWarnings(readxl::read_excel(metapth, na = c('NA', 'na', ''),
     guess_max = Inf))

formASRmeta(metadat)
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
