# Plot stubs for the check_* family. The actual drawing lives in the companion
# \pkg{anivis} package (mirroring the performance / see split in easystats): each
# check object carries a second `anivis_check_*` class, and these stubs ensure
# anivis is installed before handing off to its `plot.anivis_check_*()` method via
# `NextMethod()`. Keeping the stubs here means a user who calls `plot()` on a check
# without anivis gets a clear install prompt instead of an unhelpful default plot.

#' Plot a Check
#'
#' Visualise a `check_*()` result. The plot itself is rendered by the companion
#' \pkg{anivis} package; these methods just make sure it is installed (prompting
#' if not) and then delegate to it. See the linked anivis method for the
#' arguments each plot accepts and what it draws.
#'
#' @param x A check object from [check_confidence()], [check_na_gapsize()], or
#'   [check_na_timing()].
#' @param ... Passed on to the corresponding \pkg{anivis} plot method.
#'
#' @return A \pkg{ggplot2} object, drawn by \pkg{anivis}.
#'
#' @name plot.check
#' @seealso [check_confidence()], [check_na_gapsize()], [check_na_timing()]
NULL

#' @rdname plot.check
#' @export
plot.check_confidence <- function(x, ...) {
  check_anivis()
  NextMethod()
}

#' @rdname plot.check
#' @export
plot.check_na_gapsize <- function(x, ...) {
  check_anivis()
  NextMethod()
}

#' @rdname plot.check
#' @export
plot.check_na_timing <- function(x, ...) {
  check_anivis()
  NextMethod()
}
