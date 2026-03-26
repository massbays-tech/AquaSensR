# Apply flatline QC flag

Apply flatline QC flag

## Usage

``` r
utilASRflagflatline(flag, vals, dqo)
```

## Arguments

- flag:

  character vector of current flag values (`"pass"`, `"suspect"`, or
  `"fail"`).

- vals:

  numeric vector of observed values, the same length as `flag`.

- dqo:

  two-row data frame of data quality objectives for the parameter being
  checked, containing one row where `Flag == "Fail"` and one where
  `Flag == "Suspect"`. Optional numeric columns `FlatN` and `FlatDelta`
  define the run-length and tolerance thresholds for each severity
  level. Either row may have `NA` for these columns, in which case that
  level of check is skipped.

## Value

Updated character flag vector.

## Details

Uses
[`utilASRflagrleflat`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflagrleflat.md)
to compute consecutive run lengths. An observation is flagged
`"suspect"` when its run length (computed with `FlatDelta` from the
`"Suspect"` row) reaches `FlatN`, and `"fail"` when its run length
(computed with `FlatDelta` from the `"Fail"` row) reaches `FlatN`.

## Examples

``` r
flag <- rep("pass", 8)
vals <- c(10, 10, 10.005, 10.002, 10.001, 10.003, 12, 12)
dqo <- data.frame(
  Flag = c("Fail", "Suspect"),
  FlatN = c(5, 3), FlatDelta = c(0.01, 0.01)
)
utilASRflagflatline(flag, vals, dqo)
#> [1] "pass"    "pass"    "suspect" "suspect" "fail"    "fail"    "pass"   
#> [8] "pass"   
```
