# Build tidy long-format data for the High and Low Temperatures indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's published figure CSVs in data-raw/ and writes data/*.csv plus
# data/meta.yml. Rerunning with unchanged inputs produces byte-identical output.
# Nothing here touches the network.
#
# Generated as a stub by the build-indicator skill. Each figure below has a
# `todo_reshape()` call standing where its reshape belongs. Replace that line,
# then delete the todo_reshape() helper once no call to it remains.
#
# TO UPDATE THE DATA: drop replacement CSVs into data-raw/ and rerun. Headers
# are asserted, not assumed, so a renamed or reordered column stops the build.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

root <- here::here()
source(file.path(root, "R/utils/epa_csv.R"))
source(file.path(root, "R/utils/write_stable.R"))

raw_dir <- file.path(root, "data-raw")
out_dir <- file.path(root, "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

todo_reshape <- function(n) {
  stop(
    "R/build_data.R: the reshape for figure ", n, " has not been written yet.\n",
    "Replace the todo_reshape(", n, ") call with the pivot that produces the tidy\n",
    "long-format data frame for that figure, then remove this helper.",
    call. = FALSE
  )
}

# ---- Indicator constants -----------------------------------------------------

INDICATOR <- list(
  name                    = "High and Low Temperatures",
  slug                    = "high-and-low-temperatures",
  publisher               = "U.S. Environmental Protection Agency",
  source_page             = "https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-high-and-low-temperatures/index.html",
  technical_documentation = "https://19january2025snapshot.epa.gov/system/files/documents/2024-06/high-low-temps_documentation.pdf",
  rights                  = "Public domain, work of the U.S. Government (17 U.S.C. 105)"
)

# ---- Figure 1: Area of the Contiguous 48 States with Unusually Hot Summer Temperatures, 1910-2023 ----

f1_path <- file.path(raw_dir, "high-low-temps_fig-1.csv")
f1_meta <- read_epa_preamble(f1_path)
f1_raw  <- read_epa_csv(f1_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f1_raw,
  id_cols          = "Year",
  expected_headers = c("Hot daily highs", "Hot daily lows", "Hot daily highs (smoothed)", "Hot daily lows (smoothed)"),
  what             = "high-low-temps_fig-1.csv"
)

# One row per year per series: annual share of land area with unusually hot
# daily highs/lows, plus EPA's 9-point binomial-smoothed version of each.
f1 <- f1_raw %>%
  rename(year = Year) %>%
  pivot_longer(-year, names_to = "series", values_to = "value") %>%
  mutate(year = as.integer(year))

assert_conservation(
  f1_raw,
  value_cols = c("Hot daily highs", "Hot daily lows", "Hot daily highs (smoothed)", "Hot daily lows (smoothed)"),
  n_out      = nrow(f1),
  what       = "high-low-temps_fig-1.csv"
)

write_csv_stable(f1, file.path(out_dir, "high_and_low_temperatures_hot_area.csv"))

# ---- Figure 2: Area of the Contiguous 48 States with Unusually Cold Winter Temperatures, 1911-2024 ----

f2_path <- file.path(raw_dir, "high-low-temps_fig-2.csv")
f2_meta <- read_epa_preamble(f2_path)
f2_raw  <- read_epa_csv(f2_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f2_raw,
  id_cols          = "Year",
  expected_headers = c("Cold Highs", "9-pt High", "Cold Lows", "9-pt Low"),
  what             = "high-low-temps_fig-2.csv"
)

# One row per year per series: annual share of land area with unusually cold
# daily highs/lows ("Cold Highs"/"Cold Lows"), plus EPA's 9-point
# binomial-smoothed version of each ("9-pt High"/"9-pt Low").
f2 <- f2_raw %>%
  rename(year = Year) %>%
  pivot_longer(-year, names_to = "series", values_to = "value") %>%
  mutate(year = as.integer(year))

assert_conservation(
  f2_raw,
  value_cols = c("Cold Highs", "9-pt High", "Cold Lows", "9-pt Low"),
  n_out      = nrow(f2),
  what       = "high-low-temps_fig-2.csv"
)

write_csv_stable(f2, file.path(out_dir, "high_and_low_temperatures_cold_area.csv"))

# ---- Figure 3: Change in Unusually Hot Temperatures in the Contiguous 48 States, 1948-2023 ----

f3_path <- file.path(raw_dir, "high-low-temps_fig-3.csv")
f3_meta <- read_epa_preamble(f3_path)
f3_raw  <- read_epa_csv(f3_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f3_raw,
  id_cols          = c("State", "Lat", "Long"),
  expected_headers = "Change in 95 percent Days",
  what             = "high-low-temps_fig-3.csv"
)

# Already one row per station; only the column names need tidying.
f3 <- f3_raw %>%
  rename(state = State, lat = Lat, long = Long, value = `Change in 95 percent Days`)

write_csv_stable(f3, file.path(out_dir, "high_and_low_temperatures_hot_days_change.csv"))

# ---- Figure 4: Change in Unusually Cold Temperatures in the Contiguous 48 States, 1948-2023 ----

f4_path <- file.path(raw_dir, "high-low-temps_fig-4.csv")
f4_meta <- read_epa_preamble(f4_path)
f4_raw  <- read_epa_csv(f4_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f4_raw,
  id_cols          = c("State", "Lat", "Long"),
  expected_headers = "Change in 5 percent Days",
  what             = "high-low-temps_fig-4.csv"
)

# Already one row per station; only the column names need tidying.
f4 <- f4_raw %>%
  rename(state = State, lat = Lat, long = Long, value = `Change in 5 percent Days`)

write_csv_stable(f4, file.path(out_dir, "high_and_low_temperatures_cold_days_change.csv"))

# ---- Figure 5: Record Daily High and Low Temperatures in the Contiguous 48 States, 1950-2009 ----

f5_path <- file.path(raw_dir, "high-low-temps_fig-5.csv")
f5_meta <- read_epa_preamble(f5_path)
f5_raw  <- read_epa_csv(f5_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f5_raw,
  id_cols          = "Decade",
  expected_headers = c("High %", "Low %"),
  what             = "high-low-temps_fig-5.csv"
)

# One row per decade per series: share of daily record highs vs. record lows
# set that decade. The source embeds the unit as a literal "%" suffix on every
# value ("52.07%"); that suffix is stripped so `value` stays numeric-parseable,
# per the site's read_indicator() contract, without changing the number itself.
f5 <- f5_raw %>%
  rename(decade = Decade) %>%
  pivot_longer(-decade, names_to = "series", values_to = "value") %>%
  mutate(
    series = recode(series, "High %" = "High", "Low %" = "Low"),
    value  = sub("%$", "", value)
  )

assert_conservation(
  f5_raw,
  value_cols = c("High %", "Low %"),
  n_out      = nrow(f5),
  what       = "high-low-temps_fig-5.csv"
)

write_csv_stable(f5, file.path(out_dir, "high_and_low_temperatures_record_highs_lows.csv"))

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

# One entry per output column, in order, filled from the data frame itself so it
# cannot drift. `info` supplies the type/description for every column by name;
# a column with no entry stops the build rather than shipping undocumented.
describe <- function(df, info) {
  lapply(names(df), function(nm) {
    d <- info[[nm]]
    if (is.null(d)) {
      stop("No data-dictionary entry for column '", nm, "'; add one to the",
           " `info` list passed to describe().", call. = FALSE)
    }
    col(nm, d$type, d$description)
  })
}

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "high_and_low_temperatures_hot_area.csv",
      figure          = "Figure 1",
      figure_title    = f1_meta$title,
      source_file     = "high-low-temps_fig-1.csv",
      source_sha256   = file_sha256(f1_path),
      source_encoding = "UTF-8",
      data_source     = f1_meta$data_source,
      web_update      = f1_meta$web_update,
      unit            = f1_meta$units,
      rows            = nrow(f1),
      columns         = describe(f1, list(
        year   = list(type = "integer", description = "Calendar year."),
        series = list(type = "string", description = "Which hot-extreme metric this row measures: 'Hot daily highs'/'Hot daily lows' are EPA's annual values, and 'Hot daily highs (smoothed)'/'Hot daily lows (smoothed)' are EPA's 9-point binomial smooth of the same series."),
        value  = list(type = "number", description = "Share of the contiguous 48 states' land area, as a decimal fraction (e.g. 0.066 = 6.6%), that experienced unusually hot daily high or low temperatures that year, per the series column.")
      ))
    ),
    list(
      file            = "high_and_low_temperatures_cold_area.csv",
      figure          = "Figure 2",
      figure_title    = f2_meta$title,
      source_file     = "high-low-temps_fig-2.csv",
      source_sha256   = file_sha256(f2_path),
      source_encoding = "UTF-8",
      data_source     = f2_meta$data_source,
      web_update      = f2_meta$web_update,
      unit            = f2_meta$units,
      rows            = nrow(f2),
      columns         = describe(f2, list(
        year   = list(type = "integer", description = "Calendar year."),
        series = list(type = "string", description = "Which cold-extreme metric this row measures: 'Cold Highs'/'Cold Lows' are EPA's annual values, and '9-pt High'/'9-pt Low' are EPA's 9-point binomial smooth of the same series."),
        value  = list(type = "number", description = "Share of the contiguous 48 states' land area, as a decimal fraction (e.g. 0.035 = 3.5%), that experienced unusually cold daily high or low temperatures that year, per the series column.")
      ))
    ),
    list(
      file            = "high_and_low_temperatures_hot_days_change.csv",
      figure          = "Figure 3",
      figure_title    = f3_meta$title,
      source_file     = "high-low-temps_fig-3.csv",
      source_sha256   = file_sha256(f3_path),
      source_encoding = "UTF-8",
      data_source     = f3_meta$data_source,
      web_update      = f3_meta$web_update,
      unit            = f3_meta$units,
      rows            = nrow(f3),
      columns         = describe(f3, list(
        state = list(type = "string", description = "Two-letter U.S. state abbreviation for the reporting station."),
        lat   = list(type = "number", description = "Station latitude, decimal degrees."),
        long  = list(type = "number", description = "Station longitude, decimal degrees."),
        value = list(type = "number", description = "Change in the number of days per year with a maximum temperature above the station's local 95th-percentile threshold, comparing the start and end of the 1948-2023 record (positive = more unusually hot days).")
      ))
    ),
    list(
      file            = "high_and_low_temperatures_cold_days_change.csv",
      figure          = "Figure 4",
      figure_title    = f4_meta$title,
      source_file     = "high-low-temps_fig-4.csv",
      source_sha256   = file_sha256(f4_path),
      source_encoding = "UTF-8",
      data_source     = f4_meta$data_source,
      web_update      = f4_meta$web_update,
      unit            = f4_meta$units,
      rows            = nrow(f4),
      columns         = describe(f4, list(
        state = list(type = "string", description = "Two-letter U.S. state abbreviation for the reporting station."),
        lat   = list(type = "number", description = "Station latitude, decimal degrees."),
        long  = list(type = "number", description = "Station longitude, decimal degrees."),
        value = list(type = "number", description = "Change in the number of days per year with a minimum temperature below the station's local 5th-percentile threshold, comparing the start and end of the 1948-2023 record (positive = more unusually cold days).")
      ))
    ),
    list(
      file            = "high_and_low_temperatures_record_highs_lows.csv",
      figure          = "Figure 5",
      figure_title    = f5_meta$title,
      source_file     = "high-low-temps_fig-5.csv",
      source_sha256   = file_sha256(f5_path),
      source_encoding = "UTF-8",
      data_source     = f5_meta$data_source,
      web_update      = f5_meta$web_update,
      unit            = f5_meta$units,
      rows            = nrow(f5),
      columns         = describe(f5, list(
        decade = list(type = "string", description = "Decade label, e.g. '1950s', spanning 1950-2009."),
        series = list(type = "string", description = "'High' or 'Low': whether this row counts record daily highs or record daily lows set that decade."),
        value  = list(type = "number", description = "Share of that decade's daily temperature records that were record highs (series = 'High') or record lows (series = 'Low'), as a percent (e.g. 52.07 = 52.07%). Record-low shares are negative so the two series plot on opposite sides of zero.")
      ))
    )
  )
)

write_yaml_stable(meta, file.path(out_dir, "meta.yml"))

# ---- Verify what was written -------------------------------------------------

written <- list.files(out_dir, pattern = "[.](csv|yml)$", full.names = TRUE)
invisible(lapply(written, assert_clean_output))

cat("\nWrote:\n")
for (p in written) {
  cat(sprintf("  %-34s %8d bytes  %s\n", basename(p), file.size(p), substr(file_sha256(p), 1, 12)))
}
