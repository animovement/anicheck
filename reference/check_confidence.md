# Visualize the Distribution of Confidence Values per Keypoint

`check_confidence()` computes summary statistics for confidence values
grouped by a chosen variable (defaulting to `keypoint`) and returns a
tidy data frame that can be visualized with standard plotting functions.

## Usage

``` r
check_confidence(data, ...)

# Default S3 method
check_confidence(data, by = NULL, ...)
```

## Arguments

- data:

  A data frame that contains at least the columns `keypoint` and
  `confidence`. Additional grouping variables can be supplied via the
  `by` argument.

- ...:

  Arguments passed down to the plotting functions.

- by:

  (Optional) A character vector or column name(s) used to group the data
  before summarising. If `NULL`, the function defaults to `"keypoint"`.

## Value

A tibble/data frame with one row per group defined by `by`, containing
the following columns:

- conf_median:

  Median of `confidence` within the group (NA-removed).

- conf_q1:

  First quartile (25th percentile) of `confidence`.

- conf_q3:

  Third quartile (75th percentile) of `confidence`.

- conf_min:

  Minimum value of `confidence` within the group (NA-removed).

- conf_max:

  Maximum value of `confidence` within the group (NA-removed).

The result can be passed directly to `ggplot2` or other visualization
packages.
