library(readxl)
library(writexl)

meta <- as.data.frame(read_excel(
  'inst/extdata/ExampleMeta.xlsx',
  na = c('NA', 'na', '')
))

# Parameter order in the file:
# 1 Water Temp_C
# 2 DO_pctsat
# 3 DO_mg_L
# 4 Conductivity_uS_cm
# 5 TDS_mg_L
# 6 Salinity_psu
# 7 pH_SU

# Spike: absolute diff between consecutive observations
meta$SpikeFail    <- c(2.0, 25.0,  4.0, 10.0, 100.0, 5.0, 10.0)
meta$SpikeSuspect <- c(1.5, 10.0,  2.0,  5.0,  50.0, 3.0,  5.0)

# Flatline: consecutive run length (N) and per-step tolerance (Delta)
meta$FlatFailN       <- c(100L, 60L, 60L, 60L, 60L, 60L, 60L)
meta$FlatFailDelta   <- c(0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01)
meta$FlatSuspectN    <- c(60L,  30L, 30L, 30L, 30L, 30L, 30L)
meta$FlatSuspectDelta <- c(0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01)

# Rate of change: SD multiplier and rolling window width (hours)
meta$RoCStdev <- rep(6,  7)
meta$RoCHours <- rep(25, 7)

write_xlsx(meta, 'inst/extdata/ExampleMeta.xlsx')
cat('Done\n')
print(meta)
