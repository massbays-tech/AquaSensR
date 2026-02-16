library(testthat)

tst <- list(
  # continuous data
  contpth = system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR'),
  contdatchk = suppressWarnings(readxl::read_excel(
    system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR'),
    na = c('NA', 'na', ''),
    guess_max = Inf
  )) |>
    dplyr::mutate(dplyr::across(
      dplyr::where(~ inherits(.x, "POSIXct") | inherits(.x, "Date")),
      as.character
    )),
  contdat = readASRcont(
    system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR'),
    tz = 'Etc/GMT+5',
    runchk = F
  ),
  # continuous metadata
  metapth = system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR'),
  metadatchk = suppressWarnings(readxl::read_excel(
    system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR'),
    na = c('NA', 'na', ''),
    guess_max = Inf
  )),
  metadat = readASRmeta(
    system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR'),
    runchk = F
  )
)
