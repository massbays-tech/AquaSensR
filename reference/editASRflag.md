# Interactive editor for continuous monitoring data

Opens a Shiny application displaying the QC flag plot from
[`anlzASRflag`](https://massbays-tech.github.io/AquaSensR/reference/anlzASRflag.md)
for each parameter in `contdat` and allows the user to interactively
select and remove data points. Points are removed by clicking or drawing
a selection using the box or lasso tool on the plot. A running table of
removed points (including their flag assignments) is shown in the
sidebar and is specific to the currently displayed parameter. Individual
removal batches can be undone, or all parameters can be fully reset.
Clicking **Done / Close** stops the app; choose **Close, save edits** to
return the filtered data or **Close, discard edits** to return the
original unmodified data.

## Usage

``` r
editASRflag(cont, dqo, removed = NULL)
```

## Arguments

- cont:

  `contdat` data frame returned by
  [`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md),
  or the `contdat` element of a previous `editASRflag` result for
  iterative editing.

- dqo:

  `dqodat` data frame returned by
  [`readASRdqo`](https://massbays-tech.github.io/AquaSensR/reference/readASRdqo.md),
  or the `dqodat` element of a previous `editASRflag` result.

- removed:

  Optional data frame: the `removed` element returned by a previous call
  to `editASRflag`. When supplied, previously removed observations are
  pre-populated in the app (shown in the removed-points table and
  excluded from the plot) and original values are restored before
  re-flagging so that QC checks are not affected by the gaps. Passing
  all three elements of a prior result enables fully iterative editing.

## Value

A list with three elements, invisibly returned after the app closes:

- `contdat`:

  A data frame with the same structure as the input `contdat` (sorted by
  `DateTime`), where values removed by the user are replaced with `NA`.
  Rows in which every parameter was removed are retained with only
  `DateTime` populated.

- `dqodat`:

  A data frame with the same structure as the input `dqo`, reflecting
  any threshold edits made in the DQO Settings panel. If no edits were
  made the values are identical to the input.

- `removed`:

  A data frame of all removed observations across all parameters, with
  columns `Parameter`, `DateTime`, `Value`, `gross_flag`, `spike_flag`,
  `roc_flag`, and `flat_flag`.

## Details

QC flags are computed internally via
[`utilASRflagall`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflagall.md).

### How to select points

Zooming and panning with the plot toolbar is recommended to more easily
identify points for removal. These options are available in the menu on
the top right when hovering over the plot.

Points can be selected for removal three ways. First, individual points
can be removed by clicking. Second and third, use the box or lasso
selection tool by hovering over the plot and selecting the desired tool
from the menu on the top right. Click and drag over the desired area for
the box selection or click and encircle the points with the lasso tool
to add the points to the removal table. Double-click the plot background
to remove the selected area if present after removal.

### Controls

- **Parameter**: drop-down selector to switch between parameters. Edits
  to each parameter are preserved independently when switching.

- **Overlay**: optional drop-down to display a second parameter from
  `condtat` on a right-side y-axis, useful for spotting co-occurring
  changes across parameters.

- **USGS Overlay**: enter a USGS site number and select a parameter
  type, then click **Load** to fetch continuous data from NWIS and
  display it on the secondary y-axis. Loading USGS data clears any
  contdat overlay and selecting a contdat overlay clears the USGS data.
  Site numbers can be found at the NWIS Mapper
  (<https://apps.usgs.gov/nwismapper>).

- **Linked Removal**: optional checkbox. When checked (default), any
  timestamps removed from the current parameter are simultaneously
  removed from all other parameters. Undo restores the current parameter
  and all other parameters together as a single operation, regardless of
  which parameter is active when undo is clicked.

- **Undo Last Removal**: restores the most recently removed point or
  batch of points. If the removal was linked, all affected parameters
  are restored together.

- **Start Over**: undoes all removals and DQO edits made in the current
  session, reverting every parameter to the state it was in when the app
  opened. Any removals passed in via the `removed` argument are
  preserved.

- **Export Progress**: saves the current cleaned data and DQO thresholds
  as Excel files in a ZIP archive. If any points have been removed, a
  removed-observations file is included as well.

- **Done / Close**: stops the app. Choosing **Close, save edits**
  returns the filtered datasets for all parameters; choosing **Close,
  discard edits** returns the original unmodified data.

### DQO Settings panel

A collapsible panel on the right side of the plot exposes the numeric QC
thresholds for the currently selected parameter. Each of the four checks
(gross range, spike, rate of change, flatline) shows independent
**Suspect** and **Fail** threshold columns.

- **Apply**: re-computes flags for the current parameter using the
  edited thresholds. Previously removed points are retained.

- **Reset to original**: reverts the inputs to the values supplied in
  `dqo` and re-computes flags. Any points already removed are retained.

Threshold edits are per-parameter and independent; switching parameters
shows that parameter's current thresholds without affecting others.

The app is constructed inline so that flag data are available directly
to the server without file I/O.
[`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html) blocks
until [`shiny::stopApp()`](https://rdrr.io/pkg/shiny/man/stopApp.html)
is called by the Done button; its return value becomes the function
return value.

## Examples

``` r
if (FALSE) { # \dontrun{
contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
dqopth  <- system.file("extdata/ExampleDQO.xlsx", package = "AquaSensR")
contdat <- readASRcont(contpth)
dqodat  <- readASRdqo(dqopth)

# First session
cleaned <- editASRflag(contdat, dqodat)

# Second session: picks up where the first left off
cleaned2 <- editASRflag(cleaned$contdat, cleaned$dqodat, cleaned$removed)
} # }
```
