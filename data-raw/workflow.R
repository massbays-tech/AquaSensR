# AquaSensR QC Workflow
# Imports continuous data and data quality objectives, applies QC flags, and visualizes results

library(AquaSensR)

# ------------------------------------------------------------------------------
# 1. File paths
# ------------------------------------------------------------------------------
# Replace with paths to your own files, or use the package example data:
# contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
# contpth <- system.file("extdata/ExampleCont2.xlsx", package = "AquaSensR")
# contpth <- '~/Desktop/RVM-018 2022-07-25_2022-08-31_cond_vers2.xlsx'
# contpth <- '~/Desktop/GRBGB_DO_sat_2023_clean_datetime_noTZ.xlsx'
# contpth <- '~/Desktop/GRBGB_DO_sat_2023_clean_datetime_UTC.xlsx'
contpth <- '~/Desktop/Hobo_CND-DO_LoggerVers2.xlsx'
# dqopth <- system.file("extdata/ExampleDQO.xlsx", package = "AquaSensR")
dqopth <- '~/Desktop/ExampleDQO.xlsx'

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
