# Apply gross range QC flag

Apply gross range QC flag

## Usage

``` r
utilASRflaggross(flag, vals, meta)
```

## Arguments

- flag:

  character vector of current flag values (`"pass"`, `"suspect"`, or
  `"fail"`).

- vals:

  numeric vector of observed values, the same length as `flag`.

- meta:

  single-row data frame of metadata for the parameter being checked.
  Must contain numeric columns `GrMinFail`, `GrMaxFail`, `GrMinSuspect`,
  and `GrMaxSuspect`.

## Value

Updated character flag vector.

## Details

Observations below `GrMinFail` or above `GrMaxFail` are flagged
`"fail"`. Observations below `GrMinSuspect` or above `GrMaxSuspect` (but
within the fail bounds) are flagged `"suspect"`. `NA` threshold values
are silently skipped.

## Examples

``` r
flag <- rep("pass", 5)
vals <- c(-2, 0, 15, 26, 32)
meta <- data.frame(GrMinFail = -1, GrMaxFail = 30, GrMinSuspect = 0, GrMaxSuspect = 25)
utilASRflaggross(flag, vals, meta)
#> [1] "fail"    "pass"    "pass"    "suspect" "fail"   
```
