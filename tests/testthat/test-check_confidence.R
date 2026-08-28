# Tests for check_confidence(), its summary/print, and its plot method.

make_conf <- function() {
  af <- anicore::as_aniframe(data.frame(
    keypoint = rep(c("head", "tail"), each = 4),
    time = rep(1:4, 2),
    x = rnorm(8),
    y = rnorm(8)
  ))
  af$confidence <- c(0.9, 0.8, 1.0, 0.7, 0.2, 0.4, 0.1, 0.3)
  af
}

test_that("check_confidence stores a per-keypoint density grid", {
  out <- check_confidence(make_conf(), n = 64)
  expect_s3_class(out, "check_confidence")
  expect_true(all(c("value", "density") %in% names(out)))
  expect_equal(attr(out, "group_cols"), "keypoint")
  expect_equal(nrow(out), 128L) # 64 grid points x 2 keypoints
  expect_setequal(unique(as.character(out$keypoint)), c("head", "tail"))
})

test_that("check_confidence keeps a per-keypoint summary for the overlay", {
  g <- attr(check_confidence(make_conf()), "groups")
  head_row <- g[g$keypoint == "head", ]
  expect_equal(head_row$n, 4L)
  expect_equal(head_row$median, 0.85)
})

test_that("check_confidence errors without a confidence column or aniframe", {
  af <- anicore::as_aniframe(data.frame(
    keypoint = rep("head", 3),
    time = 1:3,
    x = 1:3,
    y = 1:3
  ))
  expect_error(check_confidence(af), "confidence")
  expect_error(check_confidence(data.frame(confidence = 0.5)), "aniframe")
})

test_that("summary.check_confidence reports median, iqr and worst case", {
  s <- summary(check_confidence(make_conf()))
  expect_setequal(names(s), c("keypoint", "n", "median", "iqr", "min"))
  tail_row <- s[s$keypoint == "tail", ]
  expect_equal(tail_row$min, 0.1)
})

test_that("print.check_confidence returns the object invisibly", {
  expect_invisible(print(check_confidence(make_conf())))
})

test_that("check_confidence collapses a constant-confidence keypoint to a spike", {
  af <- anicore::as_aniframe(data.frame(
    keypoint = rep(c("flat", "vary"), each = 4),
    time = rep(1:4, 2),
    x = rnorm(8),
    y = rnorm(8)
  ))
  af$confidence <- c(rep(0.5, 4), c(0.2, 0.4, 0.6, 0.8))
  out <- check_confidence(af, n = 16)
  flat <- out[as.character(out$keypoint) == "flat", ]
  # No spread -> a one-point spike rather than a density grid.
  expect_equal(flat$value, c(0.5, 0.5))
  expect_equal(flat$density, c(0, 1))
})

test_that("check_confidence summarises an all-missing-confidence keypoint as NA", {
  af <- anicore::as_aniframe(data.frame(
    keypoint = rep(c("none", "ok"), each = 4),
    time = rep(1:4, 2),
    x = rnorm(8),
    y = rnorm(8)
  ))
  af$confidence <- c(rep(NA_real_, 4), c(0.2, 0.4, 0.6, 0.8))
  g <- attr(check_confidence(af), "groups")
  none <- g[g$keypoint == "none", ]
  expect_equal(none$n, 0L)
  expect_true(is.na(none$median))
  # Issue #9: an all-NA group must report NA, never Inf / -Inf.
  expect_true(is.na(none$min))
  expect_true(is.na(none$max))
  expect_false(any(is.infinite(c(none$min, none$max))))
})

test_that("print.check_confidence labels an ungrouped check 'all'", {
  # A valid aniframe always has at least one identity column, but the print
  # method defends against an empty grouping by labelling the lone row "all".
  obj <- new_check_confidence(
    data.frame(value = c(0, 1), density = c(0, 1)),
    group_cols = character(0),
    groups = data.frame(
      n = 2L,
      mean = 0.5,
      sd = 0.1,
      min = 0,
      q25 = 0.25,
      median = 0.5,
      q75 = 0.75,
      max = 1
    )
  )
  expect_invisible(print(obj))
})

test_that("check objects carry the declarations group_cols is built from", {
  # `group_cols` concatenates identity and temporal context, so a consumer
  # given only that cannot tell where one ends and the other begins —
  # "the last grouping column" can land on a session rather than the
  # finest identity. anivis needs the distinction for its plot axis
  # (animovement/anivis#21). The fields travel under their own names.
  set.seed(1)
  n <- 48
  d <- data.frame(
    time = rep(seq_len(n / 4), 4),
    animal = rep(c("A", "A", "B", "B"), each = n / 4),
    bodypart = rep(c("p", "q", "p", "q"), each = n / 4),
    session = rep(c("s1", "s2"), each = n / 2),
    x = rnorm(n),
    y = rnorm(n),
    confidence = runif(n)
  )
  af <- anicore::as_aniframe(d, variables_what = c("animal", "bodypart"))

  chk <- check_confidence(af)

  expect_equal(attr(chk, "group_cols"), c("animal", "bodypart", "session"))
  # The aniframe metadata fields verbatim, under their own names.
  expect_equal(attr(chk, "variables_what"), anicore::get_variables_what(af))
  expect_equal(attr(chk, "variables_what"), c("animal", "bodypart"))
  expect_equal(attr(chk, "variables_when"), anicore::get_variables_when(af))
})
