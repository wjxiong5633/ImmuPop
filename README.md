
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ImmuPop

<!-- badges: start -->
<!-- [![R-CMD-check](https://github.com/wjxiong5633/ImmunPop/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/wjxiong5633/ImmunPop/actions/workflows/R-CMD-check.yaml) -->
<!-- [![Codecov test coverage](https://codecov.io/gh/wjxiong5633/ImmunPop/graph/badge.svg)](https://app.codecov.io/gh/wjxiong5633/ImmunPop) -->

[![R-CMD-check](https://github.com/wjxiong5633/ImmunPop/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/wjxiong5633/ImmunPop/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/wjxiong5633/ImmunPop/graph/badge.svg)](https://app.codecov.io/gh/wjxiong5633/ImmunPop)
<!-- badges: end -->

**ImmuPop** is an R package designed to estimate key population immunity
metrics from individual serology data. The package provides the
following estimators:

-   **Geometric Mean Titer (GMT)**
-   **Proportion of Non-Naïve Individuals**
-   **Proportion of Population Immune**
-   **Relative Reduction in Reproductive Number (R0)**

These estimators help assess population immunity and predict the impact
of infectious diseases.

## Installation

You can install the development version of **ImmuPop** from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("wjxiong5633/ImmuPop")
#> 
#> ── R CMD build ─────────────────────────────────────────────────────────────────
#>          checking for file 'C:\Users\Weijia\AppData\Local\Temp\Rtmp6h2ugK\remotes464417ca1cc8\wjxiong5633-ImmuPop-4a5656c/DESCRIPTION' ...     checking for file 'C:\Users\Weijia\AppData\Local\Temp\Rtmp6h2ugK\remotes464417ca1cc8\wjxiong5633-ImmuPop-4a5656c/DESCRIPTION' ...   ✔  checking for file 'C:\Users\Weijia\AppData\Local\Temp\Rtmp6h2ugK\remotes464417ca1cc8\wjxiong5633-ImmuPop-4a5656c/DESCRIPTION'
#>       ─  preparing 'ImmuPop':
#>    checking DESCRIPTION meta-information ...  ✔  checking DESCRIPTION meta-information
#>       ─  checking for LF line-endings in source and make files and shell scripts
#>   ─  checking for empty or unneeded directories
#>   ─  building 'ImmuPop_0.1.0.tar.gz'
#>      
#> 
```

## Example Usage

### Load Required Libraries

Before using the package, load **ImmuPop** and other required libraries:

``` r
library(ImmuPop)
library(dplyr)
library(rlist)
library(MCMCpack)
```

### Load Raw Data

The package includes example data (`ImmuPop_raw_data`), which contains
columns such as `time`, `epi`, `bsl`, `age`, and `raw_titer`.

``` r
data("ImmuPop_raw_data")
knitr::kable(head(ImmuPop_raw_data, 10), digits = 3, row.names = F)
```

|  uid | bsl | epi | age | time | raw_titer |
|-----:|:----|----:|----:|-----:|----------:|
| 1001 | yes |   1 |  31 |   28 |        10 |
| 1001 | no  |   1 |  31 |  308 |       160 |
| 1002 | yes |   1 |  79 |   50 |         5 |
| 1002 | no  |   1 |  79 |  300 |       320 |
| 1003 | yes |   1 |  51 |   47 |        20 |
| 1003 | no  |   1 |  51 |  340 |       160 |
| 1004 | yes |   1 |  14 |   16 |         5 |
| 1004 | no  |   1 |  14 |  338 |       320 |
| 1005 | yes |   1 |  67 |   19 |        40 |
| 1005 | no  |   1 |  67 |  343 |        80 |

### Data Preparation

Use the `generate_data()` function to preprocess raw data and categorize
age groups:

``` r
data_example <- generate_data(ImmuPop_raw_data, cut_age = c(0, 18, 50, 100))
knitr::kable(head(data_example, 10), digits = 3, row.names = F)
```

|  uid | bsl | epi | age | time | raw_titer | agegp1    | titer_level |
|-----:|:----|----:|----:|-----:|----------:|:----------|------------:|
| 1001 | yes |   1 |  31 |   28 |        10 | \[18,50)  |           2 |
| 1001 | no  |   1 |  31 |  308 |       160 | \[18,50)  |           6 |
| 1002 | yes |   1 |  79 |   50 |         5 | \[50,100) |           1 |
| 1002 | no  |   1 |  79 |  300 |       320 | \[50,100) |           7 |
| 1003 | yes |   1 |  51 |   47 |        20 | \[50,100) |           3 |
| 1003 | no  |   1 |  51 |  340 |       160 | \[50,100) |           6 |
| 1004 | yes |   1 |  14 |   16 |         5 | \[0,18)   |           1 |
| 1004 | no  |   1 |  14 |  338 |       320 | \[0,18)   |           7 |
| 1005 | yes |   1 |  67 |   19 |        40 | \[50,100) |           4 |
| 1005 | no  |   1 |  67 |  343 |        80 | \[50,100) |           5 |

### Define Population Parameters

#### Age Proportions

Define age group proportions based on the `cut_age` parameter:

``` r
age_prop <- c(0.2, 0.4, 0.4) # Adjust proportions according to your population
```

#### Contact Matrix

Define the **contact matrix**

``` r
contact_matrix <- matrix(
  c(22, 16, 15, 24, 28, 30, 18, 32, 35),
  nrow = 3, byrow = TRUE
)
```

Or can use **socialmixr** package to generate a contact matrix:

``` r
library(socialmixr)
data(polymod)
contact_matrix(polymod, countries = "United Kingdom", age.limits = c(0, 1, 5, 15))
#> Removing participants that have contacts without age information. To change this behaviour, set the 'missing.contact.age' option
#> $matrix
#>          contact.age.group
#> age.group      [0,1)     [1,5)   [5,15)      15+
#>    [0,1)  0.40000000 0.8000000 1.266667 5.933333
#>    [1,5)  0.11250000 1.9375000 1.462500 5.450000
#>    [5,15) 0.02450980 0.5049020 7.946078 6.215686
#>    15+    0.03230337 0.3581461 1.290730 9.594101
#> 
#> $participants
#>    age.group participants proportion
#>       <char>        <int>      <num>
#> 1:     [0,1)           15 0.01483680
#> 2:     [1,5)           80 0.07912957
#> 3:    [5,15)          204 0.20178042
#> 4:       15+          712 0.70425321
```

#### Protection Effects

Define protection effects for children and adults based on **HAI titer
levels** (e.g. 40% HI associated with 50% protection):

``` r
# each item of vector represent the protection of each titer level (e.g. 1-10 titer level)
protect_child <- c(0.1, 0.2, 0.3, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8)
protect_adult <- c(0.1, 0.2, 0.3, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8)
```

------------------------------------------------------------------------

## Immunity Estimation

### Estimating Immunity at a Specific Time Point

To estimate immunity for a **specific time point** (e.g., `time = 15`):

``` r
data_example_t <- data_example %>% filter(time == 15)

result <- ImmuPop_timet_est(
  df = data_example_t,
  protect_c = protect_child,
  protect_a = protect_adult,
  age_prop = age_prop,
  contact_matrix = contact_matrix,
  sim_num = 100
)

knitr::kable(result, digits = 3, row.names = F)
```

| estimator | value | CI_lwr | CI_upr |
|:----------|------:|-------:|-------:|
| pop_immun | 0.182 |  0.140 |  0.360 |
| RR_R0     | 0.189 |  0.173 |  0.371 |
| GMT       | 6.200 |  2.495 | 10.505 |
| prop_5    | 0.400 |  0.000 |  0.400 |

### Estimating Immunity Across All Time Points

To estimate immunity across **all time points**, it will return the
result of the time point that contains all age groups.

``` r
est_res_all <- ImmuPop_allt_est(
  df_long = data_example,
  protect_c = protect_child,
  protect_a = protect_adult,
  age_prop = age_prop,
  contact_matrix = contact_matrix,
  sim_num = 100
)

knitr::kable(est_res_all, digits = 3, row.names = F)
```

| estimator | time |   value |  CI_lwr |  CI_upr |
|:----------|-----:|--------:|--------:|--------:|
| GMT       |    2 |  19.530 |   5.986 |  28.443 |
| GMT       |    3 |  13.495 |   6.733 |  26.979 |
| GMT       |    6 |  17.914 |  12.000 |  26.020 |
| GMT       |    7 |  11.614 |   4.400 |  19.448 |
| GMT       |   11 |  20.737 |   9.052 |  32.985 |
| GMT       |   15 |   6.800 |   1.800 |  10.200 |
| GMT       |   17 |  11.800 |   3.190 |  20.105 |
| GMT       |   24 |  19.013 |   6.923 |  28.513 |
| GMT       |   25 |   9.758 |   4.591 |  16.533 |
| GMT       |   26 |  21.113 |   8.547 |  34.280 |
| GMT       |   30 |   8.800 |   3.295 |  14.230 |
| GMT       |   33 |  20.117 |   7.375 |  32.010 |
| GMT       |   50 |  14.645 |   4.195 |  28.073 |
| GMT       |  307 | 517.000 | 326.340 | 722.390 |
| GMT       |  312 | 559.200 | 207.255 | 956.250 |
| GMT       |  315 | 297.400 | 106.680 | 485.430 |
| GMT       |  317 | 157.400 |  60.900 | 282.160 |
| GMT       |  318 | 410.510 | 236.592 | 704.000 |
| GMT       |  322 | 437.410 |  67.764 | 812.258 |
| GMT       |  324 | 322.300 |  52.825 | 551.890 |
| GMT       |  338 | 186.510 |  87.600 | 400.000 |
| GMT       |  340 | 159.700 |  73.530 | 300.535 |
| GMT       |  345 | 317.324 | 110.557 | 508.896 |
| GMT       |  348 | 202.800 |  78.240 | 376.665 |
| GMT       |  801 |  16.485 |  14.000 |  20.000 |
| GMT       |  805 |  26.828 |  16.894 |  34.828 |
| GMT       |  807 |  21.197 |   7.919 |  27.178 |
| GMT       |  810 |   9.044 |   5.280 |  12.525 |
| GMT       |  811 |  19.808 |  10.843 |  29.304 |
| GMT       |  814 |  18.131 |   4.231 |  27.139 |
| GMT       |  822 |   9.843 |   4.910 |  14.504 |
| GMT       |  827 |  16.655 |   7.874 |  29.924 |
| GMT       |  833 |   4.600 |   1.990 |   6.800 |
| GMT       |  839 |  13.479 |   6.499 |  21.969 |
| GMT       |  845 |  17.154 |   5.071 |  29.888 |
| GMT       | 1016 | 625.215 | 166.499 | 976.559 |
| GMT       | 1019 | 322.600 |  59.895 | 546.620 |
| GMT       | 1020 | 158.200 |  39.290 | 392.480 |
| GMT       | 1022 | 400.000 | 205.255 | 737.600 |
| GMT       | 1025 | 119.500 |  38.965 | 209.305 |
| GMT       | 1030 | 195.238 | 105.564 | 278.644 |
| GMT       | 1032 | 186.600 |  47.190 | 366.220 |
| GMT       | 1033 | 297.742 | 166.570 | 805.945 |
| GMT       | 1037 | 225.870 | 139.022 | 327.737 |
| GMT       | 1039 | 142.495 |  85.677 | 207.130 |
| GMT       | 1045 | 137.800 |  41.025 | 205.695 |
| RR_R0     |    2 |   0.231 |   0.159 |   0.358 |
| RR_R0     |    3 |   0.312 |   0.256 |   0.377 |
| RR_R0     |    6 |   0.307 |   0.257 |   0.414 |
| RR_R0     |    7 |   0.280 |   0.241 |   0.362 |
| RR_R0     |   11 |   0.384 |   0.323 |   0.476 |
| RR_R0     |   15 |   0.179 |   0.176 |   0.323 |
| RR_R0     |   17 |   0.330 |   0.311 |   0.425 |
| RR_R0     |   24 |   0.359 |   0.299 |   0.451 |
| RR_R0     |   25 |   0.259 |   0.214 |   0.402 |
| RR_R0     |   26 |   0.274 |   0.232 |   0.420 |
| RR_R0     |   30 |   0.246 |   0.199 |   0.374 |
| RR_R0     |   33 |   0.402 |   0.316 |   0.479 |
| RR_R0     |   50 |   0.287 |   0.186 |   0.382 |
| RR_R0     |  307 |   0.709 |   0.611 |   0.718 |
| RR_R0     |  312 |   0.738 |   0.618 |   0.742 |
| RR_R0     |  315 |   0.683 |   0.553 |   0.704 |
| RR_R0     |  317 |   0.626 |   0.498 |   0.658 |
| RR_R0     |  318 |   0.646 |   0.618 |   0.677 |
| RR_R0     |  322 |   0.621 |   0.531 |   0.672 |
| RR_R0     |  324 |   0.653 |   0.540 |   0.673 |
| RR_R0     |  338 |   0.609 |   0.556 |   0.654 |
| RR_R0     |  340 |   0.608 |   0.475 |   0.639 |
| RR_R0     |  345 |   0.654 |   0.588 |   0.683 |
| RR_R0     |  348 |   0.677 |   0.534 |   0.691 |
| RR_R0     |  801 |   0.281 |   0.249 |   0.351 |
| RR_R0     |  805 |   0.336 |   0.274 |   0.437 |
| RR_R0     |  807 |   0.269 |   0.217 |   0.415 |
| RR_R0     |  810 |   0.208 |   0.155 |   0.317 |
| RR_R0     |  811 |   0.308 |   0.273 |   0.433 |
| RR_R0     |  814 |   0.269 |   0.169 |   0.366 |
| RR_R0     |  822 |   0.313 |   0.277 |   0.377 |
| RR_R0     |  827 |   0.242 |   0.183 |   0.334 |
| RR_R0     |  833 |   0.209 |   0.186 |   0.353 |
| RR_R0     |  839 |   0.337 |   0.291 |   0.421 |
| RR_R0     |  845 |   0.394 |   0.307 |   0.459 |
| RR_R0     | 1016 |   0.670 |   0.600 |   0.705 |
| RR_R0     | 1019 |   0.653 |   0.507 |   0.682 |
| RR_R0     | 1020 |   0.625 |   0.513 |   0.671 |
| RR_R0     | 1022 |   0.642 |   0.598 |   0.670 |
| RR_R0     | 1025 |   0.631 |   0.493 |   0.658 |
| RR_R0     | 1030 |   0.617 |   0.543 |   0.638 |
| RR_R0     | 1032 |   0.651 |   0.542 |   0.658 |
| RR_R0     | 1033 |   0.674 |   0.615 |   0.701 |
| RR_R0     | 1037 |   0.635 |   0.554 |   0.657 |
| RR_R0     | 1039 |   0.603 |   0.514 |   0.620 |
| RR_R0     | 1045 |   0.643 |   0.560 |   0.668 |
| pop_immun |    2 |   0.222 |   0.165 |   0.393 |
| pop_immun |    3 |   0.293 |   0.245 |   0.387 |
| pop_immun |    6 |   0.313 |   0.257 |   0.416 |
| pop_immun |    7 |   0.269 |   0.186 |   0.384 |
| pop_immun |   11 |   0.367 |   0.282 |   0.480 |
| pop_immun |   15 |   0.180 |   0.140 |   0.328 |
| pop_immun |   17 |   0.320 |   0.259 |   0.410 |
| pop_immun |   24 |   0.326 |   0.235 |   0.459 |
| pop_immun |   25 |   0.252 |   0.193 |   0.425 |
| pop_immun |   26 |   0.288 |   0.227 |   0.424 |
| pop_immun |   30 |   0.245 |   0.184 |   0.370 |
| pop_immun |   33 |   0.392 |   0.312 |   0.490 |
| pop_immun |   50 |   0.286 |   0.202 |   0.383 |
| pop_immun |  307 |   0.710 |   0.632 |   0.722 |
| pop_immun |  312 |   0.729 |   0.617 |   0.740 |
| pop_immun |  315 |   0.679 |   0.582 |   0.707 |
| pop_immun |  317 |   0.631 |   0.516 |   0.664 |
| pop_immun |  318 |   0.654 |   0.620 |   0.691 |
| pop_immun |  322 |   0.616 |   0.522 |   0.662 |
| pop_immun |  324 |   0.631 |   0.502 |   0.680 |
| pop_immun |  338 |   0.605 |   0.569 |   0.649 |
| pop_immun |  340 |   0.598 |   0.477 |   0.635 |
| pop_immun |  345 |   0.646 |   0.575 |   0.677 |
| pop_immun |  348 |   0.664 |   0.523 |   0.684 |
| pop_immun |  801 |   0.276 |   0.237 |   0.354 |
| pop_immun |  805 |   0.348 |   0.275 |   0.456 |
| pop_immun |  807 |   0.251 |   0.190 |   0.401 |
| pop_immun |  810 |   0.224 |   0.177 |   0.324 |
| pop_immun |  811 |   0.349 |   0.285 |   0.437 |
| pop_immun |  814 |   0.250 |   0.174 |   0.371 |
| pop_immun |  822 |   0.287 |   0.205 |   0.382 |
| pop_immun |  827 |   0.266 |   0.189 |   0.355 |
| pop_immun |  833 |   0.192 |   0.140 |   0.329 |
| pop_immun |  839 |   0.308 |   0.236 |   0.385 |
| pop_immun |  845 |   0.375 |   0.278 |   0.455 |
| pop_immun | 1016 |   0.666 |   0.593 |   0.700 |
| pop_immun | 1019 |   0.638 |   0.493 |   0.671 |
| pop_immun | 1020 |   0.629 |   0.530 |   0.690 |
| pop_immun | 1022 |   0.641 |   0.596 |   0.681 |
| pop_immun | 1025 |   0.630 |   0.514 |   0.655 |
| pop_immun | 1030 |   0.630 |   0.539 |   0.656 |
| pop_immun | 1032 |   0.629 |   0.527 |   0.653 |
| pop_immun | 1033 |   0.675 |   0.604 |   0.701 |
| pop_immun | 1037 |   0.635 |   0.563 |   0.659 |
| pop_immun | 1039 |   0.600 |   0.519 |   0.619 |
| pop_immun | 1045 |   0.631 |   0.532 |   0.658 |
| prop_5    |    2 |   0.700 |   0.248 |   0.900 |
| prop_5    |    3 |   0.800 |   0.600 |   0.905 |
| prop_5    |    6 |   0.600 |   0.600 |   1.000 |
| prop_5    |    7 |   0.600 |   0.000 |   0.800 |
| prop_5    |   11 |   0.883 |   0.633 |   1.000 |
| prop_5    |   15 |   0.400 |   0.000 |   0.400 |
| prop_5    |   17 |   0.400 |   0.000 |   0.800 |
| prop_5    |   24 |   0.800 |   0.600 |   0.800 |
| prop_5    |   25 |   0.400 |   0.000 |   0.800 |
| prop_5    |   26 |   0.800 |   0.800 |   1.000 |
| prop_5    |   30 |   0.400 |   0.000 |   0.800 |
| prop_5    |   33 |   0.800 |   0.600 |   1.000 |
| prop_5    |   50 |   0.400 |   0.000 |   0.800 |
| prop_5    |  307 |   1.000 |   0.790 |   1.000 |
| prop_5    |  312 |   1.000 |   1.000 |   1.000 |
| prop_5    |  315 |   1.000 |   0.600 |   1.000 |
| prop_5    |  317 |   1.000 |   0.600 |   1.000 |
| prop_5    |  318 |   1.000 |   1.000 |   1.000 |
| prop_5    |  322 |   1.000 |   0.800 |   1.000 |
| prop_5    |  324 |   1.000 |   0.600 |   1.000 |
| prop_5    |  338 |   1.000 |   1.000 |   1.000 |
| prop_5    |  340 |   1.000 |   0.600 |   1.000 |
| prop_5    |  345 |   1.000 |   1.000 |   1.000 |
| prop_5    |  348 |   1.000 |   0.600 |   1.000 |
| prop_5    |  801 |   1.000 |   1.000 |   1.000 |
| prop_5    |  805 |   0.900 |   0.900 |   1.000 |
| prop_5    |  807 |   0.640 |   0.240 |   0.920 |
| prop_5    |  810 |   0.600 |   0.095 |   0.800 |
| prop_5    |  811 |   0.920 |   0.520 |   1.000 |
| prop_5    |  814 |   0.400 |   0.000 |   0.800 |
| prop_5    |  822 |   0.500 |   0.200 |   0.600 |
| prop_5    |  827 |   0.700 |   0.600 |   0.900 |
| prop_5    |  833 |   0.200 |   0.000 |   0.200 |
| prop_5    |  839 |   0.600 |   0.200 |   0.905 |
| prop_5    |  845 |   0.600 |   0.000 |   1.000 |
| prop_5    | 1016 |   1.000 |   1.000 |   1.000 |
| prop_5    | 1019 |   1.000 |   0.600 |   1.000 |
| prop_5    | 1020 |   1.000 |   0.600 |   1.000 |
| prop_5    | 1022 |   1.000 |   1.000 |   1.000 |
| prop_5    | 1025 |   1.000 |   0.600 |   1.000 |
| prop_5    | 1030 |   1.000 |   1.000 |   1.000 |
| prop_5    | 1032 |   1.000 |   0.600 |   1.000 |
| prop_5    | 1033 |   1.000 |   1.000 |   1.000 |
| prop_5    | 1037 |   1.000 |   0.600 |   1.000 |
| prop_5    | 1039 |   1.000 |   0.900 |   1.000 |
| prop_5    | 1045 |   1.000 |   0.600 |   1.000 |

### Estimating Baseline Population Immunity (Pre-Epidemic)

To estimate **baseline population immunity** before an epidemic:

``` r
df_long_bsl <- data_example %>% filter(bsl == "yes")

est_res_bsl <- ImmuPop_bsl_est(
  df = df_long_bsl,
  protect_c = protect_child,
  protect_a = protect_adult,
  age_prop = age_prop,
  contact_matrix = contact_matrix,
  sim_num = 100
)

knitr::kable(est_res_bsl, digits = 3, row.names = F)
```

| estimator | epi |  value | CI_lwr | CI_upr |
|:----------|----:|-------:|-------:|-------:|
| GMT       |   1 | 13.399 | 11.721 | 15.175 |
| GMT       |   2 | 14.526 | 12.932 | 16.170 |
| RR_R0     |   1 |  0.263 |  0.243 |  0.289 |
| RR_R0     |   2 |  0.283 |  0.264 |  0.301 |
| pop_immun |   1 |  0.261 |  0.240 |  0.289 |
| pop_immun |   2 |  0.279 |  0.259 |  0.308 |
| prop_5    |   1 |  0.758 |  0.675 |  0.815 |
| prop_5    |   2 |  0.789 |  0.721 |  0.843 |
