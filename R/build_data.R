# Build tidy long-format data for the High and Low Temperatures indicator.
#
#   Rscript R/build_data.R
#
# Writes data/*.csv plus data/meta.yml. Rerunning with unchanged inputs
# produces byte-identical output. Nothing here touches the network.
#
# Data sources, and why they differ per figure (data-raw/PROVENANCE.md has the
# full account):
#
#   Figures 1, 2, 5  the FOIA-obtained EPA source workbooks (data-raw/*.xlsx),
#                     not EPA's published per-figure CSVs. For Figure 1 the
#                     workbook is a later, revised NCEI re-download (1910-2024
#                     instead of EPA's published 1910-2023, and the values for
#                     years both cover differ). Figure 2's workbook and its
#                     published CSV agree to floating-point noise; the
#                     workbook is used anyway for a consistent source across
#                     the three area/decade figures. Figure 5's workbook only
#                     adds decimal precision the published CSV's "52.07%"
#                     strings rounded away.
#
#   Figures 3, 4      the published CSVs, joined with the significance
#                     (p-value) columns from the FOIA workbook's regression
#                     output. This is the opposite direction from Figures 1/2:
#                     the workbook's own station-map sheet for Figure 3 turns
#                     out to hold *fewer* stations (1,052) than EPA's published
#                     CSV (1,065), so the CSV is the more complete network and
#                     the workbook only contributes the p-value on top of it.
#                     Figure 4's station networks already agree, so that join
#                     is direct by station ID; Figure 3 has no station-ID
#                     column in the published CSV, so it joins on state plus
#                     coordinates instead, and five ambiguous coordinate
#                     collisions in EPA's own CSV are excluded from that join
#                     rather than guessed at (see below).
#
# TO UPDATE THE DATA: drop replacement files into data-raw/ and rerun. Headers
# are asserted, not assumed, so a renamed or reordered column stops the build.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

root <- here::here()
source(file.path(root, "R/utils/epa_csv.R"))
source(file.path(root, "R/utils/epa_xlsx.R"))
source(file.path(root, "R/utils/write_stable.R"))

raw_dir <- file.path(root, "data-raw")
out_dir <- file.path(root, "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Indicator constants -----------------------------------------------------

INDICATOR <- list(
  name                    = "High and Low Temperatures",
  slug                    = "high-and-low-temperatures",
  publisher               = "U.S. Environmental Protection Agency",
  source_page             = "https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-high-and-low-temperatures/index.html",
  technical_documentation = "https://19january2025snapshot.epa.gov/system/files/documents/2024-06/high-low-temps_documentation.pdf",
  rights                  = "Public domain, work of the U.S. Government (17 U.S.C. 105)"
)

# ---- Figure 1: Area of the Contiguous 48 States with Unusually Hot Summer Temperatures ----
#
# EPA's own published title states 1910-2023; the workbook this reshapes
# covers 1910-2024 and revises prior years as well (see the module comment
# above and data-raw/PROVENANCE.md). figure_title below still records EPA's
# own wording, since that is what it is: the workbook does not rename itself.

f1_meta_path <- file.path(raw_dir, "high-low-temps_fig-1.csv")
f1_meta      <- read_epa_preamble(f1_meta_path)

f1_path <- file.path(raw_dir, "high-low-temps_figure-1_04-28-24.xlsx")
f1_cols <- c("Year", "Hot daily highs", "Hot daily highs (smoothed)",
             "Hot daily lows", "Hot daily lows (smoothed)")
# The sheet pads its four series out to 47 columns with blank filler and other
# EPA working columns; only the ones this figure actually needs are kept.
f1_raw <- read_epa_xlsx(f1_path, sheet = "Data for Figure 1")[f1_cols]

assert_headers(
  f1_raw,
  id_cols          = "Year",
  expected_headers = setdiff(f1_cols, "Year"),
  what             = "figure-1 workbook, 'Data for Figure 1' sheet"
)

f1 <- f1_raw %>%
  rename(year = Year) %>%
  pivot_longer(-year, names_to = "series", values_to = "value") %>%
  mutate(year = as.integer(year))

assert_conservation(
  f1_raw,
  value_cols = setdiff(f1_cols, "Year"),
  n_out      = nrow(f1),
  what       = "figure-1 workbook"
)

write_csv_stable(f1, file.path(out_dir, "high_and_low_temperatures_hot_area.csv"))

# ---- Figure 2: Area of the Contiguous 48 States with Unusually Cold Winter Temperatures ----

f2_meta_path <- file.path(raw_dir, "high-low-temps_fig-2.csv")
f2_meta      <- read_epa_preamble(f2_meta_path)

f2_path <- file.path(raw_dir, "high-low-temps_figure-2_04-03-24.xlsx")
f2_cols <- c("Year", "Cold Highs", "9-pt High", "Cold Lows", "9-pt Low")
f2_raw  <- read_epa_xlsx(f2_path, sheet = "Data for Figure 2")[f2_cols]

assert_headers(
  f2_raw,
  id_cols          = "Year",
  expected_headers = setdiff(f2_cols, "Year"),
  what             = "figure-2 workbook, 'Data for Figure 2' sheet"
)

f2 <- f2_raw %>%
  rename(year = Year) %>%
  pivot_longer(-year, names_to = "series", values_to = "value") %>%
  mutate(year = as.integer(year))

assert_conservation(
  f2_raw,
  value_cols = setdiff(f2_cols, "Year"),
  n_out      = nrow(f2),
  what       = "figure-2 workbook"
)

write_csv_stable(f2, file.path(out_dir, "high_and_low_temperatures_cold_area.csv"))

# ---- Figures 3 and 4 shared setup: the significance (p-value) source --------

f34_path <- file.path(raw_dir, "high-low-temps_figures-3 and 4_04-15-24.xlsx")
rc_cols  <- c("station", "state", "lat", "long",
              "coefs_100", "pval_100", "coefs_95th", "pval_95th",
              "coefs_0", "pval_0", "coefs_5th", "pval_5th")
rc_raw   <- read_epa_xlsx(f34_path, sheet = "Regression Coefficients_output", skip = 1)
names(rc_raw)[seq_along(rc_cols)] <- rc_cols

# The sheet pads its 1,052 stations out to 1,066 rows with wholly blank
# trailing rows (a spreadsheet artifact, not data, matching the row count of
# the workbook's Figure 3 map sheet); they carry no station and are dropped.
rc <- rc_raw[!is.na(rc_raw$station), c("station", "state", "lat", "long", "pval_95th", "pval_5th")]
stopifnot(
  "Regression Coefficients_output must have exactly 1052 real stations" =
    nrow(rc) == 1052L,
  "station must be a unique key in Regression Coefficients_output" =
    !anyDuplicated(rc$station)
)

# A station's regression is treated as not statistically distinguishable from
# noise at EPA's own 90% confidence convention (documented in the workbook's
# own Methods and Notes sheets for this figure pair): p >= 0.10 becomes
# "none" regardless of the sign of value, which is otherwise read straight off
# the (already-computed) change-in-days figure.
classify_trend <- function(value, p_value) {
  p <- suppressWarnings(as.numeric(p_value))
  v <- suppressWarnings(as.numeric(value))
  dplyr::case_when(
    is.na(p)  ~ NA_character_,
    p >= 0.10 ~ "none",
    v >= 0    ~ "increase",
    TRUE      ~ "decrease"
  )
}

# ---- Figure 3: Change in Unusually Hot Temperatures, by station -------------
#
# The workbook's own "Figure 3 Map Data" sheet turns out to hold only 1,052
# stations (identical to Figure 4's network), 13 fewer than EPA's published
# fig-3.csv (1,065 real stations). The published CSV is therefore the base
# here, not the workbook, and the workbook only contributes pval_95th on top
# of it. See data-raw/PROVENANCE.md.

f3_path <- file.path(raw_dir, "high-low-temps_fig-3.csv")
f3_meta <- read_epa_preamble(f3_path)
f3_raw  <- read_epa_csv(f3_path)

assert_headers(
  f3_raw,
  id_cols          = c("State", "Lat", "Long"),
  expected_headers = "Change in 95 percent Days",
  what             = "high-low-temps_fig-3.csv"
)

# One row in EPA's own published file is wholly blank (no station, no value);
# it carries nothing, so it is dropped here rather than joined, and the drop
# is asserted rather than silent.
f3_blank <- !nzchar(f3_raw$State)
stopifnot(
  "expected exactly one wholly blank row in fig-3.csv" = sum(f3_blank) == 1L
)
f3_stations <- f3_raw[!f3_blank, ]

# The published CSV has no station-ID column, so the join key to the
# workbook's p-values is state plus coordinates, rounded to the CSV's own
# 4-decimal precision. Five stations in the CSV share a coordinate with
# another row in EPA's own file (not introduced here); two of those five
# pairs report different values under the same coordinate, so which p-value
# belongs to which listed value cannot be told apart. All five ambiguous keys
# are excluded from the join rather than guessed at, on both sides, so those
# rows come through with trend = NA instead of a potentially misattributed one.
join_key <- function(state, lat, long) {
  paste(state, sprintf("%.4f", as.numeric(lat)), sprintf("%.4f", as.numeric(long)))
}
f3_stations$join_key <- join_key(f3_stations$State, f3_stations$Lat, f3_stations$Long)
rc$join_key          <- join_key(rc$state, rc$lat, rc$long)

ambiguous_keys <- unique(f3_stations$join_key[duplicated(f3_stations$join_key) |
                                                 duplicated(f3_stations$join_key, fromLast = TRUE)])
rc_for_f3 <- rc[!(rc$join_key %in% ambiguous_keys), c("join_key", "station", "pval_95th")]

f3_joined <- dplyr::left_join(f3_stations, rc_for_f3, by = "join_key")
stopifnot("the significance join must not change Figure 3's station count" =
            nrow(f3_joined) == nrow(f3_stations))

f3 <- f3_joined %>%
  transmute(
    station = station, state = State, lat = Lat, long = Long,
    value   = `Change in 95 percent Days`,
    p_value = pval_95th,
    trend   = classify_trend(value, pval_95th)
  )

write_csv_stable(f3, file.path(out_dir, "high_and_low_temperatures_hot_days_change.csv"))

# ---- Figure 4: Change in Unusually Cold Temperatures, by station ------------
#
# The workbook's own "Figure 4 Map Data" sheet already matches the published
# fig-4.csv station-for-station (both 1,052 stations, both carry Station IDs),
# so this joins directly to the workbook's own map sheet and its p-values, no
# coordinate matching needed.

f4_meta_path <- file.path(raw_dir, "high-low-temps_fig-4.csv")
f4_meta      <- read_epa_preamble(f4_meta_path)

f4_cols <- c("Station", "State", "Lat", "Long", "Change in 5 percent Days")
f4_raw  <- read_epa_xlsx(f34_path, sheet = "Figure 4 Map Data")[f4_cols]

assert_headers(
  f4_raw,
  id_cols          = c("Station", "State", "Lat", "Long"),
  expected_headers = "Change in 5 percent Days",
  what             = "figures-3-and-4 workbook, 'Figure 4 Map Data' sheet"
)

rc_for_f4 <- rc[c("station", "pval_5th")]

f4_joined <- dplyr::left_join(f4_raw, rc_for_f4, by = c("Station" = "station"))
stopifnot(
  "the significance join must not change Figure 4's station count" =
    nrow(f4_joined) == nrow(f4_raw),
  "every Figure 4 station must get a p-value" = !anyNA(f4_joined$pval_5th)
)

f4 <- f4_joined %>%
  transmute(
    station = Station, state = State, lat = Lat, long = Long,
    value   = `Change in 5 percent Days`,
    p_value = pval_5th,
    trend   = classify_trend(value, pval_5th)
  )

write_csv_stable(f4, file.path(out_dir, "high_and_low_temperatures_cold_days_change.csv"))

# ---- Figure 5: Record Daily High and Low Temperatures, by decade -----------

f5_meta_path <- file.path(raw_dir, "high-low-temps_fig-5.csv")
f5_meta      <- read_epa_preamble(f5_meta_path)

f5_path <- file.path(raw_dir, "high-low-temps_figure-5_04-15-24.xlsx")
f5_raw  <- read_epa_xlsx(f5_path, sheet = "Data for Figure 5", skip = 1)

assert_headers(
  f5_raw,
  id_cols          = "Decade",
  expected_headers = c("High %", "Low %"),
  what             = "figure-5 workbook, 'Data for Figure 5' sheet"
)

f5 <- f5_raw %>%
  rename(decade = Decade) %>%
  pivot_longer(-decade, names_to = "series", values_to = "value") %>%
  mutate(
    series = recode(series, "High %" = "High", "Low %" = "Low"),
    # The workbook stores this as a decimal fraction (0.5206733...), unlike the
    # published CSV's "52.07%" strings; multiplying by 100 here (as text, to
    # keep every digit the workbook carries) puts it on the same percent scale
    # the rest of this indicator's `value` columns use.
    value  = format(as.numeric(value) * 100, scientific = FALSE, trim = TRUE)
  )

assert_conservation(
  f5_raw,
  value_cols = c("High %", "Low %"),
  n_out      = nrow(f5),
  what       = "figure-5 workbook"
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

# A dataset's provenance is one or more source files, since Figures 3 and 4
# each combine the published CSV (or workbook) with the workbook's regression
# output. Each entry hashes the file it actually reads, not a path.
src <- function(path) list(file = basename(path), sha256 = file_sha256(path))

TREND_NOTE <- paste(
  "trend is \"increase\"/\"decrease\" when the station's regression is",
  "significant at EPA's own 90% confidence convention (p < 0.10), \"none\"",
  "when it is not distinguishable from noise (p >= 0.10), and blank when no",
  "p-value could be matched to this station (see data-raw/PROVENANCE.md)."
)

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "high_and_low_temperatures_hot_area.csv",
      figure          = "Figure 1",
      figure_title    = f1_meta$title,
      source_files    = list(src(f1_path)),
      data_source     = f1_meta$data_source,
      web_update      = f1_meta$web_update,
      unit            = f1_meta$units,
      note            = "Figure title and stated range are EPA's published wording; the workbook this reshapes is a later, revised re-download (1910-2024) that disagrees with EPA's published figure in most years. See data-raw/PROVENANCE.md.",
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
      source_files    = list(src(f2_path)),
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
      source_files    = list(src(f3_path), src(f34_path)),
      data_source     = f3_meta$data_source,
      web_update      = f3_meta$web_update,
      unit            = f3_meta$units,
      note            = TREND_NOTE,
      rows            = nrow(f3),
      columns         = describe(f3, list(
        station = list(type = "string", description = "NOAA/GHCN station identifier, where a p-value could be matched; blank for the stations EPA's published map carries that the workbook's regression output does not cover."),
        state   = list(type = "string", description = "Two-letter U.S. state abbreviation for the reporting station."),
        lat     = list(type = "number", description = "Station latitude, decimal degrees."),
        long    = list(type = "number", description = "Station longitude, decimal degrees."),
        value   = list(type = "number", description = "Change in the number of days per year with a maximum temperature above the station's local 95th-percentile threshold, comparing the start and end of the 1948-2023 record (positive = more unusually hot days)."),
        p_value = list(type = "number", description = "P-value of the station's regression, from EPA's own workbook; blank where no matching station could be found (see note)."),
        trend   = list(type = "string", description = "\"increase\", \"decrease\", \"none\", or blank; see note.")
      ))
    ),
    list(
      file            = "high_and_low_temperatures_cold_days_change.csv",
      figure          = "Figure 4",
      figure_title    = f4_meta$title,
      source_files    = list(src(f34_path)),
      data_source     = f4_meta$data_source,
      web_update      = f4_meta$web_update,
      unit            = f4_meta$units,
      note            = TREND_NOTE,
      rows            = nrow(f4),
      columns         = describe(f4, list(
        station = list(type = "string", description = "NOAA/GHCN station identifier."),
        state   = list(type = "string", description = "Two-letter U.S. state abbreviation for the reporting station."),
        lat     = list(type = "number", description = "Station latitude, decimal degrees."),
        long    = list(type = "number", description = "Station longitude, decimal degrees."),
        value   = list(type = "number", description = "Change in the number of days per year with a minimum temperature below the station's local 5th-percentile threshold, comparing the start and end of the 1948-2023 record (positive = more unusually cold days)."),
        p_value = list(type = "number", description = "P-value of the station's regression, from EPA's own workbook."),
        trend   = list(type = "string", description = "\"increase\", \"decrease\", or \"none\"; see note.")
      ))
    ),
    list(
      file            = "high_and_low_temperatures_record_highs_lows.csv",
      figure          = "Figure 5",
      figure_title    = f5_meta$title,
      source_files    = list(src(f5_path)),
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
