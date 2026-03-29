# Interactive flag editor for continuous monitoring data

Opens a Shiny application displaying the QC flag plot from
[`anlzASRflag`](https://massbays-tech.github.io/AquaSensR/reference/anlzASRflag.md)
and allows the user to interactively select and remove data points.
Points are removed by drawing a selection rectangle on the plot. A
running table of removed points (including their flag assignments) is
shown in the sidebar. Individual removal batches can be undone, or the
session can be fully reset. Clicking **Done / Close** stops the app and
returns the filtered dataset to the R session.

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

Draw a rectangle on the plot by clicking and dragging. All points within
the rectangle are removed immediately and added to the removal table.
You can also use the plotly lasso tool from the mode-bar.

### Controls

- **Undo Last Removal** — restores the most recently removed batch of
  points (one drag-selection at a time).

- **Start Over** — restores all removed points and resets to the
  original dataset.

- **Done / Close** — stops the app and returns the current filtered
  dataset to the R session.

### Shiny in a package

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
