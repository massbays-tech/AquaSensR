# AquaSensR inputs and checks

AquaSensR requires two input files to use the functions in the package:

1.  **Continuous monitoring data**: time series of sensor observations
    at a site, one column per parameter.
2.  **Data Quality Objectives**: parameter-specific data quality
    objectives used by the four QC checks (gross range, spike, rate of
    change, and flatline).

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
dqopth <- "path/to/your/DQO.xlsx"
```

The examples below use the files included with the package:

``` r
contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
dqopth <- system.file("extdata/ExampleDQO.xlsx", package = "AquaSensR")
```

## Continuous monitoring data

Use
[`readASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)
to import continuous monitoring data. The function reads the Excel file,
automatically runs a series of checks via
[`checkASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/checkASRcont.md),
and then formats the result for downstream use. The `tz` argument sets
the time zone for the output `DateTime` column (see
[`OlsonNames()`](https://rdrr.io/r/base/timezones.html) for valid
values). The default value is Eastern without daylight savings
(`Etc/GMT+5`) and does not need to be set explicitly, unless you need a
different time zone. For example, if your data are in local time and the
time zone observes DST, consider using a time zone like
`America/New_York` that will automatically adjust for daylight savings.

AquaSensR accepts two input formats for the date and time information.
The examples below demonstrate both.

**Format 1** — separate `Date` and `Time` columns (`ExampleCont1.xlsx`):

``` r
contdat <- readASRcont(contpth)
#> Running checks on continuous data...
#>  Checking column names... OK
#>  Checking Date, Time are present... OK
#>  Checking at least one parameter column is present... OK
#>  Checking date format... OK
#>  Checking time format... OK
#>  Checking for missing values... OK
#>  Checking parameter columns for non-numeric values... OK
#> 
#> All checks passed!
```

**Format 2** — combined `DateTime` column (`ExampleCont2.xlsx`):

``` r
contpth2 <- system.file("extdata/ExampleCont2.xlsx", package = "AquaSensR")
contdat2 <- readASRcont(contpth2)
#> Running checks on continuous data...
#>  Checking column names... OK
#>  Checking DateTime is present... OK
#>  Checking at least one parameter column is present... OK
#>  Checking DateTime format... OK
#>  Checking for missing values... OK
#>  Checking parameter columns for non-numeric values... OK
#> 
#> All checks passed!
```

Both calls return identically structured output (see [Output
format](#output-format) below).

### Format requirements

The continuous monitoring data workbook must follow one of two accepted
schemas. Additional unrecognised columns will trigger an error.

**Format 1: separate Date and Time columns**

| Column                        | Description                                                                                                                              |
|-------------------------------|------------------------------------------------------------------------------------------------------------------------------------------|
| `Date`                        | Observation date, parseable by [`lubridate::ymd()`](https://lubridate.tidyverse.org/reference/ymd.html) (e.g., `2024-06-01`)             |
| `Time`                        | Observation time in 24-hour (e.g., `16:30:33`), 12-hour AM/PM (e.g., `4:30:33 PM`), or Excel-native format (e.g., `1899-12-31 16:30:33`) |
| At least one parameter column | Column name must match a `Parameter` entry in `paramsASR` (e.g., `Water Temp_C`)                                                         |

**Format 2: combined DateTime column**

| Column                        | Description                                                                                                             |
|-------------------------------|-------------------------------------------------------------------------------------------------------------------------|
| `DateTime`                    | Combined date and time in 24-hour (e.g., `2024-06-01 16:30:33`) or 12-hour AM/PM (e.g., `2024-06-01 4:30:33 PM`) format |
| At least one parameter column | Column name must match a `Parameter` entry in `paramsASR` (e.g., `Water Temp_C`)                                        |

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

1.  **Column names**: all columns are either `Date`, `Time`, `DateTime`,
    or a recognised parameter from `paramsASR`.
2.  **Required columns present**: either `Date` and `Time` (Format 1) or
    `DateTime` (Format 2).
3.  **At least one parameter column**: at least one column matches an
    entry in `paramsASR$Parameter`.
4.  **Date format** *(Format 1 only)*: all values in `Date` parse
    successfully with
    [`lubridate::ymd()`](https://lubridate.tidyverse.org/reference/ymd.html).
5.  **Time format** *(Format 1 only)*: all values in `Time` are
    parseable by
    [`lubridate::parse_date_time()`](https://lubridate.tidyverse.org/reference/parse_date_time.html)
    in 24-hour, 12-hour AM/PM, or Excel-native formats.
6.  **DateTime format** *(Format 2 only)*: all values in `DateTime` are
    parseable by
    [`lubridate::parse_date_time()`](https://lubridate.tidyverse.org/reference/parse_date_time.html)
    in 24-hour or 12-hour AM/PM formats.
7.  **No missing values**: no `NA` in any column.
8.  **Numeric parameter columns**: all parameter columns contain numeric
    values.

### Example: triggering an error

Adding an unrecognised column causes
[`checkASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/checkASRcont.md)
to stop immediately. The following examples demonstrate this for both
formats.

``` r
nms <- names(readxl::read_excel(contpth, n_max = 0))
col_types <- ifelse(nms %in% c("Date", "Time", "DateTime"), "text", "guess")
contdat_raw <- suppressWarnings(
  readxl::read_excel(
    contpth,
    col_types = col_types,
    na = c("NA", "na", ""),
    guess_max = Inf
  )
)

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
returns a data frame with the same structure regardless of input format:

- `DateTime`: time-zone-aware `POSIXct` column
- One numeric column per parameter present in the input file

``` r
head(contdat)
#> # A tibble: 6 × 8
#>   DateTime            `Water Temp_C` DO_pctsat DO_mg_l Conductivity_uS_cm
#>   <dttm>                       <dbl>     <dbl>   <dbl>              <dbl>
#> 1 2024-08-14 13:56:33           24.2      76.9    6.44               410.
#> 2 2024-08-14 13:56:43           24.2      76.7    6.43               410.
#> 3 2024-08-14 13:56:53           24.2      76.6    6.42               410.
#> 4 2024-08-14 13:57:03           24.2      76.5    6.41               410.
#> 5 2024-08-14 13:57:13           24.2      76.3    6.4                409 
#> 6 2024-08-14 13:57:23           24.2      76.3    6.39               409.
#> # ℹ 3 more variables: TDS_mg_l <dbl>, Salinity_ppt <dbl>, pH_SU <dbl>
```

``` r
head(contdat2)
#> # A tibble: 6 × 8
#>   DateTime            `Water Temp_C` DO_pctsat DO_mg_l Conductivity_uS_cm
#>   <dttm>                       <dbl>     <dbl>   <dbl>              <dbl>
#> 1 2024-08-14 13:56:33           24.2      76.9    6.44               410.
#> 2 2024-08-14 13:56:43           24.2      76.7    6.43               410.
#> 3 2024-08-14 13:56:53           24.2      76.6    6.42               410.
#> 4 2024-08-14 13:57:03           24.2      76.5    6.41               410.
#> 5 2024-08-14 13:57:13           24.2      76.3    6.4                409 
#> 6 2024-08-14 13:57:23           24.2      76.3    6.39               409.
#> # ℹ 3 more variables: TDS_mg_l <dbl>, Salinity_ppt <dbl>, pH_SU <dbl>
```

## Data quality objectives

The data quality objectives file includes various information for the
quality control checks applied to each parameter (see the [quality
control
vignette](https://massbays-tech.github.io/AquaSensR/articles/qcoverview.md)
for details). Use
[`readASRdqo()`](https://massbays-tech.github.io/AquaSensR/reference/readASRdqo.md)
to import the data quality objectives. The function reads the workbook,
runs checks via
[`checkASRdqo()`](https://massbays-tech.github.io/AquaSensR/reference/checkASRdqo.md),
and returns a formatted data frame.

``` r
dqodat <- readASRdqo(dqopth)
#> Running checks on data quality objectives...
#>  Checking column names... OK
#>  Checking all columns present... OK
#>  Checking at least one parameter is present... OK
#>  Checking parameter format... OK
#>  Checking Flag column... OK
#>  Checking Rate of Change flags... OK
#>  Checking columns for non-numeric values... OK
#> 
#> All checks passed!
```

### Format requirements

The workbook must contain exactly the following columns (all required;
thresholds you do not want to apply should be left blank / `NA`):

| Column      | Description                                                                           |
|-------------|---------------------------------------------------------------------------------------|
| `Parameter` | Parameter name matching `paramsASR$Parameter`                                         |
| `Flag`      | Flag level for the thresholds in the row, either “Fail” or “Suspect”                  |
| `GrMin`     | Gross range, lower threshold                                                          |
| `GrMax`     | Gross range, upper threshold                                                          |
| `Spike`     | Spike, absolute step size for a flag                                                  |
| `FlatN`     | Flatline, consecutive identical observations for a flag                               |
| `FlatDelta` | Flatline, maximum within-run absolute change treated as “identical” for a flag        |
| `RoCN`      | Rate of change, multiplier applied to the rolling SD (flag if `\|diff\| > SD × RoCN`) |
| `RoCHours`  | Rate of change, look-back window length in hours                                      |

### Checks performed

The
[`readASRdqo()`](https://massbays-tech.github.io/AquaSensR/reference/readASRdqo.md)
function imports the data quality objectives and runs a series of checks
using the
[`checkASRdqo()`](https://massbays-tech.github.io/AquaSensR/reference/checkASRdqo.md)
function. The checks evaluate the following and stops with an
informative error if any check fails:

1.  **Column names**: Should include only Parameter, Flag, GrMin, GrMax,
    Spike, FlatN, FlatDelta, RoCN, and RoCHours
2.  **All columns present**: All columns from the previous check should
    be present
3.  **At least one parameter is present**: At least one parameter in the
    `Parameter` column matches the `Parameter` column in `paramsASR`
4.  **Parameter format**: All parameters listed in the `Parameter`
    column should match those in the `Parameter` column in `paramsASR`
5.  **Flag column**: The `Flag` column should contain only “Fail” or
    “Suspect” entries
6.  **Rate of Change**: No entries for Fail Flag rows
7.  **Numeric columns**: All columns except `Parameter` and `Flag`
    should be numeric values

### Example: triggering an error

Supplying an unrecognised parameter name fails the parameter format
check:

``` r
# import the data for the example
dqodat_raw <- suppressWarnings(
  readxl::read_excel(dqopth, na = c("NA", "na", ""), guess_max = Inf)
)

# introduce a typo in the Parameter column
dqodat_raw$Parameter[1] <- "WaterTemp"

checkASRdqo(dqodat_raw)
#> Running checks on data quality objectives...
#>  Checking column names... OK
#>  Checking all columns present... OK
#>  Checking at least one parameter is present... OK
#> Error:
#> !    Checking parameter format...
#>  Incorrect parameter format: WaterTemp
```

### Output format

After passing all checks,
[`readASRdqo()`](https://massbays-tech.github.io/AquaSensR/reference/readASRdqo.md)
returns a data frame with the columns listed in the format requirements
table above, with all threshold columns coerced to numeric.

``` r
head(dqodat)
#> # A tibble: 6 × 9
#>   Parameter    Flag    GrMin GrMax Spike FlatN FlatDelta  RoCN RoCHours
#>   <chr>        <chr>   <dbl> <dbl> <dbl> <dbl>     <dbl> <dbl>    <dbl>
#> 1 Water Temp_C Suspect  -0.5    28   1.5    60      0.01     6       25
#> 2 Water Temp_C Fail     -1      30   2     100      0.01    NA       NA
#> 3 DO_pctsat    Suspect   0     100  10      30      0.01     6       25
#> 4 DO_pctsat    Fail     -1     120  25      60      0.01    NA       NA
#> 5 DO_mg_l      Suspect   2      16   2      30      0.01     6       25
#> 6 DO_mg_l      Fail      1      18   4      60      0.01    NA       NA
```

The remaining functions in AquaSensR can now be used after the
continuous data and data quality objectives files are successfully
imported.
