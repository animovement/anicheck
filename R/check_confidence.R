#' Visualize the Distribution of Confidence Values per Keypoint
#'
#' `check_confidence()` computes summary statistics for confidence values
#' grouped by a chosen variable (defaulting to `keypoint`) and returns a
#' tidy data frame that can be visualized with standard plotting functions.
#'
#' @param data A data frame that contains at least the columns
#'   `keypoint` and `confidence`. Additional grouping variables can be
#'   supplied via the `by` argument.
#' @param by   (Optional) A character vector or column name(s) used to
#'   group the data before summarising. If `NULL`, the function defaults to
#'   `"keypoint"`.
#' @param ... Arguments passed down to the plotting functions.
#'
#' @return A tibble/data frame with one row per group defined by `by`,
#'   containing the following columns:
#'   \describe{
#'     \item{mean_confidence}{Mean of `confidence` within the group (NA‑removed).}
#'     \item{q1}{First quartile (25th percentile) of `confidence`.}
#'     \item{q3}{Third quartile (75th percentile) of `confidence`.}
#'   }
#'   The result can be passed directly to `ggplot2` or other visualization
#'   packages.
#'
#' @export
check_confidence <- function(data, ...) {
  UseMethod("check_confidence")
}

# default ----------------------------

#' @rdname check_confidence
#' @export
check_confidence.default <- function(
  data,
  by = NULL,
  ...
) {
  if (!aniframe::is_aniframe(data)) {
    cli::cli_abort("Data is not an aniframe.")
  }

  if (is.null(by)) {
    by <- "keypoint"
  }
  summarised_data <- data |>
    dplyr::ungroup() |>
    dplyr::summarise(
      conf_median = stats::median(.data$confidence, na.rm = TRUE),
      conf_q1 = stats::quantile(.data$confidence, probs = 0.25),
      conf_q3 = stats::quantile(.data$confidence, probs = 0.75),
      conf_min = min(.data$confidence, na.rm = TRUE),
      conf_max = max(.data$confidence, na.rm = TRUE),
      .by = by
    ) |>
    suppressWarnings()

  class(summarised_data) <- c(
    "check_confidence",
    "plot_check_confidence",
    "data.frame"
  )
  summarised_data
}

# methods ----------------------------------

#' @export
print.check_confidence <- function(x, ...) {
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
  NextMethod()
}

#' @export
plot.check_confidence <- function(x, ...) {
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
  NextMethod()
}
