# Datos crudos

Esta carpeta contiene los ficheros de entrada usados por el pipeline.

## NHANES 2013-2014

Los módulos usados son:

```text
nhanes/demographic.csv
nhanes/examination.csv
nhanes/labs.csv
nhanes/questionnaire.csv
```

Son extractos congelados por módulo, a nivel de participante, usados como entrada del pipeline.

## Mortalidad

El fichero de mortalidad pública es:

```text
mortality/NHANES_2013_2014_MORT_2019_PUBLIC.dat
```

Corresponde al Linked Mortality File público de NCHS para NHANES 2013-2014.

## Control de integridad

Cada fuente tiene su SHA-256 declarado en:

```text
config/sources.yml
```

El pipeline comprueba esos hashes antes de construir la tabla analítica. Si cambia un fichero crudo, la ejecución se detiene.

## Uso y procedencia

NHANES/NCHS publica estos datos para uso público. En cualquier trabajo derivado deben citarse las fuentes oficiales y respetarse sus condiciones de uso.

Los ficheros incluidos actualmente están dentro de tamaños razonables para Git. Si se añaden más ciclos o archivos grandes, se documentará si se usa Git LFS o almacenamiento externo.
