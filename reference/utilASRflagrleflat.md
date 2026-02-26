# Compute consecutive run lengths for flatline detection

Compute consecutive run lengths for flatline detection

## Usage

``` r
utilASRflagrleflat(vals, delta)
```

## Arguments

- vals:

  numeric vector of observed values.

- delta:

  non-negative numeric scalar. Two adjacent observations are considered
  part of the same flat run if their absolute difference is less than or
  equal to `delta`.

## Value

Integer vector the same length as `vals` giving the run length at each
position.

## Details

For each position \\i\\, the run length is the number of consecutive
observations ending at \\i\\ (including \\i\\ itself) for which each
successive absolute difference is \\\le\\ `delta`. A run length of 1
means the observation is not part of a flat stretch. `NA` values in
`vals` break the run.

## Examples

``` r
vals <- c(10, 10, 10.005, 10.003, 12, 12, 12)
utilASRflagrleflat(vals, delta = 0.01)
#> [1] 1 2 3 4 1 2 3
```
