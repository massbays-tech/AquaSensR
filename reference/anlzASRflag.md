# Plot QC flag results for a continuous monitoring parameter

Plot QC flag results for a continuous monitoring parameter

## Usage

``` r
anlzASRflag(flagdat)
```

## Arguments

- flagdat:

  data frame returned by
  [`utilASRflag`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflag.md).

## Value

An interactive `plotly` object.

## Details

Produces an interactive plotly time series showing all observations as a
line, with non-passing observations overlaid as markers. Marker
**colour** indicates which QC check fired:

- **Gross range** — red

- **Spike** — orange

- **Rate of change** — purple

- **Flatline** — blue

Marker **shape** indicates severity:

- **Suspect** — upward triangle

- **Fail** — cross (×)

An observation flagged by multiple checks appears as a marker for each
check that fired, allowing all sources of concern to be visible.

When `flagdat` contains more than one site, the plot uses vertically
stacked subplots that share a common x-axis. Legend items are shown once
and apply across all subplots.

## Examples

``` r
contpth <- system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR')
metapth <- system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR')

contdat <- readASRcont(contpth, tz = 'Etc/GMT+5', runchk = FALSE)
metadat <- readASRmeta(metapth, runchk = FALSE)

flagdat <- utilASRflag(contdat, metadat, param = 'Water Temp_C')
#> Error in utilASRflagupdategupdate(flag, "suspect", vals < meta$Tlower): could not find function "utilASRflagupdategupdate"
anlzASRflag(flagdat)
#> Error: object 'flagdat' not found
```
