library(testthat)

# ---------------------------------------------------------------------------
# Shared fixtures for utilASRflag / anlzASRflag tests
# ---------------------------------------------------------------------------

flag_n_obs <- 30L
flag_times <- as.POSIXct("2024-01-01 00:00:00", tz = "Etc/GMT+5") +
  seq(0L, by = 15L * 60L, length.out = flag_n_obs)

flag_make_cd <- function(site, vals) {
  df <- data.frame(Site = site, DateTime = flag_times, stringsAsFactors = FALSE)
  df[["Water Temp_C"]] <- vals
  df
}

flag_make_md <- function(site, ...) {
  base <- list(
    Site             = site,
    Parameter        = "Water Temp_C",
    Depth            = NA_real_,
    GrMinFail        = NA_real_,
    GrMaxFail        = NA_real_,
    GrMinSuspect     = NA_real_,
    GrMaxSuspect     = NA_real_,
    SpikeFail        = NA_real_,
    SpikeSuspect     = NA_real_,
    RoCN             = NA_real_,
    RoCHours         = NA_real_,
    FlatFailN        = NA_real_,
    FlatFailDelta    = NA_real_,
    FlatSuspectN     = NA_real_,
    FlatSuspectDelta = NA_real_
  )
  args <- list(...)
  base[names(args)] <- args
  as.data.frame(base, stringsAsFactors = FALSE)
}

# ---------------------------------------------------------------------------

tst <- list(
  # continuous data
  contpth = system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR'),
  contdatchk = suppressWarnings(readxl::read_excel(
    system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR'),
    na = c('NA', 'na', ''),
    guess_max = Inf
  )) |>
    dplyr::mutate(dplyr::across(
      dplyr::where(~ inherits(.x, "POSIXct") | inherits(.x, "Date")),
      as.character
    )),
  contdat = readASRcont(
    system.file('extdata/ExampleCont.xlsx', package = 'AquaSensR'),
    tz = 'Etc/GMT+5',
    runchk = F
  ),
  # continuous metadata
  metapth = system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR'),
  metadatchk = suppressWarnings(readxl::read_excel(
    system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR'),
    na = c('NA', 'na', ''),
    guess_max = Inf
  )),
  metadat = readASRmeta(
    system.file('extdata/ExampleMeta.xlsx', package = 'AquaSensR'),
    runchk = F
  )
)
