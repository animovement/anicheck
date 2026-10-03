# Tests for check_segment_length(), its summary/print, and its plot stub.

# A chain a -> b -> c -> d, built so that each segment's length per frame is
# set directly: `a` sits `l_ab` to the left of `b`, and `d` sits `l_cd` beyond
# `c` (to the right in 2D, above it in 3D). b -> c is always 2 long. Moving an
# end point changes only the one segment it ends.
make_chain <- function(
  l_ab = rep(1, 20),
  l_cd = rep(1.5, 20),
  individuals = "A",
  dim3 = FALSE
) {
  n <- length(l_ab)
  one <- function(id) {
    d <- data.frame(
      individual = id,
      keypoint = rep(c("a", "b", "c", "d"), each = n),
      time = rep(seq_len(n), 4),
      x = c(1 - l_ab, rep(1, n), rep(1, n), if (dim3) rep(1, n) else 1 + l_cd),
      y = c(rep(0, n), rep(0, n), rep(2, n), rep(2, n))
    )
    if (dim3) {
      d$z <- c(rep(0, 3 * n), l_cd)
    }
    d
  }
  af <- anicore::as_anipoint(
    do.call(rbind, lapply(individuals, one)),
    variables_what = c("individual", "keypoint")
  )
  anicore::set_structure(af, chain_structure())
}

chain_structure <- function(length = NULL) {
  segments <- data.frame(
    segment = c("ab", "bc", "cd"),
    from = c("a", "b", "c"),
    to = c("b", "c", "d")
  )
  if (!is.null(length)) {
    segments$length <- length
  }
  anicore::anistructure(segments = segments)
}

track <- function(chk, segment, individual = "A") {
  g <- attr(chk, "groups")
  g[as.character(g$segment) == segment & g$individual == individual, ]
}

stretched <- function() {
  l_cd <- rep(1.5, 20)
  l_cd[5:8] <- 3
  l_cd
}

test_that("a segment stretched in some frames is off in those frames only", {
  chk <- check_segment_length(make_chain(l_cd = stretched()))

  expect_s3_class(chk, "check_segment_length")
  expect_s3_class(chk, "anivis_check_segment_length")
  expect_equal(track(chk, "cd")$n_off, 4L)
  expect_equal(track(chk, "cd")$share_off, 0.2)
  expect_equal(track(chk, "ab")$share_off, 0)
  expect_equal(track(chk, "bc")$share_off, 0)
  # The reference is the median, which the stretched frames do not move.
  expect_equal(track(chk, "cd")$reference, 1.5)
  expect_equal(track(chk, "cd")$reference_source, "median")
  expect_equal(track(chk, "cd")$relative_max, 2)

  # When it happened: one run, frames 5 to 8, twice the reference.
  off <- attr(chk, "off")
  expect_equal(nrow(off), 1L)
  expect_equal(as.character(off$segment), "cd")
  expect_equal(off$start, 5L)
  expect_equal(off$stop, 8L)
  expect_equal(off$n_frames, 4L)
  expect_equal(off$max_deviation, 1)
})

test_that("a segment whose length wobbles has a larger spread", {
  # 20% either way, every frame: within the tolerance, but not steady.
  l_ab <- rep(c(0.8, 1.2), 10)
  chk <- check_segment_length(make_chain(l_ab = l_ab))

  ab <- track(chk, "ab")
  expect_equal(ab$median, 1)
  expect_equal(ab$mad, stats::mad(l_ab))
  expect_equal(ab$cv, stats::mad(l_ab) / 1)
  expect_gt(ab$cv, 0.25)
  expect_equal(ab$share_off, 0)
  expect_equal(track(chk, "bc")$mad, 0)
  expect_equal(track(chk, "cd")$cv, 0)
})

test_that("the structure's length is the reference when it records one", {
  af <- make_chain(l_cd = stretched())
  af <- anicore::set_structure(af, chain_structure(length = c(1, NA, 1)))
  chk <- check_segment_length(af)

  ab <- track(chk, "ab")
  expect_equal(ab$reference, 1)
  expect_equal(ab$reference_source, "structure")
  expect_equal(ab$share_off, 0)

  # The structure says 1, the data say 1.5: every frame is off, but the
  # length varies no more than before.
  cd <- track(chk, "cd")
  expect_equal(cd$reference, 1)
  expect_equal(cd$reference_source, "structure")
  expect_equal(cd$share_off, 1)
  expect_equal(cd$median, 1.5)
  expect_equal(cd$relative_median, 1.5)
  expect_equal(nrow(attr(chk, "off")), 1L)
  expect_equal(attr(chk, "off")$n_frames, 20L)

  expect_equal(track(chk, "bc")$reference_source, "median")
  expect_equal(track(chk, "bc")$reference, 2)
})

test_that("tolerance sets how far off a frame has to be", {
  l_cd <- rep(1.5, 20)
  l_cd[1:4] <- 1.5 * c(1.1, 1.25, 1.4, 1.6)
  af <- make_chain(l_cd = l_cd)

  expect_equal(track(check_segment_length(af), "cd")$n_off, 2L)
  expect_equal(
    track(check_segment_length(af, tolerance = 0.2), "cd")$n_off,
    3L
  )
  expect_equal(
    track(check_segment_length(af, tolerance = 0.05), "cd")$n_off,
    4L
  )
  expect_equal(
    track(check_segment_length(af, tolerance = 1), "cd")$n_off,
    0L
  )
  expect_equal(
    attr(check_segment_length(af, tolerance = 0.2), "tolerance"),
    0.2
  )
})

test_that("tolerance must be a single non-negative number", {
  af <- make_chain()
  for (bad in list(-0.1, c(0.1, 0.2), NA_real_, Inf, "0.3")) {
    expect_error(check_segment_length(af, tolerance = bad), "tolerance")
  }
  expect_no_error(check_segment_length(af, tolerance = 0))
})

test_that("each individual is measured against its own median", {
  af <- make_chain(individuals = c("A", "B"))
  # B is a larger animal: its c -> d is twice as long, and stretched once.
  d <- as.data.frame(af)
  is_bd <- d$individual == "B" & d$keypoint == "d"
  d$x[is_bd] <- 1 + c(rep(3, 19), 6)
  af <- anicore::set_structure(
    anicore::as_anipoint(d, variables_what = c("individual", "keypoint")),
    chain_structure()
  )
  chk <- check_segment_length(af)

  expect_equal(track(chk, "cd", "A")$reference, 1.5)
  expect_equal(track(chk, "cd", "B")$reference, 3)
  expect_equal(track(chk, "cd", "A")$share_off, 0)
  expect_equal(track(chk, "cd", "B")$share_off, 0.05)
  expect_equal(nrow(summary(chk)), 6L)
  expect_equal(attr(chk, "variables_what"), c("individual", "segment"))
  expect_true(all(c("individual", "segment") %in% attr(chk, "group_cols")))
})

test_that("3D lengths are measured in all three axes", {
  chk <- check_segment_length(make_chain(l_cd = stretched(), dim3 = TRUE))

  expect_equal(track(chk, "cd")$reference, 1.5)
  expect_equal(track(chk, "cd")$share_off, 0.2)
  expect_equal(track(chk, "ab")$share_off, 0)
})

test_that("a frame missing an end point is neither on nor off", {
  af <- make_chain(l_cd = stretched())
  d <- as.data.frame(af)
  d$x[d$keypoint == "d" & d$time %in% c(6, 15)] <- NA
  af <- anicore::set_structure(anicore::as_anipoint(d), chain_structure())
  chk <- check_segment_length(af)

  cd <- track(chk, "cd")
  expect_equal(cd$n, 18L)
  expect_equal(cd$n_off, 3L)
  expect_equal(cd$share_off, 3 / 18)
  # The missing frame splits the run of frames off in two.
  off <- attr(chk, "off")
  expect_equal(off$start, c(5L, 7L))
  expect_equal(off$stop, c(5L, 8L))
  expect_equal(track(chk, "ab")$n, 20L)
})

test_that("a segment never measured, or of no length, has no share off", {
  af <- make_chain()
  d <- as.data.frame(af)
  d$x[d$keypoint == "d"] <- NA
  # a sits on b throughout: ab has a median length of zero.
  d$x[d$keypoint == "a"] <- 1
  af <- anicore::set_structure(anicore::as_anipoint(d), chain_structure())
  chk <- check_segment_length(af)

  cd <- track(chk, "cd")
  expect_equal(cd$n, 0L)
  expect_true(is.na(cd$reference))
  expect_true(is.na(cd$share_off))
  expect_true(is.na(cd$median))
  expect_true(is.na(cd$cv))
  expect_true(is.na(cd$relative_median))

  ab <- track(chk, "ab")
  expect_equal(ab$n, 20L)
  expect_equal(ab$reference, 0)
  expect_true(is.na(ab$share_off))
  expect_true(is.na(ab$cv))
  expect_equal(ab$n_off, 0L)

  # Both still get a (degenerate) violin, as check_confidence() does.
  grid <- chk[as.character(chk$segment) == "cd", ]
  expect_equal(grid$density, c(0, 1))
  expect_true(all(is.na(grid$value)))
  expect_no_error(capture.output(print(chk)))
})

test_that("the density grid is of the relative length, clamped", {
  l_cd <- rep(1.5, 20)
  l_cd[1:3] <- c(1.4, 1.6, 30)
  chk <- check_segment_length(make_chain(l_cd = l_cd), n = 64)

  cd <- chk[as.character(chk$segment) == "cd", ]
  expect_equal(nrow(cd), 64L)
  expect_equal(attr(chk, "clamp"), 2)
  expect_equal(max(cd$value), 2)
  expect_equal(min(cd$value), 1.4 / 1.5)
  # The summary keeps the true value.
  expect_equal(track(chk, "cd")$relative_max, 20)
  # A constant segment is a spike at 1.
  bc <- chk[as.character(chk$segment) == "bc", ]
  expect_equal(bc$value, c(1, 1))

  expect_equal(
    attr(check_segment_length(make_chain(), tolerance = 0.75), "clamp"),
    2.5
  )
})

test_that("structure = chooses between several structures", {
  af <- make_chain(l_cd = stretched())
  af <- anicore::set_structure(
    af,
    anicore::anistructure(
      segments = data.frame(segment = "cd", from = "c", to = "d", length = 3)
    ),
    name = "feet"
  )

  expect_error(
    check_segment_length(af),
    "Several structures have segments"
  )
  chk <- check_segment_length(af, structure = "feet")
  expect_equal(attr(chk, "structure"), "feet")
  expect_equal(as.character(unique(attr(chk, "groups")$segment)), "cd")
  expect_equal(track(chk, "cd")$reference, 3)
  expect_equal(track(chk, "cd")$share_off, 0.8)

  chk <- check_segment_length(af, structure = "keypoint")
  expect_equal(nrow(attr(chk, "groups")), 3L)

  expect_error(
    check_segment_length(af, structure = "nope"),
    "no structure with segments called"
  )
  expect_error(check_segment_length(af, structure = 1), "single structure")
  expect_error(
    check_segment_length(af, structure = c("feet", "keypoint")),
    "single structure"
  )
})

test_that("a frame without a structure with segments is a clear error", {
  af <- anicore::as_anipoint(data.frame(
    keypoint = rep(c("a", "b"), each = 3),
    time = rep(1:3, 2),
    x = 1:6,
    y = 1:6
  ))
  expect_error(
    check_segment_length(af),
    "needs a structure with segments",
    class = "rlang_error"
  )
  err <- rlang::catch_cnd(check_segment_length(af))
  expect_match(conditionMessage(err), "set_structure")
  expect_equal(rlang::call_name(err$call), "check_segment_length")

  # A structure of points only has no segments to measure.
  pts <- anicore::set_structure(af, anicore::anistructure(points = c("a", "b")))
  expect_error(check_segment_length(pts), "needs a structure with segments")
  expect_error(
    check_segment_length(pts, structure = "keypoint"),
    "set_structure"
  )
})

test_that("check_segment_length rejects what is not an anipoint", {
  expect_error(check_segment_length(data.frame(x = 1)), "must be an anipoint")
  ev <- anicore::as_anievent(data.frame(
    channel = "behaviour",
    type = "state",
    label = "rest",
    start = 1,
    stop = 2
  ))
  expect_error(check_segment_length(ev), "must be an anipoint")
})

test_that("an empty frame gives an empty check that survives its methods", {
  chk <- check_segment_length(make_chain()[0, ])

  expect_s3_class(chk, "check_segment_length")
  expect_identical(nrow(chk), 0L)
  expect_identical(nrow(attr(chk, "groups")), 0L)
  expect_identical(nrow(attr(chk, "off")), 0L)
  expect_named(
    summary(chk),
    c(
      attr(chk, "group_cols"),
      "reference",
      "reference_source",
      "n",
      "n_off",
      "share_off",
      "median",
      "mad",
      "cv"
    )
  )
  expect_no_error(capture.output(print(chk)))
})

test_that("summary.check_segment_length gives one row per track", {
  chk <- check_segment_length(make_chain(l_cd = stretched()))
  s <- summary(chk)

  expect_equal(nrow(s), 3L)
  expect_named(
    s,
    c(
      "individual",
      "segment",
      "reference",
      "reference_source",
      "n",
      "n_off",
      "share_off",
      "median",
      "mad",
      "cv"
    )
  )
  expect_equal(as.character(s$segment), c("ab", "bc", "cd"))
})

test_that("print.check_segment_length lists the share off per track", {
  chk <- check_segment_length(make_chain(l_cd = stretched()))
  out <- paste(capture.output(print(chk)), collapse = "\n")

  expect_match(out, "segment lengths")
  expect_match(out, "more than 30% off")
  expect_match(out, "A | cd: 20.0% [0.0%]", fixed = TRUE)
  expect_match(out, "A | ab: 0.0% [0.0%]", fixed = TRUE)
  expect_invisible(print(chk))

  out <- paste(
    capture.output(print(check_segment_length(make_chain(), tolerance = 0.25))),
    collapse = "\n"
  )
  expect_match(out, "more than 25% off")
})

test_that("plot.check_segment_length ensures a recent anivis, then delegates", {
  needed <- NULL
  local_mocked_bindings(
    check_anivis = function(version = NULL) needed <<- version
  )
  assign(
    "plot.anivis_check_segment_length",
    function(x, ...) "segment length",
    envir = globalenv()
  )
  withr::defer(rm("plot.anivis_check_segment_length", envir = globalenv()))

  chk <- check_segment_length(make_chain())
  expect_equal(plot(chk), "segment length")
  # The version the method arrived in, which DESCRIPTION's Suggests matches.
  expect_equal(needed, "0.2.1.9003")
  suggests <- read.dcf(
    system.file("DESCRIPTION", package = "anicheck"),
    "Suggests"
  )
  expect_match(suggests, "anivis (>= 0.2.1.9003)", fixed = TRUE)
})
