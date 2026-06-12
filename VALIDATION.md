# Validación del pipeline

Este archivo resume las comprobaciones que deja hechas el proyecto.

## Entradas

Las fuentes se declaran en `config/sources.yml`. Para cada una se guarda:

- ruta local del fichero;
- número esperado de filas;
- SHA-256 esperado;
- módulo de procedencia;
- prefijo usado en la tabla analítica.

Al ejecutar el pipeline se comprueba que los ficheros existen, que el SHA-256 coincide y que `SEQN` no está duplicado dentro de cada fuente.

## Uniones

`R/pipeline.R` usa `Demographic` como tabla base y une el resto de módulos con `left_join()` por `SEQN`.

Se comprueba que:

- no se pierden participantes respecto a Demographic;
- la tabla final mantiene un único registro por `SEQN`;
- los módulos secundarios no introducen participantes que no estén en Demographic;
- las uniones son uno-a-uno.

El resumen queda en:

```text
outputs/2013_2014/tables/join_audit.csv
```

## Mortalidad y seguimiento

El Linked Mortality File se une también por `SEQN`.

Se mantienen separados los dos tiempos de seguimiento:

- `mort__followup_months_interview`: seguimiento desde entrevista;
- `mort__followup_months_exam`: seguimiento desde examen MEC.

No se funden en una sola variable porque tienen distinto origen temporal. Las comprobaciones quedan en:

```text
outputs/2013_2014/tables/followup_audit.csv
outputs/2013_2014/tables/followup_summary.csv
```

## Datos faltantes

El informe separa dos cosas:

- ausencia bruta sobre toda la cohorte;
- ausencia dentro de la población realmente aplicable.

Esto es importante en NHANES porque muchos valores vacíos no son errores, sino ausencia estructural por edad, submuestras, examen MEC o saltos de cuestionario.

Las tablas principales son:

```text
outputs/2013_2014/tables/missingness_all_variables.csv
outputs/2013_2014/tables/missingness_core_variables.csv
outputs/2013_2014/tables/missingness_mechanism_screen.csv
```

## Reproducibilidad

La semilla está fijada en `config/sources.yml`. El entorno de paquetes queda descrito en `renv.lock`.

Para reconstruir el entorno en un equipo nuevo:

```bash
Rscript scripts/bootstrap.R
```

Para ejecutar el pipeline:

```bash
Rscript scripts/run_pipeline.R
```

Para renderizar el informe completo:

```bash
quarto render
```
