# AquaSensR QC Workflow
# Imports continuous data and data quality objectives, applies QC flags, and visualizes results

library(AquaSensR)

# ------------------------------------------------------------------------------
# 1. File paths
# ------------------------------------------------------------------------------
# Replace with paths to your own files, or use the package example data:
# contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
contpth <- system.file("extdata/ExampleCont2.xlsx", package = "AquaSensR")
contpth <- '~/Desktop/AquaSensR_export_20260517_174049/contdat.xlsx'
# contpth <- '~/Desktop/RVM-018 2022-07-25_2022-08-31_cond_vers2.xlsx'
# contpth <- '~/Desktop/GRBGB_DO_sat_2023_clean_datetime_noTZ.xlsx'
# contpth <- '~/Desktop/GRBGB_DO_sat_2023_clean_datetime_UTC.xlsx'
# contpth <- '~/Desktop/Hobo_CND-DO_LoggerVers2.xlsx'
dqopth <- system.file("extdata/ExampleDQO.xlsx", package = "AquaSensR")
# dqopth <- '~/Desktop/ExampleDQO.xlsx'

# ------------------------------------------------------------------------------
# 2. Import data
# ------------------------------------------------------------------------------
contdat <- readASRcont(contpth)
dqodat <- readASRdqo(dqopth)

# Quick look at inputs
head(contdat)
head(dqodat)

# ------------------------------------------------------------------------------
# 3. Apply QC flags
# ------------------------------------------------------------------------------
# Change `param` to any parameter column present in contdat / dqodat
flagdat <- utilASRflag(contdat, dqodat, param = "Water_Temp_C")
flagdat <- utilASRflag(contdat, dqodat, param = "DO_adj_mg_l")

# Summary of flag results
head(flagdat)
table(flagdat$gross_flag)
table(flagdat$spike_flag)
table(flagdat$roc_flag)
table(flagdat$flat_flag)

# ------------------------------------------------------------------------------
# 4. Visualize flagged data
# ------------------------------------------------------------------------------
anlzASRflag(flagdat)

# ------------------------------------------------------------------------------
# 5. Edit flags in interactive Shiny app
#' Edit QC flags for a continuous monitoring parameter in an interactive Shiny app
cleaned <- editASRflag(contdat, dqodat)

# ------------------------------------------------------------------------------
# 6. Drift correction
# ------------------------------------------------------------------------------
# Apply a single drift correction to one parameter programmatically.
# cal_ref is the true value from an independent sonde at deployment end;
# cal_check is inferred automatically from the sensor data at drift_end_time.
t1 <- min(contdat$DateTime)
t2 <- max(contdat$DateTime)
corrected <- utilASRdrift(contdat, param = "Water_Temp_C", cal_ref = 26, t1, t2)

# Confirm the start value is unchanged and the end value equals cal_ref
corrected$Water_Temp_C[corrected$DateTime == t1] # should equal original
corrected$Water_Temp_C[corrected$DateTime == t2] # should equal 26

# view optional plot
corrected <- utilASRdrift(
  contdat,
  param = "Water_Temp_C",
  cal_ref = 26,
  t1,
  t2,
  plot = TRUE
)


# ------------------------------------------------------------------------------
# 7. Interactive drift correction app
# Interactive drift correction app — works parameter by parameter,
# returns list(contdat, corrections) on close
drift_result <- editASRdrift(contdat)
