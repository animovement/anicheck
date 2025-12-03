# Tests for check_confidence()
#
# check_confidence.default:
# - Errors when data is not an aniframe
# - Uses "keypoint" as default grouping variable
# - Respects custom `by` argument
# - Works with multiple grouping variables
# - Returns correct class
# - Returns correct column names
# - Calculates summary statistics correctly
# - Handles NA values in confidence
#
# print.check_confidence:
# - Calls check_anivis()
#
# plot.check_confidence:
# - Calls check_anivis()

# check_confidence.default ------------------------------------------------

test_that("check_confidence errors when data is not an aniframe", {
  df <- data.frame(
    time = 1,
    x = 1,
    y = 1,
    keypoint = "a",
    confidence = 0.5
  )

  expect_error(
    check_confidence(df),
    "not an aniframe"
  )
})

test_that("check_confidence returns correct class", {
  af <- aniframe::as_aniframe(data.frame(
    time = 1:4,
    x = 1:4,
    y = 1:4,
    keypoint = c("a", "a", "b", "b"),
    confidence = c(0.8, 0.9, 0.7, 0.6)
  ))

  result <- check_confidence(af)

  expect_s3_class(result, "check_confidence")
  expect_s3_class(result, "plot_check_confidence")
  expect_s3_class(result, "data.frame")
})

test_that("check_confidence returns correct columns", {
  af <- aniframe::as_aniframe(data.frame(
    time = 1:4,
    x = 1:4,
    y = 1:4,
    keypoint = c("a", "a", "b", "b"),
    confidence = c(0.8, 0.9, 0.7, 0.6)
  ))

  result <- check_confidence(af)

  expect_named(
    result,
    c("keypoint", "conf_median", "conf_q1", "conf_q3", "conf_min", "conf_max")
  )
})

test_that("check_confidence uses 'keypoint' as default grouping", {
  af <- aniframe::as_aniframe(data.frame(
    time = 1:4,
    x = 1:4,
    y = 1:4,
    keypoint = c("a", "a", "b", "b"),
    confidence = c(0.8, 0.9, 0.7, 0.6)
  ))

  result <- check_confidence(af)

  expect_equal(nrow(result), 2)
  expect_true("keypoint" %in% names(result))
  expect_setequal(result$keypoint, c("a", "b"))
})

test_that("check_confidence respects custom `by` argument", {
  af <- aniframe::as_aniframe(data.frame(
    time = 1:4,
    x = 1:4,
    y = 1:4,
    keypoint = c("a", "a", "b", "b"),
    group = c("x", "y", "x", "y"),
    confidence = c(0.8, 0.9, 0.7, 0.6)
  ))

  result <- check_confidence(af, by = "group")

  expect_equal(nrow(result), 2)
  expect_true("group" %in% names(result))
  expect_false("keypoint" %in% names(result))
  expect_setequal(result$group, c("x", "y"))
})

test_that("check_confidence works with multiple grouping variables", {
  af <- aniframe::as_aniframe(data.frame(
    time = 1:8,
    x = 1:8,
    y = 1:8,
    keypoint = rep(c("a", "b"), 4),
    individual = rep(c("i1", "i2"), each = 4),
    confidence = c(0.8, 0.7, 0.9, 0.6, 0.5, 0.4, 0.6, 0.3)
  ))

  result <- check_confidence(af, by = c("keypoint", "individual"))

  expect_equal(nrow(result), 4)
  expect_true(all(c("keypoint", "individual") %in% names(result)))
})

test_that("check_confidence calculates statistics correctly", {
  af <- aniframe::as_aniframe(data.frame(
    time = 1:5,
    x = 1:5,
    y = 1:5,
    keypoint = rep("a", 5),
    confidence = c(0.1, 0.3, 0.5, 0.7, 0.9)
  ))

  result <- check_confidence(af)

  expect_equal(result$conf_median, 0.5)
  expect_equal(result$conf_min, 0.1)
  expect_equal(result$conf_max, 0.9)
  expect_equal(result$conf_q1, 0.3, tolerance = 0.05)
  expect_equal(result$conf_q3, 0.7, tolerance = 0.05)
})

test_that("check_confidence handles NA values in confidence", {
  af <- aniframe::as_aniframe(data.frame(
    time = 1:5,
    x = 1:5,
    y = 1:5,
    keypoint = rep("a", 5),
    confidence = c(0.2, NA, 0.5, NA, 0.8)
  ))

  result <- check_confidence(af)

  expect_equal(result$conf_median, 0.5)
  expect_equal(result$conf_min, 0.2)
  expect_equal(result$conf_max, 0.8)
})

# print.check_confidence --------------------------------------------------

test_that("print.check_confidence calls check_anivis", {
  af <- aniframe::as_aniframe(data.frame(
    time = 1:2,
    x = 1:2,
    y = 1:2,
    keypoint = c("a", "b"),
    confidence = c(0.8, 0.9)
  ))
  result <- check_confidence(af)

  local_mocked_bindings(check_anivis = function() invisible(NULL))

  expect_output(print(result))
})

# plot.check_confidence ---------------------------------------------------

test_that("plot.check_confidence calls check_anivis", {
  af <- aniframe::as_aniframe(data.frame(
    time = 1:2,
    x = 1:2,
    y = 1:2,
    keypoint = c("a", "b"),
    confidence = c(0.8, 0.9)
  ))
  result <- check_confidence(af)

  local_mocked_bindings(check_anivis = function() invisible(NULL))

  expect_no_error(plot(result))
})
