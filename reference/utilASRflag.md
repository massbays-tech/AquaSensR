# Flag continuous monitoring data with QC criteria

Flag continuous monitoring data with QC criteria

## Usage

``` r
utilASRflag(contdat, dqodat, param)
```

## Arguments

- contdat:

  data frame returned by
  [`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)

- dqodat:

  data frame returned by
  [`readASRdqo`](https://massbays-tech.github.io/AquaSensR/reference/readASRdqo.md)

- param:

  character string naming the parameter column to evaluate. Must match
  one of the parameter columns present in `contdat`. If `param` has no
  matching entry in `dqodat$Parameter` all flags are returned as
  `"pass"`.

## Value

A data frame with columns `DateTime`, the selected parameter, and four
flag columns: `gross_flag`, `spike_flag`, `roc_flag`, and `flat_flag`.

## Details

Applies four independent QC checks to the selected parameter in
`contdat`, matching thresholds from `dqodat` by `Parameter`. Each check
produces its own flag (`"pass"`, `"suspect"`, or `"fail"`) so the user
can see exactly which criteria fired. Thresholds are read from the two
rows in `dqodat` that match the parameter — one with `Flag == "Fail"`
and one with `Flag == "Suspect"`.

**Gross range** (`gross_flag`) — Observations below `GrMin` or above
`GrMax` in the `"Fail"` row are flagged `"fail"`. Observations below
`GrMin` or above `GrMax` in the `"Suspect"` row (but within the fail
bounds) are flagged `"suspect"`.

**Spike** (`spike_flag`) — The absolute difference between consecutive
observations is compared to `Spike` in the `"Fail"` row (fail) and
`Spike` in the `"Suspect"` row (suspect). The second observation in the
jump is flagged.

**Rate of change** (`roc_flag`) — For each observation the standard
deviation of all raw values within a trailing `RoCHours`-hour window is
multiplied by `RoCN` to produce a threshold. The observation is flagged
`"suspect"` if its absolute lag-1 difference exceeds that threshold.
Requires at least 2 values in the window; otherwise `"pass"`. Note that
this check only produces `"suspect"` flags, not `"fail"` flags. `RoCN`
and `RoCHours` are read from the `"Suspect"` row only.

**Flatline** (`flat_flag`) — Counts consecutive observations where the
absolute step from the previous observation is within `FlatDelta` units.
Observations whose run length reaches `FlatN` are flagged, using the
`"Suspect"` row thresholds for suspect and the `"Fail"` row thresholds
for fail.

Data are sorted by `DateTime` before processing.

Underlying concepts and code for this function borrow heavily from those
in the [ContDataQC](https://leppott.github.io/ContDataQC) package. Any
credit for the approach should go to the [ContDataQC
authors](https://leppott.github.io/ContDataQC/authors.html#citation).

## Examples

``` r
contpth <- system.file('extdata/ExampleCont1.xlsx', package = 'AquaSensR')
dqopth <- system.file('extdata/ExampleDQO.xlsx', package = 'AquaSensR')

contdat <- readASRcont(contpth, runchk = FALSE)
dqodat <- readASRdqo(dqopth, runchk = FALSE)

utilASRflag(contdat, dqodat, param = 'Water Temp_C')
#> # A tibble: 927 × 6
#>    DateTime            `Water Temp_C` gross_flag spike_flag roc_flag flat_flag
#>    <dttm>                       <dbl> <chr>      <chr>      <chr>    <chr>    
#>  1 2024-08-14 13:56:33           24.2 pass       pass       pass     pass     
#>  2 2024-08-14 13:56:43           24.2 pass       pass       pass     pass     
#>  3 2024-08-14 13:56:53           24.2 pass       pass       pass     pass     
#>  4 2024-08-14 13:57:03           24.2 pass       pass       pass     pass     
#>  5 2024-08-14 13:57:13           24.2 pass       pass       pass     pass     
#>  6 2024-08-14 13:57:23           24.2 pass       pass       pass     pass     
#>  7 2024-08-14 13:57:33           24.2 pass       pass       pass     pass     
#>  8 2024-08-14 13:57:43           24.2 pass       pass       pass     pass     
#>  9 2024-08-14 13:57:53           24.2 pass       pass       pass     pass     
#> 10 2024-08-14 13:58:03           24.2 pass       pass       pass     pass     
#> # ℹ 917 more rows
```
