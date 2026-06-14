test_that("la tabla analítica conserva una fila por participante", {
  data <- readRDS(here::here("data", "processed", "2013_2014", "nhanes_analytic.rds"))
  expect_equal(nrow(data), 10175L)
  expect_equal(dplyr::n_distinct(data$SEQN), 10175L)
  expect_false(anyNA(data$SEQN))
  expect_false(anyDuplicated(data$SEQN) > 0L)
})

test_that("las uniones no dejan sufijos de colisión sin resolver", {
  data <- readRDS(here::here("data", "processed", "2013_2014", "nhanes_analytic.rds"))
  expect_false(any(grepl("\\.(x|y)$", names(data))))
})

test_that("la vinculación de mortalidad y los dos tiempos de seguimiento son coherentes", {
  data <- readRDS(here::here("data", "processed", "2013_2014", "nhanes_analytic.rds"))
  expect_equal(sum(!is.na(data$mort__ELIGSTAT)), 10175L)
  expect_equal(sum(data$mort__ELIGSTAT == 1L, na.rm = TRUE), 6100L)
  expect_equal(sum(data$mort__event == 1L, na.rm = TRUE), 467L)
  expect_equal(sum(data$mort__ELIGSTAT == 1L & !is.na(data$mort__followup_months_interview), na.rm = TRUE), 6100L)
  expect_equal(sum(data$mort__ELIGSTAT == 1L & !is.na(data$mort__followup_months_exam), na.rm = TRUE), 5913L)

  both <- data$mort__ELIGSTAT == 1L & !is.na(data$mort__followup_months_interview) & !is.na(data$mort__followup_months_exam)
  expect_true(all(data$mort__followup_months_exam[both] <= data$mort__followup_months_interview[both]))
})

test_that("todas las auditorías automáticas se superan", {
  join_audit <- readr::read_csv(
    here::here("outputs", "2013_2014", "tables", "join_audit.csv"),
    show_col_types = FALSE
  )
  followup_audit <- readr::read_csv(
    here::here("outputs", "2013_2014", "tables", "followup_audit.csv"),
    show_col_types = FALSE
  )
  expect_true(all(join_audit$passed))
  expect_true(all(followup_audit$passed))
})

test_that("las fuentes coinciden con las huellas SHA-256 registradas", {
  audit <- readr::read_csv(
    here::here("outputs", "2013_2014", "tables", "input_audit.csv"),
    show_col_types = FALSE
  )
  expect_true(all(audit$sha256_verified))
})

test_that("el informe de faltantes cubre todas las variables y separa aplicabilidad", {
  data <- readRDS(here::here("data", "processed", "2013_2014", "nhanes_analytic.rds"))
  missing_all <- readr::read_csv(
    here::here("outputs", "2013_2014", "tables", "missingness_all_variables.csv"),
    show_col_types = FALSE
  )
  missing_core <- readr::read_csv(
    here::here("outputs", "2013_2014", "tables", "missingness_core_variables.csv"),
    show_col_types = FALSE
  )

  expect_equal(nrow(missing_all), ncol(data))
  expect_equal(missing_core$pct_missing_applicable[missing_core$variable == "mort__event"], 0)
  expect_true(missing_core$pct_missing_raw[missing_core$variable == "mort__event"] > 0)
})
