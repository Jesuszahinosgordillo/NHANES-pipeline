#!/usr/bin/env Rscript

invisible(Sys.setlocale("LC_CTYPE", "C.UTF-8"))
options(encoding = "UTF-8")

# Permite ejecutar desde la raíz del proyecto con:
# Rscript scripts/run_pipeline.R
if (!file.exists("_quarto.yml")) {
  stop("Ejecute este script desde la raíz del proyecto.", call. = FALSE)
}

source("R/pipeline.R", encoding = "UTF-8")
run_pipeline()
cat("Pipeline completado correctamente.\n")
