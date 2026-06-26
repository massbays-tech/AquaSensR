# Retrieve USGS time series data for overlay in editASRflag

Downloads unit-value (continuous) data from the USGS Water Data API for
a given site and parameter over a specified date range. The result is a
two-column data frame compatible with the `overlay` argument of
[`anlzASRflag`](https://massbays-tech.github.io/AquaSensR/reference/anlzASRflag.md)
and the USGS Overlay feature in
[`editASRflag`](https://massbays-tech.github.io/AquaSensR/reference/editASRflag.md).

## Usage

``` r
readASRusgs(site, pcode, start, end, tz = "Etc/GMT+5")
```

## Arguments

- site:

  Character. USGS site number (typically 8 digits, e.g. `"01099500"`).
  Find site numbers using the NWIS Mapper at
  <https://apps.usgs.gov/nwismapper>.

- pcode:

  Character. Five-digit USGS parameter code. Common codes:

  `"00060"`

  :   Discharge / streamflow (ft\\^3\\/s)

  `"00065"`

  :   Gage height (ft)

  `"00045"`

  :   Precipitation (in)

  `"72019"`

  :   Groundwater depth (ft below land surface)

- start, end:

  Date range as `Date` objects or `"YYYY-MM-DD"` character strings.

- tz:

  Character. Time zone to which the returned `DateTime` column is
  converted. Defaults to `'Etc/GMT+5'` (Eastern Standard Time, no
  daylight saving), matching the default in
  [`readASRcont`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)
  and
  [`formASRcont`](https://massbays-tech.github.io/AquaSensR/reference/formASRcont.md).
  Pass the same value you used in
  [`readASRcont()`](https://massbays-tech.github.io/AquaSensR/reference/readASRcont.md)
  so the overlay aligns correctly with the primary time series in
  [`anlzASRflag`](https://massbays-tech.github.io/AquaSensR/reference/anlzASRflag.md)
  and
  [`editASRflag`](https://massbays-tech.github.io/AquaSensR/reference/editASRflag.md).
  See [`OlsonNames()`](https://rdrr.io/r/base/timezones.html) for valid
  strings.

## Value

A two-column data frame with columns `DateTime` (POSIXct, in the
timezone given by `tz`) and a second column whose name is a
human-readable label combining the parameter description and site number
(e.g. `"Streamflow (ft\u00b3/s) [01099500]"`). The data frame carries a
`"site_name"` attribute containing the station name, used by
[`editASRflag`](https://massbays-tech.github.io/AquaSensR/reference/editASRflag.md)
for the status message.

## Details

Data are fetched via
[`dataRetrieval::read_waterdata_continuous()`](https://rdrr.io/pkg/dataRetrieval/man/read_waterdata_continuous.html),
which targets the modern USGS Water Data API
(<https://api.waterdata.usgs.gov>). The API returns timestamps in UTC
and `readASRusgs()` re-expresses them in `tz` via
[`lubridate::with_tz()`](https://lubridate.tidyverse.org/reference/with_tz.html)
so the result aligns with `contdat` without shifting the underlying
moments in time.

The station name shown in the
[`editASRflag`](https://massbays-tech.github.io/AquaSensR/reference/editASRflag.md)
status line is retrieved with a second lightweight call to
[`dataRetrieval::read_waterdata_monitoring_location()`](https://rdrr.io/pkg/dataRetrieval/man/read_waterdata_monitoring_location.html).
If that call fails the site number is used as a fallback.

An error is raised if the site does not record the requested parameter,
if the date range returns no observations, or if the API is unreachable.

## Examples

``` r
if (FALSE) { # \dontrun{
# Fetch streamflow for the Concord R Below R Meadow Brook, at Lowell, MA
# 2024-01-01 to 2024-01-02
flow <- readASRusgs("01099500", "00060", "2024-01-01", "2024-01-02")
head(flow)
} # }
```
