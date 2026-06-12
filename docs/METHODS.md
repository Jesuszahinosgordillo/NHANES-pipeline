# Métodos y decisiones de implementación

## Ejecución

La ejecución queda separada en tres piezas:

1. `scripts/bootstrap.R` restaura el entorno de paquetes con `renv`.
2. `scripts/run_pipeline.R` ejecuta el pipeline. Quarto lo llama antes de renderizar.
3. `R/pipeline.R` contiene la lógica principal: lectura, integración, auditorías, faltantes, figuras y salidas.

`index.qmd` no vuelve a hacer la limpieza desde cero; lee las salidas generadas por el pipeline y construye el informe.

## Ciclos

La información de cada ciclo está en `config/sources.yml`. El pipeline ejecuta los ciclos incluidos en `project.active_cycles`.

Las salidas se escriben por ciclo:

```text
data/processed/<ciclo>/
outputs/<ciclo>/tables/
outputs/<ciclo>/figures/
```

## Seguimiento

El Linked Mortality File ofrece dos tiempos de seguimiento:

- desde la entrevista;
- desde el examen MEC.

Los he mantenido separados porque no empiezan en el mismo momento. Si un análisis usa variables medidas en el examen o en laboratorio, el tiempo coherente será el seguimiento desde examen.

## Datos faltantes

Antes de interpretar los NA, se diferencia entre:

- ausencia estructural: la variable no aplica a ese participante;
- ausencia dentro de la población aplicable: la variable sí aplicaba, pero no está observada.

Esta separación se deja hecha antes de cualquier imputación o modelización.
