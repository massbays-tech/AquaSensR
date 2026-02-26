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
#> # A tibble: 36 × 6
#>    `Parameter Group` Parameter uom   Label `WQX Parameter` `WQX Unit of measure`
#>    <chr>             <chr>     <chr> <chr> <chr>           <chr>                
#>  1 Air Temp          Air Temp… deg C Air … Temperature, a… deg C                
#>  2 Air Temp          Air Temp… deg F Air … Temperature, a… deg F                
#>  3 Barometric Press… Air BP_p… psi   Air … Barometric pre… psi                  
#>  4 Barometric Press… Air BP_m… mmHg  Air … Barometric pre… mmHg                 
#>  5 Chlorophyll       Chloroph… ug/l  Chlo… Chlorophyll a … ug/l                 
#>  6 Chlorophyll       Chloroph… RFU   Chlo… Chlorophyll a … RFU                  
#>  7 Chlorophyll       Pheophyt… ug/l  Pheo… Pheophytin a    ug/l                 
#>  8 Chlorophyll       Pheophyt… RFU   Pheo… Pheophytin a    RFU                  
#>  9 CO2               pCO2_ppm  ppm   pCO2… Partial Pressu… ppm                  
#> 10 Conductivity      Conducti… uS/cm Cond… Conductivity    uS/cm                
#> # ℹ 26 more rows
```
