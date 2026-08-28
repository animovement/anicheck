# anicheck (development version)

# anicheck 0.3.0 (2026-08-28)

## Changed

* The minimum `anicore` is 0.8.0, the first version published under that name — the dependency was renamed without a version constraint, so nothing recorded that a pre-rename `aniframe` will not do.

* The core data structures come from `anicore`, which is what the `aniframe` package was renamed to in its 0.8.0 (animovement/anicore#84). The `aniframe` class keeps its name; only the package providing it changed, so `anicore` replaces `aniframe` in `Imports` and in every `aniframe::` call.

## Added

* Check objects carry the aniframe declarations they were built from, as `variables_what` and `variables_when` attributes (animovement/anivis#21). `group_cols` concatenates identity and temporal context, so a consumer given only that vector cannot tell where one ends and the other begins — "the last grouping column" can land on a session rather than the finest identity. The two fields travel under the names aniframe gives them, so `group_cols` keeps its meaning and is now explained by the attributes beside it.

# anicheck 0.2.0 (2026-06-29)

First substantial release. anicheck diagnoses movement-data quality, returning objects that anivis knows how to draw.

## Added

* `check_na_timing()` summarises *where* missing values fall, as one row per gap.
* `check_na_gapsize()` tabulates how often each missing-value gap length occurs.
* `check_confidence()` reduces per-keypoint tracking confidence to a compact density grid and five-number summary.
* `summary()` and `print()` methods for each check, giving a per-group overview.
* `plot()` methods that ensure [anivis](https://animovement.dev/anivis/) is installed, prompting if not, and then delegate to it — mirroring the performance / see split in easystats.

## Removed

* The unused `dplyr` dependency. `stats` and `utils` are now declared.

# anicheck 0.1.1

## Added

* `check_confidence()`, the first check.

# anicheck 0.1.0

Package skeleton. No user-facing functions yet.
