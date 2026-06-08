# Rural Child Care Deserts Analysis

**Author:** Hailey Gibbs
**Last updated:** May 2026

This folder contains the code and input data for an exploratory analysis of child care access in rural communities across the United States. It examines how average child care supply scores and desert rates vary by rurality classification, using two independent federal definitions of "rural" — one from HRSA and one from the National Center for Health Statistics (NCHS) — as well as a breakdown by state and care type.

---

## What This Analysis Does

The analysis proceeds in five steps:

1. **FORHP rural classification:** County-level child care access data are joined to the HRSA Federal Office of Rural Health Policy (FORHP) Rural Health Areas dataset. Each county is classified as either "Fully FORHP Rural" or "Not Fully FORHP Rural," and a binary rural flag is created. Descriptive statistics compare the share of synthetic families living in rural vs. non-rural counties nationally.

2. **Supply by FORHP rurality:** Average adjusted supply scores — overall and by care type (family child care, child care center, Head Start, and Pre-K) — are summarized by rural status, both nationally and by state.

3. **NCHS urban-rural classification:** The child care data are also joined to the NCHS Urban-Rural Classification Scheme, which assigns each county one of six urbanicity codes ranging from Large Central Metro (1) to Noncore (6). This provides a more granular picture of how child care access shifts across the rural-urban continuum.

4. **Desert rates by urban code:** Desert rates (share of areas with `adj_supply < 0.33`) are calculated for each of the six NCHS urbanicity categories nationally, and then broken out by state and urbanicity category. Results show a consistent gradient: desert rates rise as counties become more rural.

5. **State/classification filter function:** A reusable function (`filt_state_code`) is defined to filter the joined dataset to a specific state and summarize average supply scores by either FORHP or NCHS classification, supporting ad hoc state-level exploration.

---

## Key Definitions

| Term | Definition |
|---|---|
| **Child care desert** | A location where `adj_supply < 0.33`, meaning there are more than three children for every available licensed child care slot |
| **Fully FORHP Rural** | Counties designated as fully rural by the HRSA Federal Office of Rural Health Policy |
| **NCHS urban-rural codes** | Six-tier classification: 1 = Large central metro, 2 = Large fringe metro, 3 = Medium metro, 4 = Small metro, 5 = Micropolitan, 6 = Noncore |

Note: the desert threshold in this script uses a strict less-than operator (`< 0.33`) rather than less-than-or-equal (`<= 0.33`). Other scripts in this repository use `<= 0.33`. This difference is preserved from the original source script.

---

## Files in This Folder

### Scripts

| File | Description |
|---|---|
| `hg_rural_deserts.Rmd` | R Markdown file containing the full analysis |

### Input Data

| File | Description |
|---|---|
| `cap_ccaccess_2025_revised_02282026.csv` | Child care access data from the Center for American Progress (CCD full file, 2025 revision). Each row represents approximately 10 children and includes an `adj_supply` score and care-type-specific supply scores |
| `rural-health-areas-data-set.xlsx` | HRSA Rural Health Areas dataset (sheet 3). Contains county-level FORHP rural eligibility classifications. Download from [HRSA](https://www.hrsa.gov/rural-health/about-us/what-is-rural/data-files) |
| `data-table.csv` | NCHS Urban-Rural Classification Scheme data table. Contains six-tier urbanicity codes and categories for each county. Download from [CDC/NCHS](https://www.cdc.gov/nchs/data_access/urban_rural.htm) |

### Interactive Parameter

The script includes a `state_filter` variable (set to `'XX'` by default) that can be changed to any two-letter state abbreviation to count FORHP-classified counties for a specific state. It also includes a `classification` variable (set to `'urb_code'` by default) that controls whether the filter function aggregates by FORHP binary rural status (`'rural'`) or NCHS urbanicity code (`'urb_code'`).

---

## How to Run the Analysis

### Requirements

- R (≥ 4.2 recommended)
- The following R packages:

```r
install.packages(c(
  "tidyverse", "magrittr", "readr", "readxl",
  "ggplot2", "ggthemes", "collections", "zoo",
  "maps", "here"
))
```

### Steps

1. Clone or download this repository and open the folder in your R project.
2. Download `rural-health-areas-data-set.xlsx` from the HRSA link above and place it in this folder.
3. Download `data-table.csv` from the CDC/NCHS link above and place it in this folder.
4. Confirm that `cap_ccaccess_2025_revised_02282026.csv` is also present in this folder.
5. Open `hg_rural_deserts.Rmd` in RStudio.
6. Click **Knit** to run the full analysis and render the output document, or run chunks individually in order.

To filter results to a specific state, update `state_filter <- 'XX'` to the two-letter abbreviation of interest before running the FORHP-by-state chunk. To switch the filter function between FORHP and NCHS classification, update `classification <- 'urb_code'` to `classification <- 'rural'`.

Results are printed inline within the document. No output CSV files are written by this script.

---

## Data Sources

- **Center for American Progress** — *Child Care Access Dataset*, 2025 revision (February 2026). Each row represents approximately 10 synthetic families derived from Census data.
- **HRSA Federal Office of Rural Health Policy** — *Rural Health Areas Data Set*. County-level rural eligibility classifications based on the FORHP definition of rural. Available at: <https://www.hrsa.gov/rural-health/about-us/what-is-rural/data-files>
- **National Center for Health Statistics (NCHS)** — *Urban-Rural Classification Scheme for Counties*, 2023. Six-tier county-level urbanicity codes. Available at: <https://www.cdc.gov/nchs/data_access/urban_rural.htm>
