# Quality control overview

The quality control (QC) functions in AquaSensR can be used once the
required data are successfully imported into R (see the [inputs
vignette](https://massbays-tech.github.io/AquaSensR/articles/inputs.md)
for details). This vignette covers the primary functions of the QC
workflow:

- [`utilASRflag()`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflag.md):
  Applies four independent QC checks to a selected parameter and returns
  a data frame of flag results.
- [`anlzASRflag()`](https://massbays-tech.github.io/AquaSensR/reference/anlzASRflag.md):
  Produces an interactive time-series plot of those flags for visual
  review.

## Load the data

The examples throughout this vignette use the example files bundled with
the package. Import both files before proceeding:

``` r
contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
dqopth <- system.file("extdata/ExampleDQO.xlsx", package = "AquaSensR")

contdat <- readASRcont(contpth)
#> Running checks on continuous data...
#>  Checking column names... OK
#>  Checking Date, Time are present... OK
#>  Checking at least one parameter column is present... OK
#>  Checking date format... OK
#>  Checking time format... OK
#>  Checking for missing values... OK
#>  Checking parameter columns for non-numeric values... OK
#> 
#> All checks passed!
dqodat <- readASRdqo(dqopth)
#> Running checks on data quality objectives...
#>  Checking column names... OK
#>  Checking all columns present... OK
#>  Checking at least one parameter is present... OK
#>  Checking parameter format... OK
#>  Checking Flag column... OK
#>  Checking columns for non-numeric values... OK
#> 
#> All checks passed!
```

`contdat` is a data frame with columns `DateTime`, and one numeric
column per parameter. `dqodat` contains the parameter-specific data
quality objectives (DQOs) for each check. See the [inputs
vignette](https://massbays-tech.github.io/AquaSensR/articles/inputs.md)
for more information on the required formats.

## `utilASRflag()` to flag continuous data

[`utilASRflag()`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflag.md)
is the primary QC function. It applies four independent checks to the
chosen parameter in `contdat`.

### Arguments

Three arguments are required for the function:

| Argument | Description                                                                                                            |
|----------|------------------------------------------------------------------------------------------------------------------------|
| `cont`   | `contdat` data frame returned by [`readASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md) |
| `dqo`    | `dqodat` data frame returned by [`readASRdqo()`](https://massbays-tech.github.io/AquaSensR/reference/readASRdqo.md)    |
| `param`  | Name of the parameter column to evaluate (must match a column in `contdat` and a `Parameter` entry in `dqodat`)        |

### Basic usage

Pass the two data frames and the name of the parameter to evaluate:

``` r
flagdat <- utilASRflag(contdat, dqodat, param = "Water_Temp_C")
head(flagdat)
#> # A tibble: 6 × 6
#>   DateTime            Water_Temp_C gross_flag spike_flag roc_flag flat_flag
#>   <dttm>                     <dbl> <chr>      <chr>      <chr>    <chr>    
#> 1 2024-08-14 13:56:33         24.2 pass       pass       pass     pass     
#> 2 2024-08-14 13:56:43         24.2 pass       pass       pass     pass     
#> 3 2024-08-14 13:56:53         24.2 pass       pass       pass     pass     
#> 4 2024-08-14 13:57:03         24.2 pass       pass       pass     pass     
#> 5 2024-08-14 13:57:13         24.2 pass       pass       pass     pass     
#> 6 2024-08-14 13:57:23         24.2 pass       pass       pass     pass
```

### Output

[`utilASRflag()`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflag.md)
returns a data frame with the following columns:

| Column       | Description                        |
|--------------|------------------------------------|
| `DateTime`   | Observation timestamp              |
| *`param`*    | The evaluated parameter values     |
| `gross_flag` | Flag from the gross range check    |
| `spike_flag` | Flag from the spike check          |
| `roc_flag`   | Flag from the rate-of-change check |
| `flat_flag`  | Flag from the flatline check       |

Each flag column contains one of three values: `"pass"`, `"suspect"`, or
`"fail"`. Checks are independent of each other such that a single
observation can receive any combination of flags across the four
columns.

If no row in `dqodat` matches a parameter a warning is returned and the
function leaves all flags as `"pass"` and continues.

## QC checks explained

AquaSensR implements four QC checks that reflect widely used sensor data
quality standards. The underlying concepts and code borrow heavily from
the [ContDataQC](https://leppott.github.io/ContDataQC) package. All
threshold values are set in the data quality objectives file and can be
customised per parameter. Manual update of these thresholds is likely
necessary to avoide false positives and negatives. Importantly, these
flags require manual verification and should not be used to
automatically exclude data without review.

Any threshold value set to `NA` in the `dqodat` file is silently skipped
such that the corresponding severity level is not applied and affected
observations remain `"pass"` for that check. This applies to the
`"Suspect"` and `"Fail"` rows independently, so individual checks or
severity levels can be disabled selectively by leaving their threshold
columns blank in the input file.

### 1. Gross range

**DQO columns:** `GrMin`, `GrMax` (thresholds differ by row:
`Flag = "Fail"` vs `Flag = "Suspect"`)

**Flag column:** `gross_flag`

The gross range check tests whether each observation falls within
absolute physical or sensor limits. It is the broadest of the four
checks and is intended to catch values that are simply impossible or
outside the expected operating range of the instrument.

Each observation is compared to the thresholds in the two data quality
objectives rows for that parameter:

- Values below `GrMin` or above `GrMax` in the `"Fail"` row return
  `"fail"`
- Values below `GrMin` or above `GrMax` in the `"Suspect"` row but
  within the fail bounds return `"suspect"`

The fail thresholds define hard physical limits (e.g., water temperature
cannot be below −5 °C for a freshwater deployment). The suspect bounds
are set somewhat more conservatively to flag readings that are unusual
but not impossible.

Any threshold can be set to `NA` in the data quality objectives file to
skip that particular flag.

Quickly view how many flags of each type were generated by the gross
range check:

``` r
# Check which observations received a gross range flag
table(flagdat$gross_flag)
#> 
#>    pass suspect 
#>     923       4
```

### 2. Spike

**DQO columns:** `Spike` (threshold differs by row: `Flag = "Fail"` vs
`Flag = "Suspect"`)

**Flag column:** `spike_flag`

The spike check detects sudden, anomalous jumps (either up or down)
between consecutive observations. It computes the absolute difference
between each reading and the one immediately before it, then compares
that difference to the thresholds in the two data quality objectives
rows for that parameter:

- \|diff\| ≥ `Spike` in the `"Suspect"` row returns `"suspect"`
- \|diff\| ≥ `Spike` in the `"Fail"` row returns `"fail"`

The first observation in each series has no predecessor and is always
left as `"pass"`. Because the spike check flags the observation at the
large step, a single anomalous reading embedded in otherwise stable data
will generate two flagged observations — one for the step up (or down)
to the outlier, and one for the step back to baseline.

The spike thresholds are absolute. For example, a 5 °C step is flagged
regardless of whether the surrounding series is calm or noisy. The
rate-of-change check (below) evaluates potentially spurious changes when
relative variability matters.

Quickly view how many flags of each type were generated by the spike
check:

``` r
table(flagdat$spike_flag)
#> 
#>    fail    pass suspect 
#>       1     925       1
```

### 3. Rate of change

**DQO columns:** `RoCStDv`, `RoCHours` (thresholds differ by row:
`Flag = "Fail"` vs `Flag = "Suspect"`)

**Flag column:** `roc_flag`

The rate-of-change (RoC) check is an adaptive counterpart to the spike
check. Rather than comparing against a fixed step size, the check
determines whether a step is large relative to the recent variability in
the series.

For each observation the function:

1.  Collects all values within a trailing `RoCHours`-hour window ending
    at that timestamp.
2.  Computes the standard deviation (SD) of those values.
3.  Multiplies the SD by `RoCStDv` to produce a contextual threshold.
4.  Flags the observation if the absolute lag-1 difference exceeds that
    threshold — `"suspect"` using the `"Suspect"` row thresholds and
    `"fail"` using the `"Fail"` row thresholds.

At least two values must fall within the window before a standard
deviation can be computed; observations with fewer window values are not
flagged. Each row is evaluated independently, so either or both severity
levels can be active. Setting `RoCStDv` or `RoCHours` to `NA` for a row
skips that severity level entirely.

The key advantage over the spike check is sensitivity scaling. During a
“calm” period, a small absolute change can exceed the threshold, while
during a naturally variable period (e.g., diurnal temperature swings)
the threshold rises accordingly.

Quickly view how many flags of each type were generated by the rate of
change check:

``` r
table(flagdat$roc_flag)
#> 
#> pass 
#>  927
```

### 4. Flatline

**DQO columns:** `FlatN`, `FlatDelta` (thresholds differ by row:
`Flag = "Fail"` vs `Flag = "Suspect"`)

**Flag column:** `flat_flag`

The flatline check identifies periods where a sensor appears to be stuck
at a constant value, which can occur from sensor fouling, burial, or
loss of power. The check counts the length of “runs” of near-identical
consecutive values and flags observations whose run length reaches a
specified count.

A run is defined by a minimum length or count (`FlatN`) and tolerance
(`FlatDelta`), each read from the appropriate data quality objectives
row. An observation extends the current run only when both of the
following conditions are met:

1.  **Step condition:** The absolute difference from the immediately
    preceding observation is ≤ `FlatDelta`. This prevents a single large
    jump (e.g., a real change in the environment) from continuing an
    otherwise flat run.
2.  **Anchor condition:** The absolute difference from the first
    observation in the run (the anchor) is ≤ `FlatDelta`. This prevents
    a series of small but consistent steps (a slow upward or downward
    drift) from accumulating into a long run even though the signal is
    clearly moving.

Either condition failing immediately resets the run length to 1 and sets
the current observation as the new anchor. This dual-condition approach
avoids two common false-positive scenarios: gradual drift that never
exceeds the step tolerance in any single interval but cumulatively moves
well outside the flat band, and a large single-step change that happens
to land near the run’s starting value.

- Run length ≥ `FlatN` (using `FlatDelta` tolerance) from the
  `"Suspect"` row returns `"suspect"`
- Run length ≥ `FlatN` (using `FlatDelta` tolerance) from the `"Fail"`
  row returns `"fail"`

The suspect and fail thresholds are evaluated independently using their
respective delta tolerances, so the two run lengths may differ. Either
row can have `NA` values to skip that level.

Quickly view how many flags of each type were generated by the flatline
check:

``` r
table(flagdat$flat_flag)
#> 
#> pass 
#>  927
```

## `anlzASRflag()` to visualise flag results

The flags generated by
[`utilASRflag()`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflag.md)
can be viewed using the
[`anlzASRflag()`](https://massbays-tech.github.io/AquaSensR/reference/anlzASRflag.md)
function. This produces an interactive time-series plot:

``` r
anlzASRflag(flagdat)
```

The plot shows all observations as a continuous line. Non-passing
observations are overlaid as coloured markers, with colour encoding the
check type and shape encoding the severity:

| Check          | Colour |
|----------------|--------|
| Gross range    | Red    |
| Spike          | Orange |
| Rate of change | Purple |
| Flatline       | Blue   |

| Severity | Marker shape    |
|----------|-----------------|
| Suspect  | Upward triangle |
| Fail     | Cross (×)       |

An observation flagged by more than one check appears as overlying
markers for each check, so that all potential issues remain visible.
Hovering over a marker reveals the check name, severity, parameter
value, and timestamp. Items in the legend can be clicked to toggle
visibility of a check or severity level, which is useful for reviewing
specific flags in a busy plot. The plot can also be zoomed and panned to
focus on specific periods.
