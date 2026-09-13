# Generate static screenshots of the editASRflag() Shiny app for use in
# vignettes.  Run this script manually after any UI change to refresh the
# images committed under vignettes/figures/.
#
# Requires:
#   install.packages("webshot2")
#   chromote::find_chrome()   # verify Chrome is detected
#   The package must be (re-)installed first (e.g. devtools::install()) --
#   library(AquaSensR) below picks up the installed version, not any
#   in-memory devtools::load_all() session.
#
# webshot2::appshot() can throw "Error in `rp_get_result()`: ! Still alive"
# even after successfully writing the screenshot -- a benign callr/processx
# race between the background screenshot process finishing and this session
# checking its result. Check the output file's timestamp rather than treating
# that specific error as a real failure.

library(AquaSensR)
library(webshot2)

outdir <- here::here("vignettes/figures")
# dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
dqopth <- system.file("extdata/ExampleDQO.xlsx", package = "AquaSensR")
contdat <- readASRcont(contpth)
dqodat <- readASRdqo(dqopth)

# ---- Screenshot 1: main app view (DQO panel closed) -------------------------
appshot(
  AquaSensR:::editASRflag_app(contdat, dqodat),
  file = file.path(outdir, "editASRflag_main.png"),
  delay = 5,
  vwidth = 1400,
  vheight = 820,
  zoom = 1.5
)
message("Wrote editASRflag_main.png")

# ---- Screenshot 2: DQO Settings panel open ----------------------------------
# dqo_sidebar_open = TRUE starts the right sidebar in the open state so no
# JavaScript interaction is needed -- appshot() captures the initial render.
appshot(
  AquaSensR:::editASRflag_app(contdat, dqodat, dqo_sidebar_open = TRUE),
  file = file.path(outdir, "editASRflag_dqo.png"),
  delay = 5,
  vwidth = 1400,
  vheight = 820,
  zoom = 1.5
)
message("Wrote editASRflag_dqo.png")

# ---- Screenshot 3: editASRdrift main view ------------------------------------
appshot(
  AquaSensR:::editASRdrift_app(contdat),
  file = file.path(outdir, "editASRdrift_main.png"),
  delay = 5,
  vwidth = 1400,
  vheight = 820,
  zoom = 1.5
)
message("Wrote editASRdrift_main.png")

# ---- Screenshot 4: editASRbulk main view -------------------------------------
appshot(
  AquaSensR:::editASRbulk_app(contdat),
  file = file.path(outdir, "editASRbulk_main.png"),
  delay = 5,
  vwidth = 1400,
  vheight = 820,
  zoom = 1.5
)
message("Wrote editASRbulk_main.png")
