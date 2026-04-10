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
  current run only when both (1) its absolute difference from the
  immediately preceding observation is \\\le\\ `delta`, and (2) its
  absolute difference from the first observation in the run (the anchor)
  is \\\le\\ `delta`. Either condition failing resets the run.

## Value

Integer vector the same length as `vals` giving the run length at each
position.

## Details

For each position \\i\\, the run extends only when both conditions hold:
(1) the step from the previous observation is \\\le\\ `delta` (prevents
a large single-step jump from continuing the run), and (2) the value is
within \\\le\\ `delta` of the first observation in the current run
(prevents slow cumulative drift from accumulating run length
indefinitely). Either condition failing resets the run and anchors to
the current observation. A run length of 1 means the observation is not
part of a flat stretch. `NA` values in `vals` break the run.

## Examples

``` r
vals <- c(10, 10, 10.005, 10.003, 12, 12, 12)
utilASRflagrleflat(vals, delta = 0.01)
#> [1] 1 2 3 4 1 2 3
```
