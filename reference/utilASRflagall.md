# Apply QC flags to all parameters in continuous monitoring data

A wrapper around
[`utilASRflag`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflag.md)
that iterates over every parameter in `contdat` the results as a named
list.

## Usage

``` r
utilASRflagall(contdat, dqodat)
```

## Arguments

- contdat:

  data frame returned by
  [`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)

- dqodat:

  data frame returned by
  [`readASRdqo`](https://massbays-tech.github.io/AquaSensR/reference/readASRdqo.md)

## Value

A named list of data frames, one per matched parameter, with names equal
to the parameter column names.

## Details

Parameters are defined as every column in `contdat` other than
`DateTime`. If a parameter has no matching entry in `dqodat$Parameter`
all four of its flags are returned as `"pass"`.

Each element of the returned list is the data frame produced by
[`utilASRflag`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflag.md)
for that parameter: columns `DateTime`, the parameter, `gross_flag`,
`spike_flag`, `roc_flag`, and `flat_flag`.

## Examples

``` r
contpth <- system.file('extdata/ExampleCont1.xlsx', package = 'AquaSensR')
dqopth <- system.file('extdata/ExampleDQO.xlsx', package = 'AquaSensR')

contdat <- readASRcont(contpth, runchk = FALSE)
dqodat <- readASRdqo(dqopth, runchk = FALSE)

utilASRflagall(contdat, dqodat)
#> $Water_Temp_C
#> # A tibble: 927 × 6
#>    DateTime            Water_Temp_C gross_flag spike_flag roc_flag flat_flag
#>    <dttm>                     <dbl> <chr>      <chr>      <chr>    <chr>    
#>  1 2024-08-14 13:56:33         24.2 pass       pass       pass     pass     
#>  2 2024-08-14 13:56:43         24.2 pass       pass       pass     pass     
#>  3 2024-08-14 13:56:53         24.2 pass       pass       pass     pass     
#>  4 2024-08-14 13:57:03         24.2 pass       pass       pass     pass     
#>  5 2024-08-14 13:57:13         24.2 pass       pass       pass     pass     
#>  6 2024-08-14 13:57:23         24.2 pass       pass       pass     pass     
#>  7 2024-08-14 13:57:33         24.2 pass       pass       pass     pass     
#>  8 2024-08-14 13:57:43         24.2 pass       pass       pass     pass     
#>  9 2024-08-14 13:57:53         24.2 pass       pass       pass     pass     
#> 10 2024-08-14 13:58:03         24.2 pass       pass       pass     pass     
#> # ℹ 917 more rows
#> 
#> $DO_pctsat
#> # A tibble: 927 × 6
#>    DateTime            DO_pctsat gross_flag spike_flag roc_flag flat_flag
#>    <dttm>                  <dbl> <chr>      <chr>      <chr>    <chr>    
#>  1 2024-08-14 13:56:33      76.9 pass       pass       pass     pass     
#>  2 2024-08-14 13:56:43      76.7 pass       pass       pass     pass     
#>  3 2024-08-14 13:56:53      76.6 pass       pass       pass     pass     
#>  4 2024-08-14 13:57:03      76.5 pass       pass       pass     pass     
#>  5 2024-08-14 13:57:13      76.3 pass       pass       pass     pass     
#>  6 2024-08-14 13:57:23      76.3 pass       pass       pass     pass     
#>  7 2024-08-14 13:57:33      76.2 pass       pass       pass     pass     
#>  8 2024-08-14 13:57:43      76.1 pass       pass       pass     pass     
#>  9 2024-08-14 13:57:53      76.5 pass       pass       pass     pass     
#> 10 2024-08-14 13:58:03      77.6 pass       pass       pass     pass     
#> # ℹ 917 more rows
#> 
#> $DO_mg_l
#> # A tibble: 927 × 6
#>    DateTime            DO_mg_l gross_flag spike_flag roc_flag flat_flag
#>    <dttm>                <dbl> <chr>      <chr>      <chr>    <chr>    
#>  1 2024-08-14 13:56:33    6.44 pass       pass       pass     pass     
#>  2 2024-08-14 13:56:43    6.43 pass       pass       pass     pass     
#>  3 2024-08-14 13:56:53    6.42 pass       pass       pass     pass     
#>  4 2024-08-14 13:57:03    6.41 pass       pass       pass     pass     
#>  5 2024-08-14 13:57:13    6.4  pass       pass       pass     pass     
#>  6 2024-08-14 13:57:23    6.39 pass       pass       pass     pass     
#>  7 2024-08-14 13:57:33    6.39 pass       pass       pass     pass     
#>  8 2024-08-14 13:57:43    6.38 pass       pass       pass     pass     
#>  9 2024-08-14 13:57:53    6.41 pass       pass       pass     pass     
#> 10 2024-08-14 13:58:03    6.5  pass       pass       pass     pass     
#> # ℹ 917 more rows
#> 
#> $Conductivity_uS_cm
#> # A tibble: 927 × 6
#>    DateTime            Conductivity_uS_cm gross_flag spike_flag roc_flag
#>    <dttm>                           <dbl> <chr>      <chr>      <chr>   
#>  1 2024-08-14 13:56:33               410. pass       pass       pass    
#>  2 2024-08-14 13:56:43               410. pass       pass       pass    
#>  3 2024-08-14 13:56:53               410. pass       pass       pass    
#>  4 2024-08-14 13:57:03               410. pass       pass       pass    
#>  5 2024-08-14 13:57:13               409  pass       pass       suspect 
#>  6 2024-08-14 13:57:23               409. pass       pass       pass    
#>  7 2024-08-14 13:57:33               409. pass       pass       pass    
#>  8 2024-08-14 13:57:43               409. pass       pass       pass    
#>  9 2024-08-14 13:57:53               404. pass       pass       suspect 
#> 10 2024-08-14 13:58:03               399. pass       suspect    pass    
#> # ℹ 917 more rows
#> # ℹ 1 more variable: flat_flag <chr>
#> 
#> $TDS_mg_l
#> # A tibble: 927 × 6
#>    DateTime            TDS_mg_l gross_flag spike_flag roc_flag flat_flag
#>    <dttm>                 <dbl> <chr>      <chr>      <chr>    <chr>    
#>  1 2024-08-14 13:56:33      266 pass       pass       pass     pass     
#>  2 2024-08-14 13:56:43      266 pass       pass       pass     pass     
#>  3 2024-08-14 13:56:53      266 pass       pass       pass     pass     
#>  4 2024-08-14 13:57:03      266 pass       pass       pass     pass     
#>  5 2024-08-14 13:57:13      266 pass       pass       pass     pass     
#>  6 2024-08-14 13:57:23      266 pass       pass       pass     pass     
#>  7 2024-08-14 13:57:33      266 pass       pass       pass     pass     
#>  8 2024-08-14 13:57:43      266 pass       pass       pass     pass     
#>  9 2024-08-14 13:57:53      262 pass       pass       suspect  pass     
#> 10 2024-08-14 13:58:03      259 pass       pass       pass     pass     
#> # ℹ 917 more rows
#> 
#> $Salinity_ppt
#> # A tibble: 927 × 6
#>    DateTime            Salinity_ppt gross_flag spike_flag roc_flag flat_flag
#>    <dttm>                     <dbl> <chr>      <chr>      <chr>    <chr>    
#>  1 2024-08-14 13:56:33         0.2  fail       pass       pass     pass     
#>  2 2024-08-14 13:56:43         0.2  fail       pass       pass     pass     
#>  3 2024-08-14 13:56:53         0.2  fail       pass       pass     pass     
#>  4 2024-08-14 13:57:03         0.2  fail       pass       pass     pass     
#>  5 2024-08-14 13:57:13         0.2  fail       pass       pass     pass     
#>  6 2024-08-14 13:57:23         0.2  fail       pass       pass     pass     
#>  7 2024-08-14 13:57:33         0.2  fail       pass       pass     pass     
#>  8 2024-08-14 13:57:43         0.2  fail       pass       pass     pass     
#>  9 2024-08-14 13:57:53         0.19 fail       pass       suspect  pass     
#> 10 2024-08-14 13:58:03         0.19 fail       pass       pass     pass     
#> # ℹ 917 more rows
#> 
#> $pH_SU
#> # A tibble: 927 × 6
#>    DateTime            pH_SU gross_flag spike_flag roc_flag flat_flag
#>    <dttm>              <dbl> <chr>      <chr>      <chr>    <chr>    
#>  1 2024-08-14 13:56:33  7.23 pass       pass       pass     pass     
#>  2 2024-08-14 13:56:43  7.2  pass       pass       pass     pass     
#>  3 2024-08-14 13:56:53  7.18 pass       pass       pass     pass     
#>  4 2024-08-14 13:57:03  7.16 pass       pass       pass     pass     
#>  5 2024-08-14 13:57:13  7.15 pass       pass       pass     pass     
#>  6 2024-08-14 13:57:23  7.15 pass       pass       pass     pass     
#>  7 2024-08-14 13:57:33  7.14 pass       pass       pass     pass     
#>  8 2024-08-14 13:57:43  7.13 pass       pass       pass     pass     
#>  9 2024-08-14 13:57:53  7.13 pass       pass       pass     pass     
#> 10 2024-08-14 13:58:03  7.13 pass       pass       pass     pass     
#> # ℹ 917 more rows
#> 
```
