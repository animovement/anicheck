# Changelog

## anicheck 0.2.0

### New features

- [`check_na_timing()`](https://animovement.dev/anicheck/reference/check_na_timing.md)
  summarises *where* missing values fall, as one row per gap.
- [`check_na_gapsize()`](https://animovement.dev/anicheck/reference/check_na_gapsize.md)
  tabulates how often each missing-value gap length occurs.
- [`check_confidence()`](https://animovement.dev/anicheck/reference/check_confidence.md)
  reduces per-keypoint tracking confidence to a compact density grid and
  five-number summary.
- Each check gains [`summary()`](https://rdrr.io/r/base/summary.html)
  and [`print()`](https://rdrr.io/r/base/print.html) methods for a
  per-group overview.

### Plotting

- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods for
  the check objects ensure the companion
  [anivis](https://animovement.dev/anivis/) package is installed
  (prompting if not) and then delegate to it, mirroring the performance
  / see split in easystats.

### Internals

- Dropped the unused `dplyr` dependency; declared `stats` and `utils`.
