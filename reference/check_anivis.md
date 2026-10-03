# Ensure anivis is available for plotting

Internal helper used by the `plot.check_*()` stubs: the diagnostic plots
live in the companion anivis package, so this prompts the user to
install it (from the animovement R-universe) when it is missing before
the plot is drawn.

## Usage

``` r
check_anivis(version = NULL)
```

## Arguments

- version:

  The minimum anivis version the plot needs, or `NULL` (the default) for
  any. A check whose plot method arrived in a later anivis than the
  others names that version, so an older installation is updated rather
  than handing the check to a plot method that is not there.

## Value

Called for its side effect; returns invisibly.
