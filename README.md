# Pipeline NHANES en Quarto/R

Autor: Jesús Manuel Zahinos Gordillo

Este repositorio contiene un pipeline en Quarto/R para construir una tabla analítica a nivel de participante a partir de NHANES. Ahora mismo el ciclo activo es **NHANES 2013-2014**, pero el ciclo se define en `config/sources.yml`, de forma que después se puedan añadir otros ciclos sin reescribir la lógica principal.

La primera parte del proyecto deja el dato limpio, documentado y reproducible. La segunda parte fija el problema predictivo antes de modelar: predictimand, outcome a 5 años, censura y auditoría de predictores. Todavía no hay imputación, selección de variables por rendimiento, modelos ni evaluación predictiva.

## Archivos principales del pipeline

- `index.qmd`: informe Quarto de la integración NHANES.
- `R/pipeline.R`: script principal de lectura, uniones, auditorías, faltantes y salidas.
- `R/config.R`: configuración general del proyecto.
- `config/sources.yml`: ciclos, rutas, huellas SHA-256 y procedencia de los datos.
- `scripts/run_pipeline.R`: ejecuta el pipeline y es llamado por Quarto antes del render.
- `scripts/bootstrap.R`: restaura el entorno con `renv` en un equipo nuevo.
- `renv.lock`: versiones de paquetes usadas.

## Cómo reproducirlo

Desde la raíz del proyecto:

```bash
Rscript scripts/bootstrap.R
quarto render
```

Si el entorno ya está preparado, normalmente basta con:

```bash
quarto render
```

Para ejecutar solo el pipeline:

```bash
Rscript scripts/run_pipeline.R
```

Para ejecutar solo la parte de la Tarea 2:

```bash
Rscript scripts/run_task2.R
quarto render protocols/tarea2_predictimand.qmd
```

## Salidas de la Tarea 1

Para el ciclo activo `2013_2014`, las salidas principales quedan en:

- `data/processed/2013_2014/nhanes_analytic.rds`
- `data/processed/2013_2014/nhanes_analytic.csv.gz`
- `outputs/2013_2014/tables/`
- `outputs/2013_2014/figures/`
- `outputs/report/index.html`

## Tarea 2: predictimand, outcome y auditoría

La Tarea 2 queda en la carpeta `protocols/`.

Archivos principales:

- `protocols/tarea2_predictimand.qmd`: protocolo fuente.
- `protocols/tarea2_predictimand.html`: versión renderizada para lectura.
- `protocols/predictor_audit_table.csv`: auditoría de predictores.
- `protocols/cohort_eligibility_audit.csv`: criterios de elegibilidad y N paso a paso.
- `protocols/outcome_5y_summary.csv`: definición del outcome a 5 años y tratamiento de la censura.
- `protocols/cycle_followup_audit.csv`: comprobación del seguimiento potencial del ciclo.
- `scripts/run_task2.R`: script que reproduce las tablas de la Tarea 2.

El objetivo queda fijado como mortalidad por cualquier causa a 5 años en adultos de 50 años o más. T0 se fija en el examen MEC basal y el reloj principal es `PERMTH_EXM`.

El outcome se mantiene binario: muerte antes o en 60 meses frente a supervivencia confirmada hasta al menos 60 meses. Los participantes vivos con menos de 60 meses de seguimiento no se etiquetan como controles, porque están censurados para este horizonte.

La auditoría de predictores clasifica los bloques de variables como admisibles, dudosos o excluidos. Las comorbilidades previas se mantienen como admisibles. Las variables que pueden reflejar deterioro avanzado —salud autopercibida, pérdida de peso, IMC muy bajo, albúmina baja, limitación funcional e inflamación extrema— quedan como dudosas y requieren justificación o sensibilidad posterior.
