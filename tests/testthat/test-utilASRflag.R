# ---------------------------------------------------------------------------
# Output structure
# ---------------------------------------------------------------------------

test_that("utilASRflag returns correct structure and all-pass baseline", {
  cd <- flag_make_cd(rep(20, flag_n_obs))
  md <- flag_make_md()
  result <- utilASRflag(cd, md, "Water_Temp_C")

  expect_s3_class(result, "data.frame")
  expect_named(
    result,
    c(
      "DateTime",
      "Water_Temp_C",
      "gross_flag",
      "spike_flag",
      "roc_flag",
      "flat_flag"
    )
  )
  expect_equal(nrow(result), flag_n_obs)
  expect_true(all(result$gross_flag == "pass"))
  expect_true(all(result$spike_flag == "pass"))
  expect_true(all(result$roc_flag == "pass"))
  expect_true(all(result$flat_flag == "pass"))
})

# ---------------------------------------------------------------------------
# Input validation
# ---------------------------------------------------------------------------

test_that("utilASRflag errors on unrecognised parameter", {
  cd <- flag_make_cd(rep(20, flag_n_obs))
  md <- flag_make_md()
  expect_error(utilASRflag(cd, md, "Fake_Param"), "not a recognised parameter")
})

test_that("utilASRflag errors when param column missing from contdat", {
  cd <- flag_make_cd(rep(20, flag_n_obs))
  md <- flag_make_md()
  md[["Parameter"]] <- "pH_SU"
  expect_error(utilASRflag(cd, md, "pH_SU"), "column not found in contdat")
})

test_that("utilASRflag warns and returns all-pass when param not in dqodat", {
  cd <- flag_make_cd(rep(20, flag_n_obs))
  md <- flag_make_md()
  md[["Parameter"]] <- "pH_SU" # dqodat has no Water_Temp_C entry
  expect_warning(
    result <- utilASRflag(cd, md, "Water_Temp_C"),
    "No matching parameter in dqodat"
  )
  expect_true(all(result$gross_flag == "pass"))
  expect_true(all(result$spike_flag == "pass"))
  expect_true(all(result$roc_flag == "pass"))
  expect_true(all(result$flat_flag == "pass"))
})

# ---------------------------------------------------------------------------
# Gross range
# ---------------------------------------------------------------------------

test_that("utilASRflag gross_flag fires for suspect and fail on both bounds", {
  vals <- rep(20, flag_n_obs)
  vals[3] <- 1.5 # below GrMinSuspect = 2  -> suspect
  vals[7] <- -6.0 # below GrMinFail    = -5 -> fail
  vals[15] <- 31.0 # above GrMaxSuspect = 30 -> suspect
  vals[22] <- 36.0 # above GrMaxFail    = 35 -> fail

  cd <- flag_make_cd(vals)
  md <- flag_make_md(
    GrMinFail = -5,
    GrMaxFail = 35,
    GrMinSuspect = 2,
    GrMaxSuspect = 30
  )

  result <- utilASRflag(cd, md, "Water_Temp_C")

  expect_equal(result$gross_flag[3], "suspect")
  expect_equal(result$gross_flag[7], "fail")
  expect_equal(result$gross_flag[15], "suspect")
  expect_equal(result$gross_flag[22], "fail")
  expect_true(all(
    result$gross_flag[c(1:2, 4:6, 8:14, 16:21, 23:flag_n_obs)] == "pass"
  ))
  expect_true(all(result$spike_flag == "pass"))
  expect_true(all(result$roc_flag == "pass"))
  expect_true(all(result$flat_flag == "pass"))
})

# ---------------------------------------------------------------------------
# Spike
# ---------------------------------------------------------------------------

test_that("utilASRflag spike_flag fires for suspect and fail steps", {
  vals <- rep(20, flag_n_obs)
  vals[8] <- vals[7] + 5 # step >= SpikeSuspect = 4 -> suspect
  vals[20] <- vals[19] + 10 # step >= SpikeFail    = 8 -> fail

  cd <- flag_make_cd(vals)
  md <- flag_make_md(SpikeSuspect = 4, SpikeFail = 8)

  result <- utilASRflag(cd, md, "Water_Temp_C")

  expect_equal(result$spike_flag[8], "suspect")
  expect_equal(result$spike_flag[20], "fail")
  expect_true(all(result$gross_flag == "pass"))
  expect_true(all(result$roc_flag == "pass"))
  expect_true(all(result$flat_flag == "pass"))
})

# ---------------------------------------------------------------------------
# Rate of change
# ---------------------------------------------------------------------------

test_that("utilASRflag skips roc check when no Suspect row present", {
  vals <- c(rep(20, 19), rep(30, flag_n_obs - 19L)) # large level shift
  cd <- flag_make_cd(vals)
  md <- flag_make_md(RoCStDv = 4, RoCHours = 25)
  md <- md[md$Flag == "Fail", ] # drop Suspect row

  result <- utilASRflag(cd, md, "Water_Temp_C")
  expect_true(all(result$roc_flag == "pass"))
})

test_that("utilASRflag skips roc check when RoCStDv set but RoCHours is NA", {
  vals <- c(rep(20, 19), rep(30, flag_n_obs - 19L)) # large level shift
  cd <- flag_make_cd(vals)
  md <- flag_make_md(RoCStDv = 4) # RoCHours stays NA -> check skipped

  result <- utilASRflag(cd, md, "Water_Temp_C")
  expect_true(all(result$roc_flag == "pass"))
})

test_that("utilASRflag roc_flag fires at level shift in stable series", {
  # 19 obs at 20 then a level shift to 30 (step = 10).
  # At obs 20: window = obs 1-20, sd(c(rep(20, 19), 30)) = sqrt(5) ~ 2.236,
  # threshold = 2.236 * 4 = 8.944. |diff| = 10 > 8.944 -> suspect.
  # All subsequent diffs = 0 -> pass.
  vals <- c(rep(20, 19), rep(30, flag_n_obs - 19L))

  cd <- flag_make_cd(vals)
  md <- flag_make_md(RoCStDv = 4, RoCHours = 25)

  result <- utilASRflag(cd, md, "Water_Temp_C")

  expect_equal(result$roc_flag[20], "suspect")
  expect_true(all(result$roc_flag[-20] == "pass"))
  expect_true(all(result$gross_flag == "pass"))
  expect_true(all(result$spike_flag == "pass"))
  expect_true(all(result$flat_flag == "pass"))
})

# ---------------------------------------------------------------------------
# Flatline
# ---------------------------------------------------------------------------

test_that("utilASRflag flat_flag fires for suspect and fail run lengths", {
  # obs 1-9:   slowly increasing (diffs = 0.1 > delta -> run always resets)
  # obs 10:    25.0 (large boundary break)
  # obs 11-25: 20.0 (stuck sensor, 15 identical readings)
  #   rl[11] = 1 (boundary reset), rl[12] = 2, ..., rl[25] = 15
  #   FlatSuspectN = 5  -> suspect from obs 15
  #   FlatFailN   = 10  -> fail    from obs 20
  # obs 26-30: slowly increasing (run resets each step)
  vals <- c(
    seq(20.1, 20.9, by = 0.1),
    25.0,
    rep(20.0, 15),
    seq(20.1, 20.5, by = 0.1)
  )

  cd <- flag_make_cd(vals)
  md <- flag_make_md(
    FlatSuspectN = 5,
    FlatSuspectDelta = 0.02,
    FlatFailN = 10,
    FlatFailDelta = 0.02
  )

  result <- utilASRflag(cd, md, "Water_Temp_C")

  expect_true(all(result$flat_flag[15:19] == "suspect"))
  expect_true(all(result$flat_flag[20:25] == "fail"))
  expect_true(all(result$flat_flag[c(1:14, 26:flag_n_obs)] == "pass"))
  expect_true(all(result$gross_flag == "pass"))
  expect_true(all(result$spike_flag == "pass"))
  expect_true(all(result$roc_flag == "pass"))
})
