#' @keywords internal
check_anivis <- function() {
  rlang::check_installed(
    "anivis",
    reason = "to use check_confidence()",
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
