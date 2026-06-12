# Notas de revisión

Cambios incorporados después de la revisión del tutor.

## 1. Pipeline por ciclo

El ciclo ya no queda fijado solo en nombres de archivo. Se declara en `config/sources.yml`:

```yaml
active_cycles:
  - "2013-2014"
```

`R/pipeline.R` lee esa lista y ejecuta cada ciclo activo. Las salidas se guardan separadas por ciclo, por ejemplo:

```text
data/processed/2013_2014/
outputs/2013_2014/tables/
outputs/2013_2014/figures/
```

Así queda preparado para añadir más ciclos cuando se haga validación temporal.

## 2. Datos crudos y procedencia

Los ficheros crudos usados en esta versión están incluidos en `data/raw/`. Su ruta, procedencia y SHA-256 aparecen en `config/sources.yml`.

También se añadió documentación en:

```text
data/raw/README.md
docs/DATA_PROVENANCE.md
```

Los datos proceden de ficheros públicos de NHANES/NCHS. Si más adelante se añaden datos de mayor tamaño, se dejará indicado si van por Git LFS o por almacenamiento externo.

## 3. Nombres de scripts

Se ha dejado alineada la documentación:

- `scripts/bootstrap.R`: restaura el entorno con `renv`.
- `scripts/run_pipeline.R`: ejecuta el pipeline y es el hook de Quarto.
- `R/pipeline.R`: contiene la lógica principal del pipeline.

No se cambia el funcionamiento de fondo; se aclara la organización para que sea más fácil de revisar.
