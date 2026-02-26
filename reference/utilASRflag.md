# Flag continuous monitoring data with QC criteria

Flag continuous monitoring data with QC criteria

## Usage

``` r
utilASRflag(contdat, metadat, param)
```

## Arguments

- contdat:

  data frame returned by
  [`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)

- metadat:

  data frame returned by
  [`readASRmeta`](https://massbays-tech.github.io/AquaSensR/reference/readASRmeta.md)

- param:

  character string naming the parameter column to evaluate. Must match
  one of the parameter columns present in `contdat` and one of the
  entries in the `Parameter` column of `metadat`.

## Value

A data frame with columns `Site`, `DateTime`, the selected parameter,
and four flag columns: `gross_flag`, `spike_flag`, `roc_flag`, and
`flat_flag`.

## Details

Applies four independent QC checks to the selected parameter for every
site in `contdat`, matching thresholds from `metadat` by `Site` and
`Parameter`. Each check produces its own flag (`"pass"`, `"suspect"`, or
`"fail"`) so the caller can see exactly which criteria fired. If
multiple metadata rows match a given site/parameter pair the first row
is used and a warning is issued.

**Gross range** (`gross_flag`) — Observations below `Min` or above `Max`
are flagged `"fail"`. Observations below `Tlower` or above `Tupper` (but
within the fail bounds) are flagged `"suspect"`.

**Spike** (`spike_flag`) — The absolute difference between consecutive
observations is compared to `SpikeFail` (fail) and `SpikeSuspect`
(suspect). The second observation in the jump is flagged.

**Rate of change** (`roc_flag`) — For each observation the absolute
difference from the previous observation is compared to `RoCStdev`
standard deviations of all absolute differences within a rolling
`RoCHours`-hour window centered on that observation. Observations
exceeding the threshold are flagged `"suspect"`. Requires at least 3
differences in the window; otherwise `"pass"`.

**Flatline** (`flat_flag`) — Counts consecutive observations where the
absolute step from the previous observation is within `FlatSuspectDelta`
(or `FlatFailDelta`) units. Observations whose run length reaches
`FlatSuspectN` (or `FlatFailN`) are flagged.

Data are sorted by `Site` and `DateTime` before processing.

## Examples

``` r
contpth <- system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR')
metapth <- system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR')

contdat <- readASRcont(contpth, tz = 'Etc/GMT+5', runchk = FALSE)
metadat <- readASRmeta(metapth, runchk = FALSE)

utilASRflag(contdat, metadat, param = 'Water Temp_C')
#> Error in utilASRflagupdategupdate(flag, "suspect", vals < meta$Tlower): could not find function "utilASRflagupdategupdate"
```
