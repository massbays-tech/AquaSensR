# Registers a static-resource path once per R session for Shiny app UIs (e.g.
# editASRworkflow()'s logo image) so they can reference bundled files in
# inst/www/ without needing to know its on-disk install location. Not
# exported.
.onLoad <- function(libname, pkgname) {
  shiny::addResourcePath("aquasensr-www", system.file("www", package = "AquaSensR"))
}

# Builds a bslib::page_sidebar() title with the AquaSensR hex logo (linked to
# the package website) to its left, shared by editASRbulk_ui(), editASRdrift_ui(),
# and editASRflag_ui() so their title bars stay visually consistent with each
# other and with editASRworkflow()'s own logo. Not exported.
aquasensr_logo_title <- function(text) {
  shiny::div(
    style = "display: flex; align-items: center; gap: 10px;",
    shiny::a(
      href = "https://massbays-tech.github.io/AquaSensR",
      target = "_blank",
      shiny::img(
        src = "aquasensr-www/logo.png",
        height = "40px",
        alt = "AquaSensR logo"
      )
    ),
    text
  )
}
