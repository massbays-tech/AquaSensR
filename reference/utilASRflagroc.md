# Apply rate-of-change QC flag

Apply rate-of-change QC flag

## Usage

``` r
utilASRflagroc(flag, vals, datetimes, dqo)
```

## Arguments

- flag:

  character vector of current flag values (`"pass"`, `"suspect"`, or
  `"fail"`).

- vals:

  numeric vector of observed values, the same length as `flag`.

- datetimes:

  POSIXct vector of observation timestamps, the same length as `flag`.

- dqo:

  two-row data frame from data quality objectives for the parameter
  being checked, containing one row where `Flag == "Fail"` and one where
  `Flag == "Suspect"`. The `"Suspect"` row's numeric columns `RoCN` (SD
  multiplier) and `RoCHours` (trailing window width in hours) control
  the check. If either column is `NA` in the `"Suspect"` row the check
  is skipped. Rate-of-change thresholds are not applied to `"Fail"`
  flags.

## Value

Updated character flag vector.

## Details

For each observation the standard deviation of all raw values within a
trailing `RoCHours`-hour window ending at (and including) that
observation is multiplied by `RoCN` to produce a threshold. The
observation is flagged `"suspect"` if the absolute lag-1 difference
exceeds that threshold. At least 2 values must fall within the window to
compute the standard deviation; otherwise the observation is skipped.
This check only produces `"suspect"` flags; it does not produce `"fail"`
flags.

## Examples

``` r
flag <- rep("pass", 6)
vals <- c(10, 10.2, 10.1, 10.3, 15.0, 10.2)
datetimes <- as.POSIXct("2024-01-01") + seq(0, 5) * 900  # 15-min intervals
dqo <- data.frame(Flag = c("Fail", "Suspect"), RoCN = c(NA, 3), RoCHours = c(NA, 2))
utilASRflagroc(flag, vals, datetimes, dqo)
#> [1] "pass" "pass" "pass" "pass" "pass" "pass"
```
