# AquaSensR inputs and checks

AquaSensR requires two types of input files to use the functions in the
package:

1.  **Continuous monitoring data** — time series of sensor observations,
    one column per parameter.
2.  **QC threshold metadata** — site- and parameter-specific thresholds
    used by the four QC checks (gross range, spike, rate of change, and
    flatline).

Both file types are Excel workbooks (`.xlsx`). This vignette describes
how to import and validate each input dataset using the `readASR*` and
`checkASR*` family of functions. Example files are included with the
package and are used throughout.

## Load the package

``` r
library(AquaSensR)
```

## File paths

In practice you will supply paths to your own files, for example:

``` r
contpth <- "path/to/your/ContinuousData.xlsx"
metapth <- "path/to/your/Metadata.xlsx"
```

The examples below use the files included with the package:

``` r
contpth <- system.file("extdata/ExampleCont.xlsx", package = "AquaSensR")
metapth <- system.file("extdata/ExampleMeta.xlsx", package = "AquaSensR")
```

------------------------------------------------------------------------

## Continuous monitoring data

Use
[`readASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)
to import continuous monitoring data. The function reads the Excel file,
runs a series of checks via
[`checkASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/checkASRcont.md),
and then formats the result for downstream use. The `tz` argument sets
the time zone for the combined `DateTime` column (see
[`OlsonNames()`](https://rdrr.io/r/base/timezones.html) for valid
values).

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

The workbook must contain the following columns (additional unrecognised
columns will trigger an error):

| Column                        | Description                                                                                                                                                  |
|-------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Site`                        | Site identifier                                                                                                                                              |
| `Date`                        | Observation date, parseable by [`lubridate::ymd()`](https://lubridate.tidyverse.org/reference/ymd.html) (e.g., `2024-06-01`)                                 |
| `Time`                        | Observation time as a full datetime string (e.g., `HH:MM:SS`), parseable by [`lubridate::ymd_hms()`](https://lubridate.tidyverse.org/reference/ymd_hms.html) |
| At least one parameter column | Column name must match a `Parameter` entry in `paramsASR` (e.g., `Water Temp_C`)                                                                             |

### Checks performed

[`checkASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/checkASRcont.md)
verifies the following and stops with an informative error if any check
fails:

1.  **Column names** — all columns are either `Site`, `Date`, `Time`, or
    a recognised parameter from `paramsASR`.
2.  **Required columns present** — `Site`, `Date`, and `Time` exist.
3.  **At least one parameter column** — at least one column matches an
    entry in `paramsASR$Parameter`.
4.  **Date format** — all values in `Date` parse successfully with
    [`lubridate::ymd()`](https://lubridate.tidyverse.org/reference/ymd.html).
5.  **Time format** — all values in `Time` parse successfully with
    [`lubridate::ymd_hms()`](https://lubridate.tidyverse.org/reference/ymd_hms.html).
6.  **No missing values** — no `NA` in any column.
7.  **Numeric parameter columns** — all parameter columns contain
    numeric values.

### Example: triggering an error

Adding an unrecognised column causes
[`checkASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/checkASRcont.md)
to stop immediately:

``` r
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union

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

- `Site` — site identifier (character)
- `DateTime` — combined and time-zone-aware `POSIXct` column
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

------------------------------------------------------------------------

## QC threshold metadata

Use
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

| Column             | Description                                                                            |
|--------------------|----------------------------------------------------------------------------------------|
| `Site`             | Site identifier matching those in the continuous data                                  |
| `Parameter`        | Parameter name matching `paramsASR$Parameter`                                          |
| `Depth`            | Sensor deployment depth (numeric; can be `NA`)                                         |
| `GrMinFail`        | Gross range — lower fail threshold                                                     |
| `GrMaxFail`        | Gross range — upper fail threshold                                                     |
| `GrMinSuspect`     | Gross range — lower suspect threshold                                                  |
| `GrMaxSuspect`     | Gross range — upper suspect threshold                                                  |
| `SpikeFail`        | Spike — absolute step size for a fail flag                                             |
| `SpikeSuspect`     | Spike — absolute step size for a suspect flag                                          |
| `FlatFailN`        | Flatline — consecutive identical observations for a fail flag                          |
| `FlatFailDelta`    | Flatline — maximum within-run absolute change treated as “identical” for fail          |
| `FlatSuspectN`     | Flatline — consecutive identical observations for a suspect flag                       |
| `FlatSuspectDelta` | Flatline — maximum within-run absolute change treated as “identical” for suspect       |
| `RoCN`             | Rate of change — multiplier applied to the rolling SD (flag if `\|diff\| > SD × RoCN`) |
| `RoCHours`         | Rate of change — look-back window length in hours                                      |

### Checks performed

[`checkASRmeta()`](https://massbays-tech.github.io/AquaSensR/reference/checkASRmeta.md)
verifies the following and stops with an informative error if any check
fails:

1.  **Column names** — all columns are in the required list above.
2.  **All columns present** — every required column exists.
3.  **At least one parameter** — at least one value in `Parameter`
    matches `paramsASR$Parameter`.
4.  **Parameter format** — all `Parameter` values match those in
    `paramsASR$Parameter`.
5.  **Numeric columns** — all columns except `Site` and `Parameter`
    contain only numeric or missing values.

### Example: triggering an error

Supplying an unrecognised parameter name fails the parameter format
check:

``` r
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
