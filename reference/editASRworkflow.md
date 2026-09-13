# Combined bulk removal, drift correction, and flag review workflow

Opens a small launcher screen with one icon per step for Bulk Removal,
Drift Correction, and Flag Review arranged horizontally. Clicking an
icon opens that step's editor
([`editASRbulk`](https://massbays-tech.github.io/AquaSensR/reference/editASRbulk.md),
[`editASRdrift`](https://massbays-tech.github.io/AquaSensR/reference/editASRdrift.md),
or
[`editASRflag`](https://massbays-tech.github.io/AquaSensR/reference/editASRflag.md))
in place, inside the same running app. When that editor's Done / Close
button is clicked, the launcher screen reopens with the updated data, so
each step's output feeds the next step's input. The arrangement of the
icons implies the order of operations, but any editor can be selected in
any order. Click the Finish & Return to R button to end the session and
return the combined result.

## Usage

``` r
editASRworkflow(cont, dqo, ext = NULL)
```

## Arguments

- cont:

  `contdat` data frame returned by
  [`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md).

- dqo:

  `dqodat` data frame returned by
  [`readASRdqo`](https://massbays-tech.github.io/AquaSensR/reference/readASRdqo.md),
  used by the Flag Review step.

- ext:

  Optional external data frame returned by
  [`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md),
  passed through to both the Drift Correction and Flag Review steps (see
  their `ext` argument for details).

## Value

A list with five elements, invisibly returned once Finish & Return to R
is clicked from the main interface:

- `contdat`:

  The data frame after all edits made across every step, sorted by
  `DateTime`.

- `dqodat`:

  The DQO thresholds data frame, reflecting any edits made in the Flag
  Review step's DQO Settings panel.

- `bulk_removed`:

  The Bulk Removal step's removed-points log (see
  [`editASRbulk`](https://massbays-tech.github.io/AquaSensR/reference/editASRbulk.md)).

- `corrections`:

  The Drift Correction step's corrections log (see
  [`editASRdrift`](https://massbays-tech.github.io/AquaSensR/reference/editASRdrift.md)).

- `removed`:

  The Flag Review step's removed-points log, including QC flag columns
  (see
  [`editASRflag`](https://massbays-tech.github.io/AquaSensR/reference/editASRflag.md)).

## Details

Each step is the same editor used by its standalone function
([`editASRbulk`](https://massbays-tech.github.io/AquaSensR/reference/editASRbulk.md),
[`editASRdrift`](https://massbays-tech.github.io/AquaSensR/reference/editASRdrift.md),
[`editASRflag`](https://massbays-tech.github.io/AquaSensR/reference/editASRflag.md)),
mounted in place as one step of this app rather than opened as an
independent process. Each selection of Done / Close save/discard within
an editor behaves exactly as it does when called directly. Output from
one editing section is passed to next selected editor.

Icons are always clickable, in any order, any number of times. Every
step always starts from the most current data, i.e., the output of
whichever step was completed most recently, regardless of the icons'
left-to-right order (e.g. reopening Bulk Removal after Drift Correction
and Flag Review have already run starts from the drift-corrected,
flag-cleaned data, not the originally supplied `cont`). Its new output
again feeds forward into whatever step runs next. Results from steps
completed earlier are not automatically re-run or invalidated when an
earlier step is revisited. It is up to the user to re-run any downstream
steps that should reflect the change.

As in the standalone editors, closing the browser tab or window directly
(instead of clicking Finish & Return to R) triggers the browser's own
"leave site?" confirmation once any edits exist to lose, whether that is
from viewing an editor mid-edit or from having completed at least one
step without yet clicking Finish. This warning is a single safety net
that spans the whole session, not one per editor. Dismissing it keeps
the session open. Choosing to leave anyway loses only what the per-step
ungraceful-close safety net does not already cover: any edits made in
the currently open, not-yet-Done step are lost, while steps whose own
Done/Close has already fired are preserved and returned as if Finish had
been clicked.

## Examples

``` r
if (FALSE) { # \dontrun{
contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
dqopth  <- system.file("extdata/ExampleDQO.xlsx", package = "AquaSensR")
contdat <- readASRcont(contpth)
dqodat  <- readASRdqo(dqopth)

result <- editASRworkflow(contdat, dqodat)
} # }
```
