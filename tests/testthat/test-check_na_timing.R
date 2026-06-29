# Tests for check_na_timing(), its summary/print, and its plot method.

make_na_single <- function() {
  # x: gap at t2-3 (len 2) and t8 (len 1).  y: an isolated NA at t5 (its
  # neighbours t4/t6 are present in x too, so it stays its own run in the union).
  aniframe::as_aniframe(data.frame(
    time = 1:8,
    x = c(1, NA, NA, 4, 5, 6, 7, NA),
    y = c(1, 1, 1, 1, NA, 1, 1, 1)
  ))
}

make_na_multi_keypoint <- function() {
  # head: gap at t2-3 (len 2).  tail: no gaps.
  aniframe::as_aniframe(data.frame(
    keypoint = rep(c("head", "tail"), each = 6),
    time = rep(1:6, 2),
    x = c(1, NA, NA, 4, 5, 6, 1, 2, 3, 4, 5, 6)
  ))
}

test_that("check_na_timing returns one row per gap with the right columns", {
  out <- check_na_timing(make_na_single())
  expect_s3_class(out, "check_na_timing")
  expect_true(all(c("start", "stop", "length") %in% names(out)))
  expect_equal(out$start, c(2, 8))
  expect_equal(out$stop, c(3, 8))
  expect_equal(out$length, c(2L, 1L))
})

test_that("check_na_timing unions missingness across several variables", {
  # x alone -> 2 gaps; x|y adds the isolated t5 gap -> 3 gaps.
  x_only <- check_na_timing(make_na_single(), variable = "x")
  both <- check_na_timing(make_na_single(), variable = c("x", "y"))
  expect_equal(nrow(x_only), 2L)
  expect_equal(nrow(both), 3L)
  expect_equal(both$start, c(2, 5, 8))
  expect_equal(attr(both, "variable"), c("x", "y"))
})

test_that("check_na_timing keeps grouping columns and per-group totals", {
  out <- check_na_timing(make_na_multi_keypoint())
  expect_true("keypoint" %in% names(out))
  expect_equal(attr(out, "group_cols"), "keypoint")
  expect_equal(nrow(out), 1L)
  expect_equal(as.character(out$keypoint), "head")
  expect_equal(nrow(attr(out, "groups")), 2L)
})

test_that("check_na_timing handles data with no missing values", {
  af <- aniframe::as_aniframe(data.frame(time = 1:5, x = 1:5))
  out <- check_na_timing(af)
  expect_equal(nrow(out), 0L)
  expect_equal(summary(out)$n_gaps, 0L)
})

test_that("check_na_timing errors on non-aniframe and unknown variable", {
  df <- data.frame(time = 1:5, x = rnorm(5))
  expect_error(check_na_timing(df), "must be an aniframe")
  expect_error(
    check_na_timing(make_na_single(), variable = "nope"),
    "unknown column"
  )
})

test_that("summary.check_na_timing gives a per-group overview", {
  s <- summary(check_na_timing(make_na_multi_keypoint()))
  expect_setequal(
    names(s),
    c(
      "keypoint",
      "n_frames",
      "n_missing",
      "pct_missing",
      "n_gaps",
      "longest_gap"
    )
  )
  expect_equal(nrow(s), 2L)
  head_row <- s[s$keypoint == "head", ]
  tail_row <- s[s$keypoint == "tail", ]
  expect_equal(head_row$n_gaps, 1L)
  expect_equal(head_row$longest_gap, 2L)
  expect_equal(tail_row$n_gaps, 0L)
})

test_that("print.check_na_timing returns the object invisibly", {
  expect_invisible(print(check_na_timing(make_na_multi_keypoint())))
})

test_that("check_na_timing uses a unit time step when groups are single-frame", {
  af <- aniframe::as_aniframe(data.frame(
    keypoint = c("a", "b"),
    time = c(1, 1),
    x = c(NA, 2)
  ))
  expect_equal(attr(check_na_timing(af), "time_step"), 1)
})

test_that("na_timing_step falls back to 1 for non-increasing times", {
  # Zero (or negative) spacing cannot scale a gap width, so it defaults to 1.
  expect_equal(na_timing_step(list(data.frame(time = c(2, 2)))), 1)
})
