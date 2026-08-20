

<!-- README.md is generated from README.qmd. Please edit that file -->

# anicheck <a href="https://animovement.dev/anicheck/"><img src="man/figures/logo.png" align="right" height="139" alt="anicheck hex logo" /></a>

<!-- badges: start -->

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21033042.svg)](https://doi.org/10.5281/zenodo.21033042)
[![R-CMD-check](https://github.com/animovement/anicheck/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/animovement/anicheck/actions/workflows/R-CMD-check.yaml)
[![anicheck status
badge](https://animovement.r-universe.dev/badges/anicheck)](https://animovement.r-universe.dev)
[![codecov](https://codecov.io/gh/animovement/anicheck/graph/badge.svg?token=Pf5n3yzLzK)](https://codecov.io/gh/animovement/anicheck)
[![Chat on
Zulip](https://img.shields.io/badge/chat-Zulip-6492FE?logo=zulip&logoColor=white)](https://animovement.zulipchat.com)
<!-- badges: end -->

*An R package for diagnosing movement data quality*

The primary aim of the *anicheck* package is to provide diagnostic tools
for assessing movement data quality, including functions to identify
missing values, temporal gaps, and spatial outliers.

## Installation

You can install the development version of *anicheck* with:

``` r
install.packages('anicheck', repos = c('https://animovement.r-universe.dev', 'https://cloud.r-project.org'))
```

Once you have installed the package, you can load it with:

``` r
library("anicheck")
```

## Citation

If you enjoy the package, please make sure to cite it. If you find a
bug, feel free to open an issue.

To cite *anicheck* in publications use:

``` r
citation("anicheck")
#> To cite anicheck in publications, please cite the animovement toolbox
#> as a whole (the first entry below). If your work used only anicheck,
#> you may cite the package directly instead (the second entry).
#> 
#>   Roald-Arbøl M (2026). "animovement: An R toolbox for analysing
#>   movement across space and time." doi:10.5281/zenodo.13235277
#>   <https://doi.org/10.5281/zenodo.13235277>.
#>   <https://animovement.dev/animovement/>.
#> 
#>   Roald-Arbøl M (2026). "anicheck: An R package for diagnosing movement
#>   data quality." doi:10.5281/zenodo.21033042
#>   <https://doi.org/10.5281/zenodo.21033042>.
#>   <https://animovement.dev/anicheck/>.
#> 
#> To see these entries in BibTeX format, use 'print(<citation>,
#> bibtex=TRUE)', 'toBibtex(.)', or set
#> 'options(citation.bibtex.max=999)'.
```
