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
