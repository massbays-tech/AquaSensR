library(dplyr)

paramsASR <- readxl::read_excel('inst/extdata/ParameterMapping.xlsx')

usethis::use_data(paramsASR, overwrite = TRUE)
