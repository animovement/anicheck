#' Ensure anivis is available for plotting
#'
#' Internal helper used by the `plot.check_*()` stubs: the diagnostic plots live
#' in the companion \pkg{anivis} package, so this prompts the user to install it
#' (from the animovement R-universe) when it is missing before the plot is drawn.
#'
#' @param version The minimum anivis version the plot needs, or `NULL` (the
#'   default) for any. A check whose plot method arrived in a later anivis
#'   than the others names that version, so an older installation is updated
#'   rather than handing the check to a plot method that is not there.
#'
#' @return Called for its side effect; returns invisibly.
#' @keywords internal
# nocov start - install prompt; exercised interactively, not in the test suite.
check_anivis <- function(version = NULL) {
  rlang::check_installed(
    "anivis",
    version = version,
    reason = "to visualise checks",
    action = function(...) {
      utils::install.packages(
        'anivis',
        repos = c(
          'https://animovement.r-universe.dev',
          'https://cloud.r-project.org'
        )
      )
    }
  )
}
# nocov end
