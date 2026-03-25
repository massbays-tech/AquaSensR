# ---------------------------------------------------------------------------
# Basic output
# ---------------------------------------------------------------------------

test_that("anlzASRflag returns a plotly object for all-pass data", {
  cd     <- flag_make_cd(rep(20, flag_n_obs))
  md     <- flag_make_md()
  fd     <- utilASRflag(cd, md, "Water Temp_C")
  result <- anlzASRflag(fd)
  expect_s3_class(result, "plotly")
})

test_that("anlzASRflag returns a plotly object with flags present", {
  # Exercises the add_trace branch (suspect + fail traces added) and the
  # `next` branch (spike/roc/flat have no flagged obs -> skipped)
  vals     <- rep(20, flag_n_obs)
  vals[5]  <- 31    # gross suspect (> GrMaxSuspect = 30)
  vals[10] <- 36    # gross fail    (> GrMaxFail    = 35)

  cd     <- flag_make_cd(vals)
  md     <- flag_make_md(GrMinSuspect = 2, GrMaxSuspect = 30,
                         GrMinFail = -5, GrMaxFail = 35)
  fd     <- utilASRflag(cd, md, "Water Temp_C")
  result <- anlzASRflag(fd)
  expect_s3_class(result, "plotly")
})

# ---------------------------------------------------------------------------
# No console noise
# ---------------------------------------------------------------------------

test_that("anlzASRflag produces no messages during construction", {
  # Confirms the inherit = FALSE fix: marker traces no longer inherit the
  # line object from the base trace, so plotly emits no warnings
  vals    <- rep(20, flag_n_obs)
  vals[5] <- 36
  cd      <- flag_make_cd(vals)
  md      <- flag_make_md(GrMaxFail = 35)
  fd      <- utilASRflag(cd, md, "Water Temp_C")
  expect_no_message(anlzASRflag(fd))
})
