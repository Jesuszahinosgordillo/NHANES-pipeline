# Lectura de fuentes ---------------------------------------------------------

# Algunos extractos agregados por módulo contienen variables repetidas con
# sufijos .x/.y, introducidos al unir componentes NHANES. Se consolidan solo
# cuando no existe ninguna discrepancia entre valores solapados. El proceso se
# detiene si dos columnas con el mismo nombre base contienen valores distintos.
resolve_join_suffixes <- function(data, module_name) {
  original_names <- names(data)
  base_names <- sub("\\.[xy]$", "", original_names)
  groups <- split(original_names, base_names)
  groups <- groups[lengths(groups) > 1L]

  if (length(groups) == 0L) {
    return(list(
      data = data,
      audit = tibble::tibble(
        module = character(), base_variable = character(), source_columns = character(),
        n_source_columns = integer(), overlap_rows = integer(), conflict_rows = integer(),
        resolution = character()
      )
    ))
  }

  audit <- purrr::imap_dfr(groups, function(cols, base) {
    values <- data[cols]
    conflict <- rep(FALSE, nrow(data))
    overlap <- rep(FALSE, nrow(data))

    if (length(cols) >= 2L) {
      pairs <- utils::combn(seq_along(cols), 2L, simplify = FALSE)
      for (pair in pairs) {
        a <- values[[pair[1L]]]
        b <- values[[pair[2L]]]
        both <- !is.na(a) & !is.na(b)
        overlap <- overlap | both
        conflict <- conflict | (both & as.character(a) != as.character(b))
      }
    }

    if (any(conflict)) {
      stop(
        module_name, ": las columnas ", paste(cols, collapse = ", "),
        " comparten nombre base, pero contienen valores incompatibles.",
        call. = FALSE
      )
    }

    tibble::tibble(
      module = module_name,
      base_variable = base,
      source_columns = paste(cols, collapse = " | "),
      n_source_columns = length(cols),
      overlap_rows = sum(overlap),
      conflict_rows = sum(conflict),
      resolution = ifelse(sum(overlap) > 0L,
                          "Consolidadas; los valores solapados coinciden",
                          "Consolidadas sin solapamiento; revisar definición en codebook")
    )
  })

  for (base in names(groups)) {
    cols <- groups[[base]]
    data[[base]] <- purrr::reduce(data[cols], dplyr::coalesce)
    drop_cols <- setdiff(cols, base)
    data <- dplyr::select(data, -dplyr::all_of(drop_cols))
  }

  list(data = data, audit = audit)
}

read_nhanes_module <- function(spec, module_name) {
  path <- spec$path
  assert_file_exists(path)
  assert_sha256(path, spec$expected_sha256, module_name)

  character_columns <- spec$character_columns %||% character()
  col_spec_args <- c(
    list(.default = readr::col_double()),
    stats::setNames(rep(list(readr::col_character()), length(character_columns)), character_columns)
  )
  col_spec <- do.call(readr::cols, col_spec_args)

  data <- readr::read_csv(
    path,
    na = c("", "NA"),
    col_types = col_spec,
    show_col_types = FALSE,
    progress = FALSE,
    lazy = FALSE,
    name_repair = "minimal"
  )

  data[[PARTICIPANT_KEY]] <- as.integer(data[[PARTICIPANT_KEY]])
  assert_unique_key(data, PARTICIPANT_KEY, module_name)
  assert_expected_rows(data, as.integer(spec$expected_rows), module_name)

  resolved <- resolve_join_suffixes(data, module_name)
  prefixed <- prefix_except_key(resolved$data, spec$prefix, PARTICIPANT_KEY)
  attr(prefixed, "name_collision_audit") <- resolved$audit
  prefixed
}

read_linked_mortality <- function(spec) {
  path <- spec$path
  assert_file_exists(path)
  assert_sha256(path, spec$expected_sha256, "Linked Mortality File")

  positions <- readr::fwf_positions(
    start = c(1, 15, 16, 17, 20, 21, 43, 46),
    end   = c(6, 15, 16, 19, 20, 21, 45, 48),
    col_names = c(
      "SEQN", "ELIGSTAT", "MORTSTAT", "UCOD_LEADING",
      "DIABETES", "HYPERTEN", "PERMTH_INT", "PERMTH_EXM"
    )
  )

  mortality <- readr::read_fwf(
    path,
    col_positions = positions,
    col_types = readr::cols(.default = readr::col_integer()),
    na = c("", ".", "..", "..."),
    trim_ws = TRUE,
    progress = FALSE,
    lazy = FALSE
  )

  assert_unique_key(mortality, PARTICIPANT_KEY, "Linked Mortality File")
  assert_expected_rows(mortality, as.integer(spec$expected_rows), "Linked Mortality File")

  prefix_except_key(mortality, spec$prefix, PARTICIPANT_KEY)
}
