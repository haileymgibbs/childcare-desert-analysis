# Child Care Deserts × Race/Ethnicity: AAPI and AIAN Communities

## Overview

This analysis examines the relationship between licensed child care access
and the racial/ethnic composition of U.S. counties, focusing on two
population groups:

- **AAPI** — Asian alone and Native Hawaiian/Other Pacific Islander (NHPI)
  alone populations (2020 Decennial Census, Table P8), analyzed both
  individually and as a combined share. Ultimately, population counts among NHPI communities were too small for county-level estimates and were removed in the revised markdown file.
- **AIAN** — American Indian and Alaska Native alone populations (2020
  Decennial Census, Table P8), analyzed independently of the AAPI categories

Both groups are evaluated against licensed child care desert status —
defined as an area where `adj_supply <= 0.33` (fewer than
roughly 1 licensed slot per 3 children under age 6) — at a **25%** concentration. This smaller concentration was included to account for overall small population counts, so direct comparisons to Black, non-Hispanic and Hispanic/Latino communities should be made with caution.

The analysis also incorporates a rural/urban breakdown to assess whether desert rates in AAPI- and AIAN-concentrated areas differ by rurality.

This work extends and adapts the methodology originally developed by Hailey
Gibbs and Evan Yi for analyzing child care deserts by Hispanic/Latino and
Black, non-Hispanic county composition, with the modification to concentration levels due to population limits.

## Repository Contents in Archive
Please be advised these estimates were abandoned because of coding artifacts related to the NHPI population (e.g., pop flags in KS and OK that could not be accounted for); the 50% concentration threshold was also ultimately abandoned for the 25% threshold.

| File | Description |
|---|---|
| `aapi_aian_childcare_analysis.Rmd` | Main analysis script: data cleaning, race/ethnicity classification, desert rate calculations, rurality breakdown, and diagnostic checks |
| `aapi_aian_childcare_with_race.csv` | Output: childcare access points joined with county-level AAPI/AIAN population shares |
| `aapi_aian_childcare_with_race_rural.csv` | Output: same as above, with rural/urban flag included |
| `aapi_aian_state_desert_rates.csv` | Output: state-level desert rates with average AAPI/AIAN population shares |
| `aapi_state_majority_50.csv`, `aapi_state_majority_25.csv` | Output: state-level desert rates for majority/predominantly AAPI counties |
| `aian_state_majority_50.csv`, `aian_state_majority_25.csv` | Output: state-level desert rates for majority/predominantly AIAN counties |
| `aapi_state_rural_majority_50.csv`, `aapi_state_rural_majority_25.csv` | Output: rural-only versions of the above for AAPI |
| `aian_state_rural_majority_50.csv`, `aian_state_rural_majority_25.csv` | Output: rural-only versions of the above for AIAN |

## ⚠️ Large File Alert

The following input files **exceed GitHub's file size limit** and are
**not included** in this repository. The analysis script will not run
without them.

- **`DECENNIALDHC2020.P8-Data.csv`** — 2020 Decennial Census Demographic and
  Housing Characteristics (DHC) file, Table P8 (Race), at the census tract
  level
- **Child care access data** (`cap_ccaccess_2025_revised_02282026.csv`) — the full licensed child care supply/access dataset.
- **`joined_rural.csv`** — rural/urban classification lookup, joined by
  longitude/latitude to the child care access points

## Methodology Notes

- **Geographic aggregation**: Census tract-level race/ethnicity percentages
  are aggregated to the county level via population-weighted mean, then
  joined to child care access points by county FIPS code. **NOTE**: output related to state aggregates are included as population count gut-checks and are not reported publicly.
- **Small-sample caution**: several state-level findings (particularly for
  Alaska, Kansas, Oklahoma, and some AIAN states) are driven by a single
  county or a small number of childcare data points. The `.Rmd` in the archive folder includes a
  diagnostic chunk (`flag_small_n()`) that automatically surfaces any
  state/category combination backed by 3 or fewer distinct counties. These
  flagged rows should be treated as suggestive, not generalizable, findings. The revised '.Rmd' removed these state-level estimates for a more general estimate, along with the breadown by rurality. 
