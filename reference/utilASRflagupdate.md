# Update QC flag severity

Update QC flag severity

## Usage

``` r
utilASRflagupdate(flag, level, condition)
```

## Arguments

- flag:

  character vector of current flag values; each element must be one of
  `"pass"`, `"suspect"`, or `"fail"`.

- level:

  scalar character string — the new flag level to apply (`"pass"`,
  `"suspect"`, or `"fail"`).

- condition:

  logical vector the same length as `flag`. Elements that are `TRUE` and
  whose current flag is less severe than `level` will be upgraded. `NA`
  values in `condition` are treated as `FALSE`.

## Value

Character vector the same length as `flag` with flags updated where
`condition` is `TRUE` and `level` is more severe than the existing flag.

## Details

Severity is ordered `"pass"` \< `"suspect"` \< `"fail"`. A flag is only
ever upgraded, never downgraded.

## Examples

``` r
flag <- c("pass", "pass", "suspect", "fail")
utilASRflagupdate(flag, "suspect", c(TRUE, FALSE, TRUE, TRUE))
#> [1] "suspect" "pass"    "suspect" "fail"   
utilASRflagupdate(flag, "fail",    c(TRUE, TRUE, FALSE, FALSE))
#> [1] "fail"    "fail"    "suspect" "fail"   
```
