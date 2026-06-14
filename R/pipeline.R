# Pipeline de ingesta e integración NHANES ----------------------------------

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

cycle_paths <- function(cycle_spec) {
  slug <- cycle_slug(cycle_spec)
  list(
    slug = slug,
    processed_dir = file.path("data", "processed", slug),
    tables_dir = file.path("outputs", slug, "tables"),
    figures_dir = file.path("outputs", slug, "figures"),
    report_dir = file.path("outputs", "report")
  )
}

processed_path <- function(paths, filename) file.path(paths$processed_dir, filename)
table_path <- function(paths, filename) file.path(paths$tables_dir, filename)
figure_path <- function(paths, filename) file.path(paths$figures_dir, filename)

build_input_audit <- function(raw_tables, source_specs, cycle_spec) {
  purrr::imap_dfr(raw_tables, function(data, name) {
    spec <- source_specs[[name]]
    tibble::tibble(
      cycle = cycle_spec$id,
      source = name,
      path = spec$path,
      origin = spec$origin %||% NA_character_,
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

build_variable_dictionary <- function(data, cycle_spec) {
  purrr::map_dfr(names(data), function(variable) {
    x <- data[[variable]]
    tibble::tibble(
      cycle = cycle_spec$id,
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

run_cycle_pipeline <- function(cycle_spec) {
  source_specs <- cycle_spec$sources
  paths <- cycle_paths(cycle_spec)
  fs::dir_create(c(paths$processed_dir, paths$tables_dir, paths$figures_dir, paths$report_dir), recurse = TRUE)

  # Leo y valido cada fuente por separado.
  demographic <- read_nhanes_module(source_specs$demographic, "Demographic")
  examination <- read_nhanes_module(source_specs$examination, "Examination")
  labs <- read_nhanes_module(source_specs$labs, "Labs")
  questionnaire <- read_nhanes_module(source_specs$questionnaire, "Questionnaire")
  mortality <- read_linked_mortality(source_specs$mortality)

  name_collision_audit <- dplyr::bind_rows(
    attr(demographic, "name_collision_audit"),
    attr(examination, "name_collision_audit"),
    attr(labs, "name_collision_audit"),
    attr(questionnaire, "name_collision_audit")
  ) |>
    dplyr::mutate(cycle = cycle_spec$id, .before = 1)

  raw_tables <- list(
    demographic = demographic,
    examination = examination,
    labs = labs,
    questionnaire = questionnaire,
    mortality = mortality
  )

  # Compruebo que los módulos secundarios no añadan SEQN que no estén en
  # Demographic, que es la tabla de partida.
  master_ids <- demographic[[PARTICIPANT_KEY]]
  purrr::iwalk(raw_tables[-1], function(data, name) {
    unexpected <- setdiff(data[[PARTICIPANT_KEY]], master_ids)
    if (length(unexpected) > 0L) {
      stop(cycle_spec$id, ": ", name, " contiene SEQN no presentes en Demographic.", call. = FALSE)
    }
  })

  input_audit <- build_input_audit(raw_tables, source_specs, cycle_spec)

  # Uso Demographic como tabla base. Las uniones izquierdas mantienen la
  # cohorte completa y dejan visible quién no tiene examen, laboratorio o
  # cuestionario.
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

  assert_unique_key(analytic, PARTICIPANT_KEY, paste0(cycle_spec$id, ": tabla analítica"))
  assert_expected_rows(analytic, as.integer(source_specs$demographic$expected_rows), paste0(cycle_spec$id, ": tabla analítica"))

  join_audit <- tibble::tibble(
    cycle = cycle_spec$id,
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
    )
  ) |>
    dplyr::mutate(passed = .data$value == .data$expected)

  if (!all(join_audit$passed)) {
    stop(cycle_spec$id, ": ha fallado al menos una comprobación de integridad de las uniones.", call. = FALSE)
  }

  mortality_audit <- tibble::tibble(
    cycle = cycle_spec$id,
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

  followup_audit <- make_followup_audit(analytic) |>
    dplyr::mutate(cycle = cycle_spec$id, .before = 1)
  if (!all(followup_audit$passed)) {
    stop(cycle_spec$id, ": ha fallado al menos una comprobación del tiempo de seguimiento.", call. = FALSE)
  }

  followup_summary <- make_followup_summary(analytic) |>
    dplyr::mutate(cycle = cycle_spec$id, .before = 1)
  missingness_all <- make_missingness_table(analytic) |>
    dplyr::mutate(cycle = cycle_spec$id, .before = 1)
  missingness_module_summary <- make_module_missingness_summary(missingness_all) |>
    dplyr::mutate(cycle = cycle_spec$id, .before = 1)
  missingness_core <- make_core_missingness_detail(analytic) |>
    dplyr::mutate(cycle = cycle_spec$id, .before = 1)
  missingness_screen <- screen_missingness_mechanisms(analytic) |>
    dplyr::mutate(cycle = cycle_spec$id, .before = 1)
  variable_dictionary <- build_variable_dictionary(analytic, cycle_spec)
  survey_design_inventory <- make_survey_design_inventory(analytic) |>
    dplyr::mutate(cycle = cycle_spec$id, .before = 1)
  cohort_profile <- make_cohort_profile(analytic) |>
    dplyr::mutate(cycle = cycle_spec$id, .before = 1)

  coverage <- make_coverage_figure(analytic, figure_path(paths, "module_coverage.png")) |>
    dplyr::mutate(cycle = cycle_spec$id, .before = 1)
  make_missingness_module_figure(missingness_all, figure_path(paths, "missingness_by_module.png"))
  make_core_missingness_figure(missingness_core, figure_path(paths, "missingness_raw_vs_applicable.png"))
  make_followup_figure(analytic, figure_path(paths, "followup_distribution.png"))
  make_age_eligibility_figure(analytic, figure_path(paths, "age_by_mortality_eligibility.png"))

  # Guardo las salidas dentro de la carpeta del ciclo. Así, si después se
  # añaden otros ciclos, no se mezclan los resultados.
  save_rds_atomic(analytic, processed_path(paths, "nhanes_analytic.rds"), compress = "gzip")
  write_csv_atomic(analytic, processed_path(paths, "nhanes_analytic.csv.gz"))
  write_csv_atomic(input_audit, table_path(paths, "input_audit.csv"))
  write_csv_atomic(join_audit, table_path(paths, "join_audit.csv"))
  write_csv_atomic(mortality_audit, table_path(paths, "mortality_audit.csv"))
  write_csv_atomic(followup_audit, table_path(paths, "followup_audit.csv"))
  write_csv_atomic(followup_summary, table_path(paths, "followup_summary.csv"))
  write_csv_atomic(missingness_all, table_path(paths, "missingness_all_variables.csv"))
  write_csv_atomic(missingness_module_summary, table_path(paths, "missingness_module_summary.csv"))
  write_csv_atomic(missingness_core, table_path(paths, "missingness_core_variables.csv"))
  write_csv_atomic(missingness_screen, table_path(paths, "missingness_mechanism_screen.csv"))
  write_csv_atomic(variable_dictionary, table_path(paths, "variable_dictionary.csv"))
  write_csv_atomic(survey_design_inventory, table_path(paths, "survey_design_inventory.csv"))
  write_csv_atomic(cohort_profile, table_path(paths, "cohort_profile.csv"))
  write_csv_atomic(coverage, table_path(paths, "module_coverage.csv"))
  if (nrow(name_collision_audit) > 0L) {
    write_csv_atomic(name_collision_audit, table_path(paths, "name_collision_audit.csv"))
  }

  manifest <- list(
    cycle = cycle_spec$id,
    cycle_label = cycle_label(cycle_spec),
    cycle_slug = paths$slug,
    seed = PROJECT_SEED,
    participant_key = PARTICIPANT_KEY,
    n_participants = nrow(analytic),
    n_variables = ncol(analytic),
    mortality_followup_end = cycle_spec$mortality_followup_end,
    primary_followup_origin = "interview",
    exam_followup_variable = "mort__followup_months_exam",
    inputs = as.list(stats::setNames(input_audit$sha256, input_audit$source))
  )
  jsonlite::write_json(manifest, table_path(paths, "pipeline_manifest.json"), pretty = TRUE, auto_unbox = TRUE)

  session <- capture.output(sessionInfo())
  writeLines(session, table_path(paths, "session_info.txt"), useBytes = TRUE)

  invisible(list(cycle = cycle_spec$id, analytic = analytic, paths = paths))
}

run_pipeline <- function(cycles = ACTIVE_CYCLE_IDS) {
  set.seed(PROJECT_SEED)
  if (length(cycles) == 0L) {
    stop("No hay ciclos activos definidos en config/sources.yml.", call. = FALSE)
  }
  results <- purrr::map(cycles, function(cycle_id) {
    run_cycle_pipeline(get_cycle_spec(cycle_id))
  })
  names(results) <- cycles
  invisible(results)
}
