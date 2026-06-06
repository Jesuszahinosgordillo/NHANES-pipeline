# Configuración central del proyecto -----------------------------------------

config <- yaml::read_yaml("config/sources.yml")

PROJECT_SEED <- as.integer(config$project$seed)
PARTICIPANT_KEY <- config$project$participant_key
SOURCE_SPECS <- config$sources

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
