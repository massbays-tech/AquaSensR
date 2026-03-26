# Apply spike QC flag

Apply spike QC flag

## Usage

``` r
utilASRflagspike(flag, vals, dqo)
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
  `Flag == "Suspect"`. Optional numeric column `Spike` defines the
  absolute-difference threshold for each severity level. Either row may
  have `NA` for `Spike`, in which case that level of check is skipped.

## Value

Updated character flag vector.

## Details

The absolute difference between each observation and the preceding one
is computed. If the difference is greater than or equal to `Spike` in
the `"Suspect"` row the observation is flagged `"suspect"`; greater than
or equal to `Spike` in the `"Fail"` row flags `"fail"`. The first
observation always receives `NA` for the difference and is not flagged
by this check.

## Examples

``` r
flag <- rep("pass", 5)
vals <- c(10, 10.5, 14, 10.2, 10.3)
dqo <- data.frame(Flag = c("Fail", "Suspect"), Spike = c(2.0, 1.5))
utilASRflagspike(flag, vals, dqo)
#> [1] "pass" "pass" "fail" "fail" "pass"
```
