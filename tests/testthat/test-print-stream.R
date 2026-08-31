# Tests that the print methods write to stdout as one block (#30)
# --------------------------------------------------------------
# 1. capture.output() sees the summary, because it is not a message
# 2. suppressMessages() cannot take it away
# 3. One print() is one block, not one condition per line

make_check <- function() {
  af <- anicore::as_aniframe(data.frame(
    keypoint = rep(c("head", "tail"), each = 4),
    time = rep(1:4, 2),
    x = c(rnorm(3), NA, rnorm(4)),
    y = c(rnorm(3), NA, rnorm(4)),
    confidence = c(runif(3), NA, runif(4))
  ))
  list(
    confidence = check_confidence(af),
    gapsize = check_na_gapsize(af),
    timing = check_na_timing(af)
  )
}

test_that("print writes to stdout, where capture.output() can see it", {
  for (obj in make_check()) {
    expect_gt(length(capture.output(print(obj))), 0L)
  }
})

test_that("print emits nothing on the message stream", {
  for (obj in make_check()) {
    expect_identical(
      length(capture.output(print(obj), type = "message")),
      0L
    )
  }
})

test_that("suppressMessages() does not hide the summary", {
  for (obj in make_check()) {
    expect_identical(
      capture.output(suppressMessages(print(obj))),
      capture.output(print(obj))
    )
  }
})

test_that("one print() is one block, not one condition per line", {
  for (obj in make_check()) {
    n <- 0L
    withCallingHandlers(
      print(obj),
      message = function(c) {
        n <<- n + 1L
        invokeRestart("muffleMessage")
      }
    )
    expect_identical(n, 0L)
  }
})
