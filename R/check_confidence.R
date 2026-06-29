#' Check the Distribution of Tracking Confidence
#'
#' Summarises the per-frame tracking `confidence` (or likelihood) of each
#' keypoint. A keypoint with a low median or a long low tail is one the tracker
#' was often unsure about — exactly the points whose coordinates deserve
#' suspicion. This check reduces the confidence column to a per-keypoint
#' distribution, and [plot.check_confidence()] draws it as a violin.
#'
#' The distribution is reduced to a compact kernel-density estimate (a fixed-size
#' grid) per keypoint, plus a five-number summary, so the object stays small
#' however long the recording — the violin is drawn straight from the stored
#' density.
#'
#' This is the data-generating half of the check. The plotting method
#' ([plot.check_confidence()]) lives in \pkg{anivis}, mirroring the
#' \pkg{performance} / \pkg{see} split in easystats. (`check_*()` functions are
#' destined for the \pkg{anicheck} package; they are kept here for now for
#' convenience.)
#'
#' @param data An aniframe object with a `confidence` column.
#' @param n Density grid resolution per keypoint. Default `256`.
#' @param ... Additional arguments (currently unused).
#'
#' @return A data frame of class `check_confidence` with one row per
#'   (keypoint, density grid point): the identity columns, the confidence
#'   `value`, and its kernel `density`. A per-keypoint five-number summary (with
#'   `n`, `mean`, `sd`) and the grouping columns are stored as attributes. Use
#'   [summary()] for a trimmed overview.
#'
#' @seealso [plot.check_confidence()]
#'
#' @examples
#' af <- aniframe::as_aniframe(data.frame(
#'   keypoint = rep(c("head", "tail"), each = 50),
#'   time = rep(1:50, 2),
#'   x = rnorm(100),
#'   y = rnorm(100)
#' ))
#' af$confidence <- c(rbeta(50, 8, 2), rbeta(50, 2, 5))
#' check_confidence(af)
#'
#' @export
check_confidence <- function(data, ...) {
  UseMethod("check_confidence")
}

#' @rdname check_confidence
#' @export
check_confidence.default <- function(data, ...) {
  cli::cli_abort("{.arg data} must be an aniframe.")
}

#' @rdname check_confidence
#' @export
check_confidence.aniframe <- function(data, n = 256, ...) {
  if (!("confidence" %in% names(data))) {
    cli::cli_abort(
      "{.fun check_confidence} needs a {.field confidence} column."
    )
  }
  group_cols <- aniframe_group_cols(data)

  df <- as.data.frame(data)
  parts <- split_by_group_cols(df, group_cols)
  grid <- do.call(
    rbind,
    lapply(parts, confidence_density, group_cols = group_cols, n = n)
  )
  rownames(grid) <- NULL

  new_check_confidence(
    grid,
    group_cols = group_cols,
    groups = distribution_summary(df, group_cols, "confidence")
  )
}

# Internal: kernel-density grid of one keypoint's confidence values, clipped to
# the observed range. Degenerate groups (fewer than two distinct values) collapse
# to a one-point spike so the violin still draws.
confidence_density <- function(d, group_cols, n) {
  v <- d$confidence[!is.na(d$confidence)]
  if (length(v) >= 2L && diff(range(v)) > 0) {
    dens <- stats::density(v, from = min(v), to = max(v), n = n)
    out <- data.frame(value = dens$x, density = dens$y)
  } else {
    val <- if (length(v)) v[1] else NA_real_
    out <- data.frame(value = c(val, val), density = c(0, 1))
  }
  for (col in group_cols) {
    out[[col]] <- d[[col]][1]
  }
  out[c(group_cols, "value", "density")]
}

# Internal: low-level constructor.
new_check_confidence <- function(x, group_cols, groups) {
  class(x) <- c(
    "check_confidence",
    "anivis_check_confidence",
    "tbl_df",
    "tbl",
    "data.frame"
  )
  attr(x, "group_cols") <- group_cols
  attr(x, "groups") <- groups
  x
}

#' Summarise a Confidence Check
#'
#' Trims a [check_confidence()] object to the headline statistics per keypoint:
#' count, median, inter-quartile range, and minimum (the worst case). The
#' print-side mirror of [anivis::as_plot_data()].
#'
#' @param object A `check_confidence` object.
#' @param ... Additional arguments (currently unused).
#'
#' @return A data frame with one row per keypoint (per identity).
#'
#' @seealso [check_confidence()]
#' @export
summary.check_confidence <- function(object, ...) {
  group_cols <- attr(object, "group_cols")
  groups <- attr(object, "groups")
  out <- groups[c(group_cols, "n", "median", "q25", "q75", "min")]
  out$iqr <- out$q75 - out$q25
  rownames(out) <- NULL
  out[c(group_cols, "n", "median", "iqr", "min")]
}

#' @export
print.check_confidence <- function(x, ...) {
  group_cols <- attr(x, "group_cols")
  s <- summary(x)

  cli::cli_h3("Check: tracking confidence")
  cli::cli_text(
    "Confidence for {nrow(s)} keypoint{?s} (median [min]):"
  )
  labels <- if (length(group_cols)) {
    do.call(
      paste,
      c(lapply(group_cols, function(col) as.character(s[[col]])), sep = " | ")
    )
  } else {
    "all"
  }
  cli::cli_ul(sprintf("%s: %.2f [%.2f]", labels, s$median, s$min))
  invisible(x)
}
