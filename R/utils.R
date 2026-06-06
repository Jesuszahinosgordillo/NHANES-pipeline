`%||%` <- function(x, y) if (is.null(x)) y else x

# Funciones auxiliares y salvaguardas ---------------------------------------

assert_file_exists <- function(path) {
  if (!fs::file_exists(path)) {
    stop("No existe el archivo requerido: ", path, call. = FALSE)
  }
  invisible(path)
}

assert_has_columns <- function(data, columns, object_name = deparse(substitute(data))) {
  missing_columns <- setdiff(columns, names(data))
  if (length(missing_columns) > 0L) {
    stop(
      object_name, " no contiene las columnas requeridas: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(data)
}

assert_unique_key <- function(data, key = PARTICIPANT_KEY, object_name = deparse(substitute(data))) {
  assert_has_columns(data, key, object_name)
  n_missing <- sum(is.na(data[[key]]))
  n_duplicated <- sum(duplicated(data[[key]]))
  if (n_missing > 0L || n_duplicated > 0L) {
    stop(
      object_name, " incumple la clave única ", key,
      ": faltantes=", n_missing, ", duplicados=", n_duplicated,
      call. = FALSE
    )
  }
  invisible(data)
}

assert_expected_rows <- function(data, expected_rows, object_name = deparse(substitute(data))) {
  if (nrow(data) != expected_rows) {
    stop(
      object_name, " tiene ", nrow(data), " filas; se esperaban ", expected_rows,
      ". Se detiene el pipeline para evitar procesar silenciosamente otra versión de los datos.",
      call. = FALSE
    )
  }
  invisible(data)
}

prefix_except_key <- function(data, prefix, key = PARTICIPANT_KEY) {
  dplyr::rename_with(data, ~ paste0(prefix, .x), -dplyr::all_of(key))
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

assert_sha256 <- function(path, expected_sha256, object_name = path) {
  observed_sha256 <- sha256_file(path)
  if (!identical(observed_sha256, expected_sha256)) {
    stop(
      object_name, " no coincide con la huella SHA-256 registrada. ",
      "Se detiene el pipeline para evitar procesar una fuente modificada o distinta.",
      call. = FALSE
    )
  }
  invisible(observed_sha256)
}

write_csv_atomic <- function(data, path) {
  fs::dir_create(fs::path_dir(path), recurse = TRUE)
  suffix <- if (grepl("\\.gz$", path)) ".tmp.csv.gz" else ".tmp.csv"
  temp_path <- paste0(path, suffix)

  # Los CSV no comprimidos se escriben con BOM para que Excel en Windows
  # reconozca correctamente la codificación UTF-8 y no muestre caracteres
  # como "definición". Los CSV comprimidos se mantienen en UTF-8 estándar.
  if (grepl("\\.gz$", path)) {
    vroom::vroom_write(data, temp_path, delim = ",", na = "")
  } else {
    readr::write_excel_csv(data, temp_path, na = "")
  }

  if (fs::file_exists(path)) fs::file_delete(path)
  fs::file_move(temp_path, path)
  invisible(path)
}

save_rds_atomic <- function(object, path, compress = "xz") {
  fs::dir_create(fs::path_dir(path), recurse = TRUE)
  temp_path <- paste0(path, ".tmp")
  saveRDS(object, temp_path, compress = compress)
  if (fs::file_exists(path)) fs::file_delete(path)
  fs::file_move(temp_path, path)
  invisible(path)
}

module_from_variable <- function(variable) {
  dplyr::case_when(
    variable == PARTICIPANT_KEY ~ "identifier",
    grepl("^dem__", variable) ~ "Demographic",
    grepl("^exam__", variable) ~ "Examination",
    grepl("^lab__", variable) ~ "Labs",
    grepl("^quest__", variable) ~ "Questionnaire",
    grepl("^mort__", variable) ~ "Linked Mortality",
    grepl("^has_", variable) ~ "integration flag",
    TRUE ~ "derived"
  )
}

original_variable_name <- function(variable) {
  sub("^(dem__|exam__|lab__|quest__|mort__)", "", variable)
}
