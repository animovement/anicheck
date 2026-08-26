# anicheck (development version)

## New features

* Check objects now carry the aniframe declarations they were built from, as `variables_what` and `variables_when` attributes (animovement/anivis#21). `group_cols` concatenates identity and temporal context, so a consumer given only that vector cannot tell where one ends and the other begins — "the last grouping column" can land on a session rather than the finest identity. The two fields travel under the names aniframe gives them, so `group_cols` keeps its meaning and is now fully explained by the attributes beside it.

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
