#' Check how much segments vary from their usual length
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Measures how far each segment of a structure strays from its usual length.
#' A keypoint can be confident and present in every frame and still be in the
#' wrong place — a left/right swap, a limb taken from a neighbouring
#' individual, a wrong match that several cameras agree on — and the segments
#' that should keep their length then stretch and shrink. This check reports,
#' per individual and segment, how much the length varies and how often it is
#' far from its reference, and [plot.check_segment_length()] draws the
#' distribution of each segment's length relative to that reference.
#'
#' @details
#' The segment lengths per frame are those of [anicore::as_anisegment()].
#' Each track — each combination of the frame's keys, so each individual and
#' segment (and session or trial, when the frame has them) — is compared with a
#' **reference length**: the structure's `length` for that segment when it
#' records one, otherwise the median of the segment's length over the track. A
#' structure's `length` applies to every individual, so leave it `NA` to let
#' each individual be measured against its own median.
#'
#' For each track the check reports
#' * the **spread** of the length, robustly: `mad`, the median absolute
#'   deviation (scaled by 1.4826, so it estimates the standard deviation of
#'   normally distributed lengths) in the frame's units, and `cv`, that MAD
#'   divided by the median length — a robust coefficient of variation, which
#'   compares segments of different sizes. Both measure how much the length
#'   varies, whatever the reference.
#' * the **share off**: the share of frames whose length differs from the
#'   reference by more than `tolerance` times the reference. It counts the
#'   frames with a measured length; a frame missing either end point is
#'   neither on nor off.
#'
#' A segment that is consistently longer than the structure says shows up in
#' the share off and in its median, not in its spread.
#'
#' The distribution of each track's length relative to its reference is reduced
#' to a kernel-density grid, as [check_confidence()] does, so the object stays
#' small however long the recording. One wild frame (a knee placed on the far
#' side of the arena) would otherwise stretch that grid until the bulk of the
#' distribution falls between two grid points, so relative lengths above
#' `max(2, 1 + 2 * tolerance)` enter the grid at that value. The summary
#' statistics use the lengths as they are.
#'
#' This is the data-generating half of the check. The plotting method
#' ([plot.check_segment_length()]) lives in \pkg{anivis}, mirroring the
#' \pkg{performance} / \pkg{see} split in easystats.
#'
#' @param data A Cartesian 2D or 3D anipoint with a structure that has
#'   segments, attached with [anicore::set_structure()].
#' @param structure Name of the structure to use (default `NULL`). May be
#'   omitted when only one of the frame's structures has segments.
#' @param tolerance A single non-negative number (default `0.3`): how far, as a
#'   share of the reference length, a segment's length may differ from it
#'   before the frame counts as off. `0.3` allows 30% either way.
#' @param n Density grid resolution per track (default `256`).
#' @param ... Additional arguments (currently unused).
#'
#' @return A data frame of class `check_segment_length` with one row per
#'   (track, density grid point): the grouping columns (the frame's keys, with
#'   `segment` in place of the structure's variable), the relative length
#'   `value` (length divided by the reference), and its kernel `density`.
#'   Stored as attributes:
#'   * `groups`: one row per track, with the `reference` length and where it
#'     came from (`reference_source`, `"structure"` or `"median"`), the number
#'     of frames with a measured length (`n`), how many of them are off
#'     (`n_off`) and their share (`share_off`), the `median` length, its `mad`
#'     and `cv`, and the five-number summary of the relative length
#'     (`relative_min`, `relative_q25`, `relative_median`, `relative_q75`,
#'     `relative_max`).
#'   * `off`: one row per run of consecutive frames off, with its `start` and
#'     `stop` (in the frame's index), its length in frames (`n_frames`), and
#'     the largest relative deviation within it (`max_deviation`, so `0.5` is
#'     50% longer or shorter than the reference) — when the segments are off.
#'   * `structure`, `tolerance`, the relative length above which values enter
#'     the density grid at that value (`clamp`), and the grouping columns.
#'
#'   Use [summary()] for one row per track.
#'
#' @seealso [plot.check_segment_length()], [anicore::as_anisegment()],
#'   [anicore::anistructure()]
#'
#' @examples
#' af <- anicore::example_anipoint(n_obs = 50, n_individuals = 1) |>
#'   anicore::set_structure(anicore::example_structure())
#' chk <- check_segment_length(af)
#' chk
#' summary(chk)
#'
#' # When the segments were off
#' attr(chk, "off")
#'
#' @export
check_segment_length <- function(data, ...) {
  UseMethod("check_segment_length")
}

#' @rdname check_segment_length
#' @export
check_segment_length.default <- function(data, ...) {
  cli::cli_abort("{.arg data} must be an anipoint.")
}

#' @rdname check_segment_length
#' @export
check_segment_length.anipoint <- function(
  data,
  structure = NULL,
  tolerance = 0.3,
  n = 256,
  ...
) {
  if (
    !is.numeric(tolerance) ||
      length(tolerance) != 1L ||
      !is.finite(tolerance) ||
      tolerance < 0
  ) {
    cli::cli_abort("{.arg tolerance} must be a single non-negative number.")
  }
  name <- segment_structure_name(data, structure)
  struct <- anicore::get_structure(data, name)
  reference_lengths <- stats::setNames(
    struct$segments$length,
    struct$segments$segment
  )

  seg <- anicore::as_anisegment(data, structure = name)
  # The anipoint helpers read the keys and index through anicore's accessors,
  # which an anisegment answers in the same way.
  group_cols <- anipoint_group_cols(seg)
  decl <- anipoint_declarations(seg)
  clamp <- max(2, 1 + 2 * tolerance)

  df <- anipoint_df(seg)
  parts <- split_by_group_cols(df, group_cols)
  tracks <- lapply(
    parts,
    segment_length_track,
    group_cols = group_cols,
    reference_lengths = reference_lengths,
    tolerance = tolerance,
    n = n,
    clamp = clamp
  )

  grid <- bind_track_part(tracks, "grid", empty_density(group_cols))
  groups <- bind_track_part(
    tracks,
    "groups",
    empty_segment_length_groups(group_cols)
  )
  off <- bind_track_part(
    tracks,
    "off",
    empty_rows(group_cols, c("start", "stop", "n_frames", "max_deviation"))
  )

  new_check_segment_length(
    grid,
    group_cols = group_cols,
    groups = groups,
    off = off,
    structure = name,
    tolerance = tolerance,
    clamp = clamp,
    variables_what = decl$what,
    variables_when = decl$when
  )
}

# Internal: the structure the check measures. The same rule as
# anicore::as_anisegment(), resolved here so that a frame without a usable
# structure fails naming check_segment_length() rather than an anicore
# internal, and so that its expected lengths can be read.
segment_structure_name <- function(
  data,
  structure,
  call = rlang::caller_env()
) {
  structures <- anicore::get_structure(data)
  with_segments <- names(Filter(
    function(s) nrow(s$segments) > 0L,
    structures
  ))
  if (!is.null(structure)) {
    if (!is.character(structure) || length(structure) != 1L) {
      cli::cli_abort(
        "{.arg structure} must be a single structure name.",
        call = call
      )
    }
    if (!structure %in% with_segments) {
      cli::cli_abort(
        c(
          "The frame has no structure with segments called {.val {structure}}.",
          "i" = if (length(with_segments)) {
            "Structures with segments: {.val {with_segments}}."
          } else {
            "Attach one with {.fn anicore::set_structure}."
          }
        ),
        call = call
      )
    }
    return(structure)
  }
  if (length(with_segments) != 1L) {
    cli::cli_abort(
      c(
        if (length(with_segments)) {
          "Several structures have segments: {.val {with_segments}}."
        } else {
          "{.fn check_segment_length} needs a structure with segments."
        },
        "i" = if (length(with_segments)) {
          "Choose one with {.arg structure}."
        } else {
          "Attach one with {.fn anicore::set_structure}."
        }
      ),
      call = call
    )
  }
  with_segments
}

# Internal: one track's density grid, summary row and runs of frames off. The
# reference is the structure's length for the segment, or the track's median
# length when the structure records none.
segment_length_track <- function(
  d,
  group_cols,
  reference_lengths,
  tolerance,
  n,
  clamp
) {
  d <- d[order(d$.time), , drop = FALSE]
  len <- d$length
  measured <- !is.na(len)

  given <- unname(reference_lengths[as.character(d$segment[1])])
  from_structure <- !is.na(given)
  reference <- if (from_structure) {
    given
  } else {
    stats::median(len[measured])
  }
  # A segment whose ends coincide over the track has a median length of zero,
  # and nothing can be measured relative to it.
  usable <- !is.na(reference) && reference > 0
  relative <- if (usable) len / reference else rep(NA_real_, length(len))
  off <- !is.na(relative) & abs(len - reference) > tolerance * reference

  n_measured <- sum(measured)
  median_length <- if (n_measured) stats::median(len[measured]) else NA_real_
  mad_length <- if (n_measured) stats::mad(len[measured]) else NA_real_
  rel <- relative[!is.na(relative)]
  q <- if (length(rel)) {
    stats::quantile(rel, c(0, 0.25, 0.5, 0.75, 1), names = FALSE)
  } else {
    rep(NA_real_, 5)
  }

  groups <- data.frame(
    reference = reference,
    reference_source = if (from_structure) "structure" else "median",
    n = n_measured,
    n_off = sum(off),
    share_off = if (usable && n_measured) sum(off) / n_measured else NA_real_,
    median = median_length,
    mad = mad_length,
    cv = if (isTRUE(median_length > 0)) {
      mad_length / median_length
    } else {
      NA_real_
    },
    relative_min = q[1],
    relative_q25 = q[2],
    relative_median = q[3],
    relative_q75 = q[4],
    relative_max = q[5],
    stringsAsFactors = FALSE
  )

  list(
    grid = with_group_cols(
      relative_density(pmin(rel, clamp), n),
      d,
      group_cols
    ),
    groups = with_group_cols(groups, d, group_cols),
    off = with_group_cols(
      off_runs(d$.time, off, abs(relative - 1)),
      d,
      group_cols
    )
  )
}

# Internal: kernel-density grid of relative lengths over their observed range.
# Fewer than two distinct values collapse to a one-point spike, as in
# confidence_density(), so the violin still draws.
relative_density <- function(v, n) {
  if (length(v) >= 2L && diff(range(v)) > 0) {
    dens <- stats::density(v, from = min(v), to = max(v), n = n)
    return(data.frame(value = dens$x, density = dens$y))
  }
  val <- if (length(v)) v[1] else NA_real_
  data.frame(value = c(val, val), density = c(0, 1))
}

# Internal: one row per run of consecutive frames off, in time order.
off_runs <- function(time, off, deviation) {
  runs <- rle(off)
  ends <- cumsum(runs$lengths)
  starts <- ends - runs$lengths + 1L
  keep <- which(runs$values)
  data.frame(
    start = time[starts[keep]],
    stop = time[ends[keep]],
    n_frames = runs$lengths[keep],
    max_deviation = vapply(
      keep,
      function(k) max(deviation[starts[k]:ends[k]]),
      numeric(1)
    )
  )
}

# Internal: prepend a track's grouping columns to one of its tables.
with_group_cols <- function(out, d, group_cols) {
  for (col in group_cols) {
    out[[col]] <- rep(d[[col]][1], nrow(out))
  }
  out[c(group_cols, setdiff(names(out), group_cols))]
}

# Internal: bind one table across tracks, or the empty shape when there are no
# tracks -- do.call(rbind, list()) is NULL.
bind_track_part <- function(tracks, part, empty) {
  out <- do.call(rbind, lapply(tracks, `[[`, part))
  if (is.null(out)) {
    out <- empty
  }
  rownames(out) <- NULL
  out
}

# Internal: the shape of the per-track summary, with no rows.
empty_segment_length_groups <- function(group_cols) {
  out <- empty_rows(
    group_cols,
    c(
      "reference",
      "n",
      "n_off",
      "share_off",
      "median",
      "mad",
      "cv",
      "relative_min",
      "relative_q25",
      "relative_median",
      "relative_q75",
      "relative_max"
    )
  )
  out$reference_source <- character(0)
  out[c(
    group_cols,
    "reference",
    "reference_source",
    setdiff(names(out), c(group_cols, "reference", "reference_source"))
  )]
}

# Internal: low-level constructor.
new_check_segment_length <- function(
  x,
  group_cols,
  groups,
  off,
  structure,
  tolerance,
  clamp,
  variables_what = character(),
  variables_when = character()
) {
  class(x) <- c(
    "check_segment_length",
    "anivis_check_segment_length",
    "tbl_df",
    "tbl",
    "data.frame"
  )
  attr(x, "group_cols") <- group_cols
  attr(x, "variables_what") <- variables_what
  attr(x, "variables_when") <- variables_when
  attr(x, "groups") <- groups
  attr(x, "off") <- off
  attr(x, "structure") <- structure
  attr(x, "tolerance") <- tolerance
  attr(x, "clamp") <- clamp
  x
}

#' Summarise a segment-length check
#'
#' Trims a [check_segment_length()] object to one row per track: the reference
#' length and where it came from, the number of frames measured, how many and
#' what share of them are off, and the median length with its spread. The
#' print-side mirror of anivis's `as_plot_data()`.
#'
#' @param object A `check_segment_length` object.
#' @param ... Additional arguments (currently unused).
#'
#' @return A data frame with one row per track (per individual and segment),
#'   with columns `reference`, `reference_source`, `n`, `n_off`, `share_off`,
#'   `median`, `mad` and `cv`.
#'
#' @seealso [check_segment_length()]
#' @keywords internal
#' @export
summary.check_segment_length <- function(object, ...) {
  group_cols <- attr(object, "group_cols")
  groups <- attr(object, "groups")
  out <- groups[c(
    group_cols,
    "reference",
    "reference_source",
    "n",
    "n_off",
    "share_off",
    "median",
    "mad",
    "cv"
  )]
  rownames(out) <- NULL
  out
}

#' @export
print.check_segment_length <- function(x, ...) {
  group_cols <- attr(x, "group_cols")
  pct <- paste0(format(100 * attr(x, "tolerance")), "%")
  s <- summary(x)

  # cli_format_method() builds the same lines without emitting them, so the
  # summary reaches stdout as one block -- capturable, and not something
  # suppressMessages() can take away.
  lines <- cli::cli_format_method({
    cli::cli_h3("Check: segment lengths")
    cli::cli_text(
      "Share of frames more than {pct} off the reference length, for
       {nrow(s)} segment{?s} of structure {.val {attr(x, 'structure')}}
       (robust CV in brackets):"
    )
    labels <- do.call(
      paste,
      c(lapply(group_cols, function(col) as.character(s[[col]])), sep = " | ")
    )
    cli::cli_ul(sprintf(
      "%s: %s [%s]",
      labels,
      format_pct(s$share_off),
      format_pct(s$cv)
    ))
  })

  cat(lines, sep = "\n")
  cat("\n")

  invisible(x)
}

# Internal: a share as a percentage for printing, "NA" when unknown.
format_pct <- function(x) {
  ifelse(is.na(x), "NA", sprintf("%.1f%%", 100 * x))
}
