# Diagnóstico inicial de datos faltantes ------------------------------------

variable_label <- function(variable) {
  label <- unname(CORE_VARIABLE_LABELS[variable])
  ifelse(is.na(label), variable, label)
}

applicability_description <- function(variable) {
  dplyr::case_when(
    variable == "dem__INDFMPIR" ~ "Todos los participantes entrevistados",
    variable %in% c("exam__BMXBMI", "exam__BMXWAIST") ~ "Participantes examinados en MEC de 2 o más años",
    variable %in% c("lab__LBXSGL", "lab__LBXGH") ~ "Participantes con registro de laboratorio de 12 o más años",
    variable == "lab__LBDHDD" ~ "Participantes con registro de laboratorio de 6 o más años",
    variable == "quest__HSD010" ~ "Participantes de 12 o más años",
    variable == "quest__SMQ020" ~ "Participantes de 18 o más años",
    variable == "quest__DIQ010" ~ "Participantes de 1 o más años",
    grepl("^mort__", variable) && variable != "mort__ELIGSTAT" ~ "Participantes elegibles para el archivo público de mortalidad",
    grepl("^exam__", variable) ~ "Participantes con registro de Examination",
    grepl("^lab__", variable) ~ "Participantes con registro de Labs",
    TRUE ~ "Cohorte completa"
  )
}

applicable_population <- function(data, variable) {
  age <- data$dem__RIDAGEYR

  keep <- dplyr::case_when(
    variable %in% c("exam__BMXBMI", "exam__BMXWAIST") ~ data$has_exam_record & age >= 2,
    variable %in% c("lab__LBXSGL", "lab__LBXGH") ~ data$has_lab_record & age >= 12,
    variable == "lab__LBDHDD" ~ data$has_lab_record & age >= 6,
    variable == "quest__HSD010" ~ age >= 12,
    variable == "quest__SMQ020" ~ age >= 18,
    variable == "quest__DIQ010" ~ age >= 1,
    grepl("^exam__", variable) ~ data$has_exam_record,
    grepl("^lab__", variable) ~ data$has_lab_record,
    grepl("^mort__", variable) && variable != "mort__ELIGSTAT" ~ data$mort__ELIGSTAT == 1L,
    TRUE ~ rep(TRUE, nrow(data))
  )

  keep[is.na(keep)] <- FALSE
  data[keep, , drop = FALSE]
}

initial_missingness_interpretation <- function(variable, module) {
  dplyr::case_when(
    variable == "SEQN" ~ "Identificador obligatorio; no procede evaluar ausencia.",
    module == "Linked Mortality" && grepl("UCOD_LEADING|DIABETES|HYPERTEN", variable) ~
      "Ausencia principalmente estructural: estas variables solo se publican para determinados fallecidos.",
    module == "Linked Mortality" ~
      "La ausencia bruta depende de la elegibilidad para el archivo público; debe evaluarse dentro de la población elegible.",
    module == "Examination" ~
      "La ausencia bruta combina no participación en MEC, restricciones de edad y ausencia de la medición.",
    module == "Labs" ~
      "La ausencia bruta combina no participación, restricciones de edad, submuestras y ausencia de la determinación.",
    module == "Questionnaire" ~
      "La ausencia bruta puede responder a edad, patrones de salto, no aplicabilidad o no respuesta.",
    module == "Demographic" ~
      "Ausencia de entrevista o no respuesta al ítem; no debe asumirse MCAR sin comprobar asociaciones observadas.",
    TRUE ~ "Variable derivada o indicador de integración."
  )
}

make_missingness_table <- function(data) {
  n_total <- nrow(data)
  purrr::map_dfr(names(data), function(variable) {
    x <- data[[variable]]
    n_missing <- sum(is.na(x))
    module <- module_from_variable(variable)
    tibble::tibble(
      variable = variable,
      original_variable = original_variable_name(variable),
      module = module,
      n_total = n_total,
      n_missing = n_missing,
      pct_missing = 100 * n_missing / n_total,
      n_observed = n_total - n_missing,
      initial_reading = initial_missingness_interpretation(variable, module)
    )
  }) |>
    dplyr::arrange(dplyr::desc(.data$pct_missing), .data$module, .data$variable)
}

make_module_missingness_summary <- function(missingness_all) {
  missingness_all |>
    dplyr::filter(.data$module %in% c("Demographic", "Examination", "Labs", "Questionnaire", "Linked Mortality")) |>
    dplyr::group_by(.data$module) |>
    dplyr::summarise(
      n_variables = dplyr::n(),
      median_pct_missing = stats::median(.data$pct_missing),
      q1_pct_missing = stats::quantile(.data$pct_missing, 0.25),
      q3_pct_missing = stats::quantile(.data$pct_missing, 0.75),
      variables_gt_10pct = sum(.data$pct_missing > 10),
      variables_gt_50pct = sum(.data$pct_missing > 50),
      variables_gt_90pct = sum(.data$pct_missing > 90),
      variables_100pct = sum(.data$pct_missing == 100),
      .groups = "drop"
    ) |>
    dplyr::arrange(match(.data$module, c("Demographic", "Examination", "Labs", "Questionnaire", "Linked Mortality")))
}

make_core_missingness_detail <- function(data, variables = CORE_MISSINGNESS_VARIABLES) {
  purrr::map_dfr(variables, function(variable) {
    if (!variable %in% names(data)) {
      return(tibble::tibble(
        variable = variable, label = variable_label(variable), module = module_from_variable(variable),
        applicability_rule = applicability_description(variable), n_total = nrow(data),
        n_not_applicable = NA_integer_, n_missing_raw = NA_integer_, pct_missing_raw = NA_real_,
        n_applicable = NA_integer_, n_missing_applicable = NA_integer_, pct_missing_applicable = NA_real_,
        missingness_type = "Variable no disponible"
      ))
    }

    applicable <- applicable_population(data, variable)
    n_total <- nrow(data)
    n_applicable <- nrow(applicable)
    n_missing_raw <- sum(is.na(data[[variable]]))
    n_missing_applicable <- sum(is.na(applicable[[variable]]))

    tibble::tibble(
      variable = variable,
      label = variable_label(variable),
      module = module_from_variable(variable),
      applicability_rule = applicability_description(variable),
      n_total = n_total,
      n_not_applicable = n_total - n_applicable,
      n_missing_raw = n_missing_raw,
      pct_missing_raw = 100 * n_missing_raw / n_total,
      n_applicable = n_applicable,
      n_missing_applicable = n_missing_applicable,
      pct_missing_applicable = ifelse(n_applicable > 0, 100 * n_missing_applicable / n_applicable, NA_real_),
      missingness_type = dplyr::case_when(
        n_total - n_applicable > 0 && n_missing_applicable == 0 ~ "Ausencia estructural por no aplicabilidad",
        n_total - n_applicable > 0 && n_missing_applicable > 0 ~ "Ausencia estructural y ausencia dentro de la población aplicable",
        n_missing_applicable > 0 ~ "Ausencia dentro de la población aplicable",
        TRUE ~ "Sin ausencia"
      )
    )
  })
}

auc_rank <- function(y, score) {
  keep <- !is.na(y) & !is.na(score)
  y <- y[keep]
  score <- score[keep]
  n1 <- sum(y == 1L)
  n0 <- sum(y == 0L)
  if (n1 == 0L || n0 == 0L) return(NA_real_)
  ranks <- rank(score, ties.method = "average")
  (sum(ranks[y == 1L]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}

screen_one_missingness_mechanism <- function(data, variable) {
  if (!variable %in% names(data)) {
    return(tibble::tibble(
      variable = variable, n_applicable = NA_integer_, n_model = NA_integer_,
      n_missing_applicable = NA_integer_, pct_missing_applicable = NA_real_,
      global_p_value = NA_real_, mcfadden_r2 = NA_real_, auc = NA_real_,
      interpretation = "Variable no disponible."
    ))
  }

  applicable <- applicable_population(data, variable)
  model_data <- applicable |>
    dplyr::transmute(
      missing = as.integer(is.na(.data[[variable]])),
      age = .data$dem__RIDAGEYR,
      sex = factor(.data$dem__RIAGENDR),
      race_ethnicity = factor(.data$dem__RIDRETH3),
      income_poverty_ratio = .data$dem__INDFMPIR
    )

  predictor_names <- c("age", "sex", "race_ethnicity", "income_poverty_ratio")
  if (variable == "dem__INDFMPIR") {
    predictor_names <- setdiff(predictor_names, "income_poverty_ratio")
  }

  n_applicable <- nrow(model_data)
  n_missing_applicable <- sum(model_data$missing)
  pct_missing_applicable <- ifelse(n_applicable > 0, 100 * mean(model_data$missing), NA_real_)
  keep <- stats::complete.cases(model_data[, predictor_names, drop = FALSE])
  model_data <- model_data[keep, , drop = FALSE]
  n_model <- nrow(model_data)

  if (n_model < 100L || dplyr::n_distinct(model_data$missing) < 2L) {
    return(tibble::tibble(
      variable = variable,
      n_applicable = n_applicable,
      n_model = n_model,
      n_missing_applicable = n_missing_applicable,
      pct_missing_applicable = pct_missing_applicable,
      global_p_value = NA_real_,
      mcfadden_r2 = NA_real_,
      auc = NA_real_,
      interpretation = if (n_missing_applicable == 0L) {
        "Sin faltantes dentro de la población aplicable."
      } else {
        "No se ajusta el cribado por falta de variación o tamaño suficiente."
      }
    ))
  }

  full_formula <- stats::reformulate(predictor_names, response = "missing")
  full_model <- suppressWarnings(stats::glm(full_formula, data = model_data, family = stats::binomial()))
  null_model <- suppressWarnings(stats::glm(missing ~ 1, data = model_data, family = stats::binomial()))

  global_test <- suppressWarnings(stats::anova(null_model, full_model, test = "Chisq"))
  global_p <- global_test$`Pr(>Chi)`[2]
  r2 <- 1 - as.numeric(stats::logLik(full_model) / stats::logLik(null_model))
  auc <- auc_rank(model_data$missing, stats::predict(full_model, type = "response"))

  tibble::tibble(
    variable = variable,
    n_applicable = n_applicable,
    n_model = n_model,
    n_missing_applicable = n_missing_applicable,
    pct_missing_applicable = pct_missing_applicable,
    global_p_value = global_p,
    mcfadden_r2 = r2,
    auc = auc,
    interpretation = dplyr::case_when(
      is.na(global_p) ~ "Cribado no concluyente.",
      global_p < 0.05 ~ "La ausencia se relaciona con variables observadas; una hipótesis MCAR simple no resulta defendible.",
      TRUE ~ "No se detecta asociación en este cribado, pero ello no demuestra MCAR ni descarta MNAR."
    )
  )
}

screen_missingness_mechanisms <- function(data, variables = CORE_MISSINGNESS_VARIABLES) {
  purrr::map_dfr(variables, ~ screen_one_missingness_mechanism(data, .x)) |>
    dplyr::mutate(global_p_value_bh = stats::p.adjust(.data$global_p_value, method = "BH")) |>
    dplyr::select(
      dplyr::all_of(c(
        "variable", "n_applicable", "n_model", "n_missing_applicable",
        "pct_missing_applicable", "global_p_value", "global_p_value_bh",
        "mcfadden_r2", "auc", "interpretation"
      ))
    )
}
