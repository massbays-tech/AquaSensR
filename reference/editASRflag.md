# Interactive editor for continuous monitoring data

Opens a Shiny application displaying the QC flag plot from
[`anlzASRflag`](https://massbays-tech.github.io/AquaSensR/reference/anlzASRflag.md)
for each parameter in `contdat` and allows the user to interactively
select and remove data points. Points are removed by clicking or drawing
a selection using the box or lasso tool on the plot. A running table of
removed points (including their flag assignments) is shown in the
sidebar and is specific to the currently displayed parameter. Individual
removal batches can be undone, or the current parameter's session can be
fully reset. Clicking **Done / Close** stops the app and returns the
filtered datasets for all parameters to the R session.

## Usage

``` r
editASRflag(contdat, dqodat)
```

## Arguments

- contdat:

  data frame returned by
  [`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)

- dqodat:

  data frame returned by
  [`readASRdqo`](https://massbays-tech.github.io/AquaSensR/reference/readASRdqo.md)

## Value

A list with two elements, invisibly returned after the app closes:

- `contdat`:

  A data frame with the same structure as the input `contdat` (sorted by
  `DateTime`), where values removed by the user are replaced with `NA`.
  Rows in which every parameter was removed are retained with only
  `DateTime` populated.

- `removed`:

  A data frame of all removed observations across all parameters, with
  columns `Parameter`, `DateTime`, `gross_flag`, `spike_flag`,
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

- **Undo Last Removal**: restores the most recently removed point or
  batch of points for the current parameter (one drag-selection at a
  time).

- **Start Over**: restores all removed points for the current parameter
  and resets to the original flagged dataset.

- **Done / Close**: stops the app and returns the filtered datasets for
  all parameters to the R session.

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
contdat <- readASRcont(contpth, tz = "Etc/GMT+5")
dqodat  <- readASRdqo(dqopth)
cleaned <- editASRflag(contdat, dqodat)
} # }
```
