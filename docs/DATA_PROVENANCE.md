# Procedencia de los datos

El proyecto usa datos públicos de NHANES/NCHS y el Linked Mortality File público asociado al ciclo 2013-2014.

## Fuentes incluidas

- Demographic data, NHANES 2013-2014.
- Examination data, NHANES 2013-2014.
- Laboratory data, NHANES 2013-2014.
- Questionnaire data, NHANES 2013-2014.
- NCHS Linked Mortality File public-use data para NHANES 2013-2014, con seguimiento público hasta 2019.

Las rutas concretas y los SHA-256 están en `config/sources.yml`.

## Por qué se incluyen los datos crudos

El tutor pidió que un clon limpio del repositorio pudiera reproducir el pipeline sin que faltasen ficheros. Por eso esta versión incluye los datos crudos usados por el proyecto dentro de `data/raw/`.

## Licencia y condiciones de uso

Los datos de NHANES/NCHS son datos públicos de uso científico. En informes, artículos o materiales derivados deben citarse las fuentes oficiales correspondientes y respetarse las condiciones de los ficheros public-use.

## Tamaño de ficheros

Los ficheros actuales no superan los límites habituales por archivo de GitHub. Si en futuras fases se incorporan más ciclos o fuentes de mayor tamaño, se recomienda usar Git LFS o un almacenamiento externo documentado, manteniendo siempre una comprobación de integridad mediante SHA-256.
