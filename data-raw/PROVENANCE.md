# Provenance

Every file in this directory is reproduced unmodified from EPA's published
indicator page and its per-figure data downloads. To update the data, replace the
file and rerun `Rscript R/build_data.R`.

## Indicator page

- `source-page.html`  \
  <https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-high-and-low-temperatures/index.html>  \
  sha256 `3a4116fc01e9cf974787931ea5279fdc9c7f68b2ab0dddfd4d8fb6c3f0375db9`

Technical documentation: <https://19january2025snapshot.epa.gov/system/files/documents/2024-06/high-low-temps_documentation.pdf>

## Figure data

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
  data source: NOAA, 2024; web update: June 2024; units: Change in number of days hotter than 95th percentile

- `high-low-temps_fig-4.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-06/high-low-temps_fig-4.csv>  \
  sha256 `5aa136e5b3d34738196ccc318938d233fecd1356522a5c67292ec53bab60e826`  \
  encoding UTF-8, 1052 data rows, columns: `State`, `Lat`, `Long`, `Change in 5 percent Days`  \
  title: Figure 4. Change in Unusually Cold Temperatures in the Contiguous 48 States, 1948-2023  \
  data source: NOAA, 2024; web update: June 2024; units: Change in number of days colder than 5th percentile

- `high-low-temps_fig-5.csv`  \
  <https://19january2025snapshot.epa.gov/sites/default/files/2021-04/high-low-temps_fig-5.csv>  \
  sha256 `9731a69dd9cca72d712e2cba92c06d6920c4ce0cefd8e58d37ea621bc6205019`  \
  encoding UTF-8, 6 data rows, columns: `Decade`, `High %`, `Low %`  \
  title: Figure 5. Record Daily High and Low Temperatures in the Contiguous 48 States, 1950-2009  \
  data source: Meehl et al., 2009; web update: April 2021; units: Percent of daily records
