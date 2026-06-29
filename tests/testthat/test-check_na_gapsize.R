# Tests for check_na_gapsize(), its summary/print, and its plot method.

make_gap_single <- function() {
  # x gaps: t2-3 (len 2), t5-6 (len 2), t8 (len 1) -> sizes {2:2, 1:1}.
  aniframe::as_aniframe(data.frame(
    time = 1:8,
    x = c(1, NA, NA, 4, NA, NA, 7, NA)
  ))
}

make_gap_multi_keypoint <- function() {
  # head: gaps len 2 and len 2 -> size 2 occurs twice.
  # tail: one gap len 1 -> size 1 occurs once.
  aniframe::as_aniframe(data.frame(
    keypoint = rep(c("head", "tail"), each = 8),
    time = rep(1:8, 2),
    x = c(1, NA, NA, 4, NA, NA, 7, 8, 1, NA, 3, 4, 5, 6, 7, 8)
  ))
}

test_that("check_na_gapsize tabulates gap sizes with the right columns", {
  out <- check_na_gapsize(make_gap_single())
  expect_s3_class(out, "check_na_gapsize")
  expect_true(all(c("gap_size", "n_gaps", "n_na") %in% names(out)))
  # sizes 1 (once) and 2 (twice), ascending.
  expect_equal(out$gap_size, c(1L, 2L))
  expect_equal(out$n_gaps, c(1L, 2L))
  expect_equal(out$n_na, c(1L, 4L))
})

test_that("check_na_gapsize splits the tabulation per group", {
  out <- check_na_gapsize(make_gap_multi_keypoint())
  expect_equal(attr(out, "group_cols"), "keypoint")
  head_rows <- out[as.character(out$keypoint) == "head", ]
  tail_rows <- out[as.character(out$keypoint) == "tail", ]
  expect_equal(head_rows$gap_size, 2L)
  expect_equal(head_rows$n_gaps, 2L)
  expect_equal(tail_rows$gap_size, 1L)
  expect_equal(tail_rows$n_gaps, 1L)
})

test_that("check_na_gapsize handles data with no missing values", {
  af <- aniframe::as_aniframe(data.frame(time = 1:5, x = 1:5))
  out <- check_na_gapsize(af)
  expect_equal(nrow(out), 0L)
  expect_equal(summary(out)$n_gaps, 0L)
})

test_that("check_na_gapsize errors on non-aniframe and unknown variable", {
  expect_error(check_na_gapsize(data.frame(time = 1:3, x = 1:3)), "aniframe")
  expect_error(
    check_na_gapsize(make_gap_single(), variable = "nope"),
    "unknown column"
  )
})

test_that("check_na_gapsize rejects an empty or non-character variable", {
  af <- make_gap_single()
  expect_error(check_na_gapsize(af, variable = NULL), "at least one column")
  expect_error(
    check_na_gapsize(af, variable = character(0)),
    "at least one column"
  )
  expect_error(check_na_gapsize(af, variable = 1), "character vector")
})

test_that("summary.check_na_gapsize gives a per-group overview", {
  s <- summary(check_na_gapsize(make_gap_multi_keypoint()))
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
  head_row <- s[s$keypoint == "head", ]
  expect_equal(head_row$n_gaps, 2L)
  expect_equal(head_row$longest_gap, 2L)
  expect_equal(head_row$n_missing, 4L)
})

test_that("print.check_na_gapsize returns the object invisibly", {
  expect_invisible(print(check_na_gapsize(make_gap_multi_keypoint())))
})
