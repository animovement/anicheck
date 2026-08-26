# Shared helpers for the check_* family (destined for the anicheck package).
# Kept in one file so each check function does not duplicate the grouping logic.

# Internal: split a data frame into one sub-frame per group, in order of first
# appearance. With no grouping columns the whole frame is a single group.
split_by_group_cols <- function(df, group_cols) {
  key <- group_key(df, group_cols)
  split(df, factor(key, levels = unique(key)))
}

# Internal: a stable per-row group key (tab-joined to avoid collisions). Returns
# "all" when there are no grouping columns, and length-0 for an empty frame.
group_key <- function(tbl, group_cols) {
  n <- nrow(tbl)
  if (!n) {
    return(character(0))
  }
  if (!length(group_cols)) {
    return(rep("all", n))
  }
  do.call(
    paste,
    c(lapply(group_cols, function(col) as.character(tbl[[col]])), sep = "\t")
  )
}

# Internal: the grouping columns of an aniframe - every `variables_what` and
# non-time `variables_when` column. Derived straight from the metadata so the
# check_* family has no dependency on anivis internals.
aniframe_group_cols <- function(data) {
  meta <- aniframe::get_metadata(data)
  what <- intersect(meta$variables_what, names(data))
  when <- setdiff(intersect(meta$variables_when, names(data)), "time")
  unique(c(what, when))
}

# Internal: the declarations `group_cols` is built from, carried through to
# the check object under their own names. `group_cols` concatenates identity
# and temporal context, so a consumer cannot tell where one ends and the
# other begins — and picking "the last grouping column" can land on a session
# or trial rather than the finest identity (animovement/anivis#21). These are
# the aniframe metadata fields verbatim, not a new concept.
aniframe_declarations <- function(data) {
  meta <- aniframe::get_metadata(data)
  list(
    variables_what = meta$variables_what,
    variables_when = meta$variables_when
  )
}

# Internal: validate the requested variable(s). Missingness is meaningful for
# any column, so (unlike a numeric measure) there is no type requirement.
check_na_variable <- function(data, variable) {
  if (is.null(variable) || !length(variable)) {
    cli::cli_abort("{.arg variable} must name at least one column.")
  }
  if (!is.character(variable)) {
    cli::cli_abort(
      "{.arg variable} must be a character vector of column names."
    )
  }
  unknown <- setdiff(variable, names(data))
  if (length(unknown)) {
    cli::cli_abort(
      "{.arg variable} names unknown column{?s}: {.val {unknown}}."
    )
  }
  variable
}

# Internal: per-group totals (frame and missing counts, time range), one row per
# group, in order of first appearance. `df` must carry a logical `.missing`.
group_totals <- function(df, group_cols) {
  parts <- split_by_group_cols(df, group_cols)
  out <- do.call(
    rbind,
    lapply(parts, function(d) {
      row <- data.frame(
        n_frames = nrow(d),
        n_missing = sum(d$.missing),
        time_min = min(d$time),
        time_max = max(d$time)
      )
      for (col in group_cols) {
        row[[col]] <- d[[col]][1]
      }
      row[c(group_cols, "n_frames", "n_missing", "time_min", "time_max")]
    })
  )
  rownames(out) <- NULL
  out
}

# Internal: per-group n / mean / sd / five-number summary of `value_col`,
# one row per group (NAs dropped). The compact form a boxplot is drawn from.
distribution_summary <- function(df, group_cols, value_col) {
  parts <- split_by_group_cols(df, group_cols)
  out <- do.call(
    rbind,
    lapply(parts, function(d) {
      v <- d[[value_col]][!is.na(d[[value_col]])]
      q <- if (length(v)) {
        stats::quantile(v, c(0, 0.25, 0.5, 0.75, 1), names = FALSE)
      } else {
        rep(NA_real_, 5)
      }
      row <- data.frame(
        n = length(v),
        mean = if (length(v)) mean(v) else NA_real_,
        sd = if (length(v) > 1L) stats::sd(v) else NA_real_,
        min = q[1],
        q25 = q[2],
        median = q[3],
        q75 = q[4],
        max = q[5]
      )
      for (col in group_cols) {
        row[[col]] <- d[[col]][1]
      }
      row[c(
        group_cols,
        "n",
        "mean",
        "sd",
        "min",
        "q25",
        "median",
        "q75",
        "max"
      )]
    })
  )
  rownames(out) <- NULL
  out
}
