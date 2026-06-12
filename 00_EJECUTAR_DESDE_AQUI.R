# Ejecutar desde la raíz del proyecto ----------------------------------------
# Abra este archivo en RStudio y ejecute todo el contenido.

if (!file.exists("_quarto.yml")) {
  stop("Este archivo debe ejecutarse desde la carpeta raíz del proyecto, donde está _quarto.yml.", call. = FALSE)
}

source("scripts/run_pipeline.R", encoding = "UTF-8")

if (requireNamespace("quarto", quietly = TRUE)) {
  quarto::quarto_render()
} else {
  message("Pipeline ejecutado. Para generar el HTML, instale/cargue Quarto y ejecute: quarto render")
}
