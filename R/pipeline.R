# Pipeline reproducible de ingesta e integración NHANES ---------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(purrr)
  library(ggplot2)
  library(tibble)
  library(yaml)
  library(fs)
  library(digest)
  library(broom)
  library(scales)
})

source("R/config.R", encoding = "UTF-8")
source("R/utils.R", encoding = "UTF-8")
source("R/io.R", encoding = "UTF-8")
source("R/missingness.R", encoding = "UTF-8")
source("R/descriptive.R", encoding = "UTF-8")

build_input_audit <- function(raw_tables, source_specs) {
  purrr::imap_dfr(raw_tables, function(data, name) {
    spec <- source_specs[[name]]
    tibble::tibble(
      source = name,
      path = spec$path,
      rows = nrow(data),
      columns_after_resolution = ncol(data),
      distinct_seqn = dplyr::n_distinct(data[[PARTICIPANT_KEY]]),
      duplicated_seqn = sum(duplicated(data[[PARTICIPANT_KEY]])),
      missing_seqn = sum(is.na(data[[PARTICIPANT_KEY]])),
      sha256 = sha256_file(spec$path),
      sha256_verified = identical(sha256_file(spec$path), spec$expected_sha256)
    )
  })
}

build_variable_dictionary <- function(data) {
  purrr::map_dfr(names(data), function(variable) {
    x <- data[[variable]]
    tibble::tibble(
      variable = variable,
      original_variable = original_variable_name(variable),
      module = module_from_variable(variable),
      r_class = paste(class(x), collapse = ";"),
      n_distinct_observed = dplyr::n_distinct(x, na.rm = TRUE),
      n_missing = sum(is.na(x)),
      pct_missing = 100 * mean(is.na(x))
    )
  })
}

run_pipeline <- function() {
  set.seed(PROJECT_SEED)

  fs::dir_create(c("data/processed", "outputs/tables", "outputs/figures", "outputs/report"), recurse = TRUE)

  # Lectura y validación independiente de cada fuente.
  demographic <- read_nhanes_module(SOURCE_SPECS$demographic, "Demographic")
  examination <- read_nhanes_module(SOURCE_SPECS$examination, "Examination")
  labs <- read_nhanes_module(SOURCE_SPECS$labs, "Labs")
  questionnaire <- read_nhanes_module(SOURCE_SPECS$questionnaire, "Questionnaire")
  mortality <- read_linked_mortality(SOURCE_SPECS$mortality)

  name_collision_audit <- dplyr::bind_rows(
    attr(demographic, "name_collision_audit"),
    attr(examination, "name_collision_audit"),
    attr(labs, "name_collision_audit"),
    attr(questionnaire, "name_collision_audit")
  )

  raw_tables <- list(
    demographic = demographic,
    examination = examination,
    labs = labs,
    questionnaire = questionnaire,
    mortality = mortality
  )

  # Los módulos secundarios no pueden introducir participantes ajenos a la
  # tabla maestra Demographic.
  master_ids <- demographic[[PARTICIPANT_KEY]]
  purrr::iwalk(raw_tables[-1], function(data, name) {
    unexpected <- setdiff(data[[PARTICIPANT_KEY]], master_ids)
    if (length(unexpected) > 0L) {
      stop(name, " contiene SEQN no presentes en Demographic.", call. = FALSE)
    }
  })

  input_audit <- build_input_audit(raw_tables, SOURCE_SPECS)

  # Demographic es la tabla maestra. Las uniones izquierdas conservan la
  # cohorte completa y permiten distinguir la falta de participación.
  analytic <- demographic |>
    dplyr::mutate(
      has_exam_record = .data$SEQN %in% examination$SEQN,
      has_lab_record = .data$SEQN %in% labs$SEQN,
      has_questionnaire_record = .data$SEQN %in% questionnaire$SEQN
    ) |>
    dplyr::left_join(examination, by = "SEQN", relationship = "one-to-one") |>
    dplyr::left_join(labs, by = "SEQN", relationship = "one-to-one") |>
    dplyr::left_join(questionnaire, by = "SEQN", relationship = "one-to-one") |>
    dplyr::left_join(mortality, by = "SEQN", relationship = "one-to-one") |>
    dplyr::mutate(
      mort__event = .data$mort__MORTSTAT,
      mort__followup_months_interview = .data$mort__PERMTH_INT,
      mort__followup_months_exam = .data$mort__PERMTH_EXM,
      mort__followup_years_interview = .data$mort__PERMTH_INT / 12,
      mort__followup_years_exam = .data$mort__PERMTH_EXM / 12
    ) |>
    dplyr::arrange(.data$SEQN)

  assert_unique_key(analytic, PARTICIPANT_KEY, "tabla analítica")
  assert_expected_rows(analytic, as.integer(SOURCE_SPECS$demographic$expected_rows), "tabla analítica")

  join_audit <- tibble::tibble(
    check = c(
      "Filas de la tabla maestra",
      "Filas tras todas las uniones",
      "SEQN únicos en tabla final",
      "Registros Examination enlazados",
      "Registros Labs enlazados",
      "Registros Questionnaire enlazados",
      "Registros de mortalidad enlazados"
    ),
    value = c(
      nrow(demographic),
      nrow(analytic),
      dplyr::n_distinct(analytic$SEQN),
      sum(analytic$has_exam_record),
      sum(analytic$has_lab_record),
      sum(analytic$has_questionnaire_record),
      sum(!is.na(analytic$mort__ELIGSTAT))
    ),
    expected = c(
      nrow(demographic), nrow(demographic), nrow(demographic),
      nrow(examination), nrow(labs), nrow(questionnaire), nrow(mortality)
    ),
    passed = .data$value == .data$expected
  )

  if (!all(join_audit$passed)) {
    stop("Ha fallado al menos una comprobación de integridad de las uniones.", call. = FALSE)
  }

  mortality_audit <- tibble::tibble(
    metric = c(
      "Participantes vinculados",
      "Elegibles para seguimiento público",
      "Menores de 18 años no publicados",
      "Ineligibles",
      "Elegibles con evento observado",
      "Fallecidos",
      "Asumidos vivos",
      "Elegibles con seguimiento desde entrevista",
      "Elegibles examinados con seguimiento desde examen",
      "Elegibles no examinados"
    ),
    value = c(
      sum(!is.na(analytic$mort__ELIGSTAT)),
      sum(analytic$mort__ELIGSTAT == 1L, na.rm = TRUE),
      sum(analytic$mort__ELIGSTAT == 2L, na.rm = TRUE),
      sum(analytic$mort__ELIGSTAT == 3L, na.rm = TRUE),
      sum(analytic$mort__ELIGSTAT == 1L & !is.na(analytic$mort__event), na.rm = TRUE),
      sum(analytic$mort__event == 1L, na.rm = TRUE),
      sum(analytic$mort__event == 0L, na.rm = TRUE),
      sum(analytic$mort__ELIGSTAT == 1L & !is.na(analytic$mort__followup_months_interview), na.rm = TRUE),
      sum(analytic$mort__ELIGSTAT == 1L & analytic$has_exam_record & !is.na(analytic$mort__followup_months_exam), na.rm = TRUE),
      sum(analytic$mort__ELIGSTAT == 1L & !analytic$has_exam_record, na.rm = TRUE)
    )
  )

  followup_audit <- make_followup_audit(analytic)
  if (!all(followup_audit$passed)) {
    stop("Ha fallado al menos una comprobación del tiempo de seguimiento.", call. = FALSE)
  }

  followup_summary <- make_followup_summary(analytic)
  missingness_all <- make_missingness_table(analytic)
  missingness_module_summary <- make_module_missingness_summary(missingness_all)
  missingness_core <- make_core_missingness_detail(analytic)
  missingness_screen <- screen_missingness_mechanisms(analytic)
  variable_dictionary <- build_variable_dictionary(analytic)
  survey_design_inventory <- make_survey_design_inventory(analytic)
  cohort_profile <- make_cohort_profile(analytic)

  coverage <- make_coverage_figure(analytic, "outputs/figures/module_coverage.png")
  make_missingness_module_figure(missingness_all, "outputs/figures/missingness_by_module.png")
  make_core_missingness_figure(missingness_core, "outputs/figures/missingness_raw_vs_applicable.png")
  make_followup_figure(analytic, "outputs/figures/followup_distribution.png")
  make_age_eligibility_figure(analytic, "outputs/figures/age_by_mortality_eligibility.png")

  # Resultados deterministas del pipeline.
  save_rds_atomic(analytic, "data/processed/nhanes_2013_2014_analytic.rds", compress = "gzip")
  write_csv_atomic(analytic, "data/processed/nhanes_2013_2014_analytic.csv.gz")
  write_csv_atomic(input_audit, "outputs/tables/input_audit.csv")
  write_csv_atomic(join_audit, "outputs/tables/join_audit.csv")
  write_csv_atomic(mortality_audit, "outputs/tables/mortality_audit.csv")
  write_csv_atomic(followup_audit, "outputs/tables/followup_audit.csv")
  write_csv_atomic(followup_summary, "outputs/tables/followup_summary.csv")
  write_csv_atomic(missingness_all, "outputs/tables/missingness_all_variables.csv")
  write_csv_atomic(missingness_module_summary, "outputs/tables/missingness_module_summary.csv")
  write_csv_atomic(missingness_core, "outputs/tables/missingness_core_variables.csv")
  write_csv_atomic(missingness_screen, "outputs/tables/missingness_mechanism_screen.csv")
  write_csv_atomic(variable_dictionary, "outputs/tables/variable_dictionary.csv")
  write_csv_atomic(survey_design_inventory, "outputs/tables/survey_design_inventory.csv")
  write_csv_atomic(cohort_profile, "outputs/tables/cohort_profile.csv")
  write_csv_atomic(coverage, "outputs/tables/module_coverage.csv")

  manifest <- list(
    cycle = config$project$cycle,
    seed = PROJECT_SEED,
    participant_key = PARTICIPANT_KEY,
    n_participants = nrow(analytic),
    n_variables = ncol(analytic),
    mortality_followup_end = config$project$mortality_followup_end,
    primary_followup_origin = "interview",
    exam_followup_variable = "mort__followup_months_exam",
    inputs = as.list(stats::setNames(input_audit$sha256, input_audit$source))
  )
  jsonlite::write_json(manifest, "outputs/tables/pipeline_manifest.json", pretty = TRUE, auto_unbox = TRUE)

  session <- capture.output(sessionInfo())
  writeLines(session, "outputs/tables/session_info.txt", useBytes = TRUE)

  invisible(analytic)
}
