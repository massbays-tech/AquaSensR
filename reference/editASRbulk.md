# Interactive bulk removal editor

Opens a Shiny application for quickly removing a contiguous stretch of
continuous monitoring data across every parameter at once, typically
because a sensor was out of the water at the start, end, or middle of a
deployment. Removal is always linked so that a selection made while
viewing one parameter removes the same timestamps from every other
parameter. Unlike
[`editASRflag`](https://massbays-tech.github.io/AquaSensR/reference/editASRflag.md),
no QC flags are computed and no DQO thresholds are involved. This is a
coarse first pass meant to run before other QC processes.

## Usage

``` r
editASRbulk(cont, removed = NULL)
```

## Arguments

- cont:

  `contdat` data frame returned by
  [`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md),
  or the `contdat` element of a previous `editASRbulk` result for
  iterative editing.

- removed:

  Optional data frame: the `removed` element returned by a previous call
  to `editASRbulk` (or a compatible `removed` data frame from
  [`editASRflag`](https://massbays-tech.github.io/AquaSensR/reference/editASRflag.md),
  since both share the same `Parameter`/`DateTime`/`Value` columns).
  When supplied, the corresponding timestamps are pre-populated as
  removed (excluded from the plot, shown in the Removed Points table)
  without any new action.

## Value

A list with two elements, invisibly returned after the app closes:

- `contdat`:

  A data frame with the same structure as the input `cont` (sorted by
  `DateTime`), where every parameter at a removed timestamp is replaced
  with `NA`. Rows are retained with only `DateTime` populated.

- `removed`:

  A data frame of all removed observations across all parameters, with
  columns `Parameter`, `DateTime`, and `Value`. Can be passed as the
  `removed` argument to a later `editASRbulk`.

## Details

### How to select a range

Zooming and panning with the plot toolbar is recommended to more easily
identify the portion to remove. Hover over the plot and choose the **Box
Select** or **Lasso Select** tool from the menu on the top right, then
click and drag (box) or click and encircle (lasso) the points to remove.
The removal applies to every parameter at those timestamps, not just the
one currently displayed.

### Controls

- **Parameter**: drop-down selector to switch between parameters.
  Removed timestamps are shared across all parameters, so switching
  parameters never changes what has been removed.

- **Undo Last Removal**: restores the most recently removed selection,
  across every parameter.

- **Start Over**: undoes all removals made in the current session,
  reverting to the state the app was in when it opened. Any removals
  passed in via the `removed` argument are preserved.

- **Export Progress**: saves the current cleaned data as an Excel file
  in a ZIP archive. If any points have been removed, a
  removed-observations file is included as well.

- **Done / Close**: stops the app. Choosing **Close, save edits**
  returns the filtered data for all parameters whereas choosing **Close,
  discard edits** returns the original unmodified data. Closing the
  browser tab or window directly (without clicking **Done / Close**)
  also saves edits, equivalent to **Close, save edits**. Refreshing the
  page has the same effect.

## Examples

``` r
if (FALSE) { # \dontrun{
contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
contdat <- readASRcont(contpth)

# First session: trim obvious out-of-water stretches
trimmed <- editASRbulk(contdat)
} # }
```
