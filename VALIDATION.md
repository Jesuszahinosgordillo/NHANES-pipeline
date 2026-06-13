# Validación técnica

## Tarea 1: pipeline NHANES

El pipeline comprueba, entre otras cosas:

- que haya una sola fila por `SEQN`;
- que las uniones no alteren el número de participantes de la tabla base;
- que los archivos de entrada coincidan con las huellas SHA-256 esperadas;
- que no queden nombres duplicados o sufijos `.x`/`.y` problemáticos;
- que la mortalidad y los tiempos de seguimiento sean coherentes;
- que los faltantes se describan separando ausencia estructural y ausencia dentro de la población aplicable.

Para 2013-2014 se esperan estas comprobaciones principales:

- 10.175 participantes en la tabla analítica;
- una fila por `SEQN`;
- mortalidad vinculada a nivel de participante;
- seguimiento desde entrevista y desde examen MEC conservados por separado;
- salidas por ciclo en `outputs/2013_2014/`.

## Tarea 2: predictimand y outcome a 5 años

La Tarea 2 queda documentada en `protocols/tarea2_predictimand.qmd` y en sus tablas asociadas.

Comprobaciones principales:

- el objetivo es mortalidad por cualquier causa a 5 años en adultos de 50 años o más;
- la unidad de análisis es el participante individual (`SEQN`);
- T0 se fija en el examen MEC basal;
- el reloj principal es `PERMTH_EXM`;
- el caso positivo es muerte por cualquier causa antes o en 60 meses desde MEC;
- el caso negativo exige seguimiento conocido al menos hasta 60 meses sin muerte dentro del horizonte;
- los vivos con menos de 60 meses de seguimiento no se codifican como controles;
- el tiempo a evento se conserva en el LMF, pero no se usa como respuesta principal en esta fase;
- `protocols/predictor_audit_table.csv` clasifica los bloques de variables como admisibles, dudosos o excluidos;
- mortalidad, causa de muerte, seguimiento e identificadores técnicos quedan fuera del set predictor;
- las comorbilidades previas se mantienen como admisibles;
- las variables con posible causalidad inversa quedan marcadas como dudosas, no como excluidas automáticas;
- no se ajustan modelos ni se calculan métricas de rendimiento.

El script `scripts/run_task2.R` genera las tablas de elegibilidad, outcome y auditoría en `outputs/task2/` y `protocols/`.

## Cómo comprobarlo

```bash
quarto render
Rscript tests/testthat.R
Rscript scripts/run_task2.R
quarto render protocols/tarea2_predictimand.qmd
```
