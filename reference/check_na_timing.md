# Check the Timing of Missing Values

Finds the runs of consecutive missing values (`NA`) in an aniframe and
returns them as a compact table - **one row per gap**, not per frame.
Where the gaps fall (at the start, the end, scattered, or in long
bursts) is often more telling than how many there are; this check
exposes that timing, and
[`plot.check_na_timing()`](https://animovement.dev/anicheck/reference/plot.check.md)
draws it as a missingness strip.

## Usage

``` r
check_na_timing(data, ...)

# Default S3 method
check_na_timing(data, ...)

# S3 method for class 'aniframe'
check_na_timing(data, variable = "x", ...)
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

A data frame of class `check_na_timing` with one row per missing run:
the aniframe's grouping columns (every `variables_what` and non-time
`variables_when` column), the run's `start` and `stop` time, and its
`length` in frames. Per-group totals (frame and missing counts, time
range), the checked variable(s), the time unit, and the typical time
step are stored as attributes for the
[`summary()`](https://rdrr.io/r/base/summary.html),
[`print()`](https://rdrr.io/r/base/print.html), and plotting methods.
Use [`summary()`](https://rdrr.io/r/base/summary.html) for a per-group
overview.

## Details

Returning gaps rather than per-frame rows keeps the object (and any plot
built from it) tiny even for million-frame recordings: its size scales
with the number of gaps, not the length of the data.

This is the data-generating half of the check. The plotting method
([`plot.check_na_timing()`](https://animovement.dev/anicheck/reference/plot.check.md))
lives in anivis, mirroring the performance / see split in easystats:
`check_*()` computes a classed object with
[`summary()`](https://rdrr.io/r/base/summary.html) /
[`print()`](https://rdrr.io/r/base/print.html) methods, and a `plot.*()`
method in the companion package draws it. (`check_*()` functions are
destined for the anicheck package; they are kept here for now for
convenience.)

## See also

[`plot.check_na_timing()`](https://animovement.dev/anicheck/reference/plot.check.md),
[`summary.check_na_timing()`](https://animovement.dev/anicheck/reference/summary.check_na_timing.md)

## Examples

``` r
af <- anicore::as_aniframe(data.frame(
  keypoint = rep(c("head", "tail"), each = 6),
  time = rep(1:6, 2),
  x = c(1, NA, NA, 4, 5, 6, 1, 2, 3, 4, 5, 6)
))
check_na_timing(af)
#> 
#> ── Check: timing of missing values 
#> Tracking x across 12 frames - 2 missing (16.7%) in 1 gap.
#> By group (keypoint):
#> • head: 33.3% missing in 1 gap (longest 2)
#> • tail: 0% missing in 0 gaps (longest 0)
summary(check_na_timing(af))
#>   keypoint n_frames n_missing pct_missing n_gaps longest_gap
#> 1     head        6         2        33.3      1           2
#> 2     tail        6         0         0.0      0           0
```
