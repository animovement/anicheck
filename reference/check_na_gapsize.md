# Check the Distribution of Missing-Value Gap Sizes

Tabulates the *lengths* of the runs of consecutive missing values (`NA`)
in an aniframe - how often a gap of each size occurs. A recording
riddled with single-frame dropouts (easy to interpolate) has a very
different gap-size profile from one with a few long blackouts (which
interpolation cannot rescue), even when their total missing counts
match; this check exposes that profile, and
[`plot.check_na_gapsize()`](https://animovement.dev/anicheck/reference/plot.check.md)
draws it as a bar chart.

## Usage

``` r
check_na_gapsize(data, ...)

# Default S3 method
check_na_gapsize(data, ...)

# S3 method for class 'aniframe'
check_na_gapsize(data, variable = "x", ...)
```

## Arguments

- data:

  An aniframe object.

- ...:

  Additional arguments (currently unused).

- variable:

  Name(s) of the column(s) whose missingness to track. A frame counts as
  missing when *any* named column is `NA` there. Defaults to `"x"`.

## Value

A data frame of class `check_na_gapsize` with one row per (group, gap
size): the aniframe's grouping columns, the `gap_size` (run length in
frames), the number of gaps of that size (`n_gaps`), and the total
missing frames they account for (`n_na` = `gap_size` x `n_gaps`).
Per-group totals and the checked variable(s) are stored as attributes.
Use [`summary()`](https://rdrr.io/r/base/summary.html) for a per-group
overview.

## Details

This is the data-generating half of the check. The plotting method
([`plot.check_na_gapsize()`](https://animovement.dev/anicheck/reference/plot.check.md))
lives in anivis, mirroring the performance / see split in easystats.
(`check_*()` functions are destined for the anicheck package; they are
kept here for now for convenience.)

## See also

[`plot.check_na_gapsize()`](https://animovement.dev/anicheck/reference/plot.check.md)

## Examples

``` r
af <- anicore::as_aniframe(data.frame(
  keypoint = rep(c("head", "tail"), each = 8),
  time = rep(1:8, 2),
  x = c(1, NA, NA, 4, NA, NA, 7, 8, 1, NA, 3, 4, 5, 6, 7, 8)
))
check_na_gapsize(af)
#> 
#> ── Check: missing-value gap sizes 
#> Tracking x: 5 missing (31.2%) across 3 gaps, longest 2 frames.
#> By group (keypoint):
#> • head: 2 gaps, longest 2
#> • tail: 1 gap, longest 1
#> 
summary(check_na_gapsize(af))
#>   keypoint n_frames n_missing pct_missing n_gaps longest_gap
#> 1     head        8         4        50.0      2           2
#> 2     tail        8         1        12.5      1           1
```
