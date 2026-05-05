#' Check if an Excel file is open and execute a read function
#'
#' @param pth character string path to the Excel file
#' @param fn a zero-argument function that reads the file
#'
#' @details
#' First checks for lock files created by Excel (\code{~$filename}) and
#' LibreOffice (\code{.~lock.filename#}). If none are found, calls \code{fn()}
#' and catches the \code{utils::unzip} error that occurs when Excel holds an
#' OS-level lock without creating a local lock file (e.g. on OneDrive). Both
#' paths produce the same user-facing message.
#'
#' @returns The value returned by \code{fn()}.
#' @export
#'
#' @examples
#' contpth <- system.file('extdata/ExampleCont1.xlsx', package = 'AquaSensR')
#' utilASRopencheck(contpth, \() readxl::read_excel(contpth, n_max = 0))
utilASRopencheck <- function(pth, fn) {
  lock_files <- file.path(
    dirname(pth),
    c(
      paste0('~$', basename(pth)),           # Excel (Windows and Mac)
      paste0('.~lock.', basename(pth), '#')  # LibreOffice (any platform)
    )
  )
  if (any(file.exists(lock_files))) {
    stop(
      'The file ', basename(pth), ' appears to be open in another program. ',
      'Please close the file and try again.',
      call. = FALSE
    )
  }
  tryCatch(
    fn(),
    error = function(e) {
      if (grepl("cannot be opened", conditionMessage(e), fixed = TRUE))
        stop(
          'The file ', basename(pth), ' appears to be open in another program. ',
          'Please close the file and try again.',
          call. = FALSE
        )
      stop(e)
    }
  )
}
