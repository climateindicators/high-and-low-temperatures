# Regression checks on the generated data for the High and Low Temperatures indicator.
#
#   Rscript tests/test-data.R
#
# The checks below are shape-independent: they hold whatever the reshape in
# R/build_data.R turns each figure into. Value snapshots, which pin the actual
# numbers so a data update fails loudly instead of passing silently, are the
# TODO at the bottom.

setwd(here::here())
source("R/utils/write_stable.R")

# Keeps the dictionary check readable when a meta.yml field is absent altogether.
`%||%` <- function(a, b) if (is.null(a)) b else a

failures <- character()
check <- function(label, ok) {
  ok <- isTRUE(ok)
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) failures <<- c(failures, label)
  invisible(ok)
}

rd <- function(f) {
  readr::read_csv(file.path("data", f),
                  col_types = readr::cols(.default = readr::col_character()),
                  na = character(), progress = FALSE)
}

meta <- yaml::read_yaml("data/meta.yml")

cat("\nData dictionary\n")
check("meta.yml documents 5 dataset(s)", length(meta$datasets) == 5L)
check("meta.yml has no timestamp",
      !any(grepl("\\d{4}-\\d{2}-\\d{2}T|Sys\\.time|generated_at",
                 readLines("data/meta.yml", warn = FALSE))))

for (ds in meta$datasets) {
  df   <- rd(ds$file)
  cols <- vapply(ds$columns, function(x) x$name, character(1))
  check(sprintf("%s: meta.yml lists the columns the file actually has", ds$file),
        identical(cols, names(df)))
  check(sprintf("%s: meta.yml row count matches the file", ds$file),
        identical(as.integer(ds$rows), nrow(df)))
  check(sprintf("%s: every column has a type and a description", ds$file),
        all(vapply(ds$columns, function(x) nzchar(x$type %||% "") && nzchar(x$description %||% ""), logical(1))))
  check(sprintf("%s: source file is still present and unchanged", ds$file),
        identical(file_sha256(file.path("data-raw", ds$source_file)), ds$source_sha256))
  check(sprintf("%s: no blank rows", ds$file), nrow(df) > 0L)
}

cat("\nFile hygiene\n")
for (f in list.files("data", pattern = "[.](csv|yml)$", full.names = TRUE)) {
  check(sprintf("%s is UTF-8, LF, no BOM, no mojibake", basename(f)),
        tryCatch({ assert_clean_output(f); TRUE },
                 error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
}

cat("\nValue snapshots\n")

# Pins row count, first/last row (in source order), and min/max of `value` for
# each output file, so a legitimate data update fails here loudly rather than
# passing silently. Rows are compared as strings, since the source carries up
# to 10 significant digits that must survive byte for byte; min/max of `value`
# are compared numerically since they are derived, not stored, values.
snap <- function(file, n, first, last, min_value, max_value) {
  df <- rd(file)
  check(sprintf("%s: row count is %d", file, n), nrow(df) == n)
  check(sprintf("%s: first row matches snapshot", file),
        identical(as.list(df[1, ]), first))
  check(sprintf("%s: last row matches snapshot", file),
        identical(as.list(df[nrow(df), ]), last))
  # data-raw/high-low-temps_fig-3.csv has one wholly blank data row (line 1060:
  # ",,,", EPA's own file, not introduced here); na.rm drops it from min/max
  # the same way it is faithfully carried through as an empty row in the output.
  v <- suppressWarnings(as.numeric(df$value))
  check(sprintf("%s: min(value) is %s", file, min_value),
        isTRUE(all.equal(min(v, na.rm = TRUE), min_value)))
  check(sprintf("%s: max(value) is %s", file, max_value),
        isTRUE(all.equal(max(v, na.rm = TRUE), max_value)))
}

snap("high_and_low_temperatures_hot_area.csv", 456L,
     first = list(year = "1910", series = "Hot daily highs", value = "0.066"),
     last  = list(year = "2023", series = "Hot daily lows (smoothed)", value = "0.444671875"),
     min_value = 0, max_value = 0.693)

snap("high_and_low_temperatures_cold_area.csv", 456L,
     first = list(year = "1911", series = "Cold Highs", value = "0.035"),
     last  = list(year = "2024", series = "9-pt Low", value = "0"),
     min_value = 0, max_value = 0.816)

snap("high_and_low_temperatures_hot_days_change.csv", 1066L,
     first = list(state = "AL", lat = "31.0583", long = "-87.055", value = "-14.34591747"),
     last  = list(state = "MN", lat = "46.9006", long = "-95.0678", value = "0"),
     min_value = -45.36519481, max_value = 47.28247557)

snap("high_and_low_temperatures_cold_days_change.csv", 1052L,
     first = list(state = "AL", lat = "31.0583", long = "-87.055", value = "0"),
     last  = list(state = "MN", lat = "46.8997", long = "-95.0669", value = "-7.293506494"),
     min_value = -51.28519481, max_value = 20.63379121)

snap("high_and_low_temperatures_record_highs_lows.csv", 12L,
     first = list(decade = "1950s", series = "High", value = "52.07"),
     last  = list(decade = "2000s", series = "Low", value = "-32.84"),
     min_value = -56.45, max_value = 67.16)

cat("\n")
if (length(failures)) {
  cat(sprintf("%d FAILED:\n", length(failures)))
  for (f in failures) cat("  -", f, "\n")
  quit(status = 1L)
}
cat("All data checks passed.\n")
