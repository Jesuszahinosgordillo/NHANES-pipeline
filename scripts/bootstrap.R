#!/usr/bin/env Rscript

# Preparación del entorno -----------------------------------------------------
# Solo hace falta usarlo en un equipo nuevo o si se quiere restaurar renv.

invisible(try(Sys.setlocale("LC_CTYPE", "C.UTF-8"), silent = TRUE))
options(repos = c(CRAN = "https://cloud.r-project.org"), encoding = "UTF-8")

if (!file.exists("_quarto.yml") && file.exists(file.path("..", "_quarto.yml"))) {
  setwd("..")
}

if (!file.exists("_quarto.yml")) {
  stop("No encuentro _quarto.yml. Abra R/RStudio en la carpeta raíz del proyecto.", call. = FALSE)
}

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}

renv::activate(project = getwd())
renv::restore(project = getwd(), prompt = FALSE)
cat("Entorno R restaurado. Después puede ejecutarse: quarto render\n")
