#' Check the Distribution of Missing-Value Gap Sizes
#'
#' Tabulates the *lengths* of the runs of consecutive missing values (`NA`) in an
#' aniframe - how often a gap of each size occurs. A recording riddled with
#' single-frame dropouts (easy to interpolate) has a very different gap-size
#' profile from one with a few long blackouts (which interpolation cannot
#' rescue), even when their total missing counts match; this check exposes that
#' profile, and [plot.check_na_gapsize()] draws it as a bar chart.
#'
#' This is the data-generating half of the check. The plotting method
#' ([plot.check_na_gapsize()]) lives in \pkg{anivis}, mirroring the
#' \pkg{performance} / \pkg{see} split in easystats. (`check_*()` functions are
#' destined for the \pkg{anicheck} package; they are kept here for now for
#' convenience.)
#'
#' @param data An aniframe object.
#' @param variable Name(s) of the column(s) whose missingness to track. A frame
#'   counts as missing when *any* named column is `NA` there. Defaults to
#'   `"x"`.
#' @param ... Additional arguments (currently unused).
#'
#' @return A data frame of class `check_na_gapsize` with one row per
#'   (group, gap size): the aniframe's grouping columns, the `gap_size` (run
#'   length in frames), the number of gaps of that size (`n_gaps`), and the total
#'   missing frames they account for (`n_na` = `gap_size` x `n_gaps`). Per-group
#'   totals and the checked variable(s) are stored as attributes. Use
#'   [summary()] for a per-group overview.
#'
#' @seealso [plot.check_na_gapsize()]
#'
#' @examples
#' af <- anicore::as_aniframe(data.frame(
#'   keypoint = rep(c("head", "tail"), each = 8),
#'   time = rep(1:8, 2),
#'   x = c(1, NA, NA, 4, NA, NA, 7, 8, 1, NA, 3, 4, 5, 6, 7, 8)
#' ))
#' check_na_gapsize(af)
#' summary(check_na_gapsize(af))
#'
#' @export
check_na_gapsize <- function(data, ...) {
  UseMethod("check_na_gapsize")
}

#' @rdname check_na_gapsize
#' @export
check_na_gapsize.default <- function(data, ...) {
  cli::cli_abort("{.arg data} must be an aniframe.")
}

#' @rdname check_na_gapsize
#' @export
check_na_gapsize.aniframe <- function(data, variable = "x", ...) {
  variable <- check_na_variable(data, variable)
  group_cols <- aniframe_group_cols(data)
  decl <- aniframe_declarations(data)

  df <- as.data.frame(data)
  df$.missing <- Reduce(`|`, lapply(variable, function(v) is.na(df[[v]])))

  parts <- split_by_group_cols(df, group_cols)
  out <- do.call(
    rbind,
    lapply(parts, na_gapsize_tabulate, group_cols = group_cols)
  )
  if (is.null(out)) {
    out <- empty_gapsize(group_cols)
  }
  rownames(out) <- NULL

  new_check_na_gapsize(
    out,
    variable = variable,
    group_cols = group_cols,
    groups = group_totals(df, group_cols),
    variables_what = decl$variables_what,
    variables_when = decl$variables_when
  )
}

# Internal: tabulate one group's gap lengths into rows of (gap_size, n_gaps,
# n_na), ascending by size. Returns NULL when the group has no gaps.
na_gapsize_tabulate <- function(d, group_cols) {
  runs <- rle(d$.missing[order(d$time)])
  lengths <- runs$lengths[runs$values]
  if (!length(lengths)) {
    return(NULL)
  }
  tab <- table(lengths)
  out <- data.frame(
    gap_size = as.integer(names(tab)),
    n_gaps = as.integer(tab)
  )
  out$n_na <- out$gap_size * out$n_gaps
  for (col in group_cols) {
    out[[col]] <- d[[col]][1]
  }
  out[c(group_cols, "gap_size", "n_gaps", "n_na")]
}

# Internal: a correctly-typed zero-row gap-size table (data with no NAs at all).
empty_gapsize <- function(group_cols) {
  cols <- c(
    stats::setNames(rep(list(character(0)), length(group_cols)), group_cols),
    list(gap_size = integer(0), n_gaps = integer(0), n_na = integer(0))
  )
  do.call(data.frame, c(cols, stringsAsFactors = FALSE))
}

# Internal: low-level constructor. Tags the data frame with the check class and
# stashes the per-group totals and checked variable(s) as attributes for the
# summary / print / plot methods.
new_check_na_gapsize <- function(
  x,
  variable,
  group_cols,
  groups,
  variables_what = character(),
  variables_when = character()
) {
  class(x) <- c(
    "check_na_gapsize",
    "anivis_check_na_gapsize",
    "tbl_df",
    "tbl",
    "data.frame"
  )
  attr(x, "variable") <- variable
  attr(x, "group_cols") <- group_cols
  attr(x, "variables_what") <- variables_what
  attr(x, "variables_when") <- variables_when
  attr(x, "groups") <- groups
  x
}

#' Summarise a Gap-Size Check
#'
#' Reduces a [check_na_gapsize()] object to a per-group overview: frame and
#' missing counts, the percentage missing, the number of gaps, and the longest
#' gap. The print-side mirror of anivis's `as_plot_data()`.
#'
#' @param object A `check_na_gapsize` object.
#' @param ... Additional arguments (currently unused).
#'
#' @return A data frame with one row per group.
#'
#' @seealso [check_na_gapsize()]
#' @keywords internal
#' @export
summary.check_na_gapsize <- function(object, ...) {
  group_cols <- attr(object, "group_cols")
  groups <- attr(object, "groups")

  gkey <- group_key(groups, group_cols)
  okey <- group_key(object, group_cols)
  by_group <- split(object, factor(okey, levels = gkey))

  out <- groups
  out$pct_missing <- ifelse(
    out$n_frames > 0,
    round(100 * out$n_missing / out$n_frames, 1),
    0
  )
  out$n_gaps <- vapply(by_group, function(d) sum(d$n_gaps), integer(1))
  out$longest_gap <- vapply(
    by_group,
    function(d) if (nrow(d)) max(d$gap_size) else 0L,
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
print.check_na_gapsize <- function(x, ...) {
  variable <- attr(x, "variable")
  group_cols <- attr(x, "group_cols")
  s <- summary(x)

  total <- sum(s$n_frames)
  n_missing <- sum(s$n_missing)
  n_gaps <- sum(s$n_gaps)
  longest <- if (nrow(s)) max(s$longest_gap) else 0L
  pct <- if (total) round(100 * n_missing / total, 1) else 0

  # cli_format_method() builds the same lines without emitting them, so the
  # summary reaches stdout as one block -- capturable, and not something
  # suppressMessages() can take away.
  lines <- cli::cli_format_method({
    cli::cli_h3("Check: missing-value gap sizes")
    cli::cli_text(
      "Tracking {.field {variable}}: {n_missing} missing ({pct}%) across
       {n_gaps} gap{?s}, longest {longest} frame{?s}."
    )

    if (length(group_cols) && nrow(s) > 1L) {
      labels <- do.call(
        paste,
        c(lapply(group_cols, function(col) as.character(s[[col]])), sep = " | ")
      )
      cli::cli_text("By group ({.field {group_cols}}):")
      cli::cli_ul(sprintf(
        "%s: %d gap%s, longest %d",
        labels,
        s$n_gaps,
        ifelse(s$n_gaps == 1L, "", "s"),
        s$longest_gap
      ))
    }
  })

  cat(lines, sep = "\n")
  cat("\n")

  invisible(x)
}
