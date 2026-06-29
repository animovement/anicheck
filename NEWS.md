# anicheck 0.2.0

## New features

* `check_na_timing()` summarises *where* missing values fall, as one row per gap.
* `check_na_gapsize()` tabulates how often each missing-value gap length occurs.
* `check_confidence()` reduces per-keypoint tracking confidence to a compact
  density grid and five-number summary.
* Each check gains `summary()` and `print()` methods for a per-group overview.

## Plotting

* `plot()` methods for the check objects ensure the companion
  [anivis](https://animovement.dev/anivis/) package is installed (prompting if
  not) and then delegate to it, mirroring the performance / see split in
  easystats.

## Internals

* Dropped the unused `dplyr` dependency; declared `stats` and `utils`.
