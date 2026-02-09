library(dplyr)

paramsASR <- readxl::read_excel('inst/extdata/ParameterMapping.xlsx') |> 
  rename(
    Label = `MassWateR Column Label`
  )

usethis::use_data(paramsASR, overwrite = TRUE)
