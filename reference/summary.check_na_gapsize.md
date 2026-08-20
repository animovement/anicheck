# Summarise a Gap-Size Check

Reduces a
[`check_na_gapsize()`](https://animovement.dev/anicheck/reference/check_na_gapsize.md)
object to a per-group overview: frame and missing counts, the percentage
missing, the number of gaps, and the longest gap. The print-side mirror
of anivis's `as_plot_data()`.

## Usage

``` r
# S3 method for class 'check_na_gapsize'
summary(object, ...)
```

## Arguments

- object:

  A `check_na_gapsize` object.

- ...:

  Additional arguments (currently unused).

## Value

A data frame with one row per group.

## See also

[`check_na_gapsize()`](https://animovement.dev/anicheck/reference/check_na_gapsize.md)
