# Ensure anivis is available for plotting

Internal helper used by the `plot.check_*()` stubs: the diagnostic plots
live in the companion anivis package, so this prompts the user to
install it (from the animovement R-universe) when it is missing before
the plot is drawn.

## Usage

``` r
check_anivis()
```

## Value

Called for its side effect; returns invisibly.
