# Tests for the plot.check_* stubs. The drawing itself lives in anivis; here we
# only verify the stub contract: ensure anivis is installed (check_anivis()),
# then hand off to anivis's plot.anivis_check_*() method via NextMethod(). Both
# are stand-ins, so the test needs no anivis installed.

make_conf <- function() {
  af <- anicore::as_aniframe(data.frame(
    keypoint = c("a", "b"),
    time = c(1, 1),
    x = c(1, 2),
    y = c(1, 2)
  ))
  af$confidence <- c(0.5, 0.9)
  af
}

make_na <- function() {
  anicore::as_aniframe(data.frame(time = 1:4, x = c(1, NA, NA, 4)))
}

test_that("plot.check_* ensure anivis then delegate via NextMethod()", {
  called <- 0L
  local_mocked_bindings(check_anivis = function() called <<- called + 1L)

  # Stand-ins for anivis's real methods so NextMethod() has a target.
  assign(
    "plot.anivis_check_confidence",
    function(x, ...) "confidence",
    envir = globalenv()
  )
  assign(
    "plot.anivis_check_na_gapsize",
    function(x, ...) "gapsize",
    envir = globalenv()
  )
  assign(
    "plot.anivis_check_na_timing",
    function(x, ...) "timing",
    envir = globalenv()
  )
  withr::defer(rm(
    list = c(
      "plot.anivis_check_confidence",
      "plot.anivis_check_na_gapsize",
      "plot.anivis_check_na_timing"
    ),
    envir = globalenv()
  ))

  expect_equal(plot(check_confidence(make_conf())), "confidence")
  expect_equal(plot(check_na_gapsize(make_na())), "gapsize")
  expect_equal(plot(check_na_timing(make_na())), "timing")
  expect_equal(called, 3L)
})
