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

  non-negative numeric scalar tolerance. An observation extends the
  current run only when the range (max minus min) of all values in the
  run so far, including the new observation, is strictly \\\<\\ `delta`.
  If this condition fails the run resets.

## Value

Integer vector the same length as `vals` giving the run length at each
position.

## Details

For each position \\i\\, the run extends only when adding the current
observation to the run keeps the range (max minus min of all values in
the run) strictly \\\<\\ `delta`. This prevents both large single-step
jumps and slow cumulative drift from accumulating run length. A range
equal to `delta` is not considered flatline. A run length of 1 means the
observation is not part of a flat stretch. `NA` values in `vals` break
the run.

## Examples

``` r
vals <- c(10, 10, 10.005, 10.003, 12, 12, 12)
utilASRflagrleflat(vals, delta = 0.01)
#> [1] 1 2 3 4 1 2 3
```
