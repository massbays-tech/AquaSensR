# Apply gross range QC flag

Apply gross range QC flag

## Usage

``` r
utilASRflaggross(flag, vals, dqo)
```

## Arguments

- flag:

  character vector of current flag values (`"pass"`, `"suspect"`, or
  `"fail"`).

- vals:

  numeric vector of observed values, the same length as `flag`.

- dqo:

  two-row data frame from data quality objectives for the parameter
  being checked, containing one row where `Flag == "Fail"` and one where
  `Flag == "Suspect"`. Must contain numeric columns `GrMin` and `GrMax`.

## Value

Updated character flag vector.

## Details

Observations below `GrMin` or above `GrMax` in the `"Fail"` row are
flagged `"fail"`. Observations below `GrMin` or above `GrMax` in the
`"Suspect"` row (but within the fail bounds) are flagged `"suspect"`.
`NA` threshold values are silently skipped.

## Examples

``` r
flag <- rep("pass", 5)
vals <- c(-2, 0, 15, 26, 32)
dqo <- data.frame(
  Flag = c("Fail", "Suspect"),
  GrMin = c(-1, 0), GrMax = c(30, 25)
)
utilASRflaggross(flag, vals, dqo)
#> [1] "fail"    "pass"    "pass"    "suspect" "fail"   
```
