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
#> # A tibble: 31 × 4
#>    `Parameter Group`   Label              `WQX Parameter`  `WQX Unit of measure`
#>    <chr>               <chr>              <chr>            <chr>                
#>  1 Air Temp            Air Temp_C         Temperature, air deg C                
#>  2 Air Temp            Air Temp_F         Temperature, air deg F                
#>  3 Water Temp          Water Temp_C       Temperature, wa… deg C                
#>  4 Water Temp          Water Temp_F       Temperature, wa… deg F                
#>  5 Barometric Pressure Air BP_psi         NA               NA                   
#>  6 Water Level         Water P_psi        NA               NA                   
#>  7 Water Level         Sensor Depth_ft    Depth            ft                   
#>  8 Water Level         Gage Height_ft     Height, gage     ft                   
#>  9 Flow                Discharge_ft3_s    Flow             cfs                  
#> 10 Conductivity        Conductivity_uS_cm Conductivity     uS/cm                
#> # ℹ 21 more rows
```
