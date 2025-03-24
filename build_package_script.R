library("devtools")
load_all()
devtools::document()
devtools::build()


# 安装 {styler}
install.packages("styler")

# 对整个包进行代码美化
styler::style_pkg()


# 安装 {testthat}
install.packages("testthat")

# 快速创建测试文件
usethis::use_testthat()
usethis::use_test("add100")
usethis::use_test("multiply100")


## usethis::use_mit_license()
## usethis::use_version()

devtools::check()
usethis::proj_get()

detach("package:ImmuPop", unload=TRUE)
devtools::test_coverage()
##
