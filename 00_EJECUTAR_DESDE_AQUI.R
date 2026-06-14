# Ejecutar desde la raíz del proyecto ----------------------------------------
# Abra este archivo en RStudio y ejecute todo el contenido.
# Importante: primero hay que extraer el ZIP. No conviene abrir este archivo
# directamente desde la vista comprimida de Windows.

options(encoding = "UTF-8")

buscar_raiz <- function(inicio = getwd()) {
  actual <- normalizePath(inicio, winslash = "/", mustWork = FALSE)
  for (i in 1:8) {
    if (file.exists(file.path(actual, "_quarto.yml"))) return(actual)
    padre <- dirname(actual)
    if (identical(padre, actual)) break
    actual <- padre
  }
  NA_character_
}

# Si el archivo se abre desde RStudio, intento usar la carpeta donde está guardado.
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  ruta_archivo <- tryCatch(rstudioapi::getActiveDocumentContext()$path, error = function(e) "")
  if (nzchar(ruta_archivo)) {
    raiz_desde_archivo <- buscar_raiz(dirname(ruta_archivo))
    if (!is.na(raiz_desde_archivo)) setwd(raiz_desde_archivo)
  }
}

# Si no se ha encontrado desde el archivo, busco desde la carpeta actual.
raiz <- buscar_raiz(getwd())
if (is.na(raiz)) {
  stop(
    "No encuentro _quarto.yml. Extraiga primero el ZIP completo y abra el archivo .Rproj de la carpeta del proyecto.",
    call. = FALSE
  )
}
setwd(raiz)

message("Carpeta del proyecto: ", getwd())

source("scripts/run_pipeline.R", encoding = "UTF-8")
source("scripts/run_task2.R", encoding = "UTF-8")

if (requireNamespace("quarto", quietly = TRUE)) {
  quarto::quarto_render("index.qmd")
  quarto::quarto_render("protocols/tarea2_predictimand.qmd")
} else {
  message("Pipeline y Tarea 2 ejecutados. Para generar los HTML, instale/cargue Quarto.")
}
