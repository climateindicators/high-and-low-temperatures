# Regression checks on the generated data for the High and Low Temperatures indicator.
#
#   Rscript tests/test-data.R
#
# The checks below are shape-independent: they hold whatever the reshape in
# R/build_data.R turns each figure into. Value snapshots, which pin the actual
# numbers so a data update fails loudly instead of passing silently, follow.

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
  # A dataset's provenance is one or more source files (Figures 3 and 4 each
  # combine a published CSV or workbook with the workbook's regression output).
  check(sprintf("%s: every source file is still present and unchanged", ds$file),
        all(vapply(ds$source_files, function(s) {
          identical(file_sha256(file.path("data-raw", s$file)), s$sha256)
        }, logical(1))))
  check(sprintf("%s: no blank rows", ds$file), nrow(df) > 0L)
}

cat("\nFile hygiene\n")
for (f in list.files("data", pattern = "[.](csv|yml)$", full.names = TRUE)) {
  check(sprintf("%s is UTF-8, LF, no BOM, no mojibake", basename(f)),
        tryCatch({ assert_clean_output(f); TRUE },
                 error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
}

cat("\nValue snapshots\n")

# Pins row count, first/last row (in source order), and min/max of `value`
# (and, where present, `p_value` and the `trend` distribution) for each output
# file, so a legitimate data update fails here loudly rather than passing
# silently. Rows are compared as strings, since the source carries precision
# that must survive byte for byte; numeric summaries are compared numerically
# since they are derived, not stored, values.
snap <- function(file, n, first, last, min_value, max_value, trend_counts = NULL) {
  df <- rd(file)
  check(sprintf("%s: row count is %d", file, n), nrow(df) == n)
  check(sprintf("%s: first row matches snapshot", file),
        identical(as.list(df[1, ]), first))
  check(sprintf("%s: last row matches snapshot", file),
        identical(as.list(df[nrow(df), ]), last))
  v <- suppressWarnings(as.numeric(df$value))
  check(sprintf("%s: min(value) is %s", file, min_value),
        isTRUE(all.equal(min(v, na.rm = TRUE), min_value)))
  check(sprintf("%s: max(value) is %s", file, max_value),
        isTRUE(all.equal(max(v, na.rm = TRUE), max_value)))
  if (!is.null(trend_counts)) {
    tab <- table(factor(df$trend, levels = names(trend_counts)), useNA = "no")
    check(sprintf("%s: trend counts match snapshot (increase/decrease/none)", file),
          identical(as.integer(tab), unname(as.integer(trend_counts))))
    check(sprintf("%s: rows with no p-value match matches snapshot", file),
          sum(df$trend == "") == n - sum(trend_counts))
  }
}

snap("high_and_low_temperatures_hot_area.csv", 460L,
     first = list(year = "1910", series = "Hot daily highs", value = "6.4000000000000001E-2"),
     last  = list(year = "2024", series = "Hot daily lows (smoothed)", value = "0.50821875000000005"),
     min_value = 0, max_value = 0.681)

snap("high_and_low_temperatures_cold_area.csv", 456L,
     first = list(year = "1911", series = "Cold Highs", value = "3.5000000000000003E-2"),
     last  = list(year = "2024", series = "9-pt Low", value = "0"),
     min_value = 0, max_value = 0.816)

# 1,065 stations: EPA's own published fig-3.csv (one wholly blank row dropped,
# see R/build_data.R), 18 of which get no p-value from the workbook's
# regression output (13 stations outside its smaller network, 5 more excluded
# because their coordinate is ambiguous in EPA's own published file).
snap("high_and_low_temperatures_hot_days_change.csv", 1065L,
     first = list(station = "USC00011084", state = "AL", lat = "31.0583", long = "-87.055",
                  value = "-14.34591747", p_value = "5.0886501834945003E-2", trend = "decrease"),
     last  = list(station = "", state = "MN", lat = "46.9006", long = "-95.0678",
                  value = "0", p_value = "", trend = ""),
     min_value = -45.36519481, max_value = 47.28247557,
     trend_counts = c(increase = 223L, decrease = 311L, none = 513L))

# 1,052 stations, all matched: the workbook's Figure 4 map sheet and its
# regression output already share the same station-ID network.
snap("high_and_low_temperatures_cold_days_change.csv", 1052L,
     first = list(station = "USC00011084", state = "AL", lat = "31.058299999999999", long = "-87.055000000000007",
                  value = "0", p_value = "0.114767261788794", trend = "none"),
     last  = list(station = "USW00094967", state = "MN", lat = "46.899700000000003", long = "-95.066900000000004",
                  value = "-7.2935064935065235", p_value = "2.7925951190538301E-2", trend = "decrease"),
     min_value = -51.285194805195, max_value = 20.6337912087912,
     trend_counts = c(increase = 21L, decrease = 613L, none = 418L))

snap("high_and_low_temperatures_record_highs_lows.csv", 12L,
     first = list(decade = "1950s", series = "High", value = "52.06733"),
     last  = list(decade = "2000s", series = "Low", value = "-32.84162"),
     min_value = -56.44863, max_value = 67.15838)

cat("\n")
if (length(failures)) {
  cat(sprintf("%d FAILED:\n", length(failures)))
  for (f in failures) cat("  -", f, "\n")
  quit(status = 1L)
}
cat("All data checks passed.\n")
