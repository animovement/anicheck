#' Check the Timing of Missing Values
#'
#' Finds the runs of consecutive missing values (`NA`) in an aniframe and
#' returns them as a compact table - **one row per gap**, not per frame. Where
#' the gaps fall (at the start, the end, scattered, or in long bursts) is often
#' more telling than how many there are; this check exposes that timing, and
#' [plot.check_na_timing()] draws it as a missingness strip.
#'
#' Returning gaps rather than per-frame rows keeps the object (and any plot built
#' from it) tiny even for million-frame recordings: its size scales with the
#' number of gaps, not the length of the data.
#'
#' This is the data-generating half of the check. The plotting method
#' ([plot.check_na_timing()]) lives in \pkg{anivis}, mirroring the
#' \pkg{performance} / \pkg{see} split in easystats: `check_*()` computes a
#' classed object with `summary()` / `print()` methods, and a `plot.*()` method
#' in the companion package draws it. (`check_*()` functions are destined for the
#' \pkg{anicheck} package; they are kept here for now for convenience.)
#'
#' @param data An aniframe object.
#' @param variable Name(s) of the column(s) whose missingness to track. A frame
#'   counts as missing when *any* named column is `NA` there. Defaults to
#'   `"x"`.
#' @param ... Additional arguments (currently unused).
#'
#' @return A data frame of class `check_na_timing` with one row per missing run:
#'   the aniframe's grouping columns (every `variables_what` and non-time
#'   `variables_when` column), the run's `start` and `stop` time, and its
#'   `length` in frames. Per-group totals (frame and missing counts, time
#'   range), the checked variable(s), the time unit, and the typical time step
#'   are stored as attributes for the `summary()`, `print()`, and plotting
#'   methods. Use [summary()] for a per-group overview.
#'
#' @seealso [plot.check_na_timing()], [summary.check_na_timing()]
#'
#' @examples
#' af <- anicore::as_aniframe(data.frame(
#'   keypoint = rep(c("head", "tail"), each = 6),
#'   time = rep(1:6, 2),
#'   x = c(1, NA, NA, 4, 5, 6, 1, 2, 3, 4, 5, 6)
#' ))
#' check_na_timing(af)
#' summary(check_na_timing(af))
#'
#' @export
check_na_timing <- function(data, ...) {
  UseMethod("check_na_timing")
}

#' @rdname check_na_timing
#' @export
check_na_timing.default <- function(data, ...) {
  cli::cli_abort("{.arg data} must be an aniframe.")
}

#' @rdname check_na_timing
#' @export
check_na_timing.aniframe <- function(data, variable = "x", ...) {
  variable <- check_na_variable(data, variable)
  meta <- anicore::get_metadata(data)
  group_cols <- aniframe_group_cols(data)
  decl <- aniframe_declarations(data)

  df <- as.data.frame(data)
  df$.missing <- Reduce(`|`, lapply(variable, function(v) is.na(df[[v]])))

  parts <- split_by_group_cols(df, group_cols)
  segments <- do.call(
    rbind,
    lapply(parts, na_timing_runs, group_cols = group_cols)
  )
  if (is.null(segments)) {
    segments <- empty_segments(group_cols)
  }
  rownames(segments) <- NULL

  groups <- do.call(
    rbind,
    lapply(parts, na_timing_totals, group_cols = group_cols)
  )
  rownames(groups) <- NULL

  new_check_na_timing(
    segments,
    variable = variable,
    unit_time = if (!is.null(meta$unit_time)) {
      as.character(meta$unit_time)
    } else {
      NA_character_
    },
    group_cols = group_cols,
    variables_what = decl$variables_what,
    variables_when = decl$variables_when,
    groups = groups,
    time_step = na_timing_step(parts),
    time_range = c(min(df$time), max(df$time))
  )
}

# Internal: low-level constructor. Tags the data frame with the check class (so
# the summary / print / plot methods dispatch) and stashes the per-group totals
# and time metadata the downstream methods need as attributes. The tbl_df / tbl
# classes make the (small) gap table print as a tibble if the check class is
# ever stripped; print.check_na_timing() handles the normal summary view.
new_check_na_timing <- function(
  x,
  variable,
  unit_time,
  group_cols,
  groups,
  time_step,
  time_range,
  variables_what = character(),
  variables_when = character()
) {
  class(x) <- c(
    "check_na_timing",
    "anivis_check_na_timing",
    "tbl_df",
    "tbl",
    "data.frame"
  )
  attr(x, "variable") <- variable
  attr(x, "unit_time") <- unit_time
  attr(x, "group_cols") <- group_cols
  attr(x, "variables_what") <- variables_what
  attr(x, "variables_when") <- variables_when
  attr(x, "groups") <- groups
  attr(x, "time_step") <- time_step
  attr(x, "time_range") <- time_range
  x
}

# (split_by_group_cols(), group_key() and check_na_variable() live in
# check_helpers.R, shared across the check_* family.)

# Internal: run-length-encode .missing within one (time-ordered) group and emit
# one row per missing run: the group columns, the run's start/stop time, and its
# length in frames. Returns NULL when the group has no missing values.
na_timing_runs <- function(d, group_cols) {
  d <- d[order(d$time), , drop = FALSE]
  runs <- rle(d$.missing)
  ends <- cumsum(runs$lengths)
  starts <- ends - runs$lengths + 1L
  keep <- which(runs$values)
  if (!length(keep)) {
    return(NULL)
  }
  out <- data.frame(
    start = d$time[starts[keep]],
    stop = d$time[ends[keep]],
    length = runs$lengths[keep]
  )
  for (col in group_cols) {
    out[[col]] <- d[[col]][1]
  }
  out[c(group_cols, "start", "stop", "length")]
}

# Internal: per-group totals used for percentages and the plot's x extent.
na_timing_totals <- function(d, group_cols) {
  out <- data.frame(
    n_frames = nrow(d),
    n_missing = sum(d$.missing),
    time_min = min(d$time),
    time_max = max(d$time)
  )
  for (col in group_cols) {
    out[[col]] <- d[[col]][1]
  }
  out[c(group_cols, "n_frames", "n_missing", "time_min", "time_max")]
}

# Internal: typical spacing between frames, taken as the median time step within
# groups. Used to give single-frame gaps a visible width when plotting. Falls
# back to 1 when it cannot be estimated (e.g. one frame per group).
na_timing_step <- function(parts) {
  steps <- unlist(
    lapply(parts, function(d) diff(sort(d$time))),
    use.names = FALSE
  )
  if (!length(steps)) {
    return(1)
  }
  step <- stats::median(steps)
  if (is.na(step) || step <= 0) 1 else step
}

# Internal: a correctly-typed zero-row gap table (for data with no NAs at all).
empty_segments <- function(group_cols) {
  cols <- c(
    stats::setNames(rep(list(character(0)), length(group_cols)), group_cols),
    list(start = numeric(0), stop = numeric(0), length = integer(0))
  )
  do.call(data.frame, c(cols, stringsAsFactors = FALSE))
}

#' Summarise a Missing-Value Timing Check
#'
#' Reduces a [check_na_timing()] object to a per-group overview table: frame and
#' missing counts, the percentage missing, the number of gaps, and the longest
#' gap. This is the print-side mirror of anivis's `as_plot_data()` - a compact
#' table for
#' the console or a report, rather than for a geom.
#'
#' @param object A `check_na_timing` object.
#' @param ... Additional arguments (currently unused).
#'
#' @return A data frame with one row per group.
#'
#' @seealso [check_na_timing()]
#' @keywords internal
#' @export
summary.check_na_timing <- function(object, ...) {
  group_cols <- attr(object, "group_cols")
  groups <- attr(object, "groups")

  gkey <- group_key(groups, group_cols)
  skey <- group_key(object, group_cols)
  lengths_by <- split(object$length, factor(skey, levels = gkey))

  out <- groups
  out$pct_missing <- ifelse(
    out$n_frames > 0,
    round(100 * out$n_missing / out$n_frames, 1),
    0
  )
  out$n_gaps <- vapply(lengths_by, length, integer(1))
  out$longest_gap <- vapply(
    lengths_by,
    function(l) if (length(l)) max(l) else 0L,
    integer(1)
  )
  rownames(out) <- NULL
  out[c(
    group_cols,
    "n_frames",
    "n_missing",
    "pct_missing",
    "n_gaps",
    "longest_gap"
  )]
}

#' @export
print.check_na_timing <- function(x, ...) {
  variable <- attr(x, "variable")
  group_cols <- attr(x, "group_cols")
  s <- summary(x)

  total <- sum(s$n_frames)
  n_missing <- sum(s$n_missing)
  n_gaps <- sum(s$n_gaps)
  pct <- if (total) round(100 * n_missing / total, 1) else 0

  cli::cli_h3("Check: timing of missing values")
  cli::cli_text(
    "Tracking {.field {variable}} across {total} frame{?s} -
     {n_missing} missing ({pct}%) in {n_gaps} gap{?s}."
  )

  if (length(group_cols) && nrow(s) > 1L) {
    labels <- do.call(
      paste,
      c(lapply(group_cols, function(col) as.character(s[[col]])), sep = " | ")
    )
    cli::cli_text("By group ({.field {group_cols}}):")
    cli::cli_ul(sprintf(
      "%s: %s%% missing in %d gap%s (longest %d)",
      labels,
      s$pct_missing,
      s$n_gaps,
      ifelse(s$n_gaps == 1L, "", "s"),
      s$longest_gap
    ))
  }

  invisible(x)
}
