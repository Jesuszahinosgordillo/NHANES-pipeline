#!/usr/bin/env Rscript

invisible(Sys.setlocale("LC_CTYPE", "C.UTF-8"))
options(repos = c(CRAN = "https://cloud.r-project.org"), encoding = "UTF-8")

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}

renv::activate(project = getwd())
renv::restore(project = getwd(), prompt = FALSE)
cat("Entorno R restaurado. Ejecute ahora: quarto render\n")
