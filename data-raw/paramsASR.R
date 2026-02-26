library(dplyr)

paramsASR <- readxl::read_excel('inst/extdata/ASRparameterMapping.xlsx')

usethis::use_data(paramsASR, overwrite = TRUE)
