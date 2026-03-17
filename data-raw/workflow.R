# AquaSensR QC Workflow
# Imports continuous and metadata, applies QC flags, and visualizes results

library(AquaSensR)

# ------------------------------------------------------------------------------
# 1. File paths
# ------------------------------------------------------------------------------
# Replace with paths to your own files, or use the package example data:
contpth <- system.file("extdata/ExampleCont.xlsx", package = "AquaSensR")
metapth <- system.file("extdata/ExampleMeta.xlsx", package = "AquaSensR")

# ------------------------------------------------------------------------------
# 2. Import data
# ------------------------------------------------------------------------------
contdat <- readASRcont(contpth, tz = "Etc/GMT+5")
metadat <- readASRmeta(metapth)

# Quick look at inputs
head(contdat)
head(metadat)

# ------------------------------------------------------------------------------
# 3. Apply QC flags
# ------------------------------------------------------------------------------
# Change `param` to any parameter column present in contdat / metadat
flagdat <- utilASRflag(contdat, metadat, param = "Water Temp_C")

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
