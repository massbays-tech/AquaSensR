# Apply linear drift correction to a continuous monitoring parameter

Corrects for instrument drift over a specified window using a linear
interpolation approach. The correction at the start of the window is
zero and grows linearly to `cal_ref - cal_check` at the end, where
`cal_check` is inferred from the data as the sensor reading at
`drift_end_time`.

## Usage

``` r
utilASRdrift(
  cont,
  param,
  cal_ref,
  drift_start_time,
  drift_end_time,
  plot = FALSE
)
```

## Arguments

- cont:

  `contdat` data frame returned by
  [`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)

- param:

  character string naming the parameter column to correct

- cal_ref:

  numeric; the true or accepted value measured by an independent
  calibrated instrument at the end of the deployment period

- drift_start_time:

  start of the drift window (POSIXct or coercible)

- drift_end_time:

  end of the drift window (POSIXct or coercible)

- plot:

  logical; if `FALSE` (default) the corrected data frame is returned. If
  `TRUE` a plotly object is returned instead, showing the corrected time
  series (blue), the original values within the drift window (gray), and
  the reference value at the end of the window (red circle).

## Value

If `plot = FALSE`, a copy of `cont` with corrected values for `param` in
the drift window (values outside the window are unchanged). If
`plot = TRUE`, a `plotly` object.

## Details

The `cal_check` value (what the deployed sensor was actually reading at
`drift_end_time`) is inferred directly from the data, so only the
independent reference reading (`cal_ref`) needs to be supplied. The
total drift `cal_ref - cal_check` is distributed linearly across the
window: zero correction is applied at `drift_start_time` and the full
correction is applied at `drift_end_time`.

This correction formula is as follows: \$\$ \mathrm{adj} =
\mathrm{sensor} + (\mathrm{cal\\ref} - \mathrm{cal\\check}) \times
\frac{i - i\_{\min}}{i\_{\max} - i\_{\min}} \$\$

## Examples

``` r
contpth <- system.file("extdata/ExampleCont1.xlsx", package = "AquaSensR")
contdat <- readASRcont(contpth, runchk = FALSE)
t1 <- min(contdat$DateTime)
t2 <- max(contdat$DateTime)
utilASRdrift(contdat, "Water_Temp_C", cal_ref = 26, t1, t2)
#> # A tibble: 927 × 8
#>    DateTime            Water_Temp_C DO_pctsat DO_mg_l Conductivity_uS_cm
#>    <dttm>                     <dbl>     <dbl>   <dbl>              <dbl>
#>  1 2024-08-14 13:56:33         24.2      76.9    6.44               410.
#>  2 2024-08-14 13:56:43         24.2      76.7    6.43               410.
#>  3 2024-08-14 13:56:53         24.2      76.6    6.42               410.
#>  4 2024-08-14 13:57:03         24.2      76.5    6.41               410.
#>  5 2024-08-14 13:57:13         24.2      76.3    6.4                409 
#>  6 2024-08-14 13:57:23         24.2      76.3    6.39               409.
#>  7 2024-08-14 13:57:33         24.2      76.2    6.39               409.
#>  8 2024-08-14 13:57:43         24.2      76.1    6.38               409.
#>  9 2024-08-14 13:57:53         24.2      76.5    6.41               404.
#> 10 2024-08-14 13:58:03         24.2      77.6    6.5                399.
#> # ℹ 917 more rows
#> # ℹ 3 more variables: TDS_mg_l <dbl>, Salinity_ppt <dbl>, pH_SU <dbl>
```
