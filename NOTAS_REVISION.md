# Notas de revisión

Cambios incorporados en esta versión:

## 1. Ciclos configurables

- `config/sources.yml` declara una lista de ciclos.
- `project.active_cycles` indica qué ciclos se ejecutan.
- `R/pipeline.R` itera sobre esa lista.
- Las salidas se guardan por ciclo en:
  - `data/processed/<ciclo>/`
  - `outputs/<ciclo>/tables/`
  - `outputs/<ciclo>/figures/`

En esta versión solo está activo `2013-2014`, pero la estructura ya permite añadir ciclos posteriores.

## 2. Datos crudos y procedencia

- Los archivos crudos están en `data/raw/`.
- La procedencia queda documentada en `data/raw/README.md`, `docs/DATA_PROVENANCE.md` y `config/sources.yml`.
- Cada archivo se verifica con SHA-256 antes de procesarse.
- Si más adelante algún archivo supera los límites de GitHub, se usará Git LFS o un almacenamiento externo documentado.

## 3. Nombres de scripts

- `scripts/bootstrap.R`: prepara el entorno.
- `scripts/run_pipeline.R`: ejecuta el pipeline y lo llama Quarto.
- `R/pipeline.R`: contiene la lógica principal.
- `index.qmd`: presenta los resultados generados.
