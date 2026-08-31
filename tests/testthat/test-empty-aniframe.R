# Tests for checks on an aniframe with no rows (#32)
# --------------------------------------------------
# dplyr::filter() produces one from any grouped pipeline where a group matches
# nothing, and it is still a valid aniframe. All three checks should agree about
# what to do with it, and the objects they return have to survive their own
# methods.

empty_frame <- function() {
  af <- anicore::example_aniframe(
    n_individuals = 1,
    n_keypoints = 1,
    n_obs = 5
  )
  dplyr::filter(af, FALSE)
}

test_that("every check returns an empty check for an empty frame", {
  empty <- empty_frame()

  for (check in list(check_confidence, check_na_gapsize, check_na_timing)) {
    result <- check(empty)

    expect_s3_class(result, "data.frame")
    expect_identical(nrow(result), 0L)
  }
})

test_that("an empty check survives summary() and print()", {
  # do.call(rbind, list()) is NULL, so a check built from no groups used to
  # carry a NULL where its methods expect a table -- summary() then failed on
  # `!nrow(NULL)` with "invalid argument type".
  empty <- empty_frame()

  for (check in list(check_confidence, check_na_gapsize, check_na_timing)) {
    result <- check(empty)

    expect_no_error(summary(result))
    expect_no_error(capture.output(print(result)))
    expect_identical(nrow(attr(result, "groups")), 0L)
  }
})

test_that("checking an empty frame is silent", {
  # min() and max() over no rows warned about "no non-missing arguments"
  empty <- empty_frame()

  expect_no_warning(check_confidence(empty))
  expect_no_warning(check_na_gapsize(empty))
  expect_no_warning(check_na_timing(empty))
})
