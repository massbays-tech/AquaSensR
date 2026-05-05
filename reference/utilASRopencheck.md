# Check if an Excel file is open and execute a read function

Check if an Excel file is open and execute a read function

## Usage

``` r
utilASRopencheck(pth, fn)
```

## Arguments

- pth:

  character string path to the Excel file

- fn:

  a zero-argument function that reads the file

## Value

The value returned by `fn()`.

## Details

First checks for lock files created by Excel (`~$filename`) and
LibreOffice (`.~lock.filename#`). If none are found, calls `fn()` and
catches the [`utils::unzip`](https://rdrr.io/r/utils/unzip.html) error
that occurs when Excel holds an OS-level lock without creating a local
lock file (e.g. on OneDrive). Both paths produce the same user-facing
message.

## Examples

``` r
contpth <- system.file('extdata/ExampleCont1.xlsx', package = 'AquaSensR')
utilASRopencheck(contpth, \() readxl::read_excel(contpth, n_max = 0))
#> # A tibble: 0 × 9
#> # ℹ 9 variables: Date <lgl>, Time <lgl>, Water_Temp_C <lgl>, DO_pctsat <lgl>,
#> #   DO_mg_l <lgl>, Conductivity_uS_cm <lgl>, TDS_mg_l <lgl>,
#> #   Salinity_ppt <lgl>, pH_SU <lgl>
```
