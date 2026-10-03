# Check how much segments vary from their usual length

**\[experimental\]**

Measures how far each segment of a structure strays from its usual
length. A keypoint can be confident and present in every frame and still
be in the wrong place — a left/right swap, a limb taken from a
neighbouring individual, a wrong match that several cameras agree on —
and the segments that should keep their length then stretch and shrink.
This check reports, per individual and segment, how much the length
varies and how often it is far from its reference, and
[`plot.check_segment_length()`](https://animovement.dev/anicheck/reference/plot.check.md)
draws the distribution of each segment's length relative to that
reference.

## Usage

``` r
check_segment_length(data, ...)

# Default S3 method
check_segment_length(data, ...)

# S3 method for class 'anipoint'
check_segment_length(data, structure = NULL, tolerance = 0.3, n = 256, ...)
```

## Arguments

- data:

  A Cartesian 2D or 3D anipoint with a structure that has segments,
  attached with
  [`anicore::set_structure()`](https://animovement.dev/anicore/reference/structures.html).

- ...:

  Additional arguments (currently unused).

- structure:

  Name of the structure to use (default `NULL`). May be omitted when
  only one of the frame's structures has segments.

- tolerance:

  A single non-negative number (default `0.3`): how far, as a share of
  the reference length, a segment's length may differ from it before the
  frame counts as off. `0.3` allows 30% either way.

- n:

  Density grid resolution per track (default `256`).

## Value

A data frame of class `check_segment_length` with one row per (track,
density grid point): the grouping columns (the frame's keys, with
`segment` in place of the structure's variable), the relative length
`value` (length divided by the reference), and its kernel `density`.
Stored as attributes:

- `groups`: one row per track, with the `reference` length and where it
  came from (`reference_source`, `"structure"` or `"median"`), the
  number of frames with a measured length (`n`), how many of them are
  off (`n_off`) and their share (`share_off`), the `median` length, its
  `mad` and `cv`, and the five-number summary of the relative length
  (`relative_min`, `relative_q25`, `relative_median`, `relative_q75`,
  `relative_max`).

- `off`: one row per run of consecutive frames off, with its `start` and
  `stop` (in the frame's index), its length in frames (`n_frames`), and
  the largest relative deviation within it (`max_deviation`, so `0.5` is
  50% longer or shorter than the reference) — when the segments are off.

- `structure`, `tolerance`, the relative length above which values enter
  the density grid at that value (`clamp`), and the grouping columns.

Use [`summary()`](https://rdrr.io/r/base/summary.html) for one row per
track.

## Details

The segment lengths per frame are those of
[`anicore::as_anisegment()`](https://animovement.dev/anicore/reference/as_anisegment.html).
Each track — each combination of the frame's keys, so each individual
and segment (and session or trial, when the frame has them) — is
compared with a **reference length**: the structure's `length` for that
segment when it records one, otherwise the median of the segment's
length over the track. A structure's `length` applies to every
individual, so leave it `NA` to let each individual be measured against
its own median.

For each track the check reports

- the **spread** of the length, robustly: `mad`, the median absolute
  deviation (scaled by 1.4826, so it estimates the standard deviation of
  normally distributed lengths) in the frame's units, and `cv`, that MAD
  divided by the median length — a robust coefficient of variation,
  which compares segments of different sizes. Both measure how much the
  length varies, whatever the reference.

- the **share off**: the share of frames whose length differs from the
  reference by more than `tolerance` times the reference. It counts the
  frames with a measured length; a frame missing either end point is
  neither on nor off.

A segment that is consistently longer than the structure says shows up
in the share off and in its median, not in its spread.

The distribution of each track's length relative to its reference is
reduced to a kernel-density grid, as
[`check_confidence()`](https://animovement.dev/anicheck/reference/check_confidence.md)
does, so the object stays small however long the recording. One wild
frame (a knee placed on the far side of the arena) would otherwise
stretch that grid until the bulk of the distribution falls between two
grid points, so relative lengths above `max(2, 1 + 2 * tolerance)` enter
the grid at that value. The summary statistics use the lengths as they
are.

This is the data-generating half of the check. The plotting method
([`plot.check_segment_length()`](https://animovement.dev/anicheck/reference/plot.check.md))
lives in anivis, mirroring the performance / see split in easystats.

## See also

[`plot.check_segment_length()`](https://animovement.dev/anicheck/reference/plot.check.md),
[`anicore::as_anisegment()`](https://animovement.dev/anicore/reference/as_anisegment.html),
[`anicore::anistructure()`](https://animovement.dev/anicore/reference/anistructure.html)

## Examples

``` r
af <- anicore::example_anipoint(n_obs = 50, n_individuals = 1) |>
  anicore::set_structure(anicore::example_structure())
chk <- check_segment_length(af)
chk
#> 
#> ── Check: segment lengths 
#> Share of frames more than 30% off the reference length, for 10 segments of
#> structure "keypoint" (robust CV in brackets):
#> • 1 | spine | 1 | 1: 62.0% [59.3%]
#> • 1 | head | 1 | 1: 60.0% [59.0%]
#> • 1 | shoulder_right | 1 | 1: 56.0% [57.9%]
#> • 1 | shoulder_left | 1 | 1: 66.0% [65.0%]
#> • 1 | hip_right | 1 | 1: 46.0% [37.0%]
#> • 1 | hip_left | 1 | 1: 54.0% [61.9%]
#> • 1 | thigh_right | 1 | 1: 62.0% [57.3%]
#> • 1 | thigh_left | 1 | 1: 56.0% [49.2%]
#> • 1 | shin_right | 1 | 1: 64.0% [65.8%]
#> • 1 | shin_left | 1 | 1: 38.0% [39.0%]
#> 
summary(chk)
#>    individual        segment session trial reference reference_source  n n_off
#> 1           1          spine       1     1  1.818649           median 50    31
#> 2           1           head       1     1  1.629934           median 50    30
#> 3           1 shoulder_right       1     1  1.453123           median 50    28
#> 4           1  shoulder_left       1     1  1.582974           median 50    33
#> 5           1      hip_right       1     1  1.565197           median 50    23
#> 6           1       hip_left       1     1  1.884591           median 50    27
#> 7           1    thigh_right       1     1  1.773552           median 50    31
#> 8           1     thigh_left       1     1  1.517423           median 50    28
#> 9           1     shin_right       1     1  1.760855           median 50    32
#> 10          1      shin_left       1     1  1.657705           median 50    19
#>    share_off   median       mad        cv
#> 1       0.62 1.818649 1.0788542 0.5932175
#> 2       0.60 1.629934 0.9622727 0.5903754
#> 3       0.56 1.453123 0.8414232 0.5790447
#> 4       0.66 1.582974 1.0287462 0.6498818
#> 5       0.46 1.565197 0.5794855 0.3702316
#> 6       0.54 1.884591 1.1666611 0.6190525
#> 7       0.62 1.773552 1.0161405 0.5729410
#> 8       0.56 1.517423 0.7459615 0.4915977
#> 9       0.64 1.760855 1.1589926 0.6581989
#> 10      0.38 1.657705 0.6461253 0.3897710

# When the segments were off
attr(chk, "off")
#>     individual        segment session trial start stop n_frames max_deviation
#> 1            1          spine       1     1     1    1        1     0.4629417
#> 2            1          spine       1     1     3    7        5     0.8934607
#> 3            1          spine       1     1    10   12        3     0.5874330
#> 4            1          spine       1     1    17   21        5     0.7339981
#> 5            1          spine       1     1    23   26        4     0.5015951
#> 6            1          spine       1     1    28   33        6     1.3054341
#> 7            1          spine       1     1    35   37        3     0.9072267
#> 8            1          spine       1     1    42   43        2     0.5615886
#> 9            1          spine       1     1    48   49        2     1.2197713
#> 10           1           head       1     1     1    4        4     0.8546798
#> 11           1           head       1     1     6    7        2     1.4518356
#> 12           1           head       1     1     9   11        3     1.2126735
#> 13           1           head       1     1    13   15        3     1.3677249
#> 14           1           head       1     1    19   19        1     0.6396866
#> 15           1           head       1     1    21   22        2     0.5656493
#> 16           1           head       1     1    25   25        1     0.6431874
#> 17           1           head       1     1    28   28        1     0.3408505
#> 18           1           head       1     1    30   31        2     0.7660708
#> 19           1           head       1     1    33   33        1     0.9467222
#> 20           1           head       1     1    35   36        2     0.5559340
#> 21           1           head       1     1    39   41        3     0.8187651
#> 22           1           head       1     1    43   45        3     0.4884381
#> 23           1           head       1     1    48   48        1     0.8712853
#> 24           1           head       1     1    50   50        1     0.6229127
#> 25           1 shoulder_right       1     1     1    1        1     0.5542795
#> 26           1 shoulder_right       1     1     5    7        3     1.3653128
#> 27           1 shoulder_right       1     1     9   10        2     1.1534013
#> 28           1 shoulder_right       1     1    13   13        1     0.3650842
#> 29           1 shoulder_right       1     1    16   17        2     0.5322496
#> 30           1 shoulder_right       1     1    20   20        1     0.8656660
#> 31           1 shoulder_right       1     1    22   24        3     0.5973590
#> 32           1 shoulder_right       1     1    26   27        2     1.7112476
#> 33           1 shoulder_right       1     1    29   32        4     0.7943246
#> 34           1 shoulder_right       1     1    35   35        1     0.8383701
#> 35           1 shoulder_right       1     1    37   38        2     1.1147182
#> 36           1 shoulder_right       1     1    42   43        2     0.7132963
#> 37           1 shoulder_right       1     1    46   49        4     1.0769838
#> 38           1  shoulder_left       1     1     2    3        2     0.7847619
#> 39           1  shoulder_left       1     1     5    7        3     1.4724167
#> 40           1  shoulder_left       1     1    10   10        1     1.0544725
#> 41           1  shoulder_left       1     1    12   15        4     0.8076325
#> 42           1  shoulder_left       1     1    17   18        2     0.3708121
#> 43           1  shoulder_left       1     1    20   25        6     0.8053343
#> 44           1  shoulder_left       1     1    27   28        2     0.5365686
#> 45           1  shoulder_left       1     1    30   30        1     0.8112793
#> 46           1  shoulder_left       1     1    32   35        4     1.2462201
#> 47           1  shoulder_left       1     1    38   39        2     1.0749045
#> 48           1  shoulder_left       1     1    41   46        6     1.0940274
#> 49           1      hip_right       1     1     2    2        1     0.4811279
#> 50           1      hip_right       1     1     8   10        3     1.3282354
#> 51           1      hip_right       1     1    12   14        3     0.5581687
#> 52           1      hip_right       1     1    16   16        1     0.5361030
#> 53           1      hip_right       1     1    19   20        2     0.6408247
#> 54           1      hip_right       1     1    22   22        1     0.5495231
#> 55           1      hip_right       1     1    25   26        2     0.7494433
#> 56           1      hip_right       1     1    28   30        3     0.6074807
#> 57           1      hip_right       1     1    35   35        1     0.3155229
#> 58           1      hip_right       1     1    43   47        5     0.9812120
#> 59           1      hip_right       1     1    50   50        1     0.4052419
#> 60           1       hip_left       1     1     1    2        2     0.6545971
#> 61           1       hip_left       1     1     4    4        1     0.3913786
#> 62           1       hip_left       1     1     7    8        2     0.4832870
#> 63           1       hip_left       1     1    10   13        4     1.2991697
#> 64           1       hip_left       1     1    17   17        1     0.7504274
#> 65           1       hip_left       1     1    19   19        1     0.6480032
#> 66           1       hip_left       1     1    22   26        5     0.9395280
#> 67           1       hip_left       1     1    28   28        1     0.9305781
#> 68           1       hip_left       1     1    30   30        1     0.5300252
#> 69           1       hip_left       1     1    35   36        2     0.6623524
#> 70           1       hip_left       1     1    39   39        1     0.6150782
#> 71           1       hip_left       1     1    41   42        2     0.5766802
#> 72           1       hip_left       1     1    47   50        4     0.8924887
#> 73           1    thigh_right       1     1     1    1        1     0.6314302
#> 74           1    thigh_right       1     1     3    6        4     0.9020680
#> 75           1    thigh_right       1     1    11   11        1     0.5384041
#> 76           1    thigh_right       1     1    13   13        1     0.8719663
#> 77           1    thigh_right       1     1    15   16        2     0.4467022
#> 78           1    thigh_right       1     1    18   19        2     0.5814511
#> 79           1    thigh_right       1     1    21   22        2     0.8402597
#> 80           1    thigh_right       1     1    24   29        6     0.8389120
#> 81           1    thigh_right       1     1    32   33        2     0.8593353
#> 82           1    thigh_right       1     1    36   37        2     0.4154239
#> 83           1    thigh_right       1     1    39   41        3     0.8010082
#> 84           1    thigh_right       1     1    44   47        4     1.0214399
#> 85           1    thigh_right       1     1    49   49        1     0.3340132
#> 86           1     thigh_left       1     1     1    4        4     1.4227958
#> 87           1     thigh_left       1     1     7    7        1     0.5389698
#> 88           1     thigh_left       1     1    11   11        1     0.4137906
#> 89           1     thigh_left       1     1    14   17        4     0.6681776
#> 90           1     thigh_left       1     1    20   22        3     0.7940393
#> 91           1     thigh_left       1     1    24   24        1     0.3098802
#> 92           1     thigh_left       1     1    27   30        4     0.7650286
#> 93           1     thigh_left       1     1    32   32        1     0.7271438
#> 94           1     thigh_left       1     1    36   41        6     0.6200713
#> 95           1     thigh_left       1     1    44   44        1     0.4573983
#> 96           1     thigh_left       1     1    48   49        2     0.6675451
#> 97           1     shin_right       1     1     1    2        2     0.5096149
#> 98           1     shin_right       1     1     4    5        2     0.7581320
#> 99           1     shin_right       1     1    11   15        5     0.7860806
#> 100          1     shin_right       1     1    17   18        2     0.6916901
#> 101          1     shin_right       1     1    21   23        3     0.6748321
#> 102          1     shin_right       1     1    25   25        1     0.6338547
#> 103          1     shin_right       1     1    27   27        1     0.5174738
#> 104          1     shin_right       1     1    29   36        8     1.5632789
#> 105          1     shin_right       1     1    39   43        5     0.8670075
#> 106          1     shin_right       1     1    46   48        3     1.1875998
#> 107          1      shin_left       1     1     1    3        3     0.7187820
#> 108          1      shin_left       1     1     6    6        1     0.8295895
#> 109          1      shin_left       1     1     9   10        2     0.4389259
#> 110          1      shin_left       1     1    12   14        3     0.6060504
#> 111          1      shin_left       1     1    17   17        1     0.8872260
#> 112          1      shin_left       1     1    23   24        2     1.1089717
#> 113          1      shin_left       1     1    27   28        2     1.9936946
#> 114          1      shin_left       1     1    31   31        1     0.3257938
#> 115          1      shin_left       1     1    38   38        1     0.4997744
#> 116          1      shin_left       1     1    40   40        1     0.9800427
#> 117          1      shin_left       1     1    42   42        1     1.2005405
#> 118          1      shin_left       1     1    48   48        1     0.4037116
```
