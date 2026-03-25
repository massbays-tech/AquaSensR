library(readxl)
library(writexl)
library(dplyr)
library(lubridate)

dat <- suppressWarnings(read_excel(
  'inst/extdata/ExampleCont1.xlsx',
  na = c('NA', 'na', ''),
  guess_max = Inf
))

# Combine Date and Time into a single DateTime column
# Time arrives from Excel as "1899-12-31 HH:MM:SS" POSIXct; extract just the time part
dat2 <- dat |>
  mutate(
    Date = as.character(as.Date(Date)),
    Time = gsub('^.*\\s', '', as.character(Time)),
    DateTime = paste(Date, Time),
    .before = 1
  ) |>
  select(-Date, -Time) |>
  select(DateTime, everything())

write_xlsx(dat2, 'inst/extdata/ExampleCont2.xlsx')
cat('ExampleCont2.xlsx written with', nrow(dat2), 'rows\n')
cat('Columns:', paste(names(dat2), collapse = ', '), '\n')
print(head(dat2, 3))
