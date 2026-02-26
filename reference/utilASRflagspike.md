# Apply spike QC flag

Apply spike QC flag

## Usage

``` r
utilASRflagspike(flag, vals, meta)
```

## Arguments

- flag:

  character vector of current flag values (`"pass"`, `"suspect"`, or
  `"fail"`).

- vals:

  numeric vector of observed values, the same length as `flag`.

- meta:

  single-row data frame of metadata for the parameter being checked.
  Optional numeric columns `SpikeSuspect` and `SpikeFail` define the
  absolute-difference thresholds. Either or both columns may be absent
  or `NA`, in which case that level of check is skipped.

## Value

Updated character flag vector.

## Details

The absolute difference between each observation and the preceding one
is computed. If the difference is greater than or equal to
`SpikeSuspect` the observation is flagged `"suspect"`; greater than or
equal to `SpikeFail` flags `"fail"`. The first observation always
receives `NA` for the difference and is not flagged by this check.

## Examples

``` r
flag <- rep("pass", 5)
vals <- c(10, 10.5, 14, 10.2, 10.3)
meta <- data.frame(SpikeSuspect = 1.5, SpikeFail = 2.0)
utilASRflagspike(flag, vals, meta)
#> Error in utilASRflagupdategupdate(flag, "suspect", diffs >= meta$SpikeSuspect): could not find function "utilASRflagupdategupdate"
```
