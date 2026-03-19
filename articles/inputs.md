# AquaSensR inputs and checks

AquaSensR requires two input files to use the functions in the package:

1.  **Continuous monitoring data**: time series of sensor observations,
    one column per parameter.
2.  **QC threshold metadata**: site- and parameter-specific thresholds
    used by the four QC checks (gross range, spike, rate of change, and
    flatline).

Both file types are Excel workbooks (`.xlsx`). This vignette describes
how to import and check each input dataset. It is critical that the
input datasets follow the exact specified format. Example files with the
correct format are included with the package and are used throughout.

## Load the package

Load the package in an R session after installation:

``` r
library(AquaSensR)
```

## File paths

First, specify the location of the two files by saving their paths to R
variables. In practice you will supply paths to your own files, for
example:

``` r
contpth <- "path/to/your/ContinuousData.xlsx"
metapth <- "path/to/your/Metadata.xlsx"
```

The examples below use the files included with the package:

``` r
contpth <- system.file("extdata/ExampleCont.xlsx", package = "AquaSensR")
metapth <- system.file("extdata/ExampleMeta.xlsx", package = "AquaSensR")
```

## Continuous monitoring data

Use
[`readASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)
to import continuous monitoring data. The function reads the Excel file,
automatically runs a series of checks via
[`checkASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/checkASRcont.md),
and then formats the result for downstream use. The `tz` argument sets
the time zone for the combined `DateTime` column (see
[`OlsonNames()`](https://rdrr.io/r/base/timezones.html) for valid
values). Be careful to specify the correct time zone, particularly one
using a fixed offset (e.g., `Etc/GMT+5` for Eastern time) to avoid
issues with daylight saving time transitions. If your data are in local
time and the time zone observes DST, consider using a time zone like
`America/New_York` that will automatically adjust for daylight savings.

``` r
contdat <- readASRcont(contpth, tz = "Etc/GMT+5")
#> Running checks on continuous data...
#>  Checking column names... OK
#>  Checking Site, Date, Time are present... OK
#>  Checking at least one parameter column is present... OK
#>  Checking date format... OK
#>  Checking time format... OK
#>  Checking for missing values... OK
#>  Checking parameter columns for non-numeric values... OK
#> 
#> All checks passed!
```

### Format requirements

The continuous monitoring data workbook must contain the following
columns (additional unrecognised columns will trigger an error):

| Column                        | Description                                                                                                                                                                                                                              |
|-------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Site`                        | Site identifier                                                                                                                                                                                                                          |
| `Date`                        | Observation date, parseable by [`lubridate::ymd()`](https://lubridate.tidyverse.org/reference/ymd.html) (e.g., `2024-06-01`)                                                                                                             |
| `Time`                        | Observation time as a full datetime string (e.g., `HH:MM:SS`), parseable by [`lubridate::ymd_hms()`](https://lubridate.tidyverse.org/reference/ymd_hms.html) or [`lubridate::hms()`](https://lubridate.tidyverse.org/reference/hms.html) |
| At least one parameter column | Column name must match a `Parameter` entry in `paramsASR` (e.g., `Water Temp_C`)                                                                                                                                                         |

Currently, AquaSensR allows the following parameters. Note the inclusion
of the units in the parameter name. Make sure the parameter name matches
the units used in your data.

| Description                  | Required file name   | Units     |
|:-----------------------------|:---------------------|:----------|
| Air Temp (C)                 | Air Temp_C           | deg C     |
| Air Temp (F)                 | Air Temp_F           | deg F     |
| Air BP (psi)                 | Air BP_psi           | psi       |
| Air BP (mmHg)                | Air BP_mmHg          | mmHg      |
| Chlorophyll-a (μg/l)         | Chlorophylla_ug_l    | ug/l      |
| Chlorophyll-a (RFU)          | Chlorophylla_RFU     | RFU       |
| Pheophytin (μg/l)            | Pheophytin_ug_l      | ug/l      |
| Pheophytin (RFU)             | Pheophytin_RFU       | RFU       |
| pCO2 (ppm)                   | pCO2_ppm             | ppm       |
| Conductivity (μS/cm)         | Conductivity_uS_cm   | uS/cm     |
| Salinity (ppt)               | Salinity_ppt         | ppt       |
| Specific Conductance (μS/cm) | Sp Conductance_uS_cm | uS/cm     |
| Cyanobacteria (μg/l)         | Cyanobacteria_ug_l   | ug/l      |
| Phycocyanin (μg/l)           | Phycocyanin_ug_l     | ug/l      |
| Phycoerythrin (μg/l)         | Phycoerythrin_ug_l   | ug/l      |
| DO (mg/l)                    | DO_mg_l              | mg/l      |
| DO Adjusted (mg/l)           | DO_adj_mg_l          | mg/l      |
| DO (% Sat)                   | DO_pctsat            | %         |
| CDOM (mg/l)                  | CDOM_mg_l            | mg/l      |
| FDOM (mg/l)                  | FDOM_mg_l            | mg/l      |
| E. coli (#/100ml)            | E. coli\_#\_100ml    | \#/100ml  |
| E. coli (CFU/100ml)          | E. coli_CFU_100ml    | CFU/100ml |
| Discharge (cfs)              | Discharge_cfs        | cfs       |
| Nitrate (μg/l)               | Nitrate_ug_l         | ug/l      |
| PAR (μmol/m2/s)              | PAR_umol_m2_s        | umol/m2/s |
| pH                           | pH_SU                | None      |
| TDS (mg/l)                   | TDS_mg_l             | mg/l      |
| TSS (mg/l)                   | TSS_mg_l             | mg/l      |
| Turbidity (NTU)              | Turbidity_NTU        | NTU       |
| Turbidity (FNU)              | Turbidity_FNU        | FNU       |
| Gage Height (ft)             | Gage Height_ft       | ft        |
| Sensor Depth (ft)            | Sensor Depth_ft      | ft        |
| Water Pressure (psi)         | Water Pressure_psi   | psi       |
| Water Pressure (mmHg)        | Water Pressure_mmHg  | mmHg      |
| Water Temp (C)               | Water Temp_C         | deg C     |
| Water Temp (F)               | Water Temp_F         | deg F     |

The list above can also be viewed in R with the `paramsASR` dataset,
which is included in the package and used for the checks.

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

### Checks performed

The
[`readASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)
function imports the data and runs a series of checks using the
[`checkASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/checkASRcont.md)
function. The checks evaluate the following and stops with an
informative error if any check fails:

1.  **Column names**: all columns are either `Site`, `Date`, `Time`, or
    a recognised parameter from `paramsASR`.
2.  **Required columns present**: `Site`, `Date`, and `Time` exist.
3.  **At least one parameter column**: at least one column matches an
    entry in `paramsASR$Parameter`.
4.  **Date format**: all values in `Date` parse successfully with
    [`lubridate::ymd()`](https://lubridate.tidyverse.org/reference/ymd.html).
5.  **Time format**: all values in `Time` parse successfully with
    [`lubridate::ymd_hms()`](https://lubridate.tidyverse.org/reference/ymd_hms.html).
6.  **No missing values**: no `NA` in any column.
7.  **Numeric parameter columns**: all parameter columns contain numeric
    values.

### Example: triggering an error

Adding an unrecognised column causes
[`checkASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/checkASRcont.md)
to stop immediately:

``` r
# import the data for the example
contdat_raw <- suppressWarnings(
  readxl::read_excel(contpth, na = c("NA", "na", ""), guess_max = Inf)
) |>
  mutate(across(
    where(~ inherits(.x, "POSIXct") | inherits(.x, "Date")),
    as.character
  ))

# add a column that is not in paramsASR
contdat_raw$BadColumn <- 1

checkASRcont(contdat_raw)
#> Running checks on continuous data...
#> Error:
#> !    Checking column names...
#>  Please correct the column names or remove: BadColumn
```

### Output format

After passing all checks,
[`readASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)
returns a data frame with:

- `Site`: site identifier (character)
- `DateTime`: combined and time-zone-aware `POSIXct` column
- One numeric column per parameter present in the input file

``` r
head(contdat)
#> # A tibble: 6 × 9
#>   Site   DateTime            `Water Temp_C` DO_pctsat DO_mg_l Conductivity_uS_cm
#>   <chr>  <dttm>                       <dbl>     <dbl>   <dbl>              <dbl>
#> 1 sud096 2024-08-14 13:56:33           24.2      76.9    6.44               410.
#> 2 sud096 2024-08-14 13:56:43           24.2      76.7    6.43               410.
#> 3 sud096 2024-08-14 13:56:53           24.2      76.6    6.42               410.
#> 4 sud096 2024-08-14 13:57:03           24.2      76.5    6.41               410.
#> 5 sud096 2024-08-14 13:57:13           24.2      76.3    6.4                409 
#> 6 sud096 2024-08-14 13:57:23           24.2      76.3    6.39               409.
#> # ℹ 3 more variables: TDS_mg_l <dbl>, Salinity_ppt <dbl>, pH_SU <dbl>
```

## QC threshold metadata

The metadata file includes various information for the quality control
checks applied to each parameter (see the [quality control
vignette](https://massbays-tech.github.io/AquaSensR/articles/qcoverview.md)
for details). Use
[`readASRmeta()`](https://massbays-tech.github.io/AquaSensR/reference/readASRmeta.md)
to import the QC threshold metadata. The function reads the workbook,
runs checks via
[`checkASRmeta()`](https://massbays-tech.github.io/AquaSensR/reference/checkASRmeta.md),
and returns a formatted data frame.

``` r
metadat <- readASRmeta(metapth)
#> Running checks on continuous metadata...
#>  Checking column names... OK
#>  Checking all columns present... OK
#>  Checking at least one parameter is present... OK
#>  Checking parameter format... OK
#>  Checking columns for non-numeric values... OK
#> 
#> All checks passed!
```

### Format requirements

The workbook must contain exactly the following columns (all required;
thresholds you do not want to apply should be left blank / `NA`):

| Column             | Description                                                                           |
|--------------------|---------------------------------------------------------------------------------------|
| `Site`             | Site identifier matching those in the continuous data                                 |
| `Parameter`        | Parameter name matching `paramsASR$Parameter`                                         |
| `Depth`            | Sensor deployment depth (numeric; can be `NA`)                                        |
| `GrMinFail`        | Gross range, lower fail threshold                                                     |
| `GrMaxFail`        | Gross range, upper fail threshold                                                     |
| `GrMinSuspect`     | Gross range, lower suspect threshold                                                  |
| `GrMaxSuspect`     | Gross range, upper suspect threshold                                                  |
| `SpikeFail`        | Spike, absolute step size for a fail flag                                             |
| `SpikeSuspect`     | Spike, absolute step size for a suspect flag                                          |
| `FlatFailN`        | Flatline, consecutive identical observations for a fail flag                          |
| `FlatFailDelta`    | Flatline, maximum within-run absolute change treated as “identical” for fail          |
| `FlatSuspectN`     | Flatline, consecutive identical observations for a suspect flag                       |
| `FlatSuspectDelta` | Flatline, maximum within-run absolute change treated as “identical” for suspect       |
| `RoCN`             | Rate of change, multiplier applied to the rolling SD (flag if `\|diff\| > SD × RoCN`) |
| `RoCHours`         | Rate of change, look-back window length in hours                                      |

### Checks performed

The
[`readASRmeta()`](https://massbays-tech.github.io/AquaSensR/reference/readASRmeta.md)
function imports the metadata and runs a series of checks using the
[`checkASRmeta()`](https://massbays-tech.github.io/AquaSensR/reference/checkASRmeta.md)
function. The checks evaluate the following and stops with an
informative error if any check fails:

1.  **Column names**: all columns are in the required list above.
2.  **All columns present**: every required column exists.
3.  **At least one parameter**: at least one value in `Parameter`
    matches `paramsASR$Parameter`.
4.  **Parameter format**: all `Parameter` values match those in
    `paramsASR$Parameter`.
5.  **Numeric columns**: all columns except `Site` and `Parameter`
    contain only numeric or missing values.

### Example: triggering an error

Supplying an unrecognised parameter name fails the parameter format
check:

``` r
# import the data for the example
metadat_raw <- suppressWarnings(
  readxl::read_excel(metapth, na = c("NA", "na", ""), guess_max = Inf)
)

# introduce a typo in the Parameter column
metadat_raw$Parameter[1] <- "WaterTemp"

checkASRmeta(metadat_raw)
#> Running checks on continuous metadata...
#>  Checking column names... OK
#>  Checking all columns present... OK
#>  Checking at least one parameter is present... OK
#> Error:
#> !    Checking parameter format...
#>  Incorrect parameter format: WaterTemp
```

### Output format

After passing all checks,
[`readASRmeta()`](https://massbays-tech.github.io/AquaSensR/reference/readASRmeta.md)
returns a data frame with the columns listed in the format requirements
table above, with all threshold columns coerced to numeric.

``` r
head(metadat)
#> # A tibble: 6 × 15
#>   Site   Parameter Depth GrMinFail GrMaxFail GrMinSuspect GrMaxSuspect SpikeFail
#>   <chr>  <chr>     <dbl>     <dbl>     <dbl>        <dbl>        <dbl>     <dbl>
#> 1 sud096 Water Te…    NA        -1        30         -0.5           28         2
#> 2 sud096 DO_pctsat    NA        -1       120          0            100        25
#> 3 sud096 DO_mg_l      NA         1        18          2             16         4
#> 4 sud096 Conducti…    NA        10      1500         20           1200        10
#> 5 sud096 TDS_mg_l     NA        10      1500         20           1200       100
#> 6 sud096 Salinity…    NA         2        41          3             37         5
#> # ℹ 7 more variables: SpikeSuspect <dbl>, FlatFailN <dbl>, FlatFailDelta <dbl>,
#> #   FlatSuspectN <dbl>, FlatSuspectDelta <dbl>, RoCN <dbl>, RoCHours <dbl>
```

The remaining functions in AquaSensR can now be used after the
continuous data and metadata files are successfully imported.
