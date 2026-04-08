library(testthat)

# ---------------------------------------------------------------------------
# Shared fixtures for utilASRflag / anlzASRflag tests
# ---------------------------------------------------------------------------

flag_n_obs <- 30L
flag_times <- as.POSIXct("2024-01-01 00:00:00", tz = "Etc/GMT+5") +
  seq(0L, by = 15L * 60L, length.out = flag_n_obs)

flag_make_cd <- function(vals) {
  df <- data.frame(DateTime = flag_times, stringsAsFactors = FALSE)
  df[["Water_Temp_C"]] <- vals
  df
}

flag_make_md <- function(
  GrMinFail = NA_real_,
  GrMaxFail = NA_real_,
  GrMinSuspect = NA_real_,
  GrMaxSuspect = NA_real_,
  SpikeFail = NA_real_,
  SpikeSuspect = NA_real_,
  RoCStDv = NA_real_,
  RoCHours = NA_real_,
  FlatFailN = NA_real_,
  FlatFailDelta = NA_real_,
  FlatSuspectN = NA_real_,
  FlatSuspectDelta = NA_real_
) {
  rbind(
    data.frame(
      Parameter = "Water_Temp_C",
      Flag = "Fail",
      GrMin = GrMinFail,
      GrMax = GrMaxFail,
      Spike = SpikeFail,
      FlatN = FlatFailN,
      FlatDelta = FlatFailDelta,
      RoCStDv = NA_real_,
      RoCHours = NA_real_,
      stringsAsFactors = FALSE
    ),
    data.frame(
      Parameter = "Water_Temp_C",
      Flag = "Suspect",
      GrMin = GrMinSuspect,
      GrMax = GrMaxSuspect,
      Spike = SpikeSuspect,
      FlatN = FlatSuspectN,
      FlatDelta = FlatSuspectDelta,
      RoCStDv = RoCStDv,
      RoCHours = RoCHours,
      stringsAsFactors = FALSE
    )
  )
}

# ---------------------------------------------------------------------------

tst <- list(
  # continuous data - separate Date/Time format (ExampleCont1)
  contpth = system.file('extdata/ExampleCont1.xlsx', package = 'AquaSensR'),
  contdatchk = utilASRimportcont(
    system.file('extdata/ExampleCont1.xlsx', package = 'AquaSensR')
  ),
  contdat = readASRcont(
    system.file('extdata/ExampleCont1.xlsx', package = 'AquaSensR'),
    runchk = F
  ),
  # continuous data - combined DateTime format (ExampleCont2)
  contpth2 = system.file('extdata/ExampleCont2.xlsx', package = 'AquaSensR'),
  contdatchk2 = utilASRimportcont(
    system.file('extdata/ExampleCont2.xlsx', package = 'AquaSensR')
  ),
  contdat2 = readASRcont(
    system.file('extdata/ExampleCont2.xlsx', package = 'AquaSensR'),
    runchk = F
  ),
  # data quality objectives
  dqopth = system.file('extdata/ExampleDQO.xlsx', package = 'AquaSensR'),
  dqodatchk = suppressWarnings(readxl::read_excel(
    system.file('extdata/ExampleDQO.xlsx', package = 'AquaSensR'),
    na = c('NA', 'na', ''),
    guess_max = Inf
  )),
  dqodat = readASRdqo(
    system.file('extdata/ExampleDQO.xlsx', package = 'AquaSensR'),
    runchk = F
  )
)
