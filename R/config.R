# Configuración central del proyecto -----------------------------------------

config <- yaml::read_yaml("config/sources.yml")

null_or <- function(x, y) if (is.null(x)) y else x

PROJECT_SEED <- as.integer(config$project$seed)
PARTICIPANT_KEY <- config$project$participant_key
CYCLE_SPECS <- config$cycles
ACTIVE_CYCLE_IDS <- as.character(unlist(null_or(config$project$active_cycles, vapply(CYCLE_SPECS, `[[`, character(1), "id"))))

cycle_ids <- function() {
  vapply(CYCLE_SPECS, `[[`, character(1), "id")
}

get_cycle_spec <- function(cycle_id) {
  ids <- cycle_ids()
  idx <- match(cycle_id, ids)
  if (is.na(idx)) {
    stop("No existe el ciclo '", cycle_id, "' en config/sources.yml.", call. = FALSE)
  }
  CYCLE_SPECS[[idx]]
}

cycle_slug <- function(cycle_spec) {
  null_or(cycle_spec$slug, gsub("[^0-9A-Za-z]+", "_", cycle_spec$id))
}

cycle_label <- function(cycle_spec) {
  null_or(cycle_spec$label, paste("NHANES", cycle_spec$id))
}

first_active_cycle <- function() {
  get_cycle_spec(ACTIVE_CYCLE_IDS[[1]])
}

# Compatibilidad para funciones antiguas que esperen SOURCE_SPECS. El pipeline
# nuevo no depende de esta variable; itera sobre los ciclos activos.
SOURCE_SPECS <- first_active_cycle()$sources

CORE_MISSINGNESS_VARIABLES <- c(
  "dem__INDFMPIR",
  "exam__BMXBMI",
  "exam__BMXWAIST",
  "lab__LBXSGL",
  "lab__LBXGH",
  "lab__LBDHDD",
  "quest__HSD010",
  "quest__SMQ020",
  "quest__DIQ010",
  "mort__event",
  "mort__followup_months_interview",
  "mort__followup_months_exam"
)

CORE_VARIABLE_LABELS <- c(
  dem__INDFMPIR = "Razón ingresos-pobreza familiar",
  exam__BMXBMI = "Índice de masa corporal",
  exam__BMXWAIST = "Perímetro de cintura",
  lab__LBXSGL = "Glucosa sérica",
  lab__LBXGH = "Hemoglobina glucosilada",
  lab__LBDHDD = "Colesterol HDL",
  quest__HSD010 = "Estado general de salud",
  quest__SMQ020 = "Ha fumado al menos 100 cigarrillos",
  quest__DIQ010 = "Diagnóstico de diabetes",
  mort__event = "Evento de mortalidad",
  mort__followup_months_interview = "Seguimiento desde entrevista",
  mort__followup_months_exam = "Seguimiento desde examen MEC"
)

OBSERVED_MISSINGNESS_PREDICTORS <- c(
  "dem__RIDAGEYR",
  "dem__RIAGENDR",
  "dem__RIDRETH3",
  "dem__INDFMPIR"
)
