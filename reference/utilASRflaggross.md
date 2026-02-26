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
  Must contain numeric columns `Min`, `Max`, `Tlower`, and `Tupper`.

## Value

Updated character flag vector.

## Details

Observations below `Min` or above `Max` are flagged `"fail"`.
Observations below `Tlower` or above `Tupper` (but within the fail
bounds) are flagged `"suspect"`. `NA` threshold values are silently
skipped.

## Examples

``` r
flag <- rep("pass", 5)
vals <- c(-2, 0, 15, 26, 32)
meta <- data.frame(Min = -1, Max = 30, Tlower = 0, Tupper = 25)
utilASRflaggross(flag, vals, meta)
#> [1] "fail"    "pass"    "pass"    "suspect" "fail"   
```
