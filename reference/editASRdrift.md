# Interactive drift correction editor

Opens a Shiny application for interactively correcting instrument drift
in continuous water quality monitoring data. Click the plot twice to
mark the start and end of a drift period, enter the reference value
measured by an independent calibrated instrument at the end of the
deployment, and click **Apply Correction**. A third click resets the
selection.

## Usage

``` r
editASRdrift(cont)
```

## Arguments

- cont:

  `contdat` data frame returned by
  [`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)

## Value

A list with two elements, invisibly returned after the app closes:

- `contdat`:

  A data frame with the same structure as the input `cont` (sorted by
  `DateTime`), with drift-corrected values replacing the originals in
  all corrected windows.

- `corrections`:

  A data frame summarising every correction applied, with columns
  `Parameter`, `drift_start`, `drift_end`, `cal_ref`, `cal_check`, and
  `drift_applied`.

## Details

### How to correct drift

Zoom and pan with the plot toolbar to identify the drift period. Click
once to set the start time and click again to set the end time. Clicking
a third time resets the selection. Once two times are selected, enter
the **Reference value** (the true reading from an independent calibrated
instrument at the end of the deployment) and click **Apply Correction**.

The `cal_check` value (the deployed sensor reading at the end of the
window) is inferred automatically from the data. The correction is
distributed linearly across the window: zero at the start, full
correction at the end. See
[`utilASRdrift`](https://massbays-tech.github.io/AquaSensR/reference/utilASRdrift.md)
for the algorithm.

Multiple corrections can be applied per parameter (e.g., one per
deployment period), and each can be individually undone.

### Controls

- **Parameter**: drop-down selector to switch between parameters.
  Corrections are tracked independently for each parameter.

- **Undo Last Correction**: reverses the most recently applied
  correction for the current parameter.

- **Start Over**: restores all original values for every parameter and
  clears the corrections log.

- **Export Progress**: saves the current corrected data and corrections
  log as Excel files in a ZIP archive.

- **Done / Close**: stops the app and returns the corrected data and
  corrections summary to the R session.

## Examples

``` r
if (FALSE) { # \dontrun{
contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
contdat <- readASRcont(contpth)
result  <- editASRdrift(contdat)
} # }
```
