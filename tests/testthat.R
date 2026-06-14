#!/usr/bin/env Rscript
invisible(Sys.setlocale("LC_CTYPE", "C.UTF-8"))
library(testthat)
test_dir("tests/testthat", reporter = "summary")
