#' Import continuous monitoring data from an Excel file
#'
#' @param contpth character string of path to the continuous data file
#'
#' @details
#' Reads an Excel workbook and returns a data frame with \code{Date},
#' \code{Time}, and \code{DateTime} columns preserved as character strings,
#' with Excel numeric representations converted to human-readable text:
#'
#' \itemize{
#'   \item \strong{Date}: integer-like strings (Excel date serial numbers,
#'     e.g. \code{"45518"}) are converted to \code{yyyy-mm-dd} using Excel's
#'     origin of 1899-12-30.
#'   \item \strong{Time}: decimal fraction strings between 0 and 1 (Excel time
#'     fractions, e.g. \code{"0.58105"}) are converted to \code{HH:MM:SS}.
#'   \item \strong{DateTime}: numeric strings with an integer part (Excel
#'     datetime serials, e.g. \code{"45518.58105"}) are converted to
#'     \code{yyyy-mm-dd HH:MM:SS}.
#'   \item Text values in any of these columns (e.g. \code{"2024-08-14"},
#'     \code{"4:30:33 PM"}) are left unchanged.
#' }
#'
#' This function is called internally by \code{\link{readASRcont}} and can also
#' be used to prepare data for manual use with \code{\link{checkASRcont}} or
#' \code{\link{formASRcont}}.
#'
#' @returns A data frame with date/time columns as character strings and all
#'   other columns type-guessed by \code{readxl}.
#' @export
#'
#' @examples
#' contpth <- system.file('extdata/ExampleCont1.xlsx', package = 'AquaSensR')
#'
#' utilASRimportcont(contpth)
utilASRimportcont <- function(contpth) {
  lock_files <- file.path(
    dirname(contpth),
    c(
      paste0('~$', basename(contpth)),           # Excel (Windows and Mac)
      paste0('.~lock.', basename(contpth), '#')  # LibreOffice (any platform)
    )
  )
  if (any(file.exists(lock_files))) {
    stop(
      'The file ', basename(contpth), ' appears to be open in another program. ',
      'Please close the file and try again.',
      call. = FALSE
    )
  }

  nms <- names(readxl::read_excel(contpth, n_max = 0))
  col_types <- ifelse(nms %in% c("Date", "Time", "DateTime"), "text", "guess")

  suppressWarnings(readxl::read_excel(
    contpth,
    col_types = col_types,
    na = c('NA', 'na', ''),
    guess_max = Inf
  )) |>
    # convert Excel serial date integers to yyyy-mm-dd strings
    dplyr::mutate(dplyr::across(
      dplyr::any_of("Date"),
      ~ dplyr::if_else(
        grepl('^\\d+$', .x),
        as.character(as.Date(
          suppressWarnings(as.integer(.x)),
          origin = '1899-12-30'
        )),
        .x
      )
    )) |>
    # convert Excel time fractions (0.xxxx) to HH:MM:SS strings
    dplyr::mutate(dplyr::across(
      dplyr::any_of("Time"),
      ~ dplyr::if_else(
        {
          num_val <- suppressWarnings(as.numeric(.x))
          !is.na(num_val) & num_val >= 0 & num_val < 1
        },
        {
          secs <- round(suppressWarnings(as.numeric(.x)) * 86400)
          sprintf(
            '%02d:%02d:%02d',
            secs %/% 3600L,
            (secs %% 3600L) %/% 60L,
            secs %% 60L
          )
        },
        .x
      )
    )) |>
    # convert Excel datetime serials (ddddd or ddddd.xxxx) to yyyy-mm-dd HH:MM:SS strings
    dplyr::mutate(dplyr::across(
      dplyr::any_of("DateTime"),
      ~ dplyr::if_else(
        grepl('^\\d+\\.?\\d*$', .x),
        format(
          as.POSIXct(
            suppressWarnings(as.numeric(.x)) * 86400,
            origin = '1899-12-30',
            tz = 'UTC'
          ),
          '%Y-%m-%d %H:%M:%S'
        ),
        .x
      )
    ))
}
