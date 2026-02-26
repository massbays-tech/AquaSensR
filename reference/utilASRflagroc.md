# Apply rate-of-change QC flag

Apply rate-of-change QC flag

## Usage

``` r
utilASRflagroc(flag, vals, datetimes, meta)
```

## Arguments

- flag:

  character vector of current flag values (`"pass"`, `"suspect"`, or
  `"fail"`).

- vals:

  numeric vector of observed values, the same length as `flag`.

- datetimes:

  POSIXct vector of observation timestamps, the same length as `flag`.

- meta:

  single-row data frame of metadata for the parameter being checked.
  Optional numeric columns `RoCStdev` (number of standard deviations)
  and `RoCHours` (full window width in hours) control the check. If
  either column is absent or `NA` the check is skipped.

## Value

Updated character flag vector.

## Details

For each observation the absolute difference from the previous
observation is compared to `RoCStdev` × the standard deviation of all
absolute differences within a `RoCHours`-hour window centered on that
observation. The observation is flagged `"suspect"` if its difference
exceeds this threshold. At least 3 differences must fall within the
window; otherwise the observation is skipped. This check only produces
`"suspect"` flags; it does not produce `"fail"` flags.

## Examples

``` r
flag <- rep("pass", 6)
vals <- c(10, 10.2, 10.1, 10.3, 15.0, 10.2)
datetimes <- as.POSIXct("2024-01-01") + seq(0, 5) * 900  # 15-min intervals
meta <- data.frame(RoCStdev = 3, RoCHours = 2)
utilASRflagroc(flag, vals, datetimes, meta)
#> Error in utilASRflagupdategupdate(flag, "suspect", is_roc): could not find function "utilASRflagupdategupdate"
```
