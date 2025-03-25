
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ImmuPop

<!-- badges: start -->

[![R-CMD-check](https://github.com/wjxiong5633/ImmuPop/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/wjxiong5633/ImmuPop/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**ImmuPop** is an R package designed to estimate four key population
immunity metrics from individual serology data: - **Geometric Mean Titer
(GMT)**

-   **Proportion of Non-Naive Individuals**

-   **Proportion of Population Immune**

-   **Relative Reduction in Reproductive Number**

These estimators provide insights into population immunity, which can be
crucial for understanding and predicting the impact of infectious
diseases.

## Installation

You can install the development version of the **ImmuPop** package from
GitHub using the following command:

``` r
# install.packages("devtools")
devtools::install_github("wjxiong5633/ImmuPop")
#> Using GitHub PAT from the git credential store.
#> Skipping install of 'ImmuPop' from a github remote, the SHA1 (f39d0371) has not changed since last install.
#>   Use `force = TRUE` to force installation
```

## Example Usage

First, load the necessary libraries and the **ImmuPop** package:

``` r
library(ImmuPop)
library(dplyr)
library(rlist)
library(MCMCpack)
```

### Sample Data

Here is an example of individual-level data that can be used to estimate
immunity:

First, load your own dataset, contains columns time, epi, bsl, age,

``` r
data("ImmuPop_raw_data")
knitr::kable(ImmuPop_raw_data, caption = "Raw dataset", digits = 3)
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

Raw dataset

``` r
data_example <- generate_data(ImmuPop_raw_data, cut_age = c(0,18,50, 100))
knitr::kable(data_example, caption = "Tidy dataset for estimation", digits = 3)
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

Tidy dataset for estimation

### Setting Age Proportions and Contact Matrix

Set the age group proportions and the contact matrix. These values
should be consistent with the structure of your population.

``` r
age_prop <- c(0.2, 0.4, 0.4)  # Proportions for age groups based on your cut age above 
contact_matrix <- matrix(c(22, 16, 15, 24, 28, 30, 18, 32,  35), nrow = 3, byrow = TRUE)
```

### Setting Protection Effects

Define the protection effect for different HAI titer levels for children
and adults, make sure the length of vector is equal to the maximum titer
levels.

``` r
## max(data_example$titer_level) = 10
protect_c <- c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6,0.7,0.8,0.9,0.95)
protect_a <- c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6,0.7,0.8,0.9,0.95)
```

### Estimating Immunity for a Specific Time Point

To obtain immunity estimators for a specific time point (e.g., time =
282):

``` r
data_example_t <- data_example %>% filter(time == 200)

df = data_example_t

result <- ImmuPop_timet_est(
  df = data_example_t,
  protect_c = protect_c,
  protect_a = protect_a,
  age_prop = age_prop,
  contact_matrix = contact_matrix,
  sim_num = 100
)


knitr::kable(result, caption = "Estimation at time 200", digits = 3)
```

| estimator | value | CI_lwr | CI_upr |
|:----------|------:|-------:|-------:|
| pop_immun | 0.219 |  0.180 |  0.367 |
| RR_R0     | 0.231 |  0.209 |  0.408 |
| GMT       | 7.300 |  1.970 | 11.105 |
| prop_5    | 0.400 |  0.000 |  0.610 |

Estimation at time 200

### Estimating Immunity Across All Time Points

To obtain immunity estimates for all time points:

``` r
est_res_all <- ImmuPop_allt_est(data_example, protect_c, protect_a, age_prop, contact_matrix, sim_num = 100)

knitr::kable(est_res_all, caption = "Estimation at each time point", digits = 3)
```

| estimator | time |  value | CI_lwr | CI_upr |
|:----------|-----:|-------:|-------:|-------:|
| GMT       |  100 |  5.000 |  1.695 |  7.705 |
| GMT       |  150 | 40.800 |  8.285 | 71.030 |
| GMT       |  200 |  7.400 |  2.600 | 12.010 |
| GMT       |  250 | 62.700 | 15.910 | 96.815 |
| RR_R0     |  100 |  0.186 |  0.179 |  0.390 |
| RR_R0     |  150 |  0.433 |  0.346 |  0.544 |
| RR_R0     |  200 |  0.229 |  0.209 |  0.389 |
| RR_R0     |  250 |  0.538 |  0.481 |  0.646 |
| pop_immun |  100 |  0.180 |  0.160 |  0.383 |
| pop_immun |  150 |  0.441 |  0.342 |  0.542 |
| pop_immun |  200 |  0.220 |  0.177 |  0.373 |
| pop_immun |  250 |  0.539 |  0.489 |  0.651 |
| prop_5    |  100 |  0.000 |  0.000 |  0.400 |
| prop_5    |  150 |  0.800 |  0.200 |  1.000 |
| prop_5    |  200 |  0.400 |  0.000 |  0.800 |
| prop_5    |  250 |  1.000 |  0.600 |  1.000 |

Estimation at each time point

### Estimating Baseline Immunity (Pre-Epidemic)

To obtain estimators for the baseline period (pre-epidemic) for each
epidemic:

``` r
df_long_bsl <- data_example %>% filter(bsl == "yes")
est_res_bsl <- ImmuPop_bsl_est(df_long_bsl, protect_c, protect_a, age_prop, contact_matrix, sim_num = 100)
knitr::kable(est_res_bsl, caption = "Estimation at each time point", digits = 3)
```

|     | estimator | epi | value | CI_lwr | CI_upr |
|:----|:----------|----:|------:|-------:|-------:|
| 1.1 | GMT       |   1 | 5.000 |  2.400 |  8.010 |
| 2.1 | GMT       |   2 | 7.800 |  2.885 | 12.010 |
| 1.2 | RR_R0     |   1 | 0.190 |  0.179 |  0.387 |
| 2.2 | RR_R0     |   2 | 0.233 |  0.203 |  0.404 |
| 1.3 | pop_immun |   1 | 0.181 |  0.159 |  0.356 |
| 2.3 | pop_immun |   2 | 0.220 |  0.178 |  0.374 |
| 1.4 | prop_5    |   1 | 0.000 |  0.000 |  0.400 |
| 2.4 | prop_5    |   2 | 0.400 |  0.000 |  0.800 |

Estimation at each time point

This package provides powerful tools for estimating immunity, reduction
in R0, and understanding the impact of vaccines or infections in
different population groups.

------------------------------------------------------------------------
