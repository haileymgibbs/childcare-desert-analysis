# Child Care Deserts by Congressional District

**Author:** Hailey Gibbs  
**Last Updated:** June 2026

This repository contains code and outputs for estimating the share of young children living in licensed child care deserts, aggregated to the 119th Congressional District level.

---

## Overview

Using a national dataset of child care access scores at the census tract level, this analysis assigns each tract to a congressional district via spatial join and calculates what percentage of children under age 6 in each district live in a licensed child care desert — defined as a tract with an adjusted supply score of 0.33 or below.
The repository produces district-level estimates, summary tables by state, and both static and interactive choropleth maps of results. The published product can be found at this link:[America’s Child Care Crisis Leaves Many Families Without Access to Licensed Care](https://www.americanprogress.org/article/americas-child-care-crisis-leaves-many-families-without-access-to-licensed-care/).

---

## Data Sources

| Dataset | Description | File |
|---|---|---|
| CAP Child Care Access Data (2025) | Tract-level child care access scores with geographic coordinates | `cap_ccaccess_2025_revised_02282026.csv` |
| Congressional District Shapefiles | 119th Congress boundaries from the Census Bureau via `tigris` | Downloaded at runtime |

> **Note:** The source data file is stored in Google Drive. It is not committed directly due to file size.

---

## Methodology

1. **Spatial join** — Child care tract points are joined to 119th Congressional District polygons using `st_within`. The ~600 points (~0.027% of total) that fall outside district boundaries due to boundary edge effects are assigned to their nearest district using `st_nearest_feature`.

2. **Desert classification** — A tract is flagged as a child care desert if its adjusted supply score (`adj_supply`) is ≤ 0.33.

3. **District-level aggregation** — Tracts are weighted by the number of children they represent (each tract observation multiplied by 10). The desert share for each district is calculated as the number of children in desert tracts divided by total children in that district.

4. **District-level classification** — Districts are classified as child care deserts at two thresholds:
   - **≥ 50%** of children in the district live in a desert tract
   - **≥ 80%** of children in the district live in a desert tract

---

## Repository Structure

```
├── analysis.Rmd                     # Main analysis script (R Markdown)
├── cap_ccaccess_2025_revised_02282026.csv  # Source data (via Drive link)
├── outputs/
│   ├── cd_desert_estimates.csv      # District-level desert estimates
│   ├── cd_desert_classified.csv     # Estimates with desert flags (50% and 80% thresholds)
│   ├── cd_desert_national_summary.csv  # National summary by threshold
│   ├── cd_desert_state_summary.csv     # State-level breakdown by threshold
│   ├── cd_desert_map.png            # Static choropleth (ggplot2)
│   └── cd_desert_map.html           # Interactive choropleth (Leaflet, self-contained)
└── README.md
```

---

## Output Files

### `cd_desert_estimates.csv`
District-level estimates with the following columns:

| Column | Description |
|---|---|
| `GEOID` | Census GEOID for the congressional district |
| `NAMELSAD` | Full district name |
| `state_abbrv` | Two-letter state abbreviation |
| `total_children` | Total children under 6 represented in the district |
| `desert_children` | Children under 6 in desert tracts |
| `pct_in_desert` | Percent of children in district living in a desert tract |

### `cd_desert_national_summary.csv`
Count and share of all 436 districts qualifying as deserts at each threshold.

### `cd_desert_state_summary.csv`
State-level counts and shares of districts qualifying as deserts at each threshold.

### `cd_desert_map.html`
Interactive Leaflet map with hover tooltips showing district name, percent in desert, total children represented, and children in desert. Color scale uses the `magma` palette (light = lower desert share, dark = higher desert share).

> **Note:** The Leaflet map does not sync cleanly with Datawrapper. Use the exported HTML for embedding or sharing, or the static PNG for print/slide use.

---

## Requirements

### R Packages

```r
tidyverse
sf
tigris
ggplot2
leaflet
leaflet.extras
leaflegend
htmlwidgets
scales
```

### Notes
- `tigris` is used with caching enabled (`options(tigris_use_cache = TRUE)`) to avoid repeated downloads of the congressional district shapefile.
- All spatial operations use WGS84 (CRS 4326).
- Puerto Rico (STATEFP = "72") is excluded from all outputs.

---

## Geographic Scope

50 U.S. states + Washington, D.C. — 436 congressional districts total (435 voting districts + DC's at-large delegate district). Puerto Rico and other territories are excluded.

---

## Key Definitions

**Child care desert:** A census tract where the adjusted child care supply score (`adj_supply`) is 0.33 or below, indicating that licensed child care capacity is severely limited relative to the population of children under age 6.

**Desert district (≥50% threshold):** A congressional district where 50% or more of children under age 6 live in a desert tract.

**Desert district (≥80% threshold):** A congressional district where 80% or more of children under age 6 live in a desert tract.

---

## Contact

For questions about the methodology or data, contact **Hailey Gibbs** at **[hgibbs@americanprogress.org](mailto:hgibbs@americanprogress.org).**
