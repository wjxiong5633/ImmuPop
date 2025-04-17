
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ImmuPop

<!-- badges: start -->
<!-- [![R-CMD-check](https://github.com/wjxiong5633/ImmunPop/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/wjxiong5633/ImmunPop/actions/workflows/R-CMD-check.yaml) -->
<!-- [![Codecov test coverage](https://codecov.io/gh/wjxiong5633/ImmunPop/graph/badge.svg)](https://app.codecov.io/gh/wjxiong5633/ImmunPop) -->
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
| pop_immun | 0.214 |  0.173 |  0.364 |
| RR_R0     | 0.231 |  0.199 |  0.369 |
| GMT       | 7.000 |  2.200 | 11.305 |
| prop_5    | 0.400 |  0.000 |  0.400 |

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
| GMT       |  100 |  5.400 |  2.295 |  8.105 |
| GMT       |  150 | 39.700 |  9.180 | 72.620 |
| GMT       |  200 |  6.600 |  2.790 | 11.210 |
| GMT       |  250 | 57.600 | 17.235 | 95.515 |
| RR_R0     |  100 |  0.187 |  0.173 |  0.333 |
| RR_R0     |  150 |  0.451 |  0.388 |  0.587 |
| RR_R0     |  200 |  0.228 |  0.223 |  0.370 |
| RR_R0     |  250 |  0.569 |  0.480 |  0.611 |
| pop_immun |  100 |  0.180 |  0.160 |  0.345 |
| pop_immun |  150 |  0.464 |  0.368 |  0.577 |
| pop_immun |  200 |  0.215 |  0.180 |  0.353 |
| pop_immun |  250 |  0.569 |  0.496 |  0.612 |
| prop_5    |  100 |  0.000 |  0.000 |  0.400 |
| prop_5    |  150 |  0.600 |  0.400 |  1.000 |
| prop_5    |  200 |  0.400 |  0.000 |  0.800 |
| prop_5    |  250 |  1.000 |  0.400 |  1.000 |

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
| GMT       |   1 | 4.600 |  1.895 |  8.410 |
| GMT       |   2 | 7.400 |  2.800 | 11.305 |
| RR_R0     |   1 | 0.187 |  0.181 |  0.343 |
| RR_R0     |   2 | 0.229 |  0.201 |  0.393 |
| pop_immun |   1 | 0.180 |  0.160 |  0.338 |
| pop_immun |   2 | 0.218 |  0.174 |  0.372 |
| prop_5    |   1 | 0.000 |  0.000 |  0.610 |
| prop_5    |   2 | 0.400 |  0.000 |  0.800 |
