#' Ensure anivis is available for plotting
#'
#' Internal helper used by the `plot.check_*()` stubs: the diagnostic plots live
#' in the companion \pkg{anivis} package, so this prompts the user to install it
#' (from the animovement R-universe) when it is missing before the plot is drawn.
#'
#' @return Called for its side effect; returns invisibly.
#' @keywords internal
# nocov start - install prompt; exercised interactively, not in the test suite.
check_anivis <- function() {
  rlang::check_installed(
    "anivis",
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
