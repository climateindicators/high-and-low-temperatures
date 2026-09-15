# Reader for the FOIA-obtained EPA source workbooks in data-raw/*.xlsx.
#
# Unlike epa_csv.R (EPA's published per-figure CSV downloads, one fixed
# preamble layout), these workbooks are EPA's own working files: every sheet's
# header row sits at a different offset and carries its own layout, so the
# caller names the sheet and how many rows to skip rather than this file
# assuming one.
#
# Every column comes back as character, deliberately, for the same reason
# epa_csv.R does it: reading a value as anything but character risks losing
# precision, and nothing here ever calls as.numeric().

#' Read one sheet of a FOIA workbook, header row explicit rather than assumed.
read_epa_xlsx <- function(path, sheet, skip = 0) {
  readxl::read_excel(
    path, sheet = sheet, skip = skip,
    col_types = "text", .name_repair = "minimal"
  )
}
