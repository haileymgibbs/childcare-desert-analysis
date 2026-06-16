# Child Care Deserts × Hispanic/Latino, Black, non-Hispanic

**Authors:** Hailey Gibbs & Evan Yi
**Last updated:** April 2026

This folder contains the code and input data for an analysis of child care desert rates by county racial and ethnic composition, with a further breakdown by urbanicity. It examines whether children in majority-Hispanic and majority-Black non-Hispanic counties face higher desert rates than children in other counties, and whether those patterns hold or shift in rural areas specifically.

---

## What This Analysis Does

The analysis proceeds in four steps:

1. **Data preparation:** Race and ethnicity data from the Census are joined to the child care access dataset at the county level. A rurality flag is then joined by geographic coordinates from `joined_rural.csv`. Points missing any of the key variables (`adj_supply`, race shares, or rural status) are dropped before analysis.

2. **County type classification:** Each data point is assigned a county type based on its county's population composition:
   - **Majority Hispanic** — county is >50% Hispanic
   - **Majority Black NH** — county is >50% Black, non-Hispanic
   - **Neither majority** — all other counties

3. **Desert rates by county type:** Desert rates (share of areas with `adj_supply ≤ 0.33`) are calculated for each county type overall, then broken out by rural vs. non-rural status.

4. **State-level drivers:** For rural majority-Hispanic and rural majority-Black NH counties specifically, desert rates are calculated by state to identify geographic concentrations.

---

## Files in This Folder

### Scripts

| File | Description |
|---|---|
| `desertsxrace.Rmd` | R Markdown file containing the full analysis |

### Input Data

| File | Description |
|---|---|
| `cap_ccaccess_2025_revised_02282026.csv` | Child care access data from the Center for American Progress (CCD full file, 2025 revision). Each row represents approximately 10 children and includes an `adj_supply` score measuring licensed child care availability |
| `pop_hispanic_blacknh.csv` | Cleaned Census tract-level race and ethnicity data (see details below) |

### ⚠️ Large File Notice

`joined_rural.csv` exceeds GitHub's file size limit and is **not included in this repository**. It can be downloaded here:

🔗 [joined_rural.csv on Google Drive](https://drive.google.com/file/d/17-cLCuDMT-M9Iujmw4yHfhYeasQr7J7R/view?usp=sharing)

Download the file and place it in this folder before running the analysis. It is used to join a rurality flag (`rural`: 0/1) to each child care data point by longitude and latitude, and also contains urban-rural classification codes (`urb_code`, `urb_category`) from NCHS.

---

## Input Data Details: `pop_hispanic_blacknh.csv`

This file contains Census tract-level population estimates for Hispanic and Black non-Hispanic residents, cleaned and compiled from American Community Survey data. It is used to compute county-level weighted average race and ethnicity shares, which are then joined to the child care access data.

**Source:** U.S. Census Bureau, American Community Survey (tract-level estimates)

**Columns:**

| Column | Description |
|---|---|
| `GEO_ID` | Full Census tract identifier in the format `1400000US` + 11-digit FIPS (e.g. `1400000US01001020100`) |
| `NAME` | Census tract name (e.g. `Census Tract 201; Autauga County; Alabama`) |
| `total_pop` | Total tract population, used as the weight when aggregating to county level |
| `hispanic` | Count of Hispanic or Latino residents in the tract |
| `black_nonh` | Count of Black or African American, non-Hispanic residents in the tract |
| `pct_hispanic` | Hispanic residents as a share of total tract population |
| `pct_black_nonh` | Black non-Hispanic residents as a share of total tract population |

**Derivation:** The script strips the `1400000US` prefix from `GEO_ID` and extracts the first five digits as the county FIPS code. It then computes population-weighted county averages of `pct_hispanic` and `pct_black_nonh` across all tracts in each county, dropping tracts missing either share before aggregating.

---

## How to Run the Analysis

### Requirements

- R (≥ 4.2 recommended)
- The following R package:

```r
install.packages("tidyverse")
```

### Steps

1. Clone or download this repository and open the folder in your R project.
2. Download `joined_rural.csv` from the Google Drive link above and place it in this folder.
3. Confirm that `cap_ccaccess_2025_revised_02282026.csv` and `pop_hispanic_blacknh.csv` are also present in this folder.
4. Open `desertsxrace.Rmd` in RStudio.
5. Click **Knit** to run the full analysis and render the output document, or run chunks individually in order.

Results are printed inline within the document. No output CSV files are written by this script.

---

## Data Sources

- **Center for American Progress** — *Child Care Access Dataset*, 2025 revision (February 2026)
- **U.S. Census Bureau** — American Community Survey, tract-level race and ethnicity estimates, compiled in `pop_hispanic_blacknh.csv`
- **Rurality classifications** — Joined by geographic coordinates via `joined_rural.csv`, which combines HRSA FORHP rural county eligibility and NCHS urban-rural classification codes
