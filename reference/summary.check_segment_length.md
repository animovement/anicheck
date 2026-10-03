# Summarise a segment-length check

Trims a
[`check_segment_length()`](https://animovement.dev/anicheck/reference/check_segment_length.md)
object to one row per track: the reference length and where it came
from, the number of frames measured, how many and what share of them are
off, and the median length with its spread. The print-side mirror of
anivis's `as_plot_data()`.

## Usage

``` r
# S3 method for class 'check_segment_length'
summary(object, ...)
```

## Arguments

- object:

  A `check_segment_length` object.

- ...:

  Additional arguments (currently unused).

## Value

A data frame with one row per track (per individual and segment), with
columns `reference`, `reference_source`, `n`, `n_off`, `share_off`,
`median`, `mad` and `cv`.

## See also

[`check_segment_length()`](https://animovement.dev/anicheck/reference/check_segment_length.md)
