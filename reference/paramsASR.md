# Master list and units for acceptable parameters

Master list and units for acceptable parameters

## Usage

``` r
paramsASR
```

## Format

A `data.frame`

## Details

This information is used to verify the correct format of input data and
for formatting output data for upload to WQX. A column showing the
corresponding WQX names is also included.

## Examples

``` r
paramsASR
#> # A tibble: 31 × 5
#>    `Parameter Group`   Parameter     Label `WQX Parameter` `WQX Unit of measure`
#>    <chr>               <chr>         <chr> <chr>           <chr>                
#>  1 Air Temp            Air Temp_C    Air … Temperature, a… deg C                
#>  2 Air Temp            Air Temp_F    Air … Temperature, a… deg F                
#>  3 Water Temp          Water Temp_C  Wate… Temperature, w… deg C                
#>  4 Water Temp          Water Temp_F  Wate… Temperature, w… deg F                
#>  5 Barometric Pressure Air BP_psi    Baro… NA              NA                   
#>  6 Water Level         Water P_psi   Wate… NA              NA                   
#>  7 Water Level         Sensor Depth… Sens… Depth           ft                   
#>  8 Water Level         Gage Height_… Gage… Height, gage    ft                   
#>  9 Flow                Discharge_ft… Disc… Flow            cfs                  
#> 10 Conductivity        Conductivity… Cond… Conductivity    uS/cm                
#> # ℹ 21 more rows
```
