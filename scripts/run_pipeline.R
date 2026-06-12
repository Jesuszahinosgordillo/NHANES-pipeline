#!/usr/bin/env Rscript

# Ejecución del pipeline ------------------------------------------------------
# Este script lo llama Quarto antes de generar el informe. También se puede
# ejecutar a mano con: Rscript scripts/run_pipeline.R

invisible(try(Sys.setlocale("LC_CTYPE", "C.UTF-8"), silent = TRUE))
options(encoding = "UTF-8")

# Me aseguro de trabajar desde la raíz del proyecto. Si alguien lo lanza desde
# la carpeta scripts/, subo automáticamente un nivel.
if (!file.exists("_quarto.yml") && file.exists(file.path("..", "_quarto.yml"))) {
  setwd("..")
}

if (!file.exists("_quarto.yml")) {
  stop("No encuentro _quarto.yml. Abra R/RStudio en la carpeta raíz del proyecto.", call. = FALSE)
}

source("R/pipeline.R", encoding = "UTF-8")
run_pipeline()
cat("Pipeline completado correctamente.\n")
