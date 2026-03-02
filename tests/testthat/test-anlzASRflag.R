# ---------------------------------------------------------------------------
# Single site
# ---------------------------------------------------------------------------

test_that("anlzASRflag returns a plotly object for a single site (all pass)", {
  cd     <- flag_make_cd("SiteA", rep(20, flag_n_obs))
  md     <- flag_make_md("SiteA")
  fd     <- utilASRflag(cd, md, "Water Temp_C")
  result <- anlzASRflag(fd)
  expect_s3_class(result, "plotly")
})

test_that("anlzASRflag returns a plotly object for a single site with flags", {
  # Exercises the add_trace branch (suspect + fail traces added) and the
  # `next` branch (spike/roc/flat have no flagged obs -> skipped)
  vals     <- rep(20, flag_n_obs)
  vals[5]  <- 31    # gross suspect (> GrMaxSuspect = 30)
  vals[10] <- 36    # gross fail    (> GrMaxFail    = 35)

  cd     <- flag_make_cd("SiteA", vals)
  md     <- flag_make_md("SiteA", GrMinSuspect = 2, GrMaxSuspect = 30,
                         GrMinFail = -5, GrMaxFail = 35)
  fd     <- utilASRflag(cd, md, "Water Temp_C")
  result <- anlzASRflag(fd)
  expect_s3_class(result, "plotly")
})

# ---------------------------------------------------------------------------
# Multiple sites
# ---------------------------------------------------------------------------

test_that("anlzASRflag returns a plotly object for multiple sites", {
  # Exercises the subplot branch and the show_legend = FALSE path
  # for the second site panel
  vals_a     <- rep(20, flag_n_obs)
  vals_b     <- rep(20, flag_n_obs)
  vals_a[5]  <- 36   # gross fail on SiteA
  vals_b[15] <- 36   # gross fail on SiteB

  cd <- rbind(flag_make_cd("SiteA", vals_a), flag_make_cd("SiteB", vals_b))
  md <- rbind(flag_make_md("SiteA", GrMaxFail = 35),
              flag_make_md("SiteB", GrMaxFail = 35))
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
  cd      <- flag_make_cd("SiteA", vals)
  md      <- flag_make_md("SiteA", GrMaxFail = 35)
  fd      <- utilASRflag(cd, md, "Water Temp_C")
  expect_no_message(anlzASRflag(fd))
})
