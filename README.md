
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ImmuPop

<!-- badges: start -->

[![R-CMD-check](https://github.com/wjxiong5633/ImmuPop/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/wjxiong5633/ImmuPop/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**ImmuPop** is an R package designed to estimate key population immunity
metrics from individual serology data. The package provides the
following estimators:

- **Geometric Mean Titer (GMT)**
- **Proportion of Non-Naïve Individuals**
- **Proportion of Population Immune**
- **Relative Reduction in Reproductive Number (R0)**

These estimators help assess population immunity and predict the impact
of infectious diseases.

## Installation

You can install the development version of **ImmuPop** from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("wjxiong5633/ImmuPop")
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
knitr::kable(ImmuPop_raw_data, digits = 3, row.names = F)
```

|  uid | time | epi | bsl | raw_titer | age |
|-----:|-----:|----:|:----|----------:|----:|
| 1001 |  100 |   1 | yes |         5 |  10 |
| 1001 |  150 |   1 | no  |        40 |  10 |
| 1002 |  100 |   1 | yes |        10 |  25 |
| 1002 |  150 |   1 | no  |       160 |  25 |
| 1003 |  100 |   1 | yes |        10 |  55 |
| 1003 |  150 |   1 | no  |        20 |  55 |
| 1004 |  200 |   2 | yes |         5 |  14 |
| 1004 |  250 |   2 | no  |        80 |  14 |
| 1005 |  200 |   2 | yes |        10 |  40 |
| 1005 |  250 |   2 | no  |       160 |  40 |
| 1006 |  200 |   2 | yes |        20 |  64 |
| 1006 |  250 |   2 | no  |        80 |  64 |

### Data Preparation

Use the `generate_data()` function to preprocess raw data and categorize
age groups:

``` r
data_example <- generate_data(ImmuPop_raw_data, cut_age = c(0, 18, 50, 100))
knitr::kable(data_example, digits = 3, row.names = F) 
```

|  uid | time | epi | bsl | raw_titer | age | agegp1    | titer_level |
|-----:|-----:|----:|:----|----------:|----:|:----------|------------:|
| 1001 |  100 |   1 | yes |         5 |  10 | \[0,18)   |           1 |
| 1001 |  150 |   1 | no  |        40 |  10 | \[0,18)   |           4 |
| 1002 |  100 |   1 | yes |        10 |  25 | \[18,50)  |           2 |
| 1002 |  150 |   1 | no  |       160 |  25 | \[18,50)  |           6 |
| 1003 |  100 |   1 | yes |        10 |  55 | \[50,100) |           2 |
| 1003 |  150 |   1 | no  |        20 |  55 | \[50,100) |           3 |
| 1004 |  200 |   2 | yes |         5 |  14 | \[0,18)   |           1 |
| 1004 |  250 |   2 | no  |        80 |  14 | \[0,18)   |           5 |
| 1005 |  200 |   2 | yes |        10 |  40 | \[18,50)  |           2 |
| 1005 |  250 |   2 | no  |       160 |  40 | \[18,50)  |           6 |
| 1006 |  200 |   2 | yes |        20 |  64 | \[50,100) |           3 |
| 1006 |  250 |   2 | no  |        80 |  64 | \[50,100) |           5 |

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
  c(22, 16, 15,24, 28, 30, 18, 32, 35),
  nrow = 3, byrow = TRUE
)
```

#### Protection Effects

Define protection effects for children and adults based on **HAI titer
levels** (e.g. 40% HI associated with 50% protection):

``` r
#each item of vector represent the protection of each titer level (e.g. 1-10 titer level)
protect_c <- c(0.1, 0.2, 0.3, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8)
protect_a <- c(0.1, 0.2, 0.3, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8)
```

------------------------------------------------------------------------

## Immunity Estimation

### Estimating Immunity at a Specific Time Point

To estimate immunity for a **specific time point** (e.g., `time = 200`):

``` r
data_example_t <- data_example %>% filter(time == 200)

result <- ImmuPop_timet_est(
  df = data_example_t,
  protect_c = protect_c,
  protect_a = protect_a,
  age_prop = age_prop,
  contact_matrix = contact_matrix,
  sim_num = 100
)

knitr::kable(result, digits = 3, row.names = F)
```

| estimator | value | CI_lwr | CI_upr |
|:----------|------:|-------:|-------:|
| pop_immun | 0.220 |  0.180 |  0.367 |
| RR_R0     | 0.232 |  0.219 |  0.335 |
| GMT       | 7.200 |  1.695 | 10.600 |
| prop_5    | 0.400 |  0.000 |  0.800 |

### Estimating Immunity Across All Time Points

To estimate immunity across **all time points**:

``` r
est_res_all <- ImmuPop_allt_est(
  df_long = data_example,
  protect_c = protect_c,
  protect_a = protect_a,
  age_prop = age_prop,
  contact_matrix = contact_matrix,
  sim_num = 100
)

knitr::kable(est_res_all, digits = 3, row.names = F)
```

| estimator | time |  value | CI_lwr | CI_upr |
|:----------|-----:|-------:|-------:|-------:|
| GMT       |  100 |  4.800 |  2.200 |  7.705 |
| GMT       |  150 | 42.100 |  8.190 | 73.210 |
| GMT       |  200 |  6.500 |  2.295 | 11.505 |
| GMT       |  250 | 56.200 | 19.360 | 92.440 |
| RR_R0     |  100 |  0.186 |  0.177 |  0.361 |
| RR_R0     |  150 |  0.451 |  0.391 |  0.555 |
| RR_R0     |  200 |  0.228 |  0.206 |  0.358 |
| RR_R0     |  250 |  0.569 |  0.514 |  0.606 |
| pop_immun |  100 |  0.181 |  0.156 |  0.377 |
| pop_immun |  150 |  0.463 |  0.380 |  0.540 |
| pop_immun |  200 |  0.217 |  0.180 |  0.364 |
| pop_immun |  250 |  0.570 |  0.531 |  0.611 |
| prop_5    |  100 |  0.000 |  0.000 |  0.400 |
| prop_5    |  150 |  0.600 |  0.400 |  1.000 |
| prop_5    |  200 |  0.400 |  0.000 |  0.400 |
| prop_5    |  250 |  1.000 |  0.600 |  1.000 |

### Estimating Baseline Population Immunity (Pre-Epidemic)

To estimate **baseline population immunity** before an epidemic:

``` r
df_long_bsl <- data_example %>% filter(bsl == "yes")

est_res_bsl <- ImmuPop_bsl_est(
  df = df_long_bsl,
  protect_c = protect_c,
  protect_a = protect_a,
  age_prop = age_prop,
  contact_matrix = contact_matrix,
  sim_num = 100
)

knitr::kable(est_res_bsl, digits = 3, row.names = F)
```

| estimator | epi | value | CI_lwr | CI_upr |
|:----------|----:|------:|-------:|-------:|
| GMT       |   1 | 5.100 |  1.895 |  8.105 |
| GMT       |   2 | 7.500 |  3.095 | 12.115 |
| RR_R0     |   1 | 0.188 |  0.181 |  0.315 |
| RR_R0     |   2 | 0.231 |  0.222 |  0.351 |
| pop_immun |   1 | 0.180 |  0.160 |  0.295 |
| pop_immun |   2 | 0.217 |  0.180 |  0.353 |
| prop_5    |   1 | 0.000 |  0.000 |  0.400 |
| prop_5    |   2 | 0.400 |  0.000 |  0.800 |
