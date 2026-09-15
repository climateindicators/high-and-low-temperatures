# Provenance

Every file in this directory is reproduced unmodified from either EPA's
published indicator page and its per-figure data downloads, or from EPA's own
source workbooks obtained via a FOIA request. `R/build_data.R` documents,
figure by figure, which file(s) it actually reshapes and why; the summary
below is the provenance of each file on disk. To update the data, replace the
relevant file(s) and rerun `Rscript R/build_data.R`.

## Indicator page

- `source-page.html`  \
  <https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-high-and-low-temperatures/index.html>  \
  sha256 `3a4116fc01e9cf974787931ea5279fdc9c7f68b2ab0dddfd4d8fb6c3f0375db9`

Technical documentation: <https://19january2025snapshot.epa.gov/system/files/documents/2024-06/high-low-temps_documentation.pdf>

## EPA's published per-figure CSV downloads

These are used only for their five-line metadata preamble (title, data
source, web update, units) for Figures 1, 2, and 5, and as the station base
for Figure 3 (see below); they are not the row data reshaped for Figures 1,
2, or 5, which instead comes from the FOIA workbooks documented further down.

- `high-low-temps_fig-1.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-06/high-low-temps_fig-1.csv>  \
  sha256 `d87afc01514b2c0f614df72ee9bbd18e97820b47e626dbbf1e03064a676dcbc3`  \
  encoding UTF-8, 114 data rows, columns: `Year`, `Hot daily highs`, `Hot daily lows`, `Hot daily highs (smoothed)`, `Hot daily lows (smoothed)`  \
  title: Figure 1. Area of the Contiguous 48 States with Unusually Hot Summer Temperatures, 1910-2023  \
  data source: NOAA, 2024; web update: June 2024; units: Percent of land area

- `high-low-temps_fig-2.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-06/high-low-temps_fig-2.csv>  \
  sha256 `b8d904ea6c9963e020edc9a981c9ae9577a61f84709d9fd84f3c7b4fcddb5d98`  \
  encoding UTF-8, 114 data rows, columns: `Year`, `Cold Highs`, `9-pt High`, `Cold Lows`, `9-pt Low`  \
  title: Figure 2. Area of the Contiguous 48 States with Unusually Cold Winter Temperatures, 1911-2024  \
  data source: NOAA, 2024; web update: June 2024; units: Percent of land area

- `high-low-temps_fig-3.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-06/high-low-temps_fig-3.csv>  \
  sha256 `ca109eb179f90a24db4e6c55cd3bb7cfdbae3877da3645a643ecc948523ae0e1`  \
  encoding UTF-8, 1066 data rows, columns: `State`, `Lat`, `Long`, `Change in 95 percent Days`  \
  title: Figure 3. Change in Unusually Hot Temperatures in the Contiguous 48 States, 1948-2023  \
  data source: NOAA, 2024; web update: June 2024; units: Change in number of days hotter than 95th percentile  \
  **This is the base data for Figure 3's output** (see "Combining the two sources" below): its 1,065 real stations (1,066 rows, one wholly blank at line 1060) are a *superset* of the station network in the FOIA workbook's own "Figure 3 Map Data" sheet, which independently checks out to only 1,052 stations, identical to Figure 4's network. Five stations in this CSV share a coordinate (rounded to 4 decimals) with another row in the same file; for two of those five pairs, the two listed values differ. Both rows are kept; `R/build_data.R` does not guess which is which.

- `high-low-temps_fig-4.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-06/high-low-temps_fig-4.csv>  \
  sha256 `5aa136e5b3d34738196ccc318938d233fecd1356522a5c67292ec53bab60e826`  \
  encoding UTF-8, 1052 data rows, columns: `State`, `Lat`, `Long`, `Change in 5 percent Days`  \
  title: Figure 4. Change in Unusually Cold Temperatures in the Contiguous 48 States, 1948-2023  \
  data source: NOAA, 2024; web update: June 2024; units: Change in number of days colder than 5th percentile  \
  Used only for its metadata preamble; Figure 4's row data comes from the FOIA workbook's own "Figure 4 Map Data" sheet, which matches this file's station network exactly.

- `high-low-temps_fig-5.csv`  \
  <https://19january2025snapshot.epa.gov/sites/default/files/2021-04/high-low-temps_fig-5.csv>  \
  sha256 `9731a69dd9cca72d712e2cba92c06d6920c4ce0cefd8e58d37ea621bc6205019`  \
  encoding UTF-8, 6 data rows, columns: `Decade`, `High %`, `Low %`  \
  title: Figure 5. Record Daily High and Low Temperatures in the Contiguous 48 States, 1950-2009  \
  data source: Meehl et al., 2009; web update: April 2021; units: Percent of daily records

## FOIA source workbooks

The following four Excel workbooks were obtained separately via a FOIA
request and were already present in this directory before this repository
was built. They are EPA's own working files behind Figures 1-5: the R output
and station-level regression data EPA's analysts used before condensing the
results into the published CSVs above.

- `high-low-temps_figure-1_04-28-24.xlsx`, sheet "Data for Figure 1": row
  data for Figure 1. Covers 1910-2024, a later NCEI re-download than EPA's
  published 1910-2023, and the values differ from the published CSV in most
  years both cover (e.g. 2021 "Hot daily highs" is 0.409 here vs. 0.414 in
  `high-low-temps_fig-1.csv`). Used because it is the more current data;
  EPA's own published figure and title describe the older vintage.
- `high-low-temps_figure-2_04-03-24.xlsx`, sheet "Data for Figure 2": row
  data for Figure 2. Checked against `high-low-temps_fig-2.csv` for years
  2018-2023: identical apart from floating-point noise (max difference
  5e-10). Used for a consistent source with Figures 1 and 5, not because it
  revises anything.
- `high-low-temps_figures-3 and 4_04-15-24.xlsx`: three sheets used.
  - "Figure 4 Map Data": row data for Figure 4 (Station, State, Lat, Long,
    Change in 5 percent Days). Matches `high-low-temps_fig-4.csv`
    station-for-station.
  - "Figure 3 Map Data": **not used as Figure 3's row data** (see above); its
    "Change in 95 percent Days" column has three separately labelled
    instances in the raw sheet (a spreadsheet artifact from copy-pasted
    headers), of which only the first is real — verified by cross-checking
    against `high-low-temps_fig-3.csv` (0 mismatches across all 1,052 shared
    stations) and against "Days Conversion - Map" below (also 0 mismatches).
    The other two instances (143 mismatches against the verified column) are
    not used and their content is unexplained.
  - "Regression Coefficients_output" (real header on row 2 of the sheet, row
    1 just says "EPA Output from R"): supplies `pval.95th` (Figure 3) and
    `pval.5th` (Figure 4), one row per station, joined by Station ID for
    Figure 4 and by state+coordinates for Figure 3 (no Station-ID column on
    the published CSV side). 1,052 real stations; the sheet pads its Station
    column to 1,066 rows with 14 wholly blank trailing rows, dropped before
    joining. A second, later block of the same columns starting around
    column 19 ("Previous update: EPA Output from R") is an older QC snapshot
    and is not used.
  - "Days Conversion - Map": used only to cross-validate the "Figure 3 Map
    Data" column choice above (see that note); not read by `R/build_data.R`.
    Also confirmed to share the 1,052-station network, not the CSV's 1,065.
- `high-low-temps_figure-5_04-15-24.xlsx`, sheet "Data for Figure 5" (real
  header on row 2): row data for Figure 5, as decimal fractions with full
  precision (e.g. `0.52067329902274539`) rather than the published CSV's
  rounded `"52.07%"` strings. `R/build_data.R` multiplies by 100 (as text,
  keeping every digit) to match this indicator's other percent-scaled
  `value` columns.

## Combining the two sources for Figures 3 and 4

Figure 4 needs no combining: the workbook's own map sheet and its regression
output already share the same 1,052-station network, so `value` and
`p_value`/`trend` come from the workbook alone, joined by Station ID.

Figure 3 does need combining, in the direction opposite to Figures 1/2/5:
there, the workbook is the more *current* source; here, the workbook's
"Figure 3 Map Data" sheet turns out to be the less *complete* one (1,052
stations against the published CSV's 1,065). `R/build_data.R` therefore uses
the published CSV as Figure 3's station base (`state`, `lat`, `long`,
`value`) and left-joins the workbook's `pval.95th` on top, by state plus
coordinates rounded to the CSV's own 4-decimal precision. Two things this
join does not attempt to paper over:

1. 13 of the CSV's 1,065 stations have no match in the workbook's smaller
   network at all, so they carry a blank `p_value`/`trend`.
2. 5 more stations share a rounded coordinate with another row in the CSV
   itself (see the fig-3.csv entry above); those five keys are excluded from
   the join on both sides rather than guessed at, so they also carry a blank
   `p_value`/`trend`, on top of the 13 above (18 blank stations total).

`trend` classifies a station as `"none"` when its p-value is at or above
0.10 (EPA's own 90%-confidence convention, documented in the workbook's
Methods and Notes sheets for this figure pair), or `"increase"`/`"decrease"`
by the sign of `value` otherwise.
