# Validación de la entrega

Autor: Jesús Manuel Zahinos Gordillo

## Estado de la versión

Esta versión incorpora la integración completa de los módulos Demographic, Examination, Labs y Questionnaire mediante `SEQN`, la vinculación con el Linked Mortality File público de NHANES 2013–2014 y la generación del informe Quarto en HTML.

## Comprobaciones realizadas

- El informe `outputs/report/index.html` se ha renderizado correctamente desde `index.qmd`.
- El documento incluye las salidas generadas por el pipeline y cinco figuras descriptivas:
  - `module_coverage.png`
  - `age_by_mortality_eligibility.png`
  - `followup_distribution.png`
  - `missingness_by_module.png`
  - `missingness_raw_vs_applicable.png`
- Las pruebas automatizadas se han ejecutado con:

```bash
Rscript tests/testthat.R
```

Resultado:

```text
integrity: ..................
DONE
```


## Comprobación de codificación

El HTML renderizado se ha revisado para evitar artefactos de codificación. Las tablas del informe muestran correctamente tildes y caracteres especiales en español.

## Comprobaciones de integridad incluidas en el proyecto

El pipeline comprueba automáticamente:

- Existencia de `SEQN` en cada fuente.
- Ausencia de `SEQN` duplicados.
- Número esperado de filas por fuente.
- Huellas SHA-256 de los ficheros de entrada.
- Uniones uno a uno.
- Conservación de la cohorte maestra de Demographic.
- Vinculación de mortalidad por `SEQN`.
- Disponibilidad de evento y seguimiento en participantes elegibles.
- Coherencia entre seguimiento desde entrevista y seguimiento desde examen MEC.
- Resolución auditable de nombres repetidos terminados en `.x` y `.y`.

## Reproducibilidad

El archivo `_quarto.yml` mantiene la instrucción:

```yaml
pre-render: Rscript scripts/run_pipeline.R
```

Por tanto, en una ejecución estándar con `quarto render`, Quarto ejecuta primero el pipeline y después genera el informe. La semilla del proyecto está fijada en `config/sources.yml`.

