# Interactive drift correction editor

Opens a Shiny application for interactively correcting instrument drift
in continuous water quality monitoring data. Click the plot twice to
mark the start and end of a drift period, enter the reference value
measured by an independent calibrated instrument at the end of the
deployment, and click **Apply Correction**. A third click resets the
selection. Clicking **Done / Close** stops the app. Choose **Close, save
corrections** to return the corrected data or **Close, discard
corrections** to return the original unmodified data.

## Usage

``` r
editASRdrift(cont, ext = NULL)
```

## Arguments

- cont:

  `contdat` data frame returned by
  [`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)

- ext:

  Optional external data frame returned by
  [`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md),
  with a `DateTime` column plus one or more parameter columns from a
  second file (e.g. a separate logger not otherwise included in `cont`).
  When supplied, each column is added as an additional entry in the
  **Overlay** drop-down (see Controls below) so it can be plotted
  alongside any parameter. Its `DateTime` column is aligned to `cont`'s
  time zone and clipped to `cont`'s date range. Entries are omitted
  entirely if the two do not overlap.

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

After a correction is applied, the plot retains the original
(pre-correction) values for the window as a solid gray line so the
adjustment can be assessed visually. A red circle marks the supplied
reference value at the end of the window. These elements are
display-only and are not included in the returned data.

Multiple corrections can be applied per parameter (e.g., one per
deployment period), and each can be individually undone.

### Controls

- **Parameter**: drop-down selector to switch between parameters.
  Corrections are tracked independently for each parameter.

- **Overlay**: optional drop-down to display a second parameter from
  `contdat` on a right-side y-axis, useful for spotting co-occurring
  changes across parameters. If an `ext` argument was supplied, one
  additional entry per column in that file is also available, labeled
  with an `"[External File]"` suffix.

- **USGS Overlay**: enter a USGS site number and select a parameter
  type, then click **Load** to fetch continuous data from NWIS and
  display it on the secondary y-axis. Loading USGS data clears any
  Overlay selection and selecting an Overlay entry clears the USGS data.
  Site numbers can be found at the NWIS Mapper
  (<https://apps.usgs.gov/nwismapper>).

- **Undo Last Correction**: reverses the most recently applied
  correction for the current parameter.

- **Start Over**: restores all original values for every parameter and
  clears the corrections log.

- **Export Progress**: saves the current corrected data and corrections
  log as Excel files in a ZIP archive.

- **Done / Close**: stops the app. Choosing **Close, save corrections**
  returns the corrected data and corrections summary. Choosing **Close,
  discard corrections** returns the original unmodified data. Closing
  the browser tab or window directly (without clicking **Done / Close**)
  also saves corrections, equivalent to **Close, save corrections**.
  Refreshing the page has the same effect and ends the session, since a
  refresh disconnects the browser from the running app. If any
  corrections have been applied in the current session, closing or
  refreshing this way triggers the browser's own "leave site?"
  confirmation as a warning. Dismissing that warning by declining it
  keeps the session open. This warning does not appear when closing via
  **Done / Close**, since that choice is already explicit.

## Examples

``` r
if (FALSE) { # \dontrun{
contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
contdat <- readASRcont(contpth)
result  <- editASRdrift(contdat)

# Optional external overlay from a second file
extpth <- system.file("extdata/ExampleFlow1.xlsx", package = "AquaSensR")
extdat <- readASRcont(extpth)
result2 <- editASRdrift(contdat, ext = extdat)
} # }
```
