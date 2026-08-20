# Summarise a Missing-Value Timing Check

Reduces a
[`check_na_timing()`](https://animovement.dev/anicheck/reference/check_na_timing.md)
object to a per-group overview table: frame and missing counts, the
percentage missing, the number of gaps, and the longest gap. This is the
print-side mirror of anivis's `as_plot_data()` - a compact table for the
console or a report, rather than for a geom.

## Usage

``` r
# S3 method for class 'check_na_timing'
summary(object, ...)
```

## Arguments

- object:

  A `check_na_timing` object.

- ...:

  Additional arguments (currently unused).

## Value

A data frame with one row per group.

## See also

[`check_na_timing()`](https://animovement.dev/anicheck/reference/check_na_timing.md)
