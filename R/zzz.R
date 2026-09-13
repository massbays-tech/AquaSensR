# Registers a static-resource path once per R session for Shiny app UIs (e.g.
# editASRworkflow()'s logo image) so they can reference bundled files in
# inst/www/ without needing to know its on-disk install location. Not
# exported.
.onLoad <- function(libname, pkgname) {
  shiny::addResourcePath("aquasensr-www", system.file("www", package = "AquaSensR"))
}
