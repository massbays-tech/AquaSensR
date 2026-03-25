# ===========================================================================
# demo_qc_checks.R
#
# Demonstrates each of the four QC checks implemented in AquaSensR using
# synthetic "Water Temp_C" time series.  Run interactively after
# devtools::load_all().
#
# One example per check:
#   1. Gross range  -- values outside absolute sensor limits
#   2. Spike        -- sudden large step between consecutive observations
#   3. Rate of change (RoC) -- step that exceeds rolling-SD * RoCN
#   4. Flatline     -- sensor stuck at a constant value
# ===========================================================================

devtools::load_all(".")

set.seed(42)

# 15-minute intervals over 5 days
n <- 5L * 24L * 4L # 480 observations
base_time <- as.POSIXct("2024-06-01 00:00:00", tz = "Etc/GMT+5")
times <- base_time + seq(0L, by = 15L * 60L, length.out = n)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build a minimal contdat frame
make_cd <- function(vals) {
  df <- data.frame(DateTime = times, stringsAsFactors = FALSE)
  df[["Water Temp_C"]] <- vals
  df
}

# Build a metadat row with all columns; supply only the thresholds you need
make_md <- function(...) {
  base <- list(
    Parameter = "Water Temp_C",
    GrMinFail = NA_real_,
    GrMaxFail = NA_real_,
    GrMinSuspect = NA_real_,
    GrMaxSuspect = NA_real_,
    SpikeFail = NA_real_,
    SpikeSuspect = NA_real_,
    RoCN = NA_real_,
    RoCHours = NA_real_,
    FlatFailN = NA_real_,
    FlatFailDelta = NA_real_,
    FlatSuspectN = NA_real_,
    FlatSuspectDelta = NA_real_
  )
  args <- list(...)
  base[names(args)] <- args
  as.data.frame(base, stringsAsFactors = FALSE)
}

# ===========================================================================
# 1.  GROSS RANGE
#
# Normal temps ~20 °C.  Four injected events:
#   obs 80-81  : suspect low  (1.5, 1.0 -- below GrMinSuspect = 2)
#   obs 160-161: fail low     (-5.5, -6 -- below GrMinFail = -5)
#   obs 280-281: suspect high (30.5, 31 -- above GrMaxSuspect = 30)
#   obs 380-381: fail high    (35.5, 36 -- above GrMaxFail = 35)
#
# Expected: suspect markers near the GrMinSuspect/GrMaxSuspect bounds,
#           fail markers at the extreme injections.
# ===========================================================================

v1 <- rnorm(n, mean = 20, sd = 0.4)
v1[c(80, 81)] <- c(1.5, 1.0) # suspect low
v1[c(160, 161)] <- c(-5.5, -6.0) # fail low
v1[c(280, 281)] <- c(30.5, 31.0) # suspect high
v1[c(380, 381)] <- c(35.5, 36.0) # fail high

cd1 <- make_cd(v1)
md1 <- make_md(
  GrMinFail = -5,
  GrMaxFail = 35,
  GrMinSuspect = 2,
  GrMaxSuspect = 30
)

fd1 <- utilASRflag(cd1, md1, "Water Temp_C")

# ===========================================================================
# 2.  SPIKE
#
# Normal temps ~20 °C with small noise (sd = 0.15).  Four injected blips:
#   obs 100: +5.5 step  (>= SpikeSuspect = 4)   -> suspect
#   obs 200: -5.5 step  (>= SpikeSuspect = 4)   -> suspect
#   obs 300: +9.5 step  (>= SpikeFail    = 8)   -> fail
#   obs 400: -9.5 step  (>= SpikeFail    = 8)   -> fail
#
# Each blip is a single anomalous observation that immediately returns to
# baseline.  Because the spike check compares every consecutive pair, each
# blip generates TWO flagged observations: the anomalous reading (large
# step up/down) and the next observation (equally large step back).
# Expect 8 flagged markers total (2 per blip × 4 blips).
# ===========================================================================

v2 <- rnorm(n, mean = 20, sd = 0.15)
v2[100] <- v2[99] + 5.5 # suspect upward
v2[200] <- v2[199] - 5.5 # suspect downward
v2[300] <- v2[299] + 9.5 # fail upward
v2[400] <- v2[399] - 9.5 # fail downward

cd2 <- make_cd(v2)
md2 <- make_md(SpikeSuspect = 4, SpikeFail = 8)

fd2 <- utilASRflag(cd2, md2, "Water Temp_C")

# ===========================================================================
# 3.  RATE OF CHANGE
#
# Series structure (all sd = 0.01 °C -- extremely stable):
#   obs   1-119: stable baseline at 20.0 °C
#   obs 120-359: shifted to 22.5 °C  (+2.5 °C level shift at obs 120)
#   obs 360-480: back to 20.0 °C     (-2.5 °C level shift at obs 360)
#
# RoCN = 8, RoCHours = 25 (trailing window = 100 obs at 15-min intervals).
#
# At each shift, the window SD is dominated by the 99 pre-shift values
# (~0.01 °C) plus the one outlier, giving window_SD ≈ 0.25 °C.
# Threshold = 0.25 * 8 ≈ 2.0 °C.  |diff| ≈ 2.5 >> 2.0 -> FLAGGED.
# Expect exactly 2 flagged observations (one at each level shift).
#
# No spurious flags: P(|diff| > window_SD * 8) for within-stable diffs
# follows N(0, 0.01*sqrt(2)), giving P(flag) ≈ 10^-7 per observation.
#
# ---------------------------------------------------------------------------
# HOW THIS DIFFERS FROM THE SPIKE CHECK
# ---------------------------------------------------------------------------
# Both checks catch sudden steps, but the threshold mechanism is different:
#
#   Spike : fixed absolute threshold (e.g., SpikeSuspect = 2.0 °C always).
#           Every step >= 2.0 °C is flagged, no matter how stable or noisy
#           the surrounding data is.
#
#   RoC   : adaptive threshold = SD_of_values_in_window * RoCN.
#           The threshold scales with local variability:
#             - Calm sensor (SD = 0.01 °C): threshold ≈ 0.08 °C in mid-run
#             - Sensor with diurnal cycle (SD = 0.5 °C): threshold ≈ 4.0 °C
#           A 2.5 °C step in the calm series here is flagged.
#           The SAME 2.5 °C step in a noisier series (SD = 0.5 °C) would
#           NOT be flagged by RoC (threshold = 4.0 °C > 2.5), but WOULD
#           still be flagged by spike if SpikeSuspect <= 2.5.
#
# In practice: use RoC when "suspicious" means "unusually large relative to
# recent variability"; use spike when any step above an absolute limit is
# always unacceptable regardless of context.
# ===========================================================================

v3 <- c(
  rnorm(119, mean = 20.0, sd = 0.01), # stable baseline
  rnorm(241, mean = 22.5, sd = 0.01), # shifted up +2.5 °C at obs 120
  rnorm(120, mean = 20.0, sd = 0.01) # shifted back down at obs 360
)

cd3 <- make_cd(v3)
md3 <- make_md(RoCN = 8, RoCHours = 25)

fd3 <- utilASRflag(cd3, md3, "Water Temp_C")

# ===========================================================================
# 4.  FLATLINE
#
# Normal temps ~20 °C (sd = 0.4).  Two "sensor stuck" periods:
#
#   obs 150-165 (16 obs): long flatline
#     - rl resets at obs 150 (boundary diff likely > FlatFailDelta)
#     - within-run |diff| = 0 <= FlatFailDelta = 0.02
#     - rl grows to 15 by obs 165
#     - FlatSuspectN = 5  -> suspect from obs 154 onward
#     - FlatFailN    = 10 -> fail    from obs 159 onward
#
#   obs 310-315 (6 obs): short flatline
#     - rl grows to 5 by obs 314
#     - FlatSuspectN = 5  -> suspect at obs 314-315
#     - FlatFailN    = 10 -> not reached
# ===========================================================================

v4 <- rnorm(n, mean = 20, sd = 0.4)
# ensure a clean break into the long stuck period
v4[149] <- 22.0 # force large boundary diff
v4[150:165] <- 20.00 # long stuck: 16 obs, run grows to 15

# ensure a clean break into the short stuck period
v4[309] <- 22.0
v4[310:315] <- 20.00 # short stuck: 6 obs, run grows to 5

cd4 <- make_cd(v4)
md4 <- make_md(
  FlatSuspectN = 5,
  FlatSuspectDelta = 0.02,
  FlatFailN = 10,
  FlatFailDelta = 0.02
)

fd4 <- utilASRflag(cd4, md4, "Water Temp_C")

# ===========================================================================
# Plots
# ===========================================================================

anlzASRflag(fd1) # gross range
anlzASRflag(fd2) # spike
anlzASRflag(fd3) # rate of change
anlzASRflag(fd4) # flatline
