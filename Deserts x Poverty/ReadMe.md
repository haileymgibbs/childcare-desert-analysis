# Child Care Deserts × Poverty Estimates
**Center for American Progress**

---

## Overview

This repository contains the R code for estimating the number and share of children under 5 living in poverty who also live in licensed child care deserts, nationally and by state. 
The script spatially joins child care supply points to Census tract boundaries, merges in tract-level poverty rates, and produces a national headline estimate and a state-level breakdown CSV.

---

## Key Definition

**Child care desert:** `adj_supply ≤ 0.33` (fewer than one licensed slot per three children)

---

## Data Sources

| File | Source | Use |
|---|---|---|
| `cap_ccaccess_2025_revised_02282026.csv` | Center for American Progress (saved in Drive) | Child care supply (`adj_supply`), lat/long points representing synthetic families |
| `poverty_total_and_under5_clean.csv` | Cleaned Census data (saved in Drive) | Tract-level poverty rate for children under 5 (`pct_poverty_under5`) |
| Census tract shapefiles | U.S. Census Bureau via `tigris` | 2020 tract boundaries for spatial join |

## Requirements

**R packages:**

```r
tidyverse, dplyr, readr, sf, tigris
```

Place both input CSV files in the same working directory as `analysis.Rmd` before running.

---

## Analysis Walkthrough

### 1. Download Tract Shapefiles

2020 Census tract boundaries for all states are downloaded via `tigris::tracts()` with `cb = TRUE` (cartographic boundary, smaller file). Results are cached locally after the first run (`options(tigris_use_cache = TRUE)`).

### 2. Spatial Join

Child care points are converted to `sf` objects and joined to tract boundaries using `st_within`. Any points that fall outside all tract boundaries (typically water areas or edge effects) are snapped to the nearest tract via `st_nearest_feature` rather than being dropped, maximizing coverage.

### 3. Merge Poverty Data

Tract-level poverty rates are joined to the spatially matched points by GEOID. A diagnostic block reports the number of points missing supply data, missing poverty data, and the final usable coverage rate.

### 4. Estimate Children in Poverty in Deserts

For each child care point, the number of poverty-eligible children is estimated as:

```
eligible_children = 10 × (pct_poverty_under5 / 100)
```

The constant 10 represents the synthetic family size used in the underlying child care access model. 
Desert status is applied at the point level (`adj_supply ≤ 0.33`), and eligible children are summed across desert and non-desert points to produce desert rates.

### 5. National and State-Level Results

National totals are computed across all usable points. State-level results are grouped by `state_name` / `state_abbrv`, sorted descending by desert rate, and written to `childcare_desert_poverty_by_state.csv`.

---

## Output

**Console (national estimate):**
```
======================================
NATIONAL RESULTS
======================================
Total children in poverty (est.):       [N]
In poverty & in a child care desert:    [N]
Percent in a child care desert:         [X.X%]
======================================
```

**File:** `childcare_desert_poverty_by_state.csv` — one row per state with columns `state_name`, `state_abbrv`, `total_eligible_children`, `desert_eligible_children`, and `pct_in_desert`.

---

## Notes

- **Bug fix (join-poverty chunk):** An earlier version of the script referenced an object named `poverty` in the join; this has been corrected to `poverty_kids` to match the loaded data frame.
- Tract shapefiles use the 2020 vintage; the poverty CSV should use matching 2020 GEOIDs to ensure accurate joins.
- The `eligible_children` estimate is synthetic and reflects the modeled family distribution in the underlying child care access dataset, not a direct Census count.


Data sources: Licensed Child Care Desert Data, on file with the Center for American Progress; U.S. Census Bureau, 2020 Census Tract Boundaries; poverty data derived from Census estimates (see `poverty_total_and_under5_clean.csv` documentation).
