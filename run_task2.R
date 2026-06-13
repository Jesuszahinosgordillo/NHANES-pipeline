#!/usr/bin/env Rscript

# Tarea 2: predictimand, outcome binario a 5 años y auditoría de predictores.
# No entrena modelos ni consulta rendimiento. Solo deja reproducibles
# la cohorte objetivo, el caso positivo, la censura y la tabla de auditoría.

options(encoding = "UTF-8")

if (basename(getwd()) == "scripts") setwd("..")
if (!file.exists("_quarto.yml")) {
  stop("Ejecute este script desde la raíz del proyecto.", call. = FALSE)
}

library(readr)
library(dplyr)
library(tibble)

analytic_path <- "data/processed/2013_2014/nhanes_analytic.csv.gz"
if (!file.exists(analytic_path)) {
  stop("No encuentro la tabla analítica procesada: ", analytic_path, call. = FALSE)
}

analytic <- read_csv(analytic_path, show_col_types = FALSE)
dir.create("outputs/task2", recursive = TRUE, showWarnings = FALSE)
dir.create("protocols", recursive = TRUE, showWarnings = FALSE)

mask0 <- rep(TRUE, nrow(analytic))
mask1 <- mask0 & analytic$dem__RIDAGEYR >= 50
mask2 <- mask1 & analytic$mort__ELIGSTAT == 1
mask3 <- mask2 & analytic$dem__RIDSTATR == 2
mask4 <- mask3 & !is.na(analytic$mort__PERMTH_EXM)

# Outcome binario a 5 años desde examen MEC.
# Caso positivo: muerte antes o en 60 meses.
# Caso negativo: ausencia de muerte antes/en 60 meses con seguimiento >=60 meses.
# Los vivos con seguimiento <60 meses no se etiquetan como 0: quedan censurados
# para este análisis binario primario.
death5 <- mask4 & analytic$mort__MORTSTAT == 1 & analytic$mort__PERMTH_EXM <= 60
known5 <- death5 | (mask4 & analytic$mort__PERMTH_EXM >= 60)
mask5 <- mask4 & known5
censored_alive_under5 <- mask4 & analytic$mort__MORTSTAT == 0 & analytic$mort__PERMTH_EXM < 60
death_after5 <- mask5 & analytic$mort__MORTSTAT == 1 & analytic$mort__PERMTH_EXM > 60
non_event5 <- mask5 & !death5

cohort_audit <- tribble(
  ~criterio, ~n, ~nota,
  "Muestra integrada NHANES 2013-2014", sum(mask0), "Tabla analítica integrada por SEQN.",
  "Adultos con edad >=50 años al inicio", sum(mask1), "Población diana definida antes de modelar.",
  "Elegibles para Linked Mortality File público", sum(mask2), "Necesario para poder observar mortalidad vinculada.",
  "Con examen MEC realizado", sum(mask3), "T0 se fija en el examen MEC, para poder usar exploración y laboratorio como información basal.",
  "Con seguimiento desde examen disponible", sum(mask4), "Reloj principal: PERMTH_EXM.",
  "Con desenlace binario a 5 años observable", sum(mask5), "Incluye fallecidos antes/en 60 meses y no eventos con seguimiento >=60 meses. Los vivos con seguimiento <60 meses no se etiquetan como 0."
)

write_csv(cohort_audit, "outputs/task2/cohort_eligibility_audit.csv")
write_csv(cohort_audit, "protocols/cohort_eligibility_audit.csv")

outcome_summary <- tribble(
  ~medida, ~valor, ~nota,
  "N análisis binario primario", sum(mask5), "Adultos >=50, elegibles, con MEC y estado a 5 años observable.",
  "Casos positivos: muerte por cualquier causa antes/en 5 años", sum(death5), "death_5y=1 si MORTSTAT=1 y PERMTH_EXM<=60.",
  "Casos negativos: sin muerte antes/en 5 años", sum(non_event5), "death_5y=0 solo si hay seguimiento al menos hasta 60 meses. Incluye muertes posteriores a los 5 años, porque a 5 años seguían vivos.",
  "Muertes posteriores al horizonte de 5 años", sum(death_after5), "No son caso positivo para este outcome binario a 5 años.",
  "Censurados antes de 5 años sin evento", sum(censored_alive_under5), "No se codifican como supervivientes; quedan fuera del análisis binario primario."
)

write_csv(outcome_summary, "outputs/task2/outcome_5y_summary.csv")
write_csv(outcome_summary, "protocols/outcome_5y_summary.csv")

cycle_followup_audit <- tribble(
  ~ciclo, ~fuente_mortalidad, ~seguimiento_potencial_5y, ~nota,
  "NHANES 2013-2014", "LMF público con seguimiento hasta 2019", "Sí", "El ciclo tiene seguimiento potencial suficiente para un horizonte de 60 meses. En ciclos futuros se comprobará este punto antes de incluirlos."
)

write_csv(cycle_followup_audit, "outputs/task2/cycle_followup_audit.csv")
write_csv(cycle_followup_audit, "protocols/cycle_followup_audit.csv")

# La tabla de auditoría de predictores es una decisión de protocolo.
# Si cambia, debe cambiar antes de modelar y quedar versionada en Git.
if (file.exists("protocols/predictor_audit_table.csv")) {
  file.copy("protocols/predictor_audit_table.csv", "outputs/task2/predictor_audit_table.csv", overwrite = TRUE)
}

cat("Tarea 2 actualizada: outcome binario a 5 años, censura documentada y tablas en outputs/task2 y protocols. No se ha ajustado ningún modelo.
")
