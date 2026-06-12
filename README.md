# Pipeline NHANES en Quarto/R

Este proyecto construye una tabla analítica a nivel de participante a partir de NHANES y del Linked Mortality File. El ciclo activo ahora es **NHANES 2013-2014**, pero ya no está fijado a mano dentro del código: se declara en `config/sources.yml`.

La idea es que el proyecto se pueda ejecutar de principio a fin con:

```bash
quarto render
```

Quarto llama antes a `scripts/run_pipeline.R`, y ese script ejecuta `R/pipeline.R`.

## Qué se ha dejado preparado

### 1. Ciclos parametrizados

Los ciclos se controlan desde:

```text
config/sources.yml
```

En esta versión aparece activo:

```yaml
active_cycles:
  - "2013-2014"
```

Para añadir otro ciclo más adelante, se añade otro bloque dentro de `cycles` y se incluye su identificador en `active_cycles`. El pipeline recorre esa lista y escribe las salidas separadas por ciclo.

### 2. Datos crudos versionados y documentados

Los datos crudos usados en esta versión están dentro de:

```text
data/raw/
```

Cada fuente tiene su ruta, procedencia y SHA-256 declarados en `config/sources.yml`. Además, la procedencia y la nota de uso/licencia quedan resumidas en:

```text
data/raw/README.md
docs/DATA_PROVENANCE.md
```

Los ficheros actuales están dentro de tamaños manejables para Git. Si en fases posteriores se añaden más ciclos o archivos grandes, se podrá pasar a Git LFS o a almacenamiento externo, dejando la ruta y la comprobación documentadas.

### 3. Nombres de scripts alineados

- `scripts/bootstrap.R`: restaura el entorno de paquetes con `renv`. Solo hace falta en un equipo nuevo o si se quiere reconstruir el entorno.
- `scripts/run_pipeline.R`: ejecuta el pipeline. Es el script que llama Quarto antes del render.
- `R/pipeline.R`: contiene la lógica principal: lectura, validaciones, uniones, mortalidad, faltantes, figuras y salidas.

## Estructura principal

```text
config/sources.yml             configuración de ciclos y fuentes
R/pipeline.R                   código principal del pipeline
R/config.R                     lectura de configuración y constantes
R/io.R                         lectura de módulos y mortalidad
R/missingness.R                análisis de datos faltantes
R/descriptive.R                tablas y figuras descriptivas
scripts/run_pipeline.R         ejecución del pipeline
scripts/bootstrap.R            restauración de paquetes con renv
index.qmd                      informe Quarto
outputs/report/index.html      informe renderizado
```

## Salidas del ciclo activo

Para `2013-2014`, las salidas se guardan en:

```text
data/processed/2013_2014/nhanes_analytic.rds
data/processed/2013_2014/nhanes_analytic.csv.gz
outputs/2013_2014/tables/
outputs/2013_2014/figures/
```

El informe HTML queda en:

```text
outputs/report/index.html
```

También se deja una copia como `index.html` en la raíz para poder abrirlo rápido o verlo más cómodo en GitHub.

## Ejecución

Desde la raíz del proyecto:

```bash
quarto render
```

O solo el pipeline:

```bash
Rscript scripts/run_pipeline.R
```

En R/RStudio:

```r
setwd("C:/ruta/a/NHANES_pipeline_v2")
source("scripts/run_pipeline.R", encoding = "UTF-8")
quarto::quarto_render()
```

`run_pipeline.R` también está preparado para funcionar si por error se lanza desde la carpeta `scripts/`, porque sube automáticamente a la raíz del proyecto.
