# Interactive editor for continuous monitoring data

Opens a Shiny application displaying the QC flag plot from
[`anlzASRflag`](https://massbays-tech.github.io/AquaSensR/reference/anlzASRflag.md)
and allows the user to interactively select and remove data points.
Points are removed by clicking or drawing a selection using the box or
lasso tool on the plot. A running table of removed points (including
their flag assignments) is shown in the sidebar. Individual removal
batches can be undone, or the session can be fully reset. Clicking
**Done / Close** stops the app and returns the filtered dataset to the R
session.

## Usage

``` r
editASRflag(flagdat)
```

## Arguments

- flagdat:

  data frame returned by
  [`utilASRflag`](https://massbays-tech.github.io/AquaSensR/reference/utilASRflag.md),
  with columns `DateTime`, the parameter column, and `gross_flag`,
  `spike_flag`, `roc_flag`, `flat_flag`.

## Value

A data frame with the same structure as `flagdat` but with user-selected
points removed, invisibly returned after the app closes.

## Details

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

- **Undo Last Removal**: restores the most recently removed point or
  batch of points (one drag-selection at a time).

- **Start Over**: restores all removed points and resets to the original
  dataset.

- **Done / Close**: stops the app and returns the current filtered
  dataset to the R session.

The app is constructed inline so that `flagdat` is available directly to
the server without file I/O.
[`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html) blocks
until [`shiny::stopApp()`](https://rdrr.io/pkg/shiny/man/stopApp.html)
is called by the Done button; its return value becomes the function
return value.

## Examples

``` r
if (FALSE) { # \dontrun{
contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
dqopth  <- system.file("extdata/ExampleDQO.xlsx", package = "AquaSensR")
contdat <- readASRcont(contpth, tz = "Etc/GMT+5")
dqodat  <- readASRdqo(dqopth)
flagdat <- utilASRflag(contdat, dqodat, "Water Temp_C")
cleaned <- editASRflag(flagdat)
} # }
```
