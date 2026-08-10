library(readxl)
library(writexl)
library(dplyr)

pth <- 'inst/extdata/ASRparameterMapping.xlsx'
dat <- read_excel(pth, sheet = 'Continuous Parameters')

new_row <- tibble(
  `Parameter Group` = "Flow",
  Parameter = "Flow_cfs",
  uom = "cfs",
  Label = "Flow (cfs)",
  `WQX Parameter` = "Flow",
  `WQX Unit of measure` = "cfs"
)

# insert immediately after the last existing "Flow" group row, preserving the
# group-alphabetical layout of the sheet
insert_at <- max(which(dat$`Parameter Group` == "Flow"))
dat2 <- bind_rows(dat[seq_len(insert_at), ], new_row, dat[(insert_at + 1):nrow(dat), ])

write_xlsx(list(`Continuous Parameters` = dat2), pth)
cat('ASRparameterMapping.xlsx updated with Flow_cfs row, now', nrow(dat2), 'rows\n')
print(dat2[dat2$`Parameter Group` == "Flow", ])
