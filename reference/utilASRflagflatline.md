# Apply flatline QC flag

Apply flatline QC flag

## Usage

``` r
utilASRflagflatline(flag, vals, meta)
```

## Arguments

- flag:

  character vector of current flag values (`"pass"`, `"suspect"`, or
  `"fail"`).

- vals:

  numeric vector of observed values, the same length as `flag`.

- meta:

  single-row data frame of metadata for the parameter being checked.
  Optional numeric columns `FlatSuspectN`, `FlatSuspectDelta`,
  `FlatFailN`, and `FlatFailDelta` define the run-length and tolerance
  thresholds. Either pair may be absent or `NA`, in which case that
  level of check is skipped.

## Value

Updated character flag vector.

## Details

Uses
[`utilASRflagrleflat`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflagrleflat.md)
to compute consecutive run lengths. An observation is flagged
`"suspect"` when its run length (computed with `FlatSuspectDelta`)
reaches `FlatSuspectN`, and `"fail"` when its run length (computed with
`FlatFailDelta`) reaches `FlatFailN`.

## Examples

``` r
flag <- rep("pass", 8)
vals <- c(10, 10, 10.005, 10.002, 10.001, 10.003, 12, 12)
meta <- data.frame(FlatSuspectN = 3, FlatSuspectDelta = 0.01,
                   FlatFailN = 5,    FlatFailDelta = 0.01)
utilASRflagflatline(flag, vals, meta)
#> Error in utilASRflagupdategupdate(flag, "suspect", rl >= meta$FlatSuspectN): could not find function "utilASRflagupdategupdate"
```
