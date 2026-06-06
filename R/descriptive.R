# Resúmenes y figuras descriptivas ------------------------------------------

make_coverage_figure <- function(analytic, path) {
  coverage <- tibble::tibble(
    source = factor(
      c("Demographic", "Questionnaire", "Examination", "Labs", "Mortalidad vinculada", "Mortalidad elegible"),
      levels = rev(c("Demographic", "Questionnaire", "Examination", "Labs", "Mortalidad vinculada", "Mortalidad elegible"))
    ),
    n = c(
      nrow(analytic),
      sum(analytic$has_questionnaire_record),
      sum(analytic$has_exam_record),
      sum(analytic$has_lab_record),
      sum(!is.na(analytic$mort__ELIGSTAT)),
      sum(analytic$mort__ELIGSTAT == 1L, na.rm = TRUE)
    )
  ) |>
    dplyr::mutate(
      pct = 100 * .data$n / nrow(analytic),
      label = sprintf("%s (%.1f%%)", scales::comma(.data$n, big.mark = ".", decimal.mark = ","), .data$pct)
    )

  figure <- ggplot2::ggplot(coverage, ggplot2::aes(x = .data$pct, y = .data$source)) +
    ggplot2::geom_col(width = 0.68, fill = "#2C5F8A") +
    ggplot2::geom_text(ggplot2::aes(label = .data$label), hjust = -0.05, size = 3.7, color = "#222222") +
    ggplot2::scale_x_continuous(limits = c(0, 116), breaks = seq(0, 100, 20), labels = function(x) paste0(x, "%")) +
    ggplot2::labs(
      title = "Cobertura de las fuentes incorporadas",
      subtitle = "Denominador: 10.175 participantes del módulo Demographic",
      x = "Porcentaje de participantes",
      y = NULL,
      caption = "La elegibilidad del archivo público de mortalidad se evalúa por separado de la vinculación por SEQN."
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.background = ggplot2::element_rect(fill = "white", color = NA),
      panel.background = ggplot2::element_rect(fill = "white", color = NA)
    )

  fs::dir_create(fs::path_dir(path), recurse = TRUE)
  ggplot2::ggsave(path, figure, width = 9.4, height = 5.4, dpi = 180, bg = "white")
  coverage
}

make_missingness_module_figure <- function(missingness_all, path) {
  plot_data <- missingness_all |>
    dplyr::filter(.data$module %in% c("Demographic", "Examination", "Labs", "Questionnaire", "Linked Mortality")) |>
    dplyr::mutate(module = factor(.data$module, levels = rev(c("Demographic", "Examination", "Labs", "Questionnaire", "Linked Mortality"))))

  figure <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .data$pct_missing, y = .data$module)) +
    ggplot2::geom_boxplot(width = 0.55, outlier.shape = NA, fill = "#D9E7F2", color = "#2C5F8A") +
    ggplot2::geom_jitter(height = 0.16, width = 0, alpha = 0.18, size = 0.8, color = "#333333") +
    ggplot2::scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 20), labels = function(x) paste0(x, "%")) +
    ggplot2::labs(
      title = "Distribución del porcentaje bruto de datos faltantes por módulo",
      subtitle = "Cada punto representa una variable de la tabla analítica",
      x = "Porcentaje de valores faltantes sobre la cohorte completa",
      y = NULL,
      caption = "Los porcentajes brutos incluyen ausencia estructural por edad, patrones de salto y submuestras; no equivalen directamente a no respuesta."
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.background = ggplot2::element_rect(fill = "white", color = NA),
      panel.background = ggplot2::element_rect(fill = "white", color = NA)
    )

  fs::dir_create(fs::path_dir(path), recurse = TRUE)
  ggplot2::ggsave(path, figure, width = 9.5, height = 5.8, dpi = 180, bg = "white")
  invisible(plot_data)
}

make_core_missingness_figure <- function(core_detail, path) {
  plot_data <- core_detail |>
    dplyr::select(label, pct_missing_raw, pct_missing_applicable) |>
    tidyr::pivot_longer(
      cols = c("pct_missing_raw", "pct_missing_applicable"),
      names_to = "denominator",
      values_to = "pct_missing"
    ) |>
    dplyr::mutate(
      denominator = dplyr::recode(
        .data$denominator,
        pct_missing_raw = "Cohorte completa",
        pct_missing_applicable = "Población aplicable"
      ),
      label = factor(.data$label, levels = rev(core_detail$label[order(core_detail$pct_missing_raw)]))
    )

  figure <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .data$pct_missing, y = .data$label, fill = .data$denominator)) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.72), width = 0.65) +
    ggplot2::scale_x_continuous(limits = c(0, 105), breaks = seq(0, 100, 20), labels = function(x) paste0(x, "%")) +
    ggplot2::scale_fill_manual(values = c("Cohorte completa" = "#8FAFC8", "Población aplicable" = "#2C5F8A")) +
    ggplot2::labs(
      title = "Datos faltantes antes y después de separar la no aplicabilidad",
      subtitle = "Variables seleccionadas para el diagnóstico inicial",
      x = "Porcentaje de valores faltantes",
      y = NULL,
      fill = NULL,
      caption = "La diferencia entre ambas barras aproxima la parte explicada por restricciones de edad, participación, submuestra o elegibilidad."
    ) +
    ggplot2::theme_minimal(base_size = 11.5) +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "top",
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.background = ggplot2::element_rect(fill = "white", color = NA),
      panel.background = ggplot2::element_rect(fill = "white", color = NA)
    )

  fs::dir_create(fs::path_dir(path), recurse = TRUE)
  ggplot2::ggsave(path, figure, width = 10.2, height = 7.2, dpi = 180, bg = "white")
  invisible(plot_data)
}

make_followup_long <- function(analytic) {
  eligible <- analytic |>
    dplyr::filter(.data$mort__ELIGSTAT == 1L) |>
    dplyr::mutate(vital_status = dplyr::if_else(.data$mort__event == 1L, "Fallecido", "Asumido vivo"))

  dplyr::bind_rows(
    eligible |>
      dplyr::transmute(SEQN = .data$SEQN, vital_status = .data$vital_status,
                       origin = "Desde entrevista", months = .data$mort__followup_months_interview),
    eligible |>
      dplyr::transmute(SEQN = .data$SEQN, vital_status = .data$vital_status,
                       origin = "Desde examen MEC", months = .data$mort__followup_months_exam)
  ) |>
    dplyr::filter(!is.na(.data$months)) |>
    dplyr::mutate(years = .data$months / 12)
}

make_followup_summary <- function(analytic) {
  long <- make_followup_long(analytic)

  summarise_followup <- function(data, group_label) {
    data |>
      dplyr::group_by(.data$origin) |>
      dplyr::summarise(
        vital_status = group_label,
        n = dplyr::n(),
        events = sum(.data$vital_status == "Fallecido"),
        min_months = min(.data$months),
        q1_months = stats::quantile(.data$months, 0.25),
        median_months = stats::median(.data$months),
        q3_months = stats::quantile(.data$months, 0.75),
        max_months = max(.data$months),
        median_years = stats::median(.data$years),
        .groups = "drop"
      )
  }

  dplyr::bind_rows(
    summarise_followup(long, "Total elegibles"),
    long |>
      dplyr::group_by(.data$origin, .data$vital_status) |>
      dplyr::summarise(
        n = dplyr::n(),
        events = sum(.data$vital_status == "Fallecido"),
        min_months = min(.data$months),
        q1_months = stats::quantile(.data$months, 0.25),
        median_months = stats::median(.data$months),
        q3_months = stats::quantile(.data$months, 0.75),
        max_months = max(.data$months),
        median_years = stats::median(.data$years),
        .groups = "drop"
      )
  ) |>
    dplyr::arrange(match(.data$origin, c("Desde entrevista", "Desde examen MEC")),
                   match(.data$vital_status, c("Total elegibles", "Asumido vivo", "Fallecido")))
}

make_followup_audit <- function(analytic) {
  both <- analytic$mort__ELIGSTAT == 1L & !is.na(analytic$mort__PERMTH_INT) & !is.na(analytic$mort__PERMTH_EXM)
  event_values <- sort(unique(stats::na.omit(analytic$mort__event)))

  tibble::tibble(
    check = c(
      "Evento observado para todos los participantes elegibles",
      "Seguimiento desde entrevista disponible para todos los elegibles",
      "Seguimiento desde examen disponible para todos los elegibles examinados",
      "Valores de evento restringidos a 0 y 1",
      "Seguimientos no negativos",
      "El seguimiento desde examen no supera al seguimiento desde entrevista"
    ),
    passed = c(
      all(!is.na(analytic$mort__event[analytic$mort__ELIGSTAT == 1L])),
      all(!is.na(analytic$mort__PERMTH_INT[analytic$mort__ELIGSTAT == 1L])),
      all(!is.na(analytic$mort__PERMTH_EXM[analytic$mort__ELIGSTAT == 1L & analytic$has_exam_record])),
      identical(event_values, c(0L, 1L)),
      all(analytic$mort__PERMTH_INT >= 0, na.rm = TRUE) && all(analytic$mort__PERMTH_EXM >= 0, na.rm = TRUE),
      all(analytic$mort__PERMTH_EXM[both] <= analytic$mort__PERMTH_INT[both])
    ),
    detail = c(
      paste0(sum(analytic$mort__ELIGSTAT == 1L & !is.na(analytic$mort__event), na.rm = TRUE), " / ", sum(analytic$mort__ELIGSTAT == 1L, na.rm = TRUE)),
      paste0(sum(analytic$mort__ELIGSTAT == 1L & !is.na(analytic$mort__PERMTH_INT), na.rm = TRUE), " / ", sum(analytic$mort__ELIGSTAT == 1L, na.rm = TRUE)),
      paste0(sum(analytic$mort__ELIGSTAT == 1L & analytic$has_exam_record & !is.na(analytic$mort__PERMTH_EXM), na.rm = TRUE), " / ", sum(analytic$mort__ELIGSTAT == 1L & analytic$has_exam_record, na.rm = TRUE)),
      paste(event_values, collapse = ", "),
      "Comprobado en PERMTH_INT y PERMTH_EXM",
      paste0(sum(both), " participantes con ambas escalas")
    )
  )
}

make_followup_figure <- function(analytic, path) {
  plot_data <- make_followup_long(analytic) |>
    dplyr::filter(.data$origin == "Desde entrevista") |>
    dplyr::mutate(vital_status = factor(.data$vital_status, levels = c("Asumido vivo", "Fallecido")))

  medians <- plot_data |>
    dplyr::group_by(.data$vital_status) |>
    dplyr::summarise(median_years = stats::median(.data$years), .groups = "drop")

  figure <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .data$years)) +
    ggplot2::geom_histogram(binwidth = 0.5, boundary = 0, fill = "#2C5F8A", color = "white") +
    ggplot2::geom_vline(data = medians, ggplot2::aes(xintercept = .data$median_years), linetype = 2, linewidth = 0.7) +
    ggplot2::facet_wrap(~ vital_status, scales = "free_y", ncol = 1) +
    ggplot2::labs(
      title = "Distribución del tiempo de seguimiento desde la entrevista",
      subtitle = "Participantes elegibles para el Linked Mortality File público",
      x = "Años de seguimiento",
      y = "Número de participantes",
      caption = "La línea discontinua indica la mediana de cada grupo. Para análisis con variables de examen o laboratorio debe emplearse el tiempo desde el examen MEC."
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.background = ggplot2::element_rect(fill = "white", color = NA),
      panel.background = ggplot2::element_rect(fill = "white", color = NA)
    )

  fs::dir_create(fs::path_dir(path), recurse = TRUE)
  ggplot2::ggsave(path, figure, width = 9.4, height = 7.1, dpi = 180, bg = "white")
  invisible(plot_data)
}

make_survey_design_inventory <- function(analytic) {
  tibble::tibble(variable = names(analytic)) |>
    dplyr::filter(grepl("^(dem__SDMV|dem__WT|lab__WT|exam__WT|quest__WT)", .data$variable)) |>
    dplyr::mutate(
      role = dplyr::case_when(
        grepl("SDMVSTRA$", .data$variable) ~ "Estrato del diseño",
        grepl("SDMVPSU$", .data$variable) ~ "Unidad primaria de muestreo",
        grepl("WTINT2YR$", .data$variable) ~ "Peso de entrevista de 2 años",
        grepl("WTMEC2YR$", .data$variable) ~ "Peso de examen MEC de 2 años",
        TRUE ~ "Peso específico de componente o submuestra"
      )
    )
}

make_cohort_profile <- function(analytic) {
  sex <- analytic$dem__RIAGENDR
  age <- analytic$dem__RIDAGEYR
  eligible <- analytic$mort__ELIGSTAT == 1L

  tibble::tibble(
    indicador = c(
      "Participantes en Demographic",
      "Edad mediana (RIQ)",
      "Mujeres",
      "Hombres",
      "Con registro Examination",
      "Con registro Labs",
      "Con Questionnaire",
      "Elegibles para mortalidad pública",
      "Fallecidos entre elegibles",
      "Seguimiento mediano desde entrevista",
      "Seguimiento mediano desde examen MEC"
    ),
    valor = c(
      scales::comma(nrow(analytic), big.mark = ".", decimal.mark = ","),
      sprintf("%s años (%s–%s)",
              format(stats::median(age, na.rm = TRUE), decimal.mark = ","),
              format(stats::quantile(age, 0.25, na.rm = TRUE), decimal.mark = ","),
              format(stats::quantile(age, 0.75, na.rm = TRUE), decimal.mark = ",")),
      sprintf("%s (%.1f%%)", scales::comma(sum(sex == 2, na.rm = TRUE), big.mark = ".", decimal.mark = ","), 100 * mean(sex == 2, na.rm = TRUE)),
      sprintf("%s (%.1f%%)", scales::comma(sum(sex == 1, na.rm = TRUE), big.mark = ".", decimal.mark = ","), 100 * mean(sex == 1, na.rm = TRUE)),
      sprintf("%s (%.1f%%)", scales::comma(sum(analytic$has_exam_record), big.mark = ".", decimal.mark = ","), 100 * mean(analytic$has_exam_record)),
      sprintf("%s (%.1f%%)", scales::comma(sum(analytic$has_lab_record), big.mark = ".", decimal.mark = ","), 100 * mean(analytic$has_lab_record)),
      sprintf("%s (%.1f%%)", scales::comma(sum(analytic$has_questionnaire_record), big.mark = ".", decimal.mark = ","), 100 * mean(analytic$has_questionnaire_record)),
      sprintf("%s (%.1f%%)", scales::comma(sum(eligible, na.rm = TRUE), big.mark = ".", decimal.mark = ","), 100 * mean(eligible, na.rm = TRUE)),
      sprintf("%s (%.1f%% de elegibles)", scales::comma(sum(analytic$mort__event == 1L, na.rm = TRUE), big.mark = ".", decimal.mark = ","), 100 * mean(analytic$mort__event[eligible] == 1L, na.rm = TRUE)),
      sprintf("%s meses", format(stats::median(analytic$mort__followup_months_interview[eligible], na.rm = TRUE), decimal.mark = ",")),
      sprintf("%s meses", format(stats::median(analytic$mort__followup_months_exam[eligible & !is.na(analytic$mort__followup_months_exam)], na.rm = TRUE), decimal.mark = ","))
    )
  )
}

make_age_eligibility_figure <- function(analytic, path) {
  plot_data <- analytic |>
    dplyr::mutate(
      mortality_group = dplyr::case_when(
        .data$mort__ELIGSTAT == 1L ~ "Elegible para seguimiento público",
        .data$mort__ELIGSTAT == 2L ~ "Menor de 18 años no publicado",
        .data$mort__ELIGSTAT == 3L ~ "No elegible",
        TRUE ~ "Sin estado de elegibilidad"
      ),
      mortality_group = factor(
        .data$mortality_group,
        levels = c("Elegible para seguimiento público", "Menor de 18 años no publicado", "No elegible", "Sin estado de elegibilidad")
      )
    )

  figure <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .data$dem__RIDAGEYR)) +
    ggplot2::geom_histogram(binwidth = 5, boundary = 0, fill = "#2C5F8A", color = "white") +
    ggplot2::facet_wrap(~ mortality_group, ncol = 1, scales = "free_y") +
    ggplot2::scale_x_continuous(breaks = seq(0, 80, 10)) +
    ggplot2::labs(
      title = "Edad de la cohorte según elegibilidad para mortalidad pública",
      subtitle = "La restricción de mortalidad afecta principalmente a menores de 18 años",
      x = "Edad en años en el momento de la entrevista",
      y = "Número de participantes",
      caption = "Esta figura ayuda a separar ausencia estructural por elegibilidad de datos realmente faltantes."
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.background = ggplot2::element_rect(fill = "white", color = NA),
      panel.background = ggplot2::element_rect(fill = "white", color = NA)
    )

  fs::dir_create(fs::path_dir(path), recurse = TRUE)
  ggplot2::ggsave(path, figure, width = 9.4, height = 7.6, dpi = 180, bg = "white")
  invisible(plot_data)
}
