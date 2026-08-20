# Plot a Check

Visualise a `check_*()` result. The plot itself is rendered by the
companion anivis package; these methods just make sure it is installed
(prompting if not) and then delegate to it. See the linked anivis method
for the arguments each plot accepts and what it draws.

## Usage

``` r
# S3 method for class 'check_confidence'
plot(x, ...)

# S3 method for class 'check_na_gapsize'
plot(x, ...)

# S3 method for class 'check_na_timing'
plot(x, ...)
```

## Arguments

- x:

  A check object from
  [`check_confidence()`](https://animovement.dev/anicheck/reference/check_confidence.md),
  [`check_na_gapsize()`](https://animovement.dev/anicheck/reference/check_na_gapsize.md),
  or
  [`check_na_timing()`](https://animovement.dev/anicheck/reference/check_na_timing.md).

- ...:

  Passed on to the corresponding anivis plot method.

## Value

A ggplot2 object, drawn by anivis.

## See also

[`check_confidence()`](https://animovement.dev/anicheck/reference/check_confidence.md),
[`check_na_gapsize()`](https://animovement.dev/anicheck/reference/check_na_gapsize.md),
[`check_na_timing()`](https://animovement.dev/anicheck/reference/check_na_timing.md)
