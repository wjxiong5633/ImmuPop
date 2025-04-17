
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ImmuPop

<!-- badges: start -->
<!-- [![R-CMD-check](https://github.com/wjxiong5633/ImmunPop/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/wjxiong5633/ImmunPop/actions/workflows/R-CMD-check.yaml) -->
<!-- [![Codecov test coverage](https://codecov.io/gh/wjxiong5633/ImmunPop/graph/badge.svg)](https://app.codecov.io/gh/wjxiong5633/ImmunPop) -->
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
#install.packages("devtools")
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

Or can use
**[socialmixr](https://cran.r-project.org/web/packages/socialmixr/vignettes/socialmixr.html)**
package to generate a contact matrix:

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
| pop_immun | 0.182 |   0.14 |  0.358 |
| RR_R0     | 0.185 |   0.17 |  0.369 |
| GMT       | 6.300 |   1.40 |  9.705 |
| prop_5    | 0.400 |   0.00 |  0.400 |

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

knitr::kable(head(est_res_all,10), digits = 3, row.names = F)
```

| estimator | time |  value | CI_lwr | CI_upr |
|:----------|-----:|-------:|-------:|-------:|
| GMT       |    2 | 18.647 |  6.800 | 29.350 |
| GMT       |    3 | 17.809 |  7.241 | 27.336 |
| GMT       |    6 | 18.857 | 12.800 | 25.810 |
| GMT       |    7 | 11.514 |  4.400 | 19.238 |
| GMT       |   11 | 23.300 |  8.294 | 31.968 |
| GMT       |   15 |  5.600 |  2.295 | 10.200 |
| GMT       |   17 | 12.200 |  3.295 | 19.315 |
| GMT       |   24 | 19.743 |  7.672 | 28.519 |
| GMT       |   25 | 11.095 |  4.759 | 16.359 |
| GMT       |   26 | 21.095 |  8.761 | 34.356 |

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
| GMT       |   1 | 13.444 | 12.028 | 14.847 |
| GMT       |   2 | 14.674 | 12.701 | 16.059 |
| RR_R0     |   1 |  0.264 |  0.240 |  0.286 |
| RR_R0     |   2 |  0.282 |  0.263 |  0.309 |
| pop_immun |   1 |  0.262 |  0.238 |  0.285 |
| pop_immun |   2 |  0.280 |  0.259 |  0.310 |
| prop_5    |   1 |  0.758 |  0.693 |  0.808 |
| prop_5    |   2 |  0.800 |  0.729 |  0.847 |
