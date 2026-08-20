# Summarise a Confidence Check

Trims a
[`check_confidence()`](https://animovement.dev/anicheck/reference/check_confidence.md)
object to the headline statistics per keypoint: count, median,
inter-quartile range, and minimum (the worst case). The print-side
mirror of anivis's `as_plot_data()`.

## Usage

``` r
# S3 method for class 'check_confidence'
summary(object, ...)
```

## Arguments

- object:

  A `check_confidence` object.

- ...:

  Additional arguments (currently unused).

## Value

A data frame with one row per keypoint (per identity).

## See also

[`check_confidence()`](https://animovement.dev/anicheck/reference/check_confidence.md)
