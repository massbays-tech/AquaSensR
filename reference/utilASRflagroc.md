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
  `Flag == "Suspect"`. Each row's numeric columns `RoCStDv` (SD
  multiplier) and `RoCHours` (trailing window width in hours) control
  the check independently. If either column is `NA` for a given row that
  severity level is skipped entirely.

## Value

Updated character flag vector.

## Details

For each observation the standard deviation of all raw values within a
trailing `RoCHours`-hour window ending at (and excluding that
observation is multiplied by `RoCStDv` to produce a threshold. The
observation is flagged if the absolute lag-1 difference exceeds that
threshold — `"suspect"` using the `"Suspect"` row thresholds and
`"fail"` using the `"Fail"` row thresholds. At least 2 values must fall
within the window to compute the standard deviation; otherwise the
observation is skipped. Flags are only ever upgraded (pass -\> suspect
-\> fail), never downgraded.

## Examples

``` r
flag <- rep("pass", 6)
vals <- c(10, 10.2, 10.1, 10.3, 15.0, 10.2)
datetimes <- as.POSIXct("2024-01-01") + seq(0, 5) * 900  # 15-min intervals
dqo <- data.frame(Flag = c("Fail", "Suspect"), RoCStDv = c(2, 3), RoCHours = c(2, 2))
utilASRflagroc(flag, vals, datetimes, dqo)
#> [1] "pass" "pass" "pass" "fail" "fail" "fail"
```
