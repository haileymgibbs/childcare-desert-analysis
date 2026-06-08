# Child Care Desert Analyses
**Last updated:** May 2026

This subfolder contains six related subanalyses examining licensed child care deserts across the United States. 
All analyses use the Center for American Progress child care access dataset as their primary input and are organized into individual subfolders, each with its own R Markdown script.

---

## What Is a Child Care Desert?

A location is classified as a **child care desert** if its adjusted supply score (`adj_supply`) is at or below 0.33 — meaning there are more than three children for every available licensed child care slot. 
Supply scores are also available for specific care types: Head Start (`adj_supply_hs`), Pre-K (`adj_supply_prek`), family child care (`adj_supply_fcc`), and child care centers (`adj_supply_ccc`).
The primary data source is the Center for American Progress Child Care Access Dataset (2025 revision, February 2026), produced in collaboration with the W.E. Upjohn Institute for Employment Research and Stanford University. 
Each row represents approximately 10 children.

---

## Analyses in This Folder

### 1. National and State Desert Estimates (Overall)
**Script:** `CCD_desert_estimates.Rmd`

National and state-level desert rates using the core child care access data, including a breakdown by care type (Head Start, Pre-K, family child care, child care center) and a state-level comparison of zero-supply, low-supply, and desert thresholds.

---

### 2. County-Level Desert Estimates
**Script:** `childcare_desert_analysis.Rmd`

Aggregates desert status to the county level and produces a summary table and an interactive choropleth map. 
Connecticut is handled separately via a spatial join to planning regions. Puerto Rico and U.S. territories are excluded.

---

### 3. Poverty and Desert Estimates
**Script:** `deserts_poverty_estimates.Rmd`

Estimates the share of poverty-eligible children (children under five living in poverty) who live in a child care desert, at national and state level. 
Poverty rates are joined to child care data via a spatial join to 2020 census tract boundaries.

---

### 4. Head Start Desert Estimates
**Script:** `CCD_x_Head_Start_Analyses.Rmd` *(Authors: Evan Yi and Hailey Gibbs)*

Estimates what share of Head Start-eligible children live in a Head Start desert, with breakdowns by rurality and degree of supply scarcity. 
Eligibility is proxied using county-level poverty rates for children under five.

---

### 5. Rural Deserts Analysis
**Script:** `hg_rural_deserts.Rmd`

Examines child care access and desert rates along the rural-urban continuum using two independent federal classification systems: the HRSA Federal Office of Rural Health Policy (FORHP) binary rural designation and the six-tier NCHS Urban-Rural Classification Scheme. 
Includes national and state-level summaries and a reusable filter function for state-level exploration.

---

### 6. Deserts by Race/Ethnicity
**Script:** `desertsxrace.Rmd` *(Authors: Hailey Gibbs and Evan Yi)*

Compares child care desert rates across counties by majority racial and ethnic composition (majority Hispanic, majority Black non-Hispanic, and all other counties), with breakdowns by rurality and by state for rural majority-minority counties.

---

### 6. Deserts by Congressional District
**Script:** `deserts_by_CD.Rmd` *(Author: Hailey Gibbs)*

Aggregates child care access measures at the Congressional District level, using tigris to merge with CD shapefile. The CD data are from 2024 and all output flags that mid-decade redistricting efforts render some of these estimates moot.


## Shared Input Files

The following files are used across multiple analyses. Each subfolder README specifies which files it requires.

| File | Used by | Description |
|---|---|---|
| `cap_ccaccess_2025_revised_02282026.csv` | All analyses | Center for American Progress child care access data, 2025 revision |
| `poverty_total_and_under5_clean.csv` | Analyses 3, 4 | County- and tract-level poverty rates for children under five, cleaned from Census data |
| `rural-health-areas-data-set.xlsx` | Analysis 5 | HRSA FORHP rural county eligibility classifications. Download from [HRSA](https://www.hrsa.gov/rural-health/about-us/what-is-rural/data-files) |
| `data-table.csv` | Analysis 5 | NCHS Urban-Rural Classification Scheme. Download from [CDC/NCHS](https://www.cdc.gov/nchs/data_access/urban_rural.htm) |
| `pop_hispanic_blacknh.csv` | Analysis 6 | Census tract-level Hispanic and Black non-Hispanic population shares, cleaned from ACS data |

### ⚠️ Large Files Notice

`joined_rural.csv` and `cap_ccaccess_2025_revised_02282026.csv`exceed GitHub's file size limit and are **not included in this repository**. 
- joined_rural is required by analyses 4 and 6 to join rurality status to each child care data point by geographic coordinates.
- **Users will need to request access if you have not been previously granted; Any external partners requesting access will need a legally-approved DUA with CAP to license these data**

🔗 [joined_rural.csv on Google Drive](https://drive.google.com/file/d/17-cLCuDMT-M9Iujmw4yHfhYeasQr7J7R/view?usp=sharing)
🔗 [cap_ccaccess_2025_revised_02282026.csv on Google Drive](https://drive.google.com/file/d/1XgFNbiQamQwYm5s0Cl9xd39dhCJ28HSQ/view?usp=drive_link)

---

## Requirements

- R (≥ 4.2 recommended)
- The following R packages (not all are required by every script — see individual READMEs):

```r
install.packages(c(
  "tidyverse", "magrittr", "dplyr", "readr", "readxl",
  "tidycensus", "tigris", "sf",
  "scales", "ggplot2", "ggthemes",
  "leaflet", "leaflet.extras", "htmlwidgets", "htmltools",
  "collections", "zoo", "maps", "here"
))
```

---

## Data Sources

- **Center for American Progress** — *Child Care Access Dataset*, 2025 revision (February 2026)
- **U.S. Census Bureau** — American Community Survey, tract- and county-level poverty and race/ethnicity estimates
- **HRSA Federal Office of Rural Health Policy** — *Rural Health Areas Data Set*: <https://www.hrsa.gov/rural-health/about-us/what-is-rural/data-files>
- **National Center for Health Statistics** — *Urban-Rural Classification Scheme for Counties*, 2023: <https://www.cdc.gov/nchs/data_access/urban_rural.htm>
