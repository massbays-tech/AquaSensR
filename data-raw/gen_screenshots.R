# Generate static screenshots of the editASRflag() Shiny app for use in
# vignettes.  Run this script manually after any UI change to refresh the
# images committed under vignettes/figures/.
#
# Requires:
#   install.packages("webshot2")
#   chromote::find_chrome()   # verify Chrome is detected

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
