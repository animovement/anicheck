# Tests for the shared check_* helpers that the per-check tests do not reach on
# their own (defensive and degenerate branches).

test_that("group_key labels ungrouped rows 'all' and handles an empty frame", {
  # A valid aniframe always carries at least one identity column, so the
  # no-grouping branch is defensive; exercise it directly.
  expect_equal(group_key(data.frame(x = 1:2), character(0)), c("all", "all"))
  expect_equal(group_key(data.frame(x = integer(0)), "x"), character(0))
})
